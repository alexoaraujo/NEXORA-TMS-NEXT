CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS identity;
CREATE SCHEMA IF NOT EXISTS party;
CREATE SCHEMA IF NOT EXISTS fleet;
CREATE SCHEMA IF NOT EXISTS transport;
CREATE SCHEMA IF NOT EXISTS regulatory;
CREATE SCHEMA IF NOT EXISTS compliance;
CREATE SCHEMA IF NOT EXISTS evidence;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS event;
CREATE SCHEMA IF NOT EXISTS integration;

CREATE TABLE identity.tenant (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(200) NOT NULL,
  status varchar(30) NOT NULL DEFAULT 'ACTIVE',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE regulatory.authority (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(50) NOT NULL UNIQUE,
  name varchar(255) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE regulatory.source (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  authority_id uuid NOT NULL REFERENCES regulatory.authority(id),
  title varchar(500),
  source_uri text NOT NULL,
  publication_date timestamptz,
  retrieved_at timestamptz NOT NULL DEFAULT now(),
  content_hash varchar(128),
  status varchar(30) NOT NULL DEFAULT 'ACTIVE'
);

CREATE TABLE regulatory.rule (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  authority_id uuid NOT NULL REFERENCES regulatory.authority(id),
  code varchar(100) NOT NULL,
  name varchar(255) NOT NULL,
  domain varchar(100) NOT NULL,
  severity varchar(30) NOT NULL,
  status varchar(30) NOT NULL DEFAULT 'DRAFT',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (authority_id, code)
);

CREATE TABLE regulatory.rule_version (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_id uuid NOT NULL REFERENCES regulatory.rule(id),
  version varchar(50) NOT NULL,
  effective_from timestamptz NOT NULL,
  effective_until timestamptz,
  definition jsonb NOT NULL,
  parameters jsonb NOT NULL DEFAULT '{}'::jsonb,
  source_id uuid REFERENCES regulatory.source(id),
  source_hash varchar(128),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (rule_id, version),
  CHECK (effective_until IS NULL OR effective_until > effective_from)
);

CREATE TABLE party.party (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  type varchar(30) NOT NULL,
  legal_name varchar(255) NOT NULL,
  trade_name varchar(255),
  tax_id varchar(32),
  status varchar(30) NOT NULL DEFAULT 'ACTIVE',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, tax_id)
);

CREATE TABLE party.carrier (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  party_id uuid NOT NULL REFERENCES party.party(id),
  status varchar(30) NOT NULL DEFAULT 'ACTIVE',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, party_id)
);

CREATE TABLE fleet.driver (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  party_id uuid REFERENCES party.party(id),
  license_number varchar(50) NOT NULL,
  license_category varchar(20),
  status varchar(30) NOT NULL DEFAULT 'ACTIVE',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, license_number)
);

CREATE TABLE fleet.vehicle (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  carrier_id uuid REFERENCES party.carrier(id),
  plate varchar(10) NOT NULL,
  renavam varchar(30),
  vehicle_type varchar(50) NOT NULL,
  capacity_kg numeric(14,3),
  status varchar(30) NOT NULL DEFAULT 'ACTIVE',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, plate),
  CHECK (capacity_kg IS NULL OR capacity_kg >= 0)
);

CREATE TABLE transport.order (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  customer_id uuid REFERENCES party.party(id),
  origin_city varchar(150) NOT NULL,
  origin_state varchar(2) NOT NULL,
  destination_city varchar(150) NOT NULL,
  destination_state varchar(2) NOT NULL,
  status varchar(30) NOT NULL DEFAULT 'DRAFT',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE transport.shipment (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  order_id uuid NOT NULL REFERENCES transport.order(id),
  status varchar(30) NOT NULL DEFAULT 'PLANNED',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE transport.operation (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  shipment_id uuid NOT NULL REFERENCES transport.shipment(id),
  carrier_id uuid REFERENCES party.carrier(id),
  driver_id uuid REFERENCES fleet.driver(id),
  vehicle_id uuid REFERENCES fleet.vehicle(id),
  status varchar(40) NOT NULL DEFAULT 'DRAFT',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE transport.trip (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  operation_id uuid NOT NULL REFERENCES transport.operation(id),
  status varchar(40) NOT NULL DEFAULT 'DRAFT',
  planned_departure_at timestamptz,
  actual_departure_at timestamptz,
  planned_arrival_at timestamptz,
  actual_arrival_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE compliance.case (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  subject_type varchar(100) NOT NULL,
  subject_id uuid NOT NULL,
  status varchar(30) NOT NULL DEFAULT 'PENDING',
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);

CREATE TABLE compliance.check (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES compliance.case(id),
  rule_version_id uuid NOT NULL REFERENCES regulatory.rule_version(id),
  result varchar(30) NOT NULL,
  severity varchar(30),
  input_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  output_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  checked_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE evidence.package (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  subject_type varchar(100) NOT NULL,
  subject_id uuid NOT NULL,
  verification_status varchar(30) NOT NULL DEFAULT 'NOT_VERIFIED',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE evidence.item (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  package_id uuid NOT NULL REFERENCES evidence.package(id),
  evidence_type varchar(100) NOT NULL,
  source_type varchar(100),
  source_uri text,
  content_hash varchar(128),
  captured_at timestamptz NOT NULL DEFAULT now(),
  verification_status varchar(30) NOT NULL DEFAULT 'NOT_VERIFIED',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE audit.event (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES identity.tenant(id),
  actor_type varchar(50),
  actor_id uuid,
  action varchar(100) NOT NULL,
  entity_type varchar(100) NOT NULL,
  entity_id uuid,
  before_state jsonb,
  after_state jsonb,
  correlation_id uuid,
  causation_id uuid,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE event.outbox (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES identity.tenant(id),
  event_type varchar(200) NOT NULL,
  aggregate_type varchar(100) NOT NULL,
  aggregate_id uuid NOT NULL,
  event_version integer NOT NULL DEFAULT 1,
  payload jsonb NOT NULL,
  correlation_id uuid,
  causation_id uuid,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz,
  attempt_count integer NOT NULL DEFAULT 0,
  last_error text
);

CREATE TABLE integration.idempotency_key (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES identity.tenant(id),
  key varchar(255) NOT NULL,
  endpoint varchar(255) NOT NULL,
  request_hash varchar(128) NOT NULL,
  response_status integer,
  response_body jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  UNIQUE (tenant_id, key, endpoint)
);

CREATE INDEX idx_outbox_unpublished ON event.outbox (occurred_at) WHERE published_at IS NULL;
CREATE INDEX idx_audit_entity ON audit.event (tenant_id, entity_type, entity_id, occurred_at);
CREATE INDEX idx_compliance_subject ON compliance.case (tenant_id, subject_type, subject_id);
CREATE INDEX idx_rule_version_effective ON regulatory.rule_version (rule_id, effective_from, effective_until);
