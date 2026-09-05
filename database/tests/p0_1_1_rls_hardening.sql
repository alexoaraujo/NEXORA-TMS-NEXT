\set ON_ERROR_STOP on

-- Execute as nexora_app (not the migration/owner role) against an isolated database.
-- P0.1 owns behavioral tenant-isolation fixtures; this suite validates the
-- application role, RLS metadata, FORCE RLS, and canonical policies.

BEGIN;

DO $$
DECLARE
  required_tables text[] := ARRAY[
    'party.party',
    'party.carrier',
    'fleet.driver',
    'fleet.vehicle',
    'transport.order',
    'transport.shipment',
    'transport.operation',
    'transport.trip',
    'compliance.case',
    'evidence.package',
    'evidence.item',
    'audit.event',
    'event.outbox',
    'integration.idempotency_key'
  ];
  qualified_name text;
  schema_name text;
  table_name text;
  rel record;
BEGIN
  IF current_user <> 'nexora_app' THEN
    RAISE EXCEPTION 'P0.1.1 must execute as nexora_app, current_user=%', current_user;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_roles
    WHERE rolname = 'nexora_app'
      AND (rolsuper OR rolbypassrls OR rolcreaterole OR rolcreatedb OR rolreplication OR rolcanlogin)
  ) THEN
    RAISE EXCEPTION 'nexora_app has forbidden role attributes';
  END IF;

  FOREACH qualified_name IN ARRAY required_tables LOOP
    schema_name := split_part(qualified_name, '.', 1);
    table_name := split_part(qualified_name, '.', 2);

    SELECT c.relrowsecurity, c.relforcerowsecurity
      INTO rel
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = schema_name
      AND c.relname = table_name
      AND c.relkind IN ('r', 'p');

    IF NOT FOUND THEN
      RAISE EXCEPTION 'required table does not exist: %', qualified_name;
    END IF;

    IF rel.relrowsecurity IS NOT TRUE THEN
      RAISE EXCEPTION 'RLS disabled: %', qualified_name;
    END IF;

    IF rel.relforcerowsecurity IS NOT TRUE THEN
      RAISE EXCEPTION 'FORCE RLS disabled: %', qualified_name;
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM pg_policies p
      WHERE p.schemaname = schema_name
        AND p.tablename = table_name
    ) THEN
      RAISE EXCEPTION 'no RLS policy defined: %', qualified_name;
    END IF;
  END LOOP;

  IF to_regclass('audit.audit_event') IS NOT NULL
     OR to_regclass('outbox.event') IS NOT NULL
     OR to_regclass('evidence.evidence') IS NOT NULL THEN
    RAISE EXCEPTION 'legacy competing objects are present';
  END IF;
END
$$;

SELECT
  current_user AS current_user,
  (SELECT rolsuper FROM pg_roles WHERE rolname = current_user) AS rolsuper,
  (SELECT rolbypassrls FROM pg_roles WHERE rolname = current_user) AS rolbypassrls;

ROLLBACK;
\echo 'P0.1.1 RLS hardening suite: PASS'
