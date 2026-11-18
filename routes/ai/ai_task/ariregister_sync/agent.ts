import { ApiClient, defaultApiClient, getConfig } from '../shared/api_client';
import { watchTaskUntilDone } from '../logs_watcher/agent';
import {
  AriregisterSyncResult,
  AriregisterSyncResultSchema,
  StartAriregisterSyncInput,
  StartAriregisterSyncInputSchema,
  TASK_FLOW_ARIREGISTER_SYNC,
} from './schemas';
import { startAriregisterSync } from './tools';

export interface AriregisterSyncOptions {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
  pollIntervalMs?: number;
  maxTimeoutMs?: number;
}

export function parseAriregisterSyncResult(result: unknown): {
  fileDate: string | null;
  rowsRead: number;
  skipped: number;
  inserted: number;
  updated: number;
  deleted: number;
  total: number;
  resultSummary: string;
} {
  if (!result || typeof result !== 'object') {
    return {
      fileDate: null,
      rowsRead: 0,
      skipped: 0,
      inserted: 0,
      updated: 0,
      deleted: 0,
      total: 0,
      resultSummary: 'Äriregister: 0 kirjet, +0 / ~0 / -0',
    };
  }

  const obj = result as Record<string, unknown>;
  const fileDate = typeof obj.file_date === 'string' ? obj.file_date : null;
  const rowsRead = typeof obj.rows_read === 'number' ? obj.rows_read : 0;
  const skipped = typeof obj.skipped === 'number' ? obj.skipped : 0;
  const inserted = typeof obj.inserted === 'number' ? obj.inserted : 0;
  const updated = typeof obj.updated === 'number' ? obj.updated : 0;
  const deleted = typeof obj.deleted === 'number' ? obj.deleted : 0;
  const total = typeof obj.total === 'number' ? obj.total : 0;

  return {
    fileDate,
    rowsRead,
    skipped,
    inserted,
    updated,
    deleted,
    total,
    resultSummary: `Äriregister: ${total} kirjet, +${inserted} / ~${updated} / -${deleted}`,
  };
}

/**
 * Субагент ariregister_sync:
 * 1. Неблокирующий запуск POST /task/syncAriregister/
 * 2. При 409 already_running возвращает статус PENDING (не FAILED)
 * 3. Мониторинг через logs_watcher (flow: ariregisterSync) и разбор счётчиков
 */
export async function runAriregisterSyncSubagent(
  input: StartAriregisterSyncInput = {},
  options: AriregisterSyncOptions = {}
): Promise<AriregisterSyncResult> {
  const validated = StartAriregisterSyncInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;

  const startResult = await startAriregisterSync(validated, apiClient);

  if (startResult.alreadyRunning) {
    return AriregisterSyncResultSchema.parse({
      flow: TASK_FLOW_ARIREGISTER_SYNC,
      logId: null,
      status: 'pending',
      alreadyRunning: true,
      fileDate: null,
      rowsRead: 0,
      skipped: 0,
      inserted: 0,
      updated: 0,
      deleted: 0,
      total: 0,
      resultSummary: 'Äriregister: sünkroniseerimine juba töötab (409), ootel',
    });
  }

  const logId = startResult.log_id;
  const watchResult = await watchTaskUntilDone(
    {
      userId: validated.userId,
      taskName: TASK_FLOW_ARIREGISTER_SYNC,
      logId: typeof logId === 'number' && logId > 0 ? logId : undefined,
      pollIntervalMs: options.pollIntervalMs,
      maxTimeoutMs: options.maxTimeoutMs,
    },
    { apiClient, sleepFn: options.sleepFn }
  );

  const parsed = parseAriregisterSyncResult(watchResult.result);

  return AriregisterSyncResultSchema.parse({
    flow: TASK_FLOW_ARIREGISTER_SYNC,
    logId,
    status: watchResult.status,
    alreadyRunning: false,
    execStart: watchResult.execStart,
    execEnd: watchResult.execEnd,
    durationMs: watchResult.durationMs,
    error: watchResult.error,
    hasErrors: watchResult.hasErrors,
    errorDetails: watchResult.errorDetails,
    ...parsed,
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
    const dryRun = typeof ctx.params?.dryRun === 'boolean' ? (ctx.params.dryRun as boolean) : false;

    const res = await startAriregisterSync(
      { userId: finalUserId, rekvId: finalRekvId, dryRun },
      ctx.apiClient
    );

    if (res.alreadyRunning) {
      // Retryable: оркестратор оставит задачу в PENDING до следующего тика
      throw new Error('Äriregister: sünkroniseerimine juba töötab (409)');
    }

    return res.log_id;
  },
  validatePrerequisites: (): string | null => {
    const hash = getConfig().inforegisterHash;
    return hash ? null : 'INFOREGISTER_HASH puudub';
  },
  enrichReportStep: (stepLog: Record<string, unknown> | null): { resultSummary?: string } => {
    if (!stepLog || !stepLog.exec_start || !stepLog.result) {
      return {};
    }
    const p = parseAriregisterSyncResult(stepLog.result);
    return { resultSummary: p.resultSummary };
  },
};
