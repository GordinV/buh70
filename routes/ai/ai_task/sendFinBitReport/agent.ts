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
      logId: typeof logId === 'number' && logId > 0 ? logId : undefined,
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

/**
 * Эстонское резюме рассылки для сводного отчета reporter.
 * result - массив результатов отправки по получателям; пустой массив при status=success означает "новых счетов не было".
 */
export function buildSendSummary(stepLog: Record<string, unknown>): string | undefined {
  const result = Array.isArray(stepLog.result) ? (stepLog.result as Array<Record<string, unknown>>) : null;
  const status = typeof stepLog.status === 'string' ? stepLog.status : null;
  const error = typeof stepLog.error === 'string' && stepLog.error.trim() !== '' && stepLog.error !== 'null' ? stepLog.error : null;

  if (!result || result.length === 0) {
    if (status === 'success') {
      return 'Uusi arveid ei olnud, teavitusi ei saadetud';
    }
    return error ? `Teavitusi ei saadetud: ${error}` : undefined;
  }

  const sent = result.filter((r) => r && r.success === true && r.already_sent !== true);
  const alreadySent = result.filter((r) => r && r.success === true && r.already_sent === true);
  const failed = result.filter((r) => !r || r.success !== true);
  const invoicesCount = sent.reduce((sum, r) => sum + (typeof r.invoicesCount === 'number' ? r.invoicesCount : 0), 0);

  let summary = `Saadetud ${sent.length} teavitust (${invoicesCount} arvet)`;
  if (alreadySent.length > 0) {
    summary += `, varem saadetud: ${alreadySent.length}`;
  }
  if (failed.length > 0) {
    const examples = failed
      .slice(0, 3)
      .map((r) => `${(r && (r.email as string)) || '?'}: ${(r && ((r.error as string) || (r.response as string))) || 'viga'}`)
      .join('; ');
    summary += `. Saatmata ${failed.length}: ${examples}`;
  }
  return summary;
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
    const logId = (ctx.params?.logId as number) ?? (ctx.params?.paramLogId as number);

    if (!logId) {
      throw new Error('sendFinBitReport viga: logId puudub (parent context import_earved log_id ei ole edastatud)');
    }

    const res = await startSendFinBitReport(
      { userId: finalUserId, rekvId: finalRekvId, logId },
      ctx.apiClient
    );
    return res.log_id;
  },
  resolveParentParams: (state: { tasks: Record<string, { log_id?: number | null }> }): Record<string, unknown> => {
    const parentLogId = state.tasks?.['import_earved']?.log_id;
    return parentLogId ? { logId: parentLogId } : {};
  },
  validatePrerequisites: (state: { tasks: Record<string, { log_id?: number | null }> }): string | null => {
    const parentLogId = state.tasks?.['import_earved']?.log_id;
    return parentLogId ? null : 'Vahele jäetud: vanemülesande import_earved log_id puudub';
  },
  enrichReportStep: (stepLog: Record<string, unknown> | null): { resultSummary?: string } => {
    if (!stepLog || !stepLog.exec_start) {
      return {};
    }
    const summary = buildSendSummary(stepLog);
    return summary ? { resultSummary: summary } : {};
  },
};
