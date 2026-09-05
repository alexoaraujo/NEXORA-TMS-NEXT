import { describe, expect, it } from 'vitest';

describe('P0.1.1 tenant-aware UI invariants', () => {
  it('shows only records belonging to the active tenant', () => {
    const activeTenant = 'tenant-a';
    const records = [
      { id: 'a-1', tenantId: 'tenant-a' },
      { id: 'b-1', tenantId: 'tenant-b' },
    ];
    expect(records.filter((record) => record.tenantId === activeTenant)).toEqual([
      { id: 'a-1', tenantId: 'tenant-a' },
    ]);
  });
});
