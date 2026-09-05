BEGIN;

CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS evidence;
CREATE SCHEMA IF NOT EXISTS outbox;

CREATE TABLE IF NOT EXISTS audit.audit_event (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  aggregate_type text NOT NULL,
  aggregate_id uuid NOT NULL,
  action text NOT NULL,
  actor_id text,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  payload jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS evidence.evidence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  aggregate_type text NOT NULL,
  aggregate_id uuid NOT NULL,
  evidence_type text NOT NULL,
  content_hash text NOT NULL,
  uri text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, content_hash)
);

CREATE TABLE IF NOT EXISTS outbox.event (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  aggregate_type text NOT NULL,
  aggregate_id uuid NOT NULL,
  event_type text NOT NULL,
  idempotency_key text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz,
  UNIQUE (tenant_id, idempotency_key)
);

CREATE INDEX IF NOT EXISTS idx_audit_event_tenant_aggregate ON audit.audit_event (tenant_id, aggregate_type, aggregate_id);
CREATE INDEX IF NOT EXISTS idx_evidence_tenant_aggregate ON evidence.evidence (tenant_id, aggregate_type, aggregate_id);
CREATE INDEX IF NOT EXISTS idx_outbox_pending ON outbox.event (tenant_id, published_at, created_at);

ALTER TABLE audit.audit_event ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit.audit_event FORCE ROW LEVEL SECURITY;
ALTER TABLE evidence.evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE evidence.evidence FORCE ROW LEVEL SECURITY;
ALTER TABLE outbox.event ENABLE ROW LEVEL SECURITY;
ALTER TABLE outbox.event FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS audit_event_tenant_isolation ON audit.audit_event;
CREATE POLICY audit_event_tenant_isolation ON audit.audit_event FOR ALL
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS evidence_tenant_isolation ON evidence.evidence;
CREATE POLICY evidence_tenant_isolation ON evidence.evidence FOR ALL
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

DROP POLICY IF EXISTS outbox_event_tenant_isolation ON outbox.event;
CREATE POLICY outbox_event_tenant_isolation ON outbox.event FOR ALL
  USING (tenant_id = identity.current_tenant_id())
  WITH CHECK (tenant_id = identity.require_tenant_context());

COMMIT;
