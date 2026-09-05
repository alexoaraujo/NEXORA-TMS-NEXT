BEGIN;

-- Canonical audit/evidence/outbox objects are created by 0001_foundation.sql.
-- This migration only adds the missing evidence-item index and verifies the
-- canonical model. It must not create competing objects or duplicate indexes.
DO $$
BEGIN
  IF to_regclass('audit.event') IS NULL THEN
    RAISE EXCEPTION 'audit.event must be created by 0001_foundation.sql';
  END IF;
  IF to_regclass('evidence.package') IS NULL THEN
    RAISE EXCEPTION 'evidence.package must be created by 0001_foundation.sql';
  END IF;
  IF to_regclass('evidence.item') IS NULL THEN
    RAISE EXCEPTION 'evidence.item must be created by 0001_foundation.sql';
  END IF;
  IF to_regclass('event.outbox') IS NULL THEN
    RAISE EXCEPTION 'event.outbox must be created by 0001_foundation.sql';
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_evidence_item_package ON evidence.item (package_id);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'evidence'
      AND tablename = 'item'
      AND policyname = 'evidence_item_tenant_isolation'
  ) THEN
    RAISE EXCEPTION 'canonical evidence.item policy from 0002 is missing';
  END IF;

  IF to_regclass('audit.audit_event') IS NOT NULL
     OR to_regclass('outbox.event') IS NOT NULL
     OR to_regclass('evidence.evidence') IS NOT NULL THEN
    RAISE EXCEPTION 'legacy competing audit/outbox/evidence objects detected';
  END IF;
END
$$;

COMMIT;
