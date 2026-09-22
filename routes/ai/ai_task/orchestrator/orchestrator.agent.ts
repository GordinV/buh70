import { ApiClient, defaultApiClient } from '../shared/api_client';
import { runSaldoandmikSubagent } from '../saldoandmik/agent';
import { startSaldoandmik } from '../saldoandmik/tools';
import { TASK_FLOW_SALDOANDMIK } from '../saldoandmik/schemas';
import { runCalcArvJaakSubagent } from '../calc_arv_jaak/agent';
import { startCalcArvJaak } from '../calc_arv_jaak/tools';
import { TASK_FLOW_CALC_ARV_JAAK } from '../calc_arv_jaak/schemas';
import { runGetEarvedSubagent } from '../getEarved/agent';
import { startGetEarved } from '../getEarved/tools';
import { TASK_FLOW_GET_EARVED } from '../getEarved/schemas';
import { runSendFinBitReportSubagent } from '../sendFinBitReport/agent';
import { startSendFinBitReport } from '../sendFinBitReport/tools';
import { TASK_FLOW_SEND_FIN_BIT_REPORT } from '../sendFinBitReport/schemas';
import { runLisa1Lisa5Subagent } from '../lisa1_lisa5/agent';
import { startLisa1Lisa5 } from '../lisa1_lisa5/tools';
import { TASK_FLOW_LISA1_LISA5 } from '../lisa1_lisa5/schemas';
import { TaskStatusCheckResult, checkTaskStatus } from '../logs_watcher/agent';
import { generateAndSendReportSubagent } from '../reporter/agent';
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
  TaskResultContext,
  TaskResultEvaluation,
  TaskResultEvaluationSchema,
  TaskSchedule,
  TaskState,
  TaskStatus,
} from './orchestrator.schemas';
import { checkTaskAlreadyRunToday } from './orchestrator.tools';
import {
  StateManager,
  calculateNextScheduledRun,
  loadOrchestratorConfig,
  resetCycleForNewDay,
} from './state.manager';

export interface OrchestratorTickOptions {
  apiClient?: ApiClient;
  stateFilePath?: string;
  targetDateStr?: string;
  currentDate?: Date;
  recipientEmail?: string;
  forceRun?: boolean;
  maxTimeoutMs?: number;
  dailyStartHour?: number;
  dailyStartTime?: string;
  timezone?: string;
  orchestratorConfig?: OrchestratorConfig;
  aiGenerateFn?: (prompt: string, context: DecisionContext) => Promise<AgentLaunchDecision>;
  aiCycleGenerateFn?: (prompt: string, context: CycleDecisionContext) => Promise<CycleDecision>;
  aiTaskResultGenerateFn?: (prompt: string, context: TaskResultContext) => Promise<TaskResultEvaluation>;
}

export interface OrchestratorOptions {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
  targetDateStr?: string;
  recipientEmail?: string;
}

/**
 * Вспомогательная функция для запуска расчетной задачи по ключу в графе с поддержкой кастомных параметров
 */
