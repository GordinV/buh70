import * as fs from 'fs';
import * as path from 'path';
import * as dotenv from 'dotenv';
import nodemailer, { Transporter } from 'nodemailer';

function ensureEnvLoaded(): void {
  if (process.env.IMAP_PASS) return;
  let dir = __dirname;
  while (dir !== path.dirname(dir)) {
    const candidate = path.join(dir, '.env');
    if (fs.existsSync(candidate)) {
      dotenv.config({ path: candidate });
      return;
    }
    dir = path.dirname(dir);
  }
  dotenv.config();
}
ensureEnvLoaded();

export const ALERT_EMAILS = ['vladislav.gordin@gmail.com', 'andrei.vargunin@narva.ee'];

import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  DEFAULT_INITIAL_SINCE_DATE,
  MailAccessConfig,
  MailAccessConfigSchema,
  MailDeliveryError,
  MailDeliveryErrorSchema,
  MailDeliveryStatus,
  RawIncomingEmail,
  ReadMailInput,
  ReadMailInputSchema,
  ReadMailResult,
  ReadMailResultSchema,
  ReadMailState,
  ReadMailStateSchema,
  StartReadMailResponse,
  StartReadMailResponseSchema,
  TASK_FLOW_READ_MAIL,
} from './schemas';

export type AiMailGenerateFn = (emailText: string) => Promise<MailDeliveryError | null>;

export type MailFetcherFn = (
  config: MailAccessConfig,
  sinceDate: Date
) => Promise<RawIncomingEmail[]>;

/**
 * Возвращает параметры доступа к почтовому серверу по умолчанию,
 * настроенные по аналогии с automailer.js
 */
export function getDefaultMailAccess(custom?: Partial<MailAccessConfig>): MailAccessConfig {
  const envHost = process.env.IMAP_HOST || 'mail.narva.ee';

  const envPort = process.env.IMAP_PORT
    ? parseInt(process.env.IMAP_PORT, 10)
    : 993;

  const envUser = process.env.IMAP_USER || 'oppetasu'; // по аналогии с automailer.js (l_user = 'oppetasu')
  const envPass = process.env.IMAP_PASS || '';

  const envSecure = process.env.IMAP_SECURE
    ? process.env.IMAP_SECURE === 'true'
    : envPort === 993;

  const envMailbox = process.env.IMAP_MAILBOX || 'INBOX';

  return MailAccessConfigSchema.parse({
    host: envHost,
    port: envPort,
    secure: envSecure,
    user: envUser,
    pass: envPass,
    rejectUnauthorized: false, // по аналогии с automailer.js tls: { rejectUnauthorized: false }
    userMail: 'oppetasu@narva.ee',
    userName: 'Õppetasu',
    userId: 11558,
    mailbox: envMailbox,
    ...custom,
  });
}

/**
 * Определяет абсолютный путь к файлу состояния read_mail_state.json
 */
export function resolveReadMailStatePath(customPath?: string): string {
  if (customPath) {
    return path.resolve(customPath);
  }
  let root = path.resolve(__dirname, '..');
  if (path.basename(root) === 'dist') {
    root = path.resolve(root, '..');
  }
  return path.join(root, 'state', 'read_mail_state.json');
}

/**
 * Загружает состояние фиксации последнего прочитанного письма
 */
export function loadReadMailState(customPath?: string): ReadMailState {
  const filePath = resolveReadMailStatePath(customPath);
  if (fs.existsSync(filePath)) {
    try {
      const raw = fs.readFileSync(filePath, 'utf8');
      const parsed = JSON.parse(raw);
      return ReadMailStateSchema.parse(parsed);
    } catch (err) {
      console.warn(`[read_mail] Viga olekufaili lugemisel (${filePath}):`, err);
    }
  }

  return ReadMailStateSchema.parse({
    sinceDate: DEFAULT_INITIAL_SINCE_DATE,
    lastReadDate: null,
    lastReadUid: null,
    lastReadMessageId: null,
    lastRunAt: null,
    totalProcessedCount: 0,
  });
}

/**
 * Атомарно сохраняет состояние фиксации прочитанных писем
 */
export function saveReadMailState(state: ReadMailState, customPath?: string): void {
  const filePath = resolveReadMailStatePath(customPath);
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  const validated = ReadMailStateSchema.parse(state);
  const tempPath = `${filePath}.${Date.now()}.tmp`;
  const content = JSON.stringify(validated, null, 2);

  fs.writeFileSync(tempPath, content, 'utf8');
  try {
    fs.renameSync(tempPath, filePath);
  } catch {
    // Windows fallback при блокировке дескриптора
    try {
      fs.copyFileSync(tempPath, filePath);
      fs.unlinkSync(tempPath);
    } catch (winErr) {
      console.warn(`[read_mail] Windows fallback save error (${filePath}):`, winErr);
    }
  }
}

/**
 * Фильтрует письма, отсекая сообщения старше 01.10.2026 и уже прочитанные ранее (инкрементальность)
 */
export function filterNewEmails(
  emails: RawIncomingEmail[],
  state: ReadMailState,
  forceSinceDate?: boolean
): RawIncomingEmail[] {
  const initialThreshold = new Date(DEFAULT_INITIAL_SINCE_DATE).getTime();
  const effectiveThreshold =
    !forceSinceDate && state.lastReadDate
      ? new Date(state.lastReadDate).getTime()
      : initialThreshold;

  return emails
    .map((e) => ({
      ...e,
      parsedDate: new Date(e.date),
    }))
    .filter((e) => {
      const msgTime = e.parsedDate.getTime();
      if (isNaN(msgTime) || msgTime < initialThreshold) {
        // Игнорируем письма до 01.10.2026
        return false;
      }

      if (msgTime > effectiveThreshold) {
        return true;
      }

      if (msgTime === effectiveThreshold) {
        // При совпадении миллисекунд проверяем UID и messageId
        if (state.lastReadUid !== null && state.lastReadUid !== undefined && e.uid) {
          return e.uid > state.lastReadUid;
        }
        if (state.lastReadMessageId && e.messageId) {
          return e.messageId !== state.lastReadMessageId;
        }
        return false;
      }

      return false;
    })
    .sort((a, b) => a.parsedDate.getTime() - b.parsedDate.getTime())
    .map(({ parsedDate, ...rest }) => rest);
}

