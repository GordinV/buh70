import { ApiClient } from '../shared/api_client';
import { startSaldoandmik } from './tools';
import { runSaldoandmikSubagent } from './agent';

describe('Субагент saldoandmik', () => {
  it('startSaldoandmik должен вызывать /task/calcKondSaldoandmik/ и возвращать log_id', async () => {
    let capturedUrl = '';
    let capturedBody = '';

    const mockFetch = jest.fn().mockImplementation(async (url: string, init: RequestInit) => {
      capturedUrl = url;
      capturedBody = init.body as string;

      return {
        ok: true,
        status: 200,
        json: async () => ({
          status: 200,
          result: 1,
          log_id: 10425,
          data: {
            action: 'calcKondSaldoandmik',
            status: 'STARTED',
            log_id: 10425,
          },
          error_message: null,
        }),
      };
    });

    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);
    const result = await startSaldoandmik({ userId: 2477, rekvId: 63, kond: 1 }, client);

    expect(capturedUrl).toBe('http://test-server/task/calcKondSaldoandmik/');
    expect(JSON.parse(capturedBody)).toEqual({ user_id: 2477, rekv_id: 63, kond: 1 });
    expect(result.log_id).toBe(10425);
    expect(result.data?.status).toBe('STARTED');
  });

  it('runSaldoandmikSubagent должен запускать задачу и возвращать результат ожидания', async () => {
    const mockFetch = jest.fn().mockImplementation(async (url: string) => {
      if (url.includes('/task/calcKondSaldoandmik/')) {
        return {
          ok: true,
          status: 200,
          json: async () => ({
            status: 200,
            result: 1,
            log_id: 5555,
            data: { action: 'calcKondSaldoandmik', status: 'STARTED', log_id: 5555 },
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
            data: [
              {
                flow: 'eelarve.sp_koosta_saldoandmik',
                status: 'success',
                exec_start: '2026-09-14T10:00:00.000Z',
                exec_end: '2026-09-14T10:05:00.000Z',
              },
            ],
          }),
        };
      }

      throw new Error(`Unexpected URL: ${url}`);
    });

    const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
    const result = await runSaldoandmikSubagent(
      { userId: 2477, rekvId: 63, kond: 1 },
      { apiClient: client, sleepFn: jest.fn().mockResolvedValue(undefined), pollIntervalMs: 10 }
    );

    expect(result.flow).toBe('eelarve.sp_koosta_saldoandmik');
    expect(result.logId).toBe(5555);
    expect(result.status).toBe('success');
  });
});
