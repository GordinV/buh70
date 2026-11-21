import { ApiClient, defaultApiClient, getConfig } from '../shared/api_client';
import { watchTaskUntilDone } from '../logs_watcher/agent';
import {
  AsutusKehtivusResult,
  AsutusKehtivusResultSchema,
  StartAsutusKehtivusInput,
  StartAsutusKehtivusInputSchema,
  TASK_FLOW_CHECK_ASUTUS_KEHTIVUS,
} from './schemas';
import { startAsutusKehtivus } from './tools';

export interface AsutusKehtivusOptions {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
  pollIntervalMs?: number;
  maxTimeoutMs?: number;
}

function formatPreviewList(items: unknown[]): string {
  const preview = items
    .slice(0, 20)
    .filter((i): i is Record<string, unknown> => !!i && typeof i === 'object')
    .map((i) => {
      const reg = typeof i.regkood === 'string' ? i.regkood : '';
      const name = typeof i.nimetus === 'string' ? i.nimetus : '';
      return name ? `${reg} ${name}` : reg;
    })
    .filter(Boolean);
  return preview.join(', ');
}

export function parseAsutusKehtivusResult(result: unknown): {
  reason: string | null;
  dryRun: boolean;
  candidatesTotal: number;
  totalClosed: number;
  totalErrors: number;
  isSkipped: boolean;
  isNonRetryableFailure: boolean;
  resultSummary: string;
} {
  if (!result || typeof result !== 'object') {
    return {
      reason: null,
      dryRun: true,
      candidatesTotal: 0,
      totalClosed: 0,
      totalErrors: 0,
      isSkipped: false,
      isNonRetryableFailure: false,
      resultSummary: 'Proovikäivitus (dry-run): kandidaate ei leitud',
    };
  }

  const obj = result as Record<string, unknown>;
  const statusStr = typeof obj.status === 'string' ? obj.status : null;
  const reason = typeof obj.reason === 'string' ? obj.reason : null;
  const dryRun = obj.dry_run !== false;
  const candidatesTotal = typeof obj.candidates_total === 'number' ? obj.candidates_total : 0;
  const totalClosed = typeof obj.totalClosed === 'number' ? obj.totalClosed : 0;
  const totalErrors = typeof obj.totalErrors === 'number' ? obj.totalErrors : 0;

  if (statusStr === 'skipped' || reason === 'registry_stale') {
    return {
      reason: reason || 'registry_stale',
      dryRun,
      candidatesTotal,
      totalClosed,
      totalErrors,
      isSkipped: true,
      isNonRetryableFailure: false,
      resultSummary: 'Asutuste kehtivus: vahele jäetud (Äriregister aegunud)',
    };
  }

  if (statusStr === 'failed' || reason === 'too_many_candidates' || reason === 'no_rights') {
    const errText = typeof obj.error_message === 'string' ? obj.error_message : (reason || 'Viga');
    return {
      reason,
      dryRun,
      candidatesTotal,
      totalClosed,
      totalErrors,
      isSkipped: false,
      isNonRetryableFailure: obj.retryable === false || reason === 'too_many_candidates' || reason === 'no_rights',
      resultSummary: `Asutuste kehtivus ebaõnnestus: ${errText}`,
    };
  }

  const list = dryRun
    ? (Array.isArray(obj.would_close) ? obj.would_close : (Array.isArray(obj.closed) ? obj.closed : []))
    : (Array.isArray(obj.closed) ? obj.closed : []);
  const preview = formatPreviewList(list);

  let summary: string;
  if (dryRun) {
    summary =
      candidatesTotal > 0
        ? `Proovikäivitus (dry-run): leitud ${candidatesTotal} kandidaati, andmebaasis muudatusi ei tehtud`
        : 'Proovikäivitus (dry-run): kandidaate ei leitud';
  } else {
    summary = `Suletud kaarte: ${totalClosed}`;
  }
  if (preview) {
    summary += ` (${preview})`;
  }
  if (totalErrors > 0) {
    summary += `; vigu: ${totalErrors}`;
  }

  const mail = obj.mail as
    | { sent?: boolean; skipped?: string | null; recipients?: string[]; error?: string | null }
    | undefined;
  if (mail) {
    if (mail.sent) summary += `; teavitus saadetud: ${(mail.recipients || []).join(', ')}`;
    else if (mail.error) summary += `; teavituse saatmine ebaõnnestus: ${mail.error}`;
  }

  return {
    reason,
    dryRun,
    candidatesTotal,
    totalClosed,
    totalErrors,
    isSkipped: false,
    isNonRetryableFailure: false,
    resultSummary: summary,
  };
}

