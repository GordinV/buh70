import { ApiClient, defaultApiClient } from '../shared/api_client';
import { watchTaskUntilDone } from '../logs_watcher/agent';
import {
  StartLisa1Lisa5Input,
  StartLisa1Lisa5InputSchema,
  Lisa1Lisa5Result,
  Lisa1Lisa5ResultSchema,
  TASK_FLOW_LISA1_LISA5,
} from './schemas';
import { startLisa1Lisa5 } from './tools';

export interface Lisa1Lisa5Options {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
  pollIntervalMs?: number;
  maxTimeoutMs?: number;
}

/**
 * Субагент расчета контроля Lisa 1 / Lisa 5:
 * 1. Инициирует фоновый расчет через POST /task/calcLisa1Lisa5/
 * 2. Делегирует мониторинг субагенту logs_watcher
 * 3. Возвращает агрегированный результат выполнения
 */
export async function runLisa1Lisa5Subagent(
  input: StartLisa1Lisa5Input = {},
  options: Lisa1Lisa5Options = {}
): Promise<Lisa1Lisa5Result> {
  const validated = StartLisa1Lisa5InputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;

  // 1. Асинхронный запуск
  const startResult = await startLisa1Lisa5(validated, apiClient);
  const logId = startResult.log_id;

  // 2. Ожидание завершения через logs_watcher
  const watchResult = await watchTaskUntilDone(
    {
      userId: validated.userId,
      taskName: TASK_FLOW_LISA1_LISA5,
      pollIntervalMs: options.pollIntervalMs,
      maxTimeoutMs: options.maxTimeoutMs,
    },
    { apiClient, sleepFn: options.sleepFn }
  );

  return Lisa1Lisa5ResultSchema.parse({
    flow: TASK_FLOW_LISA1_LISA5,
    logId,
    status: watchResult.status,
    execStart: watchResult.execStart,
    execEnd: watchResult.execEnd,
    durationMs: watchResult.durationMs,
    error: watchResult.error,
  });
}
