import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  LogAgentScheduleInput,
  LogAgentScheduleInputSchema,
  LogAgentScheduleResponse,
  LogAgentScheduleResponseSchema,
} from './schemas';

/**
 * Отправляет снимок расписания и статусов агентов в бэкенд buh70 (ou.logs)
 */
export async function logAgentSchedule(
  input: LogAgentScheduleInput,
  apiClient: ApiClient = defaultApiClient
): Promise<LogAgentScheduleResponse> {
  const validated = LogAgentScheduleInputSchema.parse(input);

  const payload = {
    user_id: validated.userId,
    rekv_id: validated.rekvId,
    snapshot: validated.snapshot,
  };

  const rawResponse = await apiClient.post<unknown>('/task/logAgentSchedule/', payload, {
    timeoutMs: 5000,
  });
  return LogAgentScheduleResponseSchema.parse(rawResponse);
}
