import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  StartLisa1Lisa5Input,
  StartLisa1Lisa5InputSchema,
  StartLisa1Lisa5Response,
  StartLisa1Lisa5ResponseSchema,
} from './schemas';

/**
 * Неблокирующий запуск фонового расчета контроля Lisa 1 / Lisa 5 в бэкенде buh70
 */
export async function startLisa1Lisa5(
  input: StartLisa1Lisa5Input = {},
  apiClient: ApiClient = defaultApiClient
): Promise<StartLisa1Lisa5Response> {
  const validated = StartLisa1Lisa5InputSchema.parse(input);

  const payload = {
    user_id: validated.userId,
    rekv_id: validated.rekvId,
  };

  const rawResponse = await apiClient.post<unknown>('/task/calcLisa1Lisa5/', payload);
  return StartLisa1Lisa5ResponseSchema.parse(rawResponse);
}
