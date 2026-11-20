import * as fs from 'fs';
import * as path from 'path';
import { toLocalDateStr } from './orchestrator.tools';
import {
  AgentConfig,
  AgentConfigSchema,
  LastRun,
  OrchestratorConfig,
  OrchestratorConfigSchema,
  OrchestratorState,
  OrchestratorStateSchema,
  ResetReason,
  TaskState,
} from './orchestrator.schemas';
import { TASK_FLOW_SALDOANDMIK } from '../saldoandmik/schemas';
import { TASK_FLOW_CALC_ARV_JAAK } from '../calc_arv_jaak/schemas';
import { TASK_FLOW_GET_EARVED } from '../getEarved/schemas';
import { TASK_FLOW_SEND_FIN_BIT_REPORT } from '../sendFinBitReport/schemas';
import { TASK_FLOW_LISA1_LISA5 } from '../lisa1_lisa5/schemas';
// Служебные каталоги, которые не являются расчетными задачами DAG (state.tasks): единый источник в shared/
import { EXCLUDED_NON_DAG_DIRS } from '../shared/excluded_dirs';

import { AI_TASK_SERVICE_USER_ID } from '../shared/constants';
export const DEFAULT_STATE_RELATIVE_PATH = path.join('state', 'orchestrator_state.json');

/**
 * Определяет корневую директорию модуля ai_task для поиска конфигураций агентов
 */
export function resolveAiTaskRootDir(customDir?: string): string {
  if (customDir && fs.existsSync(customDir)) {
    return customDir;
  }
  const candidateDirs = [
    path.resolve(__dirname, '..'), // e.g. routes/ai/ai_task when running ts directly
    path.resolve(__dirname, '..', '..'), // e.g. when running from dist/orchestrator
    path.resolve(process.cwd(), 'routes', 'ai', 'ai_task'),
    process.cwd(),
  ];
  for (const dir of candidateDirs) {
    if (fs.existsSync(path.join(dir, 'saldoandmik', 'config.json'))) {
      return dir;
    }
  }
  return path.resolve(__dirname, '..');
}

/**
 * Загружает индивидуальную конфигурацию субагента из <agent>/config.json
 */
export function loadAgentConfig(agentDirName: string, baseDir?: string): AgentConfig | null {
  const root = resolveAiTaskRootDir(baseDir);
  const configPath = path.join(root, agentDirName, 'config.json');
  if (fs.existsSync(configPath)) {
    try {
      const raw = fs.readFileSync(configPath, 'utf8');
      const parsed = JSON.parse(raw);
      return AgentConfigSchema.parse(parsed);
    } catch (err) {
      console.warn(`[state.manager] Viga faili lugemisel või parsimisel (${configPath}):`, err);
    }
  }
  return null;
}

/**
 * Загружает конфигурацию самого агента-оркестратора из orchestrator/config.json
 */
export function loadOrchestratorConfig(baseDir?: string): OrchestratorConfig {
  const root = resolveAiTaskRootDir(baseDir);
  const configPath = path.join(root, 'orchestrator', 'config.json');
  if (fs.existsSync(configPath)) {
    try {
      const raw = fs.readFileSync(configPath, 'utf8');
      const parsed = JSON.parse(raw);
      return OrchestratorConfigSchema.parse(parsed);
    } catch (err) {
      console.warn(`[state.manager] Viga orchestrator/config.json parsimisel (${configPath}):`, err);
    }
  }
  return OrchestratorConfigSchema.parse({});
}

/**
 * Загружает конфигурации всех субагентов из каталога ai_task
 */
export function loadAllAgentConfigs(baseDir?: string): Record<string, AgentConfig> {
  const root = resolveAiTaskRootDir(baseDir);
  const configs: Record<string, AgentConfig> = {};

  // Динамически сканируем поддиректории root для автоматического подключения всех агентов
  try {
    if (fs.existsSync(root)) {
      const entries = fs.readdirSync(root, { withFileTypes: true });
      for (const entry of entries) {
        if (
          entry.isDirectory() &&
          !entry.name.startsWith('.') &&
          !EXCLUDED_NON_DAG_DIRS.has(entry.name)
        ) {
          const cfg = loadAgentConfig(entry.name, root);
          if (cfg) {
            configs[cfg.name || entry.name] = cfg;
          }
        }
      }
    }
  } catch (scanErr) {
    console.warn('[state.manager] Viga agentide kaustade skaneerimisel:', scanErr);
  }

  return configs;
}

