/**
 * Шаблон реализации автономного субагента для фоновой задачи
 */
import { z } from 'zod';
import { AsyncTaskStartResponseSchema } from '../shared/types';
import { ApiClient, defaultApiClient } from '../shared/api_client';
import { watchTaskUntilDone } from '../logs_watcher/agent';

// 1. Идентификатор потока в ou.logs
export const TASK_FLOW_EXAMPLE = 'docs.sp_example_calculation';

// 2. Входные параметры запуска
export const StartExampleTaskInputSchema = z.object({
  userId: z.number().optional().default(2477),
  rekvId: z.number().optional().default(63),
  customParam: z.string().optional(),
});
export type StartExampleTaskInput = z.input<typeof StartExampleTaskInputSchema>;

// 3. Схема ответа запуска (переиспользование базовой)
export const StartExampleTaskResponseSchema = AsyncTaskStartResponseSchema;
export type StartExampleTaskResponse = z.infer<typeof StartExampleTaskResponseSchema>;

// 4. Итоговый результат работы агента
export const ExampleTaskResultSchema = z.object({
  flow: z.literal(TASK_FLOW_EXAMPLE),
  logId: z.number(),
  status: z.enum(['success', 'failed', 'timeout']),
  execStart: z.string().optional(),
  execEnd: z.string().optional(),
  durationMs: z.number().optional(),
  error: z.string().optional(),
});
export type ExampleTaskResult = z.infer<typeof ExampleTaskResultSchema>;

// 5. HTTP-инструмент неблокирующего вызова API
export async function startExampleTask(
  input: StartExampleTaskInput = {},
  apiClient: ApiClient = defaultApiClient
): Promise<StartExampleTaskResponse> {
  const validated = StartExampleTaskInputSchema.parse(input);

  const payload = {
    user_id: validated.userId,
    rekv_id: validated.rekvId,
    custom_param: validated.customParam,
  };

  const raw = await apiClient.post<unknown>('/task/exampleCalculation/', payload);

  // Защитный fallback на случай штатного отсутствия данных
  if (
    raw &&
    typeof raw === 'object' &&
    'error_message' in raw &&
    (raw as { error_message?: string }).error_message === 'Data not found'
  ) {
    return {
      status: 200,
      result: 1,
      log_id: 0,
      data: { action: TASK_FLOW_EXAMPLE, status: 'COMPLETED', log_id: 0 },
      error_message: null,
    };
  }

  return StartExampleTaskResponseSchema.parse(raw);
}

// 6. Главная функция выполнения субагента
export async function runExampleSubagent(
  input: StartExampleTaskInput = {},
  options: { apiClient?: ApiClient; pollIntervalMs?: number; maxTimeoutMs?: number } = {}
): Promise<ExampleTaskResult> {
  const validated = StartExampleTaskInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;

  // 1) Неблокирующий запуск
  const startResult = await startExampleTask(validated, apiClient);
  const logId = startResult.log_id;

  // 2) Если задача завершилась немедленно (0 записей)
  if (logId === 0 || startResult.data?.status === 'COMPLETED') {
    return {
      flow: TASK_FLOW_EXAMPLE,
      logId,
      status: 'success',
      durationMs: 0,
    };
  }

  // 3) Ожидание через logs_watcher
  const watchResult = await watchTaskUntilDone(
    {
      userId: validated.userId,
      taskName: TASK_FLOW_EXAMPLE,
      pollIntervalMs: options.pollIntervalMs,
      maxTimeoutMs: options.maxTimeoutMs,
    },
    { apiClient }
  );

  return ExampleTaskResultSchema.parse({
    flow: TASK_FLOW_EXAMPLE,
    logId,
    status: watchResult.status,
    execStart: watchResult.execStart,
    execEnd: watchResult.execEnd,
    durationMs: watchResult.durationMs,
    error: watchResult.error,
  });
}
