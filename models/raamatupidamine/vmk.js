'use strict';

let now = new Date();

const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');


const Vmk = {
    select: [
        {
            sql: `SELECT
                  d.id,
                  d.docs_ids,
                  (to_char(created, 'DD.MM.YYYY HH:MM:SS')) :: TEXT                                                   AS created,
                  (to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS')) :: TEXT                                                AS lastupdate,
                  d.bpm,
                  trim(l.nimetus)                                                                                     AS doc,
                  trim(l.kood)                                                                                        AS doc_type_id,
                  trim(s.nimetus)                                                                                     AS status,
                  k.number                                                                                            AS number,
                  k.maksepaev                                                                                         AS maksepaev,
                  k.viitenr,
                  k.aaid                                                                                              AS aa_id,
                  trim(aa.nimetus)                                                                                    AS pank,
                  k.rekvId,
                  k.kpv                                                                                               AS kpv,
                  k.selg,
                  k.muud,
                  k.opt,
                  k.arvid,
                  k.aaid,
                  ('Number:' || arv.number :: TEXT || ' Kuupäev:' || arv.kpv :: TEXT || ' Jääk:' || arv.jaak :: TEXT) AS arvnr,
                  (SELECT sum(summa)
                   FROM docs.mk1
                   WHERE parentid = k.id)                                                                             AS summa,
                   coalesce((dp.details :: JSONB ->> 'konto'),'') :: VARCHAR(20)                                      AS konto,
                   dp.selg::varchar(120)                                                                              as dokprop,
                   k.doklausid
                FROM docs.doc d
                  INNER JOIN docs.mk k ON k.parentId = d.id
                  INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                  LEFT OUTER JOIN libs.library l ON l.id = d.doc_type_id
                  LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                  LEFT OUTER JOIN ou.aa AS aa ON k.aaid = aa.Id
                  LEFT OUTER JOIN docs.arv AS arv ON k.arvid = arv.Id
                  left outer join libs.dokprop dp on dp.id = k.doklausid 
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
                       FROM docs.mk
                       WHERE opt = 0 
                       and rekvid in (
                       select rekvid from ou.userid where id = $2)
                       ),0) :: INTEGER + 1                          AS number,
                      now() :: DATE                                 AS maksepaev,
                      aa.id                                         AS aaid,
                      trim(aa.name)                                 AS pank,
                      NULL::integer                                 AS rekvId,
                      now() :: DATE                                 AS kpv,
                      NULL::varchar(120)                            AS viitenr,
                      NULL::TEXT                                    AS selg,
                      NULL::TEXT                                    AS muud,
                      0                                             AS opt,
                      NULL::varchar(20)                             AS regkood,
                      NULL::varchar(254)                            AS asutus,
                      NULL::integer                                 AS arvid,
                      NULL::varchar(20)                             AS arvnr,
                      0::numeric(12,2)                              AS summa,
                     null::varchar(120) as  dokprop,
                     null::varchar(20) as konto,
                     0 as doklausid
                    FROM libs.library l,
                      libs.library s,
                      (SELECT
                         id,
                         trim(nimetus) AS name
                       FROM ou.aa
                       WHERE pank = 1
                       ORDER BY default_
                       LIMIT 1) AS aa,
                      (SELECT *
                       FROM ou.userid u
                       WHERE u.id = $2 :: INTEGER) AS u
                    WHERE l.library = 'DOK' AND l.kood = 'VMK'
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
                      trim(a.nimetus)::varchar(254) AS asutus,
                      k1.*,
                      'EUR'::varchar(20) as valuuta,
                      1::numeric(12,4) as kuurs,
                      coalesce(jid.number,0)::integer as lausnr
                    FROM docs.mk1 AS k1
                      INNER JOIN docs.mk k ON k.id = k1.parentId
                      INNER JOIN libs.nomenklatuur n ON n.id = k1.nomid
                      INNER JOIN libs.asutus a ON a.id = k1.asutusid
                      INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                      left outer join docs.doc d on k1.journalid = d.id
                      left outer join docs.journal j on j.parentid = d.id
                      left outer join docs.journalid jid on jid.journalid = j.id
                    WHERE k.parentid = $1`,
            query: null,
            multiple: true,
            alias: 'details',
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
                          d.*,
                          0 AS valitud
                        FROM cur_mk d
                        WHERE d.rekvId = $1
                              AND coalesce(docs.usersRigths(d.id, 'select', $2), TRUE)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias:'curMk'
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
    saveDoc: `select docs.sp_salvesta_mk($1, $2, $3) as id`,
    deleteDoc: `select error_code, result, error_message from docs.sp_delete_mk($1, $2)`, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'kpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
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
        return taskFunction(docId, userId, Vmk);
    },
    register: {command: `update docs.doc set status = 1 where id = $1`, type: "sql"},
    generateJournal: {
        command: `select error_code, result, error_message from docs.gen_lausend_vmk($2, $1)`, // $1 - userId, $2 - docId
        type: "sql",
        alias: 'generateJournal'
    },
    endProcess: {command: `update docs.doc set status = 2 where id = $1`, type: "sql"},


};

module.exports = Vmk;
