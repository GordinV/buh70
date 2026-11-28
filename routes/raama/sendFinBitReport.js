'use strict';
const nodemailer = require('nodemailer');
const db = require('./../../libs/db');
//const config = require('./../../config/default.json');
const config = require('./../../config/narvalv.json');

const DEFAULT_USER_ID = 2477;
const DEFAULT_REKV_ID = 63;
const FLOW_NAME = 'sendFinBitReport';
// flow лога импорта (agent import_earved): по нему и по result.imported работает docs.get_arve_kinnitaja
const IMPORT_FLOW_NAME = 'docs.sp_loe_earved';

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
function formatInvoiceEmailText(invoices) {
    if (!invoices) invoices = [];
    var body = 'Tere!\n\n';
    body += 'Süsteemi on imporditud järgmised e-arved:\n\n';

    if (!invoices || invoices.length === 0) {
        body += 'Arveid ei leitud.\n';
    } else {
        invoices.forEach(function(inv, index) {
            var nr = (inv && inv.number) ? inv.number : '-';
            var agent = (inv && inv.kontr_agent) ? inv.kontr_agent : '-';
            var asutus = (inv && inv.asutus) ? inv.asutus : '-';
            body += (index + 1) + '. Arve nr: ' + nr + ' | Hankija: ' + agent + ' | Asutus: ' + asutus + '\n';
        });
        body += '\nKokku: ' + invoices.length + ' arve(t).\n';
    }

    body += '\nLugupidamisega,\nBuh70';
    return body;
}

/**
 * Форматирование HTML тела письма
 */
function formatInvoiceEmailHtml(invoices) {
    var list = Array.isArray(invoices) ? invoices : [];
    var rowsHtml = '';

    if (list.length === 0) {
        rowsHtml = '<tr><td colspan="4" style="border: 1px solid #ddd; padding: 8px; text-align: center;">Arveid ei leitud</td></tr>';
    } else {
        rowsHtml = list.map(function(inv, idx) {
            var nr = escapeHtml((inv && inv.number) ? inv.number : '-');
            var agent = escapeHtml((inv && inv.kontr_agent) ? inv.kontr_agent : '-');
            var asutus = escapeHtml((inv && inv.asutus) ? inv.asutus : '-');
            return '<tr>' +
                '<td style="border: 1px solid #ddd; padding: 8px; text-align: center;">' + (idx + 1) + '</td>' +
                '<td style="border: 1px solid #ddd; padding: 8px;">' + nr + '</td>' +
                '<td style="border: 1px solid #ddd; padding: 8px;">' + agent + '</td>' +
                '<td style="border: 1px solid #ddd; padding: 8px;">' + asutus + '</td>' +
            '</tr>';
        }).join('\n');
    }

    return '<!DOCTYPE html>\n' +
'<html>\n' +
'<head>\n' +
'    <meta charset="utf-8">\n' +
'</head>\n' +
'<body style="font-family: Arial, sans-serif; font-size: 14px; color: #333; line-height: 1.5;">\n' +
'    <p>Tere!</p>\n' +
'    <p>Süsteemi on imporditud järgmised e-arved:</p>\n' +
'    <table style="border-collapse: collapse; width: 100%; max-width: 700px; margin: 15px 0;">\n' +
'        <thead>\n' +
'            <tr style="background-color: #f2f4f8;">\n' +
'                <th style="border: 1px solid #ddd; padding: 8px; text-align: center; width: 40px;">#</th>\n' +
'                <th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Arve number</th>\n' +
'                <th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Hankija</th>\n' +
'                <th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Asutus</th>\n' +
'            </tr>\n' +
'        </thead>\n' +
'        <tbody>\n' +
'            ' + rowsHtml + '\n' +
'        </tbody>\n' +
'    </table>\n' +
'    <p>Kokku imporditud: <strong>' + list.length + '</strong> arve(t).</p>\n' +
'    <p style="margin-top: 20px; color: #555;">\n' +
'        Lugupidamisega,<br>\n' +
'        <strong>Buh70</strong>\n' +
'    </p>\n' +
'</body>\n' +
'</html>';
}

