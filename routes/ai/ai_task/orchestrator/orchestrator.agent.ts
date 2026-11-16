import { ApiClient, defaultApiClient } from '../shared/api_client';
import { runSaldoandmikSubagent } from '../saldoandmik/agent';
import { TASK_FLOW_SALDOANDMIK } from '../saldoandmik/schemas';
import { runCalcArvJaakSubagent } from '../calc_arv_jaak/agent';
import { TASK_FLOW_CALC_ARV_JAAK } from '../calc_arv_jaak/schemas';
import { runGetEarvedSubagent } from '../getEarved/agent';
import { TASK_FLOW_GET_EARVED } from '../getEarved/schemas';
import { runCheckAsutusSubagent } from '../check_asutus/agent';
import { TASK_FLOW_CHECK_ASUTUS } from '../check_asutus/schemas';
import { runImportEarvedSubagent } from '../import_earved/agent';
import { TASK_FLOW_IMPORT_EARVED } from '../import_earved/schemas';
import { runSendFinBitReportSubagent } from '../sendFinBitReport/agent';
import { TASK_FLOW_SEND_FIN_BIT_REPORT } from '../sendFinBitReport/schemas';
import { runLisa1Lisa5Subagent } from '../lisa1_lisa5/agent';
import { TASK_FLOW_LISA1_LISA5 } from '../lisa1_lisa5/schemas';
import { AgentManifest, buildAgentRegistry } from '../shared/agent_registry';
import { TaskStatusCheckResult, checkTaskStatus, inspectLogExecutionResult } from '../logs_watcher/agent';
import { readTaskLog } from '../logs_watcher/tools';
import { generateAndSendReportSubagent } from '../reporter/agent';
import { runScheduleMonitor } from '../schedule_monitor/agent';
import { sanitizeReportText } from '../reporter/tools';
import { ReportStepDetail } from '../reporter/schemas';
import {
  AgentLaunchDecision,
  AgentLaunchDecisionSchema,
  CycleDecision,
  CycleDecisionContext,
  CycleDecisionSchema,
  DecisionContext,
  OrchestratorConfig,
  OrchestratorInput,
  OrchestratorInputSchema,
  OrchestratorOutput,
  OrchestratorOutputSchema,
  OrchestratorState,
  OrchestratorTickInput,
  OrchestratorTickInputSchema,
  OrchestratorTickOutput,
  OrchestratorTickOutputSchema,
  ResetReason,
  TaskResultContext,
  TaskResultEvaluation,
  TaskResultEvaluationSchema,
  TaskSchedule,
  TaskState,
  TaskStatus,
  getAllDeps,
} from './orchestrator.schemas';
import { checkTaskAlreadyRunToday, findActiveRun, toLocalDateStr, ActiveRunResult } from './orchestrator.tools';

import { AI_TASK_SERVICE_USER_ID } from '../shared/constants';
/** Grace-период после отправки запуска, в течение которого отсутствие записи в ou.logs не считается провалом */
const NO_START_GRACE_MS = 10 * 60 * 1000;

/**
 * Защита от параллельного дубля: перед запуском/повтором проверяет ou.logs на незавершенный запуск этого flow.
 * Возвращает state: 'running' (запуск уже идет), 'unknown' (лог недоступен — дубль не запускаем) или 'none'.
 */
async function guardAgainstDuplicate(
  task: TaskState,
  userId: number,
  apiClient: ApiClient,
  now: Date
): Promise<ActiveRunResult> {
  const timeoutHours = task.timeout_hours && task.timeout_hours > 0 ? task.timeout_hours : 12;
  return findActiveRun(userId, task.flow, apiClient, {
    maxAgeHours: timeoutHours,
    now,
  });
}

function resolveTaskUserId(
  task: TaskState,
  defaultUserId: number,
  explicitUserId?: number
): number {
  if (typeof explicitUserId === 'number') {
    return explicitUserId;
  }
  return typeof task.params?.userId === 'number' ? task.params.userId : defaultUserId;
}
import {
  StateManager,
  calculateNextScheduledRun,
  loadOrchestratorConfig,
  resetCycleForNewDay,
  snapshotLastRun,
} from './state.manager';

export interface OrchestratorTickOptions {
  apiClient?: ApiClient;
  stateFilePath?: string;
  targetDateStr?: string;
  currentDate?: Date;
  recipientEmail?: string;
  forceRun?: boolean;
  maxTimeoutMs?: number;
  taskKey?: string;
  dailyStartHour?: number;
  dailyStartTime?: string;
  timezone?: string;
  orchestratorConfig?: OrchestratorConfig;
  registry?: Record<string, AgentManifest>;
  aiGenerateFn?: (prompt: string, context: DecisionContext) => Promise<AgentLaunchDecision>;
  aiCycleGenerateFn?: (prompt: string, context: CycleDecisionContext) => Promise<CycleDecision>;
  aiTaskResultGenerateFn?: (prompt: string, context: TaskResultContext) => Promise<TaskResultEvaluation>;
}

export interface OrchestratorOptions {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
  targetDateStr?: string;
  recipientEmail?: string;
  currentDate?: Date;
  timezone?: string;
}

/**
 * Вспомогательная функция для запуска расчетной задачи по ключу через реестр манифестов
 */
async function dispatchTaskByKey(
  key: string,
  userId: number,
  rekvId: number,
  kond: number,
  apiClient: ApiClient,
  customParams: Record<string, unknown> = {},
  registry: Record<string, AgentManifest> = {}
): Promise<number | null> {
  const manifest = registry[key];
  if (!manifest) {
    return null;
  }
  return manifest.dispatch({
    key,
    userId,
    rekvId,
    kond,
    params: customParams,
    apiClient,
  });
}

export interface ScheduleCheckResult {
  ready: boolean;
  shouldSkip: boolean;
  reason?: string;
}

/**
 * Проверяет готовность задачи к запуску по ее расписанию (Time & Date Scheduler)
 *
 * Правила:
 * 1. Если schedule отсутствует (null/undefined) -> задача готова к запуску (в рамках расчетного окна).
 * 2. Если указан month (1-12) -> текущий месяц должен строго совпадать с schedule.month. Иначе shouldSkip = true.
 * 3. Если указан day (1-31) -> текущий день месяца должен строго совпадать с schedule.day. Иначе shouldSkip = true.
 * 4. Если указано time ("HH:mm") -> текущее время сервера должно быть >= schedule.time.
 *    До наступления времени ready = false (задача ожидает следующего тика).
 *    В момент наступления времени или на первом тике сразу после (>= schedule.time) -> ready = true.
 */
export function isTaskScheduleReady(
  schedule: TaskSchedule | null | undefined,
  currentDate: Date,
  timezone: string = 'Europe/Tallinn'
): ScheduleCheckResult {
  if (!schedule) {
    return { ready: true, shouldSkip: false };
  }

  let currentMonth = currentDate.getMonth() + 1;
  let currentDay = currentDate.getDate();
  let currentHours = currentDate.getHours();
  let currentMinutes = currentDate.getMinutes();

  try {
    const parts = new Intl.DateTimeFormat('en-GB', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    }).formatToParts(currentDate);

    for (const p of parts) {
      if (p.type === 'month') currentMonth = parseInt(p.value, 10);
      if (p.type === 'day') currentDay = parseInt(p.value, 10);
      if (p.type === 'hour') currentHours = parseInt(p.value, 10);
      if (p.type === 'minute') currentMinutes = parseInt(p.value, 10);
    }
  } catch {
    // Fallback to local machine date
  }

  // Проверка месяца (1-12)
  if (schedule.month !== undefined && schedule.month !== null) {
    if (currentMonth !== schedule.month) {
      return {
        ready: false,
        shouldSkip: true,
        reason: `Käivitamine on kavandatud kuule ${schedule.month} (praegu: ${currentMonth})`,
      };
    }
  }

  // Проверка дня месяца (1-31)
  if (schedule.day !== undefined && schedule.day !== null) {
    if (currentDay !== schedule.day) {
      return {
        ready: false,
        shouldSkip: true,
        reason: `Käivitamine on kavandatud kuupäevale ${schedule.day} (praegu: ${currentDay})`,
      };
    }
  }

  // Проверка времени суток (HH:mm)
  if (schedule.time !== undefined && schedule.time !== null) {
    const [schedHours, schedMinutes] = schedule.time.split(':').map(Number);
    const schedTotalMinutes = schedHours * 60 + schedMinutes;
    const currentTotalMinutes = currentHours * 60 + currentMinutes;

    if (currentTotalMinutes < schedTotalMinutes) {
      const currentH = String(currentHours).padStart(2, '0');
      const currentM = String(currentMinutes).padStart(2, '0');
      return {
        ready: false,
        shouldSkip: false,
        reason: `Ootel kuni ${schedule.time} (praegu kell ${currentH}:${currentM})`,
      };
    }
  }

  return { ready: true, shouldSkip: false };
}

/**
 * Вычисляет, открыто ли суточное окно запуска для указанного времени старта (HH:mm) с учетом таймзоны
 */
export function isDailyExecutionWindowOpen(
  currentDate: Date,
  dailyStartTime: string = '20:00',
  timezone: string = 'Europe/Tallinn'
): boolean {
  try {
    const formatter = new Intl.DateTimeFormat('en-GB', {
      timeZone: timezone,
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    });
    const parts = formatter.format(currentDate).split(':');
    const currentMinutes = parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
    const [startH, startM] = dailyStartTime.split(':').map((s) => parseInt(s, 10));
    const targetMinutes = startH * 60 + (startM || 0);
    return currentMinutes >= targetMinutes;
  } catch {
    const currentMinutes = currentDate.getHours() * 60 + currentDate.getMinutes();
    const [startH, startM] = dailyStartTime.split(':').map((s) => parseInt(s, 10));
    const targetMinutes = startH * 60 + (startM || 0);
    return currentMinutes >= targetMinutes;
  }
}

/**
 * Оценивает решение верхнего уровня для суточного цикла (Meta-Orchestrator Decision)
 */
export async function evaluateCycleDecision(
  orchestratorConfig: OrchestratorConfig,
  state: OrchestratorState,
  currentDate: Date,
  forceRun: boolean,
  apiClient?: ApiClient,
  aiCycleGenerateFn?: (prompt: string, context: CycleDecisionContext) => Promise<CycleDecision>
): Promise<CycleDecision> {
  const effectiveApiClient = apiClient || defaultApiClient;
  const baseUrl = effectiveApiClient.getConfig().buh70ApiBaseUrl;
  const isTestMode = baseUrl.includes('localhost') || baseUrl.includes('127.0.0.1');

  let localTimeStr = '';
  try {
    localTimeStr = new Intl.DateTimeFormat('en-GB', {
      timeZone: orchestratorConfig.timezone,
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    }).format(currentDate);
  } catch {
    localTimeStr = `${String(currentDate.getHours()).padStart(2, '0')}:${String(currentDate.getMinutes()).padStart(2, '0')}`;
  }

  const tasksSummary: Record<string, { status: TaskStatus; attempts: number; error: string | null }> = {};
  for (const [k, v] of Object.entries(state.tasks)) {
    tasksSummary[k] = { status: v.status, attempts: v.attempts, error: v.error };
  }

  const context: CycleDecisionContext = {
    currentServerTime: currentDate.toISOString(),
    localTime: localTimeStr,
    timezone: orchestratorConfig.timezone,
    dailyStartTime: orchestratorConfig.daily_start_time,
    cycleDate: state.cycle_date,
    cycleStatus: state.status,
    apiBaseUrl: baseUrl,
    tasksState: tasksSummary,
    isTestMode,
  };

  // 1. Мета-промпт оркестратора
  if (orchestratorConfig.prompt && orchestratorConfig.prompt.trim().length > 0) {
    if (aiCycleGenerateFn) {
      try {
        console.log(
          `[orchestrator-meta-decision] LLM-otsuse taotlemine tsüklile (prompt: "${orchestratorConfig.prompt.slice(0, 50)}...")`
        );
        const decision = await aiCycleGenerateFn(orchestratorConfig.prompt, context);
        return CycleDecisionSchema.parse(decision);
      } catch (err) {
        console.warn(
          `[orchestrator-meta-decision] LLM tsükliotsuse viga, tagasipöördumine standardreeglitele:`,
          err
        );
      }
    } else {
      console.log(
        `[orchestrator-meta-decision] Orkestraatoril on prompt, kuid aiCycleGenerateFn puudub. Kasutatakse standardreegleid.`
      );
    }
  }

  // 2. Детерминированные правила времени
  const isOpen = isDailyExecutionWindowOpen(
    currentDate,
    orchestratorConfig.daily_start_time,
    orchestratorConfig.timezone
  );

  if (forceRun || isOpen) {
    return {
      action: 'RUN_CYCLE',
      force_run: forceRun,
      reason: forceRun
        ? 'Käivitamine sunnitud (forceRun = true)'
        : `Igapäevane ajaaken ${orchestratorConfig.daily_start_time} (${orchestratorConfig.timezone}) on avatud (kell ${localTimeStr})`,
    };
  }

  return {
    action: 'WAIT_SCHEDULE',
    force_run: false,
    reason: `Ootel kuni igapäevase aknani ${orchestratorConfig.daily_start_time} ${orchestratorConfig.timezone} (praegu kell ${localTimeStr})`,
  };
}

