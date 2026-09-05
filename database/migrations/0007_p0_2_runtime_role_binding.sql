BEGIN;

-- Bind the Neon-managed CI login to the application role. The login itself
-- may be BYPASSRLS, so the behavioral suite explicitly SET ROLE nexora_app.
GRANT nexora_app TO nexora_runtime_test;

GRANT USAGE ON SCHEMA identity, party, fleet, transport, compliance, evidence, audit, outbox, integration TO nexora_app;
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
  audit.audit_event,
  evidence.evidence,
  outbox.event,
  integration.idempotency_key
TO nexora_app;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA party, fleet, transport, compliance, evidence, audit, outbox, integration TO nexora_app;

COMMIT;
