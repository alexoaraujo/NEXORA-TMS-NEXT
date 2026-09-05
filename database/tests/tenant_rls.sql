-- P0.1 acceptance test script.
-- Execute against an isolated test database after migrations 0001 and 0002.
-- The assertions intentionally test both visibility and write protection.

BEGIN;

INSERT INTO identity.tenant (id, name) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Tenant A'),
  ('00000000-0000-0000-0000-000000000002', 'Tenant B');

SELECT set_config('app.tenant_id', '00000000-0000-0000-0000-000000000001', true);
INSERT INTO party.party (tenant_id, type, legal_name, tax_id)
VALUES ('00000000-0000-0000-0000-000000000001', 'CUSTOMER', 'A Test', 'A-TEST');

SELECT set_config('app.tenant_id', '00000000-0000-0000-0000-000000000002', true);
INSERT INTO party.party (tenant_id, type, legal_name, tax_id)
VALUES ('00000000-0000-0000-0000-000000000002', 'CUSTOMER', 'B Test', 'B-TEST');

-- Cross-tenant read must return only Tenant B's row.
SELECT count(*) AS visible_rows FROM party.party;
-- Expected: 1

-- Cross-tenant direct update must affect zero rows.
UPDATE party.party
SET legal_name = 'MUST NOT CHANGE'
WHERE tenant_id = '00000000-0000-0000-0000-000000000001';
-- Expected: UPDATE 0

-- A write claiming Tenant A while context is Tenant B must be rejected by WITH CHECK.
DO $$
BEGIN
  BEGIN
    INSERT INTO party.party (tenant_id, type, legal_name, tax_id)
    VALUES ('00000000-0000-0000-0000-000000000001', 'CUSTOMER', 'FORBIDDEN', 'FORBIDDEN');
    RAISE EXCEPTION 'FAIL: cross-tenant insert was accepted';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END $$;

-- Missing context must reject tenant-owned writes.
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
END $$;

ROLLBACK;
