BEGIN;

-- Neon role administration is an infrastructure concern. The database
-- migration must validate the pre-provisioned nexora_app role instead of
-- attempting CREATE/ALTER ROLE with a database owner that may not have
-- CREATEROLE privileges.
DO $$
DECLARE
  r record;
BEGIN
  SELECT rolsuper, rolinherit, rolcreaterole, rolcreatedb, rolcanlogin,
         rolreplication, rolbypassrls
    INTO r
  FROM pg_roles
  WHERE rolname = 'nexora_app';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'required role nexora_app is not provisioned';
  END IF;

  IF r.rolsuper OR r.rolcreaterole OR r.rolcreatedb OR r.rolcanlogin
     OR r.rolreplication OR r.rolbypassrls OR r.rolinherit THEN
    RAISE EXCEPTION 'nexora_app has invalid security attributes';
  END IF;
END
$$;

REVOKE ALL ON FUNCTION identity.package_belongs_to_current_tenant(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION identity.package_belongs_to_current_tenant(uuid) TO nexora_app;

-- Defense in depth: every tenant-scoped object is forced through RLS.
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
ALTER TABLE evidence.item FORCE ROW LEVEL SECURITY;
ALTER TABLE audit.event FORCE ROW LEVEL SECURITY;
ALTER TABLE event.outbox FORCE ROW LEVEL SECURITY;
ALTER TABLE integration.idempotency_key FORCE ROW LEVEL SECURITY;

COMMIT;
