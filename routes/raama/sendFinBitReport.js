'use strict';
const nodemailer = require('nodemailer');
const db = require('./../../libs/db');
//const config = require('./../../config/default.json');
const config = require('./../../config/narvalv.json');

const DEFAULT_USER_ID = 2477;
const DEFAULT_REKV_ID = 63;
const FLOW_NAME = 'sendFinBitReport';

/**
 * Экранирование спецсимволов для HTML
 */
function escapeHtml(text) {
    if (!text) return '';
    return String(text)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

/**
 * Форматирование текстового тела письма
 */
function formatInvoiceEmailText(invoices = []) {
    let body = 'Tere!\n\n';
    body += 'Süsteemi on imporditud järgmised e-arved:\n\n';

    if (!invoices || invoices.length === 0) {
        body += 'Arveid ei leitud.\n';
    } else {
        invoices.forEach((inv, index) => {
            const nr = inv.number || '-';
            const agent = inv.kontr_agent || '-';
            const asutus = inv.asutus || '-';
            body += `${index + 1}. Arve nr: ${nr} | Hankija: ${agent} | Asutus: ${asutus}\n`;
        });
        body += `\nKokku: ${invoices.length} arve(t).\n`;
    }

    body += '\nLugupidamisega,\nBuh70';
    return body;
}

/**
 * Форматирование HTML тела письма
 */
function formatInvoiceEmailHtml(invoices = []) {
    const list = Array.isArray(invoices) ? invoices : [];
    let rowsHtml = '';

    if (list.length === 0) {
        rowsHtml = '<tr><td colspan="4" style="border: 1px solid #ddd; padding: 8px; text-align: center;">Arveid ei leitud</td></tr>';
    } else {
        rowsHtml = list.map((inv, idx) => {
            const nr = escapeHtml(inv.number || '-');
            const agent = escapeHtml(inv.kontr_agent || '-');
            const asutus = escapeHtml(inv.asutus || '-');
            return `<tr>
                <td style="border: 1px solid #ddd; padding: 8px; text-align: center;">${idx + 1}</td>
                <td style="border: 1px solid #ddd; padding: 8px;">${nr}</td>
                <td style="border: 1px solid #ddd; padding: 8px;">${agent}</td>
                <td style="border: 1px solid #ddd; padding: 8px;">${asutus}</td>
            </tr>`;
        }).join('\n');
    }

    return `<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
</head>
<body style="font-family: Arial, sans-serif; font-size: 14px; color: #333; line-height: 1.5;">
    <p>Tere!</p>
    <p>Süsteemi on imporditud järgmised e-arved:</p>
    <table style="border-collapse: collapse; width: 100%; max-width: 700px; margin: 15px 0;">
        <thead>
            <tr style="background-color: #f2f4f8;">
                <th style="border: 1px solid #ddd; padding: 8px; text-align: center; width: 40px;">#</th>
                <th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Arve number</th>
                <th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Hankija</th>
                <th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Asutus</th>
            </tr>
        </thead>
        <tbody>
            ${rowsHtml}
        </tbody>
    </table>
    <p>Kokku imporditud: <strong>${list.length}</strong> arve(t).</p>
    <p style="margin-top: 20px; color: #555;">
        Lugupidamisega,<br>
        <strong>Buh70</strong>
    </p>
</body>
</html>`;
}

/**
 * Определение адреса отправителя на основе имени пользователя SMTP
 */
function getSenderAddress(smtpUser) {
    if (!smtpUser) return 'noreply@narva.ee';
    if (smtpUser.includes('@')) return smtpUser;
    return `${smtpUser}@narva.ee`;
}

/**
 * Получение настроек SMTP из ou.userid или переменных окружения (fallback)
 */
async function getSmtpConfig(userId = DEFAULT_USER_ID) {
    if (process.env.SMTP_HOST) {
        const port = Number(process.env.SMTP_PORT) || 465;
        return {
            host: process.env.SMTP_HOST,
            port: port,
            secure: port === 465 || process.env.SMTP_SECURE === 'true',
            auth: process.env.SMTP_USER ? {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS
            } : undefined,
            from: process.env.SMTP_FROM || 'noreply@narva.ee',
            userName: 'Buh70 Robot'
        };
    }

    const sql = `SELECT 
                    coalesce(u.properties ->> 'smtp', 'smtp.zone.eu') AS smtp,
                    coalesce((u.properties ->> 'port')::integer, 465)  AS port,
                    u.properties ->> 'user'                           AS user,
                    u.properties ->> 'pass'                           AS pass,
                    coalesce(u.properties ->> 'email', 'noreply@narva.ee') AS email,
                    coalesce(ltrim(rtrim(u.ametnik)), u.kasutaja, 'Buh70') AS user_name
                 FROM ou.userid u 
                 WHERE u.id = $1
                 LIMIT 1`;

    try {
        const res = await db.queryDb(sql, [userId], null, null, null, null, config);
        if (res && res.data && res.data.length > 0) {
            const row = res.data[0];
            const port = Number(row.port) || 465;
            return {
                host: row.smtp || 'smtp.zone.eu',
                port: port,
                secure: port === 465,
                auth: (row.user && row.pass) ? {
                    user: row.user,
                    pass: row.pass
                } : undefined,
                from: row.email || 'noreply@narva.ee',
                userName: row.user_name || 'Buh70'
            };
        }
    } catch (e) {
        console.error('[sendFinBitReport] Error fetching SMTP config from DB:', e.message);
    }

    return {
        host: 'smtp.zone.eu',
        port: 465,
        secure: true,
        from: 'noreply@narva.ee',
        userName: 'Buh70'
    };
}

/**
 * Отправка одного письма получателю
 */
async function sendNotificationEmail(toEmail, invoices, smtpConfig, customTransporter = null) {
    if (!toEmail) {
        throw new Error('E-posti aadress puudub (email is missing)');
    }

    const transporter = customTransporter || nodemailer.createTransport({
        host: smtpConfig.host,
        port: smtpConfig.port,
        secure: smtpConfig.secure,
        auth: smtpConfig.auth,
        tls: {
            rejectUnauthorized: false
        }
    });

    const count = invoices ? invoices.length : 0;
    const subject = `Teavitus: imporditud e-arved (${count} tk)`;
    const text = formatInvoiceEmailText(invoices);
    const html = formatInvoiceEmailHtml(invoices);

    const mailOptions = {
        from: `"${smtpConfig.userName || 'Buh70'}" <${smtpConfig.from || 'noreply@narva.ee'}>`,
        to: toEmail,
        subject: subject,
        text: text,
        html: html
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(`[sendFinBitReport] Email sent to ${toEmail}, messageId: ${info && info.messageId}`);
    return info;
}

/**
 * Обработка массива отчета и отправка писем получателям.
 * Параметры SMTP (smtp, smtp_port, smtp_pass, smtp_user) берутся непосредственно из строки отчета.
 */
async function sendFinBitReportNotifications(reportResult, userId = DEFAULT_USER_ID, options = {}) {
    const rows = (reportResult && reportResult.data) ? reportResult.data : (Array.isArray(reportResult) ? reportResult : []);

    if (!rows || rows.length === 0) {
        console.log('[sendFinBitReport] No recipients or invoices found to send');
        return [];
    }

    let defaultSmtpConfig = options.smtpConfig || null;
    const customTransporter = options.transporter || null;
    const sendResults = [];

    for (const row of rows) {
        const recipientEmail = row.email || row.email_to;
        let invoices = row.arved;

        if (typeof invoices === 'string') {
            try {
                invoices = JSON.parse(invoices);
            } catch (err) {
                console.error('[sendFinBitReport] JSON parse error for arved:', err);
                invoices = [];
            }
        }

        if (!Array.isArray(invoices)) {
            invoices = invoices ? [invoices] : [];
        }

        if (!recipientEmail) {
            console.warn('[sendFinBitReport] Row has no email, skipping:', row);
            sendResults.push({
                email: null,
                invoicesCount: invoices.length,
                success: false,
                error: 'Recipient email is missing'
            });
            continue;
        }

        // Параметры SMTP берем из строки процедуры docs.get_arve_kinnitaja:
        // row.smtp, row.smtp_port, row.smtp_pass, row.smtp_user
        let smtpConfig;
        if (options.smtpConfig) {
            smtpConfig = options.smtpConfig;
        } else if (row.smtp) {
            const port = Number(row.smtp_port) || 465;
            const user = row.smtp_user;
            const pass = row.smtp_pass;
            const senderEmail = getSenderAddress(user);
            smtpConfig = {
                host: row.smtp,
                port: port,
                secure: port === 465,
                auth: (user && pass) ? {
                    user: user,
                    pass: pass
                } : undefined,
                from: senderEmail,
                userName: 'Buh70 Robot'
            };
        } else {
            if (!defaultSmtpConfig) {
                defaultSmtpConfig = await getSmtpConfig(userId);
            }
            smtpConfig = defaultSmtpConfig;
        }

        try {
            const info = await sendNotificationEmail(recipientEmail, invoices, smtpConfig, customTransporter);
            const serverResponse = (info && info.response) ? info.response : '250 OK';
            sendResults.push({
                email: recipientEmail,
                invoicesCount: invoices.length,
                success: true,
                messageId: info && info.messageId,
                response: serverResponse
            });
        } catch (mailErr) {
            console.error(`[sendFinBitReport] Failed to send email to ${recipientEmail}:`, mailErr.message);
            const serverResponse = mailErr.response || mailErr.message;
            sendResults.push({
                email: recipientEmail,
                invoicesCount: invoices.length,
                success: false,
                error: mailErr.message,
                response: serverResponse
            });
        }
    }

    return sendResults;
}

/**
 * Express handler для роута POST /task/sendFinBitReport/
 * Запускает отправку отчета асинхронно в фоне и сразу возвращает ответ с log_id
 * Пример вызова: curl.exe -X POST http://localhost:3000/task/sendFinBitReport/ -d '{"logId": 8129348, "user_id": 2477, "rekv_id": 63}'
 */
exports.main = async (req, res) => {
    const params = Object.assign({}, req.query, req.body, req.params);

    const paramLogId = Number(params.logId || params.log_id || params.paramLogId);
    const userId = Number(params.userId || params.user_id || params.userid_id) || DEFAULT_USER_ID;
    const rekvId = Number(params.rekvId || params.rekv_id) || DEFAULT_REKV_ID;

    let logId = null;

    console.log('[sendFinBitReport] start, paramLogId:', paramLogId, 'userId:', userId, 'rekvId:', rekvId);

    if (!paramLogId || isNaN(paramLogId)) {
        return res.status(400).send({
            status: 400,
            result: 0,
            log_id: null,
            data: null,
            error_message: 'Param logId is missing or invalid'
        });
    }

    try {
        // 1. Создаем запись в ou.logs о старте процесса
        const logResult = await createLog(rekvId, userId);
        if (logResult && logResult.data && logResult.data[0]) {
            logId = logResult.data[0].id;
        }

        if (!logId) {
            throw new Error('Лог-запись не создана (не удалось получить log_id)');
        }

        // 2. Запускаем фоновый процесс отправки БЕЗ ожидания завершения
        runCalculationInBackground(logId, paramLogId, userId, rekvId);

        // 3. Сразу возвращаем успешный ответ клиенту с log_id для отслеживания
        return res.status(200).send({
            status: 200,
            result: 1,
            log_id: logId,
            data: {
                action: FLOW_NAME,
                status: 'STARTED',
                log_id: logId
            },
            error_message: null
        });

    } catch (error) {
        console.error('Error starting sendFinBitReport task:', error);

        if (logId) {
            try {
                await endLog(logId, 'failed', error.message);
            } catch (logErr) {
                console.error('Failed to update log on startup error:', logErr);
            }
        }

        return res.status(500).send({
            status: 500,
            result: 0,
            log_id: logId,
            data: null,
            error_message: `Start report failed: ${error.message}`
        });
    }
};

/**
 * Фоновая асинхронная функция выполнения расчета и обновления статуса в ou.logs
 */
async function runCalculationInBackground(logId, paramLogId, userId = DEFAULT_USER_ID, rekvId = DEFAULT_REKV_ID, options = {}) {
    try {
        console.log(`[sendFinBitReport] Background calculation started. log_id: ${logId}, paramLogId: ${paramLogId}, userId: ${userId}`);
        const reportResult = await getReport(paramLogId);
        const sendResults = await sendFinBitReportNotifications(reportResult, userId, options);
        console.log(`[sendFinBitReport] Background calculation finished successfully. log_id: ${logId}`, sendResults);

        // Фиксируем успешное завершение с сохранением результатов отправки
        await endLog(logId, 'success', sendResults);
    } catch (error) {
        console.error(`[sendFinBitReport] Background calculation failed. log_id: ${logId}`, error);

        // Фиксируем ошибку в ou.logs
        try {
            await endLog(logId, 'failed', error.message);
        } catch (logErr) {
            console.error(`[sendFinBitReport] Failed to update error log for log_id: ${logId}`, logErr);
        }
    }
}

/**
 * Функция синхронного выполнения полного цикла расчета (для CLI и тестов)
 */
async function executeReport(userId = DEFAULT_USER_ID, rekvId = DEFAULT_REKV_ID, paramLogId, options = {}) {
    // Поддержка гибкого вызова executeReport(logId) или executeReport({ logId, userId, rekvId })
    if (typeof userId === 'number' && rekvId === DEFAULT_REKV_ID && paramLogId === undefined) {
        paramLogId = userId;
        userId = DEFAULT_USER_ID;
    } else if (typeof userId === 'object' && userId !== null) {
        const opts = userId;
        paramLogId = opts.logId || opts.log_id || opts.paramLogId;
        userId = opts.userId || opts.user_id || DEFAULT_USER_ID;
        rekvId = opts.rekvId || opts.rekv_id || DEFAULT_REKV_ID;
        options = opts.options || {};
    }

    if (!paramLogId) {
        throw new Error('Параметр logId отсутствует (logId is required)');
    }

    let logId = null;
    try {
        const logData = await createLog(rekvId, userId);
        logId = logData && logData.data && logData.data[0] ? logData.data[0].id : null;
        console.log('Created log id:', logId);

        const reportResult = await getReport(paramLogId);
        console.log('report result:', reportResult);

        // Отправка отчета по адресам получателей
        const sendResults = await sendFinBitReportNotifications(reportResult, userId, options);
        console.log('Send results:', sendResults);

        await endLog(logId, 'success', sendResults);
        console.log('Finished log id:', logId);
        return {
            logId,
            reportResult,
            sendResults
        };
    } catch (error) {
        if (logId) {
            try {
                await endLog(logId, 'failed', error.message);
            } catch (logErr) {
                console.error('Failed to update error log for log_id:', logId, logErr);
            }
        }
        throw error;
    }
}

/**
 * Получение списка счетов и получателей отчета
 */
async function getReport(logId) {
    const sql = `select * from docs.get_arve_kinnitaja($1)`;

    try {
        console.log('start getting report for logId:', logId);
        let l_result = await db.queryDb(sql, [logId], null, null, null, null, config);
        console.log('finish getting report', l_result);
        return l_result;
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

/**
 * Логгирование старта задачи
 */
async function createLog(rekvId = DEFAULT_REKV_ID, userId = DEFAULT_USER_ID) {
    const sql = `insert into ou.logs (rekvid, user_id, propertis)
                 values ($1, $2, jsonb_build_object('flow', $3::text, 'exec_start', (clock_timestamp())))
                 returning id;`;

    try {
        console.log('start create log for flow:', FLOW_NAME);
        let l_result = await db.queryDb(sql, [rekvId, userId, FLOW_NAME], null, null, null, null, config);
        console.log('finish create log', FLOW_NAME, l_result);
        return l_result;
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

/**
 * Логгирование окончания задачи (успех / ошибка)
 * Сохраняет статус, ошибку, результат отправки и ответ почтового сервера в ou.logs (поле propertis)
 */
async function endLog(logId, status = 'success', resultOrError = null, errorMessage = null) {
    if (!logId) return;

    let error = null;
    let result = null;
    let response = null;

    if (status === 'failed') {
        if (typeof resultOrError === 'string') {
            error = resultOrError;
        } else if (resultOrError instanceof Error) {
            error = resultOrError.message;
        } else if (resultOrError) {
            result = resultOrError;
            error = errorMessage || 'Execution failed';
        } else {
            error = errorMessage || 'Execution failed';
        }
    } else {
        // status === 'success'
        result = resultOrError;
        error = errorMessage || null;
    }

    // Извлекаем ответ почтового сервера для сохранения в логах
    if (Array.isArray(result) && result.length > 0) {
        response = result
            .map(r => (r.email ? `${r.email}: ` : '') + (r.response || (r.success ? 'OK' : 'Error')))
            .join('; ');
    } else if (result && typeof result === 'object' && result.response) {
        response = result.response;
    } else if (typeof result === 'string') {
        response = result;
    }

    let resultJson = null;
    if (result) {
        try {
            resultJson = typeof result === 'string' ? result : JSON.stringify(result);
        } catch (e) {
            resultJson = JSON.stringify({ raw: String(result) });
        }
    }

    const sql = `update ou.logs
                 set propertis = propertis || jsonb_build_object(
                     'exec_end', (clock_timestamp()),
                     'status', $1::text,
                     'error', $2::text
                 )
                 || case when $3::text is not null then jsonb_build_object('result', $3::jsonb) else '{}'::jsonb end
                 || case when $4::text is not null then jsonb_build_object('response', $4::text) else '{}'::jsonb end
                 where id = $5;`;

    try {
        console.log('start endLog for id:', logId, 'status:', status, 'response:', response);
        await db.queryDb(sql, [status, error, resultJson, response, logId], null, null, null, null, config);
        console.log('finish endLog');
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

// Алиас для вызова под именем endReport
const endReport = endLog;

exports.FLOW_NAME = FLOW_NAME;
exports.DEFAULT_USER_ID = DEFAULT_USER_ID;
exports.DEFAULT_REKV_ID = DEFAULT_REKV_ID;
exports.executeReport = executeReport;
exports.getReport = getReport;
exports.getSmtpConfig = getSmtpConfig;
exports.getSenderAddress = getSenderAddress;
exports.sendNotificationEmail = sendNotificationEmail;
exports.sendFinBitReportNotifications = sendFinBitReportNotifications;
exports.formatInvoiceEmailText = formatInvoiceEmailText;
exports.formatInvoiceEmailHtml = formatInvoiceEmailHtml;
exports.createLog = createLog;
exports.endLog = endLog;
exports.endReport = endReport;
exports.runCalculationInBackground = runCalculationInBackground;

// Запуск при прямом вызове из командной строки (CLI)
if (require.main === module) {
    const argLogId = process.argv[2] ? Number(process.argv[2]) : null;
    executeReport(DEFAULT_USER_ID, DEFAULT_REKV_ID, argLogId)
        .then((result) => {
            console.log('Finished sendFinBitReport successfully:', result);
            process.exit(0);
        })
        .catch((error) => {
            console.error('Error in sendFinBitReport execution:', error);
            process.exit(1);
        });
}
