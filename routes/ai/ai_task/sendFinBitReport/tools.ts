import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  StartSendFinBitReportInput,
  StartSendFinBitReportInputSchema,
  StartSendFinBitReportResponse,
  StartSendFinBitReportResponseSchema,
} from './schemas';

/**
 * Неблокирующий запуск фоновой отправки отчета по импортированным счетам FinBit в бэкенде buh70
 */
export async function startSendFinBitReport(
  input: StartSendFinBitReportInput,
  apiClient: ApiClient = defaultApiClient
): Promise<StartSendFinBitReportResponse> {
  const validated = StartSendFinBitReportInputSchema.parse(input);

  const payload: Record<string, unknown> = {
    user_id: validated.userId,
    rekv_id: validated.rekvId,
    logId: validated.logId,
  };

  const rawResponse = await apiClient.post<unknown>('/task/sendFinBitReport/', payload);
  return StartSendFinBitReportResponseSchema.parse(rawResponse);
}
