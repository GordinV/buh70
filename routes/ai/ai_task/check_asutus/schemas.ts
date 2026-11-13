import { z } from 'zod';
import { AsyncTaskStartResponseSchema } from '../shared/types';

/**
 * Flow в ou.logs для проверки наличия контр-агентов из счетов FinBit (libs.check_asutus_availibility)
 */
export const TASK_FLOW_CHECK_ASUTUS = 'checkAsutusAvailability';

/**
 * Входные параметры для запуска проверки наличия контр-агентов
 */
export const StartCheckAsutusInputSchema = z.object({
  userId: z.number().optional().default(2477).describe('ID пользователя'),
  rekvId: z.number().optional().default(63).describe('ID учреждения'),
  extraEmails: z
    .array(z.string())
    .optional()
    .describe('Дополнительные адреса для извещения о недостающих организациях (к адресу из ou.logs.changes)'),
  logId: z
    .number()
    .int()
    .positive()
    .optional()
    .describe(
      'Идентификатор лога родительского импорта getEarved (основной лог docs.sp_loe_earved или лог getEarved). ' +
        'Если не указан, бэкенд берет последний лог getEarved за 24 часа'
    ),
});

/**
 * Схема ответа бэкенда при вызове POST /task/checkAsutusAvailability/
 */
export const StartCheckAsutusResponseSchema = AsyncTaskStartResponseSchema;

/**
 * Агрегированный результат работы субагента проверки контр-агентов
 */
export const CheckAsutusResultSchema = z.object({
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
  /** Рег.коды организаций, которых нет в libs.asutus и которые нужно добавить */
  missing: z.array(z.string()).default([]),
  totalMissing: z.number().default(0),
  sourceLogId: z.number().nullable().optional(),
});

export type StartCheckAsutusInput = z.input<typeof StartCheckAsutusInputSchema>;
export type StartCheckAsutusResponse = z.infer<typeof StartCheckAsutusResponseSchema>;
export type CheckAsutusResult = z.infer<typeof CheckAsutusResultSchema>;
