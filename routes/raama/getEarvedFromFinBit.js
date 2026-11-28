'use strict';
const getNow = require('./../../libs/getNow');
const db = require("../../libs/db");
const executePostTask = require('../task/executePostTask');
const sendFinBitReport = require('./sendFinBitReport');
const deps = {
    getXMLFile: require('../ai/e-arved/getXMLFile'),
    XMLtoJson: require('../ai/e-arved/xml_to_json'),
    executeTask: function (docId) {
        return executePostTask.executeTask(docId);
    },
    sendFinBitReport: sendFinBitReport
};

const FLOW_NAME = 'docs.sp_loe_earved';
const ROBOT_USER = 'Earved robot';
const AGENT_LOG_NAME = 'getEarved'; // имя агента в ou.logs для записи с сырым массивом счетов

//const config = require("../../config/default.json");
const config = require("../../config/narvalv.json");


/**
 * Проверка флага агентского режима в параметрах запроса
 * @param {Object} params
 * @returns {boolean}
 */
function checkIsAgent(params) {
    const val = params.is_agent !== undefined
        ? params.is_agent
        : (params.isAgent !== undefined ? params.isAgent : params.agent);

    if (val !== undefined && val !== null) {
        return val === true || val === 'true' || val === 1 || val === '1';
    }
    return params.mode === 'agent';
}

/**
 * Express handler для импорта счетов из FinBit
 * Поддерживает два режима работы:
 * 1. Обычный (по умолчанию): сохранение таски через ou.sp_salvesta_task и запуск executeTask
 * 2. Агентский (при передаче is_agent / isAgent / agent): только выкачка счетов из FinBit,
 *    сохранение массива в ou.logs (flow = getEarved) и возврат log_id. Проверку контр-агентов выполняет агент
 *    check_asutus (/task/checkAsutusAvailability/), разбор и сохранение счетов - агент import_earved (/task/importEarved/)
 */
