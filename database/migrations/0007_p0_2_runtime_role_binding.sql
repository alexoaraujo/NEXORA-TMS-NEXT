BEGIN;

-- P0.2 runtime binding is intentionally explicit. The Neon login role is
-- provisioned outside the schema migration; fail clearly if it is absent.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'nexora_runtime_test') THEN
    RAISE EXCEPTION 'required runtime login role nexora_runtime_test does not exist';
  END IF;
END
$$;

DO $role$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'nexora_app') THEN
    CREATE ROLE nexora_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
  ELSE
    ALTER ROLE nexora_app
      NOLOGIN
      NOSUPERUSER
      NOCREATEDB
      NOCREATEROLE
      NOINHERIT
      NOREPLICATION
      NOBYPASSRLS;
  END IF;
END
$role$;

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

-- UUID-backed tables do not require sequence privileges, but retain explicit
-- sequence grants for future sequence-backed additions to these schemas.
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA party, fleet, transport, compliance, evidence, audit, event, integration TO nexora_app;

DO $$
BEGIN
  IF to_regclass('audit.audit_event') IS NOT NULL
     OR to_regclass('outbox.event') IS NOT NULL
     OR to_regclass('evidence.evidence') IS NOT NULL THEN
    RAISE EXCEPTION 'legacy competing audit/outbox/evidence objects detected';
  END IF;
END
$$;

COMMIT;
