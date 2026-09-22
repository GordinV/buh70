import { z } from 'zod';
import { AsyncTaskStartResponseSchema } from '../shared/types';

export const TASK_FLOW_CALC_ARV_JAAK = 'docs.check_arv_jaak';

/**
 * Входные параметры для запуска пересчета остатков счетов
 */
export const StartCalcArvJaakInputSchema = z.object({
  userId: z.number().optional().default(2477).describe('ID пользователя'),
  rekvId: z.number().optional().default(63).describe('ID учреждения'),
});

/**
 * Схема ответа бэкенда при вызове POST /task/calcArvJaak/
 */
export const StartCalcArvJaakResponseSchema = AsyncTaskStartResponseSchema;

/**
 * Агрегированный результат работы субагента пересчета остатков счетов
 */
export const CalcArvJaakResultSchema = z.object({
  flow: z.string(),
  logId: z.number(),
  status: z.enum(['success', 'failed', 'timeout']),
  execStart: z.string().optional(),
  execEnd: z.string().optional(),
  durationMs: z.number().optional(),
  error: z.string().optional(),
});

export type StartCalcArvJaakInput = z.input<typeof StartCalcArvJaakInputSchema>;
export type StartCalcArvJaakResponse = z.infer<typeof StartCalcArvJaakResponseSchema>;
export type CalcArvJaakResult = z.infer<typeof CalcArvJaakResultSchema>;
