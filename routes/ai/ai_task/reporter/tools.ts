import nodemailer, { Transporter } from 'nodemailer';
import { getConfig } from '../shared/api_client';
import {
  GenerateReportInput,
  GenerateReportInputSchema,
  SendReportResponse,
  SendReportResponseSchema,
} from './schemas';

export interface SendEmailOptions {
  transporter?: Transporter;
}

/**
 * Puhastab ja teisendab teksti eesti keelde, tagades, et lõpparuandes poleks venekeelseid fraase.
 */
export function sanitizeReportText(text?: string | null): string | undefined {
  if (!text) return undefined;
  const trimmed = text.trim();
  if (!trimmed) return undefined;

  // Kui tekst ei sisalda kirillitsat, tagastame muutmata kujul
  if (!/[\u0400-\u04FF]/.test(trimmed)) {
    return trimmed;
  }

  const lower = trimmed.toLowerCase();

  // Eraldame tehnilised detailid (ingliskeelsed veateated, emailid, serverid, koodid)
  const techMatches = trimmed.match(
    /([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}|ETIMEDOUT[^\s,)]*|ECONN[^\s,)]*|HTTP\s*\d+|status:\s*\w+)/gi
  );
  const techDetails = techMatches ? techMatches.join('; ') : '';

  const isSuccess =
    lower.includes('выполнен') ||
    lower.includes('успешн') ||
    lower.includes('завершен') ||
    lower.includes('без ошибок');

  if (isSuccess) {
    if (lower.includes('расчет') || lower.includes('все ') || lower.includes('arvestus')) {
      return 'Kõik rutiinsed arvestused on edukalt lõpetatud.';
    }
    return 'Edukalt täidetud';
  }

  const isFailed =
    lower.includes('ошибк') ||
    lower.includes('сбо') ||
    lower.includes('не удалось') ||
    lower.includes('таймаут') ||
    lower.includes('провал');

  if (isFailed) {
    if (lower.includes('расчет') || lower.includes('все ') || lower.includes('arvestus')) {
      return 'Mõned rutiinsed arvestused lõppesid vigadega.';
    }
    return techDetails ? `Täitmisel ilmnesid vead: ${techDetails}` : 'Täitmisel ilmnesid vead';
  }

  return techDetails || 'Edukalt täidetud';
}

/**
 * Formats an ISO date/time string into a human-readable local Tallinn time (DD.MM.YYYY HH:mm:ss)
 */
export function formatDateTime(isoOrDateStr?: string | null, timezone = 'Europe/Tallinn'): string {
  if (!isoOrDateStr) return '—';
  try {
    const d = new Date(isoOrDateStr);
    if (isNaN(d.getTime())) return String(isoOrDateStr);
    return new Intl.DateTimeFormat('et-EE', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
    }).format(d);
  } catch {
    return String(isoOrDateStr);
  }
}

/**
 * Форматирует отчет в удобный текстовый Markdown-вид на эстонском языке
 * (без отображения ID пользователя и учреждения)
 */
export function formatReportMarkdown(input: GenerateReportInput): string {
  const statusIcon = input.overallSuccess ? '✅ ÕNNESTUS' : '❌ VIGA';
  let md = `# buh70 AI-Orkestraatori rutiinsete arvestuste aruanne\n\n`;
  md += `**Staatus:** ${statusIcon}\n`;
  md += `**Kuupäev:** ${input.executionDate}\n\n`;
  md += `### Täitmise etapid:\n\n`;

  for (const step of input.steps) {
    const icon =
      step.status === 'SUCCESS'
        ? '✅'
        : step.status === 'SKIPPED'
        ? '⏭️'
        : step.status === 'RUNNING'
        ? '⏳'
        : step.status === 'PENDING'
        ? '🕒'
        : '❌';

    const statusLabel =
      step.status === 'SUCCESS'
        ? 'ÕNNESTUS'
        : step.status === 'SKIPPED'
        ? 'VAHELE JÄETUD'
        : step.status === 'TIMEOUT'
        ? 'AEGUS'
        : step.status === 'RUNNING'
        ? 'TÖÖS'
        : step.status === 'PENDING'
        ? 'OOTEL'
        : 'EBAÕNNESTUS';

    const cleanSummary = sanitizeReportText(step.resultSummary);
    const cleanError = sanitizeReportText(step.error);

    md += `- ${icon} **${step.stepName}**: \`${statusLabel}\``;
    if (step.logId) md += ` (logi ID: ${step.logId})`;
    if (step.durationMs) md += ` (kestus: ${(step.durationMs / 1000).toFixed(1)} s)`;
    if (step.execStart) md += `\n  - *Algus:* ${formatDateTime(step.execStart)}`;
    if (step.execEnd) md += `\n  - *Lõpp:* ${formatDateTime(step.execEnd)}`;
    if (cleanSummary) md += `\n  - *Tulemus:* ${cleanSummary}`;
    if (cleanError) md += `\n  - *Viga:* ${cleanError}`;

    if (step.mailErrors && step.mailErrors.length > 0) {
      md += `\n  - *Tuvastatud vigased e-posti aadressid (${step.mailErrors.length} tk):*\n`;
      for (const me of step.mailErrors) {
        const nr = me.doc_number || me.invoice_number || 'N/A';
        const em = me.recipient_email || '—';
        const st = me.status || 'Muud vead';
        const rsn = me.reason || '—';
        md += `    - Arve: \`${nr}\` | Saaja: \`${em}\` | Staatus: \`${st}\` | Põhjus: ${rsn}\n`;
      }
    }
    md += `\n`;
  }

  const cleanNotes = sanitizeReportText(input.notes);
  if (cleanNotes) {
    md += `\n**Märkused:** ${cleanNotes}\n`;
  }

  return md;
}