/**
 * Клиент IMAP получения писем через библиотеку imapflow
 */
export const defaultImapFetcher: MailFetcherFn = async (access, sinceDate) => {
  const host = access.host || 'mail.narva.ee';
  const port = access.port || 993;
  const user = access.user || 'oppetasu';
  const pass = access.pass || process.env.IMAP_PASS || '';

  console.log(`[read_mail] Подключение к почтовому серверу IMAP ${host}:${port} (SSL: ${access.secure !== false}) под пользователем "${user}"...`);

  if (!pass) {
    console.warn(`[read_mail] Внимание: Пароль для ящика ${user}@${host} не задан в .env (IMAP_PASS пустой).`);
  }

  // Динамический импорт imapflow
  const { ImapFlow } = await import('imapflow');

  const client = new ImapFlow({
    host,
    port,
    secure: access.secure ?? true,
    auth: {
      user,
      pass,
    },
    tls: {
      rejectUnauthorized: access.rejectUnauthorized ?? false,
    },
    logger: false,
  });

  const emails: RawIncomingEmail[] = [];

  try {
    await client.connect();
    const targetMailbox = access.mailbox || process.env.IMAP_MAILBOX || 'INBOX';
    console.log(`[read_mail] Успешная авторизация на ${host}! Открываем папку "${targetMailbox}"...`);
    const lock = await client.getMailboxLock(targetMailbox);

    try {
      const searchCriteria = { since: sinceDate };
      console.log(`[read_mail] Поиск входящих писем начиная с даты: ${sinceDate.toISOString()} в "${targetMailbox}"...`);
      for await (const message of client.fetch(searchCriteria, {
        uid: true,
        envelope: true,
        source: true,
      })) {
        const bodyText = message.source ? message.source.toString('utf-8') : '';
        emails.push({
          uid: message.uid,
          messageId: message.envelope?.messageId,
          date: message.envelope?.date || new Date(),
          subject: message.envelope?.subject,
          from: message.envelope?.from?.[0]?.address,
          text: bodyText,
        });
      }
      console.log(`[read_mail] Загружено писем из папки "${targetMailbox}": ${emails.length}`);
    } finally {
      lock.release();
    }

    // Если в INBOX пусто и пользователь явно не указывал другую папку, проверяем папку "Архив"
    if (emails.length === 0 && targetMailbox === 'INBOX') {
      try {
        const archiveStatus = await client.status('Архив', { messages: true });
        const archiveCount = archiveStatus && typeof archiveStatus === 'object' && 'messages' in archiveStatus
          ? ((archiveStatus as any).messages ?? 0)
          : 0;
        if (archiveCount > 0) {
          console.log(`[read_mail] В INBOX 0 писем. Проверяем папку "Архив" (содержит ${archiveCount} писем)...`);
          const archiveLock = await client.getMailboxLock('Архив');
          try {
            for await (const message of client.fetch({ since: sinceDate }, {
              uid: true,
              envelope: true,
              source: true,
            })) {
              const bodyText = message.source ? message.source.toString('utf-8') : '';
              emails.push({
                uid: message.uid,
                messageId: message.envelope?.messageId,
                date: message.envelope?.date || new Date(),
                subject: message.envelope?.subject,
                from: message.envelope?.from?.[0]?.address,
                text: bodyText,
              });
            }
            console.log(`[read_mail] Загружено писем из папки "Архив": ${emails.length}`);
          } finally {
            archiveLock.release();
          }
        }
      } catch (archErr: any) {
        console.log(`[read_mail] Пропуск папки "Архив": ${archErr.message}`);
      }
    }

    await client.logout();
  } catch (err: any) {
    console.error(`[read_mail] Ошибка IMAP при обращении к ${host}: ${err.message || err}`);
    throw err;
  }

  return emails;
};

/**
 * Декодирует заголовки MIME RFC 2047 (=?UTF-8?B?...?= или =?UTF-8?Q?...?=)
 */
export function decodeMimeWords(str: string): string {
  if (!str) return '';
  const normalized = str.replace(/\?=\s+=\?/g, '?==?');
  return normalized.replace(/=\?([^?]+)\?([BQbq])\?([^?]+)\?=/g, (_, charset, encoding, text) => {
    try {
      const enc = encoding.toUpperCase();
      if (enc === 'B') {
        const buf = Buffer.from(text, 'base64');
        return buf.toString(charset.toLowerCase().includes('1251') ? 'latin1' : 'utf8');
      } else if (enc === 'Q') {
        const decoded = text
          .replace(/_/g, ' ')
          .replace(/=([A-Fa-f0-9]{2})/g, (_m: string, hex: string) =>
            String.fromCharCode(parseInt(hex, 16))
          );
        return Buffer.from(decoded, 'binary').toString('utf8');
      }
    } catch {
      return text;
    }
    return text;
  });
}

/**
 * Распаковывает тело MIME письма (multipart, base64, quoted-printable, delivery-status, html)
 */
