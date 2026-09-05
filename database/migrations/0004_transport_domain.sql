BEGIN;

CREATE SCHEMA IF NOT EXISTS transport;

CREATE TABLE IF NOT EXISTS transport.order (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  status text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','PLANNED','CANCELLED')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_transport_order_tenant_status
  ON transport.order (tenant_id, status);

ALTER TABLE transport.order ENABLE ROW LEVEL SECURITY;
ALTER TABLE transport.order FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS transport_order_tenant_isolation ON transport.order;
CREATE POLICY transport_order_tenant_isolation ON transport.order
  FOR ALL
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

COMMIT;
