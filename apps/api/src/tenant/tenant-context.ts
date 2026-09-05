import { AsyncLocalStorage } from 'node:async_hooks';

export type TenantContext = Readonly<{
  tenantId: string;
  principalId: string;
  roles: readonly string[];
}>;

const storage = new AsyncLocalStorage<TenantContext>();

export function runWithTenantContext<T>(context: TenantContext, callback: () => T): T {
  if (!context.tenantId || !context.principalId) {
    throw new Error('tenant context requires tenantId and principalId');
  }
  return storage.run(context, callback);
}

export function getTenantContext(): TenantContext {
  const context = storage.getStore();
  if (!context) throw new Error('tenant context is not initialized');
  return context;
}

export function getTenantId(): string {
  return getTenantContext().tenantId;
}
