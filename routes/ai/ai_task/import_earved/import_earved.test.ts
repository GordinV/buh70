import { ApiClient } from '../shared/api_client';
import {
  runImportEarvedSubagent,
  manifest,
  extractImportTotals,
  buildImportSummary,
} from './agent';
import { startImportEarved } from './tools';
import { TASK_FLOW_IMPORT_EARVED } from './schemas';

function startResponse(logId: number) {
  return {
    ok: true,
    status: 200,
    json: async () => ({
      status: 200,
      result: 1,
      log_id: logId,
      data: { action: 'importEarved', status: 'STARTED', log_id: logId },
      error_message: null,
    }),
  };
}

describe('Субагент import_earved', () => {
  it('startImportEarved вызывает /task/importEarved/ и передает log_id лога getEarved', async () => {
    let capturedUrl = '';
    let capturedBody: Record<string, unknown> = {};
    const mockFetch = jest.fn().mockImplementation(async (url: string, init?: RequestInit) => {
      capturedUrl = url;
      if (init?.body) capturedBody = JSON.parse(init.body as string);
      return startResponse(8001);
    });
    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

    const res = await startImportEarved({ userId: 11770, rekvId: 63, logId: 8546659 }, client);

    expect(capturedUrl).toBe('http://test-server/task/importEarved/');
    expect(capturedBody).toEqual({ user_id: 11770, rekv_id: 63, log_id: 8546659 });
    expect(res.log_id).toBe(8001);
  });

  it('startImportEarved без logId не передает log_id (бэкенд найдет последний лог getEarved)', async () => {
    let capturedBody: Record<string, unknown> = {};
    const mockFetch = jest.fn().mockImplementation(async (_url: string, init?: RequestInit) => {
      if (init?.body) capturedBody = JSON.parse(init.body as string);
      return startResponse(8002);
    });
    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

    await startImportEarved({ userId: 11770, rekvId: 63 }, client);

    expect(capturedBody).toEqual({ user_id: 11770, rekv_id: 63 });
  });

  it('extractImportTotals извлекает счетчики, пропущенные счета и рег.коды', () => {
    const totals = extractImportTotals({
      totalFetched: 3,
      totalImported: 2,
      totalSkipped: 1,
      skipped: [{ number: 'N2', asutusid: '222', rekvId: 63 }],
      missing: ['222', ' '],
      source_log_id: 400,
    });
    expect(totals).toEqual({
      totalFetched: 3,
      totalImported: 2,
      totalSkipped: 1,
      totalFailed: 0,
      imported: [],
      errors: [],
      skipped: [{ number: 'N2', asutusid: '222', rekvId: 63 }],
      missing: ['222'],
      sourceLogId: 400,
    });
    expect(extractImportTotals(undefined).totalImported).toBe(0);
    expect(extractImportTotals([]).totalSkipped).toBe(0);
  });

  it('buildImportSummary формирует эстонское резюме с пропущенными счетами', () => {
    expect(
      buildImportSummary({
        totalFetched: 3,
        totalImported: 2,
        totalSkipped: 1,
        totalFailed: 0,
        imported: [],
        errors: [],
        skipped: [],
        missing: ['222'],
        sourceLogId: 400,
      })
    ).toBe('Imporditud 2 arvet (leitud: 3). Vahele jäetud 1 arvet (puuduvad asutused: 222)');
    expect(
      buildImportSummary({
        totalFetched: 2,
        totalImported: 2,
        totalSkipped: 0,
        totalFailed: 0,
        imported: [],
        errors: [],
        skipped: [],
        missing: [],
        sourceLogId: 400,
      })
    ).toBe('Imporditud 2 arvet (leitud: 2)');
  });

  it('extractImportTotals и buildImportSummary учитывают imported и errors (частичный успех)', () => {
    const totals = extractImportTotals({
      totalFetched: 3,
      totalImported: 2,
      totalFailed: 1,
      imported: [
        { doc_id: 55, number: 'N1', rekv_id: 63 },
        { doc_id: 56, number: 'N3', rekv_id: 63 },
        { number: 'без doc_id' },
      ],
      errors: [{ number: 'N2', asutusid: '112', error: 'Viga: asutus ei leidnud' }],
      source_log_id: 400,
    });

    expect(totals.imported).toEqual([
      { doc_id: 55, number: 'N1', rekv_id: 63 },
      { doc_id: 56, number: 'N3', rekv_id: 63 },
    ]);
    expect(totals.totalFailed).toBe(1);
    expect(buildImportSummary(totals)).toBe(
      'Imporditud 2 arvet (leitud: 3). Vigu: 1 (N2: Viga: asutus ei leidnud)'
    );
  });

  it('runImportEarvedSubagent возвращает счетчики и пропущенные счета из result лога', async () => {
    const mockFetch = jest.fn().mockImplementation(async (url: string) => {
      if (url.includes('/task/importEarved/')) return startResponse(8003);
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
                flow: TASK_FLOW_IMPORT_EARVED,
                status: 'success',
                exec_start: '2026-11-13T07:20:00.000Z',
                exec_end: '2026-11-13T07:20:05.000Z',
                response: 'Imporditud 1 arvet (leitud: 2). Vahele jäetud 1 arvet (puuduvad asutused: 222).',
                result: {
                  error_code: 0,
                  totalFetched: 2,
                  totalImported: 1,
                  totalSkipped: 1,
                  skipped: [{ number: 'N2', asutusid: '222', rekvId: 63 }],
                  missing: ['222'],
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

    const result = await runImportEarvedSubagent(
      { userId: 11770, rekvId: 63, logId: 8546659 },
      { apiClient: client, pollIntervalMs: 10, maxTimeoutMs: 500, sleepFn: async () => {} }
    );

    expect(result.flow).toBe('docs.sp_loe_earved');
    expect(result.logId).toBe(8003);
    expect(result.status).toBe('success');
    expect(result.totalFetched).toBe(2);
    expect(result.totalImported).toBe(1);
    expect(result.totalSkipped).toBe(1);
    expect(result.skipped).toEqual([{ number: 'N2', asutusid: '222', rekvId: 63 }]);
    expect(result.missing).toEqual(['222']);
    expect(result.sourceLogId).toBe(400);
  });

  it('manifest.resolveParentParams берет log_id выкачки getEarved (а не check_asutus)', () => {
    expect(
      manifest.resolveParentParams({
        tasks: { getEarved: { log_id: 8546659 }, check_asutus: { log_id: 9000 } },
      })
    ).toEqual({ logId: 8546659 });
    expect(manifest.resolveParentParams({ tasks: { getEarved: { log_id: null } } })).toEqual({});
    expect(manifest.resolveParentParams({ tasks: {} })).toEqual({});
  });

  it('manifest.dispatch передает logId родителя и возвращает собственный log_id', async () => {
    let capturedBody: Record<string, unknown> = {};
    const mockFetch = jest.fn().mockImplementation(async (_url: string, init?: RequestInit) => {
      if (init?.body) capturedBody = JSON.parse(init.body as string);
      return startResponse(8004);
    });
    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

    const logId = await manifest.dispatch({
      userId: 2477,
      rekvId: 63,
      kond: 0,
      params: { userId: 11770, logId: 8546659 },
      apiClient: client,
    });

    expect(logId).toBe(8004);
    expect(capturedBody).toEqual({ user_id: 11770, rekv_id: 63, log_id: 8546659 });
  });

  it('manifest.enrichReportStep формирует резюме импорта для отчета', () => {
    expect(
      manifest.enrichReportStep({
        exec_start: '2026-11-13T07:20:00Z',
        result: { totalFetched: 3, totalImported: 2, totalSkipped: 1, missing: ['222'] },
      })
    ).toEqual({ resultSummary: 'Imporditud 2 arvet (leitud: 3). Vahele jäetud 1 arvet (puuduvad asutused: 222)' });
    expect(manifest.enrichReportStep(null)).toEqual({});
  });
});
