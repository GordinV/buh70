import { buildAgentRegistry } from './agent_registry';
import { ApiClient } from './api_client';

describe('Agent Registry (shared/agent_registry.ts)', () => {
  it('buildAgentRegistry должен успешно загружать манифесты известных субагентов', () => {
    const registry = buildAgentRegistry();

    expect(registry).toHaveProperty('saldoandmik');
    expect(registry).toHaveProperty('calc_arv_jaak');
    expect(registry).toHaveProperty('getEarved');
    expect(registry).toHaveProperty('sendFinBitReport');
    expect(registry).toHaveProperty('lisa1_lisa5');
    expect(registry).toHaveProperty('schedule_monitor');

    expect(typeof registry['saldoandmik'].dispatch).toBe('function');
    expect(typeof registry['calc_arv_jaak'].dispatch).toBe('function');
    expect(typeof registry['getEarved'].dispatch).toBe('function');
    expect(typeof registry['sendFinBitReport'].dispatch).toBe('function');
    expect(typeof registry['lisa1_lisa5'].dispatch).toBe('function');
    expect(typeof registry['schedule_monitor'].dispatch).toBe('function');
  });

  it('sendFinBitReport manifest должен определять resolveParentParams и извлекать log_id родителя getEarved', () => {
    const registry = buildAgentRegistry();
    const manifest = registry['sendFinBitReport'];

    expect(typeof manifest.resolveParentParams).toBe('function');

    const stateWithParent = {
      tasks: {
        getEarved: { log_id: 998877 },
      },
    };
    const params = manifest.resolveParentParams!(stateWithParent as any);
    expect(params).toEqual({ logId: 998877 });

    const stateWithoutParent = {
      tasks: {},
    };
    const emptyParams = manifest.resolveParentParams!(stateWithoutParent as any);
    expect(emptyParams).toEqual({});
  });

  it('buildAgentRegistry должен поддерживать overrides манифестов для тестов', async () => {
    let capturedCtx: any = null;
    const testManifest = {
      dispatch: async (ctx: any) => {
        capturedCtx = ctx;
        return 12345;
      },
    };

    const registry = buildAgentRegistry(undefined, {
      custom_task: testManifest,
    });

    expect(registry).toHaveProperty('custom_task');
    const logId = await registry['custom_task'].dispatch({
      key: 'custom_task',
      userId: 1,
      rekvId: 2,
      kond: 3,
      params: { foo: 'bar' },
      apiClient: {} as ApiClient,
    });

    expect(logId).toBe(12345);
    expect(capturedCtx.params).toEqual({ foo: 'bar' });
  });
});