const post = async (req, res) => {
    try {
        const params = Object.assign({}, req.query, req.body, req.params);
        const userId = params.userid_id || params.user_id || params.userId;
        const rawRekvId = params.rekv_id || params.rekvid || params.rekvId;
        const rekvId = (rawRekvId !== undefined && rawRekvId !== null && rawRekvId !== '') ? Number(rawRekvId) : null;
        const execDate = params.date_query_from ? params.date_query_from : getNow(); // доп параметр дата
        const isAgent = checkIsAgent(params);
        const flowName = params.flow_name || params.flowName || FLOW_NAME;
        const module = 'RAAMA';

        console.log('params', execDate, params, 'isAgent:', isAgent);

        if (!userId && !isAgent) {
            return res.send({status: 500, result: null, error_message: 'User ID is missing'});
        }

        const queryUserId = userId !== undefined && userId !== null ? userId : null;

        // получаем конфигурацию учреждений (массив учреждений)
        let sql = `select distinct on (r.id)
                       r.properties ->>'earved' as hash, c.properties->>'earved' as earved_host, r.id as rekv_id, r.regkood as rekv_regkood, u.id as user_id
                   from
                       ou.config c
                       inner join ou.rekv r
                   on r.id = c.rekvid
                       inner join ou.userid u on u.rekvid = r.id
                    where
                       ${isAgent ? `(u.id = $1::integer or u.kasutaja = '${ROBOT_USER}')` : "u.id = $1::integer"}
                       ${!isAgent && rekvId ? 'and r.id = $2::integer' : ''}
                       and coalesce(r.properties ->>'earved', '') <> ''
                    and u.status < 3  
                    order by r.id, (case when u.id = $1::integer then 1 else 2 end)`;

        const sqlParams = (!isAgent && rekvId) ? [queryUserId, rekvId] : [queryUserId];
        let eArveConfig = await db.queryDb(sql, sqlParams, null, null, null, null, config);

        // проверка получения конфигурации
        if (!eArveConfig || !eArveConfig.data || !eArveConfig.data.length) {
            return res.send({status: 500, result: null, error_message: 'Конфигурация e-arved для учреждения не найдена'});
        }

        let l_rekvId = (!isAgent && rekvId) ? rekvId : eArveConfig.data[0].rekv_id;
        let l_userId = userId || eArveConfig.data[0].user_id;

        if (!l_userId) {
            return res.send({status: 500, result: null, error_message: 'User ID is missing'});
        }

        // Строим список активных источников (с hash) и карту учреждений по regkood для маршрутизации счетов
        const regkoodMap = {};
        const activeConfigs = [];
        for (const conf of eArveConfig.data) {
            if (!isAgent && rekvId && Number(conf.rekv_id) !== rekvId) {
                continue;
            }
            const targetRekvId = (!isAgent && rekvId) ? rekvId : conf.rekv_id;
            const targetUserId = (!isAgent && rekvId && userId) ? Number(userId) : (conf.user_id || l_userId);
            const targetRegkood = conf.rekv_regkood ? String(conf.rekv_regkood).trim() : '';
            const entry = {
                rekvId: targetRekvId,
                userId: targetUserId,
                regkood: targetRegkood,
                hash: conf.hash,
                earvedHost: conf.earved_host
            };
            activeConfigs.push(entry);
            if (!isAgent && targetRegkood && !regkoodMap[targetRegkood]) {
                regkoodMap[targetRegkood] = entry;
            }
        }

        // Для агентского пути карту regkoodMap строим по ВСЕМ учреждениям ou.rekv (r.parentid < 999)
        // с активным пользователем 'Earved robot' — включая учреждения без собственного hash
        if (isAgent) {
            const allRekvSql = `select distinct on (r.id)
                                    r.id as rekv_id,
                                    r.regkood as rekv_regkood,
                                    u.id as user_id
                                from
                                    ou.rekv r
                                    left join ou.userid u
                                        on u.rekvid = r.id
                                       and u.kasutaja = '${ROBOT_USER}'
                                       and u.status < 3
                                where
                                    coalesce(btrim(r.regkood), '') <> ''
                                    and r.parentid < 999
                                order by r.id, u.id desc`;
            const allRekvRes = await db.queryDb(allRekvSql, null, null, null, null, null, config);
            if (allRekvRes && Array.isArray(allRekvRes.data)) {
                for (let k = 0; k < allRekvRes.data.length; k++) {
                    const row = allRekvRes.data[k];
                    const rk = row && row.rekv_regkood ? String(row.rekv_regkood).trim() : '';
                    if (rk) {
                        const existing = regkoodMap[rk];
                        // При совпадении regkood у нескольких организаций предпочитаем ту, у которой есть активный робот
                        if (!existing || (!existing.userId && row.user_id)) {
                            regkoodMap[rk] = {
                                rekvId: row.rekv_id,
                                userId: row.user_id || null,
                                regkood: rk
                            };
                        }
                    }
                }
            }
            // Если учреждение из eArveConfig отсутствует в allRekvRes (например, в упрощённых моках), дополним из activeConfigs
            for (let k = 0; k < activeConfigs.length; k++) {
                const entry = activeConfigs[k];
                if (entry.regkood && !regkoodMap[entry.regkood]) {
                    regkoodMap[entry.regkood] = {
                        rekvId: entry.rekvId,
                        userId: entry.userId,
                        regkood: entry.regkood
                    };
                }
            }
        }

        // Проходим по уникальным парам (hash, earved_host), запрашиваем e-счета и маршрутизируем по rekv_regkood
        const batches = [];
        const batchesByRekv = {};
        const unmatched = [];
        const fetchedSources = {};
        const seenInvoices = {};

        for (const conf of activeConfigs) {
            const itemRekvId = conf.rekvId;
            const itemUserId = conf.userId;
            const hash = conf.hash;
            const earvedHost = conf.earvedHost;

            if (!hash) {
                console.warn(`[getEarvedFromFinBit] Puudub hash asutusele rekvid: ${itemRekvId}`);
                continue;
            }

            // Выкачиваем один раз на уникальную пару (hash, earved_host)
            const sourceKey = String(hash).trim() + '||' + String(earvedHost || '').trim();
            if (fetchedSources[sourceKey]) {
                console.log(`[getEarvedFromFinBit] Allikas (hash+host) juba päritud, jätan vahele rekvid: ${itemRekvId}`);
                continue;
            }
            fetchedSources[sourceKey] = true;

            console.log('hash', hash);
            console.log('itemRekvId, itemUserId', itemRekvId, itemUserId);

            try {
                const xml = await deps.getXMLFile(hash, earvedHost, execDate);
                const json = await deps.XMLtoJson(xml, { rekvid: itemRekvId, userid: itemUserId });

                console.log('json', json);

                if (json && Array.isArray(json) && json.length > 0) {
                    for (let i = 0; i < json.length; i++) {
                        const inv = json[i];
                        if (!inv || typeof inv !== 'object') {
                            continue;
                        }
                        const hasNestedData = !!(inv.data && typeof inv.data === 'object');
                        const data = hasNestedData ? inv.data : inv;
                        const invRegkood = data.rekv_regkood ? String(data.rekv_regkood).trim() : '';
                        const invSellerRegkood = data.asutusid ? String(data.asutusid).trim() : '';
                        const invNumber = data.number ? String(data.number).trim() : '';

                        // Дедупликация по (rekv_regkood покупателя, asutusid продавца, number); если asutusid пуст — не дедуплицируем
                        if (invNumber && invSellerRegkood) {
                            const dedupScope = invRegkood || ('_src_' + itemRekvId);
                            const dedupKey = dedupScope + '||' + invSellerRegkood + '||' + invNumber;
                            if (seenInvoices[dedupKey]) {
                                console.log(`[getEarvedFromFinBit] Duplikaat arve jäetud vahele: ${invNumber} (seller=${invSellerRegkood}, regkood=${invRegkood || 'puudub'})`);
                                continue;
                            }
                            seenInvoices[dedupKey] = true;
                        }

                        let targetRekvId = itemRekvId;
                        let targetUserId = itemUserId;

                        if (invRegkood) {
                            const targetConf = regkoodMap[invRegkood];
                            if (!targetConf) {
                                const errText = 'Asutust regkoodiga ' + invRegkood + ' ei leitud';
                                console.warn(`[getEarvedFromFinBit] Arve ${invNumber || ''}: ${errText} (source_rekv_id=${itemRekvId})`);
                                unmatched.push({
                                    number: invNumber || null,
                                    rekv_regkood: invRegkood,
                                    source_rekv_id: itemRekvId,
                                    error: errText
                                });
                                continue;
                            }
                            if (!targetConf.userId) {
                                const noRobotErr = 'Asutusel ' + invRegkood + ' puudub kasutaja ' + ROBOT_USER;
                                console.warn(`[getEarvedFromFinBit] Arve ${invNumber || ''}: ${noRobotErr} (source_rekv_id=${itemRekvId})`);
                                unmatched.push({
                                    number: invNumber || null,
                                    rekv_regkood: invRegkood,
                                    source_rekv_id: itemRekvId,
                                    error: noRobotErr
                                });
                                continue;
                            }
                            targetRekvId = targetConf.rekvId;
                            targetUserId = targetConf.userId;
                            // Перезаписываем rekvid и userid на целевое учреждение
                            if (hasNestedData) {
                                inv.data = Object.assign({}, inv.data, {
                                    rekvid: targetRekvId,
                                    userid: targetUserId
                                });
                            } else {
                                inv.rekvid = targetRekvId;
                                inv.userid = targetUserId;
                            }
                        }

                        if (!batchesByRekv[targetRekvId]) {
                            batchesByRekv[targetRekvId] = {
                                rekvId: targetRekvId,
                                userId: targetUserId,
                                json: []
                            };
                            batches.push(batchesByRekv[targetRekvId]);
                        }
                        batchesByRekv[targetRekvId].json.push(inv);
                    }
                    console.log(`[getEarvedFromFinBit] Töödeldud ${json.length} arvet allikast rekvid: ${itemRekvId}`);
                } else {
                    console.log(`[getEarvedFromFinBit] Arveid ei leitud asutusele rekvid: ${itemRekvId}`);
                }
            } catch (fetchErr) {
                console.error(`[getEarvedFromFinBit] Viga asutuse rekvid: ${itemRekvId} arvete pärimisel:`, fetchErr.message || fetchErr);
            }
        }

        const unmatchedForLog = unmatched.map(function (u) {
            return {
                number: u.number,
                rekv_regkood: u.rekv_regkood,
                source_rekv_id: u.source_rekv_id,
                error: u.error
            };
        });

        // проверка количества найденных счетов по всем учреждениям
        if (!batches.length) {
            if (isAgent) {
                // В агентском режиме отсутствие новых счетов — штатная ситуация (0 счетов за дату).
                // Создаем и закрываем лог в ou.logs, чтобы оркестратор получил валидный log_id
                let emptyLogId = null;
                try {
                    // агент getEarved только выкачивает счета, поэтому flow = getEarved
                    const logResult = await createLog(l_rekvId, l_userId, AGENT_LOG_NAME);
                    if (logResult && logResult.data && logResult.data[0]) {
                        emptyLogId = logResult.data[0].id;
                    }
                    if (emptyLogId) {
                        const emptyMsg = unmatched.length > 0
                            ? ('Arveid ei leitud (0 arvet, sobimatuid: ' + unmatched.length + ')')
                            : 'Arveid ei leitud (0 arvet)';
                        await endLog(emptyLogId, 'success', null, {
                            totalFetched: 0,
                            totalImported: 0,
                            totalUnmatched: unmatchedForLog.length,
                            unmatched: unmatchedForLog,
                            error_message: emptyMsg,
                            batches: []
                        });
                    }
                } catch (logErr) {
                    console.error('[getEarvedFromFinBit] Error creating empty log:', logErr);
                }

                return res.status(200).send({
                    status: 200,
                    result: 1,
                    log_id: emptyLogId,
                    data: {
                        action: 'Import FinBit arved',
                        status: 'COMPLETED',
                        log_id: emptyLogId,
                        result: {
                            doc_id: emptyLogId,
                            error_code: 0,
                            error_message: null,
                            tulemused: 'Arveid ei leitud (0 arvet)',
                            unmatched: unmatchedForLog,
                            totalUnmatched: unmatchedForLog.length
                        }
                    },
                    error_message: null
                });
            }

            const noMatchErrorMsg = unmatched.length > 0
                ? ('Arveid ei leitud: ' + unmatched.map(function (u) { return u.error; }).join('; '))
                : 'Arveid ei leitud';
            return res.send({
                status: 500,
                result: null,
                error_message: noMatchErrorMsg,
                unmatched: unmatched,
                totalUnmatched: unmatched.length
            });
        }

        // В зависимости от флага isAgent выбираем логику работы
        if (!isAgent) {
            // === СТАРАЯ ЛОГИКА ===
            // готовим параметры, сохраняем таску (один вызов docs.sp_loe_earved_batches с параметризацией $1)
            let saveResult;
            try {
                const saveParams = buildBatchesTaskSql(batches, unmatched);
                saveResult = await db.queryDb(
                    'select ou.sp_salvesta_task($1::text, $2::text, $3::integer)',
                    [saveParams, 'Loe FinBit arved', l_userId],
                    null, null, null, null, config
                );
                console.log('saveResult', saveResult);

            } catch (e) {
                console.log('catch', e);
                return res.send({status: 500, result: null, error_message: e.message || e});
            }

            let taskId = null;
            if (saveResult && saveResult.data && Array.isArray(saveResult.data) && saveResult.data.length && saveResult.data[0].sp_salvesta_task) {
                taskId = saveResult.data[0].sp_salvesta_task;
                runPostTaskInBackground(taskId, l_rekvId, l_userId);
            }

            // ответ
            return res.send({
                status: 200, result: 1, data: {
                    action: 'Import FinBit arved',
                    result: {
                        doc_id: taskId || 1,
                        error_code: 0,
                        error_message: null,
                        tulemused: saveResult,
                        unmatched: unmatched,
                        totalUnmatched: unmatched.length
                    },
                    data: saveResult
                },
                unmatched: unmatched,
                totalUnmatched: unmatched.length
            });
        } else {
            // === АГЕНТСКАЯ ЛОГИКА: только выкачка счетов (flow = getEarved) ===
            // Разбор и сохранение счетов выполняет отдельный агент import_earved (POST /task/importEarved/)
            // после проверки контр-агентов агентом check_asutus.
            let logId = null;

            try {
                // Сохраняем полученный из FinBit массив счетов в ou.logs (flow = getEarved) и получаем log_id,
                // который передается дальше (check_asutus, import_earved)
                logId = await saveFetchedArvedLog(l_rekvId, l_userId, batches, unmatchedForLog);

                if (!logId) {
                    throw new Error('Лог-запись не создана (не удалось получить log_id)');
                }

                // Выкачка завершена синхронно - сразу возвращаем log_id
                return res.status(200).send({
                    status: 200,
                    result: 1,
                    log_id: logId,
                    data: {
                        action: 'Import FinBit arved',
                        status: 'COMPLETED',
                        log_id: logId,
                        result: {
                            doc_id: logId,
                            error_code: 0,
                            error_message: null,
                            tulemused: 'COMPLETED'
                        }
                    },
                    error_message: null
                });

            } catch (error) {
                console.error('Error starting import FinBit arved task:', error);

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
                    error_message: `Start import failed: ${error.message}`
                });
            }
        }
    } catch (err) {
        console.error('getEarvedFromFinBit error:', err);
        return res.send({status: 500, result: null, error_message: err.message || err});
    }
};