/**
 * Статические параметры задачи, для которых источником истины всегда является config.json
 * (<agent>/config.json -> orchestrator/config.json -> AI_TASK_SERVICE_USER_ID / 63),
 * а не сохранённое состояние orchestrator_state.json.
 * Динамические поля (например, logId) сохраняются из state.
 */
export const CONFIG_OWNED_PARAM_KEYS = ['userId', 'rekvId'] as const;

function resolveConfigOwnedParams(
  cfgParams?: Record<string, unknown>,
  orchestratorParams?: { userId?: number; rekvId?: number }
): { userId: number; rekvId: number } {
  const userId =
    typeof cfgParams?.userId === 'number'
      ? cfgParams.userId
      : typeof orchestratorParams?.userId === 'number'
        ? orchestratorParams.userId
        : AI_TASK_SERVICE_USER_ID;
  const rekvId =
    typeof cfgParams?.rekvId === 'number'
      ? cfgParams.rekvId
      : typeof orchestratorParams?.rekvId === 'number'
        ? orchestratorParams.rekvId
        : 63;
  return { userId, rekvId };
}

/**
 * Формирует граф задач на основе загруженных конфигураций AgentConfig
 */
export function buildTaskGraphFromConfigs(
  configs: Record<string, AgentConfig>,
  orchestratorConfig?: OrchestratorConfig
): Record<string, TaskState> {
  const tasks: Record<string, TaskState> = {};
  for (const [key, cfg] of Object.entries(configs)) {
    const configOwned = resolveConfigOwnedParams(cfg.params, orchestratorConfig?.params);
    tasks[key] = {
      flow: cfg.flow,
      depends_on: cfg.depends_on ?? [],
      soft_depends_on: cfg.soft_depends_on ?? [],
      allow_parallel: cfg.allow_parallel ?? true,
      schedule: cfg.schedule ?? null,
      prompt: cfg.prompt ?? null,
      params: { ...(cfg.params ?? {}), ...configOwned },
      status: 'PENDING',
      attempts: 0,
      max_attempts: cfg.max_attempts ?? 3,
      retry_delay_minutes: cfg.retry_delay_minutes ?? 0,
      timeout_hours: cfg.timeout_hours,
      max_wait_time: cfg.max_wait_time,
      log_id: null,
      started_at: null,
      finished_at: null,
      duration_ms: null,
      error: null,
    };
  }
  return tasks;
}

/**
 * Синхронизирует декларативные параметры задач из config.json в текущее состояние задач,
 * не перезаписывая рантайм-поля (status, attempts, log_id, timestamps, duration, error).
 */