function appendSoftDepsWarning(
  baseSummary: string | undefined,
  task: TaskState | undefined
): string | undefined {
  if (!task?.soft_deps_failed || task.soft_deps_failed.length === 0) {
    return baseSummary;
  }
  const warning = `${task.soft_deps_failed.join(', ')} ebaõnnestus/vahele jäetud — uued asutused lisamata, nende arved jäävad järgmisele allalaadimisele`;
  return baseSummary ? `${baseSummary} (${warning})` : warning;
}

/**
 * Находит все транзитивно зависимые от rootKey задачи, находящиеся в статусе RUNNING.
 */
export function findRunningDownstreamDependents(
  tasks: Record<string, TaskState>,
  rootKey: string
): string[] {
  const visited = new Set<string>([rootKey]);
  const queue: string[] = [rootKey];
  const runningDependents: string[] = [];

  while (queue.length > 0) {
    const currentKey = queue.shift()!;
    for (const [depKey, depTask] of Object.entries(tasks)) {
      if (visited.has(depKey)) continue;
      if (getAllDeps(depTask).includes(currentKey)) {
        visited.add(depKey);
        queue.push(depKey);
        if (depTask.status === 'RUNNING') {
          runningDependents.push(depKey);
        }
      }
    }
  }

  return runningDependents;
}

/**
 * Сбрасывает состояние задачи в PENDING, сохраняя снимок последнего запуска в last_run,
 * и очищает закешированный params.logId.
 */
function resetTaskToPending(
  task: TaskState,
  reason: ResetReason,
  cycleDate: string,
  nowIso: string
): void {
  const nextLastRun = snapshotLastRun(task, reason, cycleDate, nowIso);
  task.status = 'PENDING';
  task.attempts = 0;
  task.log_id = null;
  task.started_at = null;
  task.finished_at = null;
  task.duration_ms = null;
  task.error = null;
  task.soft_deps_failed = undefined;
  if (task.params && 'logId' in task.params) {
    delete (task.params as Record<string, unknown>).logId;
  }
  if (nextLastRun !== undefined) {
    task.last_run = nextLastRun;
  }
}

/**
 * Возвращает время последнего сброса/перевооружения (TASK_REARMED / TASK_RESET_MANUAL) для каждой задачи.
 */
function getLatestResetTimestampByTask(history: OrchestratorState['history']): Map<string, string> {
  const latestResetAt = new Map<string, string>();
  for (const item of history) {
    if ((item.event === 'TASK_REARMED' || item.event === 'TASK_RESET_MANUAL') && item.task) {
      const prev = latestResetAt.get(item.task);
      if (!prev || item.timestamp > prev) {
        latestResetAt.set(item.task, item.timestamp);
      }
    }
  }
  return latestResetAt;
}

/**
 * Оценивает решение о запуске задачи на текущем тике FSM.
 * Если в конфигурации задачи задан prompt, оркестратор руководствуется им в первую очередь,
 * передавая параметры задачи, расписание, статусы зависимостей и контекст в LLM (aiGenerateFn).
 * При отсутствии prompt или сбое LLM используется строгая детерминированная логика графа.
 */
