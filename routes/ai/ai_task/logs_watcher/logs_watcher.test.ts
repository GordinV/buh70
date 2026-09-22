import { ApiClient } from '../shared/api_client';
import { readTaskLog } from './tools';
import { watchTaskUntilDone, inspectLogExecutionResult } from './agent';

describe('Субагент logs_watcher', () => {
  it('readTaskLog должен успешно парсить ответ эндпоинта /task/read_log/:user_id/:task_name', async () => {
    const mockFetch = jest.fn().mockResolvedValueOnce({
      ok: true,
      status: 200,
      statusText: 'OK',
      json: async () => ({
        result: 1,
        error_code: 0,
        error_message: null,
        data: [
          {
            flow: 'eelarve.sp_koosta_saldoandmik',
            status: 'success',
            exec_start: '2026-09-14T10:00:00.000Z',
            exec_end: '2026-09-14T10:15:30.000Z',
          },
        ],
      }),
    });

    const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
    const result = await readTaskLog(
      { userId: 2477, taskName: 'eelarve.sp_koosta_saldoandmik' },
      client
    );

    expect(result.result).toBe(1);
    expect(result.data[0].status).toBe('success');
    expect(result.data[0].flow).toBe('eelarve.sp_koosta_saldoandmik');
  });

  it('watchTaskUntilDone должен вернуть status: success при завершении задачи', async () => {
    let callCount = 0;
    const mockFetch = jest.fn().mockImplementation(async () => {
      callCount++;
      if (callCount === 1) {
        // Первый опрос - задача еще выполняется (status: null)
        return {
          ok: true,
          status: 200,
          json: async () => ({
            result: 1,
            error_code: 0,
            data: [
              {
                flow: 'eelarve.sp_koosta_saldoandmik',
                status: null,
                exec_start: '2026-09-14T10:00:00.000Z',
                exec_end: null,
              },
            ],
          }),
        };
      }
      // Второй опрос - задача завершена
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
              exec_end: '2026-09-14T10:10:00.000Z',
            },
          ],
        }),
      };
    });

    const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
    const mockSleep = jest.fn().mockResolvedValue(undefined);

    const result = await watchTaskUntilDone(
      { userId: 2477, taskName: 'eelarve.sp_koosta_saldoandmik', pollIntervalMs: 10, maxTimeoutMs: 1000 },
      { apiClient: client, sleepFn: mockSleep }
    );

    expect(result.status).toBe('success');
    expect(callCount).toBe(2);
    expect(mockSleep).toHaveBeenCalledTimes(1);
  });

  it('watchTaskUntilDone должен вернуть status: failed при падении задачи', async () => {
    const mockFetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        result: 1,
        error_code: 1,
        error_message: 'Fatal error in stored procedure',
        data: [
          {
            flow: 'eelarve.salvesta_lisa_1_5_kontrol',
            status: 'failed',
            exec_start: '2026-09-14T10:00:00.000Z',
            exec_end: '2026-09-14T10:01:00.000Z',
          },
        ],
      }),
    });

    const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
    const result = await watchTaskUntilDone(
      { userId: 2477, taskName: 'eelarve.salvesta_lisa_1_5_kontrol', pollIntervalMs: 10, maxTimeoutMs: 1000 },
      { apiClient: client, sleepFn: jest.fn().mockResolvedValue(undefined) }
    );

    expect(result.status).toBe('failed');
    expect(result.error).toBe('Fatal error in stored procedure');
  });

  it('watchTaskUntilDone должен вернуть status: timeout при превышении времени', async () => {
    const mockFetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        result: 1,
        error_code: 0,
        data: [
          {
            flow: 'eelarve.sp_koosta_saldoandmik',
            status: null,
            exec_start: '2026-09-14T10:00:00.000Z',
            exec_end: null,
          },
        ],
      }),
    });

    const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
    const result = await watchTaskUntilDone(
      { userId: 2477, taskName: 'eelarve.sp_koosta_saldoandmik', pollIntervalMs: 50, maxTimeoutMs: 100 },
      { apiClient: client, sleepFn: () => new Promise((res) => setTimeout(res, 60)) }
    );

    expect(result.status).toBe('timeout');
  });

  it('inspectLogExecutionResult должен выявлять сбои (connect ETIMEDOUT) даже при status: success', () => {
    const rawLogEntry = {
      flow: 'sendFinBitReport',
      error: null,
      result: [
        {
          email: 'vladislav.gordin@gmail.com',
          error: 'connect ETIMEDOUT 213.184.47.202:25',
          success: false,
          response: 'connect ETIMEDOUT 213.184.47.202:25',
          invoicesCount: 2,
        },
      ],
      status: 'success' as const,
      exec_end: '2026-09-18T12:16:00.742581+03:00',
      response: 'vladislav.gordin@gmail.com: connect ETIMEDOUT 213.184.47.202:25',
      exec_start: '2026-09-18T12:12:40.086253+03:00',
    };

    const inspection = inspectLogExecutionResult(rawLogEntry);

    expect(inspection.hasErrors).toBe(true);
    expect(inspection.errorDetails).toContain('vladislav.gordin@gmail.com: connect ETIMEDOUT 213.184.47.202:25');
    expect(inspection.resultSummary).toContain('Kokku: 1, õnnestus: 0, vigu: 1');
  });

  it('watchTaskUntilDone должен переводить задачу в status: failed, если в result обнаружены ошибки при status: success', async () => {
    const mockFetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        result: 1,
        error_code: 0,
        data: [
          {
            flow: 'sendFinBitReport',
            status: 'success',
            exec_start: '2026-09-18T12:12:40.000Z',
            exec_end: '2026-09-18T12:16:00.000Z',
            result: [
              {
                email: 'vladislav.gordin@gmail.com',
                error: 'connect ETIMEDOUT 213.184.47.202:25',
                success: false,
              },
            ],
            response: 'vladislav.gordin@gmail.com: connect ETIMEDOUT 213.184.47.202:25',
          },
        ],
      }),
    });

    const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
    const result = await watchTaskUntilDone(
      { userId: 2477, taskName: 'sendFinBitReport', pollIntervalMs: 10, maxTimeoutMs: 1000 },
      { apiClient: client, sleepFn: jest.fn().mockResolvedValue(undefined) }
    );

    expect(result.status).toBe('failed');
    expect(result.hasErrors).toBe(true);
    expect(result.errorDetails).toContain('connect ETIMEDOUT');
    expect(result.resultSummary).toContain('vigu: 1');
  });
});
