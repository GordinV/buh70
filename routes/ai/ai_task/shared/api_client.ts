import * as dotenv from 'dotenv';
import { AppConfig } from './types';

dotenv.config();

export function getConfig(): AppConfig {
  return {
    geminiApiKey: process.env.GEMINI_API_KEY || '',
    geminiModel: process.env.GEMINI_MODEL || 'gemini-1.5-flash',
    buh70ApiBaseUrl: (process.env.BUH70_API_BASE_URL || 'http://localhost:3000').replace(/\/+$/, ''),
    buh70ApiToken: process.env.BUH70_API_TOKEN || '',
    defaultUserId: parseInt(process.env.DEFAULT_USER_ID || '2477', 10),
    defaultRekvId: parseInt(process.env.DEFAULT_REKV_ID || '63', 10),
    defaultKond: parseInt(process.env.DEFAULT_KOND || '1', 10),
    taskPollIntervalMs: parseInt(process.env.TASK_POLL_INTERVAL_MS || '60000', 10),
    taskTimeoutMs: parseInt(process.env.TASK_TIMEOUT_MS || '14400000', 10),
    maxTaskAttempts: parseInt(process.env.MAX_TASK_ATTEMPTS || '3', 10),
    stateFilePath: process.env.STATE_FILE_PATH,
    dailyStartHour: parseInt(process.env.DAILY_START_HOUR || '20', 10),

    // SMTP Email
    smtpHost: process.env.SMTP_HOST || '',
    smtpPort: parseInt(process.env.SMTP_PORT || '587', 10),
    smtpSecure: process.env.SMTP_SECURE === 'true',
    smtpUser: process.env.SMTP_USER || '',
    smtpPass: process.env.SMTP_PASS || '',
    reportEmailFrom: process.env.REPORT_EMAIL_FROM || process.env.SMTP_USER || 'no-reply@buh70.ee',
    reportEmailTo: process.env.REPORT_EMAIL_TO || '',
  };
}

export interface RequestOptions {
  timeoutMs?: number;
  retries?: number;
  headers?: Record<string, string>;
  customFetch?: typeof fetch;
}

export class ApiClient {
  private config: AppConfig;
  private fetchFn: typeof fetch;

  constructor(customConfig?: Partial<AppConfig>, customFetch?: typeof fetch) {
    this.config = { ...getConfig(), ...customConfig };
    this.fetchFn = customFetch || globalThis.fetch.bind(globalThis);
  }

  public setFetch(fn: typeof fetch): void {
    this.fetchFn = fn;
  }

  public getConfig(): AppConfig {
    return this.config;
  }

  /**
   * Выполняет HTTP POST запрос с защитой от таймаута и автоматическими повторами при сетевых сбоях
   */
  public async post<T>(
    path: string,
    body?: unknown,
    options: RequestOptions = {}
  ): Promise<T> {
    const url = path.startsWith('http')
      ? path
      : `${this.config.buh70ApiBaseUrl}${path.startsWith('/') ? '' : '/'}${path}`;

    const maxRetries = options.retries ?? 3;
    const timeoutMs = options.timeoutMs ?? 30000;
    const fetchImpl = options.customFetch || this.fetchFn;

    let lastError: unknown;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeoutMs);

      try {
        const headers: Record<string, string> = {
          'Content-Type': 'application/json',
          ...(this.config.buh70ApiToken
            ? { Authorization: `Bearer ${this.config.buh70ApiToken}` }
            : {}),
          ...options.headers,
        };

        const response = await fetchImpl(url, {
          method: 'POST',
          headers,
          body: body !== undefined ? JSON.stringify(body) : undefined,
          signal: controller.signal,
        });

        clearTimeout(timer);

        if (!response.ok) {
          const errorText = await response.text().catch(() => '');
          if (response.status >= 500 && attempt < maxRetries) {
            const delay = Math.pow(2, attempt) * 250;
            await new Promise((res) => setTimeout(res, delay));
            continue;
          }
          throw new Error(
            `HTTP ${response.status} ${response.statusText}: ${errorText || 'API error'}`
          );
        }

        const data = (await response.json()) as T;
        return data;
      } catch (err: unknown) {
        clearTimeout(timer);
        lastError = err;

        if (attempt < maxRetries) {
          const delay = Math.pow(2, attempt) * 250;
          await new Promise((res) => setTimeout(res, delay));
        }
      }
    }

    throw lastError instanceof Error
      ? lastError
      : new Error(`Failed to POST to ${url} after ${maxRetries} attempts`);
  }
}

export const defaultApiClient = new ApiClient();