export async function evaluateTaskLaunchDecision(
  key: string,
  task: TaskState,
  state: OrchestratorState,
  currentDate: Date,
  dailyStartHour: number,
  forceRun: boolean,
  aiGenerateFn?: (prompt: string, context: DecisionContext) => Promise<AgentLaunchDecision>,
  apiClient?: ApiClient,
  dailyStartTime?: string,
  timezone?: string,
  bypassScheduleTime: boolean = false,
  manifest?: AgentManifest
): Promise<AgentLaunchDecision> {
  // Собираем статусы предшественников (жёстких и мягких)
  const depsState: Record<string, TaskStatus> = {};
  for (const dep of getAllDeps(task)) {
    depsState[dep] = state.tasks[dep]?.status || 'PENDING';
  }

  const effectiveApiClient = apiClient || defaultApiClient;
  const effectiveTimezone = timezone || 'Europe/Tallinn';

  let localTimeFormatted = '';
  let localDateFormatted = '';
  try {
    const timeFormatter = new Intl.DateTimeFormat('en-GB', {
      timeZone: effectiveTimezone,
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
    });
    const dateFormatter = new Intl.DateTimeFormat('en-CA', {
      timeZone: effectiveTimezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
    localTimeFormatted = timeFormatter.format(currentDate);
    localDateFormatted = dateFormatter.format(currentDate);
  } catch {
    localTimeFormatted = `${String(currentDate.getHours()).padStart(2, '0')}:${String(currentDate.getMinutes()).padStart(2, '0')}:${String(currentDate.getSeconds()).padStart(2, '0')}`;
    localDateFormatted = currentDate.toISOString().slice(0, 10);
  }

  const schedCheckForContext = isTaskScheduleReady(task.schedule, currentDate, effectiveTimezone);

  // Обеспечиваем наличие родительских параметров (например, logId от getEarved):
  const effectiveParams: Record<string, unknown> = {
    ...((task.params as Record<string, unknown>) || {}),
  };
  if (!effectiveParams.logId && task.depends_on && task.depends_on.length > 0) {
    for (const depKey of task.depends_on) {
      const depTask = state.tasks[depKey];
      if (depTask && depTask.log_id) {
        effectiveParams.logId = depTask.log_id;
        break;
      }
    }
  }
  task.params = effectiveParams;

  const context: DecisionContext = {
    currentServerTime: currentDate.toISOString(),
    localTime: localTimeFormatted,
    localDate: localDateFormatted,
    timezone: effectiveTimezone,
    isScheduleDue: schedCheckForContext.ready && !schedCheckForContext.shouldSkip,
    agentName: key,
    params: effectiveParams,
    schedule: task.schedule,
    dependenciesState: depsState,
    attempts: task.attempts || 0,
    taskStatus: task.status,
    apiBaseUrl: effectiveApiClient.getConfig().buh70ApiBaseUrl,
  };

  // 0. Защита целостности зависимостей (Downstream Lock):
  // Запрещено запускать родительскую задачу, если любая транзитивно зависимая от нее дочерняя задача (downstream) прямо сейчас исполняется (RUNNING).
  const runningDependents = findRunningDownstreamDependents(state.tasks, key);

  if (runningDependents.length > 0) {
    return {
      should_run: false,
      action: 'WAIT',
      reason: `Ootel: sellest ülesandest sõltuv ülesanne (${runningDependents.join(', ')}) on veel teostamisel (RUNNING)`,
    };
  }

  // 1. Приоритет промпта: если задан prompt, руководствуемся им в первую очередь
  if (task.prompt && task.prompt.trim().length > 0) {
    if (aiGenerateFn) {
      try {
        console.log(
          `[orchestrator-decision] LLM-otsuse taotlemine agendile ${key} (prompt: "${task.prompt.slice(0, 50)}...")`
        );
        const decision = await aiGenerateFn(task.prompt, context);
        return AgentLaunchDecisionSchema.parse(decision);
      } catch (llmErr) {
        console.warn(
          `[orchestrator-decision] LLM genereerimise viga agendile ${key}, tagasipöördumine FSM reeglitele:`,
          llmErr
        );
      }
    } else {
      console.log(
        `[orchestrator-decision] Agendil ${key} on prompt, kuid aiGenerateFn puudub. Kasutatakse FSM reegleid.`
      );
    }
  }

  // 2. Детерминированные правила FSM
  // 2.1. Проверка сбоев в предшественниках
  const hasFailedDep = task.depends_on.some(
    (d) => state.tasks[d]?.status === 'FAILED' || state.tasks[d]?.status === 'SKIPPED'
  );
  if (hasFailedDep) {
    return {
      should_run: false,
      action: 'SKIP',
      reason: 'Vahele jäetud eelneva ülesande vea tõttu',
    };
  }

  // 2.2. Проверка готовности жёстких предшественников
  const allDepsSuccess = task.depends_on.every((d) => state.tasks[d]?.status === 'SUCCESS');
  if (!allDepsSuccess) {
    return {
      should_run: false,
      action: 'WAIT',
      reason: 'Ootel eelnevate sõltuvuste lõpetamiseni',
    };
  }

  // 2.2.1. Проверка мягких предшественников (soft_depends_on): ждём финального статуса, стартуем при любом исходе
  for (const sd of task.soft_depends_on || []) {
    const softTask = state.tasks[sd];
    if (!softTask) {
      console.warn(`[orchestrator-decision] Pehme sõltuvus "${sd}" puudub olekus ülesandel ${key}, ignoreeritakse`);
      continue;
    }
    if (softTask.status === 'PENDING' || softTask.status === 'RUNNING') {
      return {
        should_run: false,
        action: 'WAIT',
        reason: `Ootel pehme sõltuvuse lõpetamiseni (${sd})`,
      };
    }
  }

  // Проверка специфических предусловий из манифеста агента (например, наличие log_id родителя)
  const effectiveManifest = manifest ?? buildAgentRegistry()[key];
  const prereqError = effectiveManifest?.validatePrerequisites?.(state) ?? null;
  if (prereqError) {
    return {
      should_run: false,
      action: 'SKIP',
      reason: prereqError,
    };
  }

  // 2.3. Корневые задачи без явного расписания ожидают наступления базового суточного окна (dailyStartTime / dailyStartHour)
  // Если у задачи есть зависимости (например, sendFinBitReport -> getEarved), и они уже успешно завершены,
  // задача готова к старту сразу после завершения предшественников.
  if (!task.schedule && getAllDeps(task).length === 0 && !forceRun) {
    const windowStart = dailyStartTime || `${dailyStartHour}:00`;
    const tz = timezone || 'Europe/Tallinn';
    const isOpen = isDailyExecutionWindowOpen(currentDate, windowStart, tz);
    if (!isOpen) {
      let localHour = new Intl.DateTimeFormat('en-GB', {
        timeZone: tz,
        hour: '2-digit',
        minute: '2-digit',
        hour12: false,
      }).format(currentDate);
      return {
        should_run: false,
        action: 'WAIT',
        reason: `Ootel kuni ${windowStart} (praegu kell ${localHour})`,
      };
    }
  }

  // 2.4. Проверка индивидуального расписания (Time & Date Scheduler)
  const schedCheck = isTaskScheduleReady(task.schedule, currentDate, timezone);
  if (schedCheck.shouldSkip) {
    return {
      should_run: false,
      action: 'SKIP',
      reason: schedCheck.reason || 'Vahele jäetud graafiku tõttu',
    };
  }

  if (schedCheck.ready || (bypassScheduleTime && !schedCheck.shouldSkip)) {
    return {
      should_run: true,
      action: 'RUN',
      reason: 'Kõik tingimused täidetud ja graafik lubab käivitamist',
    };
  }

  return {
    should_run: false,
    action: 'WAIT',
    reason: schedCheck.reason || 'Ootel graafiku saabumiseni',
  };
}

/**
 * Семантическая оценка результатов выполнения задачи.
 * Если у задачи задан prompt, оркестратор в первую очередь передает контекст с подробным результатом
 * (logResult, logResponse, logError, hasErrors, errorDetails) в LLM (aiTaskResultGenerateFn).
 * При отсутствии prompt или сбое LLM используется детерминированный анализ inspectLogExecutionResult.
 */
export async function evaluateTaskResultDecision(
  key: string,
  task: TaskState,
  statusResult: TaskStatusCheckResult,
  currentDate: Date,
  aiTaskResultGenerateFn?: (prompt: string, context: TaskResultContext) => Promise<TaskResultEvaluation>
): Promise<TaskResultEvaluation> {
  const context: TaskResultContext = {
    currentServerTime: currentDate.toISOString(),
    agentName: key,
    flow: task.flow,
    logStatus: statusResult.rawStatus || statusResult.status,
    logResult: statusResult.result,
    logResponse: statusResult.response,
    logError: statusResult.error,
    hasErrors: !!statusResult.hasErrors,
    errorDetails: statusResult.errorDetails,
    resultSummary: statusResult.resultSummary,
    attempts: task.attempts || 1,
  };

  // 1. Приоритет промпта: если задан prompt, обращаемся к LLM
  if (task.prompt && task.prompt.trim().length > 0) {
    if (aiTaskResultGenerateFn) {
      try {
        console.log(
          `[orchestrator-eval] LLM tulemuse hindamise taotlemine agendile ${key} (prompt: "${task.prompt.slice(0, 50)}...")`
        );
        const evalDecision = await aiTaskResultGenerateFn(task.prompt, context);
        const parsed = TaskResultEvaluationSchema.parse(evalDecision);
        if (parsed.summary) {
          parsed.summary = sanitizeReportText(parsed.summary) || parsed.summary;
        }
        return parsed;
      } catch (llmErr) {
        console.warn(
          `[orchestrator-eval] LLM genereerimise viga agendile ${key}, tagasipöördumine FSM reeglitele:`,
          llmErr
        );
      }
    } else {
      console.log(
        `[orchestrator-eval] Agendil ${key} on prompt, kuid aiTaskResultGenerateFn puudub. Kasutatakse FSM reegleid.`
      );
    }
  }

  // 2. Детерминированный fallback
  const isFailed = statusResult.status === 'failed' || !!statusResult.hasErrors;
  if (isFailed) {
    return {
      is_success: false,
      status: 'FAILED',
      summary: statusResult.resultSummary || 'Ülesande täitmisel ilmnesid vead',
      error: statusResult.errorDetails || statusResult.error || 'Viga logides',
    };
  }

  return {
    is_success: true,
    status: 'SUCCESS',
    summary: statusResult.resultSummary || 'Edukalt täidetud',
    error: null,
  };
}

/**
 * Безопасный вызов субагента мониторинга расписания schedule_monitor на каждом тике
 */
async function invokeScheduleMonitorSafe(
  state: OrchestratorState,
  orchestratorConfig: OrchestratorConfig,
  apiClient: ApiClient,
  currentDate: Date,
  overrideParams?: { userId?: number; rekvId?: number }
): Promise<void> {
  if (orchestratorConfig.schedule_monitor?.enabled === false) {
    return;
  }
  try {
    await runScheduleMonitor(
      state,
      {
        userId:
          overrideParams?.userId ??
          orchestratorConfig.params?.userId ??
          state.params?.userId ??
          AI_TASK_SERVICE_USER_ID,
        rekvId:
          overrideParams?.rekvId ??
          orchestratorConfig.params?.rekvId ??
          state.params?.rekvId ??
          63,
      },
      apiClient,
      currentDate,
      orchestratorConfig.timezone
    );
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.warn(`[schedule-monitor] Logimise viga: ${msg}`);
  }
}

/**
 * Исполнитель одного тика оркестратора (Stateless FSM Tick Runner по Cron)
 */
export async function runOrchestratorTick(
  input: OrchestratorTickInput = {},
  options: OrchestratorTickOptions = {}
): Promise<OrchestratorTickOutput> {
  const validated = OrchestratorTickInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;
  const config = apiClient.getConfig();

  const stateFilePath = options.stateFilePath || validated.stateFilePath || config.stateFilePath;
  const stateManager = new StateManager(stateFilePath);

  // 1. Загрузка конфигурации оркестратора (orchestrator/config.json)
  const orchestratorConfig = options.orchestratorConfig || loadOrchestratorConfig();
  const dailyStartTime =
    options.dailyStartTime ||
    orchestratorConfig.daily_start_time ||
    `${options.dailyStartHour ?? config.dailyStartHour}:00`;
  const timezone = options.timezone || orchestratorConfig.timezone || 'Europe/Tallinn';
  const dailyStartHour =
    options.dailyStartHour ?? parseInt(dailyStartTime.split(':')[0], 10);

  const currentDate = options.currentDate || new Date();
  const targetDateStr =
    options.targetDateStr ||
    new Intl.DateTimeFormat('en-CA', { timeZone: timezone }).format(currentDate);
  const forceRun = options.forceRun ?? validated.forceRun;
  const maxTimeoutMs = options.maxTimeoutMs || config.taskTimeoutMs;
  const recipientEmail = options.recipientEmail || validated.recipientEmail || config.reportEmailTo;

  const registry = options.registry || buildAgentRegistry(undefined, undefined);

  // Источник истины для userId/rekvId — конфиг (orchestrator/config.json), если не передан явный CLI-флаг (--user/--rekv).
  // Явный CLI-флаг действует только на этот запуск и не сохраняется в orchestrator_state.json.
  const explicitUserId = typeof validated.userId === 'number' ? validated.userId : undefined;
  const explicitRekvId = typeof validated.rekvId === 'number' ? validated.rekvId : undefined;
  const configUserId =
    typeof orchestratorConfig.params?.userId === 'number'
      ? orchestratorConfig.params.userId
      : AI_TASK_SERVICE_USER_ID;
  const configRekvId =
    typeof orchestratorConfig.params?.rekvId === 'number'
      ? orchestratorConfig.params.rekvId
      : 63;
  const effectiveCycleUserId = explicitUserId ?? configUserId;
  const effectiveCycleRekvId = explicitRekvId ?? configRekvId;
  const overrideMonitorParams =
    explicitUserId !== undefined || explicitRekvId !== undefined
      ? { userId: explicitUserId, rekvId: explicitRekvId }
      : undefined;

  // 1.1. Загрузка состояния (без передачи разового CLI --user/--rekv в сохраняемый state)
  let state = await stateManager.loadState(
    { userId: configUserId, rekvId: configRekvId, kond: validated.kond },
    targetDateStr,
    undefined,
    timezone
  );

  const nowIso = currentDate.toISOString();
  console.log(`[orchestrator-tick] Käivitamine kuupäeval: ${targetDateStr}, hetkeolek: ${state.status}`);

  const rearmedKeys = new Set<string>();

  // Ручной точечный сброс конкретной задачи по CLI/параметру taskKey
  const selectedTaskKey = options.taskKey || validated.taskKey;
  if (selectedTaskKey && state.tasks[selectedTaskKey]) {
    console.log(`[orchestrator-tick] Käsitsi lähtestamine ülesandele ${selectedTaskKey}`);
    const targetTask = state.tasks[selectedTaskKey];
    resetTaskToPending(targetTask, 'TASK_RESET_MANUAL', state.cycle_date, nowIso);
    state.history.push({
      timestamp: nowIso,
      event: 'TASK_RESET_MANUAL',
      task: selectedTaskKey,
      details: `Task manually reset via taskKey option`,
    });
    rearmedKeys.add(selectedTaskKey);
  } else if (selectedTaskKey) {
    // Неизвестный ключ задачи: не прерываем тик, но явно сообщаем об этом и фиксируем событие в истории.
    // Поведение намеренно консервативное: фильтр PENDING-задач ниже (k === selectedTaskKey) при неизвестном ключе
    // не пропускает ни одной задачи, поэтому при опечатке ручной тик ничего не запускает
    // (инспекция RUNNING, reporter и сохранение состояния работают как обычно).
    const knownTaskKeys = Object.keys(state.tasks).join(', ');
    console.warn(
      `[orchestrator-tick] Hoiatus: tundmatu ülesande võti "${selectedTaskKey}", lähtestamist ei tehtud ja selles tikis ühtegi ülesannet ei käivitata. Lubatud võtmed: ${knownTaskKeys}`
    );
    state.history.push({
      timestamp: nowIso,
      event: 'TASK_RESET_UNKNOWN',
      task: selectedTaskKey,
      details: `Unknown taskKey: manual reset skipped, no tasks are launched in this tick. Known task keys: ${knownTaskKeys}`,
    });
  }
  for (const [sKey, sTask] of Object.entries(state.tasks)) {
    if (sTask.schedule && sTask.status !== 'RUNNING') {
      // Защита Downstream Lock: не перевооружаем задачу, если любая транзитивно зависимая от нее задача прямо сейчас исполняется (RUNNING)
      const runningDependents = findRunningDownstreamDependents(state.tasks, sKey);
      if (runningDependents.length > 0) {
        console.log(
          `[orchestrator-tick] Skipped re-arming scheduled task ${sKey}: dependent task(s) still RUNNING (${runningDependents.join(', ')})`
        );
        continue;
      }

      const taskFinishDateStr = sTask.finished_at ? toLocalDateStr(sTask.finished_at, timezone) : null;
      const taskStartDateStr = sTask.started_at ? toLocalDateStr(sTask.started_at, timezone) : null;
      const isAlreadyRunToday =
        (taskFinishDateStr && taskFinishDateStr === targetDateStr) ||
        (taskStartDateStr && taskStartDateStr === targetDateStr);

      const wasRunOnPreviousDay =
        !isAlreadyRunToday &&
        ((taskFinishDateStr && taskFinishDateStr < targetDateStr) ||
          (taskStartDateStr && taskStartDateStr < targetDateStr) ||
          (state.cycle_date < targetDateStr && sTask.status !== 'PENDING'));

      if (wasRunOnPreviousDay) {
        console.log(`[orchestrator-tick] Re-arming scheduled task ${sKey} for new day: ${targetDateStr}`);
        resetTaskToPending(sTask, 'TASK_REARMED', state.cycle_date, nowIso);
        state.history.push({
          timestamp: nowIso,
          event: 'TASK_REARMED',
          task: sKey,
          details: `Rearmed for scheduled execution on ${targetDateStr}`,
        });
        rearmedKeys.add(sKey);
      }
    }
  }

  // Каскадное перевооружение зависимых задач (depends_on):
  // Если родительская задача была перевооружена (в этом тике или в предыдущем, когда потомок был RUNNING и позже завершился),
  // все зависимые от нее задачи также сбрасываем в PENDING.
  const latestResetAt = getLatestResetTimestampByTask(state.history);
  let cascadeAdded = true;
  while (cascadeAdded) {
    cascadeAdded = false;
    for (const [depKey, depTask] of Object.entries(state.tasks)) {
      if (depKey === 'reporter' || depKey === 'schedule_monitor') continue;
      if (rearmedKeys.has(depKey) || depTask.status === 'RUNNING') continue;

      const depRunAt = depTask.started_at || depTask.finished_at;
      const allDepParents = getAllDeps(depTask);
      const hasRearmedParent = allDepParents.some((parentKey) => {
        if (rearmedKeys.has(parentKey)) return true;
        if (depTask.status === 'PENDING' || !depRunAt) return false;
        const parentResetAt = latestResetAt.get(parentKey);
        if (parentResetAt && parentResetAt > depRunAt) return true;
        const parentTask = state.tasks[parentKey];
        const parentRunAt = parentTask?.started_at || parentTask?.finished_at;
        return Boolean(parentRunAt && parentRunAt > depRunAt);
      });

      if (hasRearmedParent) {
        console.log(`[orchestrator-tick] Cascade re-arming dependent task ${depKey} for new day: ${targetDateStr}`);
        resetTaskToPending(depTask, 'TASK_REARMED', state.cycle_date, nowIso);
        state.history.push({
          timestamp: nowIso,
          event: 'TASK_REARMED',
          task: depKey,
          details: `Cascade rearmed following parent dependency for ${targetDateStr}`,
        });
        rearmedKeys.add(depKey);
        latestResetAt.set(depKey, nowIso);
        cascadeAdded = true;
      }
    }
  }

  // 1.2. Оценка Meta-Orchestrator решения по суточному циклу (AI Meta-Prompt или время)
  const cycleDecision = await evaluateCycleDecision(
    orchestratorConfig,
    state,
    currentDate,
    forceRun,
    apiClient,
    options.aiCycleGenerateFn
  );
  const effectiveForceRun = forceRun || cycleDecision.force_run;

  if (cycleDecision.action === 'SKIP_CYCLE') {
    console.log(`[orchestrator-tick] Meta-AI otsus: tsükkel vahele jäetud. Põhjus: ${cycleDecision.reason}`);
    state.status = 'COMPLETED';
    state.last_tick_at = nowIso;
    await stateManager.saveState(state);
    await invokeScheduleMonitorSafe(state, orchestratorConfig, apiClient, currentDate, overrideMonitorParams);
    return OrchestratorTickOutputSchema.parse({
      cycleDate: state.cycle_date,
      cycleStatus: state.status,
      action: 'TICK_EXECUTED',
      message: `Tsükkel vahele jäetud AI otsuse põhjal: ${cycleDecision.reason}`,
      activeTasks: [],
      completedTasks: [],
      pendingTasks: [],
      failedTasks: [],
      skippedTasks: Object.keys(state.tasks),
      nextScheduledRun: null,
    });
  }

  if (cycleDecision.action === 'PAUSE_CYCLE') {
    console.log(`[orchestrator-tick] Meta-AI otsus: tsükkel peatatud. Põhjus: ${cycleDecision.reason}`);
    state.last_tick_at = nowIso;
    await stateManager.saveState(state);
    await invokeScheduleMonitorSafe(state, orchestratorConfig, apiClient, currentDate, overrideMonitorParams);
    return OrchestratorTickOutputSchema.parse({
      cycleDate: state.cycle_date,
      cycleStatus: state.status,
      action: 'TICK_EXECUTED',
      message: `Tsükkel peatatud AI otsuse põhjal: ${cycleDecision.reason}`,
      activeTasks: [],
      completedTasks: [],
      pendingTasks: Object.keys(state.tasks).filter((k) => state.tasks[k].status === 'PENDING'),
      failedTasks: [],
      skippedTasks: [],
      nextScheduledRun: null,
    });
  }

  // 1.3. Проверка активных выполняющихся задач (RUNNING)
  const hasRunningTasks = Object.values(state.tasks).some((t) => t.status === 'RUNNING');

  // 1.3.1. Закрытие вчерашнего зависшего цикла при смене календарных суток
  if (!hasRunningTasks && targetDateStr > state.cycle_date && state.status === 'IN_PROGRESS') {
    const hasAnyFailed = Object.values(state.tasks).some((t) => t.status === 'FAILED');
    state.status = hasAnyFailed ? 'FAILED' : 'COMPLETED';
    state.history.push({
      timestamp: nowIso,
      event: 'CYCLE_CLOSED_DAY_CHANGE',
      details: `Closed previous day cycle ${state.cycle_date} upon reaching ${targetDateStr}`,
    });
  }

  // 1.4. Проверка суточного регламента и сверка с логами (ou.logs Reconciliation)
  if (!hasRunningTasks && (state.status === 'COMPLETED' || state.status === 'FAILED')) {
    // Проверяем задачи с индивидуальным расписанием (schedule.time), чье время уже наступило сегодня.
    // Исключаем reporter и schedule_monitor: они служебные, reporter не пишет в ou.logs
    const dueScheduledTasks = Object.entries(state.tasks).filter(([key, task]) => {
      if (key === 'reporter' || key === 'schedule_monitor') return false;
      if (!task.schedule) return false;
      const schedCheck = isTaskScheduleReady(task.schedule, currentDate, timezone);
      return schedCheck.ready && !schedCheck.shouldSkip;
    });

    for (const [key, task] of dueScheduledTasks) {
      // Проверяем, отмечена ли уже задача как SUCCESS за сегодняшний день
      const isAlreadySuccessToday = state.cycle_date === targetDateStr && task.status === 'SUCCESS';
      if (!isAlreadySuccessToday) {
        const minStartTime = task.schedule?.time || undefined;
        const logCheck = await checkTaskAlreadyRunToday(
          resolveTaskUserId(task, effectiveCycleUserId, explicitUserId),
          task.flow,
          apiClient,
          targetDateStr,
          minStartTime,
          timezone
        );

        if (logCheck.alreadyRun) {
          console.log(
            `[orchestrator-tick] Ülesanne ${key} on logide järgi juba edukalt sooritatud (ou.logs)`
          );
          if (targetDateStr > state.cycle_date) {
            state = resetCycleForNewDay(state, targetDateStr, undefined, timezone, currentDate);
          }
          if (state.tasks[key]) {
            state.tasks[key].status = 'SUCCESS';
            state.tasks[key].finished_at = logCheck.lastExecEnd || nowIso;
            if (logCheck.logId) state.tasks[key].log_id = logCheck.logId;
            if (logCheck.durationMs) state.tasks[key].duration_ms = logCheck.durationMs;
            state.tasks[key].error = null;
          }
          state.history.push({
            timestamp: nowIso,
            event: 'TASK_RECONCILED_LOGS',
            task: key,
            details: `Reconciled with ou.logs as SUCCESS (execEnd: ${state.tasks[key]?.finished_at || nowIso})`,
          });
        } else {
          // Задача с расписанием не найдена в логах после minStartTime: возобновляем суточный цикл
          console.log(
            `[orchestrator-tick] Taaskäivitamine: graafikuga ülesanne ${key} ei ole täna pärast ${minStartTime} sooritatud`
          );
          if (targetDateStr > state.cycle_date) {
            state = resetCycleForNewDay(state, targetDateStr, undefined, timezone, currentDate);
          } else {
            state.status = 'IN_PROGRESS';
            if (state.tasks[key]) {
              state.tasks[key].status = 'PENDING';
            }
          }
        }
      }
    }

    // Проверяем задачи с prompt (например, режим тестирования localhost для calc_arv_jaak):
    // если AI-модель принимает решение RUN, цикл возобновляется в IN_PROGRESS
    const promptTasks = Object.entries(state.tasks).filter(([_, t]) => t.prompt && t.prompt.trim().length > 0);
    for (const [pKey, pTask] of promptTasks) {
      if (options.aiGenerateFn) {
        try {
          let parentParams: Record<string, unknown> = {};
          try {
            parentParams = registry[pKey]?.resolveParentParams?.(state) ?? {};
          } catch {
            parentParams = {};
          }
          if (Object.keys(parentParams).length > 0) {
            pTask.params = { ...(pTask.params || {}), ...parentParams };
          }

          const decision = await evaluateTaskLaunchDecision(
            pKey,
            pTask,
            state,
            currentDate,
            dailyStartHour,
            effectiveForceRun,
            options.aiGenerateFn,
            apiClient,
            dailyStartTime,
            timezone,
            false,
            registry[pKey]
          );
          if (decision.should_run || decision.action === 'RUN') {
            console.log(`[orchestrator-tick] Prompt-otsus käivitamiseks (${pKey}): ${decision.reason}`);
            state.status = 'IN_PROGRESS';
            pTask.status = 'PENDING';
            if (decision.dynamic_params) {
              // параметры родителя (logId предшественника) приоритетнее решения модели
              pTask.params = { ...(pTask.params || {}), ...decision.dynamic_params, ...parentParams };
            }
          }
        } catch {
          // Игнорируем ошибку обращения к LLM на шаге ожидания
        }
      }
    }

    // Если после проверки расписаний и prompt статус все еще COMPLETED/FAILED:
    if (state.status === 'COMPLETED' || state.status === 'FAILED') {
      const isWaitAllowed =
        !effectiveForceRun &&
        state.next_scheduled_run &&
        currentDate.getTime() < new Date(state.next_scheduled_run).getTime();

      if (isWaitAllowed) {
        console.log(
          `[orchestrator-tick] Tsükkel on juba lõpetatud (${state.status}). Järgmine lubatud käivitamine: ${state.next_scheduled_run}`
        );
        state.last_tick_at = nowIso;
        await stateManager.saveState(state);
        await invokeScheduleMonitorSafe(state, orchestratorConfig, apiClient, currentDate, overrideMonitorParams);
        return OrchestratorTickOutputSchema.parse({
          cycleDate: state.cycle_date,
          cycleStatus: state.status,
          action: 'IDLE_WAIT_NEXT_SCHEDULE',
          message: `Rutiinne tsükkel lõpetatud (${state.status}). Ootel kuni ${state.next_scheduled_run}`,
          activeTasks: [],
          completedTasks: Object.keys(state.tasks).filter((k) => state.tasks[k].status === 'SUCCESS'),
          pendingTasks: [],
          failedTasks: Object.keys(state.tasks).filter((k) => state.tasks[k].status === 'FAILED'),
          skippedTasks: Object.keys(state.tasks).filter((k) => state.tasks[k].status === 'SKIPPED'),
          nextScheduledRun: state.next_scheduled_run,
        });
      } else {
        // Наступило время следующего запуска или передан forceRun
        console.log(`[orchestrator-tick] Uue ööpäevase tsükli lähtestamine: ${targetDateStr}`);
        state = resetCycleForNewDay(state, targetDateStr, undefined, timezone, currentDate);
      }
    }
  }

  // Проверка начала окна старта или наличия готовых задач по расписанию для IDLE
  if (state.status === 'IDLE') {
    const hasScheduledTaskReady = Object.values(state.tasks).some((task) => {
      if (task.status !== 'PENDING') return false;
      if (!task.schedule) return false;
      const schedCheck = isTaskScheduleReady(task.schedule, currentDate, timezone);
      return schedCheck.ready && !schedCheck.shouldSkip;
    });

    if (!effectiveForceRun && cycleDecision.action === 'WAIT_SCHEDULE' && !hasScheduledTaskReady) {
      console.log(`[orchestrator-tick] ${cycleDecision.reason}`);
      state.last_tick_at = nowIso;
      await stateManager.saveState(state);
      await invokeScheduleMonitorSafe(state, orchestratorConfig, apiClient, currentDate, overrideMonitorParams);
      return OrchestratorTickOutputSchema.parse({
        cycleDate: state.cycle_date,
        cycleStatus: state.status,
        action: 'IDLE_WAIT_START_HOUR',
        message: cycleDecision.reason,
        activeTasks: [],
        completedTasks: [],
        pendingTasks: Object.keys(state.tasks),
        failedTasks: [],
        skippedTasks: [],
        nextScheduledRun: null,
      });
    }

    state.status = 'IN_PROGRESS';
  }

  // 3. Инспекция активных RUNNING задач
  const runningKeys = Object.keys(state.tasks).filter((k) => state.tasks[k].status === 'RUNNING');
  if (runningKeys.length > 0) {
    console.log(`[orchestrator-tick] Aktiivsete ülesannete kontroll: ${runningKeys.join(', ')}`);
    await Promise.all(
      runningKeys.map(async (key) => {
        const task = state.tasks[key];
        // статус читается по log_id запуска этой задачи; без log_id - последняя запись flow
        const statusResult = await checkTaskStatus(
          resolveTaskUserId(task, effectiveCycleUserId, explicitUserId),
          task.flow,
          apiClient,
          task.log_id
        );

        // 3.1. Если задача завершилась (в логах status === 'success' или status === 'failed')
        if (statusResult.status === 'success' || statusResult.status === 'failed') {
          const evaluation = await evaluateTaskResultDecision(
            key,
            task,
            statusResult,
            currentDate,
            options.aiTaskResultGenerateFn
          );

          if (evaluation.status === 'SUCCESS') {
            console.log(`[orchestrator-tick] Ülesanne ${key} edukalt lõpetatud: ${evaluation.summary}`);
            task.status = 'SUCCESS';
            task.finished_at = statusResult.execEnd || nowIso;
            task.duration_ms = statusResult.durationMs ?? null;
            task.result_summary = evaluation.summary;
            task.error = null;
            state.history.push({
              timestamp: nowIso,
              event: 'TASK_COMPLETED',
              task: key,
              details: `status: success, duration: ${task.duration_ms}ms, summary: ${evaluation.summary}`,
            });
            return;
          }

          // Если evaluation.status === 'FAILED' (скрытые ошибки в result или статус failed)
          const currentAttempts = task.attempts || 1;
          const maxAttempts = task.max_attempts || config.maxTaskAttempts || 3;

          // Сверка перед повтором: если после нашего запуска сегодня появился более поздний успешный запуск этого flow
          // (например, ручной перезапуск), принимаем его и не запускаем задачу повторно
          if (task.log_id) {
            const laterRun = await checkTaskAlreadyRunToday(
              resolveTaskUserId(task, effectiveCycleUserId, explicitUserId),
              task.flow,
              apiClient,
              targetDateStr,
              undefined,
              timezone
            );
            if (laterRun.alreadyRun && laterRun.logId && laterRun.logId > task.log_id) {
              console.log(
                `[orchestrator-tick] Ülesanne ${key}: leitud hilisem edukas käivitus (log_id: ${laterRun.logId}), korduskäivitust ei tehta`
              );
              task.status = 'SUCCESS';
              task.log_id = laterRun.logId;
              task.finished_at = laterRun.lastExecEnd || nowIso;
              task.duration_ms = laterRun.durationMs ?? null;
              task.error = null;
              state.history.push({
                timestamp: nowIso,
                event: 'TASK_RECONCILED_LOGS',
                task: key,
                details: `Later successful run accepted instead of retry (log_id: ${laterRun.logId})`,
              });
              return;
            }
          }

          // Бэкенд пометил сбой как неповторяемый (нет данных/прав и т.п.): повтор с теми же входными данными бессмыслен
          const nonRetryable = statusResult.retryable === false;

          if (!nonRetryable && currentAttempts < maxAttempts) {
            const nextAttempt = currentAttempts + 1;
            const reason = evaluation.error || statusResult.error || 'Täitmisel ilmnesid vead';

            console.warn(
              `[orchestrator-tick] Ülesande ${key} korduskäivitus (${nextAttempt}/${maxAttempts}). Põhjus: ${reason}`
            );

            try {
              let parentParams: Record<string, unknown> = {};
              try {
                parentParams = registry[key]?.resolveParentParams?.(state) ?? {};
              } catch {
                parentParams = {};
              }

              if (Object.keys(parentParams).length > 0) {
                console.log(`[orchestrator-tick] Parent params for ${key}:`, JSON.stringify(parentParams));
              }

              task.params = {
                ...(task.params || {}),
                ...parentParams,
              };

              const dupGuard = await guardAgainstDuplicate(task, resolveTaskUserId(task, effectiveCycleUserId, explicitUserId), apiClient, currentDate);
              if (dupGuard.state !== 'none') {
                console.warn(
                  `[orchestrator-tick] Ülesande ${key} korduskäivitus blokeeritud (${dupGuard.state}): ${dupGuard.reason}`
                );
                state.history.push({
                  timestamp: nowIso,
                  event: 'TASK_DUP_BLOCKED',
                  task: key,
                  details: `retry after failure blocked: ${dupGuard.state}, log_id: ${dupGuard.logId ?? 'n/a'}, reason: ${dupGuard.reason}`,
                });
                return;
              }

              const logId = await dispatchTaskByKey(
                key,
                effectiveCycleUserId,
                effectiveCycleRekvId,
                state.params.kond,
                apiClient,
                task.params as Record<string, unknown>,
                registry
              );

              task.status = 'RUNNING';
              task.attempts = nextAttempt;
              task.log_id = logId;
              task.started_at = nowIso;
              task.error = null;

              state.history.push({
                timestamp: nowIso,
                event: 'TASK_RETRY',
                task: key,
                details: `attempt: ${nextAttempt}/${maxAttempts}, reason: ${reason}, log_id: ${logId}`,
              });
              return;
            } catch (retryErr: unknown) {
              const message = retryErr instanceof Error ? retryErr.message : String(retryErr);
              console.error(`[orchestrator-tick] Viga ülesande ${key} korduskäivitusel: ${message}`);
              task.attempts = nextAttempt;
              if (nextAttempt >= maxAttempts) {
                task.status = 'FAILED';
                task.finished_at = nowIso;
                task.duration_ms = statusResult.durationMs ?? null;
                task.error = `Katsed (${maxAttempts}) ammendatud. Viimane viga: ${message}`;
                task.result_summary = evaluation.summary;
                state.history.push({
                  timestamp: nowIso,
                  event: 'TASK_FAILED',
                  task: key,
                  details: task.error,
                });
                return;
              }
            }
          } else {
            // Лимит попыток исчерпан либо сбой неповторяемый
            const finalError =
              evaluation.error ||
              statusResult.error ||
              `ou.logs status: failed pärast ${currentAttempts} katset`;

            console.error(
              nonRetryable
                ? `[orchestrator-tick] Ülesanne ${key} ebaõnnestus (korduskäivitus ei ole mõttekas, retryable=false): ${finalError}`
                : `[orchestrator-tick] Ülesanne ${key} ebaõnnestus lõplikult pärast ${currentAttempts} katset: ${finalError}`
            );
            task.status = 'FAILED';
            task.finished_at = statusResult.execEnd || nowIso;
            task.duration_ms = statusResult.durationMs ?? null;
            task.error = finalError;
            task.result_summary = evaluation.summary;
            state.history.push({
              timestamp: nowIso,
              event: nonRetryable ? 'TASK_FAILED_NON_RETRYABLE' : 'TASK_FAILED',
              task: key,
              details: task.error,
            });
            return;
          }
        }

        // 3.2. Проверяем критерии сбоя при отсутствии даты старта (exec_start) или если задача еще не стартовала в логах
        const hasNoStartDate = !statusResult.execStart || statusResult.status === 'not_started';
        if (hasNoStartDate) {
          // Grace-период: запуск только что отправлен, запись в ou.logs может быть еще не видна
          const sentMs = task.started_at ? new Date(task.started_at).getTime() : NaN;
          const sinceStartMs = currentDate.getTime() - sentMs;
          if (!Number.isNaN(sentMs) && sinceStartMs >= 0 && sinceStartMs < NO_START_GRACE_MS) {
            console.log(
              `[orchestrator-tick] Ülesanne ${key}: exec_start puudub, kuid käivitusest on möödunud vaid ${Math.round(
                sinceStartMs / 1000
              )} s (grace ${NO_START_GRACE_MS / 60000} min). Ootame.`
            );
            return;
          }
          const currentAttempts = task.attempts || 1;
          const maxAttempts = task.max_attempts || config.maxTaskAttempts || 3;

          if (currentAttempts < maxAttempts) {
            const nextAttempt = currentAttempts + 1;
            const reason = 'Algusaeg (exec_start) puudub logides';

            console.warn(
              `[orchestrator-tick] Ülesande ${key} korduskäivitus (${nextAttempt}/${maxAttempts}). Põhjus: ${reason}`
            );

            try {
              let parentParams: Record<string, unknown> = {};
              try {
                parentParams = registry[key]?.resolveParentParams?.(state) ?? {};
              } catch {
                parentParams = {};
              }

              if (Object.keys(parentParams).length > 0) {
                console.log(`[orchestrator-tick] Parent params for ${key}:`, JSON.stringify(parentParams));
              }

              task.params = {
                ...(task.params || {}),
                ...parentParams,
              };

              const dupGuard = await guardAgainstDuplicate(task, resolveTaskUserId(task, effectiveCycleUserId, explicitUserId), apiClient, currentDate);
              if (dupGuard.state !== 'none') {
                console.warn(
                  `[orchestrator-tick] Ülesande ${key} korduskäivitus blokeeritud (${dupGuard.state}): ${dupGuard.reason}`
                );
                state.history.push({
                  timestamp: nowIso,
                  event: 'TASK_DUP_BLOCKED',
                  task: key,
                  details: `retry NO_START_DATE blocked: ${dupGuard.state}, log_id: ${dupGuard.logId ?? 'n/a'}, reason: ${dupGuard.reason}`,
                });
                return;
              }

              const logId = await dispatchTaskByKey(
                key,
                effectiveCycleUserId,
                effectiveCycleRekvId,
                state.params.kond,
                apiClient,
                task.params as Record<string, unknown>,
                registry
              );

              task.status = 'RUNNING';
              task.attempts = nextAttempt;
              task.log_id = logId;
              task.started_at = nowIso;
              task.error = null;

              state.history.push({
                timestamp: nowIso,
                event: 'TASK_RETRY',
                task: key,
                details: `attempt: ${nextAttempt}/${maxAttempts}, reason: NO_START_DATE, log_id: ${logId}`,
              });
            } catch (retryErr: unknown) {
              const message = retryErr instanceof Error ? retryErr.message : String(retryErr);
              console.error(`[orchestrator-tick] Viga ülesande ${key} korduskäivitusel: ${message}`);
              task.attempts = nextAttempt;
              if (nextAttempt >= maxAttempts) {
                task.status = 'FAILED';
                task.finished_at = nowIso;
                task.error = `Katsed (${maxAttempts}) ammendatud. Viimane viga: ${message}`;
                state.history.push({
                  timestamp: nowIso,
                  event: 'TASK_FAILED',
                  task: key,
                  details: task.error,
                });
              }
            }
          } else {
            // Лимит попыток исчерпан
            const finalError = `Algusaeg (exec_start) puudub logides pärast ${currentAttempts} katset`;

            console.error(
              `[orchestrator-tick] Ülesanne ${key} ebaõnnestus lõplikult pärast ${currentAttempts} katset: ${finalError}`
            );
            task.status = 'FAILED';
            task.finished_at = statusResult.execEnd || nowIso;
            task.error = finalError;
            state.history.push({
              timestamp: nowIso,
              event: 'TASK_FAILED',
              task: key,
              details: task.error,
            });
          }
        } else {
          // Задача в процессе исполнения (есть exec_start, статус в ou.logs еще не завершен)
          // Проверяем Watchdog таймаута: если превышен таймаут выполнения (timeout_hours, дефолт 12ч)
          const timeoutHours =
            task.timeout_hours && task.timeout_hours > 0 ? task.timeout_hours : 12;
          const taskTimeoutLimitMs = timeoutHours * 3600 * 1000;

          const startTimestamp = task.started_at
            ? new Date(task.started_at).getTime()
            : statusResult.execStart
            ? new Date(statusResult.execStart).getTime()
            : 0;
          const executionDurationMs = startTimestamp > 0 ? currentDate.getTime() - startTimestamp : 0;

          if (startTimestamp > 0 && executionDurationMs > taskTimeoutLimitMs) {
            console.warn(
              `[orchestrator-tick] Ülesande ${key} täitmise aeg (${Math.round(
                executionDurationMs / 1000 / 60
              )} min) ületab lubatud limiiti (${timeoutHours} h). Käivitub TASK_TIMEOUT.`
            );

            const currentAttempts = task.attempts || 1;
            const maxAttempts = task.max_attempts || config.maxTaskAttempts || 3;

            if (currentAttempts < maxAttempts) {
              const nextAttempt = currentAttempts + 1;
              const timeoutReason = `TASK_TIMEOUT: ületatud ${timeoutHours} h täitmise limiit`;

              try {
                let parentParams: Record<string, unknown> = {};
                try {
                  parentParams = registry[key]?.resolveParentParams?.(state) ?? {};
                } catch {
                  parentParams = {};
                }

                if (Object.keys(parentParams).length > 0) {
                  console.log(`[orchestrator-tick] Parent params for ${key}:`, JSON.stringify(parentParams));
                }

                task.params = {
                  ...(task.params || {}),
                  ...parentParams,
                };

                const logId = await dispatchTaskByKey(
                  key,
                  effectiveCycleUserId,
                  effectiveCycleRekvId,
                  state.params.kond,
                  apiClient,
                  task.params as Record<string, unknown>,
                  registry
                );

                task.status = 'RUNNING';
                task.attempts = nextAttempt;
                task.log_id = logId;
                task.started_at = nowIso;
                task.error = null;

                state.history.push({
                  timestamp: nowIso,
                  event: 'TASK_TIMEOUT',
                  task: key,
                  details: `attempt: ${nextAttempt}/${maxAttempts}, reason: ${timeoutReason}, log_id: ${logId}`,
                });
              } catch (timeoutRetryErr: unknown) {
                const message =
                  timeoutRetryErr instanceof Error ? timeoutRetryErr.message : String(timeoutRetryErr);
                console.error(`[orchestrator-tick] Viga ülesande ${key} korduskäivitusel pärast aegumist: ${message}`);
                task.attempts = nextAttempt;
                if (nextAttempt >= maxAttempts) {
                  task.status = 'FAILED';
                  task.finished_at = nowIso;
                  task.error = `Katsed (${maxAttempts}) ammendatud. Viimane viga: ${message}`;
                  state.history.push({
                    timestamp: nowIso,
                    event: 'TASK_FAILED',
                    task: key,
                    details: task.error,
                  });
                }
              }
            } else {
              // Лимит попыток исчерпан
              const finalError = `TASK_TIMEOUT: täitmise aeg ületas ${timeoutHours} h pärast ${currentAttempts} katset`;
              task.status = 'FAILED';
              task.finished_at = nowIso;
              task.error = finalError;
              state.history.push({
                timestamp: nowIso,
                event: 'TASK_TIMEOUT',
                task: key,
                details: finalError,
              });
              state.history.push({
                timestamp: nowIso,
                event: 'TASK_FAILED',
                task: key,
                details: finalError,
              });
            }
          } else {
            console.log(
              `[orchestrator-tick] Ülesanne ${key} on teostamisel (algusaeg: ${statusResult.execStart || task.started_at})`
            );
          }
        }
      })
    );
  }

  // 4. Оценка графа зависимостей для PENDING задач (гибридная: prompt-first AI или детерминированный FSM)
  const pendingKeys = Object.keys(state.tasks).filter(
    (k) =>
      k !== 'reporter' &&
      k !== 'schedule_monitor' &&
      state.tasks[k].status === 'PENDING' &&
      (!selectedTaskKey || k === selectedTaskKey)
  );

  const readyToStartKeys: string[] = [];

  for (const key of pendingKeys) {
    const task = state.tasks[key];

    // Если у задачи allow_parallel === false, проверяем, нет ли уже выполняющихся задач
    if (task.allow_parallel === false && hasRunningTasks) {
      console.log(`[orchestrator-tick] Ülesanne ${key} ootel: paralleelne käivitamine ei ole lubatud`);
      continue;
    }

    // Подтягиваем родительские параметры (Parent Context Forwarding) ДО принятия решения LLM/FSM,
    // чтобы DecisionContext содержал актуальный logId предшественника
    let parentParams: Record<string, unknown> = {};
    try {
      parentParams = registry[key]?.resolveParentParams?.(state) ?? {};
    } catch {
      parentParams = {};
    }

    if (Object.keys(parentParams).length > 0) {
      console.log(`[orchestrator-tick] Parent params for ${key}:`, JSON.stringify(parentParams));
    }

    task.params = {
      ...(task.params || {}),
      ...parentParams,
    };

    const isTargetTaskKey = Boolean(selectedTaskKey && key === selectedTaskKey);
    const taskForceRun = effectiveForceRun || isTargetTaskKey;

    const decision = await evaluateTaskLaunchDecision(
      key,
      task,
      state,
      currentDate,
      dailyStartHour,
      taskForceRun,
      options.aiGenerateFn,
      apiClient,
      dailyStartTime,
      timezone,
      isTargetTaskKey,
      registry[key]
    );

    if (decision.action === 'SKIP' || (!decision.should_run && decision.action !== 'WAIT')) {
      console.warn(`[orchestrator-tick] Ülesande ${key} vahelejätmine: ${decision.reason}`);
      task.status = 'SKIPPED';
      task.finished_at = nowIso;
      task.error = decision.reason;
      state.history.push({
        timestamp: nowIso,
        event: 'TASK_SKIPPED',
        task: key,
        details: decision.reason,
      });
      continue;
    }

    if (decision.action === 'RUN' || decision.should_run) {
      if (decision.dynamic_params) {
        // параметры родителя (logId предшественника) приоритетнее решения модели: LLM не может подменить logId
        task.params = { ...(task.params || {}), ...decision.dynamic_params, ...parentParams };
      }

      readyToStartKeys.push(key);
    } else {
      console.log(`[orchestrator-tick] Ülesanne ${key} ootel: ${decision.reason}`);
    }
  }

  // 5. Параллельный запуск готовых задач
  if (readyToStartKeys.length > 0) {
    console.log(`[orchestrator-tick] Valmis ülesannete paralleelkäivitus: ${readyToStartKeys.join(', ')}`);
    await Promise.all(
      readyToStartKeys.map(async (key) => {
        const task = state.tasks[key];
        try {
          const dupGuard = await guardAgainstDuplicate(task, resolveTaskUserId(task, effectiveCycleUserId, explicitUserId), apiClient, currentDate);
          if (dupGuard.state !== 'none') {
            if (dupGuard.state === 'running') {
              // Запуск уже идёт (например, state был потерян): берём его под наблюдение вместо дубля
              console.warn(`[orchestrator-tick] Ülesanne ${key}: ou.logs-is on juba käimasolev käivitus (log_id: ${dupGuard.logId ?? 'n/a'}). Duplikaati ei looda.`);
              task.status = 'RUNNING';
              task.attempts = Math.max(task.attempts || 0, 1);
              task.max_attempts = task.max_attempts || config.maxTaskAttempts || 3;
              task.log_id = dupGuard.logId ?? task.log_id;
              task.started_at = dupGuard.execStart ?? nowIso;
              state.history.push({
                timestamp: nowIso,
                event: 'TASK_DUP_BLOCKED',
                task: key,
                details: `start blocked, adopted running log_id: ${dupGuard.logId ?? 'n/a'}, reason: ${dupGuard.reason}`,
              });
            } else {
              // Статус лога неизвестен: остаёмся в PENDING до следующего тика
              console.warn(`[orchestrator-tick] Ülesanne ${key} käivitamine edasi lükatud: ${dupGuard.reason}`);
            }
            return;
          }

          const logId = await dispatchTaskByKey(
            key,
            effectiveCycleUserId,
            effectiveCycleRekvId,
            state.params.kond,
            apiClient,
            task.params as Record<string, unknown>,
            registry
          );

          const failedSoftDeps = (task.soft_depends_on || []).filter((sd) => {
            const st = state.tasks[sd]?.status;
            return st === 'FAILED' || st === 'SKIPPED';
          });
          task.soft_deps_failed = failedSoftDeps.length > 0 ? failedSoftDeps : undefined;

          task.status = 'RUNNING';
          task.attempts = (task.attempts || 0) + 1;
          task.max_attempts = task.max_attempts || config.maxTaskAttempts || 3;
          task.log_id = logId;
          task.started_at = nowIso;
          state.history.push({
            timestamp: nowIso,
            event: 'TASK_STARTED',
            task: key,
            details: `log_id: ${logId}, attempt: ${task.attempts}/${task.max_attempts}`,
          });
        } catch (err: unknown) {
          const message = err instanceof Error ? err.message : String(err);
          console.error(`[orchestrator-tick] Viga ülesande ${key} käivitamisel: ${message}`);

          const nextAttempt = (task.attempts || 0) + 1;
          const maxAttempts = task.max_attempts || config.maxTaskAttempts || 3;
          const nonRetryable = Boolean(
            err && typeof err === 'object' && (err as { retryable?: boolean }).retryable === false
          );
          task.attempts = nextAttempt;
          task.max_attempts = maxAttempts;
          task.error = message;

          if (!nonRetryable && nextAttempt < maxAttempts) {
            task.status = 'PENDING';
            console.warn(
              `[orchestrator-tick] Ülesanne ${key} ebaõnnestus käivitamisel (${nextAttempt}/${maxAttempts}). Jääb olekusse PENDING järgmise tiku korduskäivituseks.`
            );
            state.history.push({
              timestamp: nowIso,
              event: 'TASK_START_RETRY',
              task: key,
              details: `Käivitustõrge (katse ${nextAttempt}/${maxAttempts}): ${message}. Ootel järgmise tikuni.`,
            });
          } else {
            task.status = 'FAILED';
            task.finished_at = nowIso;
            state.history.push({
              timestamp: nowIso,
              event: 'TASK_START_FAILED',
              task: key,
              details: `Käivitustõrge (maksimaalsed katsed ${maxAttempts} ammendatud): ${message}`,
            });
          }
        }
      })
    );
  }

  // 6. Проверка готовности reporter по расписанию (08:00) / зависимостям и вызов reporter
  const calcTasks = Object.keys(state.tasks).filter((k) => k !== 'reporter' && k !== 'schedule_monitor');
  const allCalcFinished = calcTasks.every((k) => {
    const s = state.tasks[k].status;
    return s === 'SUCCESS' || s === 'FAILED' || s === 'SKIPPED';
  });

  const anyFailed = calcTasks.some((k) => state.tasks[k].status === 'FAILED');
  const overallSuccess = !anyFailed;

  const reporterTask = state.tasks.reporter;
  const reporterDeps = reporterTask ? getAllDeps(reporterTask) : [];
  // max_wait_time (HH:mm): предельное время ожидания зависимостей - после него отчет уходит с тем, что есть
  const reporterWaitExpired = reporterTask?.max_wait_time
    ? isDailyExecutionWindowOpen(currentDate, reporterTask.max_wait_time, timezone)
    : false;
  const reporterDepsFinished =
    reporterDeps.length > 0
      ? reporterWaitExpired ||
        reporterDeps.every((depKey) => {
          const s = state.tasks[depKey]?.status;
          return s === 'SUCCESS' || s === 'FAILED' || s === 'SKIPPED';
        })
      : reporterTask?.schedule
      ? true
      : allCalcFinished;

  const reporterFinishDate = reporterTask?.finished_at ? toLocalDateStr(reporterTask.finished_at, timezone) : null;
  const isReporterAlreadyRunToday = reporterFinishDate === targetDateStr && reporterTask?.status === 'SUCCESS';

  const reporterScheduleCheck = reporterTask?.schedule
    ? isTaskScheduleReady(reporterTask.schedule, currentDate, timezone)
    : { ready: true, shouldSkip: false };
  const reporterScheduleReady =
    (!reporterTask?.schedule && effectiveForceRun) ||
    selectedTaskKey === 'reporter' ||
    (reporterScheduleCheck.ready && !reporterScheduleCheck.shouldSkip);

  const isReporterTriggerReady =
    reporterTask?.status === 'PENDING' &&
    (!isReporterAlreadyRunToday || selectedTaskKey === 'reporter') &&
    reporterScheduleReady &&
    reporterDepsFinished;

  if (isReporterTriggerReady && reporterTask) {
    console.log(`[orchestrator-tick] Reporter käivitamine: koostatakse viimase 24h koondaruanne (graafik 08:00)`);

    const steps: ReportStepDetail[] = await Promise.all(
      calcTasks.map(async (k) => {
        const t = state.tasks[k];
        let stepLog: any = null;

        // Задача, которая сегодня еще не стартовала (PENDING без запуска), не должна подхватывать вчерашний лог,
        // за исключением случая, когда у неё есть свежий (<= 24ч) снимок last_run
        const notStartedYet = t?.status === 'PENDING' && !t.log_id;
        const lastRunRefIso = t?.last_run ? t.last_run.finished_at || t.last_run.started_at : null;
        const lastRunMs = lastRunRefIso ? new Date(lastRunRefIso).getTime() : NaN;
        const recentLastRun =
          notStartedYet &&
          t?.last_run &&
          !isNaN(lastRunMs) &&
          lastRunMs >= currentDate.getTime() - 24 * 60 * 60 * 1000
            ? t.last_run
            : null;
        const effectiveLogId = t?.log_id || recentLastRun?.log_id;
        if (apiClient && t?.flow && (!notStartedYet || recentLastRun?.log_id)) {
          try {
            const taskUserId = resolveTaskUserId(t, effectiveCycleUserId, explicitUserId);
            // Приоритет - запись запуска (по log_id текущего цикла или last_run.log_id)
            if (effectiveLogId) {
              const byId = await readTaskLog(
                { userId: taskUserId, taskName: t.flow, logId: effectiveLogId },
                apiClient
              );
              if (byId?.data && byId.data.length > 0) {
                stepLog = byId.data[0];
              }
            }
            if (!stepLog && !recentLastRun) {
              const logRes = await readTaskLog(
                {
                  userId: taskUserId,
                  taskName: t.flow,
                  hours: 24,
                  limit: 1,
                },
                apiClient
              );
              if (logRes?.data && logRes.data.length > 0) {
                stepLog = logRes.data[0];
              }
            }
          } catch {
            // fallback to state.tasks / recentLastRun
          }
        }

        if (stepLog && stepLog.exec_start) {
          let durationMs: number | undefined;
          if (stepLog.exec_start && stepLog.exec_end) {
            const start = new Date(stepLog.exec_start).getTime();
            const end = new Date(stepLog.exec_end).getTime();
            if (!isNaN(start) && !isNaN(end) && end >= start) {
              durationMs = end - start;
            }
          }
          const inspectResult = inspectLogExecutionResult(stepLog);
          const logStatus: ReportStepDetail['status'] =
            stepLog.status === 'success' && !inspectResult.hasErrors
              ? 'SUCCESS'
              : stepLog.status === 'failed' || stepLog.status === 'error' || inspectResult.hasErrors
              ? 'FAILED'
              : stepLog.exec_end
              ? 'SUCCESS'
              : 'RUNNING';

          const logId = typeof stepLog.id === 'number' ? stepLog.id : undefined;

          const enriched = registry[k]?.enrichReportStep?.(stepLog as Record<string, unknown>, t) ?? {};
          const summaryText = appendSoftDepsWarning(
            enriched.resultSummary || inspectResult.resultSummary || t.result_summary || undefined,
            t
          );

          return {
            stepName: t.flow,
            status: logStatus,
            logId,
            execStart: stepLog.exec_start ?? undefined,
            execEnd: stepLog.exec_end ?? undefined,
            durationMs: durationMs ?? (t.duration_ms ?? undefined),
            error: inspectResult.errorDetails || stepLog.error || t.error || undefined,
            ...enriched,
            resultSummary: summaryText,
          };
        }

        if (recentLastRun) {
          const enrichedLastRun = registry[k]?.enrichReportStep?.(null, t) ?? {};
          return {
            stepName: t.flow,
            status: recentLastRun.status as ReportStepDetail['status'],
            logId: recentLastRun.log_id ?? undefined,
            execStart: recentLastRun.started_at ?? undefined,
            execEnd: recentLastRun.finished_at ?? undefined,
            durationMs: recentLastRun.duration_ms ?? undefined,
            error: recentLastRun.error ?? undefined,
            ...enrichedLastRun,
            resultSummary: enrichedLastRun.resultSummary ?? recentLastRun.result_summary ?? undefined,
          };
        }

        // Шаги, не завершившиеся к моменту отчета, показываем как RUNNING / PENDING ("pooleli"), а не как пропущенные
        const stepStatus: ReportStepDetail['status'] =
          t.status === 'SUCCESS'
            ? 'SUCCESS'
            : t.status === 'FAILED'
            ? 'FAILED'
            : t.status === 'RUNNING'
            ? 'RUNNING'
            : t.status === 'PENDING'
            ? 'PENDING'
            : 'SKIPPED';

        const enrichedFallback = registry[k]?.enrichReportStep?.(null, t) ?? {};

        return {
          stepName: t.flow,
          status: stepStatus,
          logId: t.log_id ?? undefined,
          execStart: t.started_at ?? undefined,
          execEnd: t.finished_at ?? undefined,
          durationMs: t.duration_ms ?? undefined,
          error: t.error ?? undefined,
          ...enrichedFallback,
          resultSummary: appendSoftDepsWarning(
            enrichedFallback.resultSummary ??
              t.result_summary ??
              (t.status === 'SKIPPED'
                ? 'Vahele jäetud'
                : t.status === 'RUNNING' || t.status === 'PENDING'
                ? 'Pooleli (ootab lõpetamist)'
                : undefined),
            t
          ),
        };
      })
    );

    const reportOverallSuccess = !steps.some((s) => s.status === 'FAILED');

    try {
      await generateAndSendReportSubagent({
        userId: effectiveCycleUserId,
        rekvId: effectiveCycleRekvId,
        executionDate: targetDateStr,
        steps,
        overallSuccess: reportOverallSuccess,
        notes: reportOverallSuccess
          ? 'Kõik viimase 24h rutiinsed arvestused on edukalt lõpetatud.'
          : 'Mõned viimase 24h rutiinsed arvestused lõppesid vigadega.',
        recipientEmail,
      });
      state.tasks.reporter.status = 'SUCCESS';
      state.tasks.reporter.finished_at = nowIso;
      state.tasks.reporter.result_summary = reportOverallSuccess
        ? 'Viimase 24h koondaruanne edukalt saadetud'
        : 'Viimase 24h koondaruanne saadetud (ilmnesid vead)';
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error(`[orchestrator-tick] Viga aruande saatmisel: ${msg}`);
      state.tasks.reporter.status = 'FAILED';
      state.tasks.reporter.error = msg;
    }

    if (allCalcFinished) {
      state.status = overallSuccess ? 'COMPLETED' : 'FAILED';
      const [dh, dm] = dailyStartTime.split(':').map(Number);
      let earliestMinutes = dh * 60 + (dm || 0);
      for (const task of Object.values(state.tasks)) {
        if (task.schedule?.time) {
          const [h, m] = task.schedule.time.split(':').map(Number);
          const total = h * 60 + m;
          if (total < earliestMinutes) {
            earliestMinutes = total;
          }
        }
      }
      const nextHour = Math.floor(earliestMinutes / 60);
      const nextMinute = earliestMinutes % 60;
      state.next_scheduled_run = calculateNextScheduledRun(targetDateStr, nextHour, nextMinute, timezone);

      state.history.push({
        timestamp: nowIso,
        event: overallSuccess ? 'CYCLE_COMPLETED' : 'CYCLE_FAILED',
        details: `next_scheduled_run: ${state.next_scheduled_run}`,
      });
    }
  } else if (allCalcFinished && state.status === 'IN_PROGRESS' && state.tasks.reporter?.status !== 'PENDING') {
    state.status = overallSuccess ? 'COMPLETED' : 'FAILED';
    if (!state.next_scheduled_run || new Date(state.next_scheduled_run).getTime() <= currentDate.getTime()) {
      const [dh, dm] = dailyStartTime.split(':').map(Number);
      let earliestMinutes = dh * 60 + (dm || 0);
      for (const task of Object.values(state.tasks)) {
        if (task.schedule?.time) {
          const [h, m] = task.schedule.time.split(':').map(Number);
          const total = h * 60 + m;
          if (total < earliestMinutes) {
            earliestMinutes = total;
          }
        }
      }
      const nextHour = Math.floor(earliestMinutes / 60);
      const nextMinute = earliestMinutes % 60;
      state.next_scheduled_run = calculateNextScheduledRun(targetDateStr, nextHour, nextMinute, timezone);
    }
    state.history.push({
      timestamp: nowIso,
      event: overallSuccess ? 'CYCLE_COMPLETED' : 'CYCLE_FAILED',
      details: `next_scheduled_run: ${state.next_scheduled_run}`,
    });
  }

  // 7. Сохранение состояния и формирование вывода
  state.last_tick_at = nowIso;
  await stateManager.saveState(state);
  await invokeScheduleMonitorSafe(state, orchestratorConfig, apiClient, currentDate, overrideMonitorParams);

  const active = Object.keys(state.tasks).filter((k) => state.tasks[k].status === 'RUNNING');
  const completed = Object.keys(state.tasks).filter((k) => state.tasks[k].status === 'SUCCESS');
  const pending = Object.keys(state.tasks).filter((k) => state.tasks[k].status === 'PENDING');
  const failed = Object.keys(state.tasks).filter((k) => state.tasks[k].status === 'FAILED');
  const skipped = Object.keys(state.tasks).filter((k) => state.tasks[k].status === 'SKIPPED');

  const action =
    state.status === 'COMPLETED'
      ? 'CYCLE_COMPLETED'
      : state.status === 'FAILED'
      ? 'CYCLE_FAILED'
      : 'TICK_EXECUTED';

  return OrchestratorTickOutputSchema.parse({
    cycleDate: state.cycle_date,
    cycleStatus: state.status,
    action,
    message: `Tik täidetud. Olek: ${state.status}. Aktiivsed: ${active.length}, Valmis: ${completed.length}`,
    activeTasks: active,
    completedTasks: completed,
    pendingTasks: pending,
    failedTasks: failed,
    skippedTasks: skipped,
    nextScheduledRun: state.next_scheduled_run,
  });
}

/**
 * Классический запуск оркестратора с полным циклом (для обратной совместимости)
 */
export async function runOrchestrator(
  input: OrchestratorInput = {},
  options: OrchestratorOptions = {}
): Promise<OrchestratorOutput> {
  const validated = OrchestratorInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;
  const orchestratorConfig = loadOrchestratorConfig();
  const timezone = options.timezone || orchestratorConfig.timezone || 'Europe/Tallinn';
  const refDate = options.currentDate || new Date();
  const executionDate = options.targetDateStr || toLocalDateStr(refDate.toISOString(), timezone);
  const steps: ReportStepDetail[] = [];
  let overallSuccess = true;

  console.log(`[orchestrator] Rutiinsete ülesannete käivitamine kuupäeval: ${executionDate}`);

  // --- ШАГ 1: Расчет сальдоандмика ---
  let saldoSuccess = false;
  if (!validated.forceRun) {
    const history = await checkTaskAlreadyRunToday(
      validated.userId,
      TASK_FLOW_SALDOANDMIK,
      apiClient,
      executionDate
    );
    if (history.alreadyRun) {
      console.log(`[orchestrator] Samm 1 (${TASK_FLOW_SALDOANDMIK}) on täna juba sooritatud. Vahelejätmine.`);
      steps.push({
        stepName: TASK_FLOW_SALDOANDMIK,
        status: 'SKIPPED',
        execEnd: history.lastExecEnd,
      });
      saldoSuccess = true;
    }
  }

  if (!saldoSuccess) {
    console.log(`[orchestrator] Samm 1 käivitamine: ${TASK_FLOW_SALDOANDMIK}`);
    try {
      const saldoResult = await runSaldoandmikSubagent(
        {
          userId: validated.userId,
          rekvId: validated.rekvId,
          kond: validated.kond,
        },
        {
          apiClient,
          sleepFn: options.sleepFn,
          pollIntervalMs: validated.pollIntervalMs,
          maxTimeoutMs: validated.maxTimeoutMs,
        }
      );

      const isSuccess = saldoResult.status === 'success';
      steps.push({
        stepName: TASK_FLOW_SALDOANDMIK,
        status: isSuccess ? 'SUCCESS' : saldoResult.status === 'timeout' ? 'TIMEOUT' : 'FAILED',
        logId: saldoResult.logId,
        execStart: saldoResult.execStart,
        execEnd: saldoResult.execEnd,
        durationMs: saldoResult.durationMs,
        error: saldoResult.error,
      });

      saldoSuccess = isSuccess;
      if (!isSuccess) {
        overallSuccess = false;
      }
    } catch (err: unknown) {
      const errorMsg = err instanceof Error ? err.message : String(err);
      console.error(`[orchestrator] Viga sammus 1 (${TASK_FLOW_SALDOANDMIK}): ${errorMsg}`);
      steps.push({
        stepName: TASK_FLOW_SALDOANDMIK,
        status: 'FAILED',
        error: errorMsg,
      });
      saldoSuccess = false;
      overallSuccess = false;
    }
  }

  // --- ШАГ 2: Пересчет остатков счетов (параллельный/независимый расчет) ---
  let arvJaakSuccess = false;
  if (!validated.forceRun) {
    const history = await checkTaskAlreadyRunToday(
      validated.userId,
      TASK_FLOW_CALC_ARV_JAAK,
      apiClient,
      executionDate
    );
    if (history.alreadyRun) {
      console.log(`[orchestrator] Samm 2 (${TASK_FLOW_CALC_ARV_JAAK}) on täna juba sooritatud. Vahelejätmine.`);
      steps.push({
        stepName: TASK_FLOW_CALC_ARV_JAAK,
        status: 'SKIPPED',
        execEnd: history.lastExecEnd,
      });
      arvJaakSuccess = true;
    }
  }

  if (!arvJaakSuccess) {
    console.log(`[orchestrator] Samm 2 käivitamine: ${TASK_FLOW_CALC_ARV_JAAK}`);
    try {
      const arvJaakResult = await runCalcArvJaakSubagent(
        {
          userId: validated.userId,
          rekvId: validated.rekvId,
        },
        {
          apiClient,
          sleepFn: options.sleepFn,
          pollIntervalMs: validated.pollIntervalMs,
          maxTimeoutMs: validated.maxTimeoutMs,
        }
      );

      const isSuccess = arvJaakResult.status === 'success';
      steps.push({
        stepName: TASK_FLOW_CALC_ARV_JAAK,
        status: isSuccess ? 'SUCCESS' : arvJaakResult.status === 'timeout' ? 'TIMEOUT' : 'FAILED',
        logId: arvJaakResult.logId,
        execStart: arvJaakResult.execStart,
        execEnd: arvJaakResult.execEnd,
        durationMs: arvJaakResult.durationMs,
        error: arvJaakResult.error,
      });

      arvJaakSuccess = isSuccess;
      if (!isSuccess) {
        overallSuccess = false;
      }
    } catch (err: unknown) {
      const errorMsg = err instanceof Error ? err.message : String(err);
      console.error(`[orchestrator] Viga sammus 2 (${TASK_FLOW_CALC_ARV_JAAK}): ${errorMsg}`);
      steps.push({
        stepName: TASK_FLOW_CALC_ARV_JAAK,
        status: 'FAILED',
        error: errorMsg,
      });
      arvJaakSuccess = false;
      overallSuccess = false;
    }
  }

  // --- ШАГ 3: Импорт счетов из FinBit (getEarved) ---
  let getEarvedSuccess = false;
  let lastEarvedLogId: number | undefined;
  if (!validated.forceRun) {
    const history = await checkTaskAlreadyRunToday(
      validated.userId,
      TASK_FLOW_GET_EARVED,
      apiClient,
      executionDate
    );
    if (history.alreadyRun) {
      console.log(`[orchestrator] Samm 3 (${TASK_FLOW_GET_EARVED}) on täna juba sooritatud. Vahelejätmine.`);
      steps.push({
        stepName: TASK_FLOW_GET_EARVED,
        status: 'SKIPPED',
        execEnd: history.lastExecEnd,
      });
      getEarvedSuccess = true;
    }
  }

  if (!getEarvedSuccess) {
    console.log(`[orchestrator] Samm 3 käivitamine: ${TASK_FLOW_GET_EARVED}`);
    try {
      const earvedResult = await runGetEarvedSubagent(
        {
          userId: validated.userId,
          rekvId: validated.rekvId,
        },
        {
          apiClient,
          sleepFn: options.sleepFn,
          pollIntervalMs: validated.pollIntervalMs,
          maxTimeoutMs: validated.maxTimeoutMs,
        }
      );

      const isSuccess = earvedResult.status === 'success';
      lastEarvedLogId = earvedResult.logId;
      steps.push({
        stepName: TASK_FLOW_GET_EARVED,
        status: isSuccess ? 'SUCCESS' : earvedResult.status === 'timeout' ? 'TIMEOUT' : 'FAILED',
        logId: earvedResult.logId,
        execStart: earvedResult.execStart,
        execEnd: earvedResult.execEnd,
        durationMs: earvedResult.durationMs,
        error: earvedResult.error,
      });

      getEarvedSuccess = isSuccess;
      if (!isSuccess) {
        overallSuccess = false;
      }
    } catch (err: unknown) {
      const errorMsg = err instanceof Error ? err.message : String(err);
      console.error(`[orchestrator] Viga sammus 3 (${TASK_FLOW_GET_EARVED}): ${errorMsg}`);
      steps.push({
        stepName: TASK_FLOW_GET_EARVED,
        status: 'FAILED',
        error: errorMsg,
      });
      getEarvedSuccess = false;
      overallSuccess = false;
    }
  }

  // --- ШАГ 3.0: Проверка контр-агентов (check_asutus) и частичный импорт счетов (import_earved) ---
  // getEarved только выкачивает счета. Проверка и разбор выполняются отдельными агентами.
  let importSuccess = false;
  let lastImportLogId: number | undefined;
  if (getEarvedSuccess && lastEarvedLogId) {
    try {
      console.log(`[orchestrator] Samm 3.0 käivitamine: ${TASK_FLOW_CHECK_ASUTUS} (logId: ${lastEarvedLogId})`);
      const checkResult = await runCheckAsutusSubagent(
        { userId: validated.userId, rekvId: validated.rekvId, logId: lastEarvedLogId },
        {
          apiClient,
          sleepFn: options.sleepFn,
          pollIntervalMs: validated.pollIntervalMs,
          maxTimeoutMs: validated.maxTimeoutMs,
        }
      );
      const checkOk = checkResult.status === 'success';
      steps.push({
        stepName: TASK_FLOW_CHECK_ASUTUS,
        status: checkOk ? 'SUCCESS' : checkResult.status === 'timeout' ? 'TIMEOUT' : 'FAILED',
        logId: checkResult.logId,
        execStart: checkResult.execStart,
        execEnd: checkResult.execEnd,
        durationMs: checkResult.durationMs,
        error: checkResult.error,
        resultSummary: checkResult.resultSummary,
      });

      if (checkOk) {
        console.log(`[orchestrator] Samm 3.0 käivitamine: ${TASK_FLOW_IMPORT_EARVED} (logId: ${lastEarvedLogId})`);
        const importResult = await runImportEarvedSubagent(
          { userId: validated.userId, rekvId: validated.rekvId, logId: lastEarvedLogId },
          {
            apiClient,
            sleepFn: options.sleepFn,
            pollIntervalMs: validated.pollIntervalMs,
            maxTimeoutMs: validated.maxTimeoutMs,
          }
        );
        importSuccess = importResult.status === 'success';
        lastImportLogId = importResult.logId;
        steps.push({
          stepName: TASK_FLOW_IMPORT_EARVED,
          status: importSuccess ? 'SUCCESS' : importResult.status === 'timeout' ? 'TIMEOUT' : 'FAILED',
          logId: importResult.logId,
          execStart: importResult.execStart,
          execEnd: importResult.execEnd,
          durationMs: importResult.durationMs,
          error: importResult.error,
          resultSummary: importResult.resultSummary,
        });
        if (!importSuccess) {
          overallSuccess = false;
        }
      } else {
        overallSuccess = false;
      }
    } catch (err: unknown) {
      const errorMsg = err instanceof Error ? err.message : String(err);
      console.error(`[orchestrator] Viga sammus 3.0 (${TASK_FLOW_CHECK_ASUTUS}/${TASK_FLOW_IMPORT_EARVED}): ${errorMsg}`);
      steps.push({
        stepName: TASK_FLOW_IMPORT_EARVED,
        status: 'FAILED',
        error: errorMsg,
      });
      importSuccess = false;
      overallSuccess = false;
    }
  }

  // --- ШАГ 3.1: Отправка отчетов FinBit (sendFinBitReport, зависит от import_earved) ---
  if (importSuccess && lastImportLogId) {
    console.log(`[orchestrator] Samm 3.1 käivitamine: ${TASK_FLOW_SEND_FIN_BIT_REPORT} (logId: ${lastImportLogId})`);
    try {
      const sendReportResult = await runSendFinBitReportSubagent(
        {
          userId: validated.userId,
          rekvId: validated.rekvId,
          logId: lastImportLogId,
        },
        {
          apiClient,
          sleepFn: options.sleepFn,
          pollIntervalMs: validated.pollIntervalMs,
          maxTimeoutMs: validated.maxTimeoutMs,
        }
      );

      const isSuccess = sendReportResult.status === 'success' && !sendReportResult.hasErrors;
      steps.push({
        stepName: TASK_FLOW_SEND_FIN_BIT_REPORT,
        status: isSuccess ? 'SUCCESS' : sendReportResult.status === 'timeout' ? 'TIMEOUT' : 'FAILED',
        logId: sendReportResult.logId,
        execStart: sendReportResult.execStart,
        execEnd: sendReportResult.execEnd,
        durationMs: sendReportResult.durationMs,
        error: sendReportResult.error || sendReportResult.errorDetails,
        resultSummary: sendReportResult.resultSummary,
      });

      if (!isSuccess) {
        overallSuccess = false;
      }
    } catch (err: unknown) {
      const errorMsg = err instanceof Error ? err.message : String(err);
      console.error(`[orchestrator] Viga sammus 3.1 (${TASK_FLOW_SEND_FIN_BIT_REPORT}): ${errorMsg}`);
      steps.push({
        stepName: TASK_FLOW_SEND_FIN_BIT_REPORT,
        status: 'FAILED',
        error: errorMsg,
      });
      overallSuccess = false;
    }
  } else if (!getEarvedSuccess || (lastEarvedLogId && !importSuccess)) {
    console.warn(`[orchestrator] Samm 3.1 (${TASK_FLOW_SEND_FIN_BIT_REPORT}) vahelejätmine getEarved/import_earved vea tõttu`);
    steps.push({
      stepName: TASK_FLOW_SEND_FIN_BIT_REPORT,
      status: 'SKIPPED',
      error: 'Vahele jäetud getEarved/import_earved impordi vea tõttu',
    });
  }

  // --- ШАГ 4: Контроль Lisa 1 / Lisa 5 (зависит от saldoandmik) ---
  if (saldoSuccess) {
    let lisaSuccess = false;
    if (!validated.forceRun) {
      const history = await checkTaskAlreadyRunToday(
        validated.userId,
        TASK_FLOW_LISA1_LISA5,
        apiClient,
        executionDate
      );
      if (history.alreadyRun) {
        console.log(`[orchestrator] Samm 4 (${TASK_FLOW_LISA1_LISA5}) on täna juba sooritatud. Vahelejätmine.`);
        steps.push({
          stepName: TASK_FLOW_LISA1_LISA5,
          status: 'SKIPPED',
          execEnd: history.lastExecEnd,
        });
        lisaSuccess = true;
      }
    }

    if (!lisaSuccess) {
      console.log(`[orchestrator] Samm 4 käivitamine: ${TASK_FLOW_LISA1_LISA5}`);
      try {
        const lisaResult = await runLisa1Lisa5Subagent(
          {
            userId: validated.userId,
            rekvId: validated.rekvId,
          },
          {
            apiClient,
            sleepFn: options.sleepFn,
            pollIntervalMs: validated.pollIntervalMs,
            maxTimeoutMs: validated.maxTimeoutMs,
          }
        );

        const isSuccess = lisaResult.status === 'success';
        steps.push({
          stepName: TASK_FLOW_LISA1_LISA5,
          status: isSuccess ? 'SUCCESS' : lisaResult.status === 'timeout' ? 'TIMEOUT' : 'FAILED',
          logId: lisaResult.logId,
          execStart: lisaResult.execStart,
          execEnd: lisaResult.execEnd,
          durationMs: lisaResult.durationMs,
          error: lisaResult.error,
        });

        if (!isSuccess) {
          overallSuccess = false;
        }
      } catch (err: unknown) {
        const errorMsg = err instanceof Error ? err.message : String(err);
        console.error(`[orchestrator] Viga sammus 4 (${TASK_FLOW_LISA1_LISA5}): ${errorMsg}`);
        steps.push({
          stepName: TASK_FLOW_LISA1_LISA5,
          status: 'FAILED',
          error: errorMsg,
        });
        overallSuccess = false;
      }
    }
  } else {
    console.warn(`[orchestrator] Samm 4 (${TASK_FLOW_LISA1_LISA5}) vahelejätmine saldoandmiku vea tõttu`);
    steps.push({
      stepName: TASK_FLOW_LISA1_LISA5,
      status: 'SKIPPED',
      error: 'Vahele jäetud saldoandmiku arvestuse vea tõttu',
    });
  }

  // --- ШАГ 5: Итоговая отчетность через reporter (Email) ---
  console.log(`[orchestrator] Lõpparuande koostamine ja saatmine e-postiga`);
  try {
    await generateAndSendReportSubagent({
      userId: validated.userId,
      rekvId: validated.rekvId,
      executionDate,
      steps,
      overallSuccess,
      notes: overallSuccess
        ? 'Kõik rutiinsed arvestused on edukalt lõpetatud.'
        : 'Rutiinsete arvestuste täitmine katkestati vigadega.',
      recipientEmail: options.recipientEmail,
    });
  } catch (err: unknown) {
    console.error(`[orchestrator] Viga aruande saatmisel:`, err);
  }

  const message = overallSuccess
    ? 'Rutiinne tsükkel edukalt lõpetatud'
    : 'Rutiinne tsükkel lõppes vigadega';

  return OrchestratorOutputSchema.parse({
    executionDate,
    userId: validated.userId,
    rekvId: validated.rekvId,
    steps,
    overallSuccess,
    message,
  });
}
