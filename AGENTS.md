# NEXORA TMS NEXT — Agent Engineering Contract

## Governing layer
PEOS v1.2 is the engineering governance layer. Execute Evidence-First and use the approved prompt families for the task.

## Source of truth hierarchy
1. PEOS governance and applicable prompt.
2. Phase 2 regulatory requirements matrix.
3. Phase 3 domain/bounded-context specification.
4. Phase 4 PostgreSQL/API/event contracts.
5. This repository's `docs/architecture/` ADRs and blueprint.
6. Existing legacy repositories only as reference evidence.

## Mandatory rules
1. Inspect the repository and available evidence before making conclusions.
2. Do not invent missing configuration, credentials, environments, services, tests, regulatory obligations or deployment state.
3. Classify relevant statements as CONFIRMED, INFERRED, RECOMMENDED or NOT VERIFIED.
4. Regulatory claims require authoritative source + rule version + effective period.
5. For every material change define objective, scope, constraints, acceptance criteria, tests, risks and rollback.
6. Prefer small, reversible, reviewable changes.
7. Never modify production data or infrastructure as an experimental change.
8. Keep secrets out of source control, logs, prompts, issues and documentation.
9. A file existing, a build passing, a pipeline running, a deployment succeeding, or HTTP 200 is not sufficient functional evidence.
10. Every P0 change must have reproducible validation evidence.
11. Preserve tenant isolation. Client-provided `tenant_id` is never an authorization boundary.
12. Domain mutations and their outbox events must be transactionally consistent.
13. Mutating operations that can be replayed must use persisted idempotency semantics.
14. Audit and evidence history must not be rewritten to hide failures.
15. No paid/proprietary service is a mandatory runtime dependency. Prefer open-source/free-tier components.

## Approved PEOS prompt families
- 0021 Evidence-First Execution
- 0022 Source of Truth Discovery
- 0023 Change Impact Mapping
- 0024 Technical Environment Qualification
- 0025 P0/P1/P2 Plan with Gates
- 0028 Production Readiness Review
- 0502 End-to-End Feature Implementation
- 0504 Monorepo
- 0601 Design REST API
- 0602 OpenAPI / Swagger
- 0612 Idempotency Keys
- 0617 API Contract Testing
- 0701 Relational Modeling
- 0702 PostgreSQL Schema Design
- 0705 Safe Migrations
- 3102 Compliance Mapping
- 3208 Outbox Pattern
- 3211 Ordering, Deduplication and Idempotency
- 3301 IAM Architecture
- 3303 OpenID Connect
- 3307 RBAC Design
- 3501 AGENTS.md
- 3502 Repository Instructions
- 3505 Coding Agent Task Specification
- 3506 Agentic Code Review
- 3509 Agentic Test Generation
- 3510 Agentic Repository Audit
- 3511 Multi-Agent Engineering Workflow
- 3512 AI Coding Change Validation

## System-of-record boundaries
- GitHub: source code, branches, commits, PRs, CI/CD and repository governance.
- Neon: PostgreSQL data and database environments.
- Jira: planned/executed work and acceptance evidence.
- Confluence: architecture, ADRs, specifications and runbooks when available.
- PEOS: prompts, agent rules, gates and governance.

## Change workflow
Requirement → Jira → ADR/spec when needed → branch → implementation → tests → PR → review → quality gates → staging → release gate → production → evidence.

## First vertical slice
`operation → trip → compliance → rule_version → evidence → PASS/BLOCKED → release → audit → outbox`.

## Prohibited shortcuts
- No business rules implemented directly in controllers.
- No regulatory constants without source/version metadata.
- No cross-tenant query without explicit authorization design.
- No destructive production migration without checkpoint and rollback verification.
