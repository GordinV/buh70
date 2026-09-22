import { ApiClient, defaultApiClient } from '../shared/api_client';
import { watchTaskUntilDone } from '../logs_watcher/agent';
import {
  StartSendFinBitReportInput,
  StartSendFinBitReportInputSchema,
  SendFinBitReportResult,
  SendFinBitReportResultSchema,
  TASK_FLOW_SEND_FIN_BIT_REPORT,
} from './schemas';
import { startSendFinBitReport } from './tools';

export interface SendFinBitReportOptions {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
  pollIntervalMs?: number;
  maxTimeoutMs?: number;
}

/**
 * Субагент отправки отчетов по импортированным счетам FinBit:
 * 1. Инициирует неблокирующий вызов POST /task/sendFinBitReport/ с logId
 * 2. Мониторит статус выполнения через logs_watcher (flow: sendFinBitReport)
 * 3. Возвращает агрегированный результат выполнения
 */
export async function runSendFinBitReportSubagent(
  input: StartSendFinBitReportInput,
  options: SendFinBitReportOptions = {}
): Promise<SendFinBitReportResult> {
  const validated = StartSendFinBitReportInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;

  // 1. Асинхронный неблокирующий запуск в бэкенде
  const startResult = await startSendFinBitReport(validated, apiClient);
  const logId = startResult.log_id;

  // 2. Ожидание завершения процедуры через logs_watcher
  const watchResult = await watchTaskUntilDone(
    {
      userId: validated.userId,
      taskName: TASK_FLOW_SEND_FIN_BIT_REPORT,
      pollIntervalMs: options.pollIntervalMs,
      maxTimeoutMs: options.maxTimeoutMs,
    },
    { apiClient, sleepFn: options.sleepFn }
  );

  return SendFinBitReportResultSchema.parse({
    flow: TASK_FLOW_SEND_FIN_BIT_REPORT,
    logId,
    status: watchResult.status,
    execStart: watchResult.execStart,
    execEnd: watchResult.execEnd,
    durationMs: watchResult.durationMs,
    error: watchResult.error,
    hasErrors: watchResult.hasErrors,
    errorDetails: watchResult.errorDetails,
    resultSummary: watchResult.resultSummary,
  });
}
