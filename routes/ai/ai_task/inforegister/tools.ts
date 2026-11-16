import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  InforegisterLookupInput,
  InforegisterLookupInputSchema,
  InforegisterLookupResult,
  InforegisterLookupResultSchema,
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
  const hash = validated.hash ?? apiClient.getConfig().inforegisterHash;
  if (!hash) {
    throw new Error('INFOREGISTER_HASH puudub');
  }

  const payload: Record<string, unknown> = {
    user_id: validated.userId,
    rekv_id: validated.rekvId,
    dry_run: validated.dryRun,
    hash,
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

  try {
    const rawResponse = await apiClient.post<unknown>('/task/getInforegister/', payload);
    return StartInforegisterResponseSchema.parse(rawResponse);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    if (msg.includes('HTTP 401')) {
      const authErr = new Error('Inforegister: hash on vale või tühistatud (401)') as Error & { retryable?: boolean };
      authErr.retryable = false;
      throw authErr;
    }
    if (msg.includes('HTTP 403')) {
      const scopeErr = new Error('Inforegister: puudub õigus (403)') as Error & { retryable?: boolean };
      scopeErr.retryable = false;
      throw scopeErr;
    }
    throw err;
  }
}

/**
 * Синхронный поиск одной организации по 8-значному рег.коду через POST /task/inforegisterLookup/.
 * При HTTP 4xx/5xx не бросает исключение, а возвращает { ok: false, reason, message }.
 */
export async function lookupInforegister(
  input: InforegisterLookupInput,
  apiClient: ApiClient = defaultApiClient
): Promise<InforegisterLookupResult> {
  const validated = InforegisterLookupInputSchema.parse(input);
  const hash = validated.hash ?? apiClient.getConfig().inforegisterHash;
  if (!hash) {
    throw new Error('INFOREGISTER_HASH puudub');
  }

  const payload: Record<string, unknown> = {
    regkood: validated.regkood,
    hash,
    cache_only: validated.cacheOnly,
    force_refresh: validated.forceRefresh,
    insecure_tls: validated.insecureTls,
  };
  if (validated.year !== undefined) {
    payload.year = validated.year;
  }

  let raw: {
    status?: number;
    result?: number;
    data?: Record<string, unknown> | null;
    error_message?: string | null;
  };
  try {
    raw = await apiClient.post<{
      status?: number;
      result?: number;
      data?: Record<string, unknown> | null;
      error_message?: string | null;
    }>('/task/inforegisterLookup/', payload, {
      allowHttpErrorResponse: true,
      retries: 1,
      timeoutMs: 45000,
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return InforegisterLookupResultSchema.parse({
      ok: false,
      status: 500,
      data: null,
      reason: msg.toLowerCase().includes('abort') || msg.toLowerCase().includes('timeout') ? 'timeout' : 'network_error',
      message: msg,
    });
  }

  const status = typeof raw?.status === 'number' ? raw.status : 500;
  if (status >= 200 && status < 300 && raw?.result === 1 && raw.data) {
    return InforegisterLookupResultSchema.parse({
      ok: true,
      status,
      data: raw.data,
      message: raw.error_message ?? null,
    });
  }

  const reason =
    raw?.data && typeof raw.data.reason === 'string'
      ? raw.data.reason
      : `http_${status}`;
  return InforegisterLookupResultSchema.parse({
    ok: false,
    status,
    data: raw?.data ?? null,
    reason,
    message: raw?.error_message || `Inforegister lookup failed (HTTP ${status})`,
  });
}
