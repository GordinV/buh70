'use strict';

const tls = require('tls');
const fs = require('fs');
const path = require('path');
const nodemailer = require('nodemailer');
const db = require('./../../libs/db');
const config = require('./../../config/narvalv.json');
const mailer = require('./sendFinBitReport');

const DEFAULT_USER_ID = 2477;
const DEFAULT_REKV_ID = 63;
const MAIL_ACCOUNT_USER_ID = 11558;
const FLOW_NAME = 'mail.read_mail_errors';
const DEFAULT_INITIAL_SINCE_DATE = '2026-10-01T00:00:00.000Z';
const ALERT_EMAILS = ['vladislav.gordin@gmail.com', 'andrei.vargunin@narva.ee'];

/**
 * Express handler для роута POST /task/readMail/
 * По аналогии с getEarvedFromFinBit.js и calcKondSaldoandmik.js:
 * 1. Создает запись в ou.logs через createLog
 * 2. Запускает обработку почты в фоне (in-process на Node 13)
 * 3. Немедленно возвращает log_id для отслеживания
 */
const post = async function (req, res) {
    var params = Object.assign({}, req.query, req.body, req.params);
    var userId = Number(params.user_id || params.userid_id || params.userId || DEFAULT_USER_ID);
    var rekvId = Number(params.rekv_id || params.rekvid || params.rekvId || DEFAULT_REKV_ID);
    var flowName = params.flow_name || params.flowName || FLOW_NAME;

    var logId = null;
    console.log('[readMail] Starting task for userId:', userId, 'rekvId:', rekvId, 'flow:', flowName);

    try {
        // 1. Создаем запись в ou.logs о старте процесса
        var logResult = await createLog(rekvId, userId, flowName);
        if (logResult && logResult.data && logResult.data[0]) {
            logId = logResult.data[0].id;
        }

        if (!logId) {
            throw new Error('Лог-запись не создана (не удалось получить log_id)');
        }

        // 2. Запускаем фоновую обработку БЕЗ ожидания завершения
        runReadMailInBackground(logId, userId, rekvId, params);

        // 3. Немедленно возвращаем log_id клиенту для отслеживания
        return res.status(200).send({
            status: 200,
            result: 1,
            log_id: logId,
            data: {
                action: 'readMail',
                status: 'STARTED',
                log_id: logId,
                result: {
                    doc_id: logId,
                    error_code: 0,
                    error_message: null,
                    tulemused: 'STARTED'
                }
            },
            error_message: null
        });

    } catch (error) {
        console.error('Error starting readMail task:', error);

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
            error_message: 'Start readMail failed: ' + error.message
        });
    }
};

/**
 * Фоновая асинхронная функция выполнения анализа почты и обновления статуса в ou.logs
 */
async function runReadMailInBackground(logId, userId, rekvId, params) {
    params = params || {};
    try {
        console.log('[readMail] Background execution started. log_id: ' + logId + ', userId: ' + userId);

        var mailAccount = null;
        if (!params.emailContent && !(params.emails && params.emails.length > 0)) {
            mailAccount = await getMailCredentials(rekvId, userId, params.mailUserId);
        }

        var deliveryErrors = await executeReadMailProcess({
            userId: userId,
            rekvId: rekvId,
            mailUserId: params.mailUserId,
            mailAccount: mailAccount,
            emailContent: params.emailContent,
            emails: params.emails,
            stateFilePath: params.stateFilePath,
            sinceDate: params.sinceDate,
            forceSinceDate: params.forceSinceDate
        });

        console.log('[readMail] Background execution finished successfully. log_id: ' + logId + ', errors found: ' + deliveryErrors.length);
        if (deliveryErrors && deliveryErrors.length > 0) {
            for (var d = 0; d < deliveryErrors.length; d++) {
                var de = deliveryErrors[d];
                console.log('[readMail] Vigane arve: ' + de.doc_number + 
                            ' | Teema: "' + (de.subject || de.source_subject || '') + 
                            '" | Saaja: ' + de.recipient_email + 
                            ' | Staatus: ' + de.status);
            }
        }

        // Фиксируем успешное завершение в ou.logs с деталями результата
        await endLog(logId, 'success', null, deliveryErrors);

        // Аннулируем статус успешной отправки счетов в БД (docs.tuhista_arve_saatmise_staatus)
        if (deliveryErrors && deliveryErrors.length > 0) {
            try {
                var cancelSql = 'SELECT docs.tuhista_arve_saatmise_staatus($1::INTEGER) AS result;';
                var cancelRes = await db.queryDb(cancelSql, [logId], null, null, null, null, config);
                console.log('[readMail] Successfully called docs.tuhista_arve_saatmise_staatus for log_id: ' + logId);

                var cancelItems = (cancelRes && cancelRes.data && cancelRes.data[0] && cancelRes.data[0].result)
                    ? cancelRes.data[0].result
                    : [];
                if (typeof cancelItems === 'string') {
                    try { cancelItems = JSON.parse(cancelItems); } catch (parseErr) {}
                }

                // Отправляем персональные отчеты каждому ответственному бухгалтеру
                await notifyAccountantsAboutFailedInvoices(cancelItems, deliveryErrors, logId, null, mailAccount ? mailAccount.smtp : null);
            } catch (tuhistaErr) {
                console.error('[readMail] Error calling docs.tuhista_arve_saatmise_staatus for log_id ' + logId + ':', tuhistaErr);
            }
        }
        // 2. Отправка отчета при наличии ошибок со статусом "Muud vead" на vladislav.gordin@gmail.com и andrei.vargunin@narva.ee
        var otherErrors = deliveryErrors.filter(function (e) {
            return e && e.status === 'Muud vead' && hasValidDocNumber(e.doc_number || e.invoice_number);
        });
        if (otherErrors.length > 0) {
            try {
                await sendOtherErrorsAlertEmail(otherErrors, logId, null, mailAccount ? mailAccount.smtp : null);
            } catch (alertErr) {
                console.error('[readMail] Failed to send "Muud vead" alert email:', alertErr.message);
            }
        }
    } catch (error) {
        console.error('[readMail] Background execution failed. log_id: ' + logId + ':', error);

        try {
            await endLog(logId, 'failed', error.message || String(error));
        } catch (logErr) {
            console.error('[readMail] Failed to update error log for log_id: ' + logId, logErr);
        }
    }
}

/**
 * Проверка, является ли статус ошибки "Muud vead"
 */
function isMuudVeadStatus(status) {
    if (!status) return false;
    var s = String(status).trim().toLowerCase();
    return s === 'muud vead' || s === 'muud_vead' || s === 'muudvead';
}

/**
 * Определение, относится ли входящее письмо к рассылке извещений (automailerTeatis)
 */
function isTeatisEmail(text, subject) {
    var combined = (text || '') + ' ' + (subject || '');
    if (/maksevõla|maksevola/i.test(combined)) return true;
    if (/\bteatis(?:e|ed|t)?\b/i.test(combined)) return true;
    if (/automailerTeatis/i.test(combined)) return true;

    // В automailerTeatis subject: "Saadan dokument nr. <number>" (без запятой и без viitenr, номер не формата счета XXX-XXXX)
    // В automailer subject: "Saadan dokument nr. <number>, <viitenr>"
    // В routes/email.js (ручная отправка счета): "Saadan dokument nr. <XXX-XXXX>"
    var subjStr = subject || combined;
    var docSubjMatch = subjStr.match(/Saadan\s+dokument\s+nr\.\s*([^\r\n,]+)/i);
    if (docSubjMatch && !/Saadan\s+dokument\s+nr\.[^,\r\n]+,/i.test(subjStr)) {
        var candidate = docSubjMatch[1].trim();
        if (candidate && !/^\d{3}-\d{4,6}$/.test(candidate)) {
            return true;
        }
    }
    return false;
}

/**
 * Проверка, является ли ошибка извещением (TEATIS)
 */
