import { z } from 'zod';

/**
 * Общие типы данных и контракты для микросервиса ai_task
 */

export type TaskStatus = 'STARTED' | 'RUNNING' | 'COMPLETED' | 'FAILED' | 'TIMEOUT' | 'SKIPPED';

/**
 * Стандартная Zod-схема ответа при асинхронном запуске расчета бэкендом buh70
 */
export const AsyncTaskStartResponseSchema = z.object({
  status: z.number().describe('HTTP статус код ответа'),
  result: z.number().describe('Числовой результат операции'),
  log_id: z.number().describe('Идентификатор лог-записи в ou.logs'),
  data: z
    .object({
      action: z.string().optional().describe('Наименование запущенного действия'),
      status: z.string().optional().describe('Статус немедленного запуска'),
      log_id: z.number().optional().describe('Идентификатор лога'),
      result: z.unknown().optional(),
    })
    .optional(),
  error_message: z.string().nullable().optional().describe('Сообщение об ошибке (null при успехе)'),
});

export type AsyncTaskStartResponse = z.infer<typeof AsyncTaskStartResponseSchema>;

/**
 * Запись в массиве data ответа логов POST /task/read_log/:user_id/:task_name
 */
export interface ReadLogEntry {
  flow: string;
  status: 'success' | 'failed' | null;
  exec_start: string;
  exec_end: string | null;
  result?: unknown;
  response?: string | null;
  error?: string | null;
}

/**
 * Ответ эндпоинта POST /task/read_log/:user_id/:task_name
 */
export interface ReadLogResponse {
  result: number;
  error_code: number;
  error_message: string | null;
  data: ReadLogEntry[];
}

/**
 * Результат выполнения отдельного шага/субагента
 */
export interface ExecutionStepResult {
  stepName: string;
  status: 'SKIPPED' | 'SUCCESS' | 'FAILED' | 'TIMEOUT';
  logId?: number;
  startTime?: string;
  endTime?: string;
  error?: string;
  resultSummary?: string;
  details?: unknown;
}

/**
 * Сводка полного цикла оркестрации
 */
export interface ExecutionSummary {
  executionDate: string;
  userId: number;
  rekvId: number;
  steps: ExecutionStepResult[];
  overallSuccess: boolean;
  message: string;
}

/**
 * Конфигурация приложения
 */
export interface AppConfig {
  geminiApiKey: string;
  geminiModel: string;
  buh70ApiBaseUrl: string;
  buh70ApiToken: string;
  defaultUserId: number;
  defaultRekvId: number;
  defaultKond: number;
  taskPollIntervalMs: number;
  taskTimeoutMs: number;
  maxTaskAttempts: number;

  // Память состояния и расписание тиков
  stateFilePath?: string;
  dailyStartHour: number;

  // Настройки отправки почты (SMTP)
  smtpHost?: string;
  smtpPort?: number;
  smtpSecure?: boolean;
  smtpUser?: string;
  smtpPass?: string;
  reportEmailFrom?: string;
  reportEmailTo?: string;
}
