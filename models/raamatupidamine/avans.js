'use strict';

let now = new Date();

const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');


const Avans = {
    select: [
        {
            sql: `SELECT
                      d.id,
                      d.docs_ids,
                      (to_char(d.created, 'DD.MM.YYYY HH:MM:SS')) :: TEXT              AS created,
                      (to_char(d.lastupdate, 'DD.MM.YYYY HH:MM:SS')) :: TEXT           AS lastupdate,
                      d.bpm,
                      trim(l.nimetus)                                                AS doc,
                      trim(l.kood)                                                   AS doc_type_id,
                      trim(s.nimetus)                                                AS status,
                      d1.number                                                      AS number,
                      d1.kpv                                                         AS kpv,
                      d1.rekvid,
                      coalesce(d1.selg,'')                                           AS selg,
                      d1.asutusid,
                      d1.journalid,
                      d1.dokpropid,
                      coalesce((SELECT sum(summa)
                                FROM docs.avans2
                                WHERE parentid = d1.id), 0) :: NUMERIC(12, 2)        AS summa,
                      d1.jaak                                                        AS jaak,
                      d1.muud                                                        AS muud,
                      coalesce((dp.details :: JSONB ->> 'konto'), '') :: VARCHAR(20) AS konto,
                      dp.selg :: VARCHAR(120)                                        AS dokprop,
                      d1.dokpropid,
                      coalesce(jid.number, 0) :: INTEGER                             AS lausend,
                      (select sum(summa) from docs.avans2 where parentid = d1.id)::numeric(14,2) as summa,
                      (d.history->0->>'user')::varchar(120)                          AS koostaja
                    FROM docs.doc d
                      INNER JOIN docs.avans1 d1 ON d1.parentId = d.id
                      INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                      INNER JOIN libs.asutus a ON a.id = d1.asutusid
                      LEFT OUTER JOIN libs.library l ON l.id = d.doc_type_id
                      LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                      LEFT OUTER JOIN libs.dokprop dp ON dp.id = d1.dokpropid
                      LEFT OUTER JOIN docs.doc dj ON d1.journalid = dj.id
                      LEFT OUTER JOIN docs.journal j ON j.parentid = dj.id
                      LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
                    WHERE d.id = $1`,
            sqlAsNew: `SELECT
                      $1 :: INTEGER                                 AS id,
                      $2 :: INTEGER                                 AS userid,
                      to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT AS created,
                      to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT AS lastupdate,
                      NULL                                         AS bpm,
                      trim(l.nimetus)                               AS doc,
                      trim(l.kood)                                  AS doc_type_id,
                      trim(s.nimetus)                               AS status,
                      coalesce((SELECT max(val(array_to_string(regexp_match(number, '\\d+'),'')))
                       FROM docs.avans1
                       WHERE rekvid in (
                       select rekvid from ou.userid where id = $2)
                       )::integer,0) :: INTEGER + 1                             AS number,
                      NULL::integer                                 AS rekvId,
                      now() :: DATE                                 AS kpv,
                      NULL::TEXT                                    AS selg,
                      NULL::TEXT                                    AS muud,
                      NULL::integer as asutusid,
                      NULL::varchar(20)                             AS regkood,
                      NULL::varchar(254)                            AS asutus,
                      0::numeric(12,2) as summa,
                      0::numeric(12,2)                              AS jaak,
                     null::varchar(120) as  dokprop,
                     null::varchar(20) as konto,
                     0 as doklausid,
                     null::integer as journalid,
                     null::integer as dokpropid,
                     null::integer as lausend,
                     0::numeric(14,2) as summa
                    FROM libs.library l,
                      libs.library s,
                      (SELECT *
                       FROM ou.userid u
                       WHERE u.id = $2 :: INTEGER) AS u
                    WHERE l.library = 'DOK' AND l.kood = 'AVANS'
                          AND u.id = $2 :: INTEGER
                          AND s.library = 'STATUS' AND s.kood = '0'`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT
                      $2 :: INTEGER    AS userid,
                      trim(n.kood)::varchar(20)    AS kood,
                      trim(n.nimetus)::varchar(254) AS nimetus,
                      a2.*,
                      coalesce(v.valuuta,'EUR')::varchar(20) as valuuta,
                      coalesce(v.kuurs,1)::numeric(12,4) as kuurs
                    FROM docs.avans1 AS a1
                      INNER JOIN docs.avans2 a2 ON a2.parentid = a1.Id
                      INNER JOIN libs.nomenklatuur n ON n.id = a2.nomid
                      INNER JOIN libs.asutus a ON a.id = a1.asutusid
                      INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                      LEFT OUTER JOIN docs.dokvaluuta1 v ON (v.dokid = a2.id AND v.dokliik = array_position((enum_range(NULL :: DOK_VALUUTA)), 'avans2'))
                      left outer join docs.doc d on a1.journalid = d.id
                      left outer join docs.journal j on j.parentid = d.id
                      left outer join docs.journalid jid on jid.journalid = j.id
                    WHERE a1.parentid = $1`,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        },
        {
            sql: `select $2 :: INTEGER    AS userid,
                    a.* 
                    from cur_avans_tasud a where parentid = $1`,
            query: null,
            multiple: true,
            alias: 'curLaekumised',
            data: []
        },
        {
            sql: `SELECT
                      rd.id,
                      $2 :: INTEGER   AS userid,
                      trim(l.kood)    AS doc_type,
                      trim(l.nimetus) AS name
                    FROM docs.doc d
                      LEFT OUTER JOIN docs.doc rd ON rd.id IN (SELECT unnest(d.docs_ids))
                      LEFT OUTER JOIN libs.library l ON rd.doc_type_id = l.id
                      INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                    WHERE d.id = $1`,
            query: null,
            multiple: true,
            alias: 'relations',
            data: []
        }

    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "kpv", name: "Kuupäev", width: "100px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "asutus", name: "Maksja", width: "200px"},
            {id: "asutusid", name: "asutusid", width: "200px", show: false},
            {id: "nomid", name: "nomid", width: "200px", show: false},
            {id: "aa", name: "Arveldus arve", width: "100px"},
            {id: "viitenr", name: "Viite number", width: "100px"},
            {id: "maksepaev", name: "Maksepäev", width: "100px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Status", width: "100px"}
        ],
        sqlString: `SELECT
                          d.*
                        FROM cur_avans d
                        WHERE d.rekvId = $1
                              AND coalesce(docs.usersRigths(d.id, 'select', $2::INTEGER), TRUE)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curAvans'
    },
    returnData: {
        row: {},
        details: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'nimetus', name: 'Nimetus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: "nomid", name: "nomid", width: "200px", show: false},
            {id: 'asutus', name: 'Maksja', width: '200px', show: true, type: 'text', readOnly: false},
            {id: 'aa', name: 'Arveldus arve', width: '150px', show: true, type: 'text', readOnly: false},
            {id: 'summa', name: 'Summa', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'konto', name: 'Korr.konto', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'tunnus', name: 'Tunnus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'proj', name: 'Projekt', width: '100px', show: true, type: 'text', readOnly: false}
        ]
    },
    saveDoc: `select docs.sp_salvesta_avans($1::json, $2::integer, $3::integer) as id`,
    deleteDoc: `select error_code, result, error_message from docs.sp_delete_avans($1::integer, $2::integer)`, // $1 - userId, $2 - docId
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
        {
            step: 1,
            name: 'Контировка',
            action: 'generateJournal',
            nextStep: 2,
            task: 'automat',
            data: [],
            status: null,
            actualStep: false
        },
//        {step:2, name:'Оплата', action: 'tasumine', nextStep:3, task:'human', data:[], status:null, actualStep:false},
        {
            step: 2,
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
        return taskFunction(docId, userId, Avans);
    },
    register: {command: `update docs.doc set status = 1 where id = $1`, type: "sql"},
    generateJournal: {
        command: `select error_code, result, error_message from docs.gen_lausend_avans($2::integer, $1::integer)`, // $1 - userId, $2 - docId
        type: "sql",
        alias: 'generateJournal'
    },
    endProcess: {command: `update docs.doc set status = 2 where id = $1`, type: "sql"},
    executeCommand: {
        command: `select result, error_message from docs.fnc_avansijaak($1::integer)`,
        type:'sql',
        alias:'fncAvansiJaak'
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
                       ) qry`,
        type: "sql",
        alias: "getLogs"
    },

};

module.exports = Avans;