/**
 * Форматирует отчет в чистый HTML для почтовых клиентов на эстонском языке
 * (без отображения ID пользователя и учреждения)
 */
export function formatReportHtml(input: GenerateReportInput): string {
  const statusColor = input.overallSuccess ? '#2e7d32' : '#d32f2f';
  const statusText = input.overallSuccess ? 'ÕNNESTUS' : 'VIGA';

  let rowsHtml = '';
  for (const step of input.steps) {
    const stepColor =
      step.status === 'SUCCESS'
        ? '#2e7d32'
        : step.status === 'SKIPPED'
        ? '#757575'
        : step.status === 'RUNNING'
        ? '#1976d2'
        : step.status === 'PENDING'
        ? '#f57c00'
        : '#d32f2f';

    const statusLabel =
      step.status === 'SUCCESS'
        ? 'Õnnestus'
        : step.status === 'SKIPPED'
        ? 'Vahele jäetud'
        : step.status === 'TIMEOUT'
        ? 'Aegus'
        : step.status === 'RUNNING'
        ? 'Töös'
        : step.status === 'PENDING'
        ? 'Ootel'
        : 'Ebaõnnestus';

    const cleanSummary = sanitizeReportText(step.resultSummary);
    const cleanError = sanitizeReportText(step.error);

    rowsHtml += `
      <tr>
        <td style="padding: 8px; border-bottom: 1px solid #ddd;">
          <strong>${step.stepName}</strong>
          ${cleanSummary ? `<br/><span style="font-size: 12px; color: #555;">${cleanSummary}</span>` : ''}
        </td>
        <td style="padding: 8px; border-bottom: 1px solid #ddd; color: ${stepColor}; font-weight: bold;">${statusLabel}</td>
        <td style="padding: 8px; border-bottom: 1px solid #ddd;">${formatDateTime(step.execStart)}</td>
        <td style="padding: 8px; border-bottom: 1px solid #ddd;">${formatDateTime(step.execEnd)}</td>
        <td style="padding: 8px; border-bottom: 1px solid #ddd;">${step.durationMs ? (step.durationMs / 1000).toFixed(1) + ' s' : '—'}</td>
        <td style="padding: 8px; border-bottom: 1px solid #ddd;">${step.logId ? step.logId : '—'}</td>
        <td style="padding: 8px; border-bottom: 1px solid #ddd; color: #d32f2f;">${cleanError ? cleanError : '—'}</td>
      </tr>
    `;

    if (step.mailErrors && step.mailErrors.length > 0) {
      rowsHtml += `
      <tr>
        <td colspan="7" style="padding: 8px 16px 12px 16px; background-color: #fafafa; border-bottom: 2px solid #ddd;">
          <div style="font-size: 13px; font-weight: bold; margin-bottom: 6px; color: #444;">
            📧 Tuvastatud vigased e-posti aadressid (${step.mailErrors.length} tk):
          </div>
          <table style="width: 100%; border-collapse: collapse; font-size: 12px; background: #fff;">
            <thead>
              <tr style="background: #f0f0f0; text-align: left;">
                <th style="padding: 4px 8px; border: 1px solid #ddd;">Arve nr</th>
                <th style="padding: 4px 8px; border: 1px solid #ddd;">Saaja e-post</th>
                <th style="padding: 4px 8px; border: 1px solid #ddd;">Staatus</th>
                <th style="padding: 4px 8px; border: 1px solid #ddd;">Veateade / Põhjus</th>
              </tr>
            </thead>
            <tbody>
              ${step.mailErrors
                .map(
                  (me) => `
                <tr>
                  <td style="padding: 4px 8px; border: 1px solid #ddd; font-weight: bold;">${me.doc_number || me.invoice_number || 'N/A'}</td>
                  <td style="padding: 4px 8px; border: 1px solid #ddd;">${me.recipient_email || '—'}</td>
                  <td style="padding: 4px 8px; border: 1px solid #ddd; color: #d32f2f; font-weight: bold;">${me.status || 'Muud vead'}</td>
                  <td style="padding: 4px 8px; border: 1px solid #ddd; color: #555;">${me.reason || '—'}</td>
                </tr>
              `
                )
                .join('')}
            </tbody>
          </table>
        </td>
      </tr>
      `;
    }
  }

  const cleanNotes = sanitizeReportText(input.notes);

  return `
    <div style="font-family: Arial, sans-serif; max-width: 760px; margin: 0 auto; color: #333;">
      <h2 style="color: #1976d2; border-bottom: 2px solid #1976d2; padding-bottom: 8px;">
        buh70 rutiinsete arvestuste aruanne
      </h2>
      <p style="font-size: 16px;">
        <strong>Üldine staatus:</strong> 
        <span style="color: ${statusColor}; font-weight: bold; padding: 4px 8px; background-color: #f5f5f5; border-radius: 4px;">
          ${statusText}
        </span>
      </p>
      <p><strong>Kuupäev:</strong> ${input.executionDate}</p>

      <table style="width: 100%; border-collapse: collapse; margin-top: 16px;">
        <thead>
          <tr style="background-color: #f5f5f5; text-align: left;">
            <th style="padding: 8px; border-bottom: 2px solid #ddd;">Ülesanne</th>
            <th style="padding: 8px; border-bottom: 2px solid #ddd;">Staatus</th>
            <th style="padding: 8px; border-bottom: 2px solid #ddd;">Algus</th>
            <th style="padding: 8px; border-bottom: 2px solid #ddd;">Lõpp</th>
            <th style="padding: 8px; border-bottom: 2px solid #ddd;">Kestus</th>
            <th style="padding: 8px; border-bottom: 2px solid #ddd;">Logi ID</th>
            <th style="padding: 8px; border-bottom: 2px solid #ddd;">Viga</th>
          </tr>
        </thead>
        <tbody>
          ${rowsHtml}
        </tbody>
      </table>

      ${cleanNotes ? `<p style="margin-top: 16px; color: #666;"><em>Märkused: ${cleanNotes}</em></p>` : ''}
      <hr style="margin-top: 24px; border: none; border-top: 1px solid #eee;" />
      <p style="font-size: 12px; color: #999;">Genereeritud automaatselt buh70 AI-Orkestraatori poolt</p>
    </div>
  `;
}

