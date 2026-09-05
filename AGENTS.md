# NEXORA TMS NEXT — Agent Engineering Contract

## Governing layer
PEOS is the engineering governance layer for this repository. Use the approved PEOS prompt library and follow Evidence-First execution.

## Mandatory rules
1. Inspect the repository and available evidence before making conclusions.
2. Do not invent missing configuration, credentials, environments, services, tests, or deployment state.
3. Classify relevant statements as confirmed, inferred, recommended, or not verified.
4. For every material change, define objective, scope, constraints, acceptance criteria, tests, risks, and rollback.
5. Prefer small, reversible, reviewable changes.
6. Never modify production data or infrastructure as part of an experimental change.
7. Keep secrets out of source control, logs, prompts, issues, and documentation.
8. Do not declare success because a file exists, a build starts, a pipeline runs, or an HTTP 200 is returned; validate behavior against acceptance criteria.
9. Changes should be traceable to Jira work and, where applicable, an architecture decision documented in Confluence.
10. Before release, apply the PEOS release and production-readiness gates.

## Approved PEOS prompt families
- 0021 Evidence-First Execution
- 0022 Source of Truth Discovery
- 0023 Change Impact Mapping
- 0024 Technical Environment Qualification
- 0025 P0/P1/P2 Plan with Gates
- 0026 Technical Handoff
- 0028 Production Readiness Review
- 3501 AGENTS.md
- 3502 Repository Instructions
- 3505 Coding Agent Task Specification
- 3506 Agentic Code Review
- 3509 Agentic Test Generation
- 3510 Agentic Repository Audit
- 3511 Multi-Agent Engineering Workflow
- 3512 AI Coding Change Validation

## NEXORA system of record boundaries
- GitHub: source code, branches, commits, pull requests, CI/CD and repository governance.
- Neon: PostgreSQL data and database environments.
- Jira: planned and executed work.
- Confluence: architecture, ADRs, specifications, operational knowledge and runbooks.
- PEOS: engineering prompts, agent rules, gates and governance.

## Environment model
Neon environments are Development, Staging and Production. Preview branches must be isolated from production and use appropriate test/anonymous data.

## Change workflow
Requirement -> Jira -> Architecture/ADR when needed -> Git branch -> implementation -> tests -> PR -> review -> quality gates -> staging -> release gate -> production -> evidence.
