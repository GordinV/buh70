import { z } from 'zod';
import { AsyncTaskStartResponseSchema } from '../shared/types';

export const TASK_FLOW_LISA1_LISA5 = 'eelarve.salvesta_lisa_1_5_kontrol';

export const StartLisa1Lisa5InputSchema = z.object({
  userId: z.number().optional().default(2477).describe('ID пользователя'),
  rekvId: z.number().optional().default(63).describe('ID головного учреждения'),
});

export const StartLisa1Lisa5ResponseSchema = AsyncTaskStartResponseSchema;

export const Lisa1Lisa5ResultSchema = z.object({
  flow: z.literal(TASK_FLOW_LISA1_LISA5),
  logId: z.number(),
  status: z.enum(['success', 'failed', 'timeout']),
  execStart: z.string().optional(),
  execEnd: z.string().optional(),
  durationMs: z.number().optional(),
  error: z.string().optional(),
});

export type StartLisa1Lisa5Input = z.input<typeof StartLisa1Lisa5InputSchema>;
export type StartLisa1Lisa5Response = z.infer<typeof StartLisa1Lisa5ResponseSchema>;
export type Lisa1Lisa5Result = z.infer<typeof Lisa1Lisa5ResultSchema>;
