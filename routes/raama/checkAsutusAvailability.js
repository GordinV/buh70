'use strict';
const db = require('./../../libs/db');
//const config = require('./../../config/default.json');
const config = require('./../../config/narvalv.json');
const mailer = require('./sendFinBitReport');

const DEFAULT_USER_ID = 2477;
const DEFAULT_REKV_ID = 63;
const FLOW_NAME = 'checkAsutusAvailability';
const SOURCE_FLOW_NAME = 'getEarved'; // flow лога с сырым массивом счетов из FinBit (см. getEarvedFromFinBit.js)
const MAIN_IMPORT_FLOW_NAME = 'docs.sp_loe_earved'; // основной лог импорта (в result.source_log_id хранит id лога getEarved)
const SOURCE_LOG_WINDOW_HOURS = 24;
const DEFAULT_EXTRA_EMAILS = ['vladislav.gordin@bs2.ee']; // копия извещения, если агент не передал extra_emails

/**
 * Express handler для роута POST /task/checkAsutusAvailability/
 * Проверяет наличие контр-агентов (по рег.кодам из счетов FinBit) в libs.asutus через
 * libs.check_asutus_availibility. Работает асинхронно: создает лог, запускает проверку в фоне,
 * сразу возвращает log_id.
 *
 * Параметры: user_id, rekv_id, log_id (необязательный: id лога getEarved либо основного лога docs.sp_loe_earved;
 * если не передан - берется последний лог getEarved за последние 24 часа).
 *
 * Пример: curl.exe -X POST http://localhost:3000/task/checkAsutusAvailability/ -H "Content-Type: application/json" -d "{\"user_id\":11770,\"rekv_id\":63}"
 */