export function reconcileTasksWithConfigs(
  existingTasks: Record<string, TaskState>,
  configs: Record<string, AgentConfig>,
  addNewTasks: boolean = true,
  orchestratorConfig?: OrchestratorConfig
): void {
  // Очищаем служебные не-DAG агенты, если они ранее попали в сохраненный state
  for (const excludedKey of EXCLUDED_NON_DAG_DIRS) {
    if (existingTasks[excludedKey]) {
      delete existingTasks[excludedKey];
    }
  }

  for (const [name, cfg] of Object.entries(configs)) {
    const configOwned = resolveConfigOwnedParams(cfg.params, orchestratorConfig?.params);
    const existing = existingTasks[name];
    if (existing) {
      existing.flow = cfg.flow;
      existing.allow_parallel = cfg.allow_parallel ?? true;
      existing.depends_on = cfg.depends_on ?? [];
      existing.soft_depends_on = cfg.soft_depends_on ?? [];
      existing.schedule = cfg.schedule ?? null;
      existing.prompt = cfg.prompt ?? null;
      existing.max_attempts = cfg.max_attempts ?? 3;
      existing.retry_delay_minutes = cfg.retry_delay_minutes ?? 0;
      if (cfg.timeout_hours !== undefined) {
        existing.timeout_hours = cfg.timeout_hours;
      }
      existing.max_wait_time = cfg.max_wait_time;
      // Динамические параметры (logId и др.) сохраняются из state, но CONFIG_OWNED_PARAM_KEYS всегда берутся из конфига
      const mergedParams: Record<string, unknown> = { ...(cfg.params || {}), ...(existing.params || {}) };
      for (const key of CONFIG_OWNED_PARAM_KEYS) {
        mergedParams[key] = configOwned[key];
      }
      existing.params = mergedParams;
    } else if (addNewTasks) {
      existingTasks[name] = {
        flow: cfg.flow,
        depends_on: cfg.depends_on ?? [],
        soft_depends_on: cfg.soft_depends_on ?? [],
        allow_parallel: cfg.allow_parallel ?? true,
        schedule: cfg.schedule ?? null,
        prompt: cfg.prompt ?? null,
        params: { ...(cfg.params ?? {}), ...configOwned },
        status: 'PENDING',
        attempts: 0,
        max_attempts: cfg.max_attempts ?? 3,
      retry_delay_minutes: cfg.retry_delay_minutes ?? 0,
        timeout_hours: cfg.timeout_hours,
        max_wait_time: cfg.max_wait_time,
        log_id: null,
        started_at: null,
        finished_at: null,
        duration_ms: null,
        error: null,
      };
    }
  }
}

/**
 * Возвращает стандартный набор задач графа регламентного цикла
 * (сперва пробует динамически подгрузить из config.json, при сбое использует резервную схему)
 */
export function getDefaultTaskGraph(baseDir?: string): Record<string, TaskState> {
  const configs = loadAllAgentConfigs(baseDir);
  if (Object.keys(configs).length > 0) {
    const orchestratorConfig = loadOrchestratorConfig(baseDir);
    return buildTaskGraphFromConfigs(configs, orchestratorConfig);
  }

  // Резервный дефолтный граф (на случай отсутствия файлов config.json)
  return {
    saldoandmik: {
      flow: TASK_FLOW_SALDOANDMIK,
      depends_on: [],
      allow_parallel: true,
      schedule: null,
      prompt: null,
      params: { userId: AI_TASK_SERVICE_USER_ID, rekvId: 63, kond: 1 },
      status: 'PENDING',
      attempts: 0,
      max_attempts: 3,
      log_id: null,
      started_at: null,
      finished_at: null,
      duration_ms: null,
      error: null,
    },
    calc_arv_jaak: {
      flow: TASK_FLOW_CALC_ARV_JAAK,
      depends_on: [],
      allow_parallel: true,
      schedule: null,
      prompt: null,
      params: { userId: AI_TASK_SERVICE_USER_ID, rekvId: 63 },
      status: 'PENDING',
      attempts: 0,
      max_attempts: 3,
      log_id: null,
      started_at: null,
      finished_at: null,
      duration_ms: null,
      error: null,
    },
    getEarved: {
      flow: TASK_FLOW_GET_EARVED,
      depends_on: [],
      allow_parallel: true,
      schedule: { time: '12:30' },
      prompt: null,
      params: { userId: AI_TASK_SERVICE_USER_ID, rekvId: 63, is_agent: true },
      status: 'PENDING',
      attempts: 0,
      max_attempts: 3,
      log_id: null,
      started_at: null,
      finished_at: null,
      duration_ms: null,
      error: null,
    },
    check_asutus: {
      flow: 'checkAsutusAvailability',
      depends_on: ['getEarved'],
      allow_parallel: true,
      schedule: null,
      prompt: null,
      params: { userId: AI_TASK_SERVICE_USER_ID, rekvId: 63 },
      status: 'PENDING',
      attempts: 0,
      max_attempts: 3,
      log_id: null,
      started_at: null,
      finished_at: null,
      duration_ms: null,
      error: null,
    },
    inforegister: {
      flow: 'getInforegister',
      depends_on: ['check_asutus'],
      allow_parallel: true,
      schedule: null,
      prompt: null,
      params: { userId: AI_TASK_SERVICE_USER_ID, rekvId: 63, dryRun: false, maxCalls: 10 },
      status: 'PENDING',
      attempts: 0,
      max_attempts: 2,
      log_id: null,
      started_at: null,
      finished_at: null,
      duration_ms: null,
      error: null,
    },
    import_earved: {
      flow: 'docs.sp_loe_earved',
      depends_on: ['getEarved', 'check_asutus'],
      soft_depends_on: ['inforegister'],
      allow_parallel: true,
      schedule: null,
      prompt: null,
      params: { userId: AI_TASK_SERVICE_USER_ID, rekvId: 63 },
      status: 'PENDING',
      attempts: 0,
      max_attempts: 3,
      log_id: null,
      started_at: null,
      finished_at: null,
      duration_ms: null,
      error: null,
    },
    sendFinBitReport: {
      flow: TASK_FLOW_SEND_FIN_BIT_REPORT,
      depends_on: ['import_earved'],
      allow_parallel: true,
      schedule: null,
      prompt: null,
      params: { userId: AI_TASK_SERVICE_USER_ID, rekvId: 63 },
      status: 'PENDING',
      attempts: 0,
      max_attempts: 3,
      log_id: null,
      started_at: null,
      finished_at: null,
      duration_ms: null,
      error: null,
    },
    lisa1_lisa5: {
      flow: TASK_FLOW_LISA1_LISA5,
      depends_on: ['saldoandmik'],
      allow_parallel: true,
      schedule: null,
      prompt: null,
      params: { userId: AI_TASK_SERVICE_USER_ID, rekvId: 63 },
      status: 'PENDING',
      attempts: 0,
      max_attempts: 3,
      log_id: null,
      started_at: null,
      finished_at: null,
      duration_ms: null,
      error: null,
    },
    reporter: {
      flow: 'email_report',
      depends_on: [],
      allow_parallel: false,
      schedule: { time: '08:00' },
      prompt: null,
      params: {},
      status: 'PENDING',
      attempts: 0,
      max_attempts: 3,
      log_id: null,
      started_at: null,
      finished_at: null,
      duration_ms: null,
      error: null,
    },
  };
}

