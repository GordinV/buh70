import { ApiClient, defaultApiClient, RequestOptions } from '../shared/api_client';
import {
  ReadTaskLogInput,
  ReadTaskLogInputSchema,
  ReadLogResponse,
  ReadLogResponseSchema,
} from './schemas';

/**
 * Функция прямого вызова API чтения логов buh70 (POST /task/read_log/:user_id/:task_name)
 */
export async function readTaskLog(
  input: ReadTaskLogInput,
  apiClient: ApiClient = defaultApiClient,
  options?: RequestOptions
): Promise<ReadLogResponse> {
  const validatedInput = ReadTaskLogInputSchema.parse(input);
  const query = new URLSearchParams();
  if (validatedInput.logId !== undefined) query.set('log_id', String(validatedInput.logId));
  if (validatedInput.limit !== undefined) query.set('limit', String(validatedInput.limit));
  if (validatedInput.hours !== undefined) query.set('hours', String(validatedInput.hours));
  const queryString = query.toString();
  const path =
    `/task/read_log/${validatedInput.userId}/${encodeURIComponent(validatedInput.taskName)}` +
    (queryString ? `?${queryString}` : '');

  const rawResponse = await apiClient.post<unknown>(path, undefined, options);
  return ReadLogResponseSchema.parse(rawResponse);
}

/**
 * Определение Genkit Tool для вызова из моделей/агентов
 */
export function createReadTaskLogTool(apiClient: ApiClient = defaultApiClient) {
  return {
    name: 'readTaskLog',
    description: 'Опрашивает статус выполнения задачи в журнале ou.logs через POST /task/read_log/:user_id/:task_name',
    inputSchema: ReadTaskLogInputSchema,
    outputSchema: ReadLogResponseSchema,
    fn: async (input: ReadTaskLogInput) => readTaskLog(input, apiClient),
  };
}
