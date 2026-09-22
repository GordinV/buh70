import { ApiClient, defaultApiClient } from '../shared/api_client';
import { readTaskLog } from '../logs_watcher/tools';

/**
 * Проверяет в логах ou.logs через POST /task/read_log/:user_id/:task_name,
 * выполнялся ли поток успешно сегодня
 */
export async function checkTaskAlreadyRunToday(
  userId: number,
  taskName: string,
  apiClient: ApiClient = defaultApiClient,
  targetDateStr?: string,
  minStartTime?: string
): Promise<{ alreadyRun: boolean; lastExecEnd?: string; logId?: number; durationMs?: number }> {
  try {
    const logResponse = await readTaskLog({ userId, taskName }, apiClient, {
      retries: 1,
      timeoutMs: 2000,
    });
    const today = targetDateStr || new Date().toISOString().slice(0, 10); // YYYY-MM-DD

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
      const entryDate = entry.exec_start.slice(0, 10);
      if (entryDate !== today) return false;

      if (minStartMinutes !== null) {
        const execDate = new Date(entry.exec_start);
        const entryTotalMinutes = execDate.getHours() * 60 + execDate.getMinutes();
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
