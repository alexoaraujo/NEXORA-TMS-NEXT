BEGIN;

-- Transactional integration uses the canonical 0001 objects only.
DO $$
BEGIN
  IF to_regclass('audit.event') IS NULL THEN
    RAISE EXCEPTION 'audit.event must exist before 0006';
  END IF;
  IF to_regclass('event.outbox') IS NULL THEN
    RAISE EXCEPTION 'event.outbox must exist before 0006';
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION transport.emit_order_created_events()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  INSERT INTO audit.event (
    tenant_id,
    action,
    entity_type,
    entity_id,
    after_state
  )
  VALUES (
    NEW.tenant_id,
    'TRANSPORT_ORDER_CREATED',
    'transport.order',
    NEW.id,
    jsonb_build_object('status', NEW.status)
  );

  INSERT INTO event.outbox (
    tenant_id,
    event_type,
    aggregate_type,
    aggregate_id,
    payload
  )
  VALUES (
    NEW.tenant_id,
    'transport.order.created',
    'transport.order',
    NEW.id,
    jsonb_build_object('status', NEW.status)
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_transport_order_created_events ON transport.order;
CREATE TRIGGER trg_transport_order_created_events
AFTER INSERT ON transport.order
FOR EACH ROW
EXECUTE FUNCTION transport.emit_order_created_events();

COMMIT;