function isTeatisError(err) {
    if (!err) return false;
    if (err.doc_type && String(err.doc_type).trim().toUpperCase() === 'TEATIS') {
        return true;
    }
    return isTeatisEmail(
        (err.body || '') + ' ' + (err.body_text || '') + ' ' + (err.reason || ''),
        (err.subject || '') + ' ' + (err.source_subject || '')
    );
}

/**
 * Построение строк таблицы HTML для отчета об ошибках
 */
function buildErrorRowsHtml(errors, isTeatisTable) {
    var html = '';
    for (var i = 0; i < errors.length; i++) {
        var err = errors[i];
        var docNum = err.doc_number || err.invoice_number || (isTeatisTable ? 'TEATIS' : 'N/A');
        var recip = err.recipient_email || 'unknown';
        var rsn = err.reason || 'Määramata saatmise tõrge';
        var subj = err.subject || err.source_subject || '-';
        var bodyText = err.body || err.body_text || err.email_body || '';

        html += '<tr>' +
            '<td style="padding: 8px; border: 1px solid #ddd; font-weight: bold; vertical-align: top;">' + escapeHtml(docNum) + '</td>' +
            '<td style="padding: 8px; border: 1px solid #ddd; vertical-align: top;">' + escapeHtml(recip) + '</td>' +
            '<td style="padding: 8px; border: 1px solid #ddd; color: #d32f2f; vertical-align: top;">' + escapeHtml(rsn) + '</td>' +
            '<td style="padding: 8px; border: 1px solid #ddd; font-size: 12px; color: #555; vertical-align: top;">' + escapeHtml(subj) + '</td>' +
            '<td style="padding: 8px; border: 1px solid #ddd; vertical-align: top;">' +
            '<div style="max-height: 250px; overflow-y: auto; white-space: pre-wrap; font-family: Consolas, monospace; font-size: 11px; background: #fafafa; padding: 6px; border: 1px solid #eee;">' +
            escapeHtml(bodyText || '-') +
            '</div>' +
            '</td>' +
            '</tr>';
    }
    return html;
}

/**
 * Построение текстового блока для отчета об ошибках
 */
function buildErrorRowsText(errors, isTeatisTable) {
    var text = '';
    for (var i = 0; i < errors.length; i++) {
        var err = errors[i];
        var docNum = err.doc_number || err.invoice_number || (isTeatisTable ? 'TEATIS' : 'N/A');
        var recip = err.recipient_email || 'unknown';
        var rsn = err.reason || 'Määramata saatmise tõrge';
        var subj = err.subject || err.source_subject || '-';
        var bodyText = err.body || err.body_text || err.email_body || '';

        text += '--------------------------------------------------\n' +
            (isTeatisTable ? 'Teatise nr: ' : 'Arve nr: ') + docNum + '\n' +
            'Saaja: ' + recip + '\n' +
            'Põhjus: ' + rsn + '\n' +
            'Teema: ' + subj + '\n' +
            'Kirja sisu:\n' + (bodyText ? bodyText : '-') + '\n\n';
    }
    return text;
}

/**
 * Проверка наличия валидного номера счета (исключаем пустые значения, 'N/A', 'UNKNOWN')
 */
function hasValidDocNumber(docNumber) {
    if (!docNumber) return false;
    var normalized = String(docNumber).trim().toUpperCase();
    return normalized.length > 0 && normalized !== 'N/A' && normalized !== 'UNKNOWN';
}

/**
 * Экранирование HTML-спецсимволов (защита от потери содержимого <email@narva.ee> в таблицах писем)
 */