/**
 * Формирует один SQL-вызов docs.sp_loe_earved_batches($$<JSON>$$::jsonb) для ou.sp_salvesta_task.
 * Если JSON содержит '$$', подбирается уникальный тег долларовой кавычки ($finbit$, $finbit_1$, ...).
 * @param {Array<{userId: number, json: Array}>} batches
 * @returns {string}
 */
function buildBatchesTaskSql(batches, unmatched) {
    const payload = (batches || []).map(function (b) {
        return {
            user_id: b.userId,
            data: b.json
        };
    });
    if (Array.isArray(unmatched) && unmatched.length > 0) {
        for (let i = 0; i < unmatched.length; i++) {
            const u = unmatched[i];
            if (!u) continue;
            payload.push({
                user_id: null,
                number: u.number || null,
                rekv_regkood: u.rekv_regkood || null,
                error: u.error || ('Asutust regkoodiga ' + (u.rekv_regkood || '') + ' ei leitud')
            });
        }
    }
    const jsonText = JSON.stringify(payload);
    let tag = '$$';
    if (jsonText.indexOf('$$') !== -1) {
        tag = '$finbit$';
        let suffix = 1;
        while (jsonText.indexOf(tag) !== -1) {
            tag = '$finbit_' + suffix + '$';
            suffix += 1;
        }
    }
    return 'select * from docs.sp_loe_earved_batches(' + tag + jsonText + tag + '::jsonb)';
}

