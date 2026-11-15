import { ApiClient, defaultApiClient } from '../shared/api_client';
import { watchTaskUntilDone } from '../logs_watcher/agent';
import {
  StartInforegisterInput,
  StartInforegisterInputSchema,
  InforegisterItem,
  InforegisterResult,
  InforegisterResultSchema,
  TASK_FLOW_INFOREGISTER,
} from './schemas';
import { startInforegister } from './tools';

export interface InforegisterOptions {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
  pollIntervalMs?: number;
  maxTimeoutMs?: number;
}

/** Статусы, не требующие внимания человека */
const OK_STATUSES = new Set(['created', 'would_create', 'exists']);

/**
 * Разбирает result лога getInforegister в агрегированные счетчики
 */
export function parseInforegisterResult(result: unknown): {
  dryRun: boolean;
  total: number;
  created: number;
  wouldCreate: number;
  needsAttention: number;
  callsSpent: number;
  remainingYear: number | null;
  items: InforegisterItem[];
} {
  const empty = {
    dryRun: true,
    total: 0,
    created: 0,
    wouldCreate: 0,
    needsAttention: 0,
    callsSpent: 0,
    remainingYear: null,
    items: [] as InforegisterItem[],
  };
  if (!result || typeof result !== 'object') return empty;

  const obj = result as Record<string, unknown>;
  const items = (Array.isArray(obj.items) ? obj.items : [])
    .filter((i): i is Record<string, unknown> => !!i && typeof i === 'object')
    .map((i) => ({
      regkood: String(i.regkood ?? ''),
      status: String(i.status ?? ''),
      nimetus: typeof i.nimetus === 'string' ? i.nimetus : null,
      asutus_id: typeof i.asutus_id === 'number' ? i.asutus_id : null,
      source: typeof i.source === 'string' ? i.source : null,
      error: typeof i.error === 'string' ? i.error : null,
    }));

  return {
    dryRun: obj.dry_run !== false,
    total: typeof obj.total === 'number' ? obj.total : items.length,
    created: typeof obj.created === 'number' ? obj.created : 0,
    wouldCreate: typeof obj.would_create === 'number' ? obj.would_create : 0,
    needsAttention: items.filter((i) => !OK_STATUSES.has(i.status)).length,
    callsSpent: typeof obj.calls_spent === 'number' ? obj.calls_spent : 0,
    remainingYear: typeof obj.remaining_year === 'number' ? obj.remaining_year : null,
    items,
  };
}

/**
 * Субагент Inforegister:
 * 1. Неблокирующий запуск POST /task/getInforegister/ (с logId родительского check_asutus)
 * 2. Мониторинг через logs_watcher (flow: getInforegister)
 * 3. Разбор result: статус по каждой организации, расход платных вызовов
 */
export async function runInforegisterSubagent(
  input: StartInforegisterInput = {},
  options: InforegisterOptions = {}
): Promise<InforegisterResult> {
  const validated = StartInforegisterInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;

  const startResult = await startInforegister(validated, apiClient);
  const logId = startResult.log_id;

  const watchResult = await watchTaskUntilDone(
    {
      userId: validated.userId,
      taskName: TASK_FLOW_INFOREGISTER,
      logId: typeof logId === 'number' && logId > 0 ? logId : undefined,
      pollIntervalMs: options.pollIntervalMs,
      maxTimeoutMs: options.maxTimeoutMs,
    },
    { apiClient, sleepFn: options.sleepFn }
  );

  const parsed = parseInforegisterResult(watchResult.result);

  return InforegisterResultSchema.parse({
    flow: TASK_FLOW_INFOREGISTER,
    logId,
    status: watchResult.status,
    execStart: watchResult.execStart,
    execEnd: watchResult.execEnd,
    durationMs: watchResult.durationMs,
    error: watchResult.error,
    hasErrors: watchResult.hasErrors,
    errorDetails: watchResult.errorDetails,
    resultSummary: watchResult.resultSummary,
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
    // logId родительской задачи check_asutus (если передан оркестратором); иначе бэкенд найдет последний лог сам
    const logId = (ctx.params?.logId as number) ?? undefined;
    const dryRun = typeof ctx.params?.dryRun === 'boolean' ? (ctx.params.dryRun as boolean) : true;
    const maxCalls = typeof ctx.params?.maxCalls === 'number' ? (ctx.params.maxCalls as number) : undefined;

    const insecureTls = ctx.params?.insecureTls === true;

    const res = await startInforegister(
      { userId: finalUserId, rekvId: finalRekvId, logId: logId || undefined, dryRun, maxCalls, insecureTls },
      ctx.apiClient
    );
    return res.log_id;
  },
  resolveParentParams: (state: { tasks: Record<string, { log_id?: number | null }> }): Record<string, unknown> => {
    const parentLogId = state.tasks?.['check_asutus']?.log_id;
    return parentLogId ? { logId: parentLogId } : {};
  },
  enrichReportStep: (stepLog: Record<string, unknown> | null): { resultSummary?: string } => {
    if (!stepLog || !stepLog.exec_start || !stepLog.result) {
      return {};
    }
    const p = parseInforegisterResult(stepLog.result);
    if (p.total === 0) {
      return { resultSummary: 'Puuduvaid asutusi ei ole' };
    }
    const manual = p.items.filter((i) => !OK_STATUSES.has(i.status)).map((i) => `${i.regkood} (${i.status})`);
    let summary = p.dryRun
      ? `Inforegister (dry-run): leitud ${p.wouldCreate} / ${p.total}`
      : `Inforegister: lisatud ${p.created} / ${p.total}`;
    summary += `; päringuid: ${p.callsSpent}`;
    if (p.remainingYear !== null) summary += `, aastalimiidi jääk: ${p.remainingYear}`;
    if (manual.length > 0) summary += `; vajab käsitsi tööd: ${manual.join(', ')}`;
    return { resultSummary: summary };
  },
};
