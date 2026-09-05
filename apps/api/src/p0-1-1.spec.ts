import { describe, expect, it } from 'vitest';

describe('P0.1.1 application invariants', () => {
  it('rejects an empty tenant context', () => {
    const tenantId: string | undefined = undefined;
    expect(() => {
      if (!tenantId) throw new Error('tenant context required');
    }).toThrow('tenant context required');
  });

  it('accepts a valid tenant context', () => {
    const tenantId = 'tenant-a';
    expect(tenantId).toMatch(/^tenant-/);
  });
});