/**
 * Отправляет отчет на электронную почту через SMTP
 */
export async function sendReportEmail(
  input: GenerateReportInput,
  options: SendEmailOptions = {}
): Promise<SendReportResponse> {
  const validated = GenerateReportInputSchema.parse(input);
  const formattedReport = formatReportMarkdown(validated);
  const config = getConfig();

  const targetEmail = validated.recipientEmail || config.reportEmailTo;

  // Если SMTP или получатель не сконфигурированы, делаем fallback на консольный лог
  if (!config.smtpHost || !targetEmail) {
    console.log(
      `[reporter] ⚠️ Hoiatus: SMTP_HOST või REPORT_EMAIL_TO ei ole seadistatud ai_task/.env failis. Aruannet ei saadetud e-postiga ja väljastati konsooli:\n${formattedReport}`
    );
    return SendReportResponseSchema.parse({
      sent: true,
      deliveryChannel: 'local_fallback',
      timestamp: new Date().toISOString(),
      formattedReport,
    });
  }

  const statusText = validated.overallSuccess ? 'ÕNNESTUS' : 'VIGA';
  const subject = `[buh70] Rutiinne arvestus ${validated.executionDate}: ${statusText}`;

  const transporter =
    options.transporter ||
    nodemailer.createTransport({
      host: config.smtpHost,
      port: config.smtpPort,
      secure: config.smtpSecure,
      auth: config.smtpUser
        ? {
            user: config.smtpUser,
            pass: config.smtpPass,
          }
        : undefined,
      tls: {
        rejectUnauthorized: false,
      },
    });

  const mailOptions = {
    from: config.reportEmailFrom,
    to: targetEmail,
    subject,
    text: formattedReport,
    html: formatReportHtml(validated),
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`[reporter] Aruanne edukalt saadetud e-posti aadressile: ${targetEmail} (Message ID: ${info.messageId})`);

    return SendReportResponseSchema.parse({
      sent: true,
      deliveryChannel: 'email',
      timestamp: new Date().toISOString(),
      formattedReport,
      recipientEmail: targetEmail,
      messageId: info.messageId,
    });
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    console.error(`[reporter] Viga e-kirja saatmisel SMTP kaudu aadressile ${targetEmail}: ${errorMsg}`);
    return SendReportResponseSchema.parse({
      sent: false,
      deliveryChannel: 'local_fallback',
      timestamp: new Date().toISOString(),
      formattedReport,
      recipientEmail: targetEmail,
    });
  }
}
