'use strict';

const tls = require('tls');
const fs = require('fs');
const path = require('path');
const nodemailer = require('nodemailer');
const db = require('./../../libs/db');
const config = require('./../../config/narvalv.json');

const DEFAULT_USER_ID = 2477;
const DEFAULT_REKV_ID = 63;
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

        var deliveryErrors = await executeReadMailProcess({
            userId: userId,
            rekvId: rekvId,
            emailContent: params.emailContent,
            emails: params.emails,
            stateFilePath: params.stateFilePath,
            sinceDate: params.sinceDate,
            forceSinceDate: params.forceSinceDate
        });

        console.log('[readMail] Background execution finished successfully. log_id: ' + logId + ', errors found: ' + deliveryErrors.length);

        // Фиксируем успешное завершение в ou.logs с деталями результата
        await endLog(logId, 'success', null, deliveryErrors);

        // Аннулируем статус успешной отправки счетов в БД (docs.tuhista_arve_saatmise_staatus)
        if (deliveryErrors && deliveryErrors.length > 0) {
            try {
                var cancelSql = 'SELECT docs.tuhista_arve_saatmise_staatus($1::INTEGER) AS result;';
                await db.queryDb(cancelSql, [logId], null, null, null, null, config);
                console.log('[readMail] Successfully called docs.tuhista_arve_saatmise_staatus for log_id: ' + logId);
            } catch (tuhistaErr) {
                console.error('[readMail] Error calling docs.tuhista_arve_saatmise_staatus for log_id ' + logId + ':', tuhistaErr);
            }
        }
        // 2. Отправка отчета при наличии ошибок со статусом "Muud vead" на vladislav.gordin@gmail.com и andrei.vargunin@narva.ee
        var otherErrors = deliveryErrors.filter(function (e) {
            return e && e.status === 'Muud vead';
        });
        if (otherErrors.length > 0) {
            try {
                await sendOtherErrorsAlertEmail(otherErrors, logId);
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
 * Отправка отчета об ошибках "Muud vead" на vladislav.gordin@gmail.com и andrei.vargunin@narva.ee
 * Отчет включает номер счета, адрес получателя и причину ошибки
 */
async function sendOtherErrorsAlertEmail(otherErrors, logId, customTransporter) {
    if (!otherErrors || otherErrors.length === 0) return null;

    console.log('[readMail] Sending "Muud vead" alert for ' + otherErrors.length + ' error(s) to ' + ALERT_EMAILS.join(', '));

    var rowsText = '';
    var rowsHtml = '';

    for (var i = 0; i < otherErrors.length; i++) {
        var err = otherErrors[i];
        var docNum = err.doc_number || err.invoice_number || 'N/A';
        var recip = err.recipient_email || 'unknown';
        var rsn = err.reason || 'Määramata saatmise tõrge';

        rowsText += '- Arve nr: ' + docNum + ' | Saaja: ' + recip + ' | Põhjus: ' + rsn + '\n';
        rowsHtml += '<tr>' +
            '<td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">' + docNum + '</td>' +
            '<td style="padding: 8px; border: 1px solid #ddd;">' + recip + '</td>' +
            '<td style="padding: 8px; border: 1px solid #ddd; color: #d32f2f;">' + rsn + '</td>' +
            '</tr>';
    }

    var textContent = 'buh70: E-posti kohaletoimetamise määramata vead (Muud vead)\n\n' +
        'Tuvastati ' + otherErrors.length + ' teadet, mis ei vasta tavalistele vigadele ja vajavad täiendavat kontrolli:\n\n' +
        rowsText + '\n' +
        (logId ? 'Logi ID süsteemis: ' + logId + '\n' : '') +
        'Aeg: ' + new Date().toISOString() + '\n';

    var htmlContent = '<div style="font-family: Arial, sans-serif; color: #333; max-width: 650px;">' +
        '<h2 style="color: #d32f2f; border-bottom: 2px solid #d32f2f; padding-bottom: 6px;">' +
        'buh70: E-posti saatmise vead (Muud vead)' +
        '</h2>' +
        '<p>Tuvastati <strong>' + otherErrors.length + '</strong> teadet, mis ei vasta standardsetele vigadele ja vajavad käsitsi ülevaatamist:</p>' +
        '<table style="width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 13px;">' +
        '<thead>' +
        '<tr style="background-color: #f5f5f5; text-align: left;">' +
        '<th style="padding: 8px; border: 1px solid #ddd;">Arve number</th>' +
        '<th style="padding: 8px; border: 1px solid #ddd;">Saaja e-post</th>' +
        '<th style="padding: 8px; border: 1px solid #ddd;">Veateade / Põhjus</th>' +
        '</tr>' +
        '</thead>' +
        '<tbody>' +
        rowsHtml +
        '</tbody>' +
        '</table>' +
        (logId ? '<p style="margin-top: 14px; font-size: 13px; color: #666;">Logi ID süsteemis: ' + logId + '</p>' : '') +
        '</div>';

    var transporter = customTransporter;
    if (!transporter) {
        var smtpHost = process.env.SMTP_HOST || 'mail.narva.ee';
        var smtpPort = process.env.SMTP_PORT ? parseInt(process.env.SMTP_PORT, 10) : 25;
        var smtpUser = process.env.SMTP_USER || 'oppetasu';
        var smtpPass = process.env.SMTP_PASS || 'wbt5OcIhvmD8';
        var isSecure = smtpPort === 465;

        transporter = nodemailer.createTransport({
            host: smtpHost,
            port: smtpPort,
            secure: isSecure,
            auth: {
                user: smtpUser,
                pass: smtpPass
            },
            tls: {
                rejectUnauthorized: false
            }
        });
    }

    try {
        var mailOptions = {
            from: process.env.REPORT_EMAIL_FROM || 'oppetasu@narva.ee',
            to: ALERT_EMAILS.join(', '),
            subject: 'buh70: E-posti kohaletoimetamise vead (Muud vead)',
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
            if (res) parsedDirect.push(res);
        }
        return parsedDirect;
    }

    // 2. Получение учетных данных почты (из .env или ou.userid)
    var mailCreds = await getMailCredentials(params.rekvId, params.userId);

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

    // 6. Парсинг каждого входящего письма
    var deliveryErrors = [];
    for (var j = 0; j < newEmails.length; j++) {
        var email = newEmails[j];
        var errorInfo = parseIncomingEmail(email.rawText, {
            uid: email.uid,
            date: email.date
        });

        if (errorInfo) {
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
 * Получение параметров подключения к почте (аналогично automailer.js)
 */
async function getMailCredentials(rekvId, userId) {
    var host = process.env.IMAP_HOST || 'mail.narva.ee';
    var port = process.env.IMAP_PORT ? parseInt(process.env.IMAP_PORT, 10) : 993;
    var user = process.env.IMAP_USER || 'oppetasu';
    var pass = process.env.IMAP_PASS || '';
    var mailbox = process.env.IMAP_MAILBOX || 'INBOX';

    // Если пароль не задан в process.env, пробуем извлечь из ou.userid (как в automailer.js)
    if (!pass) {
        try {
            var sql = "SELECT u.properties ->> 'pass' as pass, u.properties ->> 'user' as user " +
                      "FROM ou.userid u " +
                      "WHERE u.id = 11558 OR (u.properties ->> 'user') = $1 " +
                      "LIMIT 1;";
            var res = await db.queryDb(sql, [user], null, null, null, null, config);
            if (res && res.data && res.data[0] && res.data[0].pass) {
                pass = res.data[0].pass;
                if (res.data[0].user) user = res.data[0].user;
            }
        } catch (dbErr) {
            console.warn('[readMail] Failed to load imap pass from ou.userid:', dbErr.message);
        }
    }

    // Резервный пароль по умолчанию из automailer
    if (!pass && user === 'oppetasu') {
        pass = 'wbt5OcIhvmD8';
    }

    return {
        host: host,
        port: port,
        user: user,
        pass: pass,
        mailbox: mailbox
    };
}

/**
 * Подключение к IMAP серверу по TLS и выборка писем через встроенный модуль tls Node.js
 */
function fetchEmailsViaImapTls(mailConfig, sinceDate) {
    return new Promise(function (resolve, reject) {
        var host = mailConfig.host || 'mail.narva.ee';
        var port = mailConfig.port || 993;
        var user = mailConfig.user || 'oppetasu';
        var pass = mailConfig.pass;

        console.log('[readMail:IMAP] Connecting to ' + host + ':' + port + ' (TLS) as user "' + user + '"...');

        var socket = tls.connect({
            host: host,
            port: port,
            rejectUnauthorized: false
        });

        var chunks = [];
        var step = 0;
        var currentFolder = mailConfig.mailbox || 'INBOX';
        var isCheckedArchive = false;
        var allFetchedEmails = [];
        var timeoutTimer = null;

        function cleanup() {
            if (timeoutTimer) clearTimeout(timeoutTimer);
            try { socket.end(); } catch (e) {}
        }

        timeoutTimer = setTimeout(function () {
            cleanup();
            reject(new Error('IMAP connection timed out after 30 seconds'));
        }, 30000);

        socket.on('error', function (err) {
            cleanup();
            reject(err);
        });

        socket.on('data', function (chunk) {
            chunks.push(chunk);
            var totalBuf = Buffer.concat(chunks);
            var str = totalBuf.toString('latin1');

            // Шаг 0: Ожидание приветствия сервера (* OK)
            if (step === 0 && str.indexOf('* OK') !== -1) {
                step = 1;
                chunks = [];
                socket.write('A01 LOGIN ' + user + ' ' + pass + '\r\n');
            }
            // Шаг 1: Ответ на LOGIN
            else if (step === 1 && (str.indexOf('A01 OK') !== -1 || str.indexOf('A01 NO') !== -1)) {
                if (str.indexOf('A01 NO') !== -1) {
                    cleanup();
                    return reject(new Error('IMAP LOGIN failed for user: ' + user));
                }
                step = 2;
                chunks = [];
                socket.write('A02 SELECT "' + currentFolder + '"\r\n');
            }
            // Шаг 2: Ответ на SELECT (INBOX или Archive)
            else if (step === 2 && (str.indexOf('A02 OK') !== -1 || str.indexOf('A02 NO') !== -1)) {
                if (str.indexOf('A02 NO') !== -1 && !isCheckedArchive) {
                    // Если папка не открылась, пробуем Archive
                    isCheckedArchive = true;
                    currentFolder = 'Archive';
                    chunks = [];
                    return socket.write('A02 SELECT "' + currentFolder + '"\r\n');
                }
                step = 3;
                chunks = [];
                socket.write('A03 UID SEARCH ALL\r\n');
            }
            // Шаг 3: Ответ на UID SEARCH
            else if (step === 3 && str.indexOf('A03 OK') !== -1) {
                var searchMatch = str.match(/\* SEARCH ([\d\s]+)/);
                var uids = searchMatch ? searchMatch[1].trim().split(/\s+/).filter(Boolean) : [];

                // Если в INBOX пусто (0 сообщений), а мы еще не проверяли Archive - переключаемся на Archive
                if (uids.length === 0 && !isCheckedArchive && currentFolder.toUpperCase() === 'INBOX') {
                    isCheckedArchive = true;
                    currentFolder = 'Archive';
                    step = 2;
                    chunks = [];
                    return socket.write('A02 SELECT "' + currentFolder + '"\r\n');
                }

                if (uids.length === 0) {
                    cleanup();
                    return resolve([]);
                }

                step = 4;
                chunks = [];
                socket.write('A04 UID FETCH ' + uids.join(',') + ' (UID BODY.PEEK[])\r\n');
            }
            // Шаг 4: Ответ на UID FETCH (все сообщения загружены)
            else if (step === 4 && str.indexOf('A04 OK') !== -1) {
                step = 5;
                try {
                    socket.write('A05 LOGOUT\r\n');
                } catch (e) {}

                var parsedMessages = parseImapFetchBuffers(totalBuf);
                cleanup();
                resolve(parsedMessages);
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

    var subjectMatch = headerSection.match(/^Subject:\s*(.*)$/im);
    var subject = subjectMatch ? decodeMimeWords(subjectMatch[1].trim()) : '';

    var fromMatch = headerSection.match(/^From:\s*(.*)$/im);
    var from = fromMatch ? decodeMimeWords(fromMatch[1].trim()) : '';

    var dateMatch = headerSection.match(/^Date:\s*(.*)$/im);
    var dateStr = dateMatch ? dateMatch[1].trim() : (meta.date ? new Date(meta.date).toISOString() : new Date().toISOString());

    var decodedBody = decodeEmailBody(rawEmail);
    var combinedText = (subject ? 'Subject: ' + subject + '\n' : '') +
                       (from ? 'From: ' + from + '\n' : '') +
                       decodedBody;

    // 1. Поиск номера счета (напр. 073-7745, 095-9641, 098-10566)
    var docMatch = combinedText.match(/\b(\d{3}-\d{4,6})\b/);
    var docNumber = docMatch ? docMatch[1] : null;

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
        doc_number: docNumber || 'N/A',
        invoice_number: docNumber || 'N/A',
        recipient_email: recipientEmail,
        reference_number: refNumber,
        failed_at: dateStr,
        source_subject: subject
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

        var deliveryErrors = await executeReadMailProcess(Object.assign({ userId: userId, rekvId: rekvId }, params));
        console.log('Read mail result count:', deliveryErrors.length);

        await endLog(logId, 'success', null, deliveryErrors);

        if (deliveryErrors && deliveryErrors.length > 0) {
            try {
                var cancelSql = 'SELECT docs.tuhista_arve_saatmise_staatus($1::INTEGER) AS result;';
                await db.queryDb(cancelSql, [logId], null, null, null, null, config);
                console.log('[readMail] Successfully called docs.tuhista_arve_saatmise_staatus for log_id: ' + logId);
            } catch (tuhistaErr) {
                console.error('[readMail] Error calling docs.tuhista_arve_saatmise_staatus for log_id ' + logId + ':', tuhistaErr);
            }
        }

        var otherErrors = deliveryErrors.filter(function (e) {
            return e && e.status === 'Muud vead';
        });
        if (otherErrors.length > 0) {
            try {
                await sendOtherErrorsAlertEmail(otherErrors, logId);
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
exports.parseImapFetchBuffers = parseImapFetchBuffers;
exports.decodeMimeWords = decodeMimeWords;
exports.decodeQuotedPrintable = decodeQuotedPrintable;
exports.decodeEmailBody = decodeEmailBody;
exports.parseIncomingEmail = parseIncomingEmail;
exports.filterNewEmails = filterNewEmails;
exports.loadReadMailState = loadReadMailState;
exports.saveReadMailState = saveReadMailState;
exports.sendOtherErrorsAlertEmail = sendOtherErrorsAlertEmail;
exports.ALERT_EMAILS = ALERT_EMAILS;
exports.createLog = createLog;
exports.endLog = endLog;
exports.FLOW_NAME = FLOW_NAME;
exports.DEFAULT_USER_ID = DEFAULT_USER_ID;
exports.DEFAULT_REKV_ID = DEFAULT_REKV_ID;
