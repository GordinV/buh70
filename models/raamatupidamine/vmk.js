'use strict';

let now = new Date();

const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');


const Vmk = {
    select: [
        {
            sql: `SELECT d.id,
                         d.docs_ids,
                         (to_char(created, 'DD.MM.YYYY HH:MM:SS')) :: TEXT              AS created,
                         (to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS')) :: TEXT           AS lastupdate,
                         d.bpm,
                         trim(l.nimetus)                                                AS doc,
                         trim(l.kood)                                                   AS doc_type_id,
                         trim(s.nimetus)                                                AS status,
                         k.number                                                       AS number,
                         k.maksepaev                                                    AS maksepaev,
                         k.viitenr,
                         k.aaid                                                         AS aa_id,
                         aa.pank                                                        AS pank,
                         trim(aa.arve)::VARCHAR(20)                                     AS omaArve,
                         k.rekvId,
                         k.kpv                                                          AS kpv,
                         k.selg,
                         k.muud,
                         k.opt,
                         k.arvid,
                         k.aaid,
                         ('Number:' || arv.number :: TEXT || ' Kuupäev:' || arv.kpv :: TEXT || ' Jääk:' ||
                          arv.jaak :: TEXT)                                             AS arvnr,
                         (SELECT sum(summa)
                          FROM docs.mk1
                          WHERE parentid = k.id)                                        AS summa,
                         coalesce((dp.details :: JSONB ->> 'konto'), '') :: VARCHAR(20) AS konto,
                         dp.selg::VARCHAR(120)                                          AS dokprop,
                         k.doklausid,
                         (d.history -> 0 ->> 'user')::VARCHAR(120)                      AS koostaja,
                         k.dokid
                  FROM docs.doc d
                           INNER JOIN docs.mk k ON k.parentId = d.id
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                           LEFT OUTER JOIN libs.library l ON l.id = d.doc_type_id
                           LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                           LEFT OUTER JOIN ou.aa AS aa ON k.aaid = aa.Id
                           LEFT OUTER JOIN docs.arv AS arv ON k.arvid = arv.Id
                           LEFT OUTER JOIN libs.dokprop dp ON dp.id = k.doklausid
                  WHERE d.id = $1`,
            sqlAsNew: `SELECT $1 :: INTEGER                                  AS id,
                              $2 :: INTEGER                                  AS userid,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT  AS created,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT  AS lastupdate,
                              NULL                                           AS bpm,
                              'VMK'                                          AS doc_type_id,
                              docs.sp_get_number(u.rekvid::INTEGER, 'VMK'::TEXT,
                                                 date_part('year', current_date)::INTEGER,
                                                 NULL::INTEGER)::VARCHAR(20) AS number,
                              now() :: DATE                                  AS maksepaev,
                              0                                              AS aaid,
                              1                                              AS pank,
                              trim('')::VARCHAR(20)                          AS omaarve,
                              NULL::INTEGER                                  AS rekvId,
                              now() :: DATE                                  AS kpv,
                              NULL::VARCHAR(120)                             AS viitenr,
                              NULL::TEXT                                     AS selg,
                              NULL::TEXT                                     AS muud,
                              1                                              AS opt,
                              NULL::VARCHAR(20)                              AS regkood,
                              NULL::VARCHAR(254)                             AS asutus,
                              NULL::INTEGER                                  AS arvid,
                              NULL::VARCHAR(20)                              AS arvnr,
                              0::NUMERIC(12, 2)                              AS summa,
                              NULL::VARCHAR(120)                             AS dokprop,
                              NULL::VARCHAR(20)                              AS konto,
                              0                                              AS doklausid,
                              NULL                                           AS dokid
                       FROM (SELECT *
                             FROM ou.userid u
                             WHERE u.id = $2 :: INTEGER) AS u
                       WHERE u.id = $2 :: INTEGER`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `WITH doc AS (
                SELECT trim(n.kood)::VARCHAR(20)     AS kood,
                       trim(n.nimetus)::VARCHAR(254) AS nimetus,
                       trim(a.nimetus)::VARCHAR(254) AS asutus,
                       trim(a.aadress)               AS aadress,
                       k.parentid                    AS parent_id,
                       k1.*
                FROM docs.mk1 AS k1
                         INNER JOIN docs.mk k ON k.id = k1.parentId
                         INNER JOIN libs.nomenklatuur n ON n.id = k1.nomid
                         INNER JOIN libs.asutus a ON a.id = k1.asutusid
                         INNER JOIN ou.userid u ON u.id = 70 :: INTEGER
                WHERE k.parentid = $1
            )
            SELECT d.*,
                   coalesce(l.number, 0)   AS lausnr,
                   coalesce(l.lausend, '') AS lausend,
                   $2 :: INTEGER                    AS userid                   
            FROM doc d
                     LEFT OUTER JOIN (SELECT id,
                                             number,
                                             kpv,
                                             rekvid,
                                             trim(array_agg(lausend)::TEXT, '{}"') AS lausend
                                      FROM (
                                               SELECT j.id,
                                                      j.number,
                                                      j.kpv,
                                                      j.rekvid,
                                                      ('D ' || ltrim(rtrim(j.deebet)) || ' ' ||
                                                       'K ' || ltrim(rtrim(j.kreedit)) || ' ' ||
                                                       ltrim(rtrim(round(j.summa, 2)::TEXT)) || ' ' ||
                                                       'TA ' || ltrim(rtrim(j.kood1::TEXT)) || ' ' ||
                                                       'Allikas ' || ltrim(rtrim(j.kood2::TEXT)) || ' ' ||
                                                       'RV ' || ltrim(rtrim(j.kood3::TEXT)) || ' ' ||
                                                       'Art ' || ltrim(rtrim(j.kood5::TEXT)))::TEXT AS lausend
                                               FROM (SELECT d.id,
                                                            d.rekvid,
                                                            j.kpv,
                                                            j1.deebet,
                                                            j1.kreedit,
                                                            j1.summa,
                                                            j1.kood1,
                                                            j1.kood2,
                                                            j1.kood3,
                                                            j1.kood5,
                                                            jid.number
                                                     FROM docs.journal j
                                                              INNER JOIN docs.doc D ON D.id = j.parentid
                                                              INNER JOIN docs.journalid jid ON j.id = jid.journalid
                                                              INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                                                     WHERE D.status <> 3
                                                       AND d.doc_type_id IN
                                                           (SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'JOURNAL')
                                                       AND d.id IN (SELECT journalid FROM doc)
                                                    ) j
                                           ) qry
                                      GROUP BY id, number, kpv, rekvid
            ) l ON l.id = d.journalid`,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        },
        {
            sql: `SELECT d.*
                  FROM docs.get_relative_docs($1::INTEGER) d
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER`,
            query: null,
            multiple: true,
            alias: 'relations',
            data: []
        },
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
        sqlString: `SELECT d.*,
                           0 AS valitud
                    FROM cur_pank d
                    WHERE d.rekvId = $1
                      AND coalesce(docs.usersRigths(d.id, 'select', $2::INTEGER), TRUE)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curMk'
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
    saveDoc: `select docs.sp_salvesta_mk($1::json, $2::integer, $3::integer) as id`,
    deleteDoc: `SELECT error_code, result, error_message
                FROM docs.sp_delete_mk($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
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
    register: {
        command: `UPDATE docs.doc
                  SET status = 1
                  WHERE id = $1`, type: "sql"
    },
    generateJournal: {
        command: `SELECT error_code, result, error_message
                  FROM docs.gen_lausend_vmk($2::INTEGER, $1::INTEGER)`, // $1 - userId, $2 - docId
        type: "sql",
        alias: 'generateJournal'
    },
    endProcess: {
        command: `UPDATE docs.doc
                  SET status = 2
                  WHERE id = $1`, type: "sql"
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
                           SELECT jsonb_array_elements(history) AS ajalugu, d.id, d.rekvid
                           FROM docs.doc d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry`,
        type: "sql",
        alias: "getLogs"
    },


};

module.exports = Vmk;