/**
 * Получает SMTP-конфигурацию строго из карточки ou.userid (сначала пользователь, затем робот учреждения).
 * Переменные окружения (.env) и зашитые пароли не используются.
 */
async function getTaskSmtpConfig(userId, rekvId) {
    const mailer = deps.sendFinBitReport;
    if (mailer && typeof mailer.getUserMailAccount === 'function') {
        try {
            const acc = await mailer.getUserMailAccount(userId);
            if (acc && acc.smtp) {
                return acc.smtp;
            }
        } catch (userAccErr) {
            console.warn('[getEarvedFromFinBit] User SMTP account unavailable for userId ' + userId + ': ' + (userAccErr.message || userAccErr));
        }
    }
    if (mailer && typeof mailer.getRobotSmtpConfig === 'function') {
        return await mailer.getRobotSmtpConfig(rekvId);
    }
    throw new Error('smtp_config_not_found');
}

/**
 * Форматирует текстовое и HTML письмо об ошибке или частичном импорте задачи ou.task (на эстонском языке)
 */
function formatTaskErrorEmail(taskId, taskStatus, tulemused, errors) {
    const isFullError = Number(taskStatus) === 2;
    const subject = isFullError
        ? ('Loe FinBit arved: VIGA (task ' + taskId + ')')
        : ('Loe FinBit arved: osaliselt imporditud (task ' + taskId + ')');
    const errList = Array.isArray(errors) ? errors : [];
    const escapeHtml = (deps.sendFinBitReport && typeof deps.sendFinBitReport.escapeHtml === 'function')
        ? deps.sendFinBitReport.escapeHtml
        : function (s) { return s ? String(s) : ''; };

    let text = 'Tere!\n\n';
    text += isFullError
        ? ('FinBit e-arvete import (task #' + taskId + ') ebaõnnestus.\n\n')
        : ('FinBit e-arvete import (task #' + taskId + ') lõppes osaliselt vigadega.\n\n');
    if (tulemused) {
        text += 'Tulemus: ' + tulemused + '\n\n';
    }
    if (errList.length > 0) {
        text += 'Vead:\n';
        errList.forEach(function (item, idx) {
            const nr = (item && item.number) ? item.number : '-';
            const asutus = (item && (item.asutus || item.asutusid || item.rekv_regkood)) ? (item.asutus || item.asutusid || item.rekv_regkood) : '-';
            const errMsg = (item && item.error) ? item.error : 'Tundmatu viga';
            text += (idx + 1) + '. Arve nr: ' + nr + ' | Asutus: ' + asutus + ' | Viga: ' + errMsg + '\n';
        });
    }
    text += '\nLugupidamisega,\nBuh70';

    let rowsHtml = '';
    if (errList.length > 0) {
        rowsHtml = errList.map(function (item, idx) {
            const nr = escapeHtml((item && item.number) ? item.number : '-');
            const asutus = escapeHtml((item && (item.asutus || item.asutusid || item.rekv_regkood)) ? (item.asutus || item.asutusid || item.rekv_regkood) : '-');
            const errMsg = escapeHtml((item && item.error) ? item.error : 'Tundmatu viga');
            return '<tr>' +
                '<td style="border: 1px solid #ddd; padding: 6px; text-align: center;">' + (idx + 1) + '</td>' +
                '<td style="border: 1px solid #ddd; padding: 6px;">' + nr + '</td>' +
                '<td style="border: 1px solid #ddd; padding: 6px;">' + asutus + '</td>' +
                '<td style="border: 1px solid #ddd; padding: 6px;">' + errMsg + '</td>' +
                '</tr>';
        }).join('\n');
    }

    let html = '<!DOCTYPE html><html><head><meta charset="utf-8"></head>' +
        '<body style="font-family: Arial, sans-serif; font-size: 14px; color: #333;">' +
        '<p>Tere!</p>' +
        '<p>' + escapeHtml(isFullError
            ? ('FinBit e-arvete import (task #' + taskId + ') ebaõnnestus.')
            : ('FinBit e-arvete import (task #' + taskId + ') lõppes osaliselt vigadega.')) + '</p>';
    if (tulemused) {
        html += '<p><strong>Tulemus:</strong> ' + escapeHtml(tulemused) + '</p>';
    }
    if (errList.length > 0) {
        html += '<table style="border-collapse: collapse; width: 100%; max-width: 700px; margin: 12px 0;">' +
            '<thead><tr style="background-color: #f2f4f8;">' +
            '<th style="border: 1px solid #ddd; padding: 6px;">#</th>' +
            '<th style="border: 1px solid #ddd; padding: 6px; text-align: left;">Arve nr</th>' +
            '<th style="border: 1px solid #ddd; padding: 6px; text-align: left;">Asutus</th>' +
            '<th style="border: 1px solid #ddd; padding: 6px; text-align: left;">Viga</th>' +
            '</tr></thead><tbody>' + rowsHtml + '</tbody></table>';
    }
    html += '<p>Lugupidamisega,<br><strong>Buh70</strong></p></body></html>';

    return { subject: subject, text: text, html: html };
}

