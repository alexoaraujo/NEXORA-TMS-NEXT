BEGIN;

-- P0.2 runtime binding must be safe to apply to an existing Neon preview
-- baseline. The CI login may be Neon-managed and may retain BYPASSRLS;
-- runtime behavior is tested after SET ROLE nexora_app.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'nexora_app') THEN
    CREATE ROLE nexora_app NOLOGIN NOSUPERUSER NOBYPASSRLS;
  ELSE
    ALTER ROLE nexora_app NOLOGIN NOSUPERUSER NOBYPASSRLS;
  END IF;
END
$$;

GRANT nexora_app TO nexora_runtime_test;

GRANT USAGE ON SCHEMA identity, party, fleet, transport, compliance, evidence, audit, event, integration TO nexora_app;
GRANT SELECT ON identity.tenant TO nexora_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON
  party.party,
  party.carrier,
  fleet.driver,
  fleet.vehicle,
  transport.order,
  transport.shipment,
  transport.operation,
  transport.trip,
  compliance.case,
  evidence.package,
  evidence.item,
  audit.event,
  event.outbox,
  integration.idempotency_key
TO nexora_app;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA party, fleet, transport, compliance, evidence, audit, event, integration TO nexora_app;

COMMIT;