/**
 * Возвращает смещение заданного часового пояса относительно UTC в миллисекундах на момент utcDate.
 */
function getTimezoneOffsetMs(utcDate: Date, timezone: string): number {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: timezone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  }).formatToParts(utcDate);

  const map: Record<string, number> = {};
  for (const p of parts) {
    if (p.type !== 'literal') {
      map[p.type] = Number(p.value);
    }
  }
  const tzHour = map.hour === 24 ? 0 : map.hour;
  const asUtc = Date.UTC(map.year, map.month - 1, map.day, tzHour, map.minute, map.second, 0);
  return asUtc - utcDate.getTime();
}

/**
 * Вычисляет время следующего запуска на следующий день в указанный час и минуту в заданном часовом поясе (по умолчанию Europe/Tallinn)
 */
export function calculateNextScheduledRun(
  baseDateStr: string,
  hour = 20,
  minute = 0,
  timezone: string = 'Europe/Tallinn'
): string {
  const parts = baseDateStr.split('-').map(Number);
  const year = parts[0] || new Date().getUTCFullYear();
  const month = (parts[1] || 1) - 1;
  const day = parts[2] || 1;

  const targetUtcGuess = new Date(Date.UTC(year, month, day + 1, hour, minute, 0, 0));
  try {
    const offset1 = getTimezoneOffsetMs(targetUtcGuess, timezone);
    let candidate = new Date(targetUtcGuess.getTime() - offset1);
    const offset2 = getTimezoneOffsetMs(candidate, timezone);
    if (offset2 !== offset1) {
      candidate = new Date(targetUtcGuess.getTime() - offset2);
    }
    return candidate.toISOString();
  } catch {
    return new Date(year, month, day + 1, hour, minute, 0, 0).toISOString();
  }
}

/**
 * Создает начальное состояние оркестратора
 */
