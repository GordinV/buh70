import { z } from 'zod';
import { ReportStepDetailSchema } from '../reporter/schemas';

import { AI_TASK_SERVICE_USER_ID } from '../shared/constants';
/**
 * Статусы индивидуальной задачи
 */
export const TaskStatusEnum = z.enum(['PENDING', 'RUNNING', 'SUCCESS', 'FAILED', 'SKIPPED']);
export type TaskStatus = z.infer<typeof TaskStatusEnum>;

/**
 * Схема индивидуального расписания задачи (Time & Date Scheduler)
 */
export const TaskScheduleSchema = z
  .object({
    time: z
      .string()
      .regex(/^([01]\d|2[0-3]):([0-5]\d)$/)
      .nullable()
      .optional()
      .describe('Время суток в формате HH:mm (например, "06:30", "20:00")'),
    day: z.number().int().min(1).max(31).nullable().optional().describe('День месяца (1-31)'),
    month: z.number().int().min(1).max(12).nullable().optional().describe('Месяц года (1-12)'),
  })
  .nullable()
  .optional();

export type TaskSchedule = z.infer<typeof TaskScheduleSchema>;

/**
 * Схема индивидуальной декларативной конфигурации субагента (<agent>/config.json)
 */
export const AgentConfigSchema = z
  .object({
    name: z.string().describe('Уникальный идентификатор субагента'),
    flow: z.string().describe('Имя процедуры/потока в ou.logs'),
    description: z.string().optional().describe('Описание назначения субагента'),
    allow_parallel: z.boolean().default(true).describe('Признак параллельного запуска'),
    depends_on: z.array(z.string()).default([]).describe('Жёсткие зависимости (имена предшественников)'),
    soft_depends_on: z.array(z.string()).optional().describe('Мягкие зависимости: ждём завершения, но стартуем и при FAILED/SKIPPED'),
    schedule: TaskScheduleSchema.default(null).describe('Индивидуальное расписание запуска'),
    prompt: z.string().nullable().optional().default(null).describe('Инструкция для LLM при принятии решений'),
    max_attempts: z.number().default(3).describe('Максимальное число попыток запуска при сбое'),
    timeout_hours: z.number().positive().optional().describe('Порог таймаута выполнения задачи в часах (по умолчанию 12)'),
    max_wait_time: z
      .string()
      .regex(/^([01]\d|2[0-3]):([0-5]\d)$/)
      .optional()
      .describe('Предельное время (HH:mm), до которого задача ждет завершения зависимостей; после него стартует без них (reporter)'),
    params: z.record(z.unknown()).optional().default({}).describe('Параметры по умолчанию для вызова процедуры'),
  })
  .superRefine((val, ctx) => {
    const hard = new Set(val.depends_on || []);
    const dup = (val.soft_depends_on || []).find((d) => hard.has(d));
    if (dup) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['soft_depends_on'],
        message: `Зависимость "${dup}" не может одновременно находиться в depends_on и soft_depends_on`,
      });
    }
  });
export type AgentConfig = z.infer<typeof AgentConfigSchema>;

/**
 * Возвращает объединённый список жёстких и мягких зависимостей задачи для обхода графа.
 */
export function getAllDeps(task: { depends_on?: string[]; soft_depends_on?: string[] }): string[] {
  const hard = task.depends_on || [];
  const soft = task.soft_depends_on || [];
  if (soft.length === 0) return hard;
  return Array.from(new Set([...hard, ...soft]));
}

/**
 * Схема декларативной конфигурации самого агента-оркестратора (orchestrator/config.json)
 */
