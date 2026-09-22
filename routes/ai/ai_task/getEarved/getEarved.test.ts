import { ApiClient } from '../shared/api_client';
import { runGetEarvedSubagent } from './agent';
import { startGetEarved } from './tools';
import { TASK_FLOW_GET_EARVED, getDefaultDateQueryFrom } from './schemas';

describe('Субагент getEarved', () => {
  it('startGetEarved должен вызывать /task/getEarved/ с флагом is_agent: true и возвращать log_id', async () => {
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
          log_id: 8888,
          data: {
            action: 'Import FinBit arved',
            status: 'STARTED',
            log_id: 8888,
          },
          error_message: null,
        }),
      };
    });

    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

    const res = await startGetEarved(
      { userId: 2477, rekvId: 63, dateQueryFrom: '2026-09-17' },
      client
    );

    expect(capturedUrl).toBe('http://test-server/task/getEarved/');
    expect(capturedBody).toEqual({
      user_id: 2477,
      rekv_id: 63,
      is_agent: true,
      date_query_from: '2026-09-17',
    });
    expect(res.log_id).toBe(8888);
    expect(res.status).toBe(200);
  });

  it('startGetEarved должен по умолчанию подставлять дату вчерашнего дня (текущая дата минус 1 день)', async () => {
    let capturedBody: Record<string, unknown> = {};

    const mockFetch = jest.fn().mockImplementation(async (_url: string, init?: RequestInit) => {
      if (init?.body) {
        capturedBody = JSON.parse(init.body as string);
      }
      return {
        ok: true,
        status: 200,
        json: async () => ({
          status: 200,
          result: 1,
          log_id: 8889,
          data: { action: 'Import FinBit arved', status: 'STARTED', log_id: 8889 },
          error_message: null,
        }),
      };
    });

    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

    // Вызываем без указания dateQueryFrom
    await startGetEarved({ userId: 2477, rekvId: 63 }, client);

    const expectedDate = getDefaultDateQueryFrom();
    expect(capturedBody.date_query_from).toBe(expectedDate);
  });

  it('getDefaultDateQueryFrom корректно вычисляет дату минус 1 день', () => {
    expect(getDefaultDateQueryFrom(new Date('2026-09-17T12:00:00'))).toBe('2026-09-16');
    expect(getDefaultDateQueryFrom(new Date('2026-01-01T00:00:00'))).toBe('2025-12-31');
    expect(getDefaultDateQueryFrom(new Date('2024-03-01T00:00:00'))).toBe('2024-02-29'); // високосный год
  });

  it('runGetEarvedSubagent должен запускать задачу и возвращать результат ожидания через logs_watcher', async () => {
    const mockFetch = jest.fn().mockImplementation(async (url: string) => {
      if (url.includes('/task/getEarved/')) {
        return {
          ok: true,
          status: 200,
          json: async () => ({
            status: 200,
            result: 1,
            log_id: 8888,
            data: { action: 'Import FinBit arved', status: 'STARTED', log_id: 8888 },
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
            data: [
              {
                flow: TASK_FLOW_GET_EARVED,
                status: 'success',
                exec_start: '2026-09-17T12:00:00.000Z',
                exec_end: '2026-09-17T12:02:00.000Z',
              },
            ],
          }),
        };
      }
      throw new Error(`Unexpected URL: ${url}`);
    });

    const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

    const result = await runGetEarvedSubagent(
      { userId: 2477, rekvId: 63 },
      { apiClient: client, sleepFn: async () => {} }
    );

    expect(result.flow).toBe(TASK_FLOW_GET_EARVED);
    expect(result.logId).toBe(8888);
    expect(result.status).toBe('success');
    expect(result.execStart).toBe('2026-09-17T12:00:00.000Z');
    expect(result.execEnd).toBe('2026-09-17T12:02:00.000Z');
  });
});
