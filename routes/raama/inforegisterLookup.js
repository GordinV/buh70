'use strict';
const inforegister = require('./../../libs/inforegister');
const service = require('./../../libs/inforegisterService');
const ariregisterStore = require('./../../libs/ariregisterStore');

function mapReasonToHttpStatus(reason) {
    if (reason === 'invalid_reg_code') return 400;
    if (reason === 'not_found' || reason === 'dry_run_no_spend') return 404;
    if (reason === 'budget_exhausted' || reason === 'year_limit_reserve' || reason === 'rate_limited') return 429;
    if (reason === 'no_api_key' || reason === 'registry_not_loaded') return 503;
    if (reason === 'timeout') return 504;
    if (reason === 'unauthorized' || reason === 'http_error') return 502;
    return 502;
}

/**
 * Express handler POST /task/inforegisterLookup/
 * Синхронный поиск одной организации по regkood с перепроверкой локальных данных (без сохранения в libs.asutus).
 */
exports.main = async (req, res) => {
    const params = Object.assign({}, req.query, req.body, req.params);
    const configRekvId = Number(params.config_rekv_id || params.configRekvId || service.CONFIG_REKV_ID);
    const rawHash = typeof params.hash === 'string' ? params.hash.trim() : '';

    const auth = await service.resolveInforegisterToken(rawHash, 'lookup', configRekvId);
    if (!auth.ok) {
        return res.status(auth.status).send({
            status: auth.status,
            result: 0,
            data: {reason: auth.reason},
            error_message: auth.error
        });
    }

    const regkood = String(params.regkood === undefined || params.regkood === null ? '' : params.regkood).trim();
    if (!inforegister.REG_CODE_RE.test(regkood)) {
        return res.status(400).send({
            status: 400,
            result: 0,
            data: {reason: 'invalid_reg_code', regkood: regkood},
            error_message: 'Reg.kood ei ole 8-kohaline'
        });
    }

    const cacheOnly = params.cache_only === true || params.cache_only === 'true' || params.cacheOnly === true;
    const forceRefresh = params.force_refresh === true || params.force_refresh === 'true' || params.forceRefresh === true;
    const insecureTls = params.insecure_tls === true || params.insecure_tls === 'true' || params.insecureTls === true;
    const year = params.year !== undefined && !isNaN(Number(params.year)) ? Number(params.year) : undefined;

    let logId = null;
    try {
        try {
            const logResult = await service.createLog(auth.rekvId, auth.userId, service.LOOKUP_FLOW_NAME);
            if (logResult && logResult.data && logResult.data[0]) {
                logId = logResult.data[0].id;
            }
        } catch (logErr) {
            console.error('[inforegisterLookup] Failed to create log:', logErr.message);
        }

        // cache_only, force_refresh и insecure_tls принимаются для обратной совместимости и игнорируются
        void cacheOnly;
        void forceRefresh;
        void insecureTls;
        const client = ariregisterStore.createStoreClient();

        const lookupRes = await service.lookupOne(regkood, client, {year: year});
        const usage = client.getUsage();

        await service.endLog(
            logId,
            lookupRes.ok ? 'success' : 'failed',
            lookupRes.ok ? null : lookupRes.error,
            {
                regkood: regkood,
                source: lookupRes.source,
                reason: lookupRes.reason || null,
                calls_spent: usage.spent,
                remaining_year: usage.remainingYear,
                label: auth.label
            }
        );

        if (!lookupRes.ok) {
            const httpStatus = mapReasonToHttpStatus(lookupRes.reason);
            return res.status(httpStatus).send({
                status: httpStatus,
                result: 0,
                data: {
                    regkood: regkood,
                    reason: lookupRes.reason,
                    local: lookupRes.local,
                    calls_spent: usage.spent,
                    remaining_year: usage.remainingYear
                },
                error_message: lookupRes.error
            });
        }

        return res.status(200).send({
            status: 200,
            result: 1,
            data: {
                regkood: regkood,
                asutus_id: lookupRes.local ? lookupRes.local.id : null,
                source: lookupRes.source,
                fetched_at: lookupRes.fetched_at,
                closed: lookupRes.closed,
                local: lookupRes.local,
                registry: lookupRes.registry,
                company: lookupRes.registry,
                diff: lookupRes.diff,
                calls_spent: usage.spent,
                remaining_year: usage.remainingYear
            },
            error_message: null
        });
    } catch (error) {
        console.error('[inforegisterLookup] Unexpected error:', error.message);
        if (logId) {
            try {
                await service.endLog(logId, 'failed', error.message);
            } catch (e) {
                // не маскируем исходную ошибку
            }
        }
        return res.status(500).send({
            status: 500,
            result: 0,
            data: null,
            error_message: error.message
        });
    }
};
