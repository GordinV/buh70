import { ApiClient } from '../shared/api_client';
import { manifest, parseInforegisterResult } from './agent';
import { startInforegister } from './tools';

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
    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

    const res = await startInforegister({ userId: 11770, rekvId: 63, logId: 8546670 }, client);

    expect(url).toBe('http://test-server/task/getInforegister/');
    expect(body).toEqual({ user_id: 11770, rekv_id: 63, dry_run: true, log_id: 8546670 });
    expect(res.log_id).toBe(9001);
  });

  it('insecureTls передается как insecure_tls только когда включен', async () => {
    let body: Record<string, unknown> = {};
    const mockFetch = jest.fn().mockImplementation(async (_u: string, init?: RequestInit) => {
      if (init?.body) body = JSON.parse(init.body as string);
      return startResponse(9004);
    });
    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

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
    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

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
    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

    const logId = await manifest.dispatch({
      userId: 2477,
      rekvId: 63,
      kond: 1,
      params: { userId: 11770, logId: 8546670 },
      apiClient: client,
    });

    expect(logId).toBe(9003);
    expect(body).toEqual({ user_id: 11770, rekv_id: 63, dry_run: true, log_id: 8546670 });
  });

  it('manifest.enrichReportStep: сводка с перечнем организаций для ручной работы', () => {
    const summary = manifest.enrichReportStep({ exec_start: 'x', result: RESULT }).resultSummary as string;
    expect(summary).toContain('lisatud 1 / 3');
    expect(summary).toContain('päringuid: 2');
    expect(summary).toContain('1K2563758R (needs_manual)');
    expect(summary).toContain('12345678 (closed)');
    expect(manifest.enrichReportStep(null)).toEqual({});
  });
});
