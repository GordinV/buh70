import { GenerateReportInput, GenerateReportInputSchema, SendReportResponse } from './schemas';
import { sendReportEmail, SendEmailOptions } from './tools';

export async function generateAndSendReportSubagent(
  input: GenerateReportInput,
  options: SendEmailOptions = {}
): Promise<SendReportResponse> {
  const validated = GenerateReportInputSchema.parse(input);
  return sendReportEmail(validated, options);
}
