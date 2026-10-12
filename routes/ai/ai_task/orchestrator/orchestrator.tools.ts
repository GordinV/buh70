import { ApiClient, defaultApiClient } from '../shared/api_client';
import { readTaskLog } from '../logs_watcher/tools';

const DEFAULT_TIMEZONE = 'Europe/Tallinn';

/**
 * Преобразует ISO-строку (UTC 'Z' или со смещением '+03:00') в локальную дату YYYY-MM-DD заданной таймзоны.
 * Если строка не парсится — откатывается к первым 10 символам.
 */
export function toLocalDateStr(iso: string, timezone: string = DEFAULT_TIMEZONE): string {
  const ts = new Date(iso);
  if (Number.isNaN(ts.getTime())) return iso.slice(0, 10);
  try {
    return new Intl.DateTimeFormat('en-CA', { timeZone: timezone }).format(ts);
  } catch {
    return iso.slice(0, 10);
  }
}

/**
 * Возвращает минуты от начала суток (локальное время указанной таймзоны) для ISO-строки.
 */
export function toLocalMinutes(iso: string, timezone: string = DEFAULT_TIMEZONE): number {
  const ts = new Date(iso);
  try {
    const parts = new Intl.DateTimeFormat('en-GB', {
      timeZone: timezone,
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    })
      .format(ts)
      .split(':');
    return (parseInt(parts[0], 10) % 24) * 60 + parseInt(parts[1], 10);
  } catch {
    return ts.getHours() * 60 + ts.getMinutes();
  }
}

/**
 * Проверяет в логах ou.logs через POST /task/read_log/:user_id/:task_name,
 * выполнялся ли поток успешно сегодня (дата и время сравниваются в таймзоне timezone)
 */
export async function checkTaskAlreadyRunToday(
  userId: number,
  taskName: string,
  apiClient: ApiClient = defaultApiClient,
  targetDateStr?: string,
  minStartTime?: string,
  timezone: string = DEFAULT_TIMEZONE
): Promise<{ alreadyRun: boolean; lastExecEnd?: string; logId?: number; durationMs?: number }> {
  try {
    const logResponse = await readTaskLog({ userId, taskName }, apiClient, {
      retries: 1,
      timeoutMs: 2000,
    });
    const today = targetDateStr || toLocalDateStr(new Date().toISOString(), timezone); // YYYY-MM-DD

    if (!logResponse.data || logResponse.data.length === 0) {
      return { alreadyRun: false };
    }

    let minStartMinutes: number | null = null;
    if (minStartTime) {
      const [minH, minM] = minStartTime.split(':').map(Number);
      minStartMinutes = minH * 60 + minM;
    }

    // Ищем успешное выполнение за сегодняшний день (с учетом minStartTime)
    const todaySuccess = logResponse.data.find((entry) => {
      if (entry.status !== 'success' || !entry.exec_start) return false;
      const entryDate = toLocalDateStr(entry.exec_start, timezone);
      if (entryDate !== today) return false;

      if (minStartMinutes !== null) {
        const entryTotalMinutes = toLocalMinutes(entry.exec_start, timezone);
        if (entryTotalMinutes < minStartMinutes) {
          return false; // Запуск произошел раньше заданного времени расписания
        }
      }

      return true;
    });

    if (todaySuccess) {
      let durationMs: number | undefined;
      if (todaySuccess.exec_start && todaySuccess.exec_end) {
        durationMs = new Date(todaySuccess.exec_end).getTime() - new Date(todaySuccess.exec_start).getTime();
      }
      const rawEntry = todaySuccess as unknown as Record<string, unknown>;
      const logId = typeof rawEntry.log_id === 'number' ? rawEntry.log_id : typeof rawEntry.id === 'number' ? rawEntry.id : undefined;

      return {
        alreadyRun: true,
        lastExecEnd: todaySuccess.exec_end ?? undefined,
        logId,
        durationMs,
      };
    }

    return { alreadyRun: false };
  } catch (err: unknown) {
    console.warn(`[orchestrator] Ülesande ${taskName} ajalugu ei õnnestunud kontrollida, loetakse mitte käivitatuks`);
    return { alreadyRun: false };
  }
}

export interface ActiveRunResult {
  /**
   * running  — в ou.logs есть незавершенный запуск (нет status и exec_end) моложе maxAgeHours,
   *            либо запуск только что отправлен (в пределах graceMs) и запись еще не видна
   * none     — незавершенных запусков нет
   * unknown  — не удалось прочитать лог (дубль запускать нельзя)
   */
  state: 'running' | 'none' | 'unknown';
  logId?: number;
  execStart?: string;
  reason?: string;
}

export interface FindActiveRunOptions {
  /** Время отправки последнего запуска из state (task.started_at) — для grace-периода */
  startedAt?: string | null;
  /** Grace-период (мс), в течение которого отсутствие записи не считается провалом. По умолчанию 10 мин */
  graceMs?: number;
  /** Записи старше этого возраста с пустым status считаются «мертвыми» (процесс умер). По умолчанию 12 ч */
  maxAgeHours?: number;
  now?: Date;
}

/**
 * Определяет, есть ли у потока flow незавершенный запуск в ou.logs.
 * Используется как защита от параллельного дубля перед каждым запуском/повтором.
 */
export async function findActiveRun(
  userId: number,
  taskName: string,
  apiClient: ApiClient = defaultApiClient,
  options: FindActiveRunOptions = {}
): Promise<ActiveRunResult> {
  const now = options.now ?? new Date();
  const graceMs = options.graceMs ?? 10 * 60 * 1000;
  const maxAgeHours = options.maxAgeHours ?? 12;

  try {
    const logResponse = await readTaskLog(
      { userId, taskName, limit: 5, hours: Math.ceil(maxAgeHours) },
      apiClient,
      { retries: 1, timeoutMs: 5000 }
    );

    const entries = logResponse.data || [];
    const maxAgeMs = maxAgeHours * 3600 * 1000;

    for (const entry of entries) {
      if (entry.status === 'success' || entry.status === 'failed') continue;
      if (entry.exec_end) continue;
      if (!entry.exec_start) continue;

      const startMs = new Date(entry.exec_start).getTime();
      if (Number.isNaN(startMs) || now.getTime() - startMs > maxAgeMs) continue;

      const rawEntry = entry as unknown as Record<string, unknown>;
      const logId = typeof rawEntry.id === 'number' ? rawEntry.id : typeof rawEntry.log_id === 'number' ? rawEntry.log_id : undefined;
      return { state: 'running', logId, execStart: entry.exec_start, reason: 'Незавершенный запуск в ou.logs' };
    }

    // Запись еще не появилась, но запуск только что отправлен
    if (options.startedAt) {
      const sentMs = new Date(options.startedAt).getTime();
      if (!Number.isNaN(sentMs) && now.getTime() - sentMs >= 0 && now.getTime() - sentMs < graceMs) {
        return { state: 'running', reason: 'Grace-период после отправки запуска' };
      }
    }

    return { state: 'none' };
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return { state: 'unknown', reason: `Не удалось прочитать ou.logs: ${message}` };
  }
}
