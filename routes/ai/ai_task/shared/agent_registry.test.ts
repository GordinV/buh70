import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { buildAgentRegistry } from './agent_registry';
import { ApiClient } from './api_client';
import { AI_TASK_SERVICE_USER_ID, FINBIT_AGENT_KEYS, FINBIT_SERVICE_USER_ID, SALDOANDMIK_USER_ID } from './constants';
import { getDefaultTaskGraph, loadAgentConfig, loadOrchestratorConfig } from '../orchestrator/state.manager';

describe('Agent Registry (shared/agent_registry.ts)', () => {
  it('buildAgentRegistry должен успешно загружать манифесты известных субагентов', () => {
    const registry = buildAgentRegistry();

    expect(registry).toHaveProperty('saldoandmik');
    expect(registry).toHaveProperty('calc_arv_jaak');
    expect(registry).toHaveProperty('getEarved');
    expect(registry).toHaveProperty('check_asutus');
    expect(registry).toHaveProperty('import_earved');
    expect(registry).toHaveProperty('sendFinBitReport');
    expect(registry).toHaveProperty('lisa1_lisa5');
    expect(registry).toHaveProperty('schedule_monitor');
    expect(registry).toHaveProperty('read_mail');
    expect(registry).toHaveProperty('reporter');

    expect(typeof registry['saldoandmik'].dispatch).toBe('function');
    expect(typeof registry['calc_arv_jaak'].dispatch).toBe('function');
    expect(typeof registry['getEarved'].dispatch).toBe('function');
    expect(typeof registry['sendFinBitReport'].dispatch).toBe('function');
    expect(typeof registry['lisa1_lisa5'].dispatch).toBe('function');
    expect(typeof registry['schedule_monitor'].dispatch).toBe('function');
    expect(typeof registry['read_mail'].dispatch).toBe('function');
    expect(typeof registry['reporter'].dispatch).toBe('function');

    // Служебный schedule_monitor не должен попадать в DAG задач
    const graph = getDefaultTaskGraph();
    expect(graph).not.toHaveProperty('schedule_monitor');
    expect(graph).toHaveProperty('read_mail');
    expect(graph).toHaveProperty('reporter');
  });

  it('sendFinBitReport manifest должен определять resolveParentParams и извлекать log_id родителя import_earved (лог импорта docs.sp_loe_earved)', () => {
    const registry = buildAgentRegistry();
    const manifest = registry['sendFinBitReport'];

    expect(typeof manifest.resolveParentParams).toBe('function');

    const stateWithParent = {
      tasks: {
        import_earved: { log_id: 998877 },
        getEarved: { log_id: 111 },
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

  it('buildAgentRegistry выводит предупреждение, если agent.js существует, но не загружается, и не добавляет его в реестр', () => {
    const tmpRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'ai_task_registry_'));
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
    try {
      // Каталог с ломающимся при загрузке agent.js
      fs.mkdirSync(path.join(tmpRoot, 'broken_agent'));
      fs.writeFileSync(
        path.join(tmpRoot, 'broken_agent', 'agent.js'),
        "throw new Error('boom while loading broken_agent');\n",
        'utf-8'
      );
      // Исправный агент рядом — должен загрузиться
      fs.mkdirSync(path.join(tmpRoot, 'good_agent'));
      fs.writeFileSync(
        path.join(tmpRoot, 'good_agent', 'agent.js'),
        'module.exports = { manifest: { dispatch: async () => 777 } };\n',
        'utf-8'
      );
      // Каталог без файла агента — пропускается молча
      fs.mkdirSync(path.join(tmpRoot, 'no_agent_file'));

      const registry = buildAgentRegistry(tmpRoot);

      expect(registry).not.toHaveProperty('broken_agent');
      expect(registry).not.toHaveProperty('no_agent_file');
      expect(registry).toHaveProperty('good_agent');

      const warnMessages = warnSpy.mock.calls.map((c) => String(c[0]));
      const brokenWarn = warnMessages.filter((m) => m.includes('broken_agent'));
      expect(brokenWarn).toHaveLength(1);
      expect(brokenWarn[0]).toContain('boom while loading broken_agent');
      // Отсутствующий файл агента предупреждений не даёт
      expect(warnMessages.some((m) => m.includes('no_agent_file'))).toBe(false);
    } finally {
      warnSpy.mockRestore();
      fs.rmSync(tmpRoot, { recursive: true, force: true });
    }
  });

  it('фиктивный агент во временном каталоге автоматически попадает в getDefaultTaskGraph и buildAgentRegistry', async () => {
    const tmpRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'ai_task_dummy_agent_'));
    try {
      const dummyDir = path.join(tmpRoot, 'dummy_agent');
      fs.mkdirSync(dummyDir);
      fs.writeFileSync(
        path.join(dummyDir, 'config.json'),
        JSON.stringify(
          {
            name: 'dummy_agent',
            flow: 'dummy.sp_test',
            depends_on: ['getEarved'],
            allow_parallel: true,
            schedule: { time: '09:30' },
            prompt: null,
            params: { customFlag: true },
          },
          null,
          2
        ),
        'utf-8'
      );
      fs.writeFileSync(
        path.join(dummyDir, 'agent.js'),
        'module.exports = { manifest: { dispatch: async (ctx) => (ctx.params && ctx.params.customFlag ? 4242 : 0) } };\n',
        'utf-8'
      );

      const graph = getDefaultTaskGraph(tmpRoot);
      expect(graph).toHaveProperty('dummy_agent');
      expect(graph.dummy_agent.flow).toBe('dummy.sp_test');
      expect(graph.dummy_agent.depends_on).toEqual(['getEarved']);
      expect(graph.dummy_agent.schedule).toEqual({ time: '09:30' });
      expect(graph.dummy_agent.params).toEqual({ customFlag: true, userId: AI_TASK_SERVICE_USER_ID, rekvId: 63 });

      const registry = buildAgentRegistry(tmpRoot);
      expect(registry).toHaveProperty('dummy_agent');
      const logId = await registry['dummy_agent'].dispatch({
        key: 'dummy_agent',
        userId: 1,
        rekvId: 2,
        kond: 3,
        params: graph.dummy_agent.params,
        apiClient: {} as ApiClient,
      });
      expect(logId).toBe(4242);
    } finally {
      fs.rmSync(tmpRoot, { recursive: true, force: true });
    }
  });

  it('все субагенты в config.json и orchestrator/config.json используют AI_TASK_SERVICE_USER_ID (11770), кроме saldoandmik (2477), а description getEarved не содержит userId', () => {
    const registryKeys = Object.keys(buildAgentRegistry());
    expect(registryKeys.length).toBeGreaterThanOrEqual(FINBIT_AGENT_KEYS.length);

    for (const agentKey of registryKeys) {
      const cfg = loadAgentConfig(agentKey);
      if (cfg?.params?.userId !== undefined) {
        const expectedUid = agentKey === 'saldoandmik' ? SALDOANDMIK_USER_ID : AI_TASK_SERVICE_USER_ID;
        expect(cfg.params.userId).toBe(expectedUid);
      }
    }

    for (const agentKey of Object.keys(getDefaultTaskGraph())) {
      const cfg = loadAgentConfig(agentKey);
      expect(cfg).not.toBeNull();
      if (cfg?.params?.userId !== undefined) {
        const expectedUid = agentKey === 'saldoandmik' ? SALDOANDMIK_USER_ID : AI_TASK_SERVICE_USER_ID;
        expect(cfg.params.userId).toBe(expectedUid);
      }
    }

    for (const agentKey of FINBIT_AGENT_KEYS) {
      const cfg = loadAgentConfig(agentKey);
      expect(cfg?.params?.userId).toBe(FINBIT_SERVICE_USER_ID);
    }

    const orchestratorCfg = loadOrchestratorConfig();
    expect(orchestratorCfg.params?.userId).toBe(AI_TASK_SERVICE_USER_ID);

    const getEarvedCfg = loadAgentConfig('getEarved');
    expect(getEarvedCfg?.description || '').not.toContain(String(AI_TASK_SERVICE_USER_ID));
  });
});
