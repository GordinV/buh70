'use strict';
const service = require('./../../libs/inforegisterService');

/**
 * Express handler POST /task/getInforegister/
 * Берет из лога check_asutus (checkAsutusAvailability) рег.коды отсутствующих организаций, получает данные из
 * локальной копии Äriregister (libs.ariregister) и (если dry_run выключен) сохраняет организации через libs.sp_salvesta_asutus.
 * Работает асинхронно: проверяет hash, создает лог, запускает обработку в фоне, сразу возвращает log_id.
 */
exports.main = async (req, res) => {
    const params = Object.assign({}, req.query, req.body, req.params);

    const bodyUserId = params.user_id || params.userId ? Number(params.user_id || params.userId) : null;
    let userId = bodyUserId || service.DEFAULT_USER_ID;
    let rekvId = Number(params.rekv_id || params.rekvId || service.DEFAULT_REKV_ID);
    const sourceLogParam = params.log_id || params.logId || null;
    const dryRun = service.parseDryRun(params.dry_run !== undefined ? params.dry_run : params.dryRun);
    const configRekvId = Number(params.config_rekv_id || params.configRekvId || service.CONFIG_REKV_ID);
    const insecureTls = params.insecure_tls === true || params.insecure_tls === 'true' || params.insecureTls === true;
    const maxCalls = params.max_calls !== undefined && !isNaN(Number(params.max_calls)) ? Number(params.max_calls) : undefined;

    const rawHash = typeof params.hash === 'string' ? params.hash.trim() : '';
    const requireHash = process.env.INFOREGISTER_REQUIRE_HASH_BATCH !== 'false';

    if (!rawHash && !requireHash) {
        console.warn('getInforegister called without hash');
    } else {
        const auth = await service.resolveInforegisterToken(rawHash, 'batch', configRekvId);
        if (!auth.ok) {
            return res.status(auth.status).send({
                status: auth.status,
                result: 0,
                log_id: null,
                data: {reason: auth.reason},
                error_message: auth.error
            });
        }
        if (bodyUserId && bodyUserId !== auth.userId) {
            console.warn(`[getInforegister] user_id mismatch: body=${bodyUserId}, token=${auth.userId} (using token user_id)`);
        }
        userId = auth.userId;
        rekvId = auth.rekvId;
    }

    let logId = null;

    try {
        const logResult = await service.createLog(rekvId, userId, service.FLOW_NAME);
        if (logResult && logResult.data && logResult.data[0]) {
            logId = logResult.data[0].id;
        }
        if (!logId) {
            throw new Error('Лог-запись не создана (не удалось получить log_id)');
        }

        runInBackground(logId, userId, rekvId, sourceLogParam, {
            dryRun: dryRun,
            maxCalls: maxCalls,
            configRekvId: configRekvId,
            insecureTls: insecureTls
        });

        return res.status(200).send({
            status: 200,
            result: 1,
            log_id: logId,
            data: {
                action: service.FLOW_NAME,
                status: 'STARTED',
                log_id: logId,
                result: {doc_id: logId, error_code: 0, error_message: null, tulemused: 'STARTED'}
            },
            error_message: null
        });
    } catch (error) {
        console.error('Error starting getInforegister task:', error);
        if (logId) {
            try {
                await service.endLog(logId, 'failed', error.message);
            } catch (logErr) {
                console.error('Failed to update log on startup error:', logErr);
            }
        }
        return res.status(500).send({
            status: 500,
            result: 0,
            log_id: logId,
            data: null,
            error_message: `Start getInforegister failed: ${error.message}`
        });
    }
};

async function runInBackground(logId, userId, rekvId, sourceLogParam, options) {
    try {
        const result = await service.processMissingAsutused(userId, rekvId, sourceLogParam, options);
        await service.endLog(logId, 'success', null, result);
    } catch (error) {
        console.error(`[getInforegister] Background task failed. log_id: ${logId}`, error);
        try {
            await service.endLog(logId, 'failed', error.message);
        } catch (logErr) {
            console.error(`[getInforegister] Failed to update error log for log_id: ${logId}`, logErr);
        }
    }
}

exports.processMissingAsutused = service.processMissingAsutused;
exports.processOne = service.processOne;
exports.buildAsutusPayload = service.buildAsutusPayload;
exports.findMissing = service.findMissing;
exports.getApiKey = service.getApiKey;
exports.parseDryRun = service.parseDryRun;
exports.isClosed = service.isClosed;
exports.runInBackground = runInBackground;
exports.createLog = service.createLog;
exports.endLog = service.endLog;
exports.FLOW_NAME = service.FLOW_NAME;
exports.STATUS = service.STATUS;