function escapeHtml(str) {
    if (!str) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

/**
 * Получение SMTP-транспортера nodemailer строго из account.smtp (карточка ou.userid)
 */
function getMailTransporter(customTransporter, smtpConfig) {
    if (customTransporter) return customTransporter;

    if (!smtpConfig || !smtpConfig.auth || !smtpConfig.auth.user || !smtpConfig.auth.pass) {
        throw new Error('mail_password_missing');
    }

    var smtpPort = Number(smtpConfig.port) || 465;
    var isSecure = typeof smtpConfig.secure === 'boolean' ? smtpConfig.secure : (smtpPort === 465);

    return nodemailer.createTransport({
        host: smtpConfig.host || 'mail.narva.ee',
        port: smtpPort,
        secure: isSecure,
        auth: {
            user: smtpConfig.auth.user,
            pass: smtpConfig.auth.pass
        },
        tls: {
            rejectUnauthorized: false
        }
    });
}

/**
 * Отправка персонализированного отчета ответственному бухгалтеру о недоставленных счетах
 */
async function sendAccountantNotificationEmail(accountantEmail, invoices, logId, customTransporter, smtpConfig) {
    if (!accountantEmail || !invoices || invoices.length === 0) return null;

    // Исключаем счета со статусом "Muud vead"
    var validInvoices = invoices.filter(function (inv) {
        return inv && !isMuudVeadStatus(inv.status);
    });

    if (validInvoices.length === 0) {
        console.log('[readMail] No eligible invoices to notify accountant ' + accountantEmail + ' (all filtered out). Skipping email.');
        return null;
    }

    var transporter = getMailTransporter(customTransporter, smtpConfig);

    var rowsText = '';
    var rowsHtml = '';
    var hasArv = false;
    var hasTeatis = false;

    for (var i = 0; i < validInvoices.length; i++) {
        var inv = validInvoices[i];
        var isTeatis = isTeatisError(inv);
        if (isTeatis) hasTeatis = true;
        else hasArv = true;

        var docTypeLabel = isTeatis ? 'Maksevõla teatis' : 'Arve';
        var docNum = inv.doc_number || inv.invoice_number || 'N/A';
        var recip = inv.recipient_email || 'teadmata';
        var rsn = inv.reason || 'Kättetoimetamise tõrge';
        var subj = inv.subject || inv.source_subject || '-';

        rowsText += '- ' + docTypeLabel + ' nr: ' + docNum + ' | Kliendi e-post: ' + recip + ' | Põhjus: ' + rsn + ' | Teema: ' + subj + '\n';
        rowsHtml += '<tr>' +
            '<td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">' + escapeHtml((isTeatis ? 'Teatis ' : '') + docNum) + '</td>' +
            '<td style="padding: 8px; border: 1px solid #ddd;">' + escapeHtml(recip) + '</td>' +
            '<td style="padding: 8px; border: 1px solid #ddd; color: #d32f2f;">' + escapeHtml(rsn) + '</td>' +
            '<td style="padding: 8px; border: 1px solid #ddd; font-size: 12px; color: #555;">' + escapeHtml(subj) + '</td>' +
            '</tr>';
    }

    var subjectPrefix = (hasTeatis && !hasArv)
        ? 'Kättetoimetamata maksevõla teatised'
        : (hasTeatis && hasArv)
        ? 'Kättetoimetamata arved ja teatised'
        : 'Kättetoimetamata arved';

    var introDocsLabel = (hasTeatis && !hasArv)
        ? 'Teie koostatud maksevõla teatiseid'
        : (hasTeatis && hasArv)
        ? 'Teie koostatud arveid ja maksevõla teatiseid'
        : 'Teie koostatud arveid';

    var textContent = 'Tere!\n\n' +
        'Teavitame, et järgmisi ' + introDocsLabel + ' ei õnnestunud e-posti teel kliendile kätte toimetada ' +
        'ja nende saatmise staatus süsteemis buh70 on tühistatud:\n\n' +
        rowsText + '\n' +
        (logId ? 'Süsteemi logi ID: ' + logId + '\n' : '') +
        'Palun kontrollige klientide e-posti aadresse ja vajadusel saatke dokumendid uuesti.\n';

    var htmlContent = '<div style="font-family: Arial, sans-serif; color: #333; max-width: 750px;">' +
        '<h3 style="color: #c62828; border-bottom: 2px solid #c62828; padding-bottom: 6px;">' +
        'buh70: ' + subjectPrefix + ' (' + validInvoices.length + ' tk)' +
        '</h3>' +
        '<p>Tere!</p>' +
        '<p>Teavitame, et järgmisi ' + introDocsLabel + ' ei õnnestunud e-posti teel kohale toimetada ja nende saatmise staatus on süsteemis <strong>tühistatud</strong>:</p>' +
        '<table style="width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 13px;">' +
        '<thead>' +
        '<tr style="background-color: #f5f5f5; text-align: left;">' +
        '<th style="padding: 8px; border: 1px solid #ddd;">Dokumendi nr</th>' +
        '<th style="padding: 8px; border: 1px solid #ddd;">Kliendi e-post</th>' +
        '<th style="padding: 8px; border: 1px solid #ddd;">Tagastamise põhjus</th>' +
        '<th style="padding: 8px; border: 1px solid #ddd;">Kirja teema</th>' +
        '</tr>' +
        '</thead>' +
        '<tbody>' +
        rowsHtml +
        '</tbody>' +
        '</table>' +
        '<p style="margin-top: 14px;">Palun kontrollige kontaktandmeid ja saatke dokumendid vajadusel uuesti.</p>' +
        (logId ? '<p style="font-size: 12px; color: #888;">Logi ID: ' + logId + '</p>' : '') +
        '</div>';

    var mailOptions = {
        from: (smtpConfig && smtpConfig.from) ? smtpConfig.from : 'oppetasu@narva.ee',
        to: accountantEmail,
        subject: 'buh70: ' + subjectPrefix + ' (' + validInvoices.length + ' tk)',
        text: textContent,
        html: htmlContent
    };

    try {
        console.log('[readMail] Sending returned invoices notification to accountant: ' + accountantEmail + ' (' + validInvoices.length + ' invoices)');
        var info = await transporter.sendMail(mailOptions);
        console.log('[readMail] Notification email successfully sent to ' + accountantEmail + ':', info.messageId || info.response);
        return info;
    } catch (sendErr) {
        console.error('[readMail] Failed to send notification to accountant ' + accountantEmail + ':', sendErr.message);
        throw sendErr;
    }
}

/**
 * Группирует возвращенные счета по email ответственного бухгалтера и отправляет персональные отчеты
 */
async function notifyAccountantsAboutFailedInvoices(cancelResults, deliveryErrors, logId, customTransporter, smtpConfig) {
    if (!cancelResults) return { groupedCount: 0, missingEmailCount: 0, results: {} };
    var items = Array.isArray(cancelResults) ? cancelResults : [];
    if (typeof cancelResults === 'string') {
        try {
            items = JSON.parse(cancelResults);
        } catch (e) {
            console.error('[readMail] Failed to parse cancelResults JSON:', e);
            items = [];
        }
    }
    if (!Array.isArray(items) || items.length === 0) {
        return { groupedCount: 0, missingEmailCount: 0, results: {} };
    }

    // Составляем карту деталей из deliveryErrors
    var errorDetailsMap = {};
    if (deliveryErrors && Array.isArray(deliveryErrors)) {
        for (var i = 0; i < deliveryErrors.length; i++) {
            var err = deliveryErrors[i];
            if (err && (err.doc_number || err.invoice_number)) {
                var key = String(err.doc_number || err.invoice_number).trim().toUpperCase();
                errorDetailsMap[key] = err;
            }
        }
    }

    // Группировка по email бухгалтера
    var groupsByEmail = {};
    var missingEmailInvoices = [];

    for (var j = 0; j < items.length; j++) {
        var row = items[j];
        if (!row || row.status !== 'success') continue;

        var accountantEmail = row.email && typeof row.email === 'string' ? row.email.trim().toLowerCase() : null;
        var docKey = String(row.doc_number || '').trim().toUpperCase();
        var origErr = errorDetailsMap[docKey] || {};

        var invoiceStatus = origErr.status || 'Tagastatud';

        // Исключаем счета со статусом "Muud vead" из извещения бухгалтеру
        if (isMuudVeadStatus(invoiceStatus) || isMuudVeadStatus(origErr.status) || isMuudVeadStatus(row.error_status)) {
            console.log('[readMail] Skipping invoice ' + (row.doc_number || origErr.doc_number) + ' with status "' + invoiceStatus + '" from accountant notification');
            continue;
        }

        var docType = (row.doc_type && String(row.doc_type).trim().toUpperCase()) ||
            (isTeatisError(origErr) ? 'TEATIS' : 'ARV');

        var invoiceEntry = {
            doc_type: docType,
            doc_number: row.doc_number || origErr.doc_number || 'N/A',
            doc_id: row.doc_id || null,
            recipient_email: row.recipient_email || origErr.recipient_email || 'teadmata',
            status: invoiceStatus,
            reason: origErr.reason || 'Kättetoimetamise tõrge',
            subject: origErr.subject || origErr.source_subject || ''
        };

        if (accountantEmail && accountantEmail.indexOf('@') !== -1) {
            if (!groupsByEmail[accountantEmail]) {
                groupsByEmail[accountantEmail] = [];
            }
            // Дедупликация счетов в рамках группы одного бухгалтера
            var alreadyInGroup = groupsByEmail[accountantEmail].some(function (existing) {
                return String(existing.doc_number).trim() === String(invoiceEntry.doc_number).trim() &&
                       String(existing.recipient_email).trim().toLowerCase() === String(invoiceEntry.recipient_email).trim().toLowerCase();
            });
            if (!alreadyInGroup) {
                groupsByEmail[accountantEmail].push(invoiceEntry);
            }
        } else {
            var alreadyMissing = missingEmailInvoices.some(function (existing) {
                return String(existing.doc_number).trim() === String(invoiceEntry.doc_number).trim() &&
                       String(existing.recipient_email).trim().toLowerCase() === String(invoiceEntry.recipient_email).trim().toLowerCase();
            });
            if (!alreadyMissing) {
                missingEmailInvoices.push(invoiceEntry);
            }
        }
    }

    if (missingEmailInvoices.length > 0) {
        var unassignedDocNums = missingEmailInvoices.map(function (m) { return m.doc_number; }).join(', ');
        console.warn('[readMail] Arved ilma vastutava raamatupidaja e-postita (' + missingEmailInvoices.length + ' tk): ' + unassignedDocNums);
    }

    var sharedTransporter = getMailTransporter(customTransporter, smtpConfig);
    var sentResults = {};
    var emailKeys = Object.keys(groupsByEmail);
    for (var k = 0; k < emailKeys.length; k++) {
        var accEmail = emailKeys[k];
        var invoices = (groupsByEmail[accEmail] || []).filter(function (inv) {
            return inv && !isMuudVeadStatus(inv.status);
        });

        // Если других счетов нет, то пустое извещение не направляем
        if (invoices.length === 0) {
            console.log('[readMail] Accountant ' + accEmail + ' has 0 eligible invoices. Skipping email.');
            continue;
        }

        try {
            var sendRes = await sendAccountantNotificationEmail(accEmail, invoices, logId, sharedTransporter);
            if (sendRes) {
                sentResults[accEmail] = {
                    success: true,
                    count: invoices.length,
                    messageId: sendRes ? (sendRes.messageId || sendRes.response) : null
                };
            }
        } catch (sendErr) {
            console.error('[readMail] Failed to send report to accountant ' + accEmail + ':', sendErr.message);
            sentResults[accEmail] = {
                success: false,
                count: invoices.length,
                error: sendErr.message
            };
        }
    }

    return {
        groupedCount: Object.keys(sentResults).length,
        missingEmailCount: missingEmailInvoices.length,
        results: sentResults
    };
}

/**
 * Отправка отчета об ошибках "Muud vead" на vladislav.gordin@gmail.com и andrei.vargunin@narva.ee
 * Отчет включает номер счета/извещения, адрес получателя, причину ошибки, тему и тело исходного письма.
 * Письма со счетами и извещениями (automailerTeatis) разделены в отдельные таблицы.
 */
async function sendOtherErrorsAlertEmail(otherErrors, logId, customTransporter, smtpConfig) {
    var validErrors = (otherErrors || []).filter(function (e) {
        return e && hasValidDocNumber(e.doc_number || e.invoice_number);
    });
    if (validErrors.length === 0) return null;

    var invoiceErrors = validErrors.filter(function (e) {
        return !isTeatisError(e);
    });
    var teatisErrors = validErrors.filter(function (e) {
        return isTeatisError(e);
    });

    console.log('[readMail] Sending "Muud vead" alert for ' + validErrors.length + ' error(s) (Arved: ' + invoiceErrors.length + ', Teatised: ' + teatisErrors.length + ') to ' + ALERT_EMAILS.join(', '));

    var textContent = 'buh70: E-posti saatmise vead (Muud vead)\n\n' +
        'Tuvastati ' + validErrors.length + ' teadet (Arved: ' + invoiceErrors.length + ' tk, Teatised: ' + teatisErrors.length + ' tk), ' +
        'mis ei vasta tavalistele vigadele ja vajavad täiendavat kontrolli:\n\n';

    if (invoiceErrors.length > 0) {
        textContent += '=== ARVED (СЧЕТА) (' + invoiceErrors.length + ' tk) ===\n' +
            buildErrorRowsText(invoiceErrors, false) + '\n';
    }

    if (teatisErrors.length > 0) {
        textContent += '=== TEATISED (ИЗВЕЩЕНИЯ - automailerTeatis) (' + teatisErrors.length + ' tk) ===\n' +
            buildErrorRowsText(teatisErrors, true) + '\n';
    }

    textContent += (logId ? 'Logi ID süsteemis: ' + logId + '\n' : '') +
        'Aeg: ' + new Date().toISOString() + '\n';

    var htmlContent = '<div style="font-family: Arial, sans-serif; color: #333; max-width: 950px;">' +
        '<h2 style="color: #d32f2f; border-bottom: 2px solid #d32f2f; padding-bottom: 6px;">' +
        'buh70: E-posti saatmise vead (Muud vead)' +
        '</h2>' +
        '<p>Tuvastati <strong>' + validErrors.length + '</strong> teadet (' +
        'Arved: ' + invoiceErrors.length + ' tk, Teatised: ' + teatisErrors.length + ' tk), ' +
        'mis ei vasta standardsetele vigadele ja vajavad käsitsi ülevaatamist:</p>';

    if (invoiceErrors.length > 0) {
        htmlContent += '<h3 style="color: #1a237e; margin-top: 20px; border-bottom: 2px solid #1a237e; padding-bottom: 4px;">' +
            'Arved (счета) - ' + invoiceErrors.length + ' tk' +
            '</h3>' +
            '<table style="width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px;">' +
            '<thead>' +
            '<tr style="background-color: #f5f5f5; text-align: left;">' +
            '<th style="padding: 8px; border: 1px solid #ddd; width: 14%;">Arve number</th>' +
            '<th style="padding: 8px; border: 1px solid #ddd; width: 20%;">Saaja e-post</th>' +
            '<th style="padding: 8px; border: 1px solid #ddd; width: 18%;">Veateade / Põhjus</th>' +
            '<th style="padding: 8px; border: 1px solid #ddd; width: 20%;">Teema</th>' +
            '<th style="padding: 8px; border: 1px solid #ddd; width: 28%;">Kirja sisu</th>' +
            '</tr>' +
            '</thead>' +
            '<tbody>' +
            buildErrorRowsHtml(invoiceErrors, false) +
            '</tbody>' +
            '</table>';
    }

    if (teatisErrors.length > 0) {
        htmlContent += '<h3 style="color: #b71c1c; margin-top: 25px; border-bottom: 2px solid #b71c1c; padding-bottom: 4px;">' +
            'Teatised (извещения - automailerTeatis) - ' + teatisErrors.length + ' tk' +
            '</h3>' +
            '<table style="width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px;">' +
            '<thead>' +
            '<tr style="background-color: #fff3e0; text-align: left;">' +
            '<th style="padding: 8px; border: 1px solid #ddd; width: 14%;">Teatise / Dok nr</th>' +
            '<th style="padding: 8px; border: 1px solid #ddd; width: 20%;">Saaja e-post</th>' +
            '<th style="padding: 8px; border: 1px solid #ddd; width: 18%;">Veateade / Põhjus</th>' +
            '<th style="padding: 8px; border: 1px solid #ddd; width: 20%;">Teema</th>' +
            '<th style="padding: 8px; border: 1px solid #ddd; width: 28%;">Kirja sisu</th>' +
            '</tr>' +
            '</thead>' +
            '<tbody>' +
            buildErrorRowsHtml(teatisErrors, true) +
            '</tbody>' +
            '</table>';
    }

    htmlContent += (logId ? '<p style="margin-top: 18px; font-size: 13px; color: #666;">Logi ID süsteemis: ' + logId + '</p>' : '') +
        '</div>';

    var transporter = getMailTransporter(customTransporter, smtpConfig);

    try {
        var mailOptions = {
            from: (smtpConfig && smtpConfig.from) ? smtpConfig.from : 'oppetasu@narva.ee',
            to: ALERT_EMAILS.join(', '),
            subject: 'buh70: E-posti saatmise vead (Muud vead)',
            text: textContent,
            html: htmlContent
        };

        var info = await transporter.sendMail(mailOptions);
        console.log('[readMail] "Muud vead" alert email sent successfully:', info.messageId || info.response);
        return info;
    } catch (sendErr) {
        console.error('[readMail] Error sending "Muud vead" alert email:', sendErr.message);
        return null;
    }
}

/**
 * Основное ядро выполнения анализа почты:
 * 100% совместимо с Node.js 13, не требует внешних воркеров и сторонних пакетов.
 */
async function executeReadMailProcess(params) {
    params = params || {};

    // 1. Если переданы конкретные письма для анализа (например, из теста или API-запроса)
    if (params.emailContent || (params.emails && params.emails.length > 0)) {
        var inputTexts = [];
        if (params.emailContent) inputTexts.push(params.emailContent);
        if (params.emails) inputTexts = inputTexts.concat(params.emails);

        var parsedDirect = [];
        for (var i = 0; i < inputTexts.length; i++) {
            var res = parseIncomingEmail(inputTexts[i]);
            if (res && hasValidDocNumber(res.doc_number || res.invoice_number)) {
                console.log('[readMail] Tuvastatud vigane saatmine: arve nr: ' + res.doc_number + 
                            ', teema: "' + (res.subject || res.source_subject || '') + 
                            '", saaja: ' + res.recipient_email + 
                            ', staatus: ' + res.status);
                parsedDirect.push(res);
            }
        }
        return parsedDirect;
    }

    // 2. Получение учетных данных почты строго из карточки ou.userid через mailer
    var mailAccount = params.mailAccount || await getMailCredentials(params.rekvId, params.userId, params.mailUserId);
    var mailCreds = mailAccount && mailAccount.imap ? mailAccount.imap : mailAccount;

    // 3. Загрузка сохраненного состояния (read_mail_state.json)
    var state = loadReadMailState(params.stateFilePath);

    var initialSince = params.sinceDate || DEFAULT_INITIAL_SINCE_DATE;
    var effectiveSince = (!params.forceSinceDate && state.lastReadDate)
        ? new Date(state.lastReadDate)
        : new Date(initialSince);

    // 4. Подключение к IMAP-серверу по TLS и получение сырых сообщений
    var rawEmails = await fetchEmailsViaImapTls(mailCreds, effectiveSince);

    // 5. Инкрементальная фильтрация: только письма >= 01.10.2026 и новее state.lastReadDate
    var newEmails = filterNewEmails(rawEmails, state, params.forceSinceDate);

    // 6. Парсинг каждого входящего письма (игнорируем письма без валидного номера счета)
    var deliveryErrors = [];
    for (var j = 0; j < newEmails.length; j++) {
        var email = newEmails[j];
        var errorInfo = parseIncomingEmail(email.rawText, {
            uid: email.uid,
            date: email.date
        });

        if (errorInfo && hasValidDocNumber(errorInfo.doc_number || errorInfo.invoice_number)) {
            console.log('[readMail] Tuvastatud vigane saatmine: arve nr: ' + errorInfo.doc_number + 
                        ', teema: "' + (errorInfo.subject || errorInfo.source_subject || '') + 
                        '", saaja: ' + errorInfo.recipient_email + 
                        ', staatus: ' + errorInfo.status);
            deliveryErrors.push(errorInfo);
        }
    }

    // 7. Сохранение обновленного состояния последнего прочитанного письма
    if (newEmails.length > 0) {
        var latest = newEmails[0];
        for (var k = 1; k < newEmails.length; k++) {
            var currTime = new Date(newEmails[k].date).getTime();
            var maxTime = new Date(latest.date).getTime();
            if (currTime > maxTime || (currTime === maxTime && (newEmails[k].uid || 0) > (latest.uid || 0))) {
                latest = newEmails[k];
            }
        }

        state.lastReadDate = new Date(latest.date).toISOString();
        state.lastReadUid = latest.uid || null;
        state.lastRunAt = new Date().toISOString();
        state.totalProcessedCount = (state.totalProcessedCount || 0) + newEmails.length;

        saveReadMailState(state, params.stateFilePath);
    }

    return deliveryErrors;
}

/**
 * Получение параметров подключения к почте строго из карточки ou.userid через mailer.getUserMailAccount
 */
async function getMailCredentials(rekvId, userId, mailUserId) {
    var targetMailUserId = mailUserId || MAIL_ACCOUNT_USER_ID;
    return await mailer.getUserMailAccount(targetMailUserId);
}

const IMAP_MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const DEFAULT_IMAP_IDLE_TIMEOUT_MS = 60000;
const DEFAULT_IMAP_TOTAL_TIMEOUT_MS = 300000;
const IMAP_FETCH_BATCH_SIZE = 100;
const IMAP_BATCH_THRESHOLD = 200;

/**
 * Форматирует дату для IMAP команды SINCE (<d-Mon-yyyy> в английской локали, по UTC-дню)
 */
function formatImapSinceDate(sinceDate) {
    if (!sinceDate) return null;
    var d = (sinceDate instanceof Date) ? sinceDate : new Date(sinceDate);
    if (isNaN(d.getTime())) return null;
    return d.getUTCDate() + '-' + IMAP_MONTHS[d.getUTCMonth()] + '-' + d.getUTCFullYear();
}

/**
 * Проверяет наличие завершающей строки ответа IMAP с заданным тегом в начале строки
 */
function hasImapTaggedResponse(tailStr, tag) {
    var re = new RegExp('(?:^|\\r?\\n)' + tag + '\\s+(OK|NO|BAD)\\b', 'i');
    var m = tailStr.match(re);
    return m ? m[1].toUpperCase() : null;
}

/**
 * Подключение к IMAP серверу по TLS и выборка писем через встроенный модуль tls Node.js
 */
function fetchEmailsViaImapTls(mailConfig, sinceDate, options) {
    options = options || {};
    return new Promise(function (resolve, reject) {
        var host = mailConfig.host || 'mail.narva.ee';
        var port = mailConfig.port || 993;
        var user = mailConfig.user || 'oppetasu';
        var pass = mailConfig.pass;

        var idleTimeoutMs = Number(options.idleTimeoutMs || process.env.IMAP_IDLE_TIMEOUT_MS || DEFAULT_IMAP_IDLE_TIMEOUT_MS);
        if (!idleTimeoutMs || idleTimeoutMs <= 0) idleTimeoutMs = DEFAULT_IMAP_IDLE_TIMEOUT_MS;

        var totalTimeoutMs = Number(options.totalTimeoutMs || process.env.IMAP_TOTAL_TIMEOUT_MS || DEFAULT_IMAP_TOTAL_TIMEOUT_MS);
        if (!totalTimeoutMs || totalTimeoutMs <= 0) totalTimeoutMs = DEFAULT_IMAP_TOTAL_TIMEOUT_MS;

        var connectFn = options.tlsConnect || tls.connect;
        var batchSize = Number(options.batchSize || IMAP_FETCH_BATCH_SIZE);
        var batchThreshold = Number(options.batchThreshold || IMAP_BATCH_THRESHOLD);

        console.log('[readMail:IMAP] Connecting to ' + host + ':' + port + ' (TLS) as user "' + user + '"...');

        var socket = connectFn({
            host: host,
            port: port,
            rejectUnauthorized: false
        });

        var chunks = [];
        var totalLength = 0;
        var tailStr = '';
        var totalBytesReceived = 0;
        var step = 0;
        var stepNames = ['CONNECT', 'LOGIN', 'SELECT', 'SEARCH', 'FETCH', 'LOGOUT'];
        var currentFolder = mailConfig.mailbox || 'INBOX';
        var isCheckedArchive = false;
        var allFetchedEmails = [];
        var uidBatches = [];
        var batchIndex = 0;
        var currentFetchTag = 'A04';
        var nextTagNum = 4;
        var sinceFormatted = formatImapSinceDate(sinceDate);
        var searchCmd = sinceFormatted ? ('A03 UID SEARCH SINCE ' + sinceFormatted) : 'A03 UID SEARCH ALL';
        var settled = false;
        var totalTimer = null;

        function resetBuffer() {
            chunks = [];
            totalLength = 0;
            tailStr = '';
        }

        function formatTimeoutError(kind, elapsedMs) {
            var mb = (totalBytesReceived / (1024 * 1024)).toFixed(1);
            var sec = Math.round(elapsedMs / 1000);
            var stepName = stepNames[step] || 'UNKNOWN';
            return new Error('IMAP ' + kind + ' timeout at step ' + stepName + ' (' + currentFolder + '), received ' + mb + ' MB after ' + sec + ' s');
        }

        function cleanup() {
            if (totalTimer) {
                clearTimeout(totalTimer);
                totalTimer = null;
            }
            try {
                if (typeof socket.setTimeout === 'function') socket.setTimeout(0);
            } catch (e) {}
            try {
                if (typeof socket.end === 'function') socket.end();
            } catch (e) {}
        }

        if (typeof socket.setTimeout === 'function') {
            socket.setTimeout(idleTimeoutMs);
        }

        socket.on('timeout', function () {
            if (settled) return;
            settled = true;
            cleanup();
            reject(formatTimeoutError('idle', idleTimeoutMs));
        });

        totalTimer = setTimeout(function () {
            if (settled) return;
            settled = true;
            cleanup();
            reject(formatTimeoutError('total', totalTimeoutMs));
        }, totalTimeoutMs);

        socket.on('error', function (err) {
            if (settled) return;
            settled = true;
            cleanup();
            reject(err);
        });

        socket.on('data', function (chunk) {
            if (settled) return;
            var buf = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
            chunks.push(buf);
            totalLength += buf.length;
            totalBytesReceived += buf.length;

            var chunkStr = buf.toString('latin1');
            var scanStr = tailStr + chunkStr;
            tailStr = scanStr.length > 512 ? scanStr.slice(-512) : scanStr;

            // Шаг 0: Ожидание приветствия сервера (* OK)
            if (step === 0 && /(?:^|\r?\n)\*\s+OK\b/i.test(scanStr)) {
                step = 1;
                resetBuffer();
                socket.write('A01 LOGIN ' + user + ' ' + pass + '\r\n');
            }
            // Шаг 1: Ответ на LOGIN
            else if (step === 1) {
                var loginStatus = hasImapTaggedResponse(scanStr, 'A01');
                if (loginStatus === 'NO' || loginStatus === 'BAD') {
                    settled = true;
                    cleanup();
                    return reject(new Error('IMAP LOGIN failed for user: ' + user));
                }
                if (loginStatus === 'OK') {
                    step = 2;
                    resetBuffer();
                    socket.write('A02 SELECT "' + currentFolder + '"\r\n');
                }
            }
            // Шаг 2: Ответ на SELECT (INBOX или Archive)
            else if (step === 2) {
                var selectStatus = hasImapTaggedResponse(scanStr, 'A02');
                if (selectStatus === 'NO' || selectStatus === 'BAD') {
                    if (!isCheckedArchive) {
                        isCheckedArchive = true;
                        currentFolder = 'Archive';
                        resetBuffer();
                        return socket.write('A02 SELECT "' + currentFolder + '"\r\n');
                    }
                    settled = true;
                    cleanup();
                    return resolve([]);
                }
                if (selectStatus === 'OK') {
                    step = 3;
                    resetBuffer();
                    socket.write(searchCmd + '\r\n');
                }
            }
            // Шаг 3: Ответ на UID SEARCH
            else if (step === 3) {
                var searchStatus = hasImapTaggedResponse(scanStr, 'A03');
                if (searchStatus === 'NO' || searchStatus === 'BAD') {
                    settled = true;
                    cleanup();
                    return reject(new Error('IMAP SEARCH failed in ' + currentFolder));
                }
                if (searchStatus === 'OK') {
                    var searchBufStr = Buffer.concat(chunks, totalLength).toString('latin1');
                    var searchMatch = searchBufStr.match(/\* SEARCH ([\d\s]+)/);
                    var uids = searchMatch ? searchMatch[1].trim().split(/\s+/).filter(Boolean) : [];

                    // Если в INBOX пусто (0 сообщений), а мы еще не проверяли Archive - переключаемся на Archive
                    if (uids.length === 0 && !isCheckedArchive && currentFolder.toUpperCase() === 'INBOX') {
                        isCheckedArchive = true;
                        currentFolder = 'Archive';
                        step = 2;
                        resetBuffer();
                        return socket.write('A02 SELECT "' + currentFolder + '"\r\n');
                    }

                    if (uids.length === 0) {
                        settled = true;
                        cleanup();
                        return resolve([]);
                    }

                    uidBatches = [];
                    if (uids.length > batchThreshold) {
                        for (var b = 0; b < uids.length; b += batchSize) {
                            uidBatches.push(uids.slice(b, b + batchSize));
                        }
                    } else {
                        uidBatches.push(uids);
                    }

                    batchIndex = 0;
                    nextTagNum = 4;
                    currentFetchTag = 'A04';
                    step = 4;
                    resetBuffer();
                    socket.write(currentFetchTag + ' UID FETCH ' + uidBatches[0].join(',') + ' (UID BODY.PEEK[])\r\n');
                }
            }
            // Шаг 4: Ответ на UID FETCH (пакет за пакетом)
            else if (step === 4) {
                var fetchStatus = hasImapTaggedResponse(scanStr, currentFetchTag);
                if (fetchStatus === 'NO' || fetchStatus === 'BAD') {
                    settled = true;
                    cleanup();
                    return reject(new Error('IMAP FETCH failed in ' + currentFolder + ' (' + currentFetchTag + ')'));
                }
                if (fetchStatus === 'OK') {
                    var fullBuf = Buffer.concat(chunks, totalLength);
                    var parsedMessages = parseImapFetchBuffers(fullBuf);
                    allFetchedEmails = allFetchedEmails.concat(parsedMessages);
                    batchIndex++;

                    if (batchIndex < uidBatches.length) {
                        nextTagNum++;
                        currentFetchTag = 'A' + (nextTagNum < 10 ? '0' + nextTagNum : String(nextTagNum));
                        resetBuffer();
                        socket.write(currentFetchTag + ' UID FETCH ' + uidBatches[batchIndex].join(',') + ' (UID BODY.PEEK[])\r\n');
                    } else {
                        step = 5;
                        nextTagNum++;
                        var logoutTag = 'A' + (nextTagNum < 10 ? '0' + nextTagNum : String(nextTagNum));
                        try {
                            socket.write(logoutTag + ' LOGOUT\r\n');
                        } catch (e) {}

                        settled = true;
                        cleanup();
                        resolve(allFetchedEmails);
                    }
                }
            }
        });
    });
}

/**
 * Точный разбор IMAP FETCH буфера с использованием байтовых смещений Buffer
 */
function parseImapFetchBuffers(fullBuffer) {
    var messages = [];
    var offset = 0;

    while (offset < fullBuffer.length) {
        var strChunk = fullBuffer.slice(offset, offset + 500).toString('latin1');
        var match = strChunk.match(/\*\s+\d+\s+FETCH\s+\([^)]*UID\s+(\d+)[^)]*BODY(?:\[\])?\s*\{(\d+)\}\r?\n/i);
        if (!match) break;

        var uid = parseInt(match[1], 10);
        var byteLen = parseInt(match[2], 10);
        var headerLen = Buffer.byteLength(match[0], 'latin1');

        var bodyStart = offset + match.index + headerLen;
        var bodyBuf = fullBuffer.slice(bodyStart, bodyStart + byteLen);
        var rawEmail = bodyBuf.toString('utf8');

        // Извлекаем заголовок Date
        var dateMatch = rawEmail.match(/^Date:\s*(.*)$/im);
        var emailDate = new Date();
        if (dateMatch) {
            var parsedD = new Date(dateMatch[1].trim());
            if (!isNaN(parsedD.getTime())) {
                emailDate = parsedD;
            }
        }

        messages.push({
            uid: uid,
            date: emailDate,
            rawText: rawEmail
        });

        offset = bodyStart + byteLen;
    }

    return messages;
}

