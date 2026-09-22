import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  StartSaldoandmikInput,
  StartSaldoandmikInputSchema,
  StartSaldoandmikResponse,
  StartSaldoandmikResponseSchema,
} from './schemas';

/**
 * Неблокирующий запуск фонового расчета сальдоандмика в бэкенде buh70
 */
export async function startSaldoandmik(
  input: StartSaldoandmikInput = {},
  apiClient: ApiClient = defaultApiClient
): Promise<StartSaldoandmikResponse> {
  const validated = StartSaldoandmikInputSchema.parse(input);

  const payload = {
    user_id: validated.userId,
    rekv_id: validated.rekvId,
    kond: validated.kond,
  };

  const rawResponse = await apiClient.post<unknown>('/task/calcKondSaldoandmik/', payload);
  return StartSaldoandmikResponseSchema.parse(rawResponse);
}
