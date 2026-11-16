import { ApiClient } from '../shared/api_client';
import { manifest, parseInforegisterResult } from './agent';
import { lookupInforegister, startInforegister } from './tools';

function startResponse(logId: number) {
  return {
    ok: true,
    status: 200,
    json: async () => ({
      status: 200,
      result: 1,
      log_id: logId,
      data: { action: 'getInforegister', status: 'STARTED', log_id: logId },
      error_message: null,
    }),
  };
}

const RESULT = {
  dry_run: false,
  total: 3,
  created: 1,
  would_create: 0,
  calls_spent: 2,
  remaining_year: 80,
  items: [
    { regkood: '16598086', status: 'created', nimetus: 'X OÜ', asutus_id: 55, source: 'api', error: null },
    { regkood: '1K2563758R', status: 'needs_manual', error: 'invalid_reg_code: x' },
    { regkood: '12345678', status: 'closed', nimetus: 'Y OÜ', error: 'Registri staatus: Kustutatud' },
  ],
};

describe('Субагент inforegister', () => {
  it('startInforegister вызывает /task/getInforegister/ с dry_run=true по умолчанию и log_id родителя', async () => {
    let url = '';
    let body: Record<string, unknown> = {};
    const mockFetch = jest.fn().mockImplementation(async (u: string, init?: RequestInit) => {
      url = u;
      if (init?.body) body = JSON.parse(init.body as string);
      return startResponse(9001);
    });
    const client = new ApiClient(
      { buh70ApiBaseUrl: 'http://test-server', inforegisterHash: 'test-secret-hash' },
      mockFetch as unknown as typeof fetch
    );

    const res = await startInforegister({ userId: 11770, rekvId: 63, logId: 8546670 }, client);

    expect(url).toBe('http://test-server/task/getInforegister/');
    expect(body).toEqual({
      user_id: 11770,
      rekv_id: 63,
      dry_run: true,
      log_id: 8546670,
      hash: 'test-secret-hash',
    });
    expect(res.log_id).toBe(9001);
  });

  it('insecureTls передается как insecure_tls только когда включен', async () => {
    let body: Record<string, unknown> = {};
    const mockFetch = jest.fn().mockImplementation(async (_u: string, init?: RequestInit) => {
      if (init?.body) body = JSON.parse(init.body as string);
      return startResponse(9004);
    });
    const client = new ApiClient(
      { buh70ApiBaseUrl: 'http://test-server', inforegisterHash: 'test-secret-hash' },
      mockFetch as unknown as typeof fetch
    );

    await startInforegister({ userId: 11770, rekvId: 63 }, client);
    expect(body.insecure_tls).toBeUndefined();
    await startInforegister({ userId: 11770, rekvId: 63, insecureTls: true }, client);
    expect(body.insecure_tls).toBe(true);
  });

  it('startInforegister передает dry_run=false и max_calls', async () => {
    let body: Record<string, unknown> = {};
    const mockFetch = jest.fn().mockImplementation(async (_u: string, init?: RequestInit) => {
      if (init?.body) body = JSON.parse(init.body as string);
      return startResponse(9002);
    });
    const client = new ApiClient(
      { buh70ApiBaseUrl: 'http://test-server', inforegisterHash: 'test-secret-hash' },
      mockFetch as unknown as typeof fetch
    );

    await startInforegister({ userId: 11770, rekvId: 63, dryRun: false, maxCalls: 3 }, client);

    expect(body.dry_run).toBe(false);
    expect(body.max_calls).toBe(3);
  });

  it('parseInforegisterResult считает организации, требующие ручной работы', () => {
    const p = parseInforegisterResult(RESULT);
    expect(p.total).toBe(3);
    expect(p.created).toBe(1);
    expect(p.needsAttention).toBe(2);
    expect(p.callsSpent).toBe(2);
    expect(p.remainingYear).toBe(80);
    expect(parseInforegisterResult(undefined).items).toEqual([]);
  });

  it('manifest.resolveParentParams берет log_id check_asutus', () => {
    expect(
      manifest.resolveParentParams({ tasks: { getEarved: { log_id: 1 }, check_asutus: { log_id: 8546670 } } })
    ).toEqual({ logId: 8546670 });
    expect(manifest.resolveParentParams({ tasks: {} })).toEqual({});
  });

  it('manifest.dispatch по умолчанию работает в dry-run и передает logId родителя', async () => {
    let body: Record<string, unknown> = {};
    const mockFetch = jest.fn().mockImplementation(async (_u: string, init?: RequestInit) => {
      if (init?.body) body = JSON.parse(init.body as string);
      return startResponse(9003);
    });
    const client = new ApiClient(
      { buh70ApiBaseUrl: 'http://test-server', inforegisterHash: 'test-secret-hash' },
      mockFetch as unknown as typeof fetch
    );

    const logId = await manifest.dispatch({
      userId: 2477,
      rekvId: 63,
      kond: 1,
      params: { userId: 11770, logId: 8546670 },
      apiClient: client,
    });

    expect(logId).toBe(9003);
    expect(body).toEqual({
      user_id: 11770,
      rekv_id: 63,
      dry_run: true,
      log_id: 8546670,
      hash: 'test-secret-hash',
    });
  });

  it('manifest.enrichReportStep: сводка с перечнем организаций для ручной работы', () => {
    const summary = manifest.enrichReportStep({ exec_start: 'x', result: RESULT }).resultSummary as string;
    expect(summary).toContain('lisatud 1 / 3');
    expect(summary).toContain('päringuid: 2');
    expect(summary).toContain('1K2563758R (needs_manual)');
    expect(summary).toContain('12345678 (closed)');
    expect(manifest.enrichReportStep(null)).toEqual({});
  });

  it('явный input.hash имеет приоритет над getConfig().inforegisterHash', async () => {
    let body: Record<string, unknown> = {};
    const mockFetch = jest.fn().mockImplementation(async (_u: string, init?: RequestInit) => {
      if (init?.body) body = JSON.parse(init.body as string);
      return startResponse(9005);
    });
    const client = new ApiClient(
      { buh70ApiBaseUrl: 'http://test-server', inforegisterHash: 'env-hash' },
      mockFetch as unknown as typeof fetch
    );

    await startInforegister({ userId: 11770, rekvId: 63, hash: 'explicit-hash' }, client);
    expect(body.hash).toBe('explicit-hash');
  });

  it('без INFOREGISTER_HASH startInforegister бросает ошибку до HTTP-вызова', async () => {
    const mockFetch = jest.fn();
    const client = new ApiClient(
      { buh70ApiBaseUrl: 'http://test-server', inforegisterHash: '' },
      mockFetch as unknown as typeof fetch
    );

    await expect(startInforegister({ userId: 11770, rekvId: 63 }, client)).rejects.toThrow('INFOREGISTER_HASH puudub');
    expect(mockFetch).not.toHaveBeenCalled();
  });

  it('manifest.validatePrerequisites возвращает причину SKIP без hash и null при наличии INFOREGISTER_HASH', () => {
    const prevHash = process.env.INFOREGISTER_HASH;
    try {
      delete process.env.INFOREGISTER_HASH;
      expect(manifest.validatePrerequisites()).toBe('INFOREGISTER_HASH puudub');

      process.env.INFOREGISTER_HASH = 'valid-token-hash';
      expect(manifest.validatePrerequisites()).toBeNull();
    } finally {
      if (prevHash === undefined) {
        delete process.env.INFOREGISTER_HASH;
      } else {
        process.env.INFOREGISTER_HASH = prevHash;
      }
    }
  });

  it('401 и 403 бэкенда дают различимые невозобновляемые ошибки без утечки hash', async () => {
    const secretHash = 'super-secret-token-value';
    const makeErrClient = (status: number) =>
      new ApiClient(
        { buh70ApiBaseUrl: 'http://test-server', inforegisterHash: secretHash },
        jest.fn().mockResolvedValue({
          ok: false,
          status,
          statusText: status === 401 ? 'Unauthorized' : 'Forbidden',
          text: async () => `error ${status}`,
        }) as unknown as typeof fetch
      );

    await expect(startInforegister({ userId: 11770, rekvId: 63 }, makeErrClient(401))).rejects.toMatchObject({
      message: 'Inforegister: hash on vale või tühistatud (401)',
      retryable: false,
    });
    await expect(startInforegister({ userId: 11770, rekvId: 63 }, makeErrClient(403))).rejects.toMatchObject({
      message: 'Inforegister: puudub õigus (403)',
      retryable: false,
    });
  });

  describe('lookupInforegister (синхронный поиск по regkood)', () => {
    it('(а, б) отправляет {regkood, hash, cache_only, force_refresh, insecure_tls} и парсит ответ 200', async () => {
      let url = '';
      let body: Record<string, unknown> = {};
      const mockFetch = jest.fn().mockResolvedValue({
        ok: true,
        status: 200,
        json: async () => ({
          status: 200,
          result: 1,
          data: {
            regkood: '11735006',
            asutus_id: 55,
            source: 'cache',
            fetched_at: '2026-11-16T08:00:00.000Z',
            closed: false,
            local: { id: 55, regkood: '11735006', nimetus: 'REGISTER OÜ' },
            registry: { name: 'REGISTER OÜ', regCode: '11735006', registryStatus: 'Registrisse kantud' },
            company: { name: 'REGISTER OÜ', regCode: '11735006', registryStatus: 'Registrisse kantud' },
            diff: [],
            calls_spent: 0,
            remaining_year: 90,
          },
          error_message: null,
        }),
      });
      const client = new ApiClient(
        { buh70ApiBaseUrl: 'http://test-server', inforegisterHash: 'lookup-hash-1' },
        (async (u: string, init?: RequestInit) => {
          url = u;
          if (init?.body) body = JSON.parse(init.body as string);
          return mockFetch();
        }) as unknown as typeof fetch
      );

      const res = await lookupInforegister(
        { regkood: ' 11735006 ', cacheOnly: true, forceRefresh: true, insecureTls: true },
        client
      );

      expect(url).toBe('http://test-server/task/inforegisterLookup/');
      expect(body).toEqual({
        regkood: '11735006',
        hash: 'lookup-hash-1',
        cache_only: true,
        force_refresh: true,
        insecure_tls: true,
      });
      expect(res.ok).toBe(true);
      expect(res.status).toBe(200);
      expect(res.data?.registry?.name).toBe('REGISTER OÜ');
      expect(res.data?.source).toBe('cache');
    });

    it('(в, 401, 403) HTTP 401/403/404/429/503 возвращают ok:false с reason без исключения', async () => {
      const makeStatusClient = (status: number, reason: string, errMsg: string) =>
        new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server', inforegisterHash: 'lookup-hash-1' },
          jest.fn().mockResolvedValue({
            ok: false,
            status,
            statusText: 'Error',
            text: async () => JSON.stringify({ status, result: 0, data: { reason }, error_message: errMsg }),
          }) as unknown as typeof fetch
        );

      const r401 = await lookupInforegister({ regkood: '11735006' }, makeStatusClient(401, 'unauthorized_hash', 'Bad hash'));
      expect(r401).toMatchObject({ ok: false, status: 401, reason: 'unauthorized_hash', message: 'Bad hash' });

      const r403 = await lookupInforegister({ regkood: '11735006' }, makeStatusClient(403, 'forbidden_scope', 'No scope'));
      expect(r403).toMatchObject({ ok: false, status: 403, reason: 'forbidden_scope', message: 'No scope' });

      const r404 = await lookupInforegister({ regkood: '11735006' }, makeStatusClient(404, 'not_found', 'Not found'));
      expect(r404).toMatchObject({ ok: false, status: 404, reason: 'not_found' });

      const r503 = await lookupInforegister({ regkood: '11735006' }, makeStatusClient(503, 'no_api_key', 'No key'));
      expect(r503).toMatchObject({ ok: false, status: 503, reason: 'no_api_key' });
    });

    it('(г) невалидный regkood и отсутствие INFOREGISTER_HASH отсекаются до HTTP-вызова', async () => {
      const mockFetch = jest.fn();
      const client = new ApiClient(
        { buh70ApiBaseUrl: 'http://test-server', inforegisterHash: '' },
        mockFetch as unknown as typeof fetch
      );

      await expect(lookupInforegister({ regkood: '1234' }, client)).rejects.toThrow();
      await expect(lookupInforegister({ regkood: '11735006' }, client)).rejects.toThrow('INFOREGISTER_HASH puudub');
      expect(mockFetch).not.toHaveBeenCalled();
    });

    it('при 502, 504 и сетевой ошибке делает ровно 1 вызов fetch (без повторов ApiClient)', async () => {
      const makeErrFetch = (status: number, reason: string) =>
        jest.fn().mockResolvedValue({
          ok: false,
          status,
          statusText: 'Error',
          text: async () => JSON.stringify({ status, result: 0, data: { reason }, error_message: `err ${status}` }),
        });

      const fetch502 = makeErrFetch(502, 'http_error');
      const r502 = await lookupInforegister(
        { regkood: '11735006' },
        new ApiClient({ buh70ApiBaseUrl: 'http://test-server', inforegisterHash: 'h1' }, fetch502 as unknown as typeof fetch)
      );
      expect(fetch502).toHaveBeenCalledTimes(1);
      expect(r502).toMatchObject({ ok: false, status: 502, reason: 'http_error' });

      const fetch504 = makeErrFetch(504, 'timeout');
      const r504 = await lookupInforegister(
        { regkood: '11735006' },
        new ApiClient({ buh70ApiBaseUrl: 'http://test-server', inforegisterHash: 'h1' }, fetch504 as unknown as typeof fetch)
      );
      expect(fetch504).toHaveBeenCalledTimes(1);
      expect(r504).toMatchObject({ ok: false, status: 504, reason: 'timeout' });

      const fetchNetErr = jest.fn().mockRejectedValue(new Error('ECONNREFUSED'));
      const rNet = await lookupInforegister(
        { regkood: '11735006' },
        new ApiClient({ buh70ApiBaseUrl: 'http://test-server', inforegisterHash: 'h1' }, fetchNetErr as unknown as typeof fetch)
      );
      expect(fetchNetErr).toHaveBeenCalledTimes(1);
      expect(rNet).toMatchObject({ ok: false, status: 500, reason: 'network_error', message: 'ECONNREFUSED' });
    });
  });
});