export function createInitialState(
  dateStr?: string,
  params: { userId?: number; rekvId?: number; kond?: number } = {},
  baseDir?: string,
  timezone: string = 'Europe/Tallinn'
): OrchestratorState {
  const cycleDate = dateStr || toLocalDateStr(new Date().toISOString(), timezone);
  return OrchestratorStateSchema.parse({
    version: 1,
    cycle_date: cycleDate,
    status: 'IDLE',
    last_tick_at: null,
    next_scheduled_run: null,
    params: {
      userId: params.userId ?? AI_TASK_SERVICE_USER_ID,
      rekvId: params.rekvId ?? 63,
      kond: params.kond ?? 1,
    },
    tasks: getDefaultTaskGraph(baseDir),
    history: [
      {
        timestamp: new Date().toISOString(),
        event: 'INITIALIZED',
        details: `Initial state created for cycle date: ${cycleDate}`,
      },
    ],
  });
}

const FINAL_SNAPSHOT_STATUSES = new Set(['SUCCESS', 'FAILED', 'SKIPPED']);

/**
 * Создаёт снимок последнего запуска задачи перед сбросом в PENDING.
 * Если задача не запускалась (нет log_id и started_at) или статус не финальный — сохраняет прежний last_run.
 */
export function snapshotLastRun(
  task: TaskState,
  reason: ResetReason,
  cycleDate: string,
  nowIso: string
): LastRun | null | undefined {
  const didRun = (task.log_id !== null && task.log_id !== undefined) || Boolean(task.started_at);
  if (didRun && FINAL_SNAPSHOT_STATUSES.has(task.status)) {
    return {
      log_id: task.log_id ?? null,
      status: task.status,
      started_at: task.started_at ?? null,
      finished_at: task.finished_at ?? null,
      duration_ms: task.duration_ms ?? null,
      error: task.error ?? null,
      result_summary: task.result_summary ?? null,
      cycle_date: cycleDate,
      reset_at: nowIso,
      reset_reason: reason,
    };
  }
  return task.last_run;
}

/**
 * Сбрасывает состояние задач для нового суточного расчетного цикла
 */
export function resetCycleForNewDay(
  state: OrchestratorState,
  newDateStr: string,
  baseDir?: string,
  timezone: string = 'Europe/Tallinn',
  currentDate?: Date
): OrchestratorState {
  const defaultTasks = getDefaultTaskGraph(baseDir);
  const nowIso = (currentDate || new Date()).toISOString();

  // Сохраняем состояние задач, которые уже завершились за новые календарные сутки (newDateStr)
  const tasks: Record<string, TaskState> = {};
  for (const [key, defaultTask] of Object.entries(defaultTasks)) {
    const existing = state.tasks[key];
    const finishedToday =
      existing &&
      existing.finished_at &&
      toLocalDateStr(existing.finished_at, timezone) === newDateStr &&
      (existing.status === 'SUCCESS' || existing.status === 'SKIPPED');

    if (finishedToday) {
      tasks[key] = { ...existing };
    } else {
      const lastRun = existing
        ? snapshotLastRun(existing, 'CYCLE_RESET_NEW_DAY', state.cycle_date, nowIso)
        : undefined;
      tasks[key] = lastRun !== undefined ? { ...defaultTask, last_run: lastRun } : defaultTask;
    }
  }

  return OrchestratorStateSchema.parse({
    ...state,
    cycle_date: newDateStr,
    status: 'IN_PROGRESS',
    next_scheduled_run: null,
    tasks,
    history: [
      ...state.history.slice(-50), // Храним последние 50 событий
      {
        timestamp: nowIso,
        event: 'CYCLE_RESET_NEW_DAY',
        details: `Reset tasks for new cycle date: ${newDateStr}`,
      },
    ],
  });
}

export class StateManager {
  private resolvedPath: string;

  constructor(filePath?: string) {
    this.resolvedPath = filePath
      ? path.resolve(filePath)
      : path.resolve(process.cwd(), DEFAULT_STATE_RELATIVE_PATH);
  }

  public getFilePath(): string {
    return this.resolvedPath;
  }

