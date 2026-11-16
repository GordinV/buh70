import { z } from 'zod';
import { AsyncTaskStartResponseSchema } from '../shared/types';

import { AI_TASK_SERVICE_USER_ID } from '../shared/constants';
/**
 * Flow в ou.logs для разбора и сохранения счетов FinBit.
 * Имя потока сохранено прежним: docs.get_arve_kinnitaja (отчет sendFinBitReport) ищет лог импорта именно по нему
 */
export const TASK_FLOW_IMPORT_EARVED = 'docs.sp_loe_earved';

/**
 * Входные параметры для запуска разбора и сохранения счетов FinBit
 */
export const StartImportEarvedInputSchema = z.object({
  userId: z.number().optional().default(AI_TASK_SERVICE_USER_ID).describe('ID пользователя'),
  rekvId: z.number().optional().default(63).describe('ID учреждения'),
  logId: z
    .number()
    .int()
    .positive()
    .optional()
    .describe(
      'Идентификатор лога getEarved с выкачанными счетами. ' +
        'Если не указан, бэкенд берет последний лог getEarved за 24 часа'
    ),
});

/**
 * Схема ответа бэкенда при вызове POST /task/importEarved/
 */
export const StartImportEarvedResponseSchema = AsyncTaskStartResponseSchema;

/**
 * Счет, пропущенный при частичном импорте (контр-агента нет в libs.asutus)
 */
export const SkippedInvoiceSchema = z.object({
  number: z.string().default(''),
  asutusid: z.string().default(''),
  rekvId: z.number().nullable().optional(),
});

/**
 * Счет, успешно импортированный в docs.arv (result.imported лога импорта)
 */
export const ImportedInvoiceSchema = z.object({
  doc_id: z.number(),
  number: z.string().default(''),
  rekv_id: z.number().nullable().optional(),
});

/**
 * Счет, который не удалось импортировать (result.errors): ошибка одного счета не откатывает остальные
 */
export const ImportErrorSchema = z.object({
  number: z.string().default(''),
  asutusid: z.string().default(''),
  error: z.string().default(''),
});

/**
 * Агрегированный результат работы субагента разбора и сохранения счетов
 */
export const ImportEarvedResultSchema = z.object({
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
  totalFetched: z.number().default(0),
  totalImported: z.number().default(0),
  totalSkipped: z.number().default(0),
  /** Число счетов, импорт которых завершился ошибкой (см. errors) */
  totalFailed: z.number().default(0),
  /** Реально созданные документы (по ним работает рассылка sendFinBitReport) */
  imported: z.array(ImportedInvoiceSchema).default([]),
  /** Счета с ошибкой импорта */
  errors: z.array(ImportErrorSchema).default([]),
  /** Счета, пропущенные из-за отсутствия контр-агента в базе */
  skipped: z.array(SkippedInvoiceSchema).default([]),
  /** Рег.коды организаций, которых нет в libs.asutus */
  missing: z.array(z.string()).default([]),
  sourceLogId: z.number().nullable().optional(),
});

export type StartImportEarvedInput = z.input<typeof StartImportEarvedInputSchema>;
export type StartImportEarvedResponse = z.infer<typeof StartImportEarvedResponseSchema>;
export type ImportEarvedResult = z.infer<typeof ImportEarvedResultSchema>;
