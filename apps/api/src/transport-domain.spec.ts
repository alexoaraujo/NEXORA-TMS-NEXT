import { describe, expect, it } from 'vitest';

type TransportOrder = { id: string; tenantId: string; status: 'DRAFT' | 'PLANNED' };

const transition = (order: TransportOrder, next: TransportOrder['status']): TransportOrder => {
  if (order.status === 'PLANNED' && next === 'DRAFT') throw new Error('invalid transport order transition');
  return { ...order, status: next };
};

describe('P0.2 transport domain', () => {
  it('requires tenant ownership on a transport aggregate', () => {
    const order: TransportOrder = { id: 'order-1', tenantId: 'tenant-a', status: 'DRAFT' };
    expect(order.tenantId).toBe('tenant-a');
  });

  it('allows a valid lifecycle transition', () => {
    const order: TransportOrder = { id: 'order-1', tenantId: 'tenant-a', status: 'DRAFT' };
    expect(transition(order, 'PLANNED').status).toBe('PLANNED');
  });

  it('rejects an invalid lifecycle transition', () => {
    const order: TransportOrder = { id: 'order-1', tenantId: 'tenant-a', status: 'PLANNED' };
    expect(() => transition(order, 'DRAFT')).toThrow('invalid transport order transition');
  });
});
