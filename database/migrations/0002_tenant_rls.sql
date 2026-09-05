BEGIN;

-- Canonical tenant isolation contract.
-- The application MUST set LOCAL app.tenant_id after authentication/authorization.
-- Missing tenant context returns no tenant-owned rows and rejects tenant-owned writes.
CREATE OR REPLACE FUNCTION identity.current_tenant_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT NULLIF(current_setting('app.tenant_id', true), '')::uuid;
$$;

CREATE OR REPLACE FUNCTION identity.require_tenant_context()
RETURNS uuid
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_tenant uuid := identity.current_tenant_id();
BEGIN
  IF v_tenant IS NULL THEN
    RAISE EXCEPTION 'tenant context is required' USING ERRCODE = '42501';
  END IF;
  RETURN v_tenant;
END;
$$;

ALTER TABLE party.party ENABLE ROW LEVEL SECURITY;
ALTER TABLE party.carrier ENABLE ROW LEVEL SECURITY;
ALTER TABLE fleet.driver ENABLE ROW LEVEL SECURITY;
ALTER TABLE fleet.vehicle ENABLE ROW LEVEL SECURITY;
ALTER TABLE transport.order ENABLE ROW LEVEL SECURITY;
ALTER TABLE transport.shipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE transport.operation ENABLE ROW LEVEL SECURITY;
ALTER TABLE transport.trip ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance.case ENABLE ROW LEVEL SECURITY;
ALTER TABLE evidence.package ENABLE ROW LEVEL SECURITY;
ALTER TABLE evidence.item ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit.event ENABLE ROW LEVEL SECURITY;
ALTER TABLE event.outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration.idempotency_key ENABLE ROW LEVEL SECURITY;

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

DROP POLICY IF EXISTS party_tenant_isolation ON party.party;
CREATE POLICY party_tenant_isolation ON party.party
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS carrier_tenant_isolation ON party.carrier;
CREATE POLICY carrier_tenant_isolation ON party.carrier
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS driver_tenant_isolation ON fleet.driver;
CREATE POLICY driver_tenant_isolation ON fleet.driver
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS vehicle_tenant_isolation ON fleet.vehicle;
CREATE POLICY vehicle_tenant_isolation ON fleet.vehicle
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS order_tenant_isolation ON transport.order;
CREATE POLICY order_tenant_isolation ON transport.order
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS shipment_tenant_isolation ON transport.shipment;
CREATE POLICY shipment_tenant_isolation ON transport.shipment
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS operation_tenant_isolation ON transport.operation;
CREATE POLICY operation_tenant_isolation ON transport.operation
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS trip_tenant_isolation ON transport.trip;
CREATE POLICY trip_tenant_isolation ON transport.trip
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS compliance_case_tenant_isolation ON compliance.case;
CREATE POLICY compliance_case_tenant_isolation ON compliance.case
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS evidence_package_tenant_isolation ON evidence.package;
CREATE POLICY evidence_package_tenant_isolation ON evidence.package
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS audit_event_tenant_isolation ON audit.event;
CREATE POLICY audit_event_tenant_isolation ON audit.event
  USING (tenant_id IS NULL OR tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id IS NULL OR tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS outbox_tenant_isolation ON event.outbox;
CREATE POLICY outbox_tenant_isolation ON event.outbox
  USING (tenant_id IS NULL OR tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id IS NULL OR tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS idempotency_tenant_isolation ON integration.idempotency_key;
CREATE POLICY idempotency_tenant_isolation ON integration.idempotency_key
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS evidence_item_tenant_isolation ON evidence.item;
CREATE POLICY evidence_item_tenant_isolation ON evidence.item
  USING (
    EXISTS (
      SELECT 1
      FROM evidence.package p
      WHERE p.id = evidence.item.package_id
        AND p.tenant_id = identity.current_tenant_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM evidence.package p
      WHERE p.id = evidence.item.package_id
        AND p.tenant_id = identity.require_tenant_context()
    )
  );

-- Regulatory reference data is intentionally global and is not tenant-scoped.
COMMIT;
