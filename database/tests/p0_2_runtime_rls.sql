\set ON_ERROR_STOP on
BEGIN;
SET LOCAL statement_timeout = '10s';

DO $$
BEGIN
  IF session_user <> 'nexora_runtime_test' THEN
    RAISE EXCEPTION 'P0.2 must connect as nexora_runtime_test, session_user=%', session_user;
  END IF;
END $$;

SET LOCAL ROLE nexora_app;

DO $$
BEGIN
  IF current_user <> 'nexora_app' THEN
    RAISE EXCEPTION 'P0.2 must execute as nexora_app, current_user=%', current_user;
  END IF;
  IF (SELECT rolsuper FROM pg_roles WHERE rolname=current_user) THEN
    RAISE EXCEPTION 'runtime role is SUPERUSER';
  END IF;
  IF (SELECT rolbypassrls FROM pg_roles WHERE rolname=current_user) THEN
    RAISE EXCEPTION 'runtime role has BYPASSRLS';
  END IF;
END $$;

CREATE TEMP TABLE p0_2_ids(id uuid, tenant_id uuid) ON COMMIT DROP;
SELECT set_config('app.tenant_id','00000000-0000-0000-0000-000000000001', true);
WITH ins AS (
  INSERT INTO transport.order(tenant_id,status)
  VALUES (identity.current_tenant_id(),'DRAFT')
  RETURNING id,tenant_id
)
INSERT INTO p0_2_ids SELECT * FROM ins;

DO $$
BEGIN
  IF (SELECT count(*) FROM transport.order WHERE id=(SELECT id FROM p0_2_ids)) <> 1 THEN RAISE EXCEPTION 'Tenant A cannot read own order'; END IF;
END $$;

SELECT set_config('app.tenant_id','00000000-0000-0000-0000-000000000002', true);
DO $$
BEGIN
  IF (SELECT count(*) FROM transport.order WHERE id=(SELECT id FROM p0_2_ids)) <> 0 THEN RAISE EXCEPTION 'Tenant B can read Tenant A order'; END IF;
END $$;

SELECT set_config('app.tenant_id','00000000-0000-0000-0000-000000000001', true);
UPDATE transport.order SET status='PLANNED' WHERE id=(SELECT id FROM p0_2_ids);

SELECT set_config('app.tenant_id','00000000-0000-0000-0000-000000000002', true);
DO $$
BEGIN
  IF (SELECT count(*) FROM transport.order WHERE id=(SELECT id FROM p0_2_ids)) <> 0 THEN RAISE EXCEPTION 'Tenant B sees Tenant A order'; END IF;
END $$;

SELECT set_config('app.tenant_id','00000000-0000-0000-0000-000000000001', true);
DO $$
BEGIN
  BEGIN
    INSERT INTO transport.order(tenant_id,status) VALUES ('00000000-0000-0000-0000-000000000002','DRAFT');
    RAISE EXCEPTION 'cross-tenant INSERT unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $$;

RESET app.tenant_id;
DO $$
BEGIN
  BEGIN
    INSERT INTO transport.order(tenant_id,status) VALUES ('00000000-0000-0000-0000-000000000001','DRAFT');
    RAISE EXCEPTION 'write without tenant context unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $$;

SELECT set_config('app.tenant_id','00000000-0000-0000-0000-000000000001', true);
DO $$
BEGIN
  IF (SELECT count(*) FROM audit.audit_event WHERE aggregate_id=(SELECT id FROM p0_2_ids) AND tenant_id=identity.current_tenant_id()) <> 1 THEN RAISE EXCEPTION 'missing audit event'; END IF;
  IF (SELECT count(*) FROM outbox.event WHERE aggregate_id=(SELECT id FROM p0_2_ids) AND tenant_id=identity.current_tenant_id()) <> 1 THEN RAISE EXCEPTION 'missing outbox event'; END IF;
END $$;

INSERT INTO evidence.evidence(tenant_id,aggregate_type,aggregate_id,evidence_type,content_hash,uri)
VALUES (identity.current_tenant_id(),'transport.order',(SELECT id FROM p0_2_ids),'TEST','p0-2-test-hash','test://p0-2')
ON CONFLICT (tenant_id,content_hash) DO NOTHING;

DO $$
BEGIN
  IF (SELECT count(*) FROM evidence.evidence WHERE aggregate_id=(SELECT id FROM p0_2_ids)) <> 1 THEN RAISE EXCEPTION 'evidence missing'; END IF;
END $$;

INSERT INTO outbox.event(tenant_id,aggregate_type,aggregate_id,event_type,idempotency_key,payload)
VALUES (identity.current_tenant_id(),'transport.order',(SELECT id FROM p0_2_ids),'TEST','p0-2-idempotency','{}')
ON CONFLICT (tenant_id,idempotency_key) DO NOTHING;
INSERT INTO outbox.event(tenant_id,aggregate_type,aggregate_id,event_type,idempotency_key,payload)
VALUES (identity.current_tenant_id(),'transport.order',(SELECT id FROM p0_2_ids),'TEST','p0-2-idempotency','{}')
ON CONFLICT (tenant_id,idempotency_key) DO NOTHING;

DO $$
BEGIN
  IF (SELECT count(*) FROM outbox.event WHERE tenant_id=identity.current_tenant_id() AND idempotency_key='p0-2-idempotency') <> 1 THEN RAISE EXCEPTION 'idempotency failed'; END IF;
END $$;

ROLLBACK;
\echo 'P0.2 runtime RLS behavioral suite: PASS'
