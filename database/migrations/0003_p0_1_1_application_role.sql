BEGIN;

-- Runtime application role. The CI test login (nexora_runtime_test) is a
-- Neon-managed login role and may carry BYPASSRLS; it must SET ROLE to this
-- non-login application role before exercising tenant isolation.
DO $role$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'nexora_app') THEN
    CREATE ROLE nexora_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
  ELSE
    ALTER ROLE nexora_app NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
  END IF;
END
$role$;

-- Defense-in-depth: every tenant-scoped table must remain forced through RLS,
-- including when accessed by the table owner. Migration 0002 enables this too;
-- repeating FORCE here makes the hardening contract explicit and idempotent.
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
