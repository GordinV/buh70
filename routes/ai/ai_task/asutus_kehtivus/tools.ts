import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  StartAsutusKehtivusInput,
  StartAsutusKehtivusInputSchema,
  StartAsutusKehtivusOutcome,
  StartAsutusKehtivusResponseSchema,
} from './schemas';

/**
 * Неблокирующий запуск проверки закрытых организаций и проставления properties.kehtivus
 * через POST /task/checkAsutusKehtivus/.
 */
export async function startAsutusKehtivus(
  input: StartAsutusKehtivusInput = {},
  apiClient: ApiClient = defaultApiClient
): Promise<StartAsutusKehtivusOutcome> {
  const validated = StartAsutusKehtivusInputSchema.parse(input);
  const hash = validated.hash ?? apiClient.getConfig().inforegisterHash;
  if (!hash) {
    throw new Error('INFOREGISTER_HASH puudub');
  }

  const payload: Record<string, unknown> = {
    user_id: validated.userId,
    rekv_id: validated.rekvId,
    dry_run: validated.dryRun,
    max_close: validated.maxClose,
    hash,
  };
  if (validated.extraEmails && validated.extraEmails.length > 0) {
    payload.extra_emails = validated.extraEmails;
  }

  try {
    const raw = await apiClient.post<unknown>('/task/checkAsutusKehtivus/', payload, {
      allowHttpErrorResponse: true,
      retries: 1,
    });

    const parsed = StartAsutusKehtivusResponseSchema.parse(raw);
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
      const authErr = new Error('Asutuste kehtivus: hash on vale või tühistatud (401)') as Error & { retryable?: boolean };
      authErr.retryable = false;
      throw authErr;
    }

    if (httpStatus === 403) {
      const scopeErr = new Error('Asutuste kehtivus: puudub õigus (403)') as Error & { retryable?: boolean };
      scopeErr.retryable = false;
      throw scopeErr;
    }

    if (httpStatus >= 400 || parsed.result === 0) {
      throw new Error(parsed.error_message || `HTTP ${httpStatus} checkAsutusKehtivus`);
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
      const authErr = new Error('Asutuste kehtivus: hash on vale või tühistatud (401)') as Error & { retryable?: boolean };
      authErr.retryable = false;
      throw authErr;
    }
    if (msg.includes('HTTP 403')) {
      const scopeErr = new Error('Asutuste kehtivus: puudub õigus (403)') as Error & { retryable?: boolean };
      scopeErr.retryable = false;
      throw scopeErr;
    }
    throw err;
  }
}
