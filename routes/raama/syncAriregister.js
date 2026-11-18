'use strict';
const service = require('./../../libs/inforegisterService');
const ariregisterSync = require('./../../libs/ariregisterSync');

/**
 * Express handler POST /task/syncAriregister/
 * Скачивает открытые данные Äriregister и синхронизирует таблицу libs.ariregister.
 * Работает асинхронно: проверяет hash (scope 'sync'), берет advisory lock, создает лог и сразу возвращает log_id.
 */
exports.main = async (req, res) => {
    const params = Object.assign({}, req.query, req.body, req.params);
    const configRekvId = Number(params.config_rekv_id || params.configRekvId || service.CONFIG_REKV_ID);
    const rawHash = typeof params.hash === 'string' ? params.hash.trim() : '';
    const dryRun = params.dry_run === true || params.dry_run === 'true' || params.dryRun === true;

    const auth = await service.resolveInforegisterToken(rawHash, 'sync', configRekvId);
    if (!auth.ok) {
        return res.status(auth.status).send({
            status: auth.status,
            result: 0,
            log_id: null,
            data: {reason: auth.reason},
            error_message: auth.error
        });
    }

    let lockHandle = null;
    try {
        lockHandle = await ariregisterSync.tryAcquireLock();
    } catch (lockErr) {
        console.error('[syncAriregister] Failed to acquire advisory lock:', lockErr.message);
        return res.status(500).send({
            status: 500,
            result: 0,
            log_id: null,
            data: null,
            error_message: 'Advisory lock error: ' + lockErr.message
        });
    }

    if (!lockHandle) {
        return res.status(409).send({
            status: 409,
            result: 0,
            log_id: null,
            data: {reason: 'already_running'},
            error_message: 'Äriregistri sünkroniseerimine juba töötab'
        });
    }

    let logId = null;

    try {
        const logResult = await service.createLog(auth.rekvId, auth.userId, ariregisterSync.FLOW_NAME);
        if (logResult && logResult.data && logResult.data[0]) {
            logId = logResult.data[0].id;
        }
        if (!logId) {
            throw new Error('Лог-запись не создана (не удалось получить log_id)');
        }

        runInBackground(logId, lockHandle, {
            dryRun: dryRun,
            configRekvId: configRekvId
        });

        return res.status(200).send({
            status: 200,
            result: 1,
            log_id: logId,
            data: {
                action: ariregisterSync.FLOW_NAME,
                status: 'STARTED',
                log_id: logId,
                dry_run: dryRun,
                result: {doc_id: logId, error_code: 0, error_message: null, tulemused: 'STARTED'}
            },
            error_message: null
        });
    } catch (error) {
        console.error('[syncAriregister] Error starting task:', error.message);
        if (logId) {
            try {
                await service.endLog(logId, 'failed', error.message);
            } catch (logErr) {
                console.error('[syncAriregister] Failed to update log on startup error:', logErr.message);
            }
        }
        await ariregisterSync.releaseLock(lockHandle);
        return res.status(500).send({
            status: 500,
            result: 0,
            log_id: logId,
            data: null,
            error_message: 'Start syncAriregister failed: ' + error.message
        });
    }
};

async function runInBackground(logId, lockHandle, options) {
    try {
        const result = await ariregisterSync.syncAriregister(options);
        await service.endLog(logId, 'success', null, result);
    } catch (error) {
        console.error('[syncAriregister] Background task failed. log_id:', logId, error.message);
        try {
            await service.endLog(logId, 'failed', error.message);
        } catch (logErr) {
            console.error('[syncAriregister] Failed to update error log for log_id:', logId, logErr.message);
        }
    } finally {
        await ariregisterSync.releaseLock(lockHandle);
    }
}

exports.runInBackground = runInBackground;
