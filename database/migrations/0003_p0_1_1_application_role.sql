BEGIN;

-- Runtime role is deliberately NOLOGIN: the deployment mechanism must bind the
-- runtime credential to an equivalent non-superuser/non-BYPASSRLS role.
-- CREATE ROLE is idempotent through the guarded DO block.
DO $role$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'nexora_app') THEN
    CREATE ROLE nexora_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
  ELSE
    ALTER ROLE nexora_app NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
  END IF;
END
$role$;

-- Runtime may use existing schemas, but cannot create/alter/drop objects.
GRANT USAGE ON SCHEMA identity, party, fleet, transport, compliance, evidence, audit, event, integration TO nexora_app;

-- Tenant identity is read-only for runtime; domain tables receive DML privileges.
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
  audit.event,
  event.outbox,
  integration.idempotency_key
TO nexora_app;

-- Sequence privileges are granted explicitly where serial/identity sequences exist.
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA party, fleet, transport, compliance, evidence, audit, event, integration TO nexora_app;

-- Ensure future tables do not accidentally become runtime-readable/writable by default.
ALTER DEFAULT PRIVILEGES IN SCHEMA identity, party, fleet, transport, compliance, evidence, audit, event, integration
  REVOKE ALL ON TABLES FROM nexora_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA identity, party, fleet, transport, compliance, evidence, audit, event, integration
  REVOKE ALL ON SEQUENCES FROM nexora_app;

-- The runtime role must not own tenant tables. RLS remains enforced even for owners.
ALTER TABLE party.party FORCE ROW LEVEL SECURITY;
ALTER TABLE party.carrier FORCE ROW LEVEL SECURITY;
ALTER TABLE fleet.driver FORCE ROW LEVEL SECURITY;
ALTER TABLE fleet.vehicle FORCE ROW LEVEL SECURITY;
ALTER TABLE transport.order FORCE ROW LEVEL SECURITY;
ALTER TABLE transport.shipment FORCE ROW LEVEL SECURITY;
ALTER TABLE transport.operation FORCE ROW LEVEL SECURITY;
ALTER TABLE transport.trip FORCE ROW LEVEL SECURITY;
ALTER TABLE compliance.case FORCE ROW LEVEL SECURITY;
ALTER TABLE evidence.package FORCE ROW LEVEL SECURITY;
ALTER TABLE audit.event FORCE ROW LEVEL SECURITY;
ALTER TABLE event.outbox FORCE ROW LEVEL SECURITY;
ALTER TABLE integration.idempotency_key FORCE ROW LEVEL SECURITY;

COMMIT;
