BEGIN;

-- Canonical audit/evidence/outbox objects are created by 0001_foundation.sql.
-- This migration only adds P0.2 hardening and indexes; it must not create
-- competing audit.audit_event, outbox.event, or evidence.evidence tables.
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

CREATE INDEX idx_evidence_item_package
  ON evidence.item (package_id);

CREATE INDEX idx_evidence_package_subject
  ON evidence.package (tenant_id, subject_type, subject_id);

CREATE INDEX idx_event_outbox_pending
  ON event.outbox (occurred_at)
  WHERE published_at IS NULL;

CREATE INDEX idx_audit_event_entity
  ON audit.event (tenant_id, entity_type, entity_id, occurred_at);

ALTER TABLE evidence.item ENABLE ROW LEVEL SECURITY;
ALTER TABLE evidence.item FORCE ROW LEVEL SECURITY;

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

-- Legacy competing objects are prohibited. If they exist in a supposedly
-- clean baseline, fail instead of silently carrying two data models.
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
