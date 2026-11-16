import type { AgentManifest } from '../shared/agent_registry';
import { GenerateReportInput, GenerateReportInputSchema, SendReportResponse } from './schemas';
import { sendReportEmail, SendEmailOptions } from './tools';

export async function generateAndSendReportSubagent(
  input: GenerateReportInput,
  options: SendEmailOptions = {}
): Promise<SendReportResponse> {
  const validated = GenerateReportInputSchema.parse(input);
  return sendReportEmail(validated, options);
}

/**
 * Манифест для реестра агентов; оркестратор вызывает generateAndSendReportSubagent напрямую.
 */
export const manifest: AgentManifest = {
  dispatch: async () => null,
};
