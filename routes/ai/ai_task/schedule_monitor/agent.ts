import { defaultApiClient, ApiClient } from '../shared/api_client';
import { OrchestratorState, TaskState } from '../orchestrator/orchestrator.schemas';
import { StateManager, loadOrchestratorConfig } from '../orchestrator/state.manager';
import { AgentManifest, AgentDispatchContext } from '../shared/agent_registry';
import {
  AgentScheduleEntry,
  NextRunReason,
  ScheduleSnapshot,
  ScheduleSnapshotSchema,
  ScheduleMonitorInput,
  ScheduleMonitorInputSchema,
  ScheduleMonitorResult,
  ScheduleMonitorResultSchema,
  TASK_FLOW_AGENT_SCHEDULE,
} from './schemas';
import { logAgentSchedule } from './tools';

/**
 * Извлекает компоненты даты и времени в указанном часовом поясе
 */
export function getPartsInTimezone(date: Date, timezone: string) {
  let year = date.getFullYear();
  let month = date.getMonth() + 1;
  let day = date.getDate();
  let hour = date.getHours();
  let minute = date.getMinutes();

  try {
    const parts = new Intl.DateTimeFormat('en-GB', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    }).formatToParts(date);

    for (const p of parts) {
      if (p.type === 'year') year = parseInt(p.value, 10);
      if (p.type === 'month') month = parseInt(p.value, 10);
      if (p.type === 'day') day = parseInt(p.value, 10);
      if (p.type === 'hour') hour = parseInt(p.value, 10);
      if (p.type === 'minute') minute = parseInt(p.value, 10);
    }
  } catch {
    // fallback на системное локальное время
  }

  return { year, month, day, hour, minute };
}

/**
 * Форматирует строковое представление даты и времени в формате ISO (YYYY-MM-DDTHH:mm:00)
 */
function formatLocalIso(year: number, month: number, day: number, hour: number, minute: number): string {
  const y = String(year).padStart(4, '0');
  const m = String(month).padStart(2, '0');
  const d = String(day).padStart(2, '0');
  const h = String(hour).padStart(2, '0');
  const min = String(minute).padStart(2, '0');
  return `${y}-${m}-${d}T${h}:${min}:00`;
}

/**
 * Вычисляет следующее плановое наступление расписания
 */
export function computeScheduleTarget(
  schedule: { time?: string | null; day?: number | null; month?: number | null },
  now: Date,
  timezone: string,
  forceTomorrow = false
): { targetIso: string; isTomorrow: boolean } {
  const parts = getPartsInTimezone(now, timezone);
  const [schedH, schedM] = (schedule.time || '20:00').split(':').map(Number);
  const nowMinutes = parts.hour * 60 + parts.minute;
  const schedMinutes = schedH * 60 + schedM;

  // Если задан день или месяц
  if ((schedule.day !== undefined && schedule.day !== null) || (schedule.month !== undefined && schedule.month !== null)) {
    let candidateYear = parts.year;
    let candidateMonth = schedule.month !== undefined && schedule.month !== null ? schedule.month : parts.month;
    let candidateDay = schedule.day !== undefined && schedule.day !== null ? schedule.day : parts.day;

    let candidateDate = new Date(Date.UTC(candidateYear, candidateMonth - 1, candidateDay, schedH, schedM, 0));
    if (candidateDate.getTime() < now.getTime() || forceTomorrow) {
      if (schedule.month === undefined || schedule.month === null) {
        // Следующий месяц
        candidateMonth += 1;
        if (candidateMonth > 12) {
          candidateMonth = 1;
          candidateYear += 1;
        }
      } else {
        // Следующий год
        candidateYear += 1;
      }
    }
    return {
      targetIso: formatLocalIso(candidateYear, candidateMonth, candidateDay, schedH, schedM),
      isTomorrow: true,
    };
  }

  // Только time
  const timePassedToday = nowMinutes >= schedMinutes;
  if (!forceTomorrow && !timePassedToday) {
    return {
      targetIso: formatLocalIso(parts.year, parts.month, parts.day, schedH, schedM),
      isTomorrow: false,
    };
  }

  // Завтра
  const tomorrow = new Date(Date.UTC(parts.year, parts.month - 1, parts.day + 1));
  const tYear = tomorrow.getUTCFullYear();
  const tMonth = tomorrow.getUTCMonth() + 1;
  const tDay = tomorrow.getUTCDate();
  return {
    targetIso: formatLocalIso(tYear, tMonth, tDay, schedH, schedM),
    isTomorrow: true,
  };
}

