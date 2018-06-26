'use strict';

let now = new Date();

const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');


const Ettemaksud = {
    select: [
        {
            sql: `SELECT
                      e.id,
                      e.number AS number,
                      e.rekvid,
                      e.asutusid,
                      e.muud   AS muud,
                      e.kpv,
                      e.doktyyp,
                      e.summa,
                      e.selg,
                      e.journalid,
                      e.staatus,
                      e.dokid
                    FROM rekl.ettemaksud e
                      INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                      INNER JOIN libs.asutus a ON a.id = e.asutusid
                    WHERE e.id = $1`,
            sqlAsNew: `
                SELECT
                    $1 :: INTEGER                                  AS id,
                    $2 :: INTEGER                                  AS userid,
                  NULL :: INTEGER            AS number,
                  NULL :: INTEGER            AS rekvid,
                  NULL :: INTEGER            AS asutusid,
                  NULL :: TEXT               AS muud,
                  current_date               AS kpv,
                  NULL :: REKL_ETTEMAKS_LIIK AS doktyyp,
                  NULL :: TEXT               AS selg,
                  0::numeric(12,2) as summa,
                  'active' :: DOK_STATUS`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        }
    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "kpv", name: "Kpv", width: "100px"},
            {id: "dokument", name: "Dokument", width: "100px"},
            {id: "selg", name: "Selgitus", width: "200px", show: false}
        ],
        sqlString: `SELECT
                          d.*
                        FROM cur_ettemaksud d
                        WHERE d.rekvId = $1`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curEttemaksud'
    },
    returnData: {
        row: {},
        details: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'kood', name: 'Kood', width: '100px', show: true, type: 'text', readOnly: false},
            {id: "nomid", name: "nomid", width: "10px", show: false},
            {id: 'maksumaar', name: 'Maksumaar', width: '200px', show: true, type: 'text', readOnly: false},
            {id: 'kogus', name: 'Kogus', width: '150px', show: true, type: 'text', readOnly: false},
            {id: 'liik', name: 'Sooduseliik', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'soodus', name: 'Soodus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'summa', name: 'Summa', width: '100px', show: true, type: 'number', readOnly: false}
        ]
    },
    saveDoc: `select rekl.sp_salvesta_ettemaksud($1, $2, $3) as id`,
    deleteDoc: `select error_code, result, error_message from rekl.sp_delete_ettemaksud($1, $2)`, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'kpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {
            name: 'asutusid',
            type: 'I',
        },
        {
            name: 'summa',
            type: 'N',
        },
        {
            name: 'number',
            type: 'N',
        },
        {
            name: 'selg',
            type: 'C',
        }


    ],
    bpm: [
        {
            step: 0,
            name: 'Регистация документа',
            action: 'start',
            nextStep: 1,
            task: 'human',
            data: [],
            actors: [],
            status: null,
            actualStep: false
        },
//        {step:2, name:'Оплата', action: 'tasumine', nextStep:3, task:'human', data:[], status:null, actualStep:false},
        {
            step: 1,
            name: 'Конец',
            action: 'endProcess',
            nextStep: null,
            task: 'automat',
            data: [],
            actors: [],
            status: null,
            actualStep: false
        }
    ],
    executeTask: (task, docId, userId) => {
        // выполнит задачу, переданную в параметре

        let executeTask = task;
        if (executeTask.length == 0) {
            executeTask = ['start'];
        }

        let taskFunction = eval(executeTask[0]);
        return taskFunction(docId, userId, Ettemaksud);
    },
    register: {command: `update docs.doc set status = 1 where id = $1`, type: "sql"},
    endProcess: {command: `update docs.doc set status = 2 where id = $1`, type: "sql"},
    executeCommand: {
        command: `select * from sp_execute_task($1::integer, $2::JSON, $3::TEXT )`, //$1- userId, $2 - params, $3 - task
        type:'sql',
        alias:'executeTask'
    },


};

module.exports = Ettemaksud;
