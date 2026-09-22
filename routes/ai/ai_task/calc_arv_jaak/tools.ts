import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  StartCalcArvJaakInput,
  StartCalcArvJaakInputSchema,
  StartCalcArvJaakResponse,
  StartCalcArvJaakResponseSchema,
} from './schemas';

/**
 * Неблокирующий запуск фонового пересчета остатков счетов в бэкенде buh70
 */
export async function startCalcArvJaak(
  input: StartCalcArvJaakInput = {},
  apiClient: ApiClient = defaultApiClient
): Promise<StartCalcArvJaakResponse> {
  const validated = StartCalcArvJaakInputSchema.parse(input);

  const payload = {
    user_id: validated.userId,
    rekv_id: validated.rekvId,
  };

  const rawResponse = await apiClient.post<unknown>('/task/calcArvJaak/', payload);
  return StartCalcArvJaakResponseSchema.parse(rawResponse);
}
