import { z } from 'zod';

export const ReadLogEntrySchema = z
  .object({
    id: z.number().optional(),
    log_id: z.number().optional(),
    flow: z.string(),
    status: z.enum(['success', 'failed']).nullable(),
    exec_start: z.string().nullable().optional(),
    exec_end: z.string().nullable().optional(),
    result: z.unknown().optional(),
    response: z.string().nullable().optional(),
    error: z.string().nullable().optional(),
    /** Бэкенд помечает неповторяемые сбои (нет данных, нет прав): 'false' → повтор бессмыслен. Приходит как текст 'true'/'false' */
    retryable: z.union([z.boolean(), z.string()]).nullable().optional(),
    source_log_id: z.union([z.number(), z.string()]).nullable().optional(),
  })
  .passthrough();

/**
 * Приводит поле retryable из ou.logs (boolean | 'true' | 'false' | null) к boolean | undefined.
 * undefined = бэкенд не указал → поведение по умолчанию (повтор до max_attempts).
 */
export function parseRetryable(value: unknown): boolean | undefined {
  if (value === true || value === 'true') return true;
  if (value === false || value === 'false') return false;
  return undefined;
}

export const ReadLogResponseSchema = z.object({
  result: z.number(),
  error_code: z.number().default(0),
  error_message: z.string().nullable().optional(),
  data: z.array(ReadLogEntrySchema).default([]),
});

export const ReadTaskLogInputSchema = z.object({
  userId: z.number().describe('ID пользователя для запроса логов'),
  taskName: z.string().describe('Имя потока (например, eelarve.sp_koosta_saldoandmik)'),
  logId: z.number().optional().describe('ID конкретной записи ou.logs (окно по времени игнорируется)'),
  limit: z.number().optional().describe('Сколько последних записей вернуть (по умолчанию 1)'),
  hours: z.number().optional().describe('Окно поиска по exec_start в часах (по умолчанию 48)'),
});

export const WatchTaskInputSchema = z.object({
  userId: z.number().describe('ID пользователя'),
  taskName: z.string().describe('Имя фонового потока'),
  logId: z.number().optional().describe('ID записи ou.logs запущенной задачи (если не указан - последняя запись flow)'),
  pollIntervalMs: z.number().optional().default(60000).describe('Интервал опроса в мс'),
  maxTimeoutMs: z.number().optional().default(14400000).describe('Максимальное время ожидания в мс'),
});

export const WatchTaskOutputSchema = z.object({
  taskName: z.string(),
  status: z.enum(['success', 'failed', 'timeout']),
  execStart: z.string().optional(),
  execEnd: z.string().optional(),
  durationMs: z.number().optional(),
  error: z.string().optional(),
  result: z.unknown().optional(),
  response: z.string().nullable().optional(),
  hasErrors: z.boolean().optional(),
  errorDetails: z.string().optional(),
  resultSummary: z.string().optional(),
  retryable: z.boolean().optional(),
});

export type ReadTaskLogInput = z.input<typeof ReadTaskLogInputSchema>;
export type ReadLogResponse = z.infer<typeof ReadLogResponseSchema>;
export type WatchTaskInput = z.input<typeof WatchTaskInputSchema>;
export type WatchTaskOutput = z.infer<typeof WatchTaskOutputSchema>;
