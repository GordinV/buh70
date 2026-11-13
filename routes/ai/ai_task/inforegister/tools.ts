import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  StartInforegisterInput,
  StartInforegisterInputSchema,
  StartInforegisterResponse,
  StartInforegisterResponseSchema,
} from './schemas';

/**
 * Неблокирующий запуск получения данных отсутствующих организаций из Inforegister в бэкенде buh70
 */
export async function startInforegister(
  input: StartInforegisterInput = {},
  apiClient: ApiClient = defaultApiClient
): Promise<StartInforegisterResponse> {
  const validated = StartInforegisterInputSchema.parse(input);

  const payload: Record<string, unknown> = {
    user_id: validated.userId,
    rekv_id: validated.rekvId,
    dry_run: validated.dryRun,
  };
  if (validated.logId) {
    payload.log_id = validated.logId;
  }
  if (validated.insecureTls) {
    payload.insecure_tls = true;
  }
  if (validated.maxCalls !== undefined) {
    payload.max_calls = validated.maxCalls;
  }

  const rawResponse = await apiClient.post<unknown>('/task/getInforegister/', payload);
  return StartInforegisterResponseSchema.parse(rawResponse);
}
