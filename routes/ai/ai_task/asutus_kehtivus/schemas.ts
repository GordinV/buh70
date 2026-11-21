import { z } from 'zod';
import { AI_TASK_SERVICE_USER_ID } from '../shared/constants';

export const TASK_FLOW_CHECK_ASUTUS_KEHTIVUS = 'checkAsutusKehtivus';

export const StartAsutusKehtivusInputSchema = z.object({
  userId: z.number().int().positive().default(AI_TASK_SERVICE_USER_ID),
  rekvId: z.number().int().positive().default(63),
  dryRun: z.boolean().default(false),
  maxClose: z.number().int().nonnegative().default(100),
  extraEmails: z.array(z.string()).optional(),
  hash: z.string().optional(),
});

export type StartAsutusKehtivusInput = z.input<typeof StartAsutusKehtivusInputSchema>;

export const StartAsutusKehtivusResponseSchema = z.object({
  status: z.number().optional(),
  result: z.number().optional(),
  log_id: z.number().nullable().optional(),
  data: z.record(z.string(), z.unknown()).nullable().optional(),
  error_message: z.string().nullable().optional(),
});

export type StartAsutusKehtivusResponse = z.infer<typeof StartAsutusKehtivusResponseSchema>;

export interface StartAsutusKehtivusOutcome {
  ok: boolean;
  alreadyRunning: boolean;
  log_id: number | null;
  status?: number;
}

export const AsutusKehtivusResultSchema = z.object({
  flow: z.literal(TASK_FLOW_CHECK_ASUTUS_KEHTIVUS),
  logId: z.number().nullable(),
  status: z.enum(['success', 'failed', 'timeout', 'pending', 'skipped']),
  alreadyRunning: z.boolean().default(false),
  reason: z.string().nullable().default(null),
  dryRun: z.boolean().default(true),
  candidatesTotal: z.number().default(0),
  totalClosed: z.number().default(0),
  totalErrors: z.number().default(0),
  execStart: z.string().optional(),
  execEnd: z.string().optional(),
  durationMs: z.number().optional(),
  error: z.string().optional(),
  hasErrors: z.boolean().optional(),
  errorDetails: z.string().optional(),
  resultSummary: z.string().optional(),
});

export type AsutusKehtivusResult = z.infer<typeof AsutusKehtivusResultSchema>;
