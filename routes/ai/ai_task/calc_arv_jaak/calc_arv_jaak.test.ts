import { ApiClient } from '../shared/api_client';
import { startCalcArvJaak } from './tools';
import { runCalcArvJaakSubagent } from './agent';
import { TASK_FLOW_CALC_ARV_JAAK } from './schemas';

describe('Субагент calc_arv_jaak', () => {
  it('startCalcArvJaak должен вызывать /task/calcArvJaak/ и возвращать log_id', async () => {
    const mockPost = jest.fn().mockResolvedValue({
      status: 200,
      result: 1,
      log_id: 10426,
      data: {
        action: 'calcArvJaak',
        status: 'STARTED',
        log_id: 10426,
      },
    });

    const mockClient = { post: mockPost, getConfig: () => ({}) } as unknown as ApiClient;

    const res = await startCalcArvJaak({ userId: 2477, rekvId: 63 }, mockClient);

    expect(mockPost).toHaveBeenCalledWith('/task/calcArvJaak/', {
      user_id: 2477,
      rekv_id: 63,
    });
    expect(res.log_id).toBe(10426);
    expect(res.status).toBe(200);
  });

  it('runCalcArvJaakSubagent должен запускать задачу и возвращать результат ожидания', async () => {
    const mockPost = jest
      .fn()
      // Вызов старта задачи
      .mockResolvedValueOnce({
        status: 200,
        result: 1,
        log_id: 10426,
        data: {
          action: 'calcArvJaak',
          status: 'STARTED',
          log_id: 10426,
        },
      })
      // Опрос лога
      .mockResolvedValueOnce({
        result: 1,
        error_code: 0,
        error_message: null,
        data: [
          {
            flow: TASK_FLOW_CALC_ARV_JAAK,
            status: 'success',
            exec_start: '2026-09-15T20:00:00.000Z',
            exec_end: '2026-09-15T20:05:00.000Z',
          },
        ],
      });

    const mockClient = {
      post: mockPost,
      getConfig: () => ({ taskPollIntervalMs: 10, taskTimeoutMs: 1000 }),
    } as unknown as ApiClient;

    const res = await runCalcArvJaakSubagent(
      { userId: 2477, rekvId: 63 },
      { apiClient: mockClient, sleepFn: async () => {} }
    );

    expect(res.status).toBe('success');
    expect(res.flow).toBe(TASK_FLOW_CALC_ARV_JAAK);
    expect(res.logId).toBe(10426);
  });
});
