import { describe, expect, it } from 'vitest';
import {
  getTenantContext,
  getTenantId,
  runWithTenantContext,
} from './tenant-context';

describe('TenantContext', () => {
  it('isolates concurrent async execution contexts', async () => {
    const a = runWithTenantContext(
      { tenantId: 'tenant-a', principalId: 'user-a', roles: ['dispatcher'] },
      async () => {
        await Promise.resolve();
        return getTenantId();
      },
    );
    const b = runWithTenantContext(
      { tenantId: 'tenant-b', principalId: 'user-b', roles: ['auditor'] },
      async () => {
        await Promise.resolve();
        return getTenantContext().tenantId;
      },
    );

    await expect(a).resolves.toBe('tenant-a');
    await expect(b).resolves.toBe('tenant-b');
  });

  it('rejects access without an initialized context', () => {
    expect(() => getTenantContext()).toThrow('tenant context is not initialized');
  });

  it('rejects incomplete context', () => {
    expect(() =>
      runWithTenantContext(
        { tenantId: '', principalId: 'user-a', roles: [] },
        () => 'never',
      ),
    ).toThrow('tenant context requires tenantId and principalId');
  });
});
