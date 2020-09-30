'use strict';

let now = new Date();

const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');


const Luba = {
    selectAsLibs: `SELECT id,
                          regkood,
                          nimetus,
                          rekvid,
                          coalesce(summa, 0)::NUMERIC   AS summa,
                          coalesce(jaak, 0)::NUMERIC    AS jaak,
                          coalesce(volg, 0)::NUMERIC    AS volg,
                          coalesce(intress, 0)::NUMERIC AS intress,
                          ettemaks                      AS ettemaks,
                          kas_arhiiv
                   FROM rekl.com_asutus_rekl
                   WHERE rekvid = $1
                   ORDER BY nimetus`,
    select: [
        {
            sql: `SELECT d.id,
                         d.docs_ids,
                         (to_char(d.created, 'DD.MM.YYYY HH:MM:SS')) :: TEXT    AS created,
                         (to_char(d.lastupdate, 'DD.MM.YYYY HH:MM:SS')) :: TEXT AS lastupdate,
                         d.bpm,
                         trim(t.nimetus)                                        AS doc,
                         trim(t.kood)                                           AS doc_type_id,
                         trim(s.nimetus)                                        AS status,
                         l.number                                               AS number,
                         l.rekvid,
                         l.asutusid,
                         l.muud                                                 AS muud,
                         l.algkpv,
                         l.loppkpv,
                         l.summa,
                         l.jaak,
                         l.volg,
                         l.alus,
                         l.staatus,
                         l.kord,
                         l.intress
                  FROM docs.doc d
                           INNER JOIN rekl.luba l ON l.parentId = d.id
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                           INNER JOIN libs.asutus a ON a.id = l.asutusid
                           LEFT OUTER JOIN libs.library t ON t.id = d.doc_type_id
                           LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                  WHERE d.id = $1`,
            sqlAsNew: `SELECT $1 :: INTEGER                                 AS id,
                              $2 :: INTEGER                                 AS userid,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT AS created,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT AS lastupdate,
                              NULL                                          AS bpm,
                              trim(t.nimetus)                               AS doc,
                              trim(t.kood)                                  AS doc_type_id,
                              trim(s.nimetus)                               AS status,
                              docs.sp_get_number(u.rekvId, 'LUBA', year(date()), NULL) +
                              1 :: VARCHAR(20)                              AS number,
                              NULL :: INTEGER                               AS rekvId,
                              NULL :: INTEGER                               AS asutusid,
                              NULL :: TEXT                                  AS muud,
                              (make_date(date_part('year', current_date)::INTEGER,
                                         date_part('month', current_date) :: INTEGER, 1) -
                               INTERVAL '1 month') :: DATE                  AS algkpv,
                              (make_date(date_part('year', current_date)::INTEGER,
                                         date_part('month', current_date) :: INTEGER, 1) -
                               INTERVAL '1 day') :: DATE                    AS loppkpv,
                              0 :: NUMERIC                                  AS summa,
                              0 :: NUMERIC                                  AS jaak,
                              0 :: NUMERIC                                  AS volg,
                              NULL :: VARCHAR                               AS alus,
                              0                                             AS staatus,
                              0                                             AS doc_status,
                              'KUU' :: VARCHAR(20)                          AS kord,
                              0 :: NUMERIC                                  AS intress
                       FROM libs.library t,
                            libs.library s,
                            (SELECT * FROM ou.userid u WHERE u.id = $2 :: INTEGER) AS u
                       WHERE t.library = 'DOK'
                         AND t.kood = 'LUBA'
                         AND u.id = $2 :: INTEGER
                         AND s.library = 'STATUS'
                         AND s.kood = '0'`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT $2 :: INTEGER                   AS userid,
                         trim(n.kood) :: VARCHAR(20)     AS kood,
                         trim(n.nimetus) :: VARCHAR(254) AS nimetus,
                         l1.*,
                         NULL :: VARCHAR(20)             AS liik,
                         NULL :: VARCHAR(20)             AS SOODUSTYYP
                  FROM rekl.luba AS l
                           INNER JOIN rekl.luba1 l1 ON l1.parentid = l.Id
                           INNER JOIN libs.nomenklatuur n ON n.id = l1.nomid
                  WHERE l.parentid = $1`,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        },
        {
            sql: `SELECT rd.id, $2 :: INTEGER AS userid, trim(l.kood) AS doc_type, trim(l.nimetus) AS name
                  FROM docs.doc d
                           LEFT OUTER JOIN docs.doc rd ON rd.id IN (SELECT unnest(d.docs_ids))
                           LEFT OUTER JOIN libs.library l ON rd.doc_type_id = l.id
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                  WHERE d.id = $1`,
            query: null,
            multiple: true,
            alias: 'relations',
            data: []
        },

    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "algkpv", name: "Alg.Kpv", width: "100px"},
            {id: "loppkpv", name: "Lõpp kpv", width: "100px"},
            {id: "nomid", name: "nomid", width: "200px", show: false},
            {id: "summa", name: "Summa", width: "100px"},
            {id: "volg", name: "Võlg", width: "100px"},
            {id: "status", name: "Staatus", width: "100px"}
        ],
        sqlString: `SELECT d.*
                    FROM cur_luba d
                    WHERE d.rekvId = $1
                      AND coalesce(docs.usersRigths(d.id, 'select', $2), TRUE)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curReklLuba'
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
    saveDoc: `select rekl.sp_salvesta_luba($1, $2, $3) as id`,
    deleteDoc: `SELECT error_code, result, error_message
                FROM rekl.sp_delete_luba($1, $2)`, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'algkpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {
            name: 'loppkpv',
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
        return taskFunction(docId, userId, Luba);
    },
    register: {
        command: `UPDATE docs.doc
                  SET status = 1
                  WHERE id = $1`, type: "sql"
    },
    endProcess: {
        command: `UPDATE docs.doc
                  SET status = 2
                  WHERE id = $1`, type: "sql"
    },
    executeCommand: {
        command: `SELECT *
                  FROM sp_execute_task($1 :: INTEGER, $2 :: JSON, $3 :: TEXT)`, //$1- userId, $2 - params, $3 - task
        type: 'sql',
        alias: 'executeTask'
    },


};

module.exports = Luba;
