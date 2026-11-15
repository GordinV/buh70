import { ApiClient, defaultApiClient } from '../shared/api_client';
import { watchTaskUntilDone } from '../logs_watcher/agent';
import {
  StartCheckAsutusInput,
  StartCheckAsutusInputSchema,
  CheckAsutusResult,
  CheckAsutusResultSchema,
  TASK_FLOW_CHECK_ASUTUS,
} from './schemas';
import { startCheckAsutus } from './tools';

export interface CheckAsutusOptions {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
  pollIntervalMs?: number;
  maxTimeoutMs?: number;
}

/**
 * Извлекает из result лога checkAsutusAvailability список рег.кодов отсутствующих контр-агентов
 */
export function extractMissingAsutused(result: unknown): {
  missing: string[];
  totalMissing: number;
  sourceLogId: number | null;
} {
  if (!result || typeof result !== 'object') {
    return { missing: [], totalMissing: 0, sourceLogId: null };
  }
  const obj = result as Record<string, unknown>;
  const missing = Array.isArray(obj.missing)
    ? (obj.missing as unknown[]).map((v) => String(v).trim()).filter((v) => v !== '')
    : [];
  const sourceLogId = typeof obj.source_log_id === 'number' ? obj.source_log_id : null;
  return { missing, totalMissing: missing.length, sourceLogId };
}

/**
 * Субагент проверки наличия контр-агентов из счетов FinBit:
 * 1. Инициирует неблокирующий вызов POST /task/checkAsutusAvailability/ (с logId родительского getEarved)
 * 2. Мониторит статус выполнения через logs_watcher (flow: checkAsutusAvailability)
 * 3. Из result лога извлекает рег.коды организаций, которых нет в libs.asutus
 */
export async function runCheckAsutusSubagent(
  input: StartCheckAsutusInput = {},
  options: CheckAsutusOptions = {}
): Promise<CheckAsutusResult> {
  const validated = StartCheckAsutusInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;

  // 1. Асинхронный неблокирующий запуск в бэкенде
  const startResult = await startCheckAsutus(validated, apiClient);
  const logId = startResult.log_id;

  // 2. Ожидание завершения через logs_watcher
  const watchResult = await watchTaskUntilDone(
    {
      userId: validated.userId,
      taskName: TASK_FLOW_CHECK_ASUTUS,
      logId: typeof logId === 'number' && logId > 0 ? logId : undefined,
      pollIntervalMs: options.pollIntervalMs,
      maxTimeoutMs: options.maxTimeoutMs,
    },
    { apiClient, sleepFn: options.sleepFn }
  );

  // 3. Извлечение списка отсутствующих контр-агентов
  const { missing, totalMissing, sourceLogId } = extractMissingAsutused(watchResult.result);

  return CheckAsutusResultSchema.parse({
    flow: TASK_FLOW_CHECK_ASUTUS,
    logId,
    status: watchResult.status,
    execStart: watchResult.execStart,
    execEnd: watchResult.execEnd,
    durationMs: watchResult.durationMs,
    error: watchResult.error,
    hasErrors: watchResult.hasErrors,
    errorDetails: watchResult.errorDetails,
    resultSummary: watchResult.resultSummary,
    missing,
    totalMissing,
    sourceLogId,
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
    // logId родительской задачи getEarved (если передан оркестратором); иначе бэкенд найдет последний лог getEarved сам
    const logId = (ctx.params?.logId as number) ?? (ctx.params?.paramLogId as number) ?? undefined;

    const extraEmails = Array.isArray(ctx.params?.extraEmails)
      ? (ctx.params.extraEmails as string[])
      : undefined;

    const res = await startCheckAsutus(
      { userId: finalUserId, rekvId: finalRekvId, logId: logId || undefined, extraEmails },
      ctx.apiClient
    );
    return res.log_id;
  },
  resolveParentParams: (state: { tasks: Record<string, { log_id?: number | null }> }): Record<string, unknown> => {
    const parentLogId = state.tasks?.['getEarved']?.log_id;
    return parentLogId ? { logId: parentLogId } : {};
  },
  enrichReportStep: (
    stepLog: Record<string, unknown> | null
  ): { resultSummary?: string } => {
    const { missing, totalMissing } = extractMissingAsutused(stepLog ? stepLog.result : undefined);
    if (!stepLog || !stepLog.exec_start || !stepLog.result) {
      return {};
    }
    const baseSummary =
      totalMissing > 0
        ? `Puuduvad asutused (${totalMissing}): ${missing.join(', ')}`
        : 'Kõik asutused on olemas';
    const mail = (stepLog.mail ?? (stepLog.result as Record<string, unknown>).mail) as
      | { sent?: boolean; skipped?: string | null; recipients?: string[]; error?: string | null }
      | undefined;
    let mailSummary = '';
    if (mail) {
      if (mail.sent) mailSummary = `; teavitus saadetud: ${(mail.recipients || []).join(', ')}`;
      else if (mail.error) mailSummary = `; teavituse saatmine ebaõnnestus: ${mail.error}`;
      else if (mail.skipped) mailSummary = `; teavitust ei saadetud (${mail.skipped})`;
    }
    return { resultSummary: baseSummary + mailSummary };
  },
};
