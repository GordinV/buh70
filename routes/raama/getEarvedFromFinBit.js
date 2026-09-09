'use strict';
const getNow = require('./../../libs/getNow');
const db = require("../../libs/db");
const config = require("../../config/default.json");
const getXMLFile = require('../ai/e-arved/getXMLFile');
const XMLtoJson = require('../ai/e-arved/xml_to_json');
const { executeTask } = require('../task/executePostTask');

exports.post = async (req, res) => {
    try {
        const params = Object.assign({}, req.query, req.body, req.params);
        const userId = params.userid_id || params.user_id || params.userId;
        const execDate = params.date_query_from ? params.date_query_from : getNow(); // доп параметр дата
        const module = 'RAAMA';

        console.log('params', execDate, params);

        if (!userId) {
            return res.send({status: 500, result: null, error_message: 'User ID is missing'});
        }

        // получаем конфигурацию учреждения
        let sql = `select
                       r.properties ->>'earved' as hash, c.properties->>'earved' as earved_host, r.id as rekv_id
                   from
                       ou.config c
                       inner join ou.rekv r
                   on r.id = c.rekvid
                       inner join ou.userid u on u.rekvid = r.id
                   where
                       u.id = $1::integer
                       limit 1`;

        let eArveConfig = await db.queryDb(sql, [userId], null, null, null, null, config);

        // проверка получения конфигурации
        if (!eArveConfig || !eArveConfig.data || !eArveConfig.data.length) {
            return res.send({status: 500, result: null, error_message: 'Конфигурация e-arved для учреждения не найдена'});
        }

        let l_rekvId = eArveConfig.data[0].rekv_id;

        let xml = await getXMLFile(eArveConfig.data[0].hash, eArveConfig.data[0].earved_host, execDate);

        let json = await XMLtoJson(xml, { rekvid: l_rekvId, userid: userId });

        // проверка количества объектов в массиве json
        if (!json || !Array.isArray(json) || json.length === 0) {
            return res.send({
                status: 500,
                result: null,
                error_message: 'Arveid ei leitud'
            });
        }

        // готовим параметры, сохраняем таску
        let saveResult;
        try {
            // docs.sp_loe_earved(INTEGER, JSONB)
            let jsonText = JSON.stringify(json);
            let saveParams = `select docs.sp_loe_earved(${userId}, $$${jsonText}$$)`;
            saveResult = await db.queryDb(`select ou.sp_salvesta_task('${saveParams}','Loe FinBit arved',${userId})`, null, null, null, null, null, config);
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
    } catch (err) {
        console.error('getEarvedFromFinBit error:', err);
        return res.send({status: 500, result: null, error_message: err.message || err});
    }
};