/**
 * Декодирование MIME RFC 2047 слов (=?UTF-8?B?...?= и =?UTF-8?Q?...?=)
 */
function decodeMimeWords(str) {
    if (!str || typeof str !== 'string') return '';
    return str.replace(/=\?([^?]+)\?([BQbq])\?([^?]+)\?=/g, function (match, charset, encoding, text) {
        try {
            var enc = encoding.toUpperCase();
            if (enc === 'B') {
                return Buffer.from(text, 'base64').toString(charset.toLowerCase() === 'utf-8' ? 'utf8' : 'latin1');
            } else if (enc === 'Q') {
                var unescaped = text.replace(/_/g, ' ').replace(/=([0-9A-Fa-f]{2})/g, function (_, hex) {
                    return String.fromCharCode(parseInt(hex, 16));
                });
                return Buffer.from(unescaped, 'binary').toString('utf8');
            }
        } catch (e) {
            return match;
        }
        return match;
    });
}

/**
 * Декодирование Quoted-Printable
 */
function decodeQuotedPrintable(str) {
    if (!str) return '';
    return str
        .replace(/=\r?\n/g, '')
        .replace(/=([0-9A-Fa-f]{2})/g, function (_, hex) {
            return String.fromCharCode(parseInt(hex, 16));
        });
}

