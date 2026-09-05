\set ON_ERROR_STOP on

-- P0.1 acceptance test. Execute against an isolated database after 0001-0007.
-- Fixture rows are created by the privileged test connection, then all
-- tenant-isolation assertions execute explicitly as nexora_app.

BEGIN;

INSERT INTO identity.tenant (id, name) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Tenant A'),
  ('00000000-0000-0000-0000-000000000002', 'Tenant B');

SET LOCAL ROLE nexora_app;

DO $$
BEGIN
  IF current_user <> 'nexora_app' THEN
    RAISE EXCEPTION 'P0.1 must execute tenant assertions as nexora_app, current_user=%', current_user;
  END IF;
END
$$;

SELECT set_config('app.tenant_id', '00000000-0000-0000-0000-000000000001', true);
INSERT INTO party.party (tenant_id, type, legal_name, tax_id)
VALUES ('00000000-0000-0000-0000-000000000001', 'CUSTOMER', 'A Test', 'A-TEST');

SELECT set_config('app.tenant_id', '00000000-0000-0000-0000-000000000002', true);
INSERT INTO party.party (tenant_id, type, legal_name, tax_id)
VALUES ('00000000-0000-0000-0000-000000000002', 'CUSTOMER', 'B Test', 'B-TEST');

DO $$
BEGIN
  IF (SELECT count(*) FROM party.party) <> 1 THEN
    RAISE EXCEPTION 'Tenant B must see exactly one party row';
  END IF;

  IF (SELECT count(*) FROM party.party WHERE tenant_id='00000000-0000-0000-0000-000000000001') <> 0 THEN
    RAISE EXCEPTION 'Tenant B can see Tenant A rows';
  END IF;
END
$$;

DO $$
DECLARE
  affected integer;
BEGIN
  UPDATE party.party
  SET legal_name = 'MUST NOT CHANGE'
  WHERE tenant_id = '00000000-0000-0000-0000-000000000001';
  GET DIAGNOSTICS affected = ROW_COUNT;
  IF affected <> 0 THEN
    RAISE EXCEPTION 'FAIL: cross-tenant update affected % rows', affected;
  END IF;
END
$$;

DO $$
BEGIN
  BEGIN
    INSERT INTO party.party (tenant_id, type, legal_name, tax_id)
    VALUES ('00000000-0000-0000-0000-000000000001', 'CUSTOMER', 'FORBIDDEN', 'FORBIDDEN');
    RAISE EXCEPTION 'FAIL: cross-tenant insert was accepted';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$$;

SELECT set_config('app.tenant_id', '', true);
DO $$
BEGIN
  BEGIN
    INSERT INTO party.party (tenant_id, type, legal_name, tax_id)
    VALUES ('00000000-0000-0000-0000-000000000002', 'CUSTOMER', 'NO CONTEXT', 'NO-CONTEXT');
    RAISE EXCEPTION 'FAIL: missing tenant context was accepted';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$$;

ROLLBACK;
\echo 'P0.1 tenant RLS suite: PASS'
