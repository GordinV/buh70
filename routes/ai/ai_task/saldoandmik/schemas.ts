import { z } from 'zod';
import { AsyncTaskStartResponseSchema } from '../shared/types';

export const TASK_FLOW_SALDOANDMIK = 'eelarve.sp_koosta_saldoandmik';

export const StartSaldoandmikInputSchema = z.object({
  userId: z.number().optional().default(2477).describe('ID пользователя'),
  rekvId: z.number().optional().default(63).describe('ID учреждения'),
  kond: z.number().optional().default(1).describe('Признак сводного расчета (1 - да)'),
});

export const StartSaldoandmikResponseSchema = AsyncTaskStartResponseSchema;

export const SaldoandmikResultSchema = z.object({
  flow: z.literal(TASK_FLOW_SALDOANDMIK),
  logId: z.number(),
  status: z.enum(['success', 'failed', 'timeout']),
  execStart: z.string().optional(),
  execEnd: z.string().optional(),
  durationMs: z.number().optional(),
  error: z.string().optional(),
});

export type StartSaldoandmikInput = z.input<typeof StartSaldoandmikInputSchema>;
export type StartSaldoandmikResponse = z.infer<typeof StartSaldoandmikResponseSchema>;
export type SaldoandmikResult = z.infer<typeof SaldoandmikResultSchema>;
