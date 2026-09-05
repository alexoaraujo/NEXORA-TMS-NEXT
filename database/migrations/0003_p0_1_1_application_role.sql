BEGIN;

-- Runtime application role. The CI test login (nexora_runtime_test) is a
-- Neon-managed login role and may carry BYPASSRLS; it must SET ROLE to this
-- non-login application role before exercising tenant isolation.
DO $role$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'nexora_app') THEN
    CREATE ROLE nexora_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
  ELSE
    ALTER ROLE nexora_app NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
  END IF;
END
$role$;

COMMIT;
