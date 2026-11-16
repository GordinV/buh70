import { z } from 'zod';
import { AsyncTaskStartResponseSchema } from '../shared/types';

import { AI_TASK_SERVICE_USER_ID } from '../shared/constants';
/**
 * Flow в ou.logs для получения данных отсутствующих организаций из Inforegister (/task/getInforegister/)
 */
export const TASK_FLOW_INFOREGISTER = 'getInforegister';

/**
 * Входные параметры запуска
 */
export const StartInforegisterInputSchema = z.object({
  userId: z.number().optional().default(AI_TASK_SERVICE_USER_ID).describe('ID пользователя (должен принадлежать учреждению rekvId)'),
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
  hash: z
    .string()
    .min(1)
    .optional()
    .describe('Токен авторизации Inforegister (INFOREGISTER_HASH); не логируется'),
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

/**
 * Входные параметры синхронного поиска организации по рег.коду (/task/inforegisterLookup/)
 */
export const InforegisterLookupInputSchema = z.object({
  regkood: z
    .string()
    .trim()
    .regex(/^\d{8}$/, 'Reg.kood peab olema 8-kohaline'),
  hash: z
    .string()
    .min(1)
    .optional()
    .describe('Токен авторизации Inforegister (INFOREGISTER_HASH); не логируется'),
  year: z.number().int().positive().optional(),
  cacheOnly: z.boolean().optional().default(false),
  forceRefresh: z.boolean().optional().default(false),
  insecureTls: z.boolean().optional().default(false),
});

/** Схема входа для Genkit flow (без hash, чтобы секрет не попадал в трассировку и UI) */
export const InforegisterLookupFlowInputSchema = InforegisterLookupInputSchema.omit({ hash: true });

export const InforegisterCompanySchema = z.object({
  name: z.string().nullable().optional(),
  regCode: z.string().nullable().optional(),
  registryStatus: z.string().nullable().optional(),
  businessType: z.string().nullable().optional(),
  vatNumber: z.string().nullable().optional(),
  address: z
    .object({
      fullAddress: z.string().nullable().optional(),
      city: z.string().nullable().optional(),
      street: z.string().nullable().optional(),
    })
    .nullable()
    .optional(),
  contacts: z
    .object({
      emails: z.array(z.string()).default([]),
      phones: z.array(z.string()).default([]),
    })
    .nullable()
    .optional(),
  latestEmployeeCount: z.number().nullable().optional(),
  latestPeriod: z.string().nullable().optional(),
  year: z.number().optional(),
});

export const InforegisterLocalAsutusSchema = z
  .object({
    id: z.number().optional(),
    regkood: z.string().nullable().optional(),
    nimetus: z.string().nullable().optional(),
    aadress: z.string().nullable().optional(),
    kmkr: z.string().nullable().optional(),
    email: z.string().nullable().optional(),
    tel: z.string().nullable().optional(),
    staatus: z.number().optional(),
  })
  .nullable();

export const InforegisterDiffItemSchema = z.object({
  field: z.string(),
  local: z.unknown().nullable().optional(),
  registry: z.unknown().nullable().optional(),
});

export const InforegisterLookupDataSchema = z.object({
  regkood: z.string().optional(),
  asutus_id: z.number().nullable().optional(),
  source: z.string().nullable().optional(),
  fetched_at: z.string().nullable().optional(),
  closed: z.boolean().optional(),
  local: InforegisterLocalAsutusSchema.optional(),
  registry: InforegisterCompanySchema.nullable().optional(),
  company: InforegisterCompanySchema.nullable().optional(),
  diff: z.array(InforegisterDiffItemSchema).optional(),
  calls_spent: z.number().optional(),
  remaining_year: z.number().nullable().optional(),
  reason: z.string().optional(),
});

export const InforegisterLookupResultSchema = z.object({
  ok: z.boolean(),
  status: z.number(),
  data: InforegisterLookupDataSchema.nullable().optional(),
  reason: z.string().optional(),
  message: z.string().nullable().optional(),
});

export type InforegisterLookupInput = z.input<typeof InforegisterLookupInputSchema>;
export type InforegisterLookupResult = z.infer<typeof InforegisterLookupResultSchema>;
