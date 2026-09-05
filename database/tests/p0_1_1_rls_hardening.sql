-- Execute as nexora_app (not the migration/owner role) against an isolated database.
-- The script raises on every isolation violation.

BEGIN;

CREATE TEMP TABLE rls_test_result (name text PRIMARY KEY, passed boolean NOT NULL, detail text);

SELECT set_config('app.tenant_id', '00000000-0000-0000-0000-000000000001', true);
INSERT INTO rls_test_result
SELECT 'A sees A', count(*) = 1, 'expected exactly one A row'
FROM party.party WHERE tenant_id = '00000000-0000-0000-0000-000000000001';
INSERT INTO rls_test_result
SELECT 'A cannot see B', count(*) = 0, 'expected zero B rows'
FROM party.party WHERE tenant_id = '00000000-0000-0000-0000-000000000002';

SELECT set_config('app.tenant_id', '00000000-0000-0000-0000-000000000002', true);
INSERT INTO rls_test_result
SELECT 'B sees B', count(*) = 1, 'expected exactly one B row'
FROM party.party WHERE tenant_id = '00000000-0000-0000-0000-000000000002';
INSERT INTO rls_test_result
SELECT 'B cannot see A', count(*) = 0, 'expected zero A rows'
FROM party.party WHERE tenant_id = '00000000-0000-0000-0000-000000000001';

UPDATE party.party SET legal_name = 'CROSS TENANT FORBIDDEN'
WHERE tenant_id = '00000000-0000-0000-0000-000000000001';
IF FOUND THEN RAISE EXCEPTION 'FAIL: cross-tenant update affected a row'; END IF;

BEGIN
  INSERT INTO party.party (id, tenant_id, type, legal_name, tax_id)
  VALUES ('30000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000001','CUSTOMER','CROSS TENANT FORBIDDEN','FORBIDDEN');
  RAISE EXCEPTION 'FAIL: cross-tenant insert was accepted';
EXCEPTION WHEN insufficient_privilege THEN
  NULL;
END;

SELECT set_config('app.tenant_id', '', true);
BEGIN
  INSERT INTO party.party (id, tenant_id, type, legal_name, tax_id)
  VALUES ('40000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000002','CUSTOMER','NO CONTEXT','NO-CONTEXT');
  RAISE EXCEPTION 'FAIL: insert without tenant context was accepted';
EXCEPTION WHEN insufficient_privilege THEN
  NULL;
END;

IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='nexora_app' AND (rolsuper OR rolbypassrls OR rolcreaterole OR rolcreatedb))
THEN RAISE EXCEPTION 'FAIL: nexora_app has forbidden administrative privileges'; END IF;

IF EXISTS (
  SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname IN ('party','fleet','transport','compliance','evidence','audit','event','integration')
    AND c.relrowsecurity IS NOT TRUE
)
THEN RAISE EXCEPTION 'FAIL: a tenant-scoped table has RLS disabled'; END IF;

SELECT * FROM rls_test_result ORDER BY name;
ROLLBACK;