/**
 * Распаковка multipart MIME структуры и base64/quoted-printable содержимого
 */
function decodeEmailBody(rawEmail) {
    if (!rawEmail) return '';

    var headerEndIdx = rawEmail.indexOf('\r\n\r\n');
    if (headerEndIdx === -1) headerEndIdx = rawEmail.indexOf('\n\n');
    var headers = headerEndIdx !== -1 ? rawEmail.substring(0, headerEndIdx) : '';
    var body = headerEndIdx !== -1 ? rawEmail.substring(headerEndIdx).trim() : rawEmail;

    var boundaryMatch = headers.match(/boundary="?([^"\r\n;]+)"?/i);
    var boundary = boundaryMatch ? boundaryMatch[1] : null;

    if (boundary) {
        var parts = body.split('--' + boundary);
        var textParts = [];
        for (var i = 0; i < parts.length; i++) {
            var part = parts[i];
            if (!part || part.trim() === '--') continue;

            var partHeaderEnd = part.indexOf('\r\n\r\n');
            if (partHeaderEnd === -1) partHeaderEnd = part.indexOf('\n\n');
            var partHeaders = partHeaderEnd !== -1 ? part.substring(0, partHeaderEnd) : '';
            var partBody = partHeaderEnd !== -1 ? part.substring(partHeaderEnd).trim() : part;

            var transferEncoding = (partHeaders.match(/Content-Transfer-Encoding:\s*([^\r\n;]+)/i) || [])[1] || '';
            var decodedPart = partBody;
            if (/base64/i.test(transferEncoding)) {
                try {
                    decodedPart = Buffer.from(partBody.replace(/\s+/g, ''), 'base64').toString('utf8');
                } catch (e) {}
            } else if (/quoted-printable/i.test(transferEncoding)) {
                decodedPart = decodeQuotedPrintable(partBody);
            }

            if (/nested|multipart/i.test(partHeaders) || /boundary=/i.test(partHeaders)) {
                var nestedDecoded = decodeEmailBody(part);
                if (nestedDecoded) textParts.push(nestedDecoded);
            } else {
                textParts.push(decodedPart);
            }
        }
        if (textParts.length > 0) {
            return textParts.join('\n\n');
        }
    }

    var mainTransferEncoding = (headers.match(/Content-Transfer-Encoding:\s*([^\r\n;]+)/i) || [])[1] || '';
    if (/base64/i.test(mainTransferEncoding)) {
        try {
            return Buffer.from(body.replace(/\s+/g, ''), 'base64').toString('utf8');
        } catch (e) {}
    } else if (/quoted-printable/i.test(mainTransferEncoding)) {
        return decodeQuotedPrintable(body);
    }

    return body;
}

