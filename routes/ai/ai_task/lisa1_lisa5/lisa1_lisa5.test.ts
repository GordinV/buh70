import { ApiClient } from '../shared/api_client';
import { startLisa1Lisa5 } from './tools';
import { runLisa1Lisa5Subagent } from './agent';

describe('Субагент lisa1_lisa5', () => {
  it('startLisa1Lisa5 должен вызывать /task/calcLisa1Lisa5/ и возвращать log_id', async () => {
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
          log_id: 10426,
          data: {
            action: 'calcLisa1Lisa5',
            status: 'STARTED',
            log_id: 10426,
          },
          error_message: null,
        }),
      };
    });

    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);
    const result = await startLisa1Lisa5({ userId: 2477, rekvId: 63 }, client);

    expect(capturedUrl).toBe('http://test-server/task/calcLisa1Lisa5/');
    expect(JSON.parse(capturedBody)).toEqual({ user_id: 2477, rekv_id: 63 });
    expect(result.log_id).toBe(10426);
    expect(result.data?.status).toBe('STARTED');
  });

  it('runLisa1Lisa5Subagent должен запускать расчет контроля и ожидать его завершения', async () => {
    const mockFetch = jest.fn().mockImplementation(async (url: string) => {
      if (url.includes('/task/calcLisa1Lisa5/')) {
        return {
          ok: true,
          status: 200,
          json: async () => ({
            status: 200,
            result: 1,
            log_id: 7777,
            data: { action: 'calcLisa1Lisa5', status: 'STARTED', log_id: 7777 },
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
                flow: 'eelarve.salvesta_lisa_1_5_kontrol',
                status: 'success',
                exec_start: '2026-09-14T10:00:00.000Z',
                exec_end: '2026-09-14T10:20:00.000Z',
              },
            ],
          }),
        };
      }

      throw new Error(`Unexpected URL: ${url}`);
    });

    const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
    const result = await runLisa1Lisa5Subagent(
      { userId: 2477, rekvId: 63 },
      { apiClient: client, sleepFn: jest.fn().mockResolvedValue(undefined), pollIntervalMs: 10 }
    );

    expect(result.flow).toBe('eelarve.salvesta_lisa_1_5_kontrol');
    expect(result.logId).toBe(7777);
    expect(result.status).toBe('success');
  });
});
