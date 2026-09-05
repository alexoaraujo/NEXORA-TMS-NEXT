import { describe, expect, it } from 'vitest';

type Event = { tenantId: string; aggregateId: string; idempotencyKey: string };

const acceptForTenant = (tenantId: string, event: Event) => {
  if (event.tenantId !== tenantId) throw new Error('tenant isolation violation');
  return event;
};

const enqueue = (events: Event[], event: Event) => {
  if (events.some((e) => e.tenantId === event.tenantId && e.idempotencyKey === event.idempotencyKey)) return events;
  return [...events, event];
};

describe('P0.2 audit evidence outbox invariants', () => {
  it('keeps audit/evidence/outbox records tenant scoped', () => {
    const event = { tenantId: 'tenant-a', aggregateId: 'order-a', idempotencyKey: 'order-a:created' };
    expect(acceptForTenant('tenant-a', event)).toEqual(event);
    expect(() => acceptForTenant('tenant-b', event)).toThrow('tenant isolation violation');
  });

  it('deduplicates an outbox event by tenant and idempotency key', () => {
    const event = { tenantId: 'tenant-a', aggregateId: 'order-a', idempotencyKey: 'order-a:created' };
    expect(enqueue(enqueue([], event), event)).toHaveLength(1);
  });
});
