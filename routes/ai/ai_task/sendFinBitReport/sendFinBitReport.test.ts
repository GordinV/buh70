import { ApiClient } from '../shared/api_client';
import { runSendFinBitReportSubagent, buildSendSummary, manifest } from './agent';
import { startSendFinBitReport } from './tools';
import { TASK_FLOW_SEND_FIN_BIT_REPORT } from './schemas';

describe('Субагент sendFinBitReport', () => {
  it('startSendFinBitReport должен вызывать /task/sendFinBitReport/ с logId и возвращать собственный log_id', async () => {
    let capturedUrl = '';
    let capturedBody: Record<string, unknown> = {};

    const mockFetch = jest.fn().mockImplementation(async (url: string, init?: RequestInit) => {
      capturedUrl = url;
      if (init?.body) {
        capturedBody = JSON.parse(init.body as string);
      }
      return {
        ok: true,
        status: 200,
        json: async () => ({
          status: 200,
          result: 1,
          log_id: 9999,
          data: {
            action: 'sendFinBitReport',
            status: 'STARTED',
            log_id: 9999,
          },
          error_message: null,
        }),
      };
    });

    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

    const res = await startSendFinBitReport(
      { userId: 2477, rekvId: 63, logId: 8888 },
      client
    );

    expect(capturedUrl).toBe('http://test-server/task/sendFinBitReport/');
    expect(capturedBody).toEqual({
      user_id: 2477,
      rekv_id: 63,
      logId: 8888,
    });
    expect(res.log_id).toBe(9999);
    expect(res.status).toBe(200);
  });

  it('startSendFinBitReport должен выбрасывать ошибку валидации при отсутствии или некорректном logId', async () => {
    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' });

    // @ts-expect-error Проверка валидации при отсутствии logId
    await expect(startSendFinBitReport({ userId: 2477, rekvId: 63 }, client)).rejects.toThrow();

    // Некорректный logId (отрицательный или ноль)
    await expect(startSendFinBitReport({ userId: 2477, rekvId: 63, logId: 0 }, client)).rejects.toThrow();
    await expect(startSendFinBitReport({ userId: 2477, rekvId: 63, logId: -5 }, client)).rejects.toThrow();
  });

  it('runSendFinBitReportSubagent должен запускать задачу и возвращать результат ожидания через logs_watcher', async () => {
    const mockFetch = jest.fn().mockImplementation(async (url: string) => {
      if (url.includes('/task/sendFinBitReport/')) {
        return {
          ok: true,
          status: 200,
          json: async () => ({
            status: 200,
            result: 1,
            log_id: 9999,
            data: { action: 'sendFinBitReport', status: 'STARTED', log_id: 9999 },
            error_message: null,
          }),
        };
      }
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
                flow: TASK_FLOW_SEND_FIN_BIT_REPORT,
                status: 'success',
                exec_start: '2026-09-18T10:00:00.000Z',
                exec_end: '2026-09-18T10:00:05.000Z',
              },
            ],
          }),
        };
      }
      return { ok: false, status: 404, statusText: 'Not Found' };
    });

    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

    const result = await runSendFinBitReportSubagent(
      { userId: 2477, rekvId: 63, logId: 8888 },
      {
        apiClient: client,
        pollIntervalMs: 10,
        maxTimeoutMs: 500,
        sleepFn: async () => {},
      }
    );

    expect(result.flow).toBe(TASK_FLOW_SEND_FIN_BIT_REPORT);
    expect(result.status).toBe('success');
    expect(result.logId).toBe(9999);
    expect(result.execStart).toBe('2026-09-18T10:00:00.000Z');
    expect(result.execEnd).toBe('2026-09-18T10:00:05.000Z');
  });

  it('buildSendSummary: пустой result при success - "Uusi arveid ei olnud"; при failed - причина', () => {
    expect(buildSendSummary({ status: 'success', result: [] })).toBe('Uusi arveid ei olnud, teavitusi ei saadetud');
    expect(buildSendSummary({ status: 'failed', result: [], error: 'Impordi logi ei leitud' })).toBe(
      'Teavitusi ei saadetud: Impordi logi ei leitud'
    );
    expect(buildSendSummary({ status: 'failed', result: [] })).toBeUndefined();
  });

  it('buildSendSummary: считает отправленные, ранее отправленные и неотправленные письма', () => {
    const summary = buildSendSummary({
      status: 'failed',
      result: [
        { email: 'a@narva.ee', success: true, invoicesCount: 2 },
        { email: 'b@narva.ee', success: true, already_sent: true, invoicesCount: 1 },
        { email: 'c@narva.ee', success: false, error: 'connect ETIMEDOUT', invoicesCount: 3 },
      ],
    });
    expect(summary).toContain('Saadetud 1 teavitust (2 arvet)');
    expect(summary).toContain('varem saadetud: 1');
    expect(summary).toContain('Saatmata 1: c@narva.ee: connect ETIMEDOUT');
  });

  it('manifest.enrichReportStep формирует резюме только при наличии exec_start', () => {
    expect(manifest.enrichReportStep(null)).toEqual({});
    expect(manifest.enrichReportStep({ status: 'success', result: [] })).toEqual({});
    expect(manifest.enrichReportStep({ exec_start: '2026-10-14T05:00:00.000Z', status: 'success', result: [] })).toEqual({
      resultSummary: 'Uusi arveid ei olnud, teavitusi ei saadetud',
    });
  });

  it('config.json sendFinBitReport: детерминированная оценка (prompt: null), зависит от import_earved', () => {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const cfg = require('./config.json');
    expect(cfg.prompt).toBeNull();
    expect(cfg.depends_on).toEqual(['import_earved']);
  });
});
