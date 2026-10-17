import { ApiClient, defaultApiClient } from '../shared/api_client';
import { AgentDispatchContext, AgentManifest } from '../shared/agent_registry';
import { watchTaskUntilDone } from '../logs_watcher/agent';
import {
  DEFAULT_INITIAL_SINCE_DATE,
  MailDeliveryError,
  RawIncomingEmail,
  ReadMailInput,
  ReadMailInputSchema,
  ReadMailResult,
  ReadMailResultSchema,
  TASK_FLOW_READ_MAIL,
} from './schemas';
import {
  AiMailGenerateFn,
  CreateLogFn,
  EndLogFn,
  MailFetcherFn,
  createLog,
  endLog,
  executeReadMailCore,
  getDefaultMailAccess,
  loadReadMailState,
  parseDeliveryFailureWithAi,
  saveReadMailState,
  startReadMail,
  tuhistaArveSaatmiseStaatus,
  sendOtherErrorsAlertEmail,
  ALERT_EMAILS,
  SendAlertFn,
  ReadMailCoreOptions,
} from './tools';

export interface ReadMailOptions extends ReadMailCoreOptions {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
  pollIntervalMs?: number;
  maxTimeoutMs?: number;
  useLiveBackend?: boolean;
}

/**
 * Субагент read_mail:
 * По аналогии с другими агентами (saldoandmik, getEarved, calc_arv_jaak):
 * 1. Инициирует фоновое чтение почты через HTTP API бэкенда (POST /task/readMail/)
 * 2. Ожидает завершения задачи через logs_watcher (POST /task/read_log/:user_id/:task_name)
 * 3. Возвращает массив объектов с регламентными статусами ошибок доставки
 */
export async function runReadMailSubagent(
  input: ReadMailInput = {},
  options: ReadMailOptions = {}
): Promise<ReadMailResult> {
  const validated = ReadMailInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;

  // Если переданы тестовые письма или мок-функции, выполняем локальное ядро без HTTP API бэкенда
  const isDirectMode =
    Boolean(options.mailFetcher) ||
    Boolean(options.createLogFn) ||
    Boolean(options.endLogFn) ||
    Boolean(options.tuhistaStaatusFn) ||
    Boolean(validated.rawEmails && validated.rawEmails.length > 0) ||
    Boolean(validated.emailContent) ||
    Boolean(validated.emails && validated.emails.length > 0) ||
    (process.env.NODE_ENV === 'test' && !options.useLiveBackend);

  if (isDirectMode) {
    return executeReadMailCore(validated, options);
  }

  // 1. Асинхронный запуск через HTTP API бэкенда (POST /task/readMail/)
  const startResult = await startReadMail(validated, apiClient);
  const logId = startResult.log_id;

  // 2. Ожидание завершения через logs_watcher
  const watchResult = await watchTaskUntilDone(
    {
      userId: validated.userId,
      taskName: TASK_FLOW_READ_MAIL,
      pollIntervalMs: options.pollIntervalMs,
      maxTimeoutMs: options.maxTimeoutMs,
    },
    { apiClient, sleepFn: options.sleepFn }
  );

  if (watchResult.status === 'failed') {
    throw new Error(`read_mail failed: ${watchResult.error || 'Unknown error'}`);
  }

  const deliveryErrors = Array.isArray(watchResult.result) ? watchResult.result : [];
  return ReadMailResultSchema.parse(deliveryErrors);
}

/**
 * Манифест агента read_mail для интеграции в реестр Orchestrator FSM
 */
export const manifest: AgentManifest = {
  dispatch: async (ctx: AgentDispatchContext): Promise<number | null> => {
    const finalUserId = (ctx.params?.userId as number) ?? ctx.userId;
    const finalRekvId = (ctx.params?.rekvId as number) ?? ctx.rekvId;
    const emailContent = ctx.params?.emailContent as string | undefined;
    const emails = ctx.params?.emails as string[] | undefined;
    const stateFilePath = ctx.params?.stateFilePath as string | undefined;
    const sinceDate = ctx.params?.sinceDate as string | undefined;
    const forceSinceDate = ctx.params?.forceSinceDate as boolean | undefined;

    const res = await startReadMail(
      {
        userId: finalUserId,
        rekvId: finalRekvId,
        emailContent,
        emails,
        stateFilePath,
        sinceDate,
        forceSinceDate,
      },
      ctx.apiClient
    );
    return res.log_id;
  },
};

export { createLog, endLog, executeReadMailCore, sendOtherErrorsAlertEmail, ALERT_EMAILS };
