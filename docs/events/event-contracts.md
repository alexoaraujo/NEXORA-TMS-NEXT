# Event Contracts v0.1

All events are versioned and emitted through the transactional outbox.

## Envelope

```json
{
  "id": "uuid",
  "type": "TripReleased",
  "version": 1,
  "occurredAt": "ISO-8601",
  "tenantId": "uuid",
  "aggregate": { "type": "Trip", "id": "uuid" },
  "correlationId": "uuid",
  "causationId": "uuid",
  "data": {}
}
```

## TripComplianceEvaluated

Data: `tripId`, `caseId`, `result`, `evidencePackageId`, `ruleVersionIds`.

## ComplianceBlocked

Data: `tripId`, `caseId`, `failedChecks[]`, `evidencePackageId`.

## TripReleased

Data: `tripId`, `operationId`, `caseId`, `evidencePackageId`.

## RegulatoryRuleVersionActivated

Data: `ruleId`, `ruleVersionId`, `authority`, `effectiveFrom`.

## Delivery guarantees

- Event persistence and aggregate mutation occur in one database transaction.
- `event.outbox.id` is the event identity.
- Consumers must be idempotent.
- Retry state is persisted.
- Ordering is defined per aggregate where required.
- No consumer assumes exactly-once delivery.
