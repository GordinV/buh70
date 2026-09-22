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
        : '❌';

    const statusLabel =
      step.status === 'SUCCESS'
        ? 'ÕNNESTUS'
        : step.status === 'SKIPPED'
        ? 'VAHELE JÄETUD'
        : step.status === 'TIMEOUT'
        ? 'AEGUS'
        : 'EBAÕNNESTUS';

    const cleanSummary = sanitizeReportText(step.resultSummary);
    const cleanError = sanitizeReportText(step.error);

    md += `- ${icon} **${step.stepName}**: \`${statusLabel}\``;
    if (step.logId) md += ` (logi ID: ${step.logId})`;
    if (step.durationMs) md += ` (kestus: ${(step.durationMs / 1000).toFixed(1)} s)`;
    if (cleanSummary) md += `\n  - *Tulemus:* ${cleanSummary}`;
    if (cleanError) md += `\n  - *Viga:* ${cleanError}`;
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
      step.status === 'SUCCESS' ? '#2e7d32' : step.status === 'SKIPPED' ? '#757575' : '#d32f2f';

    const statusLabel =
      step.status === 'SUCCESS'
        ? 'Õnneestus'
        : step.status === 'SKIPPED'
        ? 'Vahele jäetud'
        : step.status === 'TIMEOUT'
        ? 'Aegus'
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
        <td style="padding: 8px; border-bottom: 1px solid #ddd;">${step.logId ? step.logId : '—'}</td>
        <td style="padding: 8px; border-bottom: 1px solid #ddd;">${step.durationMs ? (step.durationMs / 1000).toFixed(1) + ' s' : '—'}</td>
        <td style="padding: 8px; border-bottom: 1px solid #ddd; color: #d32f2f;">${cleanError ? cleanError : '—'}</td>
      </tr>
    `;
  }

  const cleanNotes = sanitizeReportText(input.notes);

  return `
    <div style="font-family: Arial, sans-serif; max-width: 680px; margin: 0 auto; color: #333;">
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
            <th style="padding: 8px; border-bottom: 2px solid #ddd;">Logi ID</th>
            <th style="padding: 8px; border-bottom: 2px solid #ddd;">Kestus</th>
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
