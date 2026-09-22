import { z } from 'zod';
import { AsyncTaskStartResponseSchema } from '../shared/types';

export const TASK_FLOW_SEND_FIN_BIT_REPORT = 'sendFinBitReport';

/**
 * Входные параметры для запуска отправки отчетов по импортированным счетам FinBit
 */
export const StartSendFinBitReportInputSchema = z.object({
  userId: z.number().optional().default(2477).describe('ID пользователя'),
  rekvId: z.number().optional().default(63).describe('ID учреждения'),
  logId: z
    .number()
    .int()
    .positive()
    .describe('Идентификатор лог-записи родительского импорта getEarved (обязателен для docs.get_arve_kinnitaja)'),
});

/**
 * Схема ответа бэкенда при вызове POST /task/sendFinBitReport/
 */
export const StartSendFinBitReportResponseSchema = AsyncTaskStartResponseSchema;

/**
 * Агрегированный результат работы субагента отправки отчетов FinBit
 */
export const SendFinBitReportResultSchema = z.object({
  flow: z.string(),
  logId: z.number(),
  status: z.enum(['success', 'failed', 'timeout']),
  execStart: z.string().optional(),
  execEnd: z.string().optional(),
  durationMs: z.number().optional(),
  error: z.string().optional(),
  hasErrors: z.boolean().optional(),
  errorDetails: z.string().optional(),
  resultSummary: z.string().optional(),
});

export type StartSendFinBitReportInput = z.input<typeof StartSendFinBitReportInputSchema>;
export type StartSendFinBitReportResponse = z.infer<typeof StartSendFinBitReportResponseSchema>;
export type SendFinBitReportResult = z.infer<typeof SendFinBitReportResultSchema>;
