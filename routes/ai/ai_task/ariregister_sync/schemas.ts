import { z } from 'zod';
import { AI_TASK_SERVICE_USER_ID } from '../shared/constants';

export const TASK_FLOW_ARIREGISTER_SYNC = 'ariregisterSync';

export const StartAriregisterSyncInputSchema = z.object({
  userId: z.number().int().positive().default(AI_TASK_SERVICE_USER_ID),
  rekvId: z.number().int().positive().default(63),
  dryRun: z.boolean().default(false),
  hash: z.string().optional(),
});

export type StartAriregisterSyncInput = z.input<typeof StartAriregisterSyncInputSchema>;

export const StartAriregisterSyncResponseSchema = z.object({
  status: z.number().optional(),
  result: z.number().optional(),
  log_id: z.number().nullable().optional(),
  data: z.record(z.string(), z.unknown()).nullable().optional(),
  error_message: z.string().nullable().optional(),
});

export type StartAriregisterSyncResponse = z.infer<typeof StartAriregisterSyncResponseSchema>;

export interface StartAriregisterSyncOutcome {
  ok: boolean;
  alreadyRunning: boolean;
  log_id: number | null;
  status?: number;
}

export const AriregisterSyncResultSchema = z.object({
  flow: z.literal(TASK_FLOW_ARIREGISTER_SYNC),
  logId: z.number().nullable(),
  status: z.enum(['success', 'failed', 'timeout', 'pending']),
  alreadyRunning: z.boolean().default(false),
  fileDate: z.string().nullable(),
  rowsRead: z.number(),
  skipped: z.number(),
  inserted: z.number(),
  updated: z.number(),
  deleted: z.number(),
  total: z.number(),
  execStart: z.string().optional(),
  execEnd: z.string().optional(),
  durationMs: z.number().optional(),
  error: z.string().optional(),
  hasErrors: z.boolean().optional(),
  errorDetails: z.string().optional(),
  resultSummary: z.string().optional(),
});

export type AriregisterSyncResult = z.infer<typeof AriregisterSyncResultSchema>;
