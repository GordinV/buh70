import { z } from 'zod';
import { AsyncTaskStartResponseSchema } from '../shared/types';

export const TASK_FLOW_READ_MAIL = 'mail.read_mail_errors';
export const DEFAULT_INITIAL_SINCE_DATE = '2026-10-01T00:00:00.000Z';

/**
 * Допустимые категории статусов ошибок доставки счетов клиенту
 */
export const MailDeliveryStatusEnum = z.enum([
  'Aadressi viga',
  'Domeeni viga',
  'Postkast täis',
  'Muud vead',
]);

export type MailDeliveryStatus = z.infer<typeof MailDeliveryStatusEnum>;

/**
 * Схема единичной записи об ошибке доставки счета клиенту
 */
export const MailDeliveryErrorSchema = z.object({
  status: MailDeliveryStatusEnum.describe('Статус ошибки: Aadressi viga, Domeeni viga, Postkast täis, Muud vead'),
  reason: z.string().describe('Причина ошибки доставки (например, "Domain lookup error")'),
  doc_number: z.string().describe('Номер счета / документа (например, "101-10772")'),
  invoice_number: z.string().describe('Синоним поля doc_number для обратной совместимости'),
  recipient_email: z.string().describe('Электронный адрес получателя счета'),
  reference_number: z.string().optional().describe('Ссылочный номер счета (viitenumber), если присутствует'),
  failed_at: z.string().optional().describe('Дата/время отправки или ошибки доставки'),
  source_subject: z.string().optional().describe('Тема исходного или пересланного письма'),
});

export type MailDeliveryError = z.infer<typeof MailDeliveryErrorSchema>;

/**
 * Параметры доступа к почтовому серверу по аналогии с automailer.js
 */
export const MailAccessConfigSchema = z.object({
  host: z.string().optional().describe('Почтовый сервер (IMAP host, например mail.narva.ee)'),
  port: z.number().default(993).describe('Порт подключения (993 для SSL)'),
  secure: z.boolean().default(true).describe('Флаг SSL/TLS'),
  user: z.string().default('oppetasu').describe('Имя пользователя (l_user из automailer.js)'),
  pass: z.string().default('').describe('Пароль к ящику (l_pass из automailer.js / ou.userid)'),
  rejectUnauthorized: z.boolean().default(false).describe('tls.rejectUnauthorized (по аналогии с automailer.js)'),
  userMail: z.string().default('oppetasu@narva.ee').describe('Email адрес (l_user_mail из automailer.js)'),
  userName: z.string().default('Õppetasu').describe('Имя владельца (l_user_name из automailer.js)'),
  userId: z.number().default(11558).describe('ID пользователя (l_userId из automailer.js)'),
  mailbox: z.string().default('INBOX').describe('Папка почтового ящика (по умолчанию "INBOX")'),
});

export type MailAccessConfig = z.infer<typeof MailAccessConfigSchema>;

/**
 * Состояние фиксации прочитанных писем (read_mail_state.json)
 */
export const ReadMailStateSchema = z.object({
  sinceDate: z.string().default(DEFAULT_INITIAL_SINCE_DATE),
  lastReadDate: z.string().nullable().optional().describe('Дата самого нового прочитанного письма (ISO)'),
  lastReadUid: z.number().nullable().optional().describe('UID последнего прочитанного письма'),
  lastReadMessageId: z.string().nullable().optional().describe('Message-ID последнего письма'),
  lastRunAt: z.string().nullable().optional().describe('Время последнего запуска агента'),
  totalProcessedCount: z.number().default(0).describe('Всего обработано новых писем'),
});

export type ReadMailState = z.infer<typeof ReadMailStateSchema>;

/**
 * Структурированное представление входящего письма
 */
export const RawIncomingEmailSchema = z.object({
  uid: z.number().optional().default(0),
  messageId: z.string().optional(),
  date: z.union([z.date(), z.string()]),
  subject: z.string().optional(),
  from: z.string().optional(),
  text: z.string(),
});

export type RawIncomingEmail = z.infer<typeof RawIncomingEmailSchema>;

/**
 * Входные параметры субагента read_mail
 */
export const ReadMailInputSchema = z.object({
  logId: z.number().optional().describe('ID записи в ou.logs, если уже создана бэкендом'),
  mailAccess: MailAccessConfigSchema.optional().describe('Параметры доступа к почте'),
  sinceDate: z.string().optional().describe('Начальная дата (по умолчанию "2026-10-01T00:00:00.000Z")'),
  stateFilePath: z.string().optional().describe('Пользовательский путь к файлу состояния read_mail_state.json'),
  emailContent: z.string().optional().describe('Текст одного письма для ручного вызова'),
  emails: z.array(z.string()).optional().describe('Массив текстов писем'),
  rawEmails: z.array(RawIncomingEmailSchema).optional().describe('Структурированные письма для тестирования'),
  userId: z.number().default(2477).describe('ID пользователя buh70'),
  rekvId: z.number().default(63).describe('ID учреждения buh70'),
  useAi: z.boolean().default(true).describe('Флаг использования LLM для анализа сложных писем'),
  forceSinceDate: z.boolean().default(false).describe('Принудительно начать с sinceDate, игнорируя сохраненный state'),
});

export type ReadMailInput = z.input<typeof ReadMailInputSchema>;

/**
 * Схема ответа бэкенда при вызове POST /task/readMail/
 */
export const StartReadMailResponseSchema = AsyncTaskStartResponseSchema;
export type StartReadMailResponse = z.infer<typeof StartReadMailResponseSchema>;

/**
 * Итоговый результат работы агента - массив объектов ошибок доставки
 */
export const ReadMailResultSchema = z.array(MailDeliveryErrorSchema);
export type ReadMailResult = z.infer<typeof ReadMailResultSchema>;
