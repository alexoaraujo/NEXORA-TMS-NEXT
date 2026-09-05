BEGIN;

-- P0.2 runtime roles are provisioned at the Neon infrastructure layer.
-- The migration validates both roles and establishes only the membership and
-- grants required by the runtime test.
DO $$
DECLARE
  app_role record;
  runtime_role record;
BEGIN
  SELECT rolsuper, rolinherit, rolcreaterole, rolcreatedb, rolcanlogin,
         rolreplication, rolbypassrls
    INTO app_role
  FROM pg_roles
  WHERE rolname = 'nexora_app';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'required role nexora_app is not provisioned';
  END IF;

  IF app_role.rolsuper OR app_role.rolinherit OR app_role.rolcreaterole
     OR app_role.rolcreatedb OR app_role.rolcanlogin
     OR app_role.rolreplication OR app_role.rolbypassrls THEN
    RAISE EXCEPTION 'nexora_app has invalid security attributes';
  END IF;

  SELECT rolsuper, rolinherit, rolcreaterole, rolcreatedb, rolcanlogin,
         rolreplication, rolbypassrls
    INTO runtime_role
  FROM pg_roles
  WHERE rolname = 'nexora_runtime_test';

  IF NOT FOUND OR runtime_role.rolcanlogin IS NOT TRUE THEN
    RAISE EXCEPTION 'required runtime login role nexora_runtime_test is not available';
  END IF;

  IF runtime_role.rolsuper OR runtime_role.rolinherit OR runtime_role.rolcreaterole
     OR runtime_role.rolcreatedb OR runtime_role.rolreplication
     OR runtime_role.rolbypassrls THEN
    RAISE EXCEPTION 'nexora_runtime_test has forbidden security attributes';
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
