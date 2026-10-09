import { ApiClient, defaultApiClient } from '../shared/api_client';
import { watchTaskUntilDone } from '../logs_watcher/agent';
import {
  StartSaldoandmikInput,
  StartSaldoandmikInputSchema,
  SaldoandmikResult,
  SaldoandmikResultSchema,
  TASK_FLOW_SALDOANDMIK,
} from './schemas';
import { startSaldoandmik } from './tools';

export interface SaldoandmikOptions {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
  pollIntervalMs?: number;
  maxTimeoutMs?: number;
}

/**
 * Субагент расчета сальдоандмика:
 * 1. Инициирует фоновый расчет через POST /task/calcKondSaldoandmik/
 * 2. Делегирует мониторинг субагенту logs_watcher
 * 3. Возвращает агрегированный результат выполнения
 */
export async function runSaldoandmikSubagent(
  input: StartSaldoandmikInput = {},
  options: SaldoandmikOptions = {}
): Promise<SaldoandmikResult> {
  const validated = StartSaldoandmikInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;

  // 1. Асинхронный запуск
  const startResult = await startSaldoandmik(validated, apiClient);
  const logId = startResult.log_id;

  // 2. Ожидание завершения через logs_watcher
  const watchResult = await watchTaskUntilDone(
    {
      userId: validated.userId,
      taskName: TASK_FLOW_SALDOANDMIK,
      pollIntervalMs: options.pollIntervalMs,
      maxTimeoutMs: options.maxTimeoutMs,
    },
    { apiClient, sleepFn: options.sleepFn }
  );

  return SaldoandmikResultSchema.parse({
    flow: TASK_FLOW_SALDOANDMIK,
    logId,
    status: watchResult.status,
    execStart: watchResult.execStart,
    execEnd: watchResult.execEnd,
    durationMs: watchResult.durationMs,
    error: watchResult.error,
  });
}

export const manifest = {
  dispatch: async (ctx: {
    userId: number;
    rekvId: number;
    kond: number;
    params: Record<string, unknown>;
    apiClient: ApiClient;
  }): Promise<number | null> => {
    const finalUserId = (ctx.params?.userId as number) ?? ctx.userId;
    const finalRekvId = (ctx.params?.rekvId as number) ?? ctx.rekvId;
    const finalKond = (ctx.params?.kond as number) ?? ctx.kond;

    const res = await startSaldoandmik(
      { userId: finalUserId, rekvId: finalRekvId, kond: finalKond },
      ctx.apiClient
    );
    return res.log_id;
  },
};
