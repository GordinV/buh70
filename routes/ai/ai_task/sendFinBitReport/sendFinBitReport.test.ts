import { ApiClient } from '../shared/api_client';
import { runSendFinBitReportSubagent } from './agent';
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
});
