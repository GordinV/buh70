import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  WatchTaskInput,
  WatchTaskInputSchema,
  WatchTaskOutput,
  WatchTaskOutputSchema,
} from './schemas';
import { readTaskLog } from './tools';

export interface WatcherOptions {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
}

const defaultSleep = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

export interface LogInspectionResult {
  hasErrors: boolean;
  errorDetails?: string;
  resultSummary?: string;
  totalCount?: number;
  successCount?: number;
  failCount?: number;
}

/**
 * Глубокая инспекция результата выполнения задачи из ou.logs.
 * Проверяет result (массивы, success: false, ошибки), response и error.
 */
export function inspectLogExecutionResult(entry: {
  status?: string | null;
  error?: string | null;
  result?: unknown;
  response?: string | null;
}): LogInspectionResult {
  const errors: string[] = [];

  // 1. Проверяем поле error
  if (entry.error && typeof entry.error === 'string' && entry.error.trim().length > 0 && entry.error !== 'null') {
    errors.push(entry.error.trim());
  }

  // 2. Проверяем структуру result
  let totalCount = 0;
  let successCount = 0;
  let failCount = 0;

  if (Array.isArray(entry.result)) {
    totalCount = entry.result.length;
    for (const item of entry.result) {
      if (item && typeof item === 'object') {
        const itemObj = item as Record<string, unknown>;
        const isSuccess = itemObj.success === true || (itemObj.success === undefined && !itemObj.error);
        if (isSuccess) {
          successCount++;
        } else {
          failCount++;
          const target = itemObj.email || itemObj.recipient || itemObj.id || '';
          const errMsg = itemObj.error || itemObj.response || 'Viga täitmisel';
          errors.push(target ? `${target}: ${errMsg}` : String(errMsg));
        }
      }
    }
  } else if (entry.result && typeof entry.result === 'object') {
    const resObj = entry.result as Record<string, unknown>;
    if (resObj.success === false || resObj.error) {
      failCount++;
      errors.push(String(resObj.error || resObj.response || 'Ilmnes viga'));
    }
  }

  // 3. Проверяем поле response, если errors пока пуст, но status='failed'
  if (errors.length === 0 && entry.status === 'failed' && entry.response) {
    errors.push(String(entry.response).trim());
  }

  const hasErrors = errors.length > 0;
  let resultSummary: string | undefined;

  if (totalCount > 0) {
    resultSummary = `Kokku: ${totalCount}, õnnestus: ${successCount}, vigu: ${failCount}`;
    if (errors.length > 0) {
      resultSummary += ` (${errors.slice(0, 2).join('; ')})`;
    }
  } else if (entry.response) {
    resultSummary = String(entry.response).slice(0, 200);
  }

  return {
    hasErrors,
    errorDetails: errors.length > 0 ? errors.join('; ') : undefined,
    resultSummary,
    totalCount: totalCount > 0 ? totalCount : undefined,
    successCount: totalCount > 0 ? successCount : undefined,
    failCount: totalCount > 0 ? failCount : undefined,
  };
}

/**
 * Watchdog субагент: опрашивает логи фонового процесса до терминального состояния
 */
