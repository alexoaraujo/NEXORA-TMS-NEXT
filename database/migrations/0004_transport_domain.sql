BEGIN;

-- transport.order is defined canonically by 0001_foundation.sql.
-- This migration must evolve that table, never redefine it with a reduced shape.
DO $$
BEGIN
  IF to_regclass('transport.order') IS NULL THEN
    RAISE EXCEPTION 'transport.order must be created by 0001_foundation.sql';
  END IF;
END
$$;

CREATE INDEX idx_transport_order_tenant_status
  ON transport.order (tenant_id, status);

ALTER TABLE transport.order ENABLE ROW LEVEL SECURITY;
ALTER TABLE transport.order FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS transport_order_tenant_isolation ON transport.order;

-- 0002 is the canonical owner of the transport.order tenant policy.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'transport'
      AND tablename = 'order'
      AND policyname = 'order_tenant_isolation'
  ) THEN
    RAISE EXCEPTION 'canonical order_tenant_isolation policy from 0002 is missing';
  END IF;
END
$$;

COMMIT;