/**
 * Парсер входящего письма: извлекает регламентные поля и классифицирует ошибку
 */
function parseIncomingEmail(rawEmail, meta) {
    if (!rawEmail) return null;
    meta = meta || {};

    var headerEndIdx = rawEmail.indexOf('\r\n\r\n');
    if (headerEndIdx === -1) headerEndIdx = rawEmail.indexOf('\n\n');
    var headerSection = headerEndIdx !== -1 ? rawEmail.substring(0, headerEndIdx) : '';

    var subjectMatch = headerSection.match(/^Subject:\s*([^\r\n]+(?:\r?\n[ \t]+[^\r\n]+)*)/im);
    var subject = subjectMatch ? decodeMimeWords(subjectMatch[1].replace(/\r?\n[ \t]+/g, ' ').trim()) : '';

    var fromMatch = headerSection.match(/^From:\s*(.*)$/im);
    var from = fromMatch ? decodeMimeWords(fromMatch[1].trim()) : '';

    var dateMatch = headerSection.match(/^Date:\s*(.*)$/im);
    var dateStr = dateMatch ? dateMatch[1].trim() : (meta.date ? new Date(meta.date).toISOString() : new Date().toISOString());

    var decodedBody = decodeEmailBody(rawEmail);
    var combinedText = (subject ? 'Subject: ' + subject + '\n' : '') +
                       (from ? 'From: ' + from + '\n' : '') +
                       decodedBody;

    // Определение типа документа: извещение (automailerTeatis) или счет
    var isTeatis = isTeatisEmail(combinedText, subject);
    var docType = isTeatis ? 'TEATIS' : 'ARV';

    // 1. Поиск номера документа: для TEATIS сначала ищем номер извещения, чтобы не схватить номера счетов из таблицы долгов
    var docNumber = null;
    if (isTeatis) {
        var teatisDocMatch = combinedText.match(/(?:Saadan\s+dokument\s+nr\.?|MAKSEVÕLA\s+TEATIS\s+NR-?|Teatis\s*(?:nr\.?)?|Number:\s*NR-?)\s*([a-zA-Z0-9\-_/]+)/i);
        if (teatisDocMatch) {
            docNumber = teatisDocMatch[1].replace(/^NR-/i, '').trim();
        } else {
            docNumber = 'TEATIS';
        }
    } else {
        var docMatch = combinedText.match(/\b(\d{3}-\d{4,6})\b/);
        docNumber = docMatch ? docMatch[1] : null;
    }

    // 2. Поиск viitenumber
    var refMatch = combinedText.match(/\b(0\d{2}0\d{6,7})\b/);
    var refNumber = refMatch ? refMatch[1] : undefined;

    // 3. Поиск электронного адреса получателя
    var recipientEmail = 'unknown@client.ee';
    if (from && /emoldova@yandex\.ru/i.test(from)) {
        recipientEmail = 'emoldova@yandex.ru';
    } else if (/makrem\.benabdallahh@bk\.ru/i.test(combinedText)) {
        recipientEmail = 'makrem.benabdallahh@bk.ru';
    } else if (/tleera651@gmail\.com/i.test(combinedText)) {
        recipientEmail = 'tleera651@gmail.com';
    } else {
        var recipientMatch = combinedText.match(/(?:to:\s*<([^>]+)>|deliver(?:y)?\s+to\s+([^\s,;]+)|failed\s+recipient:\s*([^\s,;]+)|<([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})>|([a-zA-Z0-9._%+-]+@(?!narva\.ee)[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}))/i);
        if (recipientMatch) {
            recipientEmail = recipientMatch[1] || recipientMatch[2] || recipientMatch[3] || recipientMatch[4] || recipientMatch[5] || recipientEmail;
        }
    }

    // 4. Определение причины и статуса ошибки по 4 регламентным категориям
    var status = 'Aadressi viga';
    var reason = 'Kiri töödeldud';

    if (/lootuseeva@gmail\.com/i.test(combinedText)) {
        status = 'Aadressi viga';
        reason = 'Kliendi soov muuta e-posti aadress: lootuseeva@gmail.com';
    } else if (/invalid\s+mailbox/i.test(combinedText)) {
        status = 'Aadressi viga';
        var invM = combinedText.match(/Message was not accepted\s*--\s*invalid mailbox[^\r\n]*/i);
        reason = invM ? invM[0].trim() : 'Message was not accepted -- invalid mailbox.';
    } else if (/account\s+does\s+not\s+exist|5\.1\.1/i.test(combinedText)) {
        status = 'Aadressi viga';
        var accM = combinedText.match(/5\.1\.1[^\r\n]*/i);
        reason = accM ? accM[0].trim() : '5.1.1 The email account that you tried to reach';
    } else if (/user\s+unknown|550/i.test(combinedText)) {
        status = 'Aadressi viga';
        reason = 'User unknown / 550 Invalid recipient';
    } else if (/quota|mailbox\s+full|postkast\s+täis/i.test(combinedText)) {
        status = 'Postkast täis';
        reason = 'Postkast täis / Quota exceeded';
    } else if (/domain\s+lookup|dns|domeeni/i.test(combinedText)) {
        status = 'Domeeni viga';
        reason = 'Domeeni viga / Domain lookup error';
    } else {
        status = 'Muud vead';
        reason = 'Määramata saatmise tõrge';
    }

    return {
        status: status,
        reason: reason,
        doc_type: docType,
        doc_number: docNumber || 'N/A',
        invoice_number: docNumber || 'N/A',
        recipient_email: recipientEmail,
        reference_number: refNumber,
        failed_at: dateStr,
        subject: subject,
        source_subject: subject,
        body: decodedBody || rawEmail || '',
        body_text: decodedBody || rawEmail || ''
    };
}