/**
 * Определение адреса отправителя на основе имени пользователя SMTP
 */
function getSenderAddress(smtpUser) {
    if (!smtpUser) return 'noreply@narva.ee';
    if (smtpUser.includes('@')) return smtpUser;
    return smtpUser + '@narva.ee';
}

/**
 * Получение настроек SMTP из ou.userid или переменных окружения (fallback)
 */
async function getSmtpConfig(userId) {
    if (userId === undefined || userId === null) userId = DEFAULT_USER_ID;

    if (process.env.SMTP_HOST) {
        var port = Number(process.env.SMTP_PORT) || 465;
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

    var sql = 'SELECT ' +
        'coalesce(u.properties ->> \'smtp\', \'smtp.zone.eu\') AS smtp, ' +
        'coalesce((u.properties ->> \'port\')::integer, 465)  AS port, ' +
        'u.properties ->> \'user\'                           AS user, ' +
        'u.properties ->> \'pass\'                           AS pass, ' +
        'coalesce(u.properties ->> \'email\', \'noreply@narva.ee\') AS email, ' +
        'coalesce(ltrim(rtrim(u.ametnik)), u.kasutaja, \'Buh70\') AS user_name ' +
        'FROM ou.userid u ' +
        'WHERE u.id = $1 ' +
        'LIMIT 1';

    try {
        var res = await db.queryDb(sql, [userId], null, null, null, null, config);
        if (res && res.data && res.data.length > 0) {
            var row = res.data[0];
            var rowPort = Number(row.port) || 465;
            return {
                host: row.smtp || 'smtp.zone.eu',
                port: rowPort,
                secure: rowPort === 465,
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
 * Получение настроек SMTP из карточки робота ('Earved robot') в ou.userid.
 * Не использует properties.email — отправитель формируется из properties.user (по умолчанию palk@narva.ee).
 */
async function getRobotSmtpConfig(rekvId) {
    var targetRekvId = (rekvId !== undefined && rekvId !== null) ? Number(rekvId) : DEFAULT_REKV_ID;
    var sql = 'SELECT ' +
        "coalesce(u.properties ->> 'smtp', 'smtp.zone.eu') AS smtp, " +
        "coalesce((u.properties ->> 'port')::integer, 465) AS port, " +
        "coalesce(nullif(ltrim(rtrim(u.properties ->> 'user')), ''), 'palk') AS user, " +
        "u.properties ->> 'pass' AS pass " +
        'FROM ou.userid u ' +
        "WHERE u.kasutaja = 'Earved robot' AND u.status < 3 AND u.rekvid IN ($1, 63) " +
        'ORDER BY CASE WHEN u.rekvid = $1 THEN 0 ELSE 1 END, u.id DESC ' +
        'LIMIT 1';

    var res = await db.queryDb(sql, [targetRekvId], null, null, null, null, config);
    if (!res || !Array.isArray(res.data) || res.data.length === 0) {
        throw new Error('smtp_config_not_found');
    }
    var row = res.data[0];
    var rowPort = Number(row.port) || 465;
    var user = row.user || 'palk';
    var pass = row.pass;
    return {
        host: row.smtp || 'smtp.zone.eu',
        port: rowPort,
        secure: rowPort === 465,
        auth: pass ? {
            user: user,
            pass: pass
        } : undefined,
        from: getSenderAddress(user),
        userName: 'Buh70 Robot'
    };
}

/**
 * Получение настроек почтовой учетной записи (SMTP + IMAP) строго из карточки ou.userid по id (без process.env).
 */
async function getUserMailAccount(userId) {
    if (userId === undefined || userId === null) {
        throw new Error('mail_account_not_found');
    }

    var sql = 'SELECT ' +
        "u.properties ->> 'smtp' AS smtp, " +
        "(u.properties ->> 'port')::integer AS port, " +
        "ltrim(rtrim(u.properties ->> 'user')) AS user, " +
        "u.properties ->> 'pass' AS pass, " +
        "coalesce(nullif(ltrim(rtrim(u.properties ->> 'imap')), ''), 'mail.narva.ee') AS imap, " +
        "coalesce((u.properties ->> 'imap_port')::integer, 993) AS imap_port, " +
        "coalesce(nullif(ltrim(rtrim(u.properties ->> 'imap_mailbox')), ''), 'INBOX') AS imap_mailbox " +
        'FROM ou.userid u ' +
        'WHERE u.id = $1 ' +
        'LIMIT 1';

    var res = await db.queryDb(sql, [Number(userId)], null, null, null, null, config);
    if (!res || !Array.isArray(res.data) || res.data.length === 0) {
        throw new Error('mail_account_not_found');
    }

    var row = res.data[0];
    var user = row.user ? String(row.user).trim() : '';
    var pass = row.pass ? String(row.pass) : '';
    if (!user || !pass) {
        throw new Error('mail_password_missing');
    }

    var smtpHost = row.smtp ? String(row.smtp).trim() : 'mail.narva.ee';
    var smtpPort = Number(row.port) || 465;
    var imapHost = row.imap ? String(row.imap).trim() : 'mail.narva.ee';
    var imapPort = Number(row.imap_port) || 993;
    var imapMailbox = row.imap_mailbox ? String(row.imap_mailbox).trim() : 'INBOX';

    return {
        smtp: {
            host: smtpHost,
            port: smtpPort,
            secure: smtpPort === 465,
            auth: {
                user: user,
                pass: pass
            },
            from: getSenderAddress(user)
        },
        imap: {
            host: imapHost,
            port: imapPort,
            secure: true,
            user: user,
            pass: pass,
            mailbox: imapMailbox
        }
    };
}

/**
 * Отправка одного письма получателю
 */
async function sendNotificationEmail(toEmail, invoices, smtpConfig, customTransporter) {
    if (customTransporter === undefined) customTransporter = null;

    if (!toEmail) {
        throw new Error('E-posti aadress puudub (email is missing)');
    }

    var transporter = customTransporter || nodemailer.createTransport({
        host: smtpConfig.host,
        port: smtpConfig.port,
        secure: smtpConfig.secure,
        auth: smtpConfig.auth,
        tls: {
            rejectUnauthorized: false
        }
    });

    var count = invoices ? invoices.length : 0;
    var subject = 'Teavitus: imporditud e-arved (' + count + ' tk)';
    var text = formatInvoiceEmailText(invoices);
    var html = formatInvoiceEmailHtml(invoices);

    var mailOptions = {
        from: '"' + (smtpConfig.userName || 'Buh70') + '" <' + (smtpConfig.from || 'noreply@narva.ee') + '>',
        to: toEmail,
        subject: subject,
        text: text,
        html: html
    };

    var info = await transporter.sendMail(mailOptions);
    console.log('[sendFinBitReport] Email sent to ' + toEmail + ', messageId: ' + (info && info.messageId));
    return info;
}

/**
 * Универсальная отправка письма (html + text) одному или нескольким получателям
 * @param {string|string[]} toEmails
 * @param {string} subject
 * @param {string} text
 * @param {string} html
 * @param {Object} smtpConfig результат getSmtpConfig
 * @param {Object} [customTransporter]
 */
async function sendHtmlEmail(toEmails, subject, text, html, smtpConfig, customTransporter, attachments) {
    if (customTransporter === undefined) customTransporter = null;
    var recipients = Array.isArray(toEmails) ? toEmails.filter(Boolean) : (toEmails ? [toEmails] : []);

    if (recipients.length === 0) {
        throw new Error('E-posti aadress puudub (email is missing)');
    }

    var transporter = customTransporter || nodemailer.createTransport({
        host: smtpConfig.host,
        port: smtpConfig.port,
        secure: smtpConfig.secure,
        auth: smtpConfig.auth,
        tls: {
            rejectUnauthorized: false
        }
    });

    var mailOptions = {
        from: '"' + (smtpConfig.userName || 'Buh70') + '" <' + (smtpConfig.from || 'noreply@narva.ee') + '>',
        to: recipients.join(', '),
        subject: subject,
        text: text,
        html: html
    };
    if (Array.isArray(attachments) && attachments.length > 0) {
        mailOptions.attachments = attachments;
    }

    var info = await transporter.sendMail(mailOptions);
    console.log('[sendFinBitReport] Email sent to ' + recipients.join(', ') + ', messageId: ' + (info && info.messageId));
    return info;
}

// Адреса-заглушки в карточках пользователей: на них письма не отправляются (решение пользователя 2026-11-28)
var BLOCKED_EMAILS = ['vigane@narva.ee'];

function isBlockedEmail(email) {
    return !!email && BLOCKED_EMAILS.indexOf(String(email).trim().toLowerCase()) !== -1;
}

/**
 * Обработка массива отчета и отправка писем получателям.
 * Параметры SMTP (smtp, smtp_port, smtp_pass, smtp_user) берутся непосредственно из строки отчета.
 */
async function sendFinBitReportNotifications(reportResult, userId, options) {
    if (userId === undefined || userId === null) userId = DEFAULT_USER_ID;
    if (!options) options = {};

    var rows = (reportResult && reportResult.data) ? reportResult.data : (Array.isArray(reportResult) ? reportResult : []);

    if (!rows || rows.length === 0) {
        console.log('[sendFinBitReport] No recipients or invoices found to send');
        return [];
    }

    var defaultSmtpConfig = options.smtpConfig || null;
    var customTransporter = options.transporter || null;
    // адреса, которым письмо по этому же импорту уже отправлено ранее (идемпотентность повтора)
    var alreadySent = options.alreadySent || {};
    var sendResults = [];

    for (var i = 0; i < rows.length; i++) {
        var row = rows[i];
        var recipientEmail = row.email || row.email_to;
        var invoices = row.arved;

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

        if (isBlockedEmail(recipientEmail)) {
            // адрес-заглушка: письмо не отправляем; это не сбой рассылки, повтор не нужен
            console.warn('[sendFinBitReport] Blocked recipient address, skipping: ' + recipientEmail);
            sendResults.push({
                email: recipientEmail,
                invoicesCount: invoices.length,
                success: true,
                skipped: true,
                response: 'Aadress on blokeeritud, kirja ei saadetud'
            });
            continue;
        }

        if (alreadySent[String(recipientEmail).trim().toLowerCase()]) {
            // повтор после частичного сбоя: этому получателю письмо уже ушло, второй раз не шлем
            sendResults.push({
                email: recipientEmail,
                invoicesCount: invoices.length,
                success: true,
                already_sent: true,
                response: 'Juba saadetud (eelmine katse)'
            });
            continue;
        }

        var smtpConfig;
        if (options.smtpConfig) {
            smtpConfig = options.smtpConfig;
        } else if (row.smtp) {
            var port = Number(row.smtp_port) || 465;
            var user = row.smtp_user;
            var pass = row.smtp_pass;
            var senderEmail = getSenderAddress(user);
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
            var info = await sendNotificationEmail(recipientEmail, invoices, smtpConfig, customTransporter);
            var serverResponse = (info && info.response) ? info.response : '250 OK';
            sendResults.push({
                email: recipientEmail,
                invoicesCount: invoices.length,
                success: true,
                messageId: info && info.messageId,
                response: serverResponse
            });
        } catch (mailErr) {
            console.error('[sendFinBitReport] Failed to send email to ' + recipientEmail + ':', mailErr.message);
            var errResponse = mailErr.response || mailErr.message;
            sendResults.push({
                email: recipientEmail,
                invoicesCount: invoices.length,
                success: false,
                error: mailErr.message,
                response: errResponse
            });
        }
    }

    return sendResults;
}

/**
 * Express handler для роута POST /task/sendFinBitReport/
 * Запускает отправку отчета асинхронно в фоне и сразу возвращает ответ с log_id
 */
exports.main = async function(req, res) {
    var params = Object.assign({}, req.query, req.body, req.params);

    var paramLogId = Number(params.logId || params.log_id || params.paramLogId);
    var userId = Number(params.userId || params.user_id || params.userid_id) || DEFAULT_USER_ID;
    var rekvId = Number(params.rekvId || params.rekv_id) || DEFAULT_REKV_ID;

    var logId = null;

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
        var logResult = await createLog(rekvId, userId, paramLogId);
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
                await endLog(logId, 'failed', error.message, undefined, {retryable: true});
            } catch (logErr) {
                console.error('Failed to update log on startup error:', logErr);
            }
        }

        return res.status(500).send({
            status: 500,
            result: 0,
            log_id: logId,
            data: null,
            error_message: 'Start report failed: ' + error.message
        });
    }
};

/**
 * Чтение сведений о логе импорта (flow docs.sp_loe_earved): сколько документов реально создано.
 * Источник - структурированный result.imported; для логов старого формата - result.totalImported.
 * @returns {Promise<{found: boolean, flow: (string|null), importedCount: number}>}
 */
async function getImportInfo(importLogId) {
    var sql = 'select l.propertis ->> \'flow\' as flow, ' +
        'l.propertis -> \'result\' -> \'imported\' as imported, ' +
        'l.propertis -> \'result\' ->> \'totalImported\' as total_imported ' +
        'from ou.logs l where l.id = $1';

    try {
        var r = await db.queryDb(sql, [importLogId], null, null, null, null, config);
        var row = r && Array.isArray(r.data) && r.data[0] ? r.data[0] : null;
        if (!row) {
            return {found: false, flow: null, importedCount: 0};
        }
        var importedCount = 0;
        if (Array.isArray(row.imported)) {
            importedCount = row.imported.length;
        } else if (row.total_imported !== undefined && row.total_imported !== null) {
            importedCount = Number(row.total_imported) || 0;
        }
        return {found: true, flow: row.flow || null, importedCount: importedCount};
    } catch (error) {
        throw new Error('DB Query failed: ' + error.message);
    }
}

/**
 * Адреса, которым письмо по этому же импорту (source_log_id) уже успешно отправлено предыдущими запусками.
 * Ошибка чтения не критична: в худшем случае письмо уйдет повторно, поэтому возвращаем пустой набор.
 * @returns {Promise<Object>} {email_lowercase: true}
 */
async function getAlreadySentEmails(sourceLogId, currentLogId) {
    var sent = {};
    var sql = 'select l.propertis -> \'result\' as result ' +
        'from ou.logs l ' +
        'where l.propertis ->> \'flow\' = $1 ' +
        'and l.propertis ->> \'source_log_id\' = $2::text ' +
        'and l.id <> $3';

    try {
        var r = await db.queryDb(sql, [FLOW_NAME, sourceLogId, currentLogId || 0], null, null, null, null, config);
        var rows = r && Array.isArray(r.data) ? r.data : [];
        rows.forEach(function(row) {
            var results = row && Array.isArray(row.result) ? row.result : [];
            results.forEach(function(item) {
                if (item && item.success === true && item.email) {
                    sent[String(item.email).trim().toLowerCase()] = true;
                }
            });
        });
    } catch (error) {
        console.warn('[sendFinBitReport] Could not read previous send results:', error.message);
    }
    return sent;
}

/**
 * Итоговый статус рассылки по результатам отправки писем.
 * Все письма ушли (в т.ч. в прошлых попытках) -> success.
 * Есть неотправленные -> failed; retryable=false, если ни одну ошибку повтором не вылечить (нет адреса получателя).
 */
function evaluateSendResults(sendResults) {
    var failures = [];
    for (var i = 0; i < sendResults.length; i++) {
        if (!sendResults[i] || !sendResults[i].success) {
            failures.push(sendResults[i] || {});
        }
    }

    if (failures.length === 0) {
        return {status: 'success', errorMessage: null, retryable: null};
    }

    var retryable = failures.some(function(f) {
        return f.error !== 'Recipient email is missing';
    });
    var errorMessage = failures.length === sendResults.length
        ? 'Kõik teavituste saatmised ebaõnnestusid (vigu: ' + failures.length + ')'
        : 'Mõnede teavituste saatmisel ilmnesid vead (vigu: ' + failures.length + ' / ' + sendResults.length + ')';
    return {status: 'failed', errorMessage: errorMessage, retryable: retryable};
}

/**
 * Полный цикл рассылки по логу импорта paramLogId.
 * Возвращает итог для записи в ou.logs; исключения (БД и т.п.) пробрасываются вызывающему.
 *
 * Правила:
 *  - лог импорта не найден / не того flow            -> failed, retryable=false
 *  - импорт не создал ни одного документа            -> success (no_op), рассылки нет: "нет новых счетов" - штатная ситуация
 *  - документы есть, а получателей нет               -> failed, retryable=false
 *  - письма отправлены                               -> см. evaluateSendResults
 */
async function processReport(paramLogId, userId, currentLogId, options) {
    var importInfo = await getImportInfo(paramLogId);

    if (!importInfo.found || importInfo.flow !== IMPORT_FLOW_NAME) {
        return {
            status: 'failed',
            errorMessage: 'Impordi logi ei leitud (logId: ' + paramLogId + ', oodatud flow: ' + IMPORT_FLOW_NAME + ')',
            retryable: false,
            sendResults: [],
            reportResult: null,
            noOp: false
        };
    }

    if (importInfo.importedCount === 0) {
        console.log('[sendFinBitReport] Import log ' + paramLogId + ' created no documents, nothing to send');
        return {
            status: 'success',
            errorMessage: null,
            retryable: null,
            sendResults: [],
            reportResult: null,
            noOp: true,
            response: 'Uusi arveid ei imporditud, teavitusi ei saadetud'
        };
    }

    var reportResult = await getReport(paramLogId);
    var rows = (reportResult && reportResult.data) ? reportResult.data : (Array.isArray(reportResult) ? reportResult : []);

    if (!rows || rows.length === 0) {
        console.warn('[sendFinBitReport] Warning: imported ' + importInfo.importedCount + ' invoices, but no recipients for logId ' + paramLogId);
        return {
            status: 'failed',
            errorMessage: 'Imporditud ' + importInfo.importedCount + ' arvet, kuid saajaid ei leitud (docs.get_arve_kinnitaja tagastas 0 kirjet)',
            retryable: false,
            sendResults: [],
            reportResult: reportResult,
            noOp: false
        };
    }

    var alreadySent = await getAlreadySentEmails(paramLogId, currentLogId);
    var sendOptions = Object.assign({}, options, {alreadySent: alreadySent});
    var sendResults = await sendFinBitReportNotifications(reportResult, userId, sendOptions);
    var verdict = evaluateSendResults(sendResults);

    return {
        status: verdict.status,
        errorMessage: verdict.errorMessage,
        retryable: verdict.retryable,
        sendResults: sendResults,
        reportResult: reportResult,
        noOp: false
    };
}

/**
 * Дополнительные ключи propertis для лога рассылки по итогу processReport
 */
function buildLogExtra(outcome) {
    var extra = {};
    if (outcome.status === 'failed' && outcome.retryable !== null && outcome.retryable !== undefined) {
        extra.retryable = outcome.retryable;
    }
    if (outcome.noOp) {
        extra.no_op = true;
    }
    if (outcome.response) {
        extra.response = outcome.response;
    }
    return extra;
}

/**
 * Фоновая асинхронная функция выполнения расчета и обновления статуса в ou.logs
 */
async function runCalculationInBackground(logId, paramLogId, userId, rekvId, options) {
    if (userId === undefined || userId === null) userId = DEFAULT_USER_ID;
    if (rekvId === undefined || rekvId === null) rekvId = DEFAULT_REKV_ID;
    if (!options) options = {};

    try {
        console.log('[sendFinBitReport] Background calculation started. log_id: ' + logId + ', paramLogId: ' + paramLogId + ', userId: ' + userId);
        var outcome = await processReport(paramLogId, userId, logId, options);
        console.log('[sendFinBitReport] Background calculation finished. log_id: ' + logId, outcome.sendResults);

        // Фиксируем завершение с сохранением результатов отправки и статуса
        await endLog(logId, outcome.status, outcome.sendResults, outcome.errorMessage, buildLogExtra(outcome));
    } catch (error) {
        console.error('[sendFinBitReport] Background calculation failed. log_id: ' + logId, error);

        // Фиксируем ошибку в ou.logs (БД, сеть - временные ошибки, повтор имеет смысл)
        try {
            await endLog(logId, 'failed', error.message, undefined, {retryable: true});
        } catch (logErr) {
            console.error('[sendFinBitReport] Failed to update error log for log_id: ' + logId, logErr);
        }
    }
}

/**
 * Функция синхронного выполнения полного цикла расчета (для CLI и тестов)
 */
async function executeReport(userId, rekvId, paramLogId, options) {
    if (userId === undefined || userId === null) userId = DEFAULT_USER_ID;
    if (rekvId === undefined || rekvId === null) rekvId = DEFAULT_REKV_ID;
    if (!options) options = {};

    // Поддержка гибкого вызова executeReport(logId) или executeReport({ logId, userId, rekvId })
    if (typeof userId === 'number' && rekvId === DEFAULT_REKV_ID && paramLogId === undefined) {
        paramLogId = userId;
        userId = DEFAULT_USER_ID;
    } else if (typeof userId === 'object' && userId !== null) {
        var opts = userId;
        paramLogId = opts.logId || opts.log_id || opts.paramLogId;
        userId = opts.userId || opts.user_id || DEFAULT_USER_ID;
        rekvId = opts.rekvId || opts.rekv_id || DEFAULT_REKV_ID;
        options = opts.options || {};
    }

    if (!paramLogId) {
        throw new Error('Параметр logId отсутствует (logId is required)');
    }

    var logId = null;
    try {
        var logData = await createLog(rekvId, userId, paramLogId);
        logId = logData && logData.data && logData.data[0] ? logData.data[0].id : null;
        console.log('Created log id:', logId);

        var outcome = await processReport(paramLogId, userId, logId, options);
        console.log('Send results:', outcome.sendResults);

        await endLog(logId, outcome.status, outcome.sendResults, outcome.errorMessage, buildLogExtra(outcome));
        console.log('Finished log id:', logId);
        return {
            logId: logId,
            status: outcome.status,
            noOp: outcome.noOp,
            reportResult: outcome.reportResult,
            sendResults: outcome.sendResults
        };
    } catch (error) {
        if (logId) {
            try {
                await endLog(logId, 'failed', error.message, undefined, {retryable: true});
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
    var sql = 'select * from docs.get_arve_kinnitaja($1)';

    try {
        console.log('start getting report for logId:', logId);
        var l_result = await db.queryDb(sql, [logId], null, null, null, null, config);
        console.log('finish getting report', l_result);
        return l_result;
    } catch (error) {
        throw new Error('DB Query failed: ' + error.message);
    }
}

/**
 * Логгирование старта задачи
 */
async function createLog(rekvId, userId, sourceLogId) {
    if (rekvId === undefined || rekvId === null) rekvId = DEFAULT_REKV_ID;
    if (userId === undefined || userId === null) userId = DEFAULT_USER_ID;
    var sourceId = Number(sourceLogId) > 0 ? Number(sourceLogId) : null;

    // source_log_id - id лога импорта, по которому идет рассылка (нужен для идемпотентности повторов)
    var sql = 'insert into ou.logs (rekvid, user_id, propertis) ' +
        'values ($1, $2, jsonb_build_object(\'flow\', $3::text, \'exec_start\', (clock_timestamp())) ' +
        '|| case when $4::integer is not null then jsonb_build_object(\'source_log_id\', $4::integer) else \'{}\'::jsonb end) ' +
        'returning id;';

    try {
        console.log('start create log for flow:', FLOW_NAME);
        var l_result = await db.queryDb(sql, [rekvId, userId, FLOW_NAME, sourceId], null, null, null, null, config);
        console.log('finish create log', FLOW_NAME, l_result);
        return l_result;
    } catch (error) {
        throw new Error('DB Query failed: ' + error.message);
    }
}

/**
 * Логгирование окончания задачи (успех / ошибка)
 * Сохраняет статус, ошибку, результат отправки и ответ почтового сервера в ou.logs (поле propertis)
 */
async function endLog(logId, status, resultOrError, errorMessage, extra) {
    if (!logId) return;
    if (!status) status = 'success';
    if (resultOrError === undefined) resultOrError = null;
    if (errorMessage === undefined) errorMessage = null;

    var error = null;
    var result = null;
    var response = null;

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
        result = resultOrError;
        error = errorMessage || null;
    }

    // Извлекаем ответ почтового сервера для сохранения в логах
    if (Array.isArray(result) && result.length > 0) {
        response = result
            .map(function(r) { return (r.email ? (r.email + ': ') : '') + (r.response || (r.success ? 'OK' : 'Error')); })
            .join('; ');
    } else if (result && typeof result === 'object' && result.response) {
        response = result.response;
    } else if (typeof result === 'string') {
        response = result;
    }

    // extra: retryable, no_op и явный response (например, "нет новых счетов")
    var extraJson = null;
    if (extra && typeof extra === 'object') {
        var extraProps = Object.assign({}, extra);
        if (extraProps.response) {
            response = extraProps.response;
        }
        delete extraProps.response;
        if (Object.keys(extraProps).length > 0) {
            extraJson = JSON.stringify(extraProps);
        }
    }

    var resultJson = null;
    if (result) {
        try {
            resultJson = typeof result === 'string' ? result : JSON.stringify(result);
        } catch (e) {
            resultJson = JSON.stringify({ raw: String(result) });
        }
    }

    var sql = 'update ou.logs ' +
        'set propertis = propertis || jsonb_build_object(' +
        '\'exec_end\', (clock_timestamp()), ' +
        '\'status\', $1::text, ' +
        '\'error\', $2::text' +
        ') ' +
        '|| case when $3::text is not null then jsonb_build_object(\'result\', $3::jsonb) else \'{}\'::jsonb end ' +
        '|| case when $4::text is not null then jsonb_build_object(\'response\', $4::text) else \'{}\'::jsonb end ' +
        '|| case when $6::text is not null then ($6::text)::jsonb else \'{}\'::jsonb end ' +
        'where id = $5;';

    try {
        console.log('start endLog for id:', logId, 'status:', status, 'response:', response);
        await db.queryDb(sql, [status, error, resultJson, response, logId, extraJson], null, null, null, null, config);
        console.log('finish endLog');
    } catch (error) {
        throw new Error('DB Query failed: ' + error.message);
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
exports.getRobotSmtpConfig = getRobotSmtpConfig;
exports.getUserMailAccount = getUserMailAccount;
exports.getSenderAddress = getSenderAddress;
exports.sendNotificationEmail = sendNotificationEmail;
exports.sendHtmlEmail = sendHtmlEmail;
exports.escapeHtml = escapeHtml;
exports.sendFinBitReportNotifications = sendFinBitReportNotifications;
exports.formatInvoiceEmailText = formatInvoiceEmailText;
exports.formatInvoiceEmailHtml = formatInvoiceEmailHtml;
exports.createLog = createLog;
exports.endLog = endLog;
exports.endReport = endReport;
exports.runCalculationInBackground = runCalculationInBackground;
exports.processReport = processReport;
exports.getImportInfo = getImportInfo;
exports.getAlreadySentEmails = getAlreadySentEmails;
exports.evaluateSendResults = evaluateSendResults;
exports.IMPORT_FLOW_NAME = IMPORT_FLOW_NAME;
exports.BLOCKED_EMAILS = BLOCKED_EMAILS;
exports.isBlockedEmail = isBlockedEmail;

// Запуск при прямом вызове из командной строки (CLI)
if (require.main === module) {
    var argLogId = process.argv[2] ? Number(process.argv[2]) : null;
    executeReport(DEFAULT_USER_ID, DEFAULT_REKV_ID, argLogId)
        .then(function(result) {
            console.log('Finished sendFinBitReport successfully:', result);
            process.exit(0);
        })
        .catch(function(error) {
            console.error('Error in sendFinBitReport execution:', error);
            process.exit(1);
        });
}
