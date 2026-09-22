import * as fs from 'fs';
import * as path from 'path';
import {
  AgentConfig,
  AgentConfigSchema,
  OrchestratorConfig,
  OrchestratorConfigSchema,
  OrchestratorState,
  OrchestratorStateSchema,
  TaskState,
} from './orchestrator.schemas';
import { TASK_FLOW_SALDOANDMIK } from '../saldoandmik/schemas';
import { TASK_FLOW_CALC_ARV_JAAK } from '../calc_arv_jaak/schemas';
import { TASK_FLOW_GET_EARVED } from '../getEarved/schemas';
import { TASK_FLOW_SEND_FIN_BIT_REPORT } from '../sendFinBitReport/schemas';
import { TASK_FLOW_LISA1_LISA5 } from '../lisa1_lisa5/schemas';

export const DEFAULT_STATE_RELATIVE_PATH = path.join('state', 'orchestrator_state.json');

export const KNOWN_AGENT_DIRS = [
  'saldoandmik',
  'calc_arv_jaak',
  'getEarved',
  'sendFinBitReport',
  'lisa1_lisa5',
  'reporter',
];

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

  // 1. Проверяем известные каталоги агентов
  for (const dirName of KNOWN_AGENT_DIRS) {
    const cfg = loadAgentConfig(dirName, root);
    if (cfg) {
      configs[cfg.name || dirName] = cfg;
    }
  }

  // 2. Сканируем поддиректории root на случай появления новых агентов
  try {
    if (fs.existsSync(root)) {
      const entries = fs.readdirSync(root, { withFileTypes: true });
      for (const entry of entries) {
        if (
          entry.isDirectory() &&
          !KNOWN_AGENT_DIRS.includes(entry.name) &&
          entry.name !== 'node_modules' &&
          entry.name !== 'dist' &&
          entry.name !== 'state' &&
          entry.name !== 'orchestrator' &&
          entry.name !== 'shared' &&
          entry.name !== 'logs_watcher'
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
 * Формирует граф задач на основе загруженных конфигураций AgentConfig
 */
export function buildTaskGraphFromConfigs(configs: Record<string, AgentConfig>): Record<string, TaskState> {
  const tasks: Record<string, TaskState> = {};
  for (const [key, cfg] of Object.entries(configs)) {
    tasks[key] = {
      flow: cfg.flow,
      depends_on: cfg.depends_on ?? [],
      allow_parallel: cfg.allow_parallel ?? true,
      schedule: cfg.schedule ?? null,
      prompt: cfg.prompt ?? null,
      params: cfg.params ?? {},
      status: 'PENDING',
      attempts: 0,
      max_attempts: cfg.max_attempts ?? 3,
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
  addNewTasks: boolean = true
): void {
  for (const [name, cfg] of Object.entries(configs)) {
    const existing = existingTasks[name];
    if (existing) {
      existing.flow = cfg.flow;
      existing.allow_parallel = cfg.allow_parallel ?? true;
      existing.depends_on = cfg.depends_on ?? [];
      existing.schedule = cfg.schedule ?? null;
      existing.prompt = cfg.prompt ?? null;
      existing.max_attempts = cfg.max_attempts ?? 3;
      existing.params = { ...(cfg.params || {}), ...(existing.params || {}) };
    } else if (addNewTasks) {
      existingTasks[name] = {
        flow: cfg.flow,
        depends_on: cfg.depends_on ?? [],
        allow_parallel: cfg.allow_parallel ?? true,
        schedule: cfg.schedule ?? null,
        prompt: cfg.prompt ?? null,
        params: cfg.params ?? {},
        status: 'PENDING',
        attempts: 0,
        max_attempts: cfg.max_attempts ?? 3,
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
    return buildTaskGraphFromConfigs(configs);
  }

  // Резервный дефолтный граф (на случай отсутствия файлов config.json)
  return {
    saldoandmik: {
      flow: TASK_FLOW_SALDOANDMIK,
      depends_on: [],
      allow_parallel: true,
      schedule: null,
      prompt: null,
      params: { userId: 2477, rekvId: 63, kond: 1 },
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
      params: { userId: 2477, rekvId: 63 },
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
      params: { userId: 2477, rekvId: 63, is_agent: true },
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
      depends_on: ['getEarved'],
      allow_parallel: true,
      schedule: null,
      prompt: null,
      params: { userId: 2477, rekvId: 63 },
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
      params: { userId: 2477, rekvId: 63 },
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
      depends_on: ['saldoandmik', 'calc_arv_jaak', 'getEarved', 'sendFinBitReport', 'lisa1_lisa5'],
      allow_parallel: false,
      schedule: null,
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
 * Вычисляет время следующего запуска на следующий день в указанный час и минуту местного времени сервера
 */
export function calculateNextScheduledRun(baseDateStr: string, hour = 20, minute = 0): string {
  const parts = baseDateStr.split('-').map(Number);
  const year = parts[0] || new Date().getFullYear();
  const month = (parts[1] || 1) - 1;
  const day = parts[2] || 1;

  // Создаем дату в локальном часовом поясе сервера
  const nextDate = new Date(year, month, day + 1, hour, minute, 0, 0);
  return nextDate.toISOString();
}

/**
 * Создает начальное состояние оркестратора
 */
export function createInitialState(
  dateStr?: string,
  params: { userId?: number; rekvId?: number; kond?: number } = {},
  baseDir?: string
): OrchestratorState {
  const cycleDate = dateStr || new Date().toISOString().slice(0, 10);
  return OrchestratorStateSchema.parse({
    version: 1,
    cycle_date: cycleDate,
    status: 'IDLE',
    last_tick_at: null,
    next_scheduled_run: null,
    params: {
      userId: params.userId ?? 2477,
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

/**
 * Сбрасывает состояние задач для нового суточного расчетного цикла
 */
export function resetCycleForNewDay(
  state: OrchestratorState,
  newDateStr: string,
  baseDir?: string
): OrchestratorState {
  const tasks = getDefaultTaskGraph(baseDir);
  return OrchestratorStateSchema.parse({
    ...state,
    cycle_date: newDateStr,
    status: 'IN_PROGRESS',
    tasks,
    history: [
      ...state.history.slice(-50), // Храним последние 50 событий
      {
        timestamp: new Date().toISOString(),
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
    baseDir?: string
  ): Promise<OrchestratorState> {
    const rootDir = resolveAiTaskRootDir(baseDir);
    const configs = loadAllAgentConfigs(rootDir);

    const isProductionState = path.basename(this.resolvedPath) === 'orchestrator_state.json';

    if (fs.existsSync(this.resolvedPath)) {
      try {
        const rawContent = await fs.promises.readFile(this.resolvedPath, 'utf8');
        const parsed = JSON.parse(rawContent);
        const validated = OrchestratorStateSchema.parse(parsed);

        // Синхронизируем статические конфигурационные параметры задач из <agent>/config.json для рабочего файла состояния
        if (isProductionState && Object.keys(configs).length > 0) {
          reconcileTasksWithConfigs(validated.tasks, configs, isProductionState);
        }

        return validated;
      } catch (err: unknown) {
        console.warn(
          `[state.manager] Viga olekufaili lugemisel (${this.resolvedPath}), lähtestamine:`,
          err
        );
      }
    }

    const initialState = createInitialState(dateStr, defaultParams, rootDir);
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