/**
 * Вычисляет следующее плановое время запуска и причину для задачи
 */
export function computeNextPlannedRun(
  task: TaskState,
  now: Date,
  timezone: string
): { next_planned_run: string | null; next_run_reason: NextRunReason } {
  if (task.status === 'RUNNING') {
    return {
      next_planned_run: null,
      next_run_reason: 'RUNNING_NOW',
    };
  }

  if (task.status === 'PENDING') {
    if (task.attempts > 0) {
      return {
        next_planned_run: now.toISOString(),
        next_run_reason: 'RETRY',
      };
    }

    if (task.schedule?.time) {
      const calc = computeScheduleTarget(task.schedule, now, timezone, false);
      return {
        next_planned_run: calc.targetIso,
        next_run_reason: calc.isTomorrow ? 'SCHEDULE_TOMORROW' : 'SCHEDULE_TODAY',
      };
    }

    if (task.depends_on && task.depends_on.length > 0) {
      return {
        next_planned_run: null,
        next_run_reason: 'AFTER_DEPENDENCIES',
      };
    }

    return {
      next_planned_run: now.toISOString(),
      next_run_reason: 'SCHEDULE_TODAY',
    };
  }

  // SUCCESS, FAILED, SKIPPED
  if (task.schedule?.time) {
    const calc = computeScheduleTarget(task.schedule, now, timezone, true);
    return {
      next_planned_run: calc.targetIso,
      next_run_reason: 'SCHEDULE_TOMORROW',
    };
  }

  return {
    next_planned_run: null,
    next_run_reason: 'NONE',
  };
}

/**
 * Формирует снимок расписания и текущего состояния всех субагентов
 */
export function buildScheduleSnapshot(
  state: OrchestratorState,
  now: Date = new Date(),
  timezone: string = 'Europe/Tallinn'
): ScheduleSnapshot {
  const summary = {
    pending: 0,
    running: 0,
    success: 0,
    failed: 0,
    skipped: 0,
  };

  const agents: AgentScheduleEntry[] = [];

  for (const [key, task] of Object.entries(state.tasks)) {
    if (task.status === 'PENDING') summary.pending++;
    else if (task.status === 'RUNNING') summary.running++;
    else if (task.status === 'SUCCESS') summary.success++;
    else if (task.status === 'FAILED') summary.failed++;
    else if (task.status === 'SKIPPED') summary.skipped++;

    const { next_planned_run, next_run_reason } = computeNextPlannedRun(task, now, timezone);

    let timeout_deadline: string | null = null;
    if (task.status === 'RUNNING' && task.started_at) {
      const startedMs = new Date(task.started_at).getTime();
      const timeoutHours = task.timeout_hours && task.timeout_hours > 0 ? task.timeout_hours : 12;
      timeout_deadline = new Date(startedMs + timeoutHours * 3600 * 1000).toISOString();
    }

    const truncatedError = task.error
      ? task.error.length > 500
        ? `${task.error.slice(0, 500)}...`
        : task.error
      : null;

    agents.push({
      agent: key,
      flow: task.flow,
      status: task.status,
      schedule: task.schedule
        ? {
            time: task.schedule.time ?? null,
            day: task.schedule.day ?? null,
            month: task.schedule.month ?? null,
          }
        : null,
      depends_on: task.depends_on || [],
      next_planned_run,
      next_run_reason,
      last_started_at: task.started_at,
      last_finished_at: task.finished_at,
      timeout_deadline,
      attempts: task.attempts || 0,
      max_attempts: task.max_attempts || 3,
      log_id: task.log_id,
      error: truncatedError,
    });
  }

  const rawSnapshot = {
    tick_at: now.toISOString(),
    timezone,
    cycle_date: state.cycle_date,
    cycle_status: state.status,
    next_scheduled_run: state.next_scheduled_run,
    summary,
    agents,
  };

  return ScheduleSnapshotSchema.parse(rawSnapshot);
}

