import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  StartGetEarvedInput,
  StartGetEarvedInputSchema,
  StartGetEarvedResponse,
  StartGetEarvedResponseSchema,
} from './schemas';

/**
 * Неблокирующий запуск фонового импорта счетов из FinBit в бэкенде buh70 в режиме агентского вызова
 */
export async function startGetEarved(
  input: StartGetEarvedInput = {},
  apiClient: ApiClient = defaultApiClient
): Promise<StartGetEarvedResponse> {
  const validated = StartGetEarvedInputSchema.parse(input);

  const payload: Record<string, unknown> = {
    user_id: validated.userId,
    rekv_id: validated.rekvId,
    date_query_from: validated.dateQueryFrom,
    is_agent: true,
  };

  const rawResponse = await apiClient.post<unknown>('/task/getEarved/', payload);

  if (
    rawResponse &&
    typeof rawResponse === 'object' &&
    'error_message' in rawResponse &&
    (rawResponse as { error_message?: string }).error_message === 'Arveid ei leitud'
  ) {
    return {
      status: 200,
      result: 1,
      log_id: 0,
      data: {
        action: 'Import FinBit arved',
        status: 'COMPLETED',
        log_id: 0,
        result: { count: 0, message: 'Arveid ei leitud' },
      },
      error_message: null,
    };
  }

  return StartGetEarvedResponseSchema.parse(rawResponse);
}