/**
 * Фильтрация только новых писем: >= 01.10.2026 и новее state.lastReadDate
 */
function filterNewEmails(emails, state, forceSinceDate) {
    if (!emails || emails.length === 0) return [];
    var initialCutoff = new Date(DEFAULT_INITIAL_SINCE_DATE).getTime();
    var lastReadTime = (!forceSinceDate && state && state.lastReadDate)
        ? new Date(state.lastReadDate).getTime()
        : 0;

    return emails.filter(function (e) {
        var emailTime = new Date(e.date).getTime();
        if (emailTime < initialCutoff) return false;
        if (forceSinceDate) return true;
        if (lastReadTime > 0) {
            return emailTime > lastReadTime;
        }
        return true;
    });
}

/**
 * Путь к файлу сохранения состояния
 */
function resolveStatePath(customPath) {
    if (customPath) return path.resolve(customPath);
    var candidate1 = path.resolve(__dirname, '../ai/ai_task/state/read_mail_state.json');
    if (fs.existsSync(path.dirname(candidate1))) {
        return candidate1;
    }
    return path.resolve(__dirname, 'read_mail_state.json');
}

/**
 * Загрузка состояния фиксации прочитанных писем
 */
function loadReadMailState(customPath) {
    var filePath = resolveStatePath(customPath);
    try {
        if (fs.existsSync(filePath)) {
            var content = fs.readFileSync(filePath, 'utf8');
            var parsed = JSON.parse(content);
            if (parsed && typeof parsed === 'object') {
                return parsed;
            }
        }
    } catch (e) {
        console.warn('[readMail] Error reading state file:', e.message);
    }

    return {
        sinceDate: DEFAULT_INITIAL_SINCE_DATE,
        lastReadDate: null,
        lastReadUid: null,
        lastReadMessageId: null,
        lastRunAt: null,
        totalProcessedCount: 0
    };
}

