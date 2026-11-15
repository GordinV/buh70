import { ApiClient, defaultApiClient } from '../shared/api_client';
import { watchTaskUntilDone } from '../logs_watcher/agent';
import {
  StartImportEarvedInput,
  StartImportEarvedInputSchema,
  ImportEarvedResult,
  ImportEarvedResultSchema,
  TASK_FLOW_IMPORT_EARVED,
} from './schemas';
import { startImportEarved } from './tools';

export interface ImportEarvedOptions {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
  pollIntervalMs?: number;
  maxTimeoutMs?: number;
}

/**
 * Извлекает из result лога импорта итоговые счетчики и список пропущенных счетов
 */
export function extractImportTotals(result: unknown): {
  totalFetched: number;
  totalImported: number;
  totalSkipped: number;
  totalFailed: number;
  imported: Array<{ doc_id: number; number: string; rekv_id?: number | null }>;
  errors: Array<{ number: string; asutusid: string; error: string }>;
  skipped: Array<{ number: string; asutusid: string; rekvId?: number | null }>;
  missing: string[];
  sourceLogId: number | null;
} {
  const empty = {
    totalFetched: 0,
    totalImported: 0,
    totalSkipped: 0,
    totalFailed: 0,
    imported: [],
    errors: [],
    skipped: [],
    missing: [],
    sourceLogId: null,
  };
  if (!result || typeof result !== 'object' || Array.isArray(result)) {
    return empty;
  }
  const obj = result as Record<string, unknown>;
  const toNum = (v: unknown): number => (typeof v === 'number' && Number.isFinite(v) ? v : 0);

  const skipped = Array.isArray(obj.skipped)
    ? (obj.skipped as Array<Record<string, unknown>>).map((s) => ({
        number: s && s.number !== undefined && s.number !== null ? String(s.number) : '',
        asutusid: s && s.asutusid !== undefined && s.asutusid !== null ? String(s.asutusid) : '',
        rekvId: typeof s?.rekvId === 'number' ? (s.rekvId as number) : null,
      }))
    : [];
  const imported = Array.isArray(obj.imported)
    ? (obj.imported as Array<Record<string, unknown>>)
        .filter((i) => i && typeof i.doc_id === 'number')
        .map((i) => ({
          doc_id: i.doc_id as number,
          number: i.number !== undefined && i.number !== null ? String(i.number) : '',
          rekv_id: typeof i.rekv_id === 'number' ? (i.rekv_id as number) : null,
        }))
    : [];
  const errors = Array.isArray(obj.errors)
    ? (obj.errors as Array<Record<string, unknown>>).map((e) => ({
        number: e && e.number !== undefined && e.number !== null ? String(e.number) : '',
        asutusid: e && e.asutusid !== undefined && e.asutusid !== null ? String(e.asutusid) : '',
        error: e && e.error !== undefined && e.error !== null ? String(e.error) : '',
      }))
    : [];
  const missing = Array.isArray(obj.missing)
    ? (obj.missing as unknown[]).map((v) => String(v).trim()).filter((v) => v !== '')
    : [];

  return {
    totalFetched: toNum(obj.totalFetched),
    totalImported: toNum(obj.totalImported),
    totalSkipped: toNum(obj.totalSkipped) || skipped.length,
    totalFailed: toNum(obj.totalFailed) || errors.length,
    imported,
    errors,
    skipped,
    missing,
    sourceLogId: typeof obj.source_log_id === 'number' ? obj.source_log_id : null,
  };
}

/**
 * Формирует эстонское резюме импорта для отчета
 */
export function buildImportSummary(totals: ReturnType<typeof extractImportTotals>): string {
  let summary = `Imporditud ${totals.totalImported} arvet (leitud: ${totals.totalFetched})`;
  if (totals.totalSkipped > 0) {
    summary += `. Vahele jäetud ${totals.totalSkipped} arvet (puuduvad asutused: ${totals.missing.join(', ')})`;
  }
  if (totals.totalFailed > 0) {
    const examples = totals.errors
      .slice(0, 3)
      .map((e) => `${e.number || '?'}: ${e.error}`)
      .join('; ');
    summary += `. Vigu: ${totals.totalFailed}${examples ? ` (${examples})` : ''}`;
  }
  return summary;
}

/**
 * Субагент разбора и сохранения счетов FinBit (частичный импорт):
 * 1. Инициирует неблокирующий вызов POST /task/importEarved/ (с logId лога getEarved)
 * 2. Бэкенд импортирует счета, контр-агенты которых есть в libs.asutus, остальные пропускает (result.skipped)
 * 3. Мониторит статус через logs_watcher (flow: docs.sp_loe_earved) и возвращает итоговые счетчики
 */
export async function runImportEarvedSubagent(
  input: StartImportEarvedInput = {},
  options: ImportEarvedOptions = {}
): Promise<ImportEarvedResult> {
  const validated = StartImportEarvedInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;

  // 1. Асинхронный неблокирующий запуск в бэкенде
  const startResult = await startImportEarved(validated, apiClient);
  const logId = startResult.log_id;

  // 2. Ожидание завершения через logs_watcher
  const watchResult = await watchTaskUntilDone(
    {
      userId: validated.userId,
      taskName: TASK_FLOW_IMPORT_EARVED,
      logId: typeof logId === 'number' && logId > 0 ? logId : undefined,
      pollIntervalMs: options.pollIntervalMs,
      maxTimeoutMs: options.maxTimeoutMs,
    },
    { apiClient, sleepFn: options.sleepFn }
  );

  // 3. Итоговые счетчики и пропущенные счета
  const totals = extractImportTotals(watchResult.result);

  return ImportEarvedResultSchema.parse({
    flow: TASK_FLOW_IMPORT_EARVED,
    logId,
    status: watchResult.status,
    execStart: watchResult.execStart,
    execEnd: watchResult.execEnd,
    durationMs: watchResult.durationMs,
    error: watchResult.error,
    hasErrors: watchResult.hasErrors,
    errorDetails: watchResult.errorDetails,
    resultSummary: watchResult.resultSummary,
    ...totals,
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

    const res = await startImportEarved(
      { userId: finalUserId, rekvId: finalRekvId, logId: logId || undefined },
      ctx.apiClient
    );
    return res.log_id;
  },
  resolveParentParams: (state: { tasks: Record<string, { log_id?: number | null }> }): Record<string, unknown> => {
    // импортируются счета, выкачанные агентом getEarved
    const parentLogId = state.tasks?.['getEarved']?.log_id;
    return parentLogId ? { logId: parentLogId } : {};
  },
  enrichReportStep: (stepLog: Record<string, unknown> | null): { resultSummary?: string } => {
    if (!stepLog || !stepLog.exec_start || !stepLog.result) {
      return {};
    }
    return { resultSummary: buildImportSummary(extractImportTotals(stepLog.result)) };
  },
};
