import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  StartCheckAsutusInput,
  StartCheckAsutusInputSchema,
  StartCheckAsutusResponse,
  StartCheckAsutusResponseSchema,
} from './schemas';

/**
 * Неблокирующий запуск проверки наличия контр-агентов (из счетов FinBit) в бэкенде buh70
 */
export async function startCheckAsutus(
  input: StartCheckAsutusInput = {},
  apiClient: ApiClient = defaultApiClient
): Promise<StartCheckAsutusResponse> {
  const validated = StartCheckAsutusInputSchema.parse(input);

  const payload: Record<string, unknown> = {
    user_id: validated.userId,
    rekv_id: validated.rekvId,
  };
  if (validated.extraEmails && validated.extraEmails.length > 0) {
    payload.extra_emails = validated.extraEmails;
  }
  if (validated.logId) {
    payload.log_id = validated.logId;
  }

  const rawResponse = await apiClient.post<unknown>('/task/checkAsutusAvailability/', payload);
  return StartCheckAsutusResponseSchema.parse(rawResponse);
}
