# NEXORA TMS NEXT — Implementation Blueprint v0.1

## Baseline

Phase 5 converts the Phase 4 contracts into an implementation plan for the first vertical slice. The repository is intentionally a modular monolith with a persistent worker and a shared PostgreSQL boundary.

## Source hierarchy

1. PEOS v1.2 governance and approved prompts.
2. Phase 2 regulatory requirements matrix.
3. Phase 3 domain/bounded-context specification.
4. Phase 4 PostgreSQL/API/event contracts.
5. Existing `alexoaraujo/nexora-tms` implementation, reused only where compatible and evidenced.
6. This blueprint and ADRs.

## Repository topology

```text
.
├── AGENTS.md
├── apps/
│   ├── api/                 # NestJS HTTP API
│   ├── web/                 # Next.js web application
│   └── worker/              # Outbox/compliance/integration workers
├── packages/
│   ├── contracts/           # DTO/event schemas shared by apps
│   ├── domain/              # Domain types and value objects
│   └── config/              # Validated runtime configuration
├── database/
│   ├── migrations/          # Ordered SQL migrations
│   └── seeds/                # Only sourced/verified regulatory seeds
├── docs/
│   ├── architecture/
│   ├── api/
│   ├── events/
│   └── operations/
├── .github/workflows/
└── turbo.json
```

## First vertical slice

`create operation -> create trip -> run compliance -> persist rule version + evidence -> PASS/BLOCKED -> release gate -> audit -> outbox event`.

### P0 implementation order

1. Tenant context and authorization boundary.
2. Regulatory authority/source/rule/rule_version.
3. Party/carrier/driver/vehicle.
4. Order/shipment/operation/trip.
5. Compliance case/check/decision.
6. Evidence package/item.
7. Audit event.
8. Outbox + idempotency.
9. REST/OpenAPI contracts.
10. Worker publication and retry.
11. Web release-gate UI.
12. CI quality/security/contract gates.

## Module boundaries

Controllers depend on application services. Application services depend on domain ports. Infrastructure implements persistence/integration ports. Domain code must not import framework adapters.

## Regulatory rule execution

A rule evaluation must record:
- authority
- rule identifier
- exact rule version
- effective period
- input snapshot
- output/result
- evidence references
- evaluation timestamp

No normative value is hard-coded without a source reference and verification status.

## Evidence-first release gate

A trip can be released only when mandatory checks are `PASS` and required evidence is present. `WARNING`, `BLOCKED`, `EXPIRED`, `PENDING` and `NOT_VERIFIED` never silently become PASS.

## Free-only constraint

No paid proprietary service is a required runtime dependency. PostgreSQL, Node.js, TypeScript, NestJS, Next.js, Turborepo, Playwright, OpenTelemetry, Prometheus and Grafana are the baseline technology choices. Hosted free tiers may be used, but application contracts must remain portable.

## Reuse from legacy repository

The existing `alexoaraujo/nexora-tms` already demonstrates a monorepo with Web/API/Worker, CI gates, Neon PostgreSQL and the same Node/pnpm baseline. Its implementation is treated as reference material, not as an implicit source of truth. The new repository must preserve only behavior proven compatible with the Phase 2–4 contracts.

## Definition of Done

A P0 item is done only with code + tests + contract + evidence + security check + documentation + rollback/recovery notes. A green build or deployment is not sufficient functional evidence.
