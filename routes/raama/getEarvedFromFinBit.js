'use strict';
const getNow = require('./../../libs/getNow');
const db = require("../../libs/db");
const getXMLFile = require('../ai/e-arved/getXMLFile');
const XMLtoJson = require('../ai/e-arved/xml_to_json');
const { executeTask } = require('../task/executePostTask');

const FLOW_NAME = 'docs.sp_loe_earved';
const ROBOT_USER = 'Earved robot';

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
 * 2. Агентский (при передаче is_agent / isAgent / agent): логирование в ou.logs,
 *    прямой вызов docs.sp_loe_earved в фоне и немедленный возврат log_id (по аналогии с calcArvJaak.js)
 */
const post = async (req, res) => {
    try {
        const params = Object.assign({}, req.query, req.body, req.params);
        const userId = params.userid_id || params.user_id || params.userId;
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
                       r.properties ->>'earved' as hash, c.properties->>'earved' as earved_host, r.id as rekv_id, u.id as user_id
                   from
                       ou.config c
                       inner join ou.rekv r
                   on r.id = c.rekvid
                       inner join ou.userid u on u.rekvid = r.id
                    where
                       ${isAgent ? `(u.id = $1::integer or u.kasutaja = '${ROBOT_USER}')` : "u.id = $1::integer"}
                       and coalesce(r.properties ->>'earved', '') <> ''
                    and u.status < 3  
                    order by r.id, (case when u.id = $1::integer then 1 else 2 end)`;

        let eArveConfig = await db.queryDb(sql, [queryUserId], null, null, null, null, config);

        // проверка получения конфигурации
        if (!eArveConfig || !eArveConfig.data || !eArveConfig.data.length) {
            return res.send({status: 500, result: null, error_message: 'Конфигурация e-arved для учреждения не найдена'});
        }

        let l_rekvId = eArveConfig.data[0].rekv_id;
        let l_userId = userId || eArveConfig.data[0].user_id;

        if (!l_userId) {
            return res.send({status: 500, result: null, error_message: 'User ID is missing'});
        }

        // Проходим по массиву учреждений, запрашиваем e-счета и формируем пакеты для сохранения
        const batches = [];
        for (const conf of eArveConfig.data) {
            const itemRekvId = conf.rekv_id;
            const itemUserId = conf.user_id || l_userId;
            const hash = conf.hash;
            const earvedHost = conf.earved_host;

            if (!hash) {
                console.warn(`[getEarvedFromFinBit] Puudub hash asutusele rekvid: ${itemRekvId}`);
                continue;
            }
            console.log('hash',hash);
            console.log('itemRekvId, itemUserId',itemRekvId, itemUserId);

            try {
                const xml = await getXMLFile(hash, earvedHost, execDate);
                const json = await XMLtoJson(xml, { rekvid: itemRekvId, userid: itemUserId });

                console.log('json',json);

                if (json && Array.isArray(json) && json.length > 0) {
                    batches.push({
                        rekvId: itemRekvId,
                        userId: itemUserId,
                        json: json
                    });
                    console.log(`[getEarvedFromFinBit] Leitud ${json.length} arvet asutusele rekvid: ${itemRekvId}`);
                } else {
                    console.log(`[getEarvedFromFinBit] Arveid ei leitud asutusele rekvid: ${itemRekvId}`);
                }
            } catch (fetchErr) {
                console.error(`[getEarvedFromFinBit] Viga asutuse rekvid: ${itemRekvId} arvete pärimisel:`, fetchErr.message || fetchErr);
            }
        }

        // проверка количества найденных счетов по всем учреждениям
        if (!batches.length) {
            if (isAgent) {
                // В агентском режиме отсутствие новых счетов — штатная ситуация (0 счетов за дату).
                // Создаем и закрываем лог в ou.logs, чтобы оркестратор получил валидный log_id
                let emptyLogId = null;
                try {
                    const logResult = await createLog(l_rekvId, l_userId, flowName);
                    if (logResult && logResult.data && logResult.data[0]) {
                        emptyLogId = logResult.data[0].id;
                    }
                    if (emptyLogId) {
                        await endLog(emptyLogId, 'success', null);
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
                            tulemused: 'Arveid ei leitud (0 arvet)'
                        }
                    },
                    error_message: null
                });
            }

            return res.send({
                status: 500,
                result: null,
                error_message: 'Arveid ei leitud'
            });
        }

        // В зависимости от флага isAgent выбираем логику работы
        if (!isAgent) {
            // === СТАРАЯ ЛОГИКА ===
            // готовим параметры, сохраняем таску
            let saveResult;
            try {
                // docs.sp_loe_earved(INTEGER, JSONB)
                // Формируем последовательный sql запрос вида:
                // select docs.sp_loe_earved(user1, $$json1$$); select docs.sp_loe_earved(user2, $$json2$$)
                const saveSqlStatements = batches.map(b => {
                    const jsonText = JSON.stringify(b.json);
                    return `select docs.sp_loe_earved(${b.userId}, $$${jsonText}$$)`;
                });
                const saveParams = saveSqlStatements.join('; ');
                saveResult = await db.queryDb(`select ou.sp_salvesta_task('${saveParams}','Loe FinBit arved',${l_userId})`, null, null, null, null, null, config);
                console.log('saveResult', saveResult);

            } catch (e) {
                console.log('catch', e);
                return res.send({status: 500, result: null, error_message: e.message || e});
            }

            let taskId = null;
            if (saveResult && saveResult.data && Array.isArray(saveResult.data) && saveResult.data.length && saveResult.data[0].sp_salvesta_task) {
                taskId = saveResult.data[0].sp_salvesta_task;
                executeTask(taskId);
            }

            // ответ
            return res.send({
                status: 200, result: 1, data: {
                    action: 'Import FinBit arved',
                    result: {
                        doc_id: taskId || 1,
                        error_code: 0,
                        error_message: null,
                        tulemused: saveResult
                    },
                    data: saveResult
                }
            });
        } else {
            // === НОВАЯ АГЕНТСКАЯ ЛОГИКА (по аналогии с calcArvJaak.js) ===
            let logId = null;

            try {
                // 1. Создаем запись в ou.logs о старте процесса
                const logResult = await createLog(l_rekvId, l_userId, flowName);
                if (logResult && logResult.data && logResult.data[0]) {
                    logId = logResult.data[0].id;
                }

                if (!logId) {
                    throw new Error('Лог-запись не создана (не удалось получить log_id)');
                }

                // 2. Запускаем фоновый вызов docs.sp_loe_earved БЕЗ ожидания завершения
                runCalculationInBackground(logId, l_userId, batches);

                // 3. Сразу возвращаем успешный ответ клиенту с log_id для отслеживания
                return res.status(200).send({
                    status: 200,
                    result: 1,
                    log_id: logId,
                    data: {
                        action: 'Import FinBit arved',
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
 * Фоновая асинхронная функция выполнения docs.sp_loe_earved и обновления статуса в ou.logs
 */
async function runCalculationInBackground(logId, userId, batchesOrJson) {
    try {
        console.log(`[getEarvedFromFinBit] Background sp_loe_earved started. log_id: ${logId}, userId: ${userId}`);
        const calcResult = await loeEarved(userId, batchesOrJson);
        console.log(`[getEarvedFromFinBit] Background sp_loe_earved finished successfully. log_id: ${logId}`, calcResult);

        // Фиксируем успешное завершение
        await endLog(logId, 'success');
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
 * Выполняет SQL-запрос docs.sp_loe_earved к БД
 * Поддерживает:
 * 1. Одиночный батч или массив счетов: SELECT * FROM docs.sp_loe_earved($1::INTEGER, $2::JSONB);
 * 2. Массив батчей от нескольких учреждений: последовательное выполнение составным SQL запросом вида:
 *    select docs.sp_loe_earved(user1, $$json1$$); select docs.sp_loe_earved(user2, $$json2$$);
 */
async function loeEarved(userId, jsonOrBatches) {
    try {
        const isBatchList = Array.isArray(jsonOrBatches) && jsonOrBatches.length > 0 && ('json' in jsonOrBatches[0]);

        if (isBatchList) {
            if (jsonOrBatches.length === 1) {
                const single = jsonOrBatches[0];
                const targetUserId = single.userId || userId;
                const sql = `SELECT * FROM docs.sp_loe_earved($1::INTEGER, $2::JSONB);`;
                const jsonText = typeof single.json === 'string' ? single.json : JSON.stringify(single.json);
                console.log('start sp_loe_earved for userId:', targetUserId);
                const l_result = await db.queryDb(sql, [targetUserId, jsonText], null, null, null, null, config);
                console.log('finish sp_loe_earved', l_result);

                if (l_result && l_result.error_code && l_result.error_code !== 0) {
                    throw new Error(l_result.error_message || `docs.sp_loe_earved returned error code ${l_result.error_code}`);
                }
                return l_result;
            }

            // Множество учреждений: формируем составной последовательный SQL-запрос
            // select docs.sp_loe_earved(parameters); select docs.sp_loe_earved(parameters);
            const sqlStatements = jsonOrBatches.map(b => {
                const bUserId = b.userId || userId;
                const jsonText = typeof b.json === 'string' ? b.json : JSON.stringify(b.json);
                return `select docs.sp_loe_earved(${bUserId}::integer, $$${jsonText}$$::jsonb);`;
            });
            const combinedSql = sqlStatements.join(' ');
            console.log(`[getEarvedFromFinBit] start combined sp_loe_earved for ${jsonOrBatches.length} institutions:`, combinedSql.slice(0, 150));
            const l_result = await db.queryDb(combinedSql, null, null, null, null, null, config);
            console.log('finish combined sp_loe_earved', l_result);

            if (l_result && l_result.error_code && l_result.error_code !== 0) {
                throw new Error(l_result.error_message || `docs.sp_loe_earved returned error code ${l_result.error_code}`);
            }
            return l_result;
        }

        if (typeof userId === 'string' && userId.toLowerCase().startsWith('select')) {
            return await db.queryDb(userId, null, null, null, null, null, config);
        }

        const sql = `SELECT * FROM docs.sp_loe_earved($1::INTEGER, $2::JSONB);`;
        const jsonText = typeof jsonOrBatches === 'string' ? jsonOrBatches : JSON.stringify(jsonOrBatches);

        console.log('start sp_loe_earved for userId:', userId);
        const l_result = await db.queryDb(sql, [userId, jsonText], null, null, null, null, config);
        console.log('finish sp_loe_earved', l_result);

        if (l_result && l_result.error_code && l_result.error_code !== 0) {
            throw new Error(l_result.error_message || `docs.sp_loe_earved returned error code ${l_result.error_code}`);
        }
        return l_result;
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
 * Логгирование окончания задачи в ou.logs (успех / ошибка)
 */
async function endLog(logId, status = 'success', errorMessage = null) {
    if (!logId) return;

    const sql = `update ou.logs
                 set propertis = propertis || jsonb_build_object('exec_end', (clock_timestamp()), 'status', $1::text, 'error', $2::text)
                 where id = $3;`;

    try {
        console.log('start endLog for id:', logId, 'status:', status);
        await db.queryDb(sql, [status, errorMessage, logId], null, null, null, null, config);
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
                const xml = await getXMLFile(hash, earvedHost, execDate);
                const json = await XMLtoJson(xml, { rekvid: itemRekvId, userid: itemUserId });

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

        await endLog(logId, 'success');
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
exports.createLog = createLog;
exports.endLog = endLog;
exports.FLOW_NAME = FLOW_NAME;
exports.ROBOT_USER = ROBOT_USER;
exports.checkIsAgent = checkIsAgent;