  /**
   * Загружает состояние из файла или инициализирует дефолтное при отсутствии
   */
  public async loadState(
    defaultParams: { userId?: number; rekvId?: number; kond?: number } = {},
    dateStr?: string,
    baseDir?: string,
    timezone: string = 'Europe/Tallinn'
  ): Promise<OrchestratorState> {
    const rootDir = resolveAiTaskRootDir(baseDir);
    const configs = loadAllAgentConfigs(rootDir);
    const orchestratorConfig = loadOrchestratorConfig(rootDir);

    const isProductionState = path.basename(this.resolvedPath) === 'orchestrator_state.json';

    if (fs.existsSync(this.resolvedPath)) {
      try {
        const rawContent = await fs.promises.readFile(this.resolvedPath, 'utf8');
        const parsed = JSON.parse(rawContent);

        // Миграция устаревшего поля previous_cycle_failures в tasks[k].last_run
        if (parsed && typeof parsed === 'object' && parsed.previous_cycle_failures && typeof parsed.previous_cycle_failures === 'object') {
          const nowIso = new Date().toISOString();
          for (const [k, failure] of Object.entries(parsed.previous_cycle_failures as Record<string, any>)) {
            if (parsed.tasks?.[k] && !parsed.tasks[k].last_run && failure && typeof failure === 'object') {
              parsed.tasks[k].last_run = {
                log_id: failure.log_id ?? null,
                status: 'FAILED',
                started_at: failure.started_at ?? null,
                finished_at: failure.finished_at ?? null,
                duration_ms: failure.duration_ms ?? null,
                error: failure.error ?? null,
                result_summary: failure.result_summary ?? null,
                cycle_date: failure.cycle_date || parsed.cycle_date || '',
                reset_at: nowIso,
                reset_reason: 'CYCLE_RESET_NEW_DAY',
              };
            }
          }
          delete parsed.previous_cycle_failures;
        }

        const validated = OrchestratorStateSchema.parse(parsed);

        // Синхронизируем статические конфигурационные параметры задач и цикла из config.json для рабочего файла состояния
        if (isProductionState) {
          if (Object.keys(configs).length > 0) {
            reconcileTasksWithConfigs(validated.tasks, configs, isProductionState, orchestratorConfig);
          }
          validated.params.userId =
            typeof orchestratorConfig.params?.userId === 'number'
              ? orchestratorConfig.params.userId
              : AI_TASK_SERVICE_USER_ID;
          validated.params.rekvId =
            typeof orchestratorConfig.params?.rekvId === 'number'
              ? orchestratorConfig.params.rekvId
              : 63;
        }

        return validated;
      } catch (err: unknown) {
        console.warn(
          `[state.manager] Viga olekufaili lugemisel (${this.resolvedPath}), lähtestamine:`,
          err
        );
      }
    }

    const effectiveDefaultParams = isProductionState
      ? {
          userId:
            typeof orchestratorConfig.params?.userId === 'number'
              ? orchestratorConfig.params.userId
              : defaultParams.userId ?? AI_TASK_SERVICE_USER_ID,
          rekvId:
            typeof orchestratorConfig.params?.rekvId === 'number'
              ? orchestratorConfig.params.rekvId
              : defaultParams.rekvId ?? 63,
          kond: defaultParams.kond,
        }
      : defaultParams;
    const initialState = createInitialState(dateStr, effectiveDefaultParams, rootDir, timezone);
    await this.saveState(initialState);
    return initialState;
  }

  /**
   * Атомарно сохраняет состояние в файл
   */
  public async saveState(state: OrchestratorState): Promise<void> {
    const validated = OrchestratorStateSchema.parse(state);
    const dir = path.dirname(this.resolvedPath);
    if (!fs.existsSync(dir)) {
      await fs.promises.mkdir(dir, { recursive: true });
    }

    const tempPath = `${this.resolvedPath}.${Date.now()}.tmp`;
    const content = JSON.stringify(validated, null, 2);

    await fs.promises.writeFile(tempPath, content, 'utf8');
    try {
      await fs.promises.rename(tempPath, this.resolvedPath);
    } catch (renameErr: unknown) {
      // Резервный механизм замены для Windows при блокировке процессами/антивирусом (EPERM/EXDEV)
      await fs.promises.copyFile(tempPath, this.resolvedPath);
      await fs.promises.unlink(tempPath).catch(() => {});
    }
  }
}