export function decodeEmailBody(raw: string): string {
  if (!raw || typeof raw !== 'string') return '';

  const boundaryMatches = Array.from(raw.matchAll(/boundary="?([^";\r\n]+)"?/gi));
  if (boundaryMatches.length > 0) {
    const boundaries = Array.from(new Set(boundaryMatches.map((m) => m[1].trim())));
    const boundaryPattern = new RegExp(
      `--(?:${boundaries.map((b) => b.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|')})(?:--)?\r?\n?`
    );
    const parts = raw.split(boundaryPattern);
    let textResult = '';
    for (const part of parts) {
      if (!part.trim()) continue;
      const [headerSection, ...bodySections] = part.split(/\r?\n\r?\n/);
      if (bodySections.length === 0) continue;
      const bodyPart = bodySections.join('\n\n');

      const isBase64 = /content-transfer-encoding:\s*base64/i.test(headerSection);
      const isQP = /content-transfer-encoding:\s*quoted-printable/i.test(headerSection);
      const isHtml = /content-type:\s*text\/html/i.test(headerSection);
      const isText = /content-type:\s*(?:text\/plain|message\/delivery-status)/i.test(headerSection);

      let decoded = bodyPart;
      if (isBase64) {
        try {
          decoded = Buffer.from(bodyPart.replace(/\s+/g, ''), 'base64').toString('utf8');
        } catch {}
      } else if (isQP) {
        try {
          decoded = bodyPart
            .replace(/=\r?\n/g, '')
            .replace(/=([A-Fa-f0-9]{2})/g, (_m: string, hex: string) => String.fromCharCode(parseInt(hex, 16)));
        } catch {}
      }

      if (isHtml) {
        decoded = decoded
          .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
          .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
          .replace(/<[^>]+>/g, ' ')
          .replace(/&nbsp;/gi, ' ')
          .replace(/\s+/g, ' ');
      }

      if (isText || isHtml) {
        textResult += '\n' + decoded;
      }
    }
    if (textResult.trim()) {
      return textResult.trim();
    }
  }

  const [headerSection, ...bodySections] = raw.split(/\r?\n\r?\n/);
  if (bodySections.length > 0) {
    const bodyPart = bodySections.join('\n\n');
    if (/content-transfer-encoding:\s*base64/i.test(headerSection)) {
      try {
        return Buffer.from(bodyPart.replace(/\s+/g, ''), 'base64').toString('utf8');
      } catch {}
    } else if (/content-transfer-encoding:\s*quoted-printable/i.test(headerSection)) {
      try {
        return bodyPart
          .replace(/=\r?\n/g, '')
          .replace(/=([A-Fa-f0-9]{2})/g, (_m: string, hex: string) => String.fromCharCode(parseInt(hex, 16)));
      } catch {}
    }
    return bodyPart;
  }
  return raw;
}

/**
 * Очищает разметку Markdown links, HTML ссылки и угловые скобки из текста письма
 */
export function cleanEmailText(text: string): string {
  if (!text) return '';
  return text
    .replace(/\[\s*<?\s*([^\]>]+?)\s*>?\s*\]\(mailto:[^)]+\)/gi, '$1')
    .replace(/<a\b[^>]*>(.*?)<\/a>/gi, '$1')
    .replace(/<\s*([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})\s*>/g, '$1');
}

/**
 * Классифицирует ошибки доставки по четырем регламентным статусам:
 * 1. Aadressi viga - несуществующий или неверный адрес получателя (User unknown, Mailbox unavailable, 550 5.1.1 и т.д.)
 * 2. Domeeni viga - ошибка поиска или недоступность домена/DNS/MX записи (Domain lookup error, Host not found и т.д.)
 * 3. Postkast täis - переполнение почтового ящика получателя (Quota exceeded, Mailbox full, 552, 452)
 * 4. Muud vead - все прочие сетевые и почтовые сбои (Connection refused, Relay access denied, таймауты и др.)
 */
export function categorizeMailError(text: string, reason?: string | null): MailDeliveryStatus {
  // Очищаем текст от технического заголовка Reporting-MTA: dns; ... (RFC 3464), чтобы не путать с реальной DNS ошибкой
  const cleanBody = (text || '').replace(/reporting-mta:\s*dns[^\r\n]*/gi, '');
  const combined = `${reason || ''} ${cleanBody}`.toLowerCase();

  // 1. Postkast täis (Quota exceeded, mailbox full, out of storage space, overquota, 4.2.2, 5.2.2, 552, 452)
  if (
    combined.includes('quota exceeded') ||
    combined.includes('mailbox is full') ||
    combined.includes('mailbox full') ||
    combined.includes('over quota') ||
    combined.includes('overquota') ||
    combined.includes('out of storage') ||
    combined.includes('storage space') ||
    combined.includes('storage limit') ||
    combined.includes('postkast täis') ||
    combined.includes('postkast on täis') ||
    combined.includes('insufficient storage') ||
    /\b4\.2\.2\b/.test(combined) ||
    /\b5\.2\.2\b/.test(combined) ||
    /\b552\b/.test(combined) ||
    /\b452\b/.test(combined)
  ) {
    return 'Postkast täis';
  }

  // 2. Aadressi viga (User unknown, invalid address, mailbox does not exist, user not found, invalid mailbox, 550 5.1.1, client email change)
  if (
    combined.includes('user not found') ||
    combined.includes('user unknown') ||
    combined.includes('unknown user') ||
    combined.includes('no such user') ||
    combined.includes('invalid mailbox') ||
    combined.includes('mailbox is unavailable') ||
    combined.includes('mailbox unavailable') ||
    combined.includes('mailbox disabled') ||
    combined.includes('account disabled') ||
    combined.includes('recipient address rejected') ||
    combined.includes('address rejected') ||
    combined.includes('invalid address') ||
    combined.includes('invalid recipient') ||
    combined.includes('does not exist') ||
    combined.includes('bad destination mailbox') ||
    combined.includes('550 5.1.1') ||
    /\b5\.1\.1\b/.test(combined) ||
    combined.includes('aadressi viga') ||
    combined.includes('изменить свой эмайл') ||
    combined.includes('изменить email') ||
    combined.includes('изменить почту') ||
    combined.includes('свой эмайл') ||
    combined.includes('новый эмайл') ||
    combined.includes('muuda e-post') ||
    combined.includes('uus e-mail')
  ) {
    return 'Aadressi viga';
  }

  // 3. Domeeni viga (Domain lookup error, host not found, dns query failed, mx)
  if (
    combined.includes('domain lookup error') ||
    combined.includes('host or domain name not found') ||
    combined.includes('domain not found') ||
    combined.includes('dns lookup') ||
    combined.includes('dns query') ||
    combined.includes('dns error') ||
    combined.includes('dns failure') ||
    combined.includes('nxdomain') ||
    combined.includes('no mx record') ||
    combined.includes('name server') ||
    combined.includes('domeeni viga') ||
    /\bdns\b/i.test(reason || '')
  ) {
    return 'Domeeni viga';
  }

  // 4. Muud vead (все остальные сетевые и почтовые сбои)
  return 'Muud vead';
}