export const OrchestratorConfigSchema = z.object({
  name: z.string().default('orchestrator').describe('Уникальный идентификатор оркестратора'),
  description: z.string().optional().describe('Описание назначения оркестратора'),
  daily_start_time: z
    .string()
    .regex(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .default('20:00')
    .describe('Базовое суточное время старта по местному времени в формате HH:mm'),
  timezone: z.string().default('Europe/Tallinn').describe('Часовой пояс (например, "Europe/Tallinn")'),
  max_task_attempts: z.number().default(3).describe('Максимальное допустимое число попыток запуска задач при сбое'),
  params: z
    .object({
      userId: z.number().default(AI_TASK_SERVICE_USER_ID),
      rekvId: z.number().default(63),
      kond: z.number().default(1),
    })
    .passthrough()
    .default({ userId: AI_TASK_SERVICE_USER_ID, rekvId: 63, kond: 1 }),
  prompt: z
    .string()
    .nullable()
    .optional()
    .default(null)
    .describe('Мета-инструкция для LLM при принятии решений по суточному расчетному циклу'),
  schedule_monitor: z
    .object({
      enabled: z.boolean().default(true).describe('Признак включения мониторинга расписания на тиках'),
    })
    .optional()
    .describe('Настройки агента мониторинга расписания и статусов'),
});
export type OrchestratorConfig = z.infer<typeof OrchestratorConfigSchema>;

/**
 * Схема решения верхнего уровня по суточному циклу (Meta-Orchestrator Decision)
 */
export const CycleDecisionSchema = z.object({
  action: z
    .enum(['RUN_CYCLE', 'WAIT_SCHEDULE', 'SKIP_CYCLE', 'PAUSE_CYCLE'])
    .default('RUN_CYCLE')
    .describe('Предписанное действие для цикла'),
  force_run: z.boolean().default(false).describe('Принудительный запуск цикла вне стандартного окна времени'),
  reason: z.string().describe('Обоснование решения'),
  cycle_params_override: z.record(z.unknown()).optional().describe('Скорректированные параметры цикла'),
});
export type CycleDecision = z.infer<typeof CycleDecisionSchema>;

/**
 * Контекст, передаваемый для мета-принятия решений по циклу в LLM
 */
export interface CycleDecisionContext {
  currentServerTime: string;
  localTime: string;
  timezone: string;
  dailyStartTime: string;
  cycleDate: string;
  cycleStatus: CycleStatus;
  apiBaseUrl: string;
  tasksState: Record<string, { status: TaskStatus; attempts: number; error: string | null }>;
  isTestMode: boolean;
}

/**
 * Схема решения о запуске задачи (Structured Output от LLM или детерминированного анализа)
 */
export const AgentLaunchDecisionSchema = z.object({
  should_run: z.boolean().describe('Решение: запускать ли поток на текущем тике'),
  reason: z.string().describe('Подробное обоснование решения'),
  action: z.enum(['RUN', 'WAIT', 'SKIP']).default('RUN').describe('Предписанное действие'),
  dynamic_params: z.record(z.unknown()).optional().describe('Скорректированные параметры вызова'),
});
export type AgentLaunchDecision = z.infer<typeof AgentLaunchDecisionSchema>;

/**
 * Контекст, передаваемый для принятия решения (в LLM или детерминированный обработчик)
 */
export interface DecisionContext {
  currentServerTime: string;
  localTime?: string;
  localDate?: string;
  timezone?: string;
  isScheduleDue?: boolean;
  agentName: string;
  params: Record<string, unknown>;
  schedule: TaskSchedule | null | undefined;
  dependenciesState: Record<string, TaskStatus>;
  recentLogs?: unknown[];
  attempts: number;
  taskStatus?: TaskStatus;
  apiBaseUrl?: string;
}

/**
 * Схема решения об оценке результатов выполнения задачи (LLM Structured Output)
 */
export const TaskResultEvaluationSchema = z.object({
  is_success: z.boolean().describe('Является ли выполнение задачи успешным'),
  status: z.enum(['SUCCESS', 'FAILED']).describe('Итоговый статус выполнения задачи'),
  summary: z.string().describe('Краткое информативное резюме для отчета reporter'),
  error: z.string().nullable().optional().describe('Текст ошибки для отчета, если задача завершилась со сбоем'),
});
export type TaskResultEvaluation = z.infer<typeof TaskResultEvaluationSchema>;

/**
 * Контекст для семантической оценки результатов выполнения задачи в LLM
 */
export interface TaskResultContext {
  currentServerTime: string;
  agentName: string;
  flow: string;
  logStatus: string;
  logResult: unknown;
  logResponse: string | null | undefined;
  logError: string | null | undefined;
  hasErrors: boolean;
  errorDetails?: string;
  resultSummary?: string;
  attempts: number;
}

export const ResetReasonEnum = z.enum(['TASK_REARMED', 'TASK_RESET_MANUAL', 'CYCLE_RESET_NEW_DAY']);
export type ResetReason = z.infer<typeof ResetReasonEnum>;

/**
 * Снимок последнего завершённого запуска задачи (переживает сброс в PENDING для утреннего отчёта reporter)
 */
export const LastRunSchema = z.object({
  log_id: z.number().nullable().default(null),
  status: TaskStatusEnum,
  started_at: z.string().nullable().default(null),
  finished_at: z.string().nullable().default(null),
  duration_ms: z.number().nullable().default(null),
  error: z.string().nullable().default(null),
  result_summary: z.string().nullable().optional(),
  cycle_date: z.string(),
  reset_at: z.string(),
  reset_reason: ResetReasonEnum,
});
export type LastRun = z.infer<typeof LastRunSchema>;

/**
 * Схема состояния конкретной задачи в графе
 */
export const TaskStateSchema = z.object({
  flow: z.string().describe('Имя процедуры/потока в ou.logs'),
  depends_on: z.array(z.string()).default([]).describe('Жёсткие зависимости потока'),
  soft_depends_on: z.array(z.string()).optional().describe('Мягкие зависимости потока'),
  soft_deps_failed: z.array(z.string()).optional().describe('Мягкие зависимости, завершившиеся неуспешно к моменту старта'),
  allow_parallel: z.boolean().default(true).describe('Признак допустимости параллельного выполнения'),
  schedule: TaskScheduleSchema.default(null).describe('Индивидуальное расписание запуска задачи'),
  prompt: z.string().nullable().optional().default(null).describe('Инструкция для LLM при принятии решений'),
  params: z.record(z.unknown()).optional().default({}).describe('Параметры вызова задачи'),
  status: TaskStatusEnum.default('PENDING').describe('Текущий статус выполнения'),
  attempts: z.number().default(0).describe('Число выполненных попыток запуска'),
  max_attempts: z.number().default(3).describe('Максимальное допустимое число попыток запуска'),
  timeout_hours: z.number().positive().optional().describe('Порог таймаута выполнения задачи в часах (по умолчанию 12)'),
  max_wait_time: z.string().optional().describe('Предельное время (HH:mm) ожидания зависимостей (reporter)'),
  log_id: z.number().nullable().default(null).describe('ID записи в ou.logs'),
  started_at: z.string().nullable().default(null).describe('Время запуска задачи (ISO)'),
  finished_at: z.string().nullable().default(null).describe('Время окончания задачи (ISO)'),
  duration_ms: z.number().nullable().default(null).describe('Длительность в миллисекундах'),
  error: z.string().nullable().default(null).describe('Текст ошибки при сбое'),
  result_summary: z.string().nullable().optional().describe('Сводка результата выполнения'),
  last_run: LastRunSchema.nullable().optional().describe('Снимок последнего запуска для отчёта reporter после сброса'),
});
export type TaskState = z.infer<typeof TaskStateSchema>;

/**
 * Статусы общего суточного расчетного цикла
 */
export const CycleStatusEnum = z.enum(['IDLE', 'IN_PROGRESS', 'COMPLETED', 'FAILED']);
export type CycleStatus = z.infer<typeof CycleStatusEnum>;

/**
 * Событие в истории состояний
 */
export const HistoryEventSchema = z.object({
  timestamp: z.string().describe('Время события (ISO)'),
  event: z.string().describe('Тип события (например, TASK_STARTED, TASK_COMPLETED)'),
  task: z.string().optional().describe('Идентификатор задачи'),
  details: z.string().optional().describe('Дополнительные детали'),
});
export type HistoryEvent = z.infer<typeof HistoryEventSchema>;

/**
 * Полная схема файла дампа состояния (orchestrator_state.json)
 */
export const OrchestratorStateSchema = z.object({
  version: z.number().default(1),
  cycle_date: z.string().describe('Дата расчетного цикла (YYYY-MM-DD)'),
  status: CycleStatusEnum.default('IDLE'),
  last_tick_at: z.string().nullable().default(null),
  next_scheduled_run: z.string().nullable().default(null),
  params: z.object({
    userId: z.number().default(AI_TASK_SERVICE_USER_ID),
    rekvId: z.number().default(63),
    kond: z.number().default(1),
  }),
  tasks: z.record(TaskStateSchema),
  history: z.array(HistoryEventSchema).default([]),
});
export type OrchestratorState = z.infer<typeof OrchestratorStateSchema>;

/**
 * Входные параметры для тика оркестратора
 */
export const OrchestratorTickInputSchema = z.object({
  userId: z.number().optional(),
  rekvId: z.number().optional(),
  kond: z.number().optional().default(1),
  forceRun: z.boolean().optional().default(false),
  stateFilePath: z.string().optional(),
  recipientEmail: z.string().optional(),
  taskKey: z.string().optional().describe('Точечный сброс и немедленный запуск конкретной задачи (CLI флаг --task)'),
});
export type OrchestratorTickInput = z.input<typeof OrchestratorTickInputSchema>;

/**
 * Выходной результат одного тика
 */
export const OrchestratorTickOutputSchema = z.object({
  cycleDate: z.string(),
  cycleStatus: CycleStatusEnum,
  action: z.enum([
    'TICK_EXECUTED',
    'IDLE_WAIT_START_HOUR',
    'IDLE_WAIT_NEXT_SCHEDULE',
    'CYCLE_COMPLETED',
    'CYCLE_FAILED',
  ]),
  message: z.string(),
  activeTasks: z.array(z.string()),
  completedTasks: z.array(z.string()),
  pendingTasks: z.array(z.string()),
  failedTasks: z.array(z.string()),
  skippedTasks: z.array(z.string()),
  nextScheduledRun: z.string().nullable(),
});
export type OrchestratorTickOutput = z.infer<typeof OrchestratorTickOutputSchema>;

/**
 * Входные параметры для классического (полного) запуска оркестратора (backward compatibility)
 */
export const OrchestratorInputSchema = z.object({
  userId: z.number().optional().default(AI_TASK_SERVICE_USER_ID).describe('ID пользователя'),
  rekvId: z.number().optional().default(63).describe('ID учреждения'),
  kond: z.number().optional().default(1).describe('Признак сводного расчета'),
  forceRun: z
    .boolean()
    .optional()
    .default(false)
    .describe('Принудительный запуск без проверки истории за сегодня'),
  pollIntervalMs: z.number().optional().describe('Интервал опроса логов (мс)'),
  maxTimeoutMs: z.number().optional().describe('Максимальный таймаут (мс)'),
});

export const OrchestratorOutputSchema = z.object({
  executionDate: z.string(),
  userId: z.number(),
  rekvId: z.number(),
  steps: z.array(ReportStepDetailSchema),
  overallSuccess: z.boolean(),
  message: z.string(),
});

export type OrchestratorInput = z.input<typeof OrchestratorInputSchema>;
export type OrchestratorOutput = z.infer<typeof OrchestratorOutputSchema>;
