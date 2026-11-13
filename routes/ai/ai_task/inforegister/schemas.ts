import { z } from 'zod';
import { AsyncTaskStartResponseSchema } from '../shared/types';

/**
 * Flow в ou.logs для получения данных отсутствующих организаций из Inforegister (/task/getInforegister/)
 */
export const TASK_FLOW_INFOREGISTER = 'getInforegister';

/**
 * Входные параметры запуска
 */
export const StartInforegisterInputSchema = z.object({
  userId: z.number().optional().default(2477).describe('ID пользователя (должен принадлежать учреждению rekvId)'),
  rekvId: z.number().optional().default(63).describe('ID учреждения'),
  logId: z
    .number()
    .int()
    .positive()
    .optional()
    .describe('ID лога check_asutus (checkAsutusAvailability). Если не указан, бэкенд берет последний за 24 часа'),
  dryRun: z
    .boolean()
    .optional()
    .default(true)
    .describe('true: данные запрашиваются, но организации в libs.asutus не создаются'),
  maxCalls: z.number().int().nonnegative().optional().describe('Потолок платных вызовов Inforegister за запуск'),
  insecureTls: z
    .boolean()
    .optional()
    .describe('true: не проверять TLS-сертификат api.ir.ee (сеть с подменой сертификата). Небезопасно, по умолчанию выключено'),
});

export const StartInforegisterResponseSchema = AsyncTaskStartResponseSchema;

/**
 * Результат обработки одной организации
 */
export const InforegisterItemSchema = z.object({
  regkood: z.string(),
  status: z.string(),
  nimetus: z.string().nullable().optional(),
  asutus_id: z.number().nullable().optional(),
  source: z.string().nullable().optional(),
  error: z.string().nullable().optional(),
});

/**
 * Агрегированный результат субагента
 */
export const InforegisterResultSchema = z.object({
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
  dryRun: z.boolean().default(true),
  total: z.number().default(0),
  created: z.number().default(0),
  wouldCreate: z.number().default(0),
  needsAttention: z.number().default(0),
  callsSpent: z.number().default(0),
  remainingYear: z.number().nullable().optional(),
  items: z.array(InforegisterItemSchema).default([]),
});

export type StartInforegisterInput = z.input<typeof StartInforegisterInputSchema>;
export type StartInforegisterResponse = z.infer<typeof StartInforegisterResponseSchema>;
export type InforegisterItem = z.infer<typeof InforegisterItemSchema>;
export type InforegisterResult = z.infer<typeof InforegisterResultSchema>;
