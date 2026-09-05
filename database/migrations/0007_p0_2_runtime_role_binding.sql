BEGIN;

-- P0.2 runtime roles are provisioned at the Neon infrastructure layer.
-- Migrations validate their availability/security posture and establish only
-- the database membership/grants needed by the runtime test.
DO $$
DECLARE
  app_role record;
  login_role record;
BEGIN
  SELECT rolsuper, rolcreaterole, rolcreatedb, rolcanlogin,
         rolreplication, rolbypassrls
    INTO app_role
  FROM pg_roles
  WHERE rolname = 'nexora_app';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'required role nexora_app is not provisioned';
  END IF;

  IF app_role.rolsuper OR app_role.rolcreaterole OR app_role.rolcreatedb
     OR app_role.rolcanlogin OR app_role.rolreplication OR app_role.rolbypassrls THEN
    RAISE EXCEPTION 'nexora_app has invalid security attributes';
  END IF;

  SELECT rolcanlogin
    INTO login_role
  FROM pg_roles
  WHERE rolname = 'nexora_runtime_test';

  IF NOT FOUND OR login_role.rolcanlogin IS NOT TRUE THEN
    RAISE EXCEPTION 'required runtime login role nexora_runtime_test is not available';
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