exports.main = async (req, res) => {
    const params = Object.assign({}, req.query, req.body, req.params);

    const userId = Number(params.user_id || params.userid_id || params.userId || DEFAULT_USER_ID);
    const rekvId = Number(params.rekv_id || params.rekvid || params.rekvId || DEFAULT_REKV_ID);
    const sourceLogParam = params.log_id || params.logId || null;

    let logId = null;

    try {
        // 1. Создаем запись в ou.logs о старте процесса
        const logResult = await createLog(rekvId, userId);
        if (logResult && logResult.data && logResult.data[0]) {
            logId = logResult.data[0].id;
        }

        if (!logId) {
            throw new Error('Лог-запись не создана (не удалось получить log_id)');
        }

        // 2. Фоновая проверка БЕЗ ожидания завершения
        runCheckInBackground(logId, userId, sourceLogParam, parseEmails(params.extra_emails || params.extraEmails));

        // 3. Сразу возвращаем log_id для отслеживания
        return res.status(200).send({
            status: 200,
            result: 1,
            log_id: logId,
            data: {
                action: 'checkAsutusAvailability',
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
        console.error('Error starting checkAsutusAvailability task:', error);

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
            error_message: `Start check failed: ${error.message}`
        });
    }
};

/**
 * Фоновая функция: выполняет проверку и фиксирует результат в ou.logs
 */
async function runCheckInBackground(logId, userId, sourceLogParam, extraEmails) {
    try {
        console.log(`[checkAsutusAvailability] Background check started. log_id: ${logId}, userId: ${userId}`);
        const checkResult = await checkAsutusAvailability(userId, sourceLogParam);
        console.log(`[checkAsutusAvailability] Background check finished. log_id: ${logId}`, checkResult);

        // извещение по почте (ошибка отправки не должна ронять проверку)
        const mailInfo = await notifyMissingAsutused(checkResult, userId, extraEmails);

        await endLog(logId, 'success', null, checkResult, mailInfo);
    } catch (error) {
        console.error(`[checkAsutusAvailability] Background check failed. log_id: ${logId}`, error);

        try {
            await endLog(logId, 'failed', error.message);
        } catch (logErr) {
            console.error(`[checkAsutusAvailability] Failed to update error log for log_id: ${logId}`, logErr);
        }
    }
}

/**
 * Приводит email-параметр (массив или строка через запятую/;) к массиву уникальных адресов
 */
function parseEmails(value) {
    if (!value) return [];
    const list = Array.isArray(value) ? value : String(value).split(/[;,]/);
    const result = [];
    list.forEach(function (e) {
        const v = String(e || '').trim().toLowerCase();
        if (v.indexOf('@') > 0 && result.indexOf(v) === -1) {
            result.push(v);
        }
    });
    return result;
}

/**
 * Собирает получателей: адреса из changes (поле email) + дополнительные
 */
function collectRecipients(details, extraEmails) {
    const fromChanges = (details || []).map(function (d) {
        return d && d.email ? d.email : '';
    });
    const extra = extraEmails && extraEmails.length ? extraEmails : DEFAULT_EXTRA_EMAILS;
    return parseEmails(fromChanges.concat(extra));
}

/**
 * Тема, текст и HTML-таблица извещения о недостающих организациях
 */
function formatMissingAsutusedEmail(regkoodid) {
    const esc = mailer.escapeHtml;
    const subject = 'Teavitus: puuduvad asutused (' + regkoodid.length + ' tk)';

    let text = 'Tere!\n\nFinBit e-arvete impordil leiti asutused, mida ei ole andmebaasis (libs.asutus). ' +
        'Palun lisa need andmebaasi:\n\n';
    regkoodid.forEach(function (r, i) {
        text += (i + 1) + '. ' + r + '\n';
    });
    text += '\nKokku: ' + regkoodid.length + ' asutus(t).\n\nLugupidamisega,\nBuh70';

    const rows = regkoodid.map(function (r, i) {
        return '<tr><td style="border: 1px solid #ddd; padding: 8px;">' + (i + 1) + '</td>' +
            '<td style="border: 1px solid #ddd; padding: 8px;">' + esc(r) + '</td></tr>';
    }).join('');
    const html = '<p>Tere!</p>' +
        '<p>FinBit e-arvete impordil leiti asutused, mida ei ole andmebaasis (libs.asutus). Palun lisa need andmebaasi:</p>' +
        '<table style="border-collapse: collapse;">' +
        '<thead><tr><th style="border: 1px solid #ddd; padding: 8px; background: #f2f2f2;">#</th>' +
        '<th style="border: 1px solid #ddd; padding: 8px; background: #f2f2f2;">Registrikood</th></tr></thead>' +
        '<tbody>' + rows + '</tbody></table>' +
        '<p>Kokku: ' + regkoodid.length + ' asutus(t).</p><p>Lugupidamisega,<br>Buh70</p>';
    return {subject: subject, text: text, html: html};
}

/**
 * Отправляет извещение о недостающих организациях (один раз на лог getEarved).
 * @returns {Promise<Object|null>} объект для ou.logs.propertis.mail или null, если письмо не требуется
 */
async function notifyMissingAsutused(checkResult, userId, extraEmails, transporter) {
    if (!checkResult || !checkResult.totalMissing || !checkResult.source_log_id) {
        return null;
    }

    const sourceLogId = checkResult.source_log_id;
    const recipients = collectRecipients(checkResult.details, extraEmails);
    const mailInfo = {
        sent: false,
        skipped: null,
        recipients: recipients,
        missing: checkResult.missing,
        source_log_id: sourceLogId,
        sent_at: null,
        message_id: null,
        error: null
    };

    try {
        // защита от дублей: на один лог getEarved письмо шлем один раз
        const prev = await db.queryDb(`select propertis -> 'asutus_mail' as asutus_mail from ou.logs where id = $1`,
            [sourceLogId], null, null, null, null, config);
        const prevRow = prev && Array.isArray(prev.data) && prev.data[0] ? prev.data[0] : null;
        if (prevRow && prevRow.asutus_mail && prevRow.asutus_mail.sent) {
            mailInfo.skipped = 'duplicate';
            return mailInfo;
        }

        if (recipients.length === 0) {
            mailInfo.skipped = 'no_recipients';
            return mailInfo;
        }

        const msg = formatMissingAsutusedEmail(checkResult.missing);
        const smtpConfig = await mailer.getSmtpConfig(userId);
        const info = await mailer.sendHtmlEmail(recipients, msg.subject, msg.text, msg.html, smtpConfig, transporter);

        mailInfo.sent = true;
        mailInfo.sent_at = new Date().toISOString();
        mailInfo.message_id = info && info.messageId ? info.messageId : null;

        // отметка на логе getEarved, чтобы не слать повторно
        await db.queryDb(`update ou.logs
                          set propertis = propertis || jsonb_build_object('asutus_mail', $1::jsonb)
                          where id = $2`,
            [JSON.stringify(mailInfo), sourceLogId], null, null, null, null, config);
    } catch (error) {
        console.error('[checkAsutusAvailability] Email notification failed:', error);
        mailInfo.error = error.message;
    }
    return mailInfo;
}

/**
 * Находит id лога getEarved с сырым массивом счетов.
 * - sourceLogParam задан: если это лог getEarved - используем его, если основной лог импорта - берем result.source_log_id
 * - не задан: последний лог getEarved за SOURCE_LOG_WINDOW_HOURS часов
 * @returns {Promise<number|null>}
 */
async function findSourceLogId(sourceLogParam) {
    const paramId = Number(sourceLogParam);

    if (Number.isInteger(paramId) && paramId > 0) {
        const sqlById = `select l.id,
                                l.propertis ->> 'flow'                  as flow,
                                l.propertis -> 'result' ->> 'source_log_id' as source_log_id
                         from ou.logs l
                         where l.id = $1`;
        const r = await db.queryDb(sqlById, [paramId], null, null, null, null, config);
        const row = r && Array.isArray(r.data) && r.data[0] ? r.data[0] : null;
        if (!row) return null;
        if (row.flow === SOURCE_FLOW_NAME) return Number(row.id);
        if (row.flow === MAIN_IMPORT_FLOW_NAME && row.source_log_id) return Number(row.source_log_id);
        return null;
    }

    const sqlLatest = `select l.id
                       from ou.logs l
                       where l.propertis ->> 'flow' = $1
                         and (l.propertis ->> 'exec_start')::timestamptz >= now() - ($2::integer * interval '1 hour')
                       order by l.id desc
                       limit 1`;
    const r = await db.queryDb(sqlLatest, [SOURCE_FLOW_NAME, SOURCE_LOG_WINDOW_HOURS], null, null, null, null, config);
    const row = r && Array.isArray(r.data) && r.data[0] ? r.data[0] : null;
    return row ? Number(row.id) : null;
}

/**
 * Вызывает libs.check_asutus_availibility и читает список отсутствующих контр-агентов из ou.logs.changes
 * @returns {Promise<Object>} { error_code, totalMissing, missing: [regkood], details: [...], source_log_id, error_message }
 */
async function checkAsutusAvailability(userId, sourceLogParam) {
    try {
        const sourceLogId = await findSourceLogId(sourceLogParam);

        if (!sourceLogId) {
            // штатная ситуация: за период не было получения счетов из FinBit
            return {
                error_code: 0,
                result: 0,
                totalMissing: 0,
                missing: [],
                details: [],
                source_log_id: null,
                error_message: 'Arveid ei leitud (getEarved logi puudub)'
            };
        }

        const sql = `SELECT * FROM libs.check_asutus_availibility($1::INTEGER, $2::INTEGER);`;
        console.log('start check_asutus_availibility for userId:', userId, 'source log:', sourceLogId);
        const l_result = await db.queryDb(sql, [userId, sourceLogId], null, null, null, null, config);
        console.log('finish check_asutus_availibility', l_result);

        const row = (l_result && Array.isArray(l_result.data) && l_result.data[0]) ? l_result.data[0] : (l_result || {});
        const errCode = Number(row.error_code !== undefined && row.error_code !== null ? row.error_code : 0);
        const errMsg = row.error_message || null;

        if (errCode !== 0) {
            throw new Error(errMsg || `libs.check_asutus_availibility returned error code ${errCode}`);
        }

        // список отсутствующих контр-агентов процедура сохраняет в ou.logs.changes
        const changesRes = await db.queryDb(`select changes from ou.logs where id = $1`, [sourceLogId], null, null, null, null, config);
        const changesRow = changesRes && Array.isArray(changesRes.data) && changesRes.data[0] ? changesRes.data[0] : null;
        const details = changesRow && Array.isArray(changesRow.changes) ? changesRow.changes : [];
        const missing = details
            .map(function (d) {
                return d && d.puuduvad_asutused ? String(d.puuduvad_asutused).trim() : '';
            })
            .filter(function (v) {
                return v !== '';
            });

        const totalMissing = missing.length;
        return {
            error_code: 0,
            result: totalMissing,
            totalMissing: totalMissing,
            missing: missing,
            details: details,
            source_log_id: sourceLogId,
            error_message: totalMissing > 0
                ? `Leidnud puuduvad asutused: ${missing.join(', ')}`
                : (errMsg || 'Kõik asutused on olemas')
        };
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

/**
 * Логгирование старта задачи в ou.logs
 */
async function createLog(rekvId = DEFAULT_REKV_ID, userId = DEFAULT_USER_ID) {
    const sql = `insert into ou.logs (rekvid, user_id, propertis)
                 values ($1, $2, jsonb_build_object('flow', $3::text, 'exec_start', (clock_timestamp())))
                 returning id;`;

    try {
        console.log('start create log for flow:', FLOW_NAME);
        const l_result = await db.queryDb(sql, [rekvId, userId, FLOW_NAME], null, null, null, null, config);
        console.log('finish create log', FLOW_NAME, l_result);
        return l_result;
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

/**
 * Логгирование окончания задачи (успех / ошибка) с сохранением result и response
 */
async function endLog(logId, status = 'success', errorMessage = null, resultData = null, mailInfo = null) {
    if (!logId) return;

    let resultJson = null;
    let responseText = null;

    if (resultData !== null && resultData !== undefined) {
        responseText = resultData.error_message || null;
        try {
            resultJson = JSON.stringify(resultData);
        } catch (e) {
            resultJson = JSON.stringify({raw: String(resultData)});
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
                 || case when $6::text is not null then jsonb_build_object('mail', $6::jsonb) else '{}'::jsonb end
                 where id = $5;`;

    try {
        console.log('start endLog for id:', logId, 'status:', status, 'response:', responseText);
        await db.queryDb(sql, [status, errorMessage, resultJson, responseText, logId, mailInfo ? JSON.stringify(mailInfo) : null], null, null, null, null, config);
        console.log('finish endLog');
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

exports.checkAsutusAvailability = checkAsutusAvailability;
exports.findSourceLogId = findSourceLogId;
exports.runCheckInBackground = runCheckInBackground;
exports.notifyMissingAsutused = notifyMissingAsutused;
exports.collectRecipients = collectRecipients;
exports.parseEmails = parseEmails;
exports.createLog = createLog;
exports.endLog = endLog;
exports.FLOW_NAME = FLOW_NAME;
exports.SOURCE_FLOW_NAME = SOURCE_FLOW_NAME;
