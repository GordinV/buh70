'use strict';

let now = new Date();

const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');

const Vorder = {
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
                  k.summa,
                  k.kassaid                                                                                           AS kassa_id,
                  trim(aa.nimetus)                                                                                    AS kassa,
                  k.rekvId,
                  k.kpv                                                                        AS kpv,
                  k.asutusid,
                  trim(k.dokument)                                                                                    AS dokument,
                  k.alus,
                  k.muud,
                  k.nimi,
                  k.aadress,
                  k.tyyp,
                  asutus.regkood,
                  trim(asutus.nimetus)                                                                                AS asutus,
                  k.arvid,
                  ('Number:' || arv.number :: TEXT || ' Kuupäev:' || arv.kpv :: TEXT || ' Jääk:' || arv.jaak :: TEXT) AS arvnr,
                  k.doklausid,
                  k.journalid,
                  coalesce(jid.number,0)::integer as lausnr,
                   coalesce((dp.details :: JSONB ->> 'konto'),'') :: VARCHAR(20)                                      AS konto,
                   dp.selg::varchar(120)                                                                              as dokprop

                FROM docs.doc d
                  INNER JOIN libs.library l ON l.id = d.doc_type_id
                  INNER JOIN docs.korder1 k ON k.parentId = d.id
                  INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                  LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                  LEFT OUTER JOIN libs.asutus AS asutus ON asutus.id = k.asutusId
                  LEFT OUTER JOIN ou.aa AS aa ON k.kassaid = aa.Id
                  LEFT OUTER JOIN docs.arv AS arv ON k.arvid = arv.Id
                  left outer join docs.journal j on j.parentid = k.journalid                  
                  left outer join docs.journalid jid on jid.journalid = j.id                  
                  left outer join libs.dokprop dp on dp.id = k.doklausid 
                WHERE d.id = $1`,
            sqlAsNew: `SELECT
                      $1 :: INTEGER                                   AS id,
                      $2 :: INTEGER                                   AS userid,
                      (now() :: DATE || 'T' || now() :: TIME) :: TEXT AS created,
                      (now() :: DATE || 'T' || now() :: TIME) :: TEXT AS lastupdate,
                      NULL                                            AS bpm,
                      trim(l.nimetus)                                 AS doc,
                      trim(l.kood)                                    AS doc_type_id,
                      trim(s.nimetus)                                 AS status,
                      docs.get_new_number('VORDER', 1, year(now()::date))::varchar(20)  AS number,
                      0                                               AS summa,
                      aa.id                                           AS kassa_id,
                      trim(aa.name)                                   AS kassa,
                      NULL::integer                                   AS rekvId,
                      now()::date                                     AS kpv,
                      NULL::integer                                   AS asutusid,
                      NULL::varchar(120)                              AS dokument,
                      NULL::text                                      AS alus,
                      NULL::text                                      AS muud,
                      NULL::text                                      AS nimi,
                      NULL::text                                      AS aadress,
                      2                                               AS tyyp,
                      0::numeric(12,2)                                AS summa,
                      NULL::varchar(20)                               AS regkood,
                      NULL::varchar(254)                              AS asutus,
                      NULL::integer                                   AS arvid,
                      NULL::integer                                   AS arvnr,
                      NULL::integer                                   as doklausid,
                      0::integer                                      as journalid,
                      NULL::integer as lausnr,
                      null::varchar(120) as  dokprop,
                      null::varchar(20) as konto
                    FROM libs.library l,
                      ou.userid u,
                      libs.library s,
                      (SELECT
                         id,
                         trim(nimetus) AS name
                       FROM ou.aa
                       WHERE kassa = 1
                       ORDER BY default_
                       LIMIT 1) AS aa
                    WHERE l.library = 'DOK' AND l.kood = 'VORDER'
                          AND u.id =$2 :: INTEGER
                          AND s.library = 'STATUS' AND s.kood = '0'`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT
                  k1.id,
                  $2 :: INTEGER   AS userid,
                  trim(n.kood)    AS kood,
                  trim(n.nimetus) AS nimetus,
                  trim(n.uhik)    AS uhik,
                  k1.*,
                  coalesce(v.valuuta,'EUR')::varchar(20) as valuuta,
                  coalesce(v.kuurs,1)::numeric(12,4) as kuurs
                FROM docs.korder2 AS k1
                  INNER JOIN docs.korder1 k ON k.id = k1.parentId
                  INNER JOIN libs.nomenklatuur n ON n.id = k1.nomid
                  INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                  left outer join docs.dokvaluuta1 v on (k1.id = v.dokid and v.dokliik = 11)                 
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
            {id: "kpv", name: "Kuupaev", width: "100px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "nimi", name: "Nimi", width: "200px"},
            {id: "dokument", name: "Dokument", width: "200px"},
            {id: "summa", name: "Summa", width: "100px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Status", width: "100px"}
        ],
        sqlString: `SELECT *
                    FROM cur_korder k
                    WHERE k.rekvId = $1
                          AND coalesce(docs.usersRigths(k.id, 'select', $2), TRUE)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curKorder'
    },
    returnData: {
        row: {},
        relations: [],
        details: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'nimetus', name: 'Nimetus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'summa', name: 'Summa', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'konto', name: 'Korr.konto', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'tunnus', name: 'Tunnus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'proj', name: 'Projekt', width: '100px', show: true, type: 'text', readOnly: false}
        ]
    },
    saveDoc: `select docs.sp_salvesta_korder($1, $2, $3) as id`,
    deleteDoc: `select error_code, result, error_message from docs.sp_delete_korder($1, $2)`, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'kpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {name: 'asutusid', type: 'N', min: null, max: null},
        {name: 'summa', type: 'N', min: -9999999, max: 999999}
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
        return taskFunction(docId, userId, Vorder);
    },
    register: {command: `update docs.doc set status = 1 where id = $1`, type: "sql"},
    generateJournal: {
        command: `select error_code, result, error_message from docs.gen_lausend_vorder($2, $1)`, // $1 - userId, $2 - docId
        type: "sql",
        alias: 'generateJournal'
    },
    endProcess: {command: `update docs.doc set status = 2 where id = $1`, type: "sql"},


};

module.exports = Vorder;

