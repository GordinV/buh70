import { ApiClient } from '../shared/api_client';
import { buildAgentRegistry } from '../shared/agent_registry';
import { checkTaskAlreadyRunToday } from '../orchestrator/orchestrator.tools';
import { isTaskScheduleReady } from '../orchestrator/orchestrator.agent';
import { getDefaultTaskGraph } from '../orchestrator/state.manager';
import {
  manifest,
  parseAriregisterSyncResult,
  runAriregisterSyncSubagent,
} from './agent';
import { startAriregisterSync } from './tools';

function makeMockApiClient(
  postImpl: jest.Mock,
  inforegisterHash = 'sync-secret-hash'
): ApiClient {
  return {
    getConfig: () => ({
      baseUrl: 'http://localhost:3000',
      token: 'test-token',
      inforegisterHash,
    }),
    post: postImpl,
    get: jest.fn(),
  } as unknown as ApiClient;
}

describe('Субагент ariregister_sync', () => {
  const prevEnvHash = process.env.INFOREGISTER_HASH;

  afterEach(() => {
    if (prevEnvHash === undefined) {
      delete process.env.INFOREGISTER_HASH;
    } else {
      process.env.INFOREGISTER_HASH = prevEnvHash;
    }
  });

  test('(а) payload содержит hash из env/config и отправляется на /task/syncAriregister/', async () => {
    const postMock = jest.fn().mockResolvedValue({
      status: 200,
      result: 1,
      log_id: 501,
      data: { status: 'STARTED', log_id: 501 },
      error_message: null,
    });
    const client = makeMockApiClient(postMock, 'hash-from-env');

    const res = await startAriregisterSync({ userId: 11770, rekvId: 63, dryRun: false }, client);
    expect(res.ok).toBe(true);
    expect(res.log_id).toBe(501);
    expect(postMock).toHaveBeenCalledWith(
      '/task/syncAriregister/',
      {
        user_id: 11770,
        rekv_id: 63,
        dry_run: false,
        hash: 'hash-from-env',
      },
      { allowHttpErrorResponse: true, retries: 1 }
    );
  });

  test('(б) нет INFOREGISTER_HASH -> validatePrerequisites возвращает причину SKIP и startAriregisterSync бросает до HTTP', async () => {
    delete process.env.INFOREGISTER_HASH;
    expect(manifest.validatePrerequisites()).toBe('INFOREGISTER_HASH puudub');

    process.env.INFOREGISTER_HASH = 'valid-hash';
    expect(manifest.validatePrerequisites()).toBeNull();

    const postMock = jest.fn();
    const client = makeMockApiClient(postMock, '');
    await expect(startAriregisterSync({}, client)).rejects.toThrow('INFOREGISTER_HASH puudub');
    expect(postMock).not.toHaveBeenCalled();
  });

  test('(в) 409 already_running -> не FAILED (субагент возвращает PENDING, dispatch бросает retryable ошибку)', async () => {
    const postMock = jest.fn().mockResolvedValue({
      status: 409,
      result: 0,
      log_id: null,
      data: { reason: 'already_running' },
      error_message: 'Äriregistri sünkroniseerimine juba töötab',
    });
    const client = makeMockApiClient(postMock, 'sync-hash');

    const subRes = await runAriregisterSyncSubagent({}, { apiClient: client });
    expect(subRes.status).toBe('pending');
    expect(subRes.alreadyRunning).toBe(true);
    expect(subRes.logId).toBeNull();

    let caught: (Error & { retryable?: boolean }) | null = null;
    try {
      await manifest.dispatch({
        userId: 11770,
        rekvId: 63,
        kond: 1,
        params: { userId: 11770, rekvId: 63, dryRun: false },
        apiClient: client,
      });
    } catch (e) {
      caught = e as Error & { retryable?: boolean };
    }
    expect(caught).not.toBeNull();
    expect(caught?.retryable).not.toBe(false);
  });

  test('(г) успешный лог -> resultSummary со счётчиками на эстонском', async () => {
    const postMock = jest.fn(async (endpoint: string) => {
      if (endpoint === '/task/syncAriregister/') {
        return { status: 200, result: 1, log_id: 601 };
      }
      // logs_watcher запрос логов
      return {
        result: 1,
        data: [
          {
            id: 601,
            flow: 'ariregisterSync',
            status: 'success',
            exec_start: '2026-11-18T06:00:00+02:00',
            exec_end: '2026-11-18T06:01:53+02:00',
            result: {
              file_date: '2026-11-18',
              rows_read: 381556,
              skipped: 0,
              inserted: 10,
              updated: 2,
              deleted: 1,
              total: 381556,
              duration_ms: 113000,
            },
          },
        ],
      };
    });

    const client = makeMockApiClient(postMock, 'sync-hash');
    const res = await runAriregisterSyncSubagent(
      { userId: 11770, rekvId: 63 },
      { apiClient: client, sleepFn: async () => {}, pollIntervalMs: 1, maxTimeoutMs: 1000 }
    );

    expect(res.status).toBe('success');
    expect(res.total).toBe(381556);
    expect(res.inserted).toBe(10);
    expect(res.updated).toBe(2);
    expect(res.deleted).toBe(1);
    expect(res.resultSummary).toBe('Äriregister: 381556 kirjet, +10 / ~2 / -1');

    const enriched = manifest.enrichReportStep({
      exec_start: '2026-11-18T06:00:00+02:00',
      result: { total: 381556, inserted: 10, updated: 2, deleted: 1 },
    });
    expect(enriched.resultSummary).toBe('Äriregister: 381556 kirjet, +10 / ~2 / -1');

    expect(parseAriregisterSyncResult(null).resultSummary).toBe('Äriregister: 0 kirjet, +0 / ~0 / -0');
  });

  test('(д) агент обнаруживается реестром с расписанием 06:00 и checkTaskAlreadyRunToday блокирует повтор в тот же день', async () => {
    const registry = buildAgentRegistry();
    expect(registry['ariregister_sync']).toBeDefined();

    const cfg = require('./config.json');
    expect(cfg.flow).toBe('ariregisterSync');
    expect(cfg.schedule).toEqual({ time: '06:00' });
    expect(cfg.depends_on).toEqual([]);

    const postMock = jest.fn().mockResolvedValue({
      result: 1,
      data: [
        {
          id: 602,
          flow: 'ariregisterSync',
          status: 'success',
          exec_start: '2026-11-18T06:00:05+02:00',
          exec_end: '2026-11-18T06:01:55+02:00',
        },
      ],
    });
    const client = makeMockApiClient(postMock, 'sync-hash');
    const already = await checkTaskAlreadyRunToday(11770, 'ariregisterSync', client, '2026-11-18');
    expect(already.alreadyRun).toBe(true);
    expect(already.logId).toBe(602);
  });

  test('(е) 05:30 Europe/Tallinn не запускает ariregister_sync, 06:00 запускает, и падение не блокирует FinBit', () => {
    const cfg = require('./config.json');
    // 2026-11-18 (зима, UTC+2): 05:30 Europe/Tallinn = 03:30 UTC, 06:00 Europe/Tallinn = 04:00 UTC
    const before06 = isTaskScheduleReady(cfg.schedule, new Date('2026-11-18T03:30:00.000Z'), 'Europe/Tallinn');
    expect(before06.ready).toBe(false);

    const at06 = isTaskScheduleReady(cfg.schedule, new Date('2026-11-18T04:00:00.000Z'), 'Europe/Tallinn');
    expect(at06.ready).toBe(true);
    expect(at06.shouldSkip).toBe(false);

    const graph = getDefaultTaskGraph();
    expect(graph['ariregister_sync']).toBeDefined();
    expect(graph['ariregister_sync'].depends_on).toEqual([]);
    const finbitKeys = ['getEarved', 'check_asutus', 'inforegister', 'import_earved', 'sendFinBitReport'];
    for (const k of finbitKeys) {
      expect(graph[k].depends_on).not.toContain('ariregister_sync');
      expect(graph[k].soft_depends_on || []).not.toContain('ariregister_sync');
    }
  });
});
