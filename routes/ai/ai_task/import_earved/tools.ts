import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  StartImportEarvedInput,
  StartImportEarvedInputSchema,
  StartImportEarvedResponse,
  StartImportEarvedResponseSchema,
} from './schemas';

/**
 * Неблокирующий запуск разбора и сохранения счетов FinBit (частичный импорт) в бэкенде buh70
 */
export async function startImportEarved(
  input: StartImportEarvedInput = {},
  apiClient: ApiClient = defaultApiClient
): Promise<StartImportEarvedResponse> {
  const validated = StartImportEarvedInputSchema.parse(input);

  const payload: Record<string, unknown> = {
    user_id: validated.userId,
    rekv_id: validated.rekvId,
  };
  if (validated.logId) {
    payload.log_id = validated.logId;
  }

  const rawResponse = await apiClient.post<unknown>('/task/importEarved/', payload);
  return StartImportEarvedResponseSchema.parse(rawResponse);
}