/**
 * Детерминированный парсер уведомлений о сбоях доставки (Bounce / MAILER-DAEMON / DSN)
 * Анализирует пересланные цепочки писем и извлекает:
 * 1. статус (status: "Aadressi viga" | "Domeeni viga" | "Postkast täis" | "Muud vead")
 * 2. причину (reason)
 * 3. номер счета (doc_number / invoice_number)
 * 4. адрес получателя счета (recipient_email)
 */
export function parseDeliveryFailureText(rawText: string): MailDeliveryError | null {
  if (!rawText || typeof rawText !== 'string') {
    return null;
  }

  const decodedRaw = decodeEmailBody(rawText);
  const text = cleanEmailText(decodedRaw);

  // 1. Проверяем наличие признаков ошибки доставки (bounce notice)
  const isBounce =
    /permanent\s+failure\s+notice/i.test(rawText) ||
    /permanent\s+failure\s+notice/i.test(text) ||
    /mailer-daemon/i.test(rawText) ||
    /mailer-daemon/i.test(text) ||
    /delivery\s+(?:status\s+notification|failure|status)/i.test(rawText) ||
    /delivery\s+(?:status\s+notification|failure|status)/i.test(text) ||
    /undelivered\s+mail/i.test(rawText) ||
    /undelivered\s+mail/i.test(text) ||
    /not\s+able\s+to\s+deliver\s+your\s+mail/i.test(text) ||
    /domain\s+lookup\s+error/i.test(text) ||
    /user\s+unknown/i.test(text) ||
    /quota\s+exceeded/i.test(text) ||
    /mailbox\s+(?:is\s+)?full/i.test(text) ||
    /postkast\s+(?:on\s+)?t[aä]is/i.test(text) ||
    /550\s+5\.\d+\.\d+/i.test(text);

  if (!isBounce) {
    return null;
  }

  // 2. Извлечение адреса получателя (recipient_email)
  let recipientEmail: string | null = null;
  let reason: string | null = null;

  // Шаблон 1: Строка вида "email@domain.com : Reason text" (стандарт MAILER-DAEMON / Postfix)
  const daemonLineMatch = text.match(
    /([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})\s*:\s*([^\r\n]+)/i
  );

  if (daemonLineMatch) {
    const candidate = daemonLineMatch[1].trim();
    if (!/mailer-daemon|postmaster|oppetasu/i.test(candidate)) {
      recipientEmail = candidate;
      reason = daemonLineMatch[2].trim();
    }
  }

  // Шаблон 2: Final-Recipient: rfc822;email@domain.com
  if (!recipientEmail) {
    const finalRecMatch = text.match(
      /Final-Recipient:\s*rfc822;([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/i
    );
    if (finalRecMatch) {
      recipientEmail = finalRecMatch[1].trim();
    }
  }

  // Шаблон 3: В блоке "I was not able to deliver your mail to the following addresses:"
  if (!recipientEmail) {
    const deliverBlockMatch = text.match(
      /(?:not\s+able\s+to\s+deliver\s+your\s+mail\s+to|failed\s+recipients?|failed\s+addresses?):[\s\S]*?([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/i
    );
    if (deliverBlockMatch) {
      recipientEmail = deliverBlockMatch[1].trim();
    }
  }

  // Шаблон 4: Получатель оригинального письма счета (Saaja: email)
  if (!recipientEmail) {
    const saajaMatch = text.match(
      /(?:Saaja|To|Recipient):\s*(?:[^\r\n<]*<)?([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/i
    );
    if (saajaMatch) {
      const candidate = saajaMatch[1].trim();
      if (!/oppetasu@narva\.ee|andrei\.vargunin|mailer-daemon/i.test(candidate)) {
        recipientEmail = candidate;
      }
    }
  }

  if (!recipientEmail) {
    return null;
  }

  // 3. Извлечение причины ошибки (reason)
  if (!reason) {
    const specificReasonMatch = text.match(
      /(Domain lookup error|User unknown|Mailbox unavailable|Quota exceeded|Host or domain name not found|Connection refused|Relay access denied|550\s+[^\r\n]+|554\s+[^\r\n]+|user\s+not\s+found|invalid\s+mailbox|5\.1\.1[^\r\n]*)/i
    );
    if (specificReasonMatch) {
      reason = specificReasonMatch[1].trim();
    } else {
      const generalFailureMatch = text.match(
        /(?:This is a permanent delivery failure[^\r\n.]*|Delivery has been tried[^\r\n.]*)/i
      );
      reason = generalFailureMatch ? generalFailureMatch[0].trim() : 'Permanent delivery failure';
    }
  }

  // 4. Определение статуса (status) по 4 регламентным категориям
  const status: MailDeliveryStatus = categorizeMailError(text, reason);

  // 5. Извлечение номера счета / документа (doc_number / invoice_number)
  let docNumber = '';
  let referenceNumber: string | undefined = undefined;

  // Ищем формат buh70 automailer: "Saadan dokument nr. 101-10772, 1010177139"
  const docNrPattern =
    /(?:Saadan\s+dokument\s+nr[.:]?|Arve\s+nr[.:]?|Dokument\s+nr[.:]?|Invoice\s+nr[.:]?)\s*([0-9a-zA-Z\-_/]+)(?:,\s*([0-9a-zA-Z\-_/]+))?/i;

  const docNrMatch = text.match(docNrPattern) || rawText.match(docNrPattern);

  if (docNrMatch) {
    docNumber = docNrMatch[1].trim();
    if (docNrMatch[2]) {
      referenceNumber = docNrMatch[2].trim();
    }
  } else {
    const genericDocMatch = text.match(/(?:nr[.:]?\s*)([0-9]{2,4}-[0-9]{3,7})/i);
    if (genericDocMatch) {
      docNumber = genericDocMatch[1].trim();
    }
  }

  if (!docNumber) {
    docNumber = 'UNKNOWN';
  }

  // 6. Извлечение даты сбоя или отправки (failed_at)
  let failedAt: string | undefined = undefined;
  const dateMatch = text.match(/(?:Kuupäev|Date|Sent):\s*([^\r\n]+)/i);
  if (dateMatch) {
    failedAt = dateMatch[1].trim();
  }

  // 7. Исходная тема
  let sourceSubject: string | undefined = undefined;
  const subjectMatch = text.match(/(?:Subject|Teema):\s*([^\r\n]+)/i);
  if (subjectMatch) {
    sourceSubject = decodeMimeWords(subjectMatch[1].trim());
  }

  const result: MailDeliveryError = {
    status,
    reason,
    doc_number: docNumber,
    invoice_number: docNumber,
    recipient_email: recipientEmail,
    ...(referenceNumber ? { reference_number: referenceNumber } : {}),
    ...(failedAt ? { failed_at: failedAt } : {}),
    ...(sourceSubject ? { source_subject: sourceSubject } : {}),
  };

  return MailDeliveryErrorSchema.parse(result);
}

/**
 * Универсальный парсер входящих писем:
 * Расшифровывает ЛЮБОЕ поступившее письмо (bounce, ответ клиента, запрос смены email, вопрос по счету)
 * и возвращает структурированный объект MailDeliveryError
 */
export function parseIncomingEmail(
  rawText: string,
  metadata?: { subject?: string; from?: string; date?: Date | string }
): MailDeliveryError {
  const decodedBody = decodeEmailBody(rawText);
  const cleanBody = cleanEmailText(decodedBody);

  // Извлечение темы
  let subject = metadata?.subject;
  if (!subject) {
    const subMatch = rawText.match(/Subject:\s*([^\r\n]+(?:\r?\n\s+[^\r\n]+)*)/i);
    if (subMatch) {
      subject = decodeMimeWords(subMatch[1].replace(/\r?\n\s+/g, ' ').trim());
    }
  }
  if (!subject) {
    const teemaMatch = cleanBody.match(/(?:Teema|Subject):\s*([^\r\n]+)/i);
    if (teemaMatch) {
      subject = decodeMimeWords(teemaMatch[1].trim());
    }
  }

  // Извлечение отправителя (From)
  let fromAddress = metadata?.from;
  if (!fromAddress) {
    const fromMatch = rawText.match(/From:\s*(?:[^\r\n<]*<)?([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/i);
    if (fromMatch) {
      fromAddress = fromMatch[1].trim();
    }
  }

  const combinedSearchText = `${subject || ''}\n${cleanBody}\n${rawText}`;

  // 1. Проверяем, является ли письмо bounce (MAILER-DAEMON / DSN)
  const isBounce =
    /permanent\s+failure\s+notice/i.test(combinedSearchText) ||
    /mailer-daemon/i.test(combinedSearchText) ||
    /delivery\s+(?:status\s+notification|failure|status)/i.test(combinedSearchText) ||
    /undelivered\s+mail/i.test(combinedSearchText) ||
    /not\s+able\s+to\s+deliver\s+your\s+mail/i.test(combinedSearchText) ||
    /550\s+5\.\d+\.\d+/i.test(combinedSearchText);

  if (isBounce) {
    const bounceRes = parseDeliveryFailureText(rawText);
    if (bounceRes) {
      return bounceRes;
    }
  }

  // 2. Не bounce: ответ клиента / запрос смены email / вопрос по счету
  let docNumber = '';
  let referenceNumber: string | undefined = undefined;

  const docNrPattern =
    /(?:Saadan\s+dokument\s+nr[.:]?|Arve\s+nr[.:]?|Dokument\s+nr[.:]?|Invoice\s+nr[.:]?)\s*([0-9a-zA-Z\-_/]+)(?:,\s*([0-9a-zA-Z\-_/]+))?/i;
  const docNrMatch = combinedSearchText.match(docNrPattern);

  if (docNrMatch) {
    docNumber = docNrMatch[1].trim();
    if (docNrMatch[2]) {
      referenceNumber = docNrMatch[2].trim();
    }
  } else {
    const genericDocMatch = combinedSearchText.match(/(?:nr[.:]?\s*)([0-9]{2,4}-[0-9]{3,7})/i);
    if (genericDocMatch) {
      docNumber = genericDocMatch[1].trim();
    }
  }

  if (!docNumber) {
    docNumber = 'N/A';
  }

  // Получатель счета: для ответа клиента получателем является адрес клиента (fromAddress)
  let recipientEmail: string | null = fromAddress || null;
  if (!recipientEmail || /oppetasu@narva\.ee/i.test(recipientEmail)) {
    const saajaMatch = cleanBody.match(
      /(?:Saaja|To|Recipient):\s*(?:[^\r\n<]*<)?([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/i
    );
    if (saajaMatch && !/oppetasu@narva\.ee/i.test(saajaMatch[1])) {
      recipientEmail = saajaMatch[1].trim();
    }
  }

  // Проверяем запрос клиента на смену e-mail
  const isAddressChange =
    /изменить(?:\s+свой)?\s+(?:эмайл|email|почту|адрес)/i.test(combinedSearchText) ||
    /новый\s+(?:эмайл|email|адрес)/i.test(combinedSearchText) ||
    /muuda\s+(?:e-post|e-mail|aadress)/i.test(combinedSearchText) ||
    /uus\s+(?:e-post|e-mail|aadress)/i.test(combinedSearchText) ||
    /vale\s+(?:e-post|aadress)/i.test(combinedSearchText);

  let newEmail: string | undefined = undefined;
  const newEmailMatch = combinedSearchText.match(
    /(?:новый\s+(?:эмайл|email|адрес|ящик)|uus\s+(?:e-post|e-mail|aadress))[:\s]+([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/i
  );
  if (newEmailMatch) {
    newEmail = newEmailMatch[1].trim();
  } else {
    const allEmails = Array.from(
      combinedSearchText.matchAll(/([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/g)
    ).map((m) => m[1].trim());
    const candidate = allEmails.find(
      (e) => !/oppetasu@narva\.ee|narvakultuur\.ee|mailer-daemon/i.test(e) && e.toLowerCase() !== recipientEmail?.toLowerCase()
    );
    if (candidate) {
      newEmail = candidate;
    }
  }

  let status: MailDeliveryStatus;
  let reason: string;

  if (isAddressChange) {
    status = 'Aadressi viga';
    reason = newEmail
      ? `Kliendi soov muuta e-posti aadress: ${newEmail}`
      : 'Kliendi teade: e-posti aadressi muutmine';
  } else {
    status = categorizeMailError(combinedSearchText, subject);
    const cleanLines = cleanBody
      .split(/\r?\n/)
      .map((l) => l.trim())
      .filter((l) => l && !l.startsWith('>') && !l.startsWith('---') && !/^(From|To|Subject|Date|Sent|Teema|Saatja|Kuupäev|Saaja):/i.test(l));
    const firstLine = cleanLines[0] || subject || 'Sissetulnud kiri';
    reason = firstLine.slice(0, 150);
  }

  let failedAt: string | undefined = undefined;
  if (metadata?.date) {
    failedAt = typeof metadata.date === 'string' ? metadata.date : metadata.date.toISOString();
  } else {
    const dateMatch = rawText.match(/(?:Kuupäev|Date|Sent):\s*([^\r\n]+)/i);
    if (dateMatch) {
      failedAt = dateMatch[1].trim();
    }
  }

  const result: MailDeliveryError = {
    status,
    reason: reason || 'Kiri töödeldud',
    doc_number: docNumber,
    invoice_number: docNumber,
    recipient_email: recipientEmail || 'unknown@client.ee',
    ...(referenceNumber ? { reference_number: referenceNumber } : {}),
    ...(failedAt ? { failed_at: failedAt } : {}),
    ...(subject ? { source_subject: subject } : {}),
  };

  return MailDeliveryErrorSchema.parse(result);
}

/**
 * Интеллектуальный парсинг с использованием AI (Gemini) и автоматическим fallback на регулярный парсер
 */
export async function parseDeliveryFailureWithAi(
  emailText: string,
  aiGenerateFn?: AiMailGenerateFn,
  emailMeta?: RawIncomingEmail
): Promise<MailDeliveryError | null> {
  if (aiGenerateFn) {
    try {
      const aiResult = await aiGenerateFn(emailText);
      if (aiResult) {
        const normalizedStatus = categorizeMailError(
          emailText,
          aiResult.reason || aiResult.status
        );

        return MailDeliveryErrorSchema.parse({
          ...aiResult,
          status: normalizedStatus,
          doc_number: aiResult.doc_number,
          invoice_number: aiResult.invoice_number || aiResult.doc_number,
        });
      }
    } catch (err) {
      console.warn('[read_mail] AI parsing error, falling back to deterministic parser:', err);
    }
  }

  return parseIncomingEmail(emailText, {
    subject: emailMeta?.subject,
    from: emailMeta?.from,
    date: emailMeta?.date,
  });
}

/**
 * Инициирует задачу анализа почты через API бэкенда (если доступен роут POST /task/readMail/)
 */
/**
 * Инициирует задачу анализа почты через HTTP API бэкенда (POST /task/readMail/)
 * По аналогии с startSaldoandmik / startGetEarved
 */
export async function startReadMail(
  input: ReadMailInput = {},
  apiClient: ApiClient = defaultApiClient
): Promise<StartReadMailResponse> {
  const validated = ReadMailInputSchema.parse(input);
  const payload = {
    userId: validated.userId,
    rekvId: validated.rekvId,
    sinceDate: validated.sinceDate,
    forceSinceDate: validated.forceSinceDate,
    stateFilePath: validated.stateFilePath,
    emailContent: validated.emailContent,
    emails: validated.emails,
  };

  const response = await apiClient.post<unknown>('/task/readMail/', payload);
  return StartReadMailResponseSchema.parse(response);
}

export interface DbQueryResult<T = unknown> {
  error_code?: number;
  result?: number | null;
  error_message?: string | null;
  data?: T[];
}

export type CreateLogFn = (
  rekvId?: number,
  userId?: number,
  flowName?: string
) => Promise<DbQueryResult<{ id: number }> | null>;

export type EndLogFn = (
  logId?: number | null,
  status?: string,
  errorMessage?: string | null,
  resultDetails?: unknown
) => Promise<void>;

export type TuhistaArveSaatmiseStaatusFn = (
  logId: number
) => Promise<DbQueryResult<unknown> | null>;

export type SendAlertFn = (
  otherErrors: MailDeliveryError[],
  logId?: number | null
) => Promise<any>;

export interface ReadMailCoreOptions {
  aiGenerateFn?: AiMailGenerateFn;
  mailFetcher?: MailFetcherFn;
  createLogFn?: CreateLogFn;
  endLogFn?: EndLogFn;
  tuhistaStaatusFn?: TuhistaArveSaatmiseStaatusFn;
  sendAlertFn?: SendAlertFn;
  transporter?: Transporter;
}

/**
 * Ядро выполнения выборки и анализа почты (IMAP + декодирование + обновление state)
 * Не имеет прямых зависимостей от БД. Используется воркером и тестами.
 */
export async function executeReadMailCore(
  input: ReadMailInput = {},
  options: ReadMailCoreOptions = {}
): Promise<ReadMailResult> {
  const validated = ReadMailInputSchema.parse(input);
  const flowName = TASK_FLOW_READ_MAIL;

  let logId: number | null = validated.logId ?? null;

  try {
    if (!logId && options.createLogFn) {
      try {
        const logResult = await options.createLogFn(validated.rekvId, validated.userId, flowName);
        if (logResult && logResult.data && logResult.data[0] && logResult.data[0].id) {
          logId = Number(logResult.data[0].id);
        }
      } catch (logErr) {
        console.warn('[read_mail] Failed to create start log hook:', logErr);
      }
    }

    // 1. Загрузка сохраненного состояния (read_mail_state.json)
    const state = loadReadMailState(validated.stateFilePath);

    // 2. Определение точки отсчета (начиная с 01.10.2026)
    const initialSince = validated.sinceDate || DEFAULT_INITIAL_SINCE_DATE;
    const effectiveSince =
      !validated.forceSinceDate && state.lastReadDate
        ? new Date(state.lastReadDate)
        : new Date(initialSince);

    // 3. Получение писем для анализа
    let incomingEmails: RawIncomingEmail[] = [];
    if (validated.rawEmails && validated.rawEmails.length > 0) {
      incomingEmails = validated.rawEmails.map((e, idx) => ({
        uid: e.uid ?? idx + 1,
        messageId: e.messageId,
        date: new Date(e.date),
        subject: e.subject,
        text: e.text,
      }));
    } else if (validated.emailContent || (validated.emails && validated.emails.length > 0)) {
      const list: string[] = [];
      if (validated.emailContent) list.push(validated.emailContent);
      if (validated.emails) list.push(...validated.emails);

      incomingEmails = list.map((text, idx) => ({
        uid: idx + 1,
        date: new Date(),
        text,
      }));
    } else {
      const mailAccess = getDefaultMailAccess(validated.mailAccess);
      const fetcher = options.mailFetcher || defaultImapFetcher;
      incomingEmails = await fetcher(mailAccess, effectiveSince);
    }

    // 4. Инкрементальная фильтрация: только письма >= 01.10.2026 и новее state.lastReadDate
    const newEmails = filterNewEmails(incomingEmails, state, validated.forceSinceDate);

    const deliveryErrors: MailDeliveryError[] = [];

    // 5. Анализ содержимого писем (игнорируем письма без валидного номера счета)
    for (const email of newEmails) {
      const errorInfo = validated.useAi
        ? await parseDeliveryFailureWithAi(email.text, options.aiGenerateFn, email)
        : await parseDeliveryFailureWithAi(email.text, undefined, email);

      if (errorInfo && hasValidDocNumber(errorInfo.doc_number || errorInfo.invoice_number)) {
        deliveryErrors.push(errorInfo);
      }
    }

    // 6. Фиксация последнего прочитанного письма в state
    if (newEmails.length > 0) {
      const latest = newEmails.reduce((max, curr) => {
        const currTime = new Date(curr.date).getTime();
        const maxTime = new Date(max.date).getTime();
        if (currTime > maxTime) return curr;
        if (currTime === maxTime && (curr.uid || 0) > (max.uid || 0)) return curr;
        return max;
      });

      state.lastReadDate = new Date(latest.date).toISOString();
      state.lastReadUid = latest.uid ?? null;
      state.lastReadMessageId = latest.messageId ?? null;
      state.lastRunAt = new Date().toISOString();
      state.totalProcessedCount += newEmails.length;

      saveReadMailState(state, validated.stateFilePath);
    }

    const finalResult = ReadMailResultSchema.parse(deliveryErrors);

    // 7. Опциональный вызов хуков логирования, если переданы в options (для тестов)
    if (logId && options.endLogFn) {
      try {
        await options.endLogFn(logId, 'success', null, finalResult);
      } catch (endErr) {
        console.warn('[read_mail] Failed to update end log hook:', endErr);
      }

      const hasInvoicesToCancel = finalResult.some((r) =>
        hasValidDocNumber(r.doc_number || r.invoice_number)
      );
      if (hasInvoicesToCancel && options.tuhistaStaatusFn) {
        try {
          await options.tuhistaStaatusFn(logId);
        } catch (tuhistaErr) {
          console.warn('[read_mail] Failed to execute tuhistaStaatusFn hook:', tuhistaErr);
        }
      }
    }

    // 8. Отправка отчета об ошибках "Muud vead" на vladislav.gordin@gmail.com и andrei.vargunin@narva.ee
    const otherErrors = finalResult.filter(
      (r) => r.status === 'Muud vead' && hasValidDocNumber(r.doc_number || r.invoice_number)
    );
    if (otherErrors.length > 0) {
      if (options.sendAlertFn) {
        try {
          await options.sendAlertFn(otherErrors, logId);
        } catch (alertErr) {
          console.warn('[read_mail] Failed to execute sendAlertFn hook:', alertErr);
        }
      } else {
        try {
          await sendOtherErrorsAlertEmail(otherErrors, {
            transporter: options.transporter,
            logId,
          });
        } catch (alertErr) {
          console.warn('[read_mail] Failed to send other errors alert email:', alertErr);
        }
      }
    }

    return finalResult;
  } catch (error: any) {
    if (logId && options.endLogFn) {
      try {
        await options.endLogFn(logId, 'failed', error.message || String(error));
      } catch (endErr) {
        console.warn('[read_mail] Failed to update fail log hook:', endErr);
      }
    }
    throw error;
  }
}

/**
 * Проверка наличия валидного номера счета (исключаем пустые значения, 'N/A', 'UNKNOWN')
 */
export function hasValidDocNumber(docNumber?: string | null): boolean {
  if (!docNumber) return false;
  const normalized = String(docNumber).trim().toUpperCase();
  return normalized.length > 0 && normalized !== 'N/A' && normalized !== 'UNKNOWN';
}

/**
 * Обратно-совместимые заглушки хуков БД
 */
export async function createLog(
  rekvId: number = 63,
  userId: number = 2477,
  flowName: string = TASK_FLOW_READ_MAIL
): Promise<DbQueryResult<{ id: number }> | null> {
  return null;
}

export async function endLog(
  logId?: number | null,
  status: string = 'success',
  errorMessage: string | null = null,
  resultDetails?: unknown
): Promise<void> {}

export async function tuhistaArveSaatmiseStaatus(
  logId: number
): Promise<DbQueryResult<unknown> | null> {
  return null;
}

/**
 * Отправка отчета об ошибках со статусом "Muud vead" на vladislav.gordin@gmail.com и andrei.vargunin@narva.ee
 */
export async function sendOtherErrorsAlertEmail(
  otherErrors: MailDeliveryError[],
  options: { transporter?: Transporter; logId?: number | null } = {}
): Promise<any> {
  const validErrors = (otherErrors || []).filter((err) =>
    hasValidDocNumber(err.doc_number || err.invoice_number)
  );
  if (validErrors.length === 0) return null;

  console.log(
    `[read_mail] Sending "Muud vead" alert for ${validErrors.length} error(s) to ${ALERT_EMAILS.join(', ')}`
  );

  let rowsText = '';
  let rowsHtml = '';

  for (const err of validErrors) {
    const docNum = err.doc_number || err.invoice_number || 'N/A';
    const recip = err.recipient_email || 'unknown';
    const rsn = err.reason || 'Määramata saatmise tõrge';

    rowsText += `- Arve nr: ${docNum} | Saaja: ${recip} | Põhjus: ${rsn}\n`;
    rowsHtml += `<tr>
      <td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">${docNum}</td>
      <td style="padding: 8px; border: 1px solid #ddd;">${recip}</td>
      <td style="padding: 8px; border: 1px solid #ddd; color: #d32f2f;">${rsn}</td>
    </tr>`;
  }

  const textContent =
    `buh70: E-posti kohaletoimetamise määramata vead (Muud vead)\n\n` +
    `Tuvastati ${validErrors.length} teadet, mis ei vasta tavalistele vigadele ja vajavad täiendavat kontrolli:\n\n` +
    rowsText +
    `\n` +
    (options.logId ? `Logi ID süsteemis: ${options.logId}\n` : '') +
    `Aeg: ${new Date().toISOString()}\n`;

  const htmlContent = `
    <div style="font-family: Arial, sans-serif; color: #333; max-width: 650px;">
      <h2 style="color: #d32f2f; border-bottom: 2px solid #d32f2f; padding-bottom: 6px;">
        buh70: E-posti saatmise vead (Muud vead)
      </h2>
      <p>Tuvastati <strong>${validErrors.length}</strong> teadet, mis ei vasta standardsetele vigadele ja vajavad käsitsi ülevaatamist:</p>
      <table style="width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 13px;">
        <thead>
          <tr style="background-color: #f5f5f5; text-align: left;">
            <th style="padding: 8px; border: 1px solid #ddd;">Arve number</th>
            <th style="padding: 8px; border: 1px solid #ddd;">Saaja e-post</th>
            <th style="padding: 8px; border: 1px solid #ddd;">Veateade / Põhjus</th>
          </tr>
        </thead>
        <tbody>
          ${rowsHtml}
        </tbody>
      </table>
      ${options.logId ? `<p style="margin-top: 14px; font-size: 13px; color: #666;">Logi ID süsteemis: ${options.logId}</p>` : ''}
    </div>
  `;

  let transporter = options.transporter;
  if (!transporter) {
    if (process.env.NODE_ENV === 'test') {
      console.log(
        `[read_mail] [TEST MODE] Skipping live SMTP alert send for ${otherErrors.length} error(s)`
      );
      return { messageId: '<test-alert-id@buh70.ee>', response: '250 Test OK' };
    }

    const smtpHost = process.env.SMTP_HOST || 'mail.narva.ee';
    const smtpPort = process.env.SMTP_PORT ? parseInt(process.env.SMTP_PORT, 10) : 25;
    const smtpUser = process.env.SMTP_USER || 'oppetasu';
    const smtpPass = process.env.SMTP_PASS || 'wbt5OcIhvmD8';
    const isSecure = smtpPort === 465;

    transporter = nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: isSecure,
      auth: {
        user: smtpUser,
        pass: smtpPass,
      },
      tls: {
        rejectUnauthorized: false,
      },
    });
  }

  try {
    const mailOptions = {
      from: process.env.REPORT_EMAIL_FROM || 'oppetasu@narva.ee',
      to: ALERT_EMAILS.join(', '),
      subject: 'buh70: E-posti kohaletoimetamise vead (Muud vead)',
      text: textContent,
      html: htmlContent,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(
      '[read_mail] "Muud vead" alert email sent successfully:',
      info.messageId || info.response
    );
    return info;
  } catch (sendErr: any) {
    console.error('[read_mail] Error sending "Muud vead" alert email:', sendErr.message);
    return null;
  }
}

