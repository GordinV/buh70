import { z } from 'zod';

export const ReportStepDetailSchema = z.object({
  stepName: z.string(),
  status: z.enum(['SKIPPED', 'SUCCESS', 'FAILED', 'TIMEOUT']),
  logId: z.number().optional(),
  execStart: z.string().optional(),
  execEnd: z.string().optional(),
  durationMs: z.number().optional(),
  error: z.string().optional(),
  resultSummary: z.string().optional(),
});

export const GenerateReportInputSchema = z.object({
  userId: z.number().default(2477),
  rekvId: z.number().default(63),
  executionDate: z.string(),
  steps: z.array(ReportStepDetailSchema),
  overallSuccess: z.boolean(),
  notes: z.string().optional(),
  recipientEmail: z.string().email().optional(),
});

export const SendReportResponseSchema = z.object({
  sent: z.boolean(),
  deliveryChannel: z.string().default('email'),
  timestamp: z.string(),
  formattedReport: z.string().optional(),
  recipientEmail: z.string().optional(),
  messageId: z.string().optional(),
});

export type ReportStepDetail = z.infer<typeof ReportStepDetailSchema>;
export type GenerateReportInput = z.infer<typeof GenerateReportInputSchema>;
export type SendReportResponse = z.infer<typeof SendReportResponseSchema>;