async function dispatchTaskByKey(
  key: string,
  userId: number,
  rekvId: number,
  kond: number,
  apiClient: ApiClient,
  customParams?: Record<string, unknown>
): Promise<number | null> {
  const finalUserId = (customParams?.userId as number) ?? userId;
  const finalRekvId = (customParams?.rekvId as number) ?? rekvId;
  const finalKond = (customParams?.kond as number) ?? kond;

  if (key === 'saldoandmik') {
    const res = await startSaldoandmik(
      { userId: finalUserId, rekvId: finalRekvId, kond: finalKond },
      apiClient
    );
    return res.log_id;
  }
  if (key === 'calc_arv_jaak') {
    const res = await startCalcArvJaak(
      { userId: finalUserId, rekvId: finalRekvId },
      apiClient
    );
    return res.log_id;
  }
  if (key === 'getEarved') {
    const res = await startGetEarved(
      {
        userId: finalUserId,
        rekvId: finalRekvId,
        dateQueryFrom: customParams?.dateQueryFrom as string | undefined,
      },
      apiClient
    );
    return res.log_id;
  }
  if (key === 'sendFinBitReport') {
    const logId = (customParams?.logId as number) ?? (customParams?.paramLogId as number);
    if (!logId) {
      throw new Error(`sendFinBitReport viga: logId puudub (parent context getEarved log_id ei ole edastatud)`);
    }
    const res = await startSendFinBitReport(
      { userId: finalUserId, rekvId: finalRekvId, logId },
      apiClient
    );
    return res.log_id;
  }
  if (key === 'lisa1_lisa5') {
    const res = await startLisa1Lisa5(
      { userId: finalUserId, rekvId: finalRekvId },
      apiClient
    );
    return res.log_id;
  }
  return null;
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
  currentDate: Date
): ScheduleCheckResult {
  if (!schedule) {
    return { ready: true, shouldSkip: false };
  }

  // Проверка месяца (1-12)
  if (schedule.month !== undefined && schedule.month !== null) {
    const currentMonth = currentDate.getMonth() + 1;
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
    const currentDay = currentDate.getDate();
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
    const currentTotalMinutes = currentDate.getHours() * 60 + currentDate.getMinutes();

    if (currentTotalMinutes < schedTotalMinutes) {
      const currentH = String(currentDate.getHours()).padStart(2, '0');
      const currentM = String(currentDate.getMinutes()).padStart(2, '0');
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
  timezone?: string
): Promise<AgentLaunchDecision> {
  // Собираем статусы предшественников
  const depsState: Record<string, TaskStatus> = {};
  for (const dep of task.depends_on) {
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

  const schedCheckForContext = isTaskScheduleReady(task.schedule, currentDate);

  const context: DecisionContext = {
    currentServerTime: currentDate.toISOString(),
    localTime: localTimeFormatted,
    localDate: localDateFormatted,
    timezone: effectiveTimezone,
    isScheduleDue: schedCheckForContext.ready && !schedCheckForContext.shouldSkip,
    agentName: key,
    params: (task.params as Record<string, unknown>) || {},
    schedule: task.schedule,
    dependenciesState: depsState,
    attempts: task.attempts || 0,
    taskStatus: task.status,
    apiBaseUrl: effectiveApiClient.getConfig().buh70ApiBaseUrl,
  };

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

  // 2.2. Проверка готовности предшественников
  const allDepsSuccess = task.depends_on.every((d) => state.tasks[d]?.status === 'SUCCESS');
  if (!allDepsSuccess) {
    return {
      should_run: false,
      action: 'WAIT',
      reason: 'Ootel eelnevate sõltuvuste lõpetamiseni',
    };
  }

  // Для sendFinBitReport проверяем наличие log_id родительского getEarved
  if (key === 'sendFinBitReport') {
    const parentLogId = state.tasks['getEarved']?.log_id;
    if (!parentLogId) {
      return {
        should_run: false,
        action: 'SKIP',
        reason: 'Vahele jäetud: vanemülesande getEarved log_id puudub',
      };
    }
  }

  // 2.3. Корневые задачи без явного расписания ожидают наступления базового суточного окна (dailyStartTime / dailyStartHour)
  // Если у задачи есть зависимости (например, sendFinBitReport -> getEarved), и они уже успешно завершены,
  // задача готова к старту сразу после завершения предшественников.
  if (!task.schedule && (!task.depends_on || task.depends_on.length === 0) && !forceRun) {
    const windowStart = dailyStartTime || `${dailyStartHour}:00`;
    const tz = timezone || 'Europe/Tallinn';
    const isOpen = isDailyExecutionWindowOpen(currentDate, windowStart, tz);
    if (!isOpen) {
      let localHour = currentDate.getHours();
      return {
        should_run: false,
        action: 'WAIT',
        reason: `Ootel kuni ${windowStart} (praegu kell ${localHour})`,
      };
    }
  }

  // 2.4. Проверка индивидуального расписания (Time & Date Scheduler)
  const schedCheck = isTaskScheduleReady(task.schedule, currentDate);
  if (schedCheck.shouldSkip) {
    return {
      should_run: false,
      action: 'SKIP',
      reason: schedCheck.reason || 'Vahele jäetud graafiku tõttu',
    };
  }

  if (schedCheck.ready) {
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
  const targetDateStr = options.targetDateStr || currentDate.toISOString().slice(0, 10);
  const forceRun = options.forceRun ?? validated.forceRun;
  const maxTimeoutMs = options.maxTimeoutMs || config.taskTimeoutMs;
  const recipientEmail = options.recipientEmail || validated.recipientEmail || config.reportEmailTo;

  // 1.1. Загрузка состояния
  let state = await stateManager.loadState(
    { userId: validated.userId, rekvId: validated.rekvId, kond: validated.kond },
    targetDateStr
  );

  const nowIso = currentDate.toISOString();
  console.log(`[orchestrator-tick] Käivitamine kuupäeval: ${targetDateStr}, hetkeolek: ${state.status}`);

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

  // 1.4. Проверка суточного регламента и сверка с логами (ou.logs Reconciliation)
  if (!hasRunningTasks && (state.status === 'COMPLETED' || state.status === 'FAILED')) {
    // Проверяем задачи с индивидуальным расписанием (schedule.time), чье время уже наступило сегодня
    const dueScheduledTasks = Object.entries(state.tasks).filter(([_, task]) => {
      if (!task.schedule) return false;
      const schedCheck = isTaskScheduleReady(task.schedule, currentDate);
      return schedCheck.ready && !schedCheck.shouldSkip;
    });

    for (const [key, task] of dueScheduledTasks) {
      // Проверяем, отмечена ли уже задача как SUCCESS за сегодняшний день
      const isAlreadySuccessToday = state.cycle_date === targetDateStr && task.status === 'SUCCESS';
      if (!isAlreadySuccessToday) {
        const minStartTime = task.schedule?.time || undefined;
        const logCheck = await checkTaskAlreadyRunToday(
          state.params.userId,
          task.flow,
          apiClient,
          targetDateStr,
          minStartTime
        );

        if (logCheck.alreadyRun) {
          console.log(
            `[orchestrator-tick] Ülesanne ${key} on logide järgi juba edukalt sooritatud (ou.logs)`
          );
          if (targetDateStr > state.cycle_date) {
            state = resetCycleForNewDay(state, targetDateStr);
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
            state = resetCycleForNewDay(state, targetDateStr);
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
            timezone
          );
          if (decision.should_run || decision.action === 'RUN') {
            console.log(`[orchestrator-tick] Prompt-otsus käivitamiseks (${pKey}): ${decision.reason}`);
            state.status = 'IN_PROGRESS';
            pTask.status = 'PENDING';
            if (decision.dynamic_params) {
              pTask.params = { ...(pTask.params || {}), ...decision.dynamic_params };
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
        state = resetCycleForNewDay(state, targetDateStr);
      }
    }
  }

  // Проверка начала окна старта или наличия готовых задач по расписанию для IDLE
  if (state.status === 'IDLE') {
    const hasScheduledTaskReady = Object.values(state.tasks).some((task) => {
      if (task.status !== 'PENDING') return false;
      if (!task.schedule) return false;
      const schedCheck = isTaskScheduleReady(task.schedule, currentDate);
      return schedCheck.ready && !schedCheck.shouldSkip;
    });

    if (!effectiveForceRun && cycleDecision.action === 'WAIT_SCHEDULE' && !hasScheduledTaskReady) {
      console.log(`[orchestrator-tick] ${cycleDecision.reason}`);
      state.last_tick_at = nowIso;
      await stateManager.saveState(state);
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
        const statusResult = await checkTaskStatus(state.params.userId, task.flow, apiClient);

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

          if (currentAttempts < maxAttempts) {
            const nextAttempt = currentAttempts + 1;
            const reason = evaluation.error || statusResult.error || 'Täitmisel ilmnesid vead';

            console.warn(
              `[orchestrator-tick] Ülesande ${key} korduskäivitus (${nextAttempt}/${maxAttempts}). Põhjus: ${reason}`
            );

            try {
              if (key === 'sendFinBitReport' && !task.params?.logId && state.tasks['getEarved']?.log_id) {
                task.params = { ...(task.params || {}), logId: state.tasks['getEarved'].log_id };
              }

              const logId = await dispatchTaskByKey(
                key,
                state.params.userId,
                state.params.rekvId,
                state.params.kond,
                apiClient,
                task.params as Record<string, unknown>
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
            // Лимит попыток исчерпан
            const finalError =
              evaluation.error ||
              statusResult.error ||
              `ou.logs status: failed pärast ${currentAttempts} katset`;

            console.error(
              `[orchestrator-tick] Ülesanne ${key} ebaõnnestus lõplikult pärast ${currentAttempts} katset: ${finalError}`
            );
            task.status = 'FAILED';
            task.finished_at = statusResult.execEnd || nowIso;
            task.duration_ms = statusResult.durationMs ?? null;
            task.error = finalError;
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

        // 3.2. Проверяем критерии сбоя при отсутствии даты старта (exec_start) или если задача еще не стартовала в логах
        const hasNoStartDate = !statusResult.execStart || statusResult.status === 'not_started';
        if (hasNoStartDate) {
          const currentAttempts = task.attempts || 1;
          const maxAttempts = task.max_attempts || config.maxTaskAttempts || 3;

          if (currentAttempts < maxAttempts) {
            const nextAttempt = currentAttempts + 1;
            const reason = 'Algusaeg (exec_start) puudub logides';

            console.warn(
              `[orchestrator-tick] Ülesande ${key} korduskäivitus (${nextAttempt}/${maxAttempts}). Põhjus: ${reason}`
            );

            try {
              if (key === 'sendFinBitReport' && !task.params?.logId && state.tasks['getEarved']?.log_id) {
                task.params = { ...(task.params || {}), logId: state.tasks['getEarved'].log_id };
              }

              const logId = await dispatchTaskByKey(
                key,
                state.params.userId,
                state.params.rekvId,
                state.params.kond,
                apiClient,
                task.params as Record<string, unknown>
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
          // Задача в процессе штатного исполнения (есть exec_start, статус еще не завершен)
          // Таймаут отсутствует: задача выполняется столько времени, сколько необходимо
          console.log(`[orchestrator-tick] Ülesanne ${key} on teostamisel (algusaeg: ${statusResult.execStart})`);
        }
      })
    );
  }

  // 4. Оценка графа зависимостей для PENDING задач (гибридная: prompt-first AI или детерминированный FSM)
  const pendingKeys = Object.keys(state.tasks).filter(
    (k) => k !== 'reporter' && state.tasks[k].status === 'PENDING'
  );

  const readyToStartKeys: string[] = [];

  for (const key of pendingKeys) {
    const task = state.tasks[key];
    const decision = await evaluateTaskLaunchDecision(
      key,
      task,
      state,
      currentDate,
      dailyStartHour,
      effectiveForceRun,
      options.aiGenerateFn,
      apiClient,
      dailyStartTime,
      timezone
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
        task.params = { ...(task.params || {}), ...decision.dynamic_params };
      }

      // Parent Context Forwarding: если это sendFinBitReport, инжектируем log_id родителя getEarved
      if (key === 'sendFinBitReport') {
        const parentLogId = state.tasks['getEarved']?.log_id;
        if (parentLogId && !task.params?.logId) {
          task.params = { ...(task.params || {}), logId: parentLogId };
        }
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
          const logId = await dispatchTaskByKey(
            key,
            state.params.userId,
            state.params.rekvId,
            state.params.kond,
            apiClient,
            task.params as Record<string, unknown>
          );

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
          task.attempts = nextAttempt;
          task.max_attempts = maxAttempts;
          task.error = message;

          if (nextAttempt < maxAttempts) {
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

  // 6. Проверка завершения всех расчетных потоков и вызов reporter
  const calcTasks = Object.keys(state.tasks).filter((k) => k !== 'reporter');
  const allCalcFinished = calcTasks.every((k) => {
    const s = state.tasks[k].status;
    return s === 'SUCCESS' || s === 'FAILED' || s === 'SKIPPED';
  });

  if (allCalcFinished && state.tasks.reporter?.status === 'PENDING') {
    console.log(`[orchestrator-tick] Kõik arvestused tehtud, lõpparuande saatmine e-postiga`);

    const steps: ReportStepDetail[] = calcTasks.map((k) => {
      const t = state.tasks[k];
      const stepStatus: ReportStepDetail['status'] =
        t.status === 'SUCCESS' ? 'SUCCESS' : t.status === 'FAILED' ? 'FAILED' : 'SKIPPED';
      return {
        stepName: t.flow,
        status: stepStatus,
        logId: t.log_id ?? undefined,
        execStart: t.started_at ?? undefined,
        execEnd: t.finished_at ?? undefined,
        durationMs: t.duration_ms ?? undefined,
        error: t.error ?? undefined,
        resultSummary: t.result_summary ?? undefined,
      };
    });

    const anyFailed = calcTasks.some((k) => state.tasks[k].status === 'FAILED');
    const overallSuccess = !anyFailed;

    try {
      await generateAndSendReportSubagent({
        userId: state.params.userId,
        rekvId: state.params.rekvId,
        executionDate: targetDateStr,
        steps,
        overallSuccess,
        notes: overallSuccess
          ? 'Kõik rutiinsed arvestused on edukalt lõpetatud.'
          : 'Mõned rutiinsed arvestused lõppesid vigadega.',
        recipientEmail,
      });
      state.tasks.reporter.status = 'SUCCESS';
      state.tasks.reporter.finished_at = nowIso;
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error(`[orchestrator-tick] Viga aruande saatmisel: ${msg}`);
      state.tasks.reporter.status = 'FAILED';
      state.tasks.reporter.error = msg;
    }

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
    state.next_scheduled_run = calculateNextScheduledRun(targetDateStr, nextHour, nextMinute);

    state.history.push({
      timestamp: nowIso,
      event: overallSuccess ? 'CYCLE_COMPLETED' : 'CYCLE_FAILED',
      details: `next_scheduled_run: ${state.next_scheduled_run}`,
    });
  }

  // 7. Сохранение состояния и формирование вывода
  state.last_tick_at = nowIso;
  await stateManager.saveState(state);

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
  const executionDate = options.targetDateStr || new Date().toISOString().slice(0, 10);
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

  // --- ШАГ 3.1: Отправка отчетов FinBit (sendFinBitReport, зависит от getEarved) ---
  if (getEarvedSuccess && lastEarvedLogId) {
    console.log(`[orchestrator] Samm 3.1 käivitamine: ${TASK_FLOW_SEND_FIN_BIT_REPORT} (logId: ${lastEarvedLogId})`);
    try {
      const sendReportResult = await runSendFinBitReportSubagent(
        {
          userId: validated.userId,
          rekvId: validated.rekvId,
          logId: lastEarvedLogId,
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
  } else if (!getEarvedSuccess) {
    console.warn(`[orchestrator] Samm 3.1 (${TASK_FLOW_SEND_FIN_BIT_REPORT}) vahelejätmine getEarved vea tõttu`);
    steps.push({
      stepName: TASK_FLOW_SEND_FIN_BIT_REPORT,
      status: 'SKIPPED',
      error: 'Vahele jäetud getEarved impordi vea tõttu',
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
