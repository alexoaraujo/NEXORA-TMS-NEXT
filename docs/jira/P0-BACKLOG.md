# NEXORA TMS NEXT — P0 Backlog v0.1

> This is the implementation-ready backlog. The connected Atlassian workspace currently exposes the generic `SCRUM` project; do not create NEXORA issues there until a dedicated project/key is confirmed.

## Epic P0-FOUNDATION
- NXT-P0-001 Repository bootstrap and workspace
- NXT-P0-002 Runtime configuration and environment contract
- NXT-P0-003 Tenant context + authorization boundary
- NXT-P0-004 Database migration runner
- NXT-P0-005 CI quality gates

## Epic P0-TRANSPORT
- NXT-P0-010 Party and carrier
- NXT-P0-011 Driver and vehicle
- NXT-P0-012 Order and shipment
- NXT-P0-013 Transport operation
- NXT-P0-014 Trip lifecycle

## Epic P0-REGULATORY
- NXT-P0-020 Authority and source
- NXT-P0-021 Regulatory rule
- NXT-P0-022 Rule version and effective period
- NXT-P0-023 Rule evaluation port

## Epic P0-COMPLIANCE
- NXT-P0-030 Compliance case
- NXT-P0-031 Compliance checks
- NXT-P0-032 PASS/WARNING/BLOCKED decision
- NXT-P0-033 Release gate

## Epic P0-EVIDENCE
- NXT-P0-040 Evidence package
- NXT-P0-041 Evidence item and hash
- NXT-P0-042 Evidence verification status
- NXT-P0-043 Audit event

## Epic P0-EVENTS
- NXT-P0-050 Transactional outbox
- NXT-P0-051 Outbox worker/retry
- NXT-P0-052 Idempotency key store
- NXT-P0-053 Event contract tests

## Epic P0-API
- NXT-P0-060 Operations API
- NXT-P0-061 Compliance API
- NXT-P0-062 Release API
- NXT-P0-063 Regulatory API
- NXT-P0-064 Evidence API

## Epic P0-SECURITY
- NXT-P0-070 RLS policies
- NXT-P0-071 RBAC enforcement
- NXT-P0-072 Secrets and dependency hygiene
- NXT-P0-073 Security test gate

## Acceptance gate for every P0 story
- Given/When/Then acceptance criteria exist.
- Unit/integration/contract/E2E tests are selected at the correct layer.
- Evidence of execution is recorded.
- No known regression is introduced.
- Rollback/recovery is documented for material changes.
- Regulatory claims cite authoritative evidence or are explicitly NOT VERIFIED.