/**
 * Субагент asutus_kehtivus:
 * 1. Неблокирующий запуск POST /task/checkAsutusKehtivus/
 * 2. При 409 already_running возвращает статус pending (не failed)
 * 3. Мониторинг через logs_watcher (flow: checkAsutusKehtivus)
 */
export async function runAsutusKehtivusSubagent(
  input: StartAsutusKehtivusInput = {},
  options: AsutusKehtivusOptions = {}
): Promise<AsutusKehtivusResult> {
  const validated = StartAsutusKehtivusInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;

  const startResult = await startAsutusKehtivus(validated, apiClient);

  if (startResult.alreadyRunning) {
    return AsutusKehtivusResultSchema.parse({
      flow: TASK_FLOW_CHECK_ASUTUS_KEHTIVUS,
      logId: null,
      status: 'pending',
      alreadyRunning: true,
      reason: 'already_running',
      dryRun: validated.dryRun,
      candidatesTotal: 0,
      totalClosed: 0,
      totalErrors: 0,
      resultSummary: 'Asutuste kehtivus: kontroll juba töötab (409), ootel',
    });
  }

  const logId = startResult.log_id;
  const watchResult = await watchTaskUntilDone(
    {
      userId: validated.userId,
      taskName: TASK_FLOW_CHECK_ASUTUS_KEHTIVUS,
      logId: typeof logId === 'number' && logId > 0 ? logId : undefined,
      pollIntervalMs: options.pollIntervalMs,
      maxTimeoutMs: options.maxTimeoutMs,
    },
    { apiClient, sleepFn: options.sleepFn }
  );

  const parsed = parseAsutusKehtivusResult(watchResult.result);
  const finalStatus = parsed.isSkipped ? 'skipped' : watchResult.status;

  if (finalStatus === 'failed' && parsed.isNonRetryableFailure) {
    const err = new Error(watchResult.error || parsed.resultSummary) as Error & { retryable?: boolean };
    err.retryable = false;
    throw err;
  }

  return AsutusKehtivusResultSchema.parse({
    flow: TASK_FLOW_CHECK_ASUTUS_KEHTIVUS,
    logId,
    status: finalStatus,
    alreadyRunning: false,
    reason: parsed.reason,
    dryRun: parsed.dryRun,
    candidatesTotal: parsed.candidatesTotal,
    totalClosed: parsed.totalClosed,
    totalErrors: parsed.totalErrors,
    execStart: watchResult.execStart,
    execEnd: watchResult.execEnd,
    durationMs: watchResult.durationMs,
    error: watchResult.error,
    hasErrors: watchResult.hasErrors,
    errorDetails: watchResult.errorDetails,
    resultSummary: parsed.resultSummary,
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
    const maxClose = typeof ctx.params?.maxClose === 'number' ? (ctx.params.maxClose as number) : 100;
    const rawEmails = ctx.params?.extraEmails ?? ctx.params?.notifyEmails;
    const extraEmails = Array.isArray(rawEmails)
      ? rawEmails.filter((e): e is string => typeof e === 'string' && e.trim() !== '')
      : undefined;

    const res = await startAsutusKehtivus(
      { userId: finalUserId, rekvId: finalRekvId, dryRun, maxClose, extraEmails },
      ctx.apiClient
    );

    if (res.alreadyRunning) {
      throw new Error('Asutuste kehtivus: kontroll juba töötab (409)');
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
    const p = parseAsutusKehtivusResult(stepLog.result);
    return { resultSummary: p.resultSummary };
  },
};