export async function watchTaskUntilDone(
  input: WatchTaskInput,
  options: WatcherOptions = {}
): Promise<WatchTaskOutput> {
  const validated = WatchTaskInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;
  const sleep = options.sleepFn || defaultSleep;

  const pollInterval = validated.pollIntervalMs || apiClient.getConfig().taskPollIntervalMs;
  const maxTimeout = validated.maxTimeoutMs || apiClient.getConfig().taskTimeoutMs;
  const startTime = Date.now();

  while (Date.now() - startTime < maxTimeout) {
    try {
      const logResult = await readTaskLog(
        { userId: validated.userId, taskName: validated.taskName },
        apiClient
      );

      if (logResult.data && logResult.data.length > 0) {
        // Берем последнюю запись лога
        const latestEntry = logResult.data[logResult.data.length - 1];
        const inspection = inspectLogExecutionResult(latestEntry);

        if (latestEntry.status === 'success') {
          const duration =
            latestEntry.exec_start && latestEntry.exec_end
              ? new Date(latestEntry.exec_end).getTime() - new Date(latestEntry.exec_start).getTime()
              : Date.now() - startTime;

          return WatchTaskOutputSchema.parse({
            taskName: validated.taskName,
            status: inspection.hasErrors ? 'failed' : 'success',
            execStart: latestEntry.exec_start,
            execEnd: latestEntry.exec_end ?? undefined,
            durationMs: duration > 0 ? duration : undefined,
            error: inspection.errorDetails,
            result: latestEntry.result,
            response: latestEntry.response ?? undefined,
            hasErrors: inspection.hasErrors,
            errorDetails: inspection.errorDetails,
            resultSummary: inspection.resultSummary,
          });
        }

        if (latestEntry.status === 'failed') {
          return WatchTaskOutputSchema.parse({
            taskName: validated.taskName,
            status: 'failed',
            execStart: latestEntry.exec_start,
            execEnd: latestEntry.exec_end ?? undefined,
            error: inspection.errorDetails || logResult.error_message || 'Task failed in ou.logs',
            result: latestEntry.result,
            response: latestEntry.response ?? undefined,
            hasErrors: true,
            errorDetails: inspection.errorDetails,
            resultSummary: inspection.resultSummary,
          });
        }
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      console.warn(`[logs_watcher] Viga logi päringul ${validated.taskName}: ${message}`);
    }

    // Ждем интервал перед следующим опросом
    await sleep(pollInterval);
  }

  // Превышен таймаут
  return WatchTaskOutputSchema.parse({
    taskName: validated.taskName,
    status: 'timeout',
    durationMs: Date.now() - startTime,
    error: `Maksimaalne ooteaeg ületatud (${maxTimeout} ms)`,
  });
}

export interface TaskStatusCheckResult {
  status: 'success' | 'failed' | 'running' | 'not_started';
  rawStatus?: string | null;
  execStart?: string;
  execEnd?: string;
  durationMs?: number;
  error?: string;
  result?: unknown;
  response?: string | null;
  hasErrors?: boolean;
  errorDetails?: string;
  resultSummary?: string;
}

/**
 * Разовая неблокирующая проверка статуса задачи в ou.logs (для тиков оркестратора)
 */
export async function checkTaskStatus(
  userId: number,
  taskName: string,
  apiClient: ApiClient = defaultApiClient
): Promise<TaskStatusCheckResult> {
  try {
    const logResult = await readTaskLog({ userId, taskName }, apiClient);
    if (logResult.data && logResult.data.length > 0) {
      const latestEntry = logResult.data[logResult.data.length - 1];

      // Если даты/времени старта нет в логе — возвращаем not_started
      if (!latestEntry.exec_start) {
        return {
          status: 'not_started',
          error: 'Algusaeg (exec_start) puudub ou.logs kirjes',
        };
      }

      const inspection = inspectLogExecutionResult(latestEntry);

      if (latestEntry.status === 'success') {
        const duration =
          latestEntry.exec_start && latestEntry.exec_end
            ? new Date(latestEntry.exec_end).getTime() - new Date(latestEntry.exec_start).getTime()
            : undefined;
        return {
          status: inspection.hasErrors ? 'failed' : 'success',
          rawStatus: latestEntry.status,
          execStart: latestEntry.exec_start,
          execEnd: latestEntry.exec_end ?? undefined,
          durationMs: duration && duration > 0 ? duration : undefined,
          error: inspection.errorDetails,
          result: latestEntry.result,
          response: latestEntry.response ?? undefined,
          hasErrors: inspection.hasErrors,
          errorDetails: inspection.errorDetails,
          resultSummary: inspection.resultSummary,
        };
      }
      if (latestEntry.status === 'failed') {
        return {
          status: 'failed',
          rawStatus: latestEntry.status,
          execStart: latestEntry.exec_start,
          execEnd: latestEntry.exec_end ?? undefined,
          error: inspection.errorDetails || logResult.error_message || 'Task failed in ou.logs',
          result: latestEntry.result,
          response: latestEntry.response ?? undefined,
          hasErrors: true,
          errorDetails: inspection.errorDetails,
          resultSummary: inspection.resultSummary,
        };
      }
      return {
        status: 'running',
        rawStatus: latestEntry.status,
        execStart: latestEntry.exec_start,
        result: latestEntry.result,
        response: latestEntry.response ?? undefined,
      };
    }
    return { status: 'not_started', error: 'Ühtegi logikirjet ei leitud' };
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return { status: 'running', error: message };
  }
}

