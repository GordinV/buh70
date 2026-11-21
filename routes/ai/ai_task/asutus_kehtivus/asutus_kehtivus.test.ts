import { ApiClient } from '../shared/api_client';
import { buildAgentRegistry } from '../shared/agent_registry';
import { getDefaultTaskGraph } from '../orchestrator/state.manager';
import {
  manifest,
  parseAsutusKehtivusResult,
  runAsutusKehtivusSubagent,
} from './agent';
import { startAsutusKehtivus } from './tools';

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

describe('Субагент asutus_kehtivus', () => {
  const prevEnvHash = process.env.INFOREGISTER_HASH;

  afterEach(() => {
    if (prevEnvHash === undefined) {
      delete process.env.INFOREGISTER_HASH;
    } else {
      process.env.INFOREGISTER_HASH = prevEnvHash;
    }
  });

  test('(а) агент обнаруживается реестром и зависит строго от ariregister_sync (не от FinBit)', () => {
    const registry = buildAgentRegistry();
    expect(registry['asutus_kehtivus']).toBeDefined();

    const graph = getDefaultTaskGraph();
    expect(graph['asutus_kehtivus']).toBeDefined();
    expect(graph['asutus_kehtivus'].flow).toBe('checkAsutusKehtivus');
    expect(graph['asutus_kehtivus'].depends_on).toEqual(['ariregister_sync']);
    expect(graph['asutus_kehtivus'].params).toMatchObject({
      userId: 11770,
      rekvId: 63,
      dryRun: false,
      maxClose: 100,
      extraEmails: [
        'vladislav.gordin@gmail.com',
        'jelena.tsekanina@narva.ee',
        'svetlana.tsaikina@narva.ee',
      ],
    });
  });

  test('(б) нет INFOREGISTER_HASH -> SKIP до HTTP; startAsutusKehtivus бросает ошибку до HTTP', async () => {
    delete process.env.INFOREGISTER_HASH;
    expect(manifest.validatePrerequisites()).toBe('INFOREGISTER_HASH puudub');

    process.env.INFOREGISTER_HASH = 'valid-hash';
    expect(manifest.validatePrerequisites()).toBeNull();

    const postMock = jest.fn();
    const client = makeMockApiClient(postMock, '');
    await expect(startAsutusKehtivus({}, client)).rejects.toThrow('INFOREGISTER_HASH puudub');
    expect(postMock).not.toHaveBeenCalled();
  });

  test('(в) параметры dry_run, max_close и extra_emails передаются в POST /task/checkAsutusKehtivus/', async () => {
    const postMock = jest.fn().mockResolvedValue({
      status: 200,
      result: 1,
      log_id: 701,
      data: { status: 'STARTED', log_id: 701 },
      error_message: null,
    });
    const client = makeMockApiClient(postMock, 'hash-from-env');

    const res = await startAsutusKehtivus(
      { userId: 11770, rekvId: 63, dryRun: true, maxClose: 50, extraEmails: ['vladislav.gordin@gmail.com'] },
      client
    );
    expect(res.ok).toBe(true);
    expect(res.log_id).toBe(701);
    expect(postMock).toHaveBeenCalledWith(
      '/task/checkAsutusKehtivus/',
      {
        user_id: 11770,
        rekv_id: 63,
        dry_run: true,
        max_close: 50,
        extra_emails: ['vladislav.gordin@gmail.com'],
        hash: 'hash-from-env',
      },
      { allowHttpErrorResponse: true, retries: 1 }
    );
  });

  test('(г) registry_stale -> SKIPPED; too_many_candidates / 401 / 403 -> FAILED без повтора (retryable=false)', async () => {
    // registry_stale -> status: 'skipped'
    const postStale = jest.fn(async (ep: string) => {
      if (ep === '/task/checkAsutusKehtivus/') return { status: 200, result: 1, log_id: 801 };
      return {
        result: 1,
        data: [
          {
            id: 801,
            flow: 'checkAsutusKehtivus',
            status: 'success',
            exec_start: '2026-11-19T06:35:00+02:00',
            exec_end: '2026-11-19T06:35:02+02:00',
            result: { status: 'skipped', reason: 'registry_stale', dry_run: true, candidates_total: 0 },
          },
        ],
      };
    });
    const resStale = await runAsutusKehtivusSubagent(
      {},
      { apiClient: makeMockApiClient(postStale), sleepFn: async () => {}, pollIntervalMs: 1, maxTimeoutMs: 1000 }
    );
    expect(resStale.status).toBe('skipped');
    expect(resStale.reason).toBe('registry_stale');

    // too_many_candidates -> throws non-retryable error
    const postTooMany = jest.fn(async (ep: string) => {
      if (ep === '/task/checkAsutusKehtivus/') return { status: 200, result: 1, log_id: 802 };
      return {
        result: 1,
        data: [
          {
            id: 802,
            flow: 'checkAsutusKehtivus',
            status: 'failed',
            exec_start: '2026-11-19T06:35:00+02:00',
            exec_end: '2026-11-19T06:35:02+02:00',
            error: 'Liiga palju kandidaate',
            result: { status: 'failed', reason: 'too_many_candidates', retryable: false, candidates_total: 150 },
          },
        ],
      };
    });
    let errTooMany: (Error & { retryable?: boolean }) | null = null;
    try {
      await runAsutusKehtivusSubagent(
        {},
        { apiClient: makeMockApiClient(postTooMany), sleepFn: async () => {}, pollIntervalMs: 1, maxTimeoutMs: 1000 }
      );
    } catch (e) {
      errTooMany = e as Error & { retryable?: boolean };
    }
    expect(errTooMany).not.toBeNull();
    expect(errTooMany?.retryable).toBe(false);

    // 401 и 403 -> non-retryable
    for (const code of [401, 403]) {
      const postAuth = jest.fn().mockResolvedValue({ status: code, result: 0, log_id: null });
      let authErr: (Error & { retryable?: boolean }) | null = null;
      try {
        await startAsutusKehtivus({}, makeMockApiClient(postAuth));
      } catch (e) {
        authErr = e as Error & { retryable?: boolean };
      }
      expect(authErr).not.toBeNull();
      expect(authErr?.retryable).toBe(false);
    }
  });

  test('(д) enrichReportStep для dry_run и реального запуска (до 20 первых записей)', () => {
    const items = Array.from({ length: 25 }, (_, i) => ({
      regkood: String(10000000 + i),
      nimetus: `Firma ${i} OÜ`,
    }));

    const dryStep = manifest.enrichReportStep({
      exec_start: '2026-11-19T06:35:00+02:00',
      result: { dry_run: true, candidates_total: 25, would_close: items },
    });
    expect(dryStep.resultSummary).toContain('Proovikäivitus (dry-run): leitud 25 kandidaati, andmebaasis muudatusi ei tehtud');
    expect(dryStep.resultSummary).not.toMatch(/Suletud|Suletakse/i);
    expect(dryStep.resultSummary).toContain('10000000 Firma 0 OÜ');
    expect(dryStep.resultSummary).toContain('10000019 Firma 19 OÜ');
    expect(dryStep.resultSummary).not.toContain('10000020');

    const liveStep = manifest.enrichReportStep({
      exec_start: '2026-11-19T06:35:00+02:00',
      result: { dry_run: false, candidates_total: 25, totalClosed: 25, totalErrors: 0, closed: items },
    });
    expect(liveStep.resultSummary).toContain('Suletud kaarte: 25');
    expect(liveStep.resultSummary).toContain('10000019 Firma 19 OÜ');
    expect(liveStep.resultSummary).not.toContain('10000020');

    expect(parseAsutusKehtivusResult({ status: 'skipped', reason: 'registry_stale' }).resultSummary).toContain('vahele jäetud');
  });
});
