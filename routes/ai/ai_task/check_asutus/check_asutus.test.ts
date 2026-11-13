import { ApiClient } from '../shared/api_client';
import { runCheckAsutusSubagent, manifest, extractMissingAsutused } from './agent';
import { startCheckAsutus } from './tools';
import { TASK_FLOW_CHECK_ASUTUS } from './schemas';

function startResponse(logId: number) {
  return {
    ok: true,
    status: 200,
    json: async () => ({
      status: 200,
      result: 1,
      log_id: logId,
      data: { action: 'checkAsutusAvailability', status: 'STARTED', log_id: logId },
      error_message: null,
    }),
  };
}

describe('Субагент check_asutus', () => {
  it('startCheckAsutus вызывает /task/checkAsutusAvailability/ и передает log_id родителя', async () => {
    let capturedUrl = '';
    let capturedBody: Record<string, unknown> = {};
    const mockFetch = jest.fn().mockImplementation(async (url: string, init?: RequestInit) => {
      capturedUrl = url;
      if (init?.body) capturedBody = JSON.parse(init.body as string);
      return startResponse(7001);
    });
    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

    const res = await startCheckAsutus({ userId: 11770, rekvId: 63, logId: 8546660 }, client);

    expect(capturedUrl).toBe('http://test-server/task/checkAsutusAvailability/');
    expect(capturedBody).toEqual({ user_id: 11770, rekv_id: 63, log_id: 8546660 });
    expect(res.log_id).toBe(7001);
  });

  it('startCheckAsutus без logId не передает log_id (бэкенд найдет последний лог getEarved)', async () => {
    let capturedBody: Record<string, unknown> = {};
    const mockFetch = jest.fn().mockImplementation(async (_url: string, init?: RequestInit) => {
      if (init?.body) capturedBody = JSON.parse(init.body as string);
      return startResponse(7002);
    });
    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

    await startCheckAsutus({ userId: 11770, rekvId: 63 }, client);

    expect(capturedBody).toEqual({ user_id: 11770, rekv_id: 63 });
  });

  it('extractMissingAsutused извлекает рег.коды и source_log_id из result', () => {
    expect(
      extractMissingAsutused({ missing: ['16077631', ' 10000001 ', ''], source_log_id: 400 })
    ).toEqual({ missing: ['16077631', '10000001'], totalMissing: 2, sourceLogId: 400 });
    expect(extractMissingAsutused(undefined)).toEqual({ missing: [], totalMissing: 0, sourceLogId: null });
  });

  it('runCheckAsutusSubagent возвращает список отсутствующих рег.кодов из result лога', async () => {
    const mockFetch = jest.fn().mockImplementation(async (url: string) => {
      if (url.includes('/task/checkAsutusAvailability/')) return startResponse(7003);
      if (url.includes('/task/read_log/')) {
        return {
          ok: true,
          status: 200,
          json: async () => ({
            result: 1,
            error_code: 0,
            error_message: null,
            data: [
              {
                flow: TASK_FLOW_CHECK_ASUTUS,
                status: 'success',
                exec_start: '2026-11-13T07:10:00.000Z',
                exec_end: '2026-11-13T07:10:02.000Z',
                response: 'Leidnud puuduvad asutused: 16077631',
                result: {
                  error_code: 0,
                  totalMissing: 1,
                  missing: ['16077631'],
                  details: [{ puuduvad_asutused: '16077631' }],
                  source_log_id: 400,
                },
              },
            ],
          }),
        };
      }
      return { ok: false, status: 404, statusText: 'Not Found' };
    });
    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

    const result = await runCheckAsutusSubagent(
      { userId: 11770, rekvId: 63, logId: 8546660 },
      { apiClient: client, pollIntervalMs: 10, maxTimeoutMs: 500, sleepFn: async () => {} }
    );

    expect(result.flow).toBe(TASK_FLOW_CHECK_ASUTUS);
    expect(result.logId).toBe(7003);
    expect(result.status).toBe('success');
    expect(result.missing).toEqual(['16077631']);
    expect(result.totalMissing).toBe(1);
    expect(result.sourceLogId).toBe(400);
  });

  it('manifest.resolveParentParams пробрасывает log_id родителя getEarved как logId', () => {
    expect(manifest.resolveParentParams({ tasks: { getEarved: { log_id: 8546660 } } })).toEqual({ logId: 8546660 });
    expect(manifest.resolveParentParams({ tasks: { getEarved: { log_id: null } } })).toEqual({});
    expect(manifest.resolveParentParams({ tasks: {} })).toEqual({});
  });

  it('manifest.dispatch передает logId родителя и возвращает собственный log_id', async () => {
    let capturedBody: Record<string, unknown> = {};
    const mockFetch = jest.fn().mockImplementation(async (_url: string, init?: RequestInit) => {
      if (init?.body) capturedBody = JSON.parse(init.body as string);
      return startResponse(7004);
    });
    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

    const logId = await manifest.dispatch({
      userId: 2477,
      rekvId: 63,
      kond: 0,
      params: { userId: 11770, logId: 8546660 },
      apiClient: client,
    });

    expect(logId).toBe(7004);
    expect(capturedBody).toEqual({ user_id: 11770, rekv_id: 63, log_id: 8546660 });
  });

  it('manifest.enrichReportStep формирует эстонское резюме для отчета', () => {
    expect(
      manifest.enrichReportStep({
        exec_start: '2026-11-13T07:10:00Z',
        result: { missing: ['16077631', '10000001'] },
      })
    ).toEqual({ resultSummary: 'Puuduvad asutused (2): 16077631, 10000001' });
    expect(
      manifest.enrichReportStep({ exec_start: '2026-11-13T07:10:00Z', result: { missing: [] } })
    ).toEqual({ resultSummary: 'Kõik asutused on olemas' });
    expect(manifest.enrichReportStep(null)).toEqual({});
  });
});