/**
 * Фоновое выполнение задачи ou.task (путь из UI, !isAgent):
 * 1. Создает лог импорта в ou.logs (flow = docs.sp_loe_earved)
 * 2. Дожидается ou.execute_task({doc_id})
 * 3. Читает итог задачи ou.task, закрывает лог импорта с imported/errors/ou_task_id
 * 4. При status=2 или непустом properties.errors шлет письмо инициатору (или на email учреждения)
 * 5. При status=1 вызывает рассылку sendFinBitReport.executeReport и сохраняет send_log_id в ou.task.properties
 */
async function runPostTaskInBackground(taskId, rekvId, userId) {
    let importLogId = null;
    try {
        try {
            const logResult = await createLog(rekvId, userId);
            if (logResult && logResult.data && logResult.data[0] && logResult.data[0].id) {
                importLogId = logResult.data[0].id;
            }
        } catch (createLogErr) {
            console.error('[getEarvedFromFinBit] Failed to create import log for task ' + taskId + ':', createLogErr);
        }

        try {
            await deps.executeTask(taskId);
        } catch (execErr) {
            console.error('[getEarvedFromFinBit] executeTask failed for task ' + taskId + ':', execErr);
            if (importLogId) {
                try {
                    await endLog(importLogId, 'failed', execErr.message || String(execErr), {
                        imported: [],
                        errors: [],
                        totalImported: 0,
                        totalFailed: 0,
                        ou_task_id: taskId
                    }, { ou_task_id: taskId });
                } catch (endErr) {
                    console.error('[getEarvedFromFinBit] Failed to close import log after executeTask error:', endErr);
                }
            }
            return;
        }

        const taskSql = 'SELECT t.id, t.user_id, t.status, t.tulemused, t.properties, ' +
            'u.rekvid AS rekv_id, ' +
            'nullif(btrim(u.properties ->> \'email\'), \'\') AS user_email, ' +
            'nullif(btrim(r.properties ->> \'email\'), \'\') AS rekv_email ' +
            'FROM ou.task t ' +
            'LEFT JOIN ou.userid u ON u.id = t.user_id ' +
            'LEFT JOIN ou.rekv r ON r.id = u.rekvid ' +
            'WHERE t.id = $1::integer LIMIT 1';
        const taskRes = await db.queryDb(taskSql, [taskId], null, null, null, null, config);
        const taskRow = (taskRes && Array.isArray(taskRes.data) && taskRes.data[0]) ? taskRes.data[0] : null;
        if (!taskRow) {
            console.warn('[getEarvedFromFinBit] ou.task row not found after executeTask, id=' + taskId);
            return;
        }

        let props = taskRow.properties;
        if (typeof props === 'string') {
            try {
                props = JSON.parse(props);
            } catch (parseErr) {
                props = {};
            }
        }
        if (!props || typeof props !== 'object') {
            props = {};
        }

        const taskStatus = Number(taskRow.status);
        const taskUserId = taskRow.user_id || userId;
        const taskRekvId = taskRow.rekv_id || rekvId;
        const imported = toArray(props.imported);
        const errors = toArray(props.errors);

        if (importLogId) {
            try {
                const logStatus = taskStatus === 2 ? 'failed' : 'success';
                const logError = taskStatus === 2 ? (taskRow.tulemused || 'Import ebaõnnestus') : null;
                const resultData = {
                    imported: imported,
                    errors: errors,
                    totalImported: imported.length,
                    totalFailed: errors.length,
                    ou_task_id: taskId
                };
                await endLog(importLogId, logStatus, logError, resultData, { ou_task_id: taskId });
            } catch (endLogErr) {
                console.error('[getEarvedFromFinBit] Failed to close import log ' + importLogId + ':', endLogErr);
            }
        }

        // Отправка письма об ошибке или частичном успехе инициатору / на email учреждения
        if (taskStatus === 2 || errors.length > 0) {
            try {
                const recipientEmail = (taskRow.user_email && String(taskRow.user_email).trim())
                    || (taskRow.rekv_email && String(taskRow.rekv_email).trim())
                    || null;
                if (recipientEmail) {
                    const smtpConfig = await getTaskSmtpConfig(taskUserId, taskRekvId);
                    const mail = formatTaskErrorEmail(taskId, taskStatus, taskRow.tulemused, errors);
                    await deps.sendFinBitReport.sendHtmlEmail(recipientEmail, mail.subject, mail.text, mail.html, smtpConfig);
                } else {
                    console.warn('[getEarvedFromFinBit] Cannot send error mail for task ' + taskId + ': recipient email missing');
                }
            } catch (mailErr) {
                console.error('[getEarvedFromFinBit] Error sending task error mail for task ' + taskId + ':', mailErr);
            }
        }

        // Рассылка уведомлений об импортированных счетах при status = 1 (полный или частичный успех)
        if (taskStatus === 1 && importLogId && deps.sendFinBitReport && typeof deps.sendFinBitReport.executeReport === 'function') {
            try {
                const reportRes = await deps.sendFinBitReport.executeReport(taskUserId, taskRekvId, importLogId);
                const sendLogId = reportRes ? (reportRes.logId || reportRes.log_id || null) : null;
                if (sendLogId) {
                    const updatePropSql = 'update ou.task ' +
                        'set properties = coalesce(properties, \'{}\'::jsonb) || jsonb_build_object(\'send_log_id\', $1::integer) ' +
                        'where id = $2::integer';
                    await db.queryDb(updatePropSql, [sendLogId, taskId], null, null, null, null, config);
                }
            } catch (notifyErr) {
                console.error('[getEarvedFromFinBit] Error executing sendFinBitReport for task ' + taskId + ':', notifyErr);
            }
        }
    } catch (err) {
        console.error('[getEarvedFromFinBit] Unexpected error in runPostTaskInBackground for task ' + taskId + ':', err);
    }
}