export interface ScheduleMonitorOptions {
  apiClient?: ApiClient;
  now?: Date;
  timezone?: string;
  throwOnError?: boolean;
}

/**
 * Запуск субагента schedule_monitor:
 * 1. Загружает или принимает состояние оркестратора
 * 2. Формирует срез расписания и статусов всех агентов
 * 3. Отправляет запись в ou.logs через POST /task/logAgentSchedule/
 * 4. Возвращает структурированный результат
 */
export async function runScheduleMonitorSubagent(
  input: ScheduleMonitorInput = {},
  options: ScheduleMonitorOptions = {}
): Promise<ScheduleMonitorResult> {
  const validated = ScheduleMonitorInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;
  const now = options.now || new Date();

  let timezone = options.timezone;
  if (!timezone) {
    try {
      const orchestratorConfig = loadOrchestratorConfig();
      timezone = orchestratorConfig.timezone || 'Europe/Tallinn';
    } catch {
      timezone = 'Europe/Tallinn';
    }
  }

  let state: OrchestratorState;
  if (validated.state) {
    state = validated.state;
  } else {
    const stateManager = new StateManager(validated.stateFilePath);
    state = await stateManager.loadState({ userId: validated.userId, rekvId: validated.rekvId });
  }

  const snapshot = buildScheduleSnapshot(state, now, timezone);

  try {
    const res = await logAgentSchedule(
      {
        userId: validated.userId,
        rekvId: validated.rekvId,
        snapshot,
      },
      apiClient
    );

    console.log(`[schedule-monitor] Ajakava logitud edukalt (log_id: ${res.log_id})`);

    return ScheduleMonitorResultSchema.parse({
      flow: TASK_FLOW_AGENT_SCHEDULE,
      status: 'success',
      logId: res.log_id,
      snapshot,
      error: null,
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.warn(`[schedule-monitor] Logimise viga: ${msg}`);

    if (options.throwOnError) {
      throw err;
    }

    return ScheduleMonitorResultSchema.parse({
      flow: TASK_FLOW_AGENT_SCHEDULE,
      status: 'failed',
      logId: null,
      snapshot,
      error: msg,
    });
  }
}

/**
 * Исполнитель агента мониторинга расписания: собирает срез и вызывает API бэкенда (обратная совместимость)
 */
export async function runScheduleMonitor(
  state: OrchestratorState,
  params: { userId: number; rekvId: number },
  apiClient: ApiClient = defaultApiClient,
  now: Date = new Date(),
  timezone: string = 'Europe/Tallinn'
): Promise<number | null> {
  const result = await runScheduleMonitorSubagent(
    {
      userId: params.userId,
      rekvId: params.rekvId,
      state,
    },
    {
      apiClient,
      now,
      timezone,
      throwOnError: false,
    }
  );
  return result.logId;
}

export const manifest: AgentManifest = {
  dispatch: async (ctx: AgentDispatchContext): Promise<number | null> => {
    const finalUserId = (ctx.params?.userId as number) ?? ctx.userId;
    const finalRekvId = (ctx.params?.rekvId as number) ?? ctx.rekvId;

    const res = await runScheduleMonitorSubagent(
      { userId: finalUserId, rekvId: finalRekvId },
      { apiClient: ctx.apiClient, throwOnError: true }
    );
    return res.logId;
  },
};
