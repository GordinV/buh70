import { z } from 'zod';
import { AsyncTaskStartResponseSchema } from '../shared/types';
import { TaskStatusEnum, OrchestratorStateSchema } from '../orchestrator/orchestrator.schemas';

export const TASK_FLOW_AGENT_SCHEDULE = 'ai_task.agent_schedule';

/**
 * Причина планирования ближайшего запуска
 */
export const NextRunReasonEnum = z.enum([
  'SCHEDULE_TODAY',
  'SCHEDULE_TOMORROW',
  'AFTER_DEPENDENCIES',
  'RETRY',
  'RUNNING_NOW',
  'NONE',
]);
export type NextRunReason = z.infer<typeof NextRunReasonEnum>;

/**
 * Запись информации об агенте в срезе расписания
 */
export const AgentScheduleEntrySchema = z.object({
  agent: z.string().describe('Ключ задачи в state.tasks'),
  flow: z.string().describe('Имя flow в ou.logs'),
  status: TaskStatusEnum.describe('Текущий статус задачи'),
  schedule: z
    .object({
      time: z.string().nullable().optional(),
      day: z.number().int().nullable().optional(),
      month: z.number().int().nullable().optional(),
    })
    .nullable()
    .describe('Индивидуальное расписание задачи'),
  depends_on: z.array(z.string()).describe('Список задач, от которых зависит поток'),
  next_planned_run: z.string().nullable().describe('ISO-дата/время планируемого старта в TZ оркестратора'),
  next_run_reason: NextRunReasonEnum.describe('Причина вычисления времени следующего запуска'),
  last_started_at: z.string().nullable().describe('Время последнего старта задачи'),
  last_finished_at: z.string().nullable().describe('Время последнего завершения задачи'),
  timeout_deadline: z.string().nullable().describe('Дедлайн таймаута для RUNNING задач'),
  attempts: z.number().describe('Число попыток'),
  max_attempts: z.number().describe('Максимальное число попыток'),
  log_id: z.number().nullable().describe('ID последней записи в ou.logs'),
  error: z.string().nullable().describe('Текст ошибки (усечённый)'),
});
export type AgentScheduleEntry = z.infer<typeof AgentScheduleEntrySchema>;

/**
 * Полный срез расписания и статусов агентов
 */
export const ScheduleSnapshotSchema = z.object({
  tick_at: z.string().describe('Время формирования среза (ISO)'),
  timezone: z.string().describe('Часовой пояс оркестратора'),
  cycle_date: z.string().describe('Дата текущего цикла YYYY-MM-DD'),
  cycle_status: z.string().describe('Текущий статус расчетного цикла'),
  next_scheduled_run: z.string().nullable().describe('Время следующего запуска цикла'),
  summary: z.object({
    pending: z.number(),
    running: z.number(),
    success: z.number(),
    failed: z.number(),
    skipped: z.number(),
  }).describe('Агрегированные счетчики статусов'),
  agents: z.array(AgentScheduleEntrySchema).describe('Список записей расписания по агентам'),
});
export type ScheduleSnapshot = z.infer<typeof ScheduleSnapshotSchema>;

/**
 * Входные параметры для записи среза в логи
 */
export const LogAgentScheduleInputSchema = z.object({
  userId: z.number().default(2477).describe('ID пользователя'),
  rekvId: z.number().default(63).describe('ID учреждения'),
  snapshot: ScheduleSnapshotSchema.describe('Снимок расписания и статусов субагентов'),
});
export type LogAgentScheduleInput = z.infer<typeof LogAgentScheduleInputSchema>;

/**
 * Ответ бэкенда на вызов POST /task/logAgentSchedule/
 */
export const LogAgentScheduleResponseSchema = AsyncTaskStartResponseSchema;
export type LogAgentScheduleResponse = z.infer<typeof LogAgentScheduleResponseSchema>;

/**
 * Входные параметры вызова субагента schedule_monitor через Genkit / CLI
 */
export const ScheduleMonitorInputSchema = z.object({
  userId: z.number().optional().default(2477).describe('ID пользователя'),
  rekvId: z.number().optional().default(63).describe('ID учреждения'),
  stateFilePath: z.string().optional().describe('Путь к файлу orchestrator_state.json'),
  state: OrchestratorStateSchema.optional().describe('Готовое состояние оркестратора (если вызывается из тика)'),
});
export type ScheduleMonitorInput = z.input<typeof ScheduleMonitorInputSchema>;

/**
 * Результат выполнения субагента schedule_monitor
 */
export const ScheduleMonitorResultSchema = z.object({
  flow: z.string().describe('Имя flow в ou.logs'),
  status: z.enum(['success', 'failed']).describe('Статус операции'),
  logId: z.number().nullable().describe('ID записи в ou.logs'),
  snapshot: ScheduleSnapshotSchema.describe('Сохраненный снимок расписания'),
  error: z.string().nullable().optional().describe('Ошибка выполнения (если есть)'),
});
export type ScheduleMonitorResult = z.infer<typeof ScheduleMonitorResultSchema>;