/**
 * Фоновая асинхронная функция выполнения docs.sp_loe_earved и обновления статуса в ou.logs
 */
async function runCalculationInBackground(logId, userId, batchesOrJson) {
    try {
        console.log(`[getEarvedFromFinBit] Background sp_loe_earved started. log_id: ${logId}, userId: ${userId}`);
        const calcResult = await loeEarved(userId, batchesOrJson);
        console.log(`[getEarvedFromFinBit] Background sp_loe_earved finished successfully. log_id: ${logId}`, calcResult);

        // Фиксируем успешное завершение и сохраняем детали импорта в ou.logs
        await endLog(logId, 'success', null, calcResult);
    } catch (error) {
        console.error(`[getEarvedFromFinBit] Background sp_loe_earved failed. log_id: ${logId}`, error);

        // Фиксируем ошибку в ou.logs
        try {
            await endLog(logId, 'failed', error.message);
        } catch (logErr) {
            console.error(`[getEarvedFromFinBit] Failed to update error log for log_id: ${logId}`, logErr);
        }
    }
}

/**
 * Извлекает номера счетов из массива JSON документов FinBit
 */
function extractInvoiceNumbers(jsonArray) {
    if (!Array.isArray(jsonArray)) return [];
    const numbers = [];
    for (const item of jsonArray) {
        if (!item || typeof item !== 'object') continue;
        const nr = (item.data && item.data.number) ? item.data.number : item.number;
        if (nr) numbers.push(String(nr).trim());
    }
    return numbers;
}

/**
 * Приводит значение jsonb-колонки к массиву (драйвер может вернуть массив, JSON-строку или null)
 */
function toArray(value) {
    if (Array.isArray(value)) return value;
    if (typeof value === 'string') {
        try {
            const parsed = JSON.parse(value);
            return Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            return [];
        }
    }
    return [];
}

/**
 * Выполняет SQL-запрос docs.sp_loe_earved к БД
 * Поддерживает:
 * 1. Одиночный батч или массив счетов: SELECT * FROM docs.sp_loe_earved($1::INTEGER, $2::JSONB);
 * 2. Массив батчей от нескольких учреждений: последовательное параметризованное выполнение
 *    SELECT * FROM docs.sp_loe_earved($1::INTEGER, $2::JSONB) в цикле с агрегацией результата.
 */
