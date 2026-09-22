import { ApiClient, defaultApiClient } from '../shared/api_client';
import { watchTaskUntilDone } from '../logs_watcher/agent';
import {
  StartCalcArvJaakInput,
  StartCalcArvJaakInputSchema,
  CalcArvJaakResult,
  CalcArvJaakResultSchema,
  TASK_FLOW_CALC_ARV_JAAK,
} from './schemas';
import { startCalcArvJaak } from './tools';

export interface CalcArvJaakOptions {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
  pollIntervalMs?: number;
  maxTimeoutMs?: number;
}

/**
 * Субагент пересчета остатков счетов:
 * 1. Инициирует расчет через POST /task/calcArvJaak/
 * 2. Делегирует мониторинг субагенту logs_watcher
 * 3. Возвращает агрегированный результат выполнения
 */
export async function runCalcArvJaakSubagent(
  input: StartCalcArvJaakInput = {},
  options: CalcArvJaakOptions = {}
): Promise<CalcArvJaakResult> {
  const validated = StartCalcArvJaakInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;

  // 1. Асинхронный запуск
  const startResult = await startCalcArvJaak(validated, apiClient);
  const logId = startResult.log_id;

  // 2. Ожидание завершения через logs_watcher
  const watchResult = await watchTaskUntilDone(
    {
      userId: validated.userId,
      taskName: TASK_FLOW_CALC_ARV_JAAK,
      pollIntervalMs: options.pollIntervalMs,
      maxTimeoutMs: options.maxTimeoutMs,
    },
    { apiClient, sleepFn: options.sleepFn }
  );

  return CalcArvJaakResultSchema.parse({
    flow: TASK_FLOW_CALC_ARV_JAAK,
    logId,
    status: watchResult.status,
    execStart: watchResult.execStart,
    execEnd: watchResult.execEnd,
    durationMs: watchResult.durationMs,
    error: watchResult.error,
  });
}
