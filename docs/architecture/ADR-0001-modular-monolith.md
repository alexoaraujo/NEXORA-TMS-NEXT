# ADR-0001 — Modular Monolith + Worker

## Status
Accepted for v0.1.

## Context
NEXORA TMS NEXT needs strong domain boundaries, regulatory traceability and reliable asynchronous processing without creating paid infrastructure dependencies or premature distributed-system complexity.

## Decision
Use a TypeScript modular monolith for the API and a separate persistent worker process. Both use the same domain/application modules and PostgreSQL database. Cross-module communication uses explicit application ports and domain events; asynchronous delivery uses the transactional outbox.

## Consequences
- Lower operational complexity than microservices.
- Clear bounded-context ownership remains enforceable in code.
- PostgreSQL is the durable system of record.
- Outbox enables reliable event publication without a mandatory message broker.
- A broker can be introduced later without changing domain contracts.

## Rejected for v0.1
- Mandatory Kafka/RabbitMQ deployment.
- Provider-specific business logic.
- Direct controller-to-database business rules.

## Constraints
Free/open-source/free-tier only; no paid service is required for local development, tests or core runtime behavior.