async function loeEarved(userId, jsonOrBatches) {
    try {
        const isBatchList = Array.isArray(jsonOrBatches) && jsonOrBatches.length > 0 && ('json' in jsonOrBatches[0]);

        if (isBatchList) {
            const sql = `SELECT * FROM docs.sp_loe_earved($1::INTEGER, $2::JSONB);`;
            const batchResults = [];
            const rawRows = [];
            const allInvoiceNumbers = [];
            const allImported = [];
            const allErrors = [];
            const messages = [];
            let totalFetched = 0;
            let totalImported = 0;

            for (const b of jsonOrBatches) {
                const bUserId = b.userId || userId;
                const parsedArray = typeof b.json === 'string' ? JSON.parse(b.json) : b.json;
                const fetchedCount = Array.isArray(parsedArray) ? parsedArray.length : 0;
                const batchInvoiceNumbers = extractInvoiceNumbers(parsedArray);
                const jsonText = typeof b.json === 'string' ? b.json : JSON.stringify(b.json);

                console.log('start sp_loe_earved for userId:', bUserId, 'rekvId:', b.rekvId);
                const l_result = await db.queryDb(sql, [bUserId, jsonText], null, null, null, null, config);
                console.log('finish sp_loe_earved', l_result);

                const row = (l_result && Array.isArray(l_result.data) && l_result.data[0])
                    ? l_result.data[0]
                    : (l_result || {});
                const rawErrCode = (row.error_code !== undefined && row.error_code !== null)
                    ? row.error_code
                    : ((l_result && l_result.error_code !== undefined && l_result.error_code !== null) ? l_result.error_code : 0);
                const errCode = Number(rawErrCode);
                const errMsg = row.error_message || (l_result && l_result.error_message) || null;

                if (errCode !== 0 || errMsg === 'Puudub õigused') {
                    throw new Error(errMsg || `docs.sp_loe_earved returned error code ${errCode}`);
                }

                // структурированный результат процедуры: созданные документы и ошибки по отдельным счетам
                const batchImported = toArray(row.imported);
                const batchErrors = toArray(row.errors);
                const importedCount = Array.isArray(row.imported)
                    ? batchImported.length
                    : ((row.result !== undefined && row.result !== null) ? Number(row.result) : fetchedCount);

                totalFetched += fetchedCount;
                totalImported += importedCount;
                allImported.push(...batchImported);
                allErrors.push(...batchErrors);
                allInvoiceNumbers.push(...batchInvoiceNumbers);
                if (errMsg) {
                    messages.push(errMsg.trim());
                }
                if (row) {
                    rawRows.push(row);
                }

                batchResults.push({
                    rekvId: b.rekvId,
                    userId: bUserId,
                    fetched: fetchedCount,
                    imported: importedCount,
                    failed: batchErrors.length,
                    invoiceNumbers: batchInvoiceNumbers,
                    message: errMsg
                });
            }

            const summaryMessage = messages.length > 0
                ? `Imporditud ${totalImported} arvet (leitud: ${totalFetched}). ${messages.join(' ')}`
                : `Imporditud ${totalImported} arvet (leitud: ${totalFetched})`;

            return {
                error_code: 0,
                result: totalImported,
                totalFetched,
                totalImported,
                totalFailed: allErrors.length,
                imported: allImported,
                errors: allErrors,
                invoiceNumbers: allInvoiceNumbers,
                error_message: summaryMessage,
                batches: batchResults,
                data: rawRows
            };
        }

        if (typeof userId === 'string' && userId.toLowerCase().startsWith('select')) {
            return await db.queryDb(userId, null, null, null, null, null, config);
        }

        const sql = `SELECT * FROM docs.sp_loe_earved($1::INTEGER, $2::JSONB);`;
        const parsedArray = typeof jsonOrBatches === 'string' ? JSON.parse(jsonOrBatches) : jsonOrBatches;
        const fetchedCount = Array.isArray(parsedArray) ? parsedArray.length : 0;
        const invoiceNumbers = extractInvoiceNumbers(parsedArray);
        const jsonText = typeof jsonOrBatches === 'string' ? jsonOrBatches : JSON.stringify(jsonOrBatches);

        console.log('start sp_loe_earved for userId:', userId);
        const l_result = await db.queryDb(sql, [userId, jsonText], null, null, null, null, config);
        console.log('finish sp_loe_earved', l_result);

        const row = (l_result && Array.isArray(l_result.data) && l_result.data[0])
            ? l_result.data[0]
            : (l_result || {});
        const rawErrCode = (row.error_code !== undefined && row.error_code !== null)
            ? row.error_code
            : ((l_result && l_result.error_code !== undefined && l_result.error_code !== null) ? l_result.error_code : 0);
        const errCode = Number(rawErrCode);
        const errMsg = row.error_message || (l_result && l_result.error_message) || null;

        if (errCode !== 0 || errMsg === 'Puudub õigused') {
            throw new Error(errMsg || `docs.sp_loe_earved returned error code ${errCode}`);
        }

        const singleImported = toArray(row.imported);
        const singleErrors = toArray(row.errors);
        const importedCount = Array.isArray(row.imported)
            ? singleImported.length
            : ((row.result !== undefined && row.result !== null) ? Number(row.result) : fetchedCount);

        return {
            error_code: 0,
            result: importedCount,
            totalFetched: fetchedCount,
            totalImported: importedCount,
            totalFailed: singleErrors.length,
            imported: singleImported,
            errors: singleErrors,
            invoiceNumbers,
            error_message: errMsg || `Imporditud ${importedCount} arvet (leitud: ${fetchedCount})`,
            data: l_result && l_result.data ? l_result.data : [row]
        };
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

/**
 * Логгирование старта задачи в ou.logs
 */
async function createLog(rekvId, userId, flowName = FLOW_NAME) {
    const sql = `insert into ou.logs (rekvid, user_id, propertis)
                 values ($1, $2, jsonb_build_object('flow', $3::text, 'exec_start', (clock_timestamp())))
                 returning id;`;

    try {
        console.log('start create log for flow:', flowName);
        const l_result = await db.queryDb(sql, [rekvId, userId, flowName], null, null, null, null, config);
        console.log('finish create log', flowName, l_result);
        return l_result;
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

/**
 * Сохраняет в ou.logs (flow = getEarved) массив счетов, полученный из FinBit, и закрывает лог (status = success).
 * Это результат работы агента getEarved (выкачка). Возвращаемый id (log_id) передается дальше:
 * check_asutus (проверка контр-агентов) и import_earved (разбор и сохранение счетов).
 * Формат propertis.arved: [{rekvId, userId, count, arved: [...]}]
 * @returns {Promise<number|null>} id записи; при ошибке записи пробрасывает исключение
 */
async function saveFetchedArvedLog(rekvId, userId, batches, unmatched) {
    const payload = (batches || []).map(b => ({
        rekvId: b.rekvId,
        userId: b.userId,
        count: Array.isArray(b.json) ? b.json.length : 0,
        arved: b.json
    }));
    const total = payload.reduce((s, b) => s + b.count, 0);
    const unmatchedList = Array.isArray(unmatched) ? unmatched : [];
    const resultData = {
        totalFetched: total,
        totalUnmatched: unmatchedList.length,
        unmatched: unmatchedList,
        invoiceNumbers: (batches || []).reduce((acc, b) => acc.concat(extractInvoiceNumbers(b.json)), []),
        batches: (batches || []).map(b => ({
            rekvId: b.rekvId,
            userId: b.userId,
            fetched: Array.isArray(b.json) ? b.json.length : 0
        }))
    };
    const responseText = `Leitud ${total} arvet (FinBit)`;

    const sql = `insert into ou.logs (rekvid, user_id, propertis)
                 values ($1, $2, jsonb_build_object(
                     'flow', $3::text,
                     'exec_start', clock_timestamp(),
                     'exec_end', clock_timestamp(),
                     'status', 'success',
                     'total', $5::int,
                     'arved', $4::jsonb,
                     'result', $6::jsonb,
                     'response', $7::text))
                 returning id;`;
    try {
        const r = await db.queryDb(
            sql,
            [rekvId, userId, AGENT_LOG_NAME, JSON.stringify(payload), total, JSON.stringify(resultData), responseText],
            null, null, null, null, config);
        const id = r && r.data && r.data[0] ? r.data[0].id : null;
        console.log(`[getEarvedFromFinBit] fetched arved saved to log (flow=${AGENT_LOG_NAME}), id:`, id);
        return id;
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

/**
 * Логгирование окончания задачи в ou.logs (успех / ошибка) с сохранением result и response
 */
async function endLog(logId, status = 'success', errorMessage = null, resultData = null, extra = null) {
    if (!logId) return;

    // extra - дополнительные ключи propertis (например, retryable: false - повтор задачи бессмыслен)
    let extraJson = null;
    if (extra && typeof extra === 'object' && Object.keys(extra).length > 0) {
        extraJson = JSON.stringify(extra);
    }

    let resultJson = null;
    let responseText = null;

    if (resultData !== null && resultData !== undefined) {
        if (typeof resultData === 'object') {
            const fetchedCountText = (resultData.totalFetched !== undefined && resultData.totalFetched !== null)
                ? resultData.totalFetched
                : resultData.totalImported;
            responseText = resultData.error_message || resultData.response || resultData.tulemused ||
                (resultData.totalImported !== undefined
                    ? `Imporditud ${resultData.totalImported} arvet (leitud: ${fetchedCountText})`
                    : null);
            try {
                resultJson = JSON.stringify(resultData);
            } catch (e) {
                resultJson = JSON.stringify({ raw: String(resultData) });
            }
        } else {
            responseText = String(resultData);
            resultJson = JSON.stringify({ message: responseText });
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
                 || case when $6::text is not null then ($6::text)::jsonb else '{}'::jsonb end
                 where id = $5;`;

    try {
        console.log('start endLog for id:', logId, 'status:', status, 'response:', responseText);
        await db.queryDb(sql, [status, errorMessage, resultJson, responseText, logId, extraJson], null, null, null, null, config);
        console.log('finish endLog');
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

/**
 * Функция полного синхронного выполнения (для CLI и тестов)
 */
async function executeCalculation(userId, execDate = getNow()) {
    let logId = null;
    try {
        const queryUserId = userId !== undefined && userId !== null ? userId : null;
        const sql = `select distinct on (r.id)
                       r.properties ->>'earved' as hash, c.properties->>'earved' as earved_host, r.id as rekv_id, u.id as user_id
                   from
                       ou.config c
                       inner join ou.rekv r
                   on r.id = c.rekvid
                       inner join ou.userid u on u.rekvid = r.id
                   where
                       (u.id = $1::integer or u.kasutaja = '${ROBOT_USER}')
                       and coalesce(r.properties ->>'earved', '') <> ''
                   order by r.id, (case when u.id = $1::integer then 1 else 2 end)`;

        const eArveConfig = await db.queryDb(sql, [queryUserId], null, null, null, null, config);
        if (!eArveConfig || !eArveConfig.data || !eArveConfig.data.length) {
            throw new Error('Конфигурация e-arved для учреждения не найдена');
        }

        const l_rekvId = eArveConfig.data[0].rekv_id;
        const l_userId = userId || eArveConfig.data[0].user_id;

        if (!l_userId) {
            throw new Error('User ID is missing');
        }

        const batches = [];
        for (const conf of eArveConfig.data) {
            const itemRekvId = conf.rekv_id;
            const itemUserId = conf.user_id || l_userId;
            const hash = conf.hash;
            const earvedHost = conf.earved_host;

            if (!hash) continue;

            try {
                const xml = await deps.getXMLFile(hash, earvedHost, execDate);
                const json = await deps.XMLtoJson(xml, { rekvid: itemRekvId, userid: itemUserId });

                if (json && Array.isArray(json) && json.length > 0) {
                    batches.push({
                        rekvId: itemRekvId,
                        userId: itemUserId,
                        json: json
                    });
                }
            } catch (err) {
                console.error(`[executeCalculation] Error fetching invoices for rekv: ${itemRekvId}:`, err);
            }
        }

        if (!batches.length) {
            throw new Error('Arveid ei leitud');
        }

        const logData = await createLog(l_rekvId, l_userId);
        logId = logData && logData.data && logData.data[0] ? logData.data[0].id : null;
        console.log('Created log id:', logId);

        const result = await loeEarved(l_userId, batches);
        console.log('Calculation result:', result);

        await endLog(logId, 'success', null, result);
        console.log('Finished log id:', logId);
        return result;
    } catch (error) {
        if (logId) {
            await endLog(logId, 'failed', error.message);
        }
        throw error;
    }
}

// Запуск при прямом вызове из командной строки (CLI)
if (require.main === module) {
    const defaultUserId = 2477;
    executeCalculation(defaultUserId)
        .then((result) => {
            console.log('Finished getEarvedFromFinBit successfully:', result);
            process.exit(0);
        })
        .catch((error) => {
            console.error('Error in getEarvedFromFinBit execution:', error);
            process.exit(1);
        });
}

exports.post = post;
exports.main = post;
exports.executeCalculation = executeCalculation;
exports.runCalculationInBackground = runCalculationInBackground;
exports.loeEarved = loeEarved;
exports.toArray = toArray;
exports.createLog = createLog;
exports.saveFetchedArvedLog = saveFetchedArvedLog;
exports.extractInvoiceNumbers = extractInvoiceNumbers;
exports.AGENT_LOG_NAME = AGENT_LOG_NAME;
exports.endLog = endLog;
exports.FLOW_NAME = FLOW_NAME;
exports.ROBOT_USER = ROBOT_USER;
exports.checkIsAgent = checkIsAgent;
exports.buildBatchesTaskSql = buildBatchesTaskSql;
exports.runPostTaskInBackground = runPostTaskInBackground;
exports.formatTaskErrorEmail = formatTaskErrorEmail;
exports.getTaskSmtpConfig = getTaskSmtpConfig;
exports.deps = deps;
