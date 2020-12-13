'use strict';

let now = new Date();

const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');


const Toiming = {
    select: [
        {
            sql: `SELECT d.id,
                         d.docs_ids,
                         (to_char(d.created, 'DD.MM.YYYY HH:MM:SS')) :: TEXT            AS created,
                         (to_char(d.lastupdate, 'DD.MM.YYYY HH:MM:SS')) :: TEXT         AS lastupdate,
                         d.bpm,
                         trim(dt.nimetus)                                               AS doc,
                         trim(dt.kood)                                                  AS doc_type_id,
                         trim(s.nimetus)                                                AS status,
                         t.number                                                       AS number,
                         d.rekvid,
                         t.asutusid,
                         t.lubaid,
                         t.muud                                                         AS muud,
                         t.kpv,
                         t.summa,
                         t.tyyp,
                         t.deklid,
                         t.staatus,
                         t.saadetud,
                         t.dokpropid,
                         t.journalid,
                         t.lubaid,
                         t.tahtaeg,
                         t.alus :: VARCHAR(254),
                         t.ettekirjutus,
                         coalesce((dp.details :: JSONB ->> 'konto'), '') :: VARCHAR(20) AS konto,
                         dp.selg :: VARCHAR(120)                                        AS dokprop,
                         coalesce(jid.number, 0) :: INTEGER                             AS lausend,
                         rekl.fnc_dekl_jaak(d.ID)                                       AS jaak,
                         t.lisa->>'dekltasud' :: TEXT                                   AS tasud,
                         t.lisa->>'failid' :: TEXT                                      AS failid,
                         ((lisa->>'failid') :: JSONB)->>'fail'                          AS fail,
                         ((lisa->>'failid') :: JSONB)->>'tyyp'                          AS storage_tyyp

                  FROM docs.doc d
                         INNER JOIN rekl.toiming t ON t.parentId = d.id
                         INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                         INNER JOIN libs.asutus a ON a.id = t.asutusid
                         LEFT OUTER JOIN libs.dokprop dp ON dp.id = t.dokpropid
                         LEFT OUTER JOIN libs.library dt ON t.id = d.doc_type_id
                         LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                         LEFT OUTER JOIN docs.doc dj ON t.journalid = dj.id
                         LEFT OUTER JOIN docs.journal j ON j.parentid = dj.id
                         LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
                  WHERE d.id = $1`,
            sqlAsNew: `SELECT $1 :: INTEGER                                 AS id,
                              $2 :: INTEGER                                 AS userid,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT AS created,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT AS lastupdate,
                              NULL                                          AS bpm,
                              trim(t.nimetus)                               AS doc,
                              trim(t.kood)                                  AS doc_type_id,
                              trim(s.nimetus)                               AS status,
                              0 :: INTEGER                                  AS number,
                              NULL :: INTEGER                               AS rekvId,
                              NULL :: INTEGER                               AS asutusid,
                              NULL :: INTEGER                               AS lubaid,
                              NULL :: TEXT                                  AS muud,
                              now() :: DATE                                 AS kpv,
                              0 :: NUMERIC                                  AS summa,
                              'DEKL' :: REKL_TOIMING_LIIK                   AS TYYP,
                              NULL :: INTEGER                               AS deklid,
                              NULL :: DOK_STATUS                            AS staatus,
                              NULL :: DATE                                  AS saadetud,
                              NULL :: INTEGER                               AS dokpropid,
                              NULL :: DATE                                  AS tahtaeg,
                              NULL :: VARCHAR(254)                          AS alus,
                              NULL :: TEXT                                  AS ettekirjutus,
                              NULL :: VARCHAR(120)                          AS dokprop,
                              NULL :: VARCHAR(20)                           AS konto,
                              NULL :: INTEGER                               AS lausend,
                              0 :: NUMERIC                                  AS jaak,
                              NULL :: TEXT                                  AS tasud,
                              NULL :: TEXT                                  AS failid,
                              NULL :: TEXT                                  AS fail,
                              NULL :: TEXT                                  AS storage_type
                       FROM libs.library t,
                            libs.library s,
                            (SELECT * FROM ou.userid u WHERE u.id = $2 :: INTEGER) AS u
                       WHERE t.library = 'DOK'
                         AND t.kood = 'DEKL'
                         AND u.id = $2 :: INTEGER
                         AND s.library = 'STATUS'
                         AND s.kood = '0'`,
            query: null,
            multiple: false,
            alias: 'row',
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
        {
            sql: `SELECT t.summa, t.kpv AS kpv
                  FROM docs.doc d
                         INNER JOIN rekl.toiming t ON d.id = t.parentid
                  WHERE t.tyyp = 'TASU'
                    AND d.docs_ids @> ARRAY[$1] :: INTEGER []
                  ORDER BY d.id DESC`,
            query: null,
            multiple: true,
            alias: 'tasud',
            data: []
        }

    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "kpv", name: "Kpv", width: "100px"},
            {id: "summa", name: "Summa", width: "100px"},
            {id: "tahtaeg", name: "Tähtaeg", width: "100px"},
            {id: "tyyp", name: "Tüüp", width: "100px"},
            {id: "volg", name: "Võlg", width: "100px"},
            {id: "lausend", name: "Lausend", width: "100px"},
            {id: "parandus", name: "Parandus", width: "100px"},
            {id: "status", name: "Staatus", width: "100px"}
        ],
        sqlString: `SELECT d.*
                    FROM cur_toiming d
                    WHERE d.rekvId = $1
                      AND coalesce(docs.usersRigths(d.id, 'select', $2), TRUE)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curReklDekl'
    },
    returnData: {
        row: {},
        details: []
    },
    saveDoc: `select rekl.sp_salvesta_toiming($1, $2, $3) as id`,
    deleteDoc: `SELECT error_code, result, error_message
                FROM rekl.sp_delete_toiming($1, $2)`, // $1 - userId, $2 - docId
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
        return taskFunction(docId, userId, Toiming);
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
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                                                        AS id,
                         (ajalugu ->> 'user')::VARCHAR(20)                                                           AS kasutaja,
                         coalesce(to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS koostatud,
                         coalesce(to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS muudatud,
                         coalesce(to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS prinditud,
                         coalesce(to_char((ajalugu ->> 'email')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'), '')::VARCHAR(20) AS
                                                                                                                        email,
                         coalesce(to_char((ajalugu ->> 'earve')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS earve,
                         coalesce(to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS kustutatud
                  FROM (
                           SELECT jsonb_array_elements( history) AS ajalugu, d.id, d.rekvid
                           FROM docs.doc d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry WHERE (qry.ajalugu ->> 'user') IS NOT NULL`,
        type: "sql",
        alias: "getLogs"
    },


};

module.exports = Toiming;