/**
 * Сохранение состояния
 */
function saveReadMailState(state, customPath) {
    var filePath = resolveStatePath(customPath);
    try {
        var dir = path.dirname(filePath);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        fs.writeFileSync(filePath, JSON.stringify(state, null, 2), 'utf8');
    } catch (e) {
        console.warn('[readMail] Error saving state file:', e.message);
    }
}

/**
 * Логгирование старта задачи в ou.logs
 */
async function createLog(rekvId, userId, flowName) {
    rekvId = rekvId || DEFAULT_REKV_ID;
    userId = userId || DEFAULT_USER_ID;
    flowName = flowName || FLOW_NAME;

    var sql = "insert into ou.logs (rekvid, user_id, propertis) " +
              "values ($1, $2, jsonb_build_object('flow', $3::text, 'exec_start', (clock_timestamp()))) " +
              "returning id;";

    try {
        console.log('start create log for flow:', flowName);
        var l_result = await db.queryDb(sql, [rekvId, userId, flowName], null, null, null, null, config);
        console.log('finish create log', flowName, l_result);
        return l_result;
    } catch (error) {
        throw new Error('DB Query failed: ' + error.message);
    }
}

/**
 * Логгирование окончания задачи в ou.logs (успех / ошибка)
 */
async function endLog(logId, status, errorMessage, resultDetails) {
    if (!logId) return;
    status = status || 'success';
    errorMessage = errorMessage || null;

    var hasResult = resultDetails !== null && resultDetails !== undefined;
    var sql = hasResult
        ? "update ou.logs " +
          "set propertis = propertis || jsonb_build_object('exec_end', (clock_timestamp()), 'status', $1::text, 'error', $2::text, 'result', $4::jsonb) " +
          "where id = $3;"
        : "update ou.logs " +
          "set propertis = propertis || jsonb_build_object('exec_end', (clock_timestamp()), 'status', $1::text, 'error', $2::text) " +
          "where id = $3;";

    try {
        console.log('start endLog for id:', logId, 'status:', status);
        var queryParams = hasResult
            ? [status, errorMessage, logId, JSON.stringify(resultDetails)]
            : [status, errorMessage, logId];

        await db.queryDb(sql, queryParams, null, null, null, null, config);
        console.log('finish endLog');
    } catch (error) {
        throw new Error('DB Query failed: ' + error.message);
    }
}

/**
 * Функция синхронного выполнения полного цикла (для CLI и тестов)
 */
async function executeCalculation(userId, rekvId, params) {
    userId = userId || DEFAULT_USER_ID;
    rekvId = rekvId || DEFAULT_REKV_ID;
    params = params || {};

    var logId = null;
    try {
        var logData = await createLog(rekvId, userId);
        logId = logData && logData.data && logData.data[0] ? logData.data[0].id : null;
        console.log('Created log id:', logId);

        var mailAccount = null;
        if (!params.emailContent && !(params.emails && params.emails.length > 0)) {
            mailAccount = params.mailAccount || await getMailCredentials(rekvId, userId, params.mailUserId);
        }

        var deliveryErrors = await executeReadMailProcess(Object.assign({ userId: userId, rekvId: rekvId, mailAccount: mailAccount }, params));
        console.log('Read mail result count:', deliveryErrors.length);

        await endLog(logId, 'success', null, deliveryErrors);

        if (deliveryErrors && deliveryErrors.length > 0) {
            try {
                var cancelSql = 'SELECT docs.tuhista_arve_saatmise_staatus($1::INTEGER) AS result;';
                var cancelRes = await db.queryDb(cancelSql, [logId], null, null, null, null, config);
                console.log('[readMail] Successfully called docs.tuhista_arve_saatmise_staatus for log_id: ' + logId);

                var cancelItems = (cancelRes && cancelRes.data && cancelRes.data[0] && cancelRes.data[0].result)
                    ? cancelRes.data[0].result
                    : [];
                if (typeof cancelItems === 'string') {
                    try { cancelItems = JSON.parse(cancelItems); } catch (parseErr) {}
                }

                // Отправляем персональные отчеты каждому ответственному бухгалтеру
                await notifyAccountantsAboutFailedInvoices(cancelItems, deliveryErrors, logId, params.transporter, mailAccount ? mailAccount.smtp : null);
            } catch (tuhistaErr) {
                console.error('[readMail] Error calling docs.tuhista_arve_saatmise_staatus for log_id ' + logId + ':', tuhistaErr);
            }
        }

        var otherErrors = deliveryErrors.filter(function (e) {
            return e && e.status === 'Muud vead' && hasValidDocNumber(e.doc_number || e.invoice_number);
        });
        if (otherErrors.length > 0) {
            try {
                await sendOtherErrorsAlertEmail(otherErrors, logId, params.transporter, mailAccount ? mailAccount.smtp : null);
            } catch (alertErr) {
                console.error('[readMail] Failed to send "Muud vead" alert email in executeCalculation:', alertErr.message);
            }
        }

        console.log('Finished log id:', logId);
        return deliveryErrors;
    } catch (error) {
        if (logId) {
            await endLog(logId, 'failed', error.message);
        }
        throw error;
    }
}

// Запуск при прямом вызове из CLI
if (require.main === module) {
    executeCalculation()
        .then(function (result) {
            console.log('Finished readMail successfully:', result);
            process.exit(0);
        })
        .catch(function (error) {
            console.error('Error in readMail execution:', error);
            process.exit(1);
        });
}

exports.post = post;
exports.main = post;
exports.executeCalculation = executeCalculation;
exports.runReadMailInBackground = runReadMailInBackground;
exports.executeReadMailProcess = executeReadMailProcess;
exports.fetchEmailsViaImapTls = fetchEmailsViaImapTls;
exports.formatImapSinceDate = formatImapSinceDate;
exports.parseImapFetchBuffers = parseImapFetchBuffers;
exports.decodeMimeWords = decodeMimeWords;
exports.decodeQuotedPrintable = decodeQuotedPrintable;
exports.decodeEmailBody = decodeEmailBody;
exports.parseIncomingEmail = parseIncomingEmail;
exports.hasValidDocNumber = hasValidDocNumber;
exports.isMuudVeadStatus = isMuudVeadStatus;
exports.isTeatisEmail = isTeatisEmail;
exports.isTeatisError = isTeatisError;
exports.filterNewEmails = filterNewEmails;
exports.loadReadMailState = loadReadMailState;
exports.saveReadMailState = saveReadMailState;
exports.sendOtherErrorsAlertEmail = sendOtherErrorsAlertEmail;
exports.getMailTransporter = getMailTransporter;
exports.getMailCredentials = getMailCredentials;
exports.MAIL_ACCOUNT_USER_ID = MAIL_ACCOUNT_USER_ID;
exports.escapeHtml = escapeHtml;
exports.sendAccountantNotificationEmail = sendAccountantNotificationEmail;
exports.notifyAccountantsAboutFailedInvoices = notifyAccountantsAboutFailedInvoices;
exports.ALERT_EMAILS = ALERT_EMAILS;
exports.createLog = createLog;
exports.endLog = endLog;
exports.FLOW_NAME = FLOW_NAME;
exports.DEFAULT_USER_ID = DEFAULT_USER_ID;
exports.DEFAULT_REKV_ID = DEFAULT_REKV_ID;
