\set ON_ERROR_STOP on

-- Execute by connecting as nexora_runtime_test. The login role must SET ROLE
-- nexora_app through migration 0007. The isolated test database must contain
-- the two fixed tenant fixture rows used below.

BEGIN;
SET LOCAL statement_timeout = '10s';

DO $$
BEGIN
  IF session_user <> 'nexora_runtime_test' THEN RAISE EXCEPTION 'P0.2 must connect as nexora_runtime_test, session_user=%', session_user; END IF;
END
$$;

SET LOCAL ROLE nexora_app;

DO $$
BEGIN
  IF current_user <> 'nexora_app' THEN RAISE EXCEPTION 'P0.2 must execute as nexora_app'; END IF;
  IF (SELECT rolsuper FROM pg_roles WHERE rolname=current_user) THEN RAISE EXCEPTION 'runtime role is SUPERUSER'; END IF;
  IF (SELECT rolbypassrls FROM pg_roles WHERE rolname=current_user) THEN RAISE EXCEPTION 'runtime role has BYPASSRLS'; END IF;
  IF (SELECT rolcreaterole FROM pg_roles WHERE rolname=current_user) THEN RAISE EXCEPTION 'runtime role has CREATEROLE'; END IF;
  IF (SELECT rolcreatedb FROM pg_roles WHERE rolname=current_user) THEN RAISE EXCEPTION 'runtime role has CREATEDB'; END IF;
END
$$;

DO $$
BEGIN
  IF (SELECT count(*) FROM identity.tenant WHERE id IN ('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002')) <> 2 THEN
    RAISE EXCEPTION 'P0.2 requires two pre-seeded tenant fixture rows';
  END IF;
END
$$;

CREATE TEMP TABLE p0_2_ids(id uuid, tenant_id uuid) ON COMMIT DROP;

SELECT set_config('app.tenant_id', '00000000-0000-0000-0000-000000000001', true);
WITH ins AS (
  INSERT INTO transport.order(tenant_id, origin_city, origin_state, destination_city, destination_state, status)
  VALUES (identity.current_tenant_id(), 'Santos', 'SP', 'São Paulo', 'SP', 'DRAFT')
  RETURNING id, tenant_id
)
INSERT INTO p0_2_ids SELECT * FROM ins;

DO $$
BEGIN
  IF (SELECT count(*) FROM transport.order WHERE id=(SELECT id FROM p0_2_ids)) <> 1 THEN RAISE EXCEPTION 'Tenant A cannot read own order'; END IF;
END
$$;

SELECT set_config('app.tenant_id', '00000000-0000-0000-0000-000000000002', true);
DO $$
BEGIN
  IF (SELECT count(*) FROM transport.order WHERE id=(SELECT id FROM p0_2_ids)) <> 0 THEN RAISE EXCEPTION 'Tenant B can read Tenant A order'; END IF;
END
$$;

SELECT set_config('app.tenant_id', '00000000-0000-0000-0000-000000000001', true);
UPDATE transport.order SET status='PLANNED' WHERE id=(SELECT id FROM p0_2_ids);

SELECT set_config('app.tenant_id', '00000000-0000-0000-0000-000000000002', true);
DO $$
BEGIN
  IF (SELECT count(*) FROM transport.order WHERE id=(SELECT id FROM p0_2_ids)) <> 0 THEN RAISE EXCEPTION 'Tenant B sees Tenant A order'; END IF;
END
$$;

SELECT set_config('app.tenant_id', '00000000-0000-0000-0000-000000000001', true);
DO $$
BEGIN
  BEGIN
    INSERT INTO transport.order(tenant_id, origin_city, origin_state, destination_city, destination_state, status)
    VALUES ('00000000-0000-0000-0000-000000000002','Santos','SP','São Paulo','SP','DRAFT');
    RAISE EXCEPTION 'cross-tenant INSERT unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END
$$;

RESET app.tenant_id;
DO $$
BEGIN
  BEGIN
    INSERT INTO transport.order(tenant_id, origin_city, origin_state, destination_city, destination_state, status)
    VALUES ('00000000-0000-0000-0000-000000000001','Santos','SP','São Paulo','SP','DRAFT');
    RAISE EXCEPTION 'write without tenant context unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END
$$;

SELECT set_config('app.tenant_id','00000000-0000-0000-0000-000000000001', true);

DO $$
BEGIN
  IF (SELECT count(*) FROM audit.event WHERE entity_id=(SELECT id FROM p0_2_ids) AND tenant_id=identity.current_tenant_id() AND action='TRANSPORT_ORDER_CREATED') <> 1 THEN RAISE EXCEPTION 'missing canonical audit event'; END IF;
  IF (SELECT count(*) FROM event.outbox WHERE aggregate_id=(SELECT id FROM p0_2_ids) AND tenant_id=identity.current_tenant_id() AND event_type='transport.order.created') <> 1 THEN RAISE EXCEPTION 'missing canonical outbox event'; END IF;
END
$$;

INSERT INTO evidence.package (tenant_id, subject_type, subject_id)
VALUES (identity.current_tenant_id(), 'transport.order', (SELECT id FROM p0_2_ids));

INSERT INTO evidence.item (package_id, evidence_type, source_type, source_uri)
SELECT p.id, 'TEST', 'TEST', 'test://p0-2'
FROM evidence.package p
WHERE p.tenant_id=identity.current_tenant_id()
  AND p.subject_type='transport.order'
  AND p.subject_id=(SELECT id FROM p0_2_ids);

DO $$
BEGIN
  IF (SELECT count(*) FROM evidence.package WHERE tenant_id=identity.current_tenant_id() AND subject_id=(SELECT id FROM p0_2_ids)) <> 1 THEN RAISE EXCEPTION 'canonical evidence.package missing'; END IF;
  IF (SELECT count(*) FROM evidence.item i JOIN evidence.package p ON p.id=i.package_id WHERE p.tenant_id=identity.current_tenant_id() AND p.subject_id=(SELECT id FROM p0_2_ids)) <> 1 THEN RAISE EXCEPTION 'canonical evidence.item missing'; END IF;
END
$$;

INSERT INTO integration.idempotency_key (tenant_id, key, endpoint, request_hash, response_status, response_body)
VALUES (identity.current_tenant_id(), 'p0-2-idempotency', 'test://p0-2', 'hash-1', 200, '{}'::jsonb)
ON CONFLICT (tenant_id, key, endpoint) DO NOTHING;

INSERT INTO integration.idempotency_key (tenant_id, key, endpoint, request_hash, response_status, response_body)
VALUES (identity.current_tenant_id(), 'p0-2-idempotency', 'test://p0-2', 'hash-1', 200, '{}'::jsonb)
ON CONFLICT (tenant_id, key, endpoint) DO NOTHING;

DO $$
BEGIN
  IF (SELECT count(*) FROM integration.idempotency_key WHERE tenant_id=identity.current_tenant_id() AND key='p0-2-idempotency' AND endpoint='test://p0-2') <> 1 THEN RAISE EXCEPTION 'idempotency constraint failed'; END IF;
END
$$;

ROLLBACK;
\echo 'P0.2 runtime RLS canonical suite: PASS'
