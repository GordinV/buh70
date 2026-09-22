import { ApiClient, defaultApiClient } from '../shared/api_client';
import { watchTaskUntilDone } from '../logs_watcher/agent';
import {
  StartGetEarvedInput,
  StartGetEarvedInputSchema,
  GetEarvedResult,
  GetEarvedResultSchema,
  TASK_FLOW_GET_EARVED,
} from './schemas';
import { startGetEarved } from './tools';

export interface GetEarvedOptions {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
  pollIntervalMs?: number;
  maxTimeoutMs?: number;
}

/**
 * Субагент импорта счетов из FinBit:
 * 1. Инициирует неблокирующий расчет через POST /task/getEarved/ с is_agent: true
 * 2. Мониторит статус выполнения через logs_watcher (flow: docs.sp_loe_earved)
 * 3. Возвращает агрегированный результат выполнения
 */
export async function runGetEarvedSubagent(
  input: StartGetEarvedInput = {},
  options: GetEarvedOptions = {}
): Promise<GetEarvedResult> {
  const validated = StartGetEarvedInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;

  // 1. Асинхронный неблокирующий запуск в бэкенде
  const startResult = await startGetEarved(validated, apiClient);
  const logId = startResult.log_id;

  // Если процедура уже завершена сразу (например, 0 счетов за дату), не ждем в logs_watcher
  if (logId === 0 || startResult.data?.status === 'COMPLETED') {
    return {
      flow: TASK_FLOW_GET_EARVED,
      logId: logId,
      status: 'success',
      durationMs: 0,
    };
  }

  // 2. Ожидание завершения процедуры через logs_watcher
  const watchResult = await watchTaskUntilDone(
    {
      userId: validated.userId,
      taskName: TASK_FLOW_GET_EARVED,
      pollIntervalMs: options.pollIntervalMs,
      maxTimeoutMs: options.maxTimeoutMs,
    },
    { apiClient, sleepFn: options.sleepFn }
  );

  return GetEarvedResultSchema.parse({
    flow: TASK_FLOW_GET_EARVED,
    logId,
    status: watchResult.status,
    execStart: watchResult.execStart,
    execEnd: watchResult.execEnd,
    durationMs: watchResult.durationMs,
    error: watchResult.error,
  });
}
