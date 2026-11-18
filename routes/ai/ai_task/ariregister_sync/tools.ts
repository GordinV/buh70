import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  StartAriregisterSyncInput,
  StartAriregisterSyncInputSchema,
  StartAriregisterSyncOutcome,
  StartAriregisterSyncResponseSchema,
} from './schemas';

/**
 * Неблокирующий запуск суточной синхронизации Äriregister через POST /task/syncAriregister/.
 * При HTTP 409 (already_running) возвращает { ok: false, alreadyRunning: true, log_id: null }.
 */
export async function startAriregisterSync(
  input: StartAriregisterSyncInput = {},
  apiClient: ApiClient = defaultApiClient
): Promise<StartAriregisterSyncOutcome> {
  const validated = StartAriregisterSyncInputSchema.parse(input);
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

  try {
    const raw = await apiClient.post<unknown>('/task/syncAriregister/', payload, {
      allowHttpErrorResponse: true,
      retries: 1,
    });

    const parsed = StartAriregisterSyncResponseSchema.parse(raw);
    const httpStatus = parsed.status ?? 200;

    if (httpStatus === 409) {
      return {
        ok: false,
        alreadyRunning: true,
        log_id: null,
        status: 409,
      };
    }

    if (httpStatus === 401) {
      const authErr = new Error('Äriregister sync: hash on vale või tühistatud (401)') as Error & { retryable?: boolean };
      authErr.retryable = false;
      throw authErr;
    }

    if (httpStatus === 403) {
      const scopeErr = new Error('Äriregister sync: puudub õigus (403)') as Error & { retryable?: boolean };
      scopeErr.retryable = false;
      throw scopeErr;
    }

    if (httpStatus >= 400 || parsed.result === 0) {
      throw new Error(parsed.error_message || `HTTP ${httpStatus} syncAriregister`);
    }

    return {
      ok: true,
      alreadyRunning: false,
      log_id: parsed.log_id ?? null,
      status: httpStatus,
    };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    if (msg.includes('HTTP 409')) {
      return {
        ok: false,
        alreadyRunning: true,
        log_id: null,
        status: 409,
      };
    }
    if (msg.includes('HTTP 401')) {
      const authErr = new Error('Äriregister sync: hash on vale või tühistatud (401)') as Error & { retryable?: boolean };
      authErr.retryable = false;
      throw authErr;
    }
    if (msg.includes('HTTP 403')) {
      const scopeErr = new Error('Äriregister sync: puudub õigus (403)') as Error & { retryable?: boolean };
      scopeErr.retryable = false;
      throw scopeErr;
    }
    throw err;
  }
}
