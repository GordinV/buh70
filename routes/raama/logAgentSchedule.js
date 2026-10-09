'use strict';
const db = require('./../../libs/db');
//const config = require('./../../config/default.json');
const config = require('./../../config/narvalv.json');

const DEFAULT_USER_ID = 2477;
const DEFAULT_REKV_ID = 63;
const FLOW_NAME = 'ai_task.agent_schedule';

/**
 * Express handler для роута POST /task/logAgentSchedule/
 * Синхронно записывает снимок расписания и статусов агентов (snapshot) в таблицу ou.logs
 * под именем потока ai_task.agent_schedule
 *
 * Пример вызова:
 * curl.exe -X POST http://localhost:3000/task/logAgentSchedule/ \
 *   -H "Content-Type: application/json" \
 *   -d '{"user_id": 2477, "rekv_id": 63, "snapshot": {"tick_at": "...", ...}}'
 */
exports.main = async (req, res) => {
    const params = Object.assign({}, req.query, req.body, req.params);

    const userId = Number(params.user_id || params.userid_id || params.userId || DEFAULT_USER_ID);
    const rekvId = Number(params.rekv_id || params.rekvid || params.rekvId || DEFAULT_REKV_ID);
    const snapshot = params.snapshot !== undefined ? params.snapshot : {};

    try {
        const logId = await writeScheduleLog(rekvId, userId, snapshot);

        console.log('logAgentSchedule Log ID:', logId);

        if (!logId) {
            throw new Error('Лог-запись не создана (не удалось получить log_id)');
        }

        return res.status(200).send({
            status: 200,
            result: 1,
            log_id: logId,
            data: {
                action: 'logAgentSchedule',
                status: 'COMPLETED',
                log_id: logId
            },
            error_message: null
        });

    } catch (error) {
        console.error('Error logging agent schedule snapshot:', error);

        return res.status(500).send({
            status: 500,
            result: 0,
            log_id: null,
            data: null,
            error_message: `Log agent schedule failed: ${error.message}`
        });
    }
};

/**
 * Синхронная запись среза в ou.logs
 * @param {number} rekvId
 * @param {number} userId
 * @param {object|string} snapshot
 * @returns {Promise<number>} ID созданной записи в ou.logs
 */
async function writeScheduleLog(rekvId = DEFAULT_REKV_ID, userId = DEFAULT_USER_ID, snapshot = {}) {
    const snapshotJson = typeof snapshot === 'string' ? snapshot : JSON.stringify(snapshot);

    const sql = `insert into ou.logs (rekvid, user_id, propertis)
                 values ($1, $2, jsonb_build_object(
                     'flow', $3::text,
                     'exec_start', (clock_timestamp()),
                     'exec_end', (clock_timestamp()),
                     'status', 'success',
                     'result', $4::jsonb
                 ))
                 returning id;`;

    try {
        console.log(`[logAgentSchedule] Writing snapshot for userId: ${userId}, flow: ${FLOW_NAME}`);
        const result = await db.queryDb(sql, [rekvId, userId, FLOW_NAME, snapshotJson], null, null, null, null, config);

        if (result && result.data && result.data[0] && result.data[0].id) {
            const logId = Number(result.data[0].id);
            console.log(`[logAgentSchedule] Snapshot recorded successfully. log_id: ${logId}`);
            return logId;
        }

        throw new Error('Query executed but no returning id found');
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

exports.writeScheduleLog = writeScheduleLog;
exports.FLOW_NAME = FLOW_NAME;

// CLI запуск для ручной проверки
if (require.main === module) {
    const sampleSnapshot = {
        tick_at: new Date().toISOString(),
        timezone: 'Europe/Tallinn',
        cycle_date: new Date().toISOString().slice(0, 10),
        cycle_status: 'IN_PROGRESS',
        next_scheduled_run: null,
        summary: { pending: 0, running: 0, success: 0, failed: 0, skipped: 0 },
        agents: []
    };

    writeScheduleLog(DEFAULT_REKV_ID, DEFAULT_USER_ID, sampleSnapshot)
        .then((logId) => {
            console.log('Finished logAgentSchedule CLI successfully, logId:', logId);
            process.exit(0);
        })
        .catch((error) => {
            console.error('Error in logAgentSchedule CLI execution:', error);
            process.exit(1);
        });
}
