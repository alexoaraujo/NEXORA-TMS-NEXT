BEGIN;

CREATE OR REPLACE FUNCTION transport.emit_order_created_events()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  INSERT INTO audit.audit_event (tenant_id, aggregate_type, aggregate_id, action, payload)
  VALUES (NEW.tenant_id, 'transport.order', NEW.id, 'TRANSPORT_ORDER_CREATED', jsonb_build_object('status', NEW.status));

  INSERT INTO outbox.event (tenant_id, aggregate_type, aggregate_id, event_type, idempotency_key, payload)
  VALUES (NEW.tenant_id, 'transport.order', NEW.id, 'transport.order.created', NEW.id::text || ':created', jsonb_build_object('status', NEW.status))
  ON CONFLICT (tenant_id, idempotency_key) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_transport_order_created_events ON transport.order;
CREATE TRIGGER trg_transport_order_created_events
AFTER INSERT ON transport.order
FOR EACH ROW
EXECUTE FUNCTION transport.emit_order_created_events();

COMMIT;
