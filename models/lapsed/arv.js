'use strict';
//var co = require('co');
let now = new Date();
const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');

const Arv = {
    selectAsLibs: `SELECT *
                   FROM com_arved a
                   WHERE (a.rekvId = $1::INTEGER)
                     AND docs.usersRigths(a.id, 'select', $2::INTEGER)`, //$1 - rekvid, $2 userid
    select: [
        {
            sql: `SELECT d.id,
                         $2 :: INTEGER                                      AS userid,
                         to_char(created, 'DD.MM.YYYY HH:MM:SS') :: TEXT    AS created,
                         to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS') :: TEXT AS lastupdate,
                         d.bpm,
                         d.status                                           AS doc_status,
                         a.number::TEXT                                     AS number,
                         a.rekvId,
                         a.liik,
                         a.operid,
                         to_char(a.kpv, 'YYYY-MM-DD')::TEXT                 AS kpv,
                         a.asutusid,
                         a.arvId,
                         a.lisa:: TEXT                                      AS lisa,
                         to_char(a.tahtaeg, 'YYYY-MM-DD')::TEXT             AS tahtaeg,
                         a.kbmta,
                         a.kbm,
                         a.summa,
                         a.tasud,
                         a.tasudok::TEXT                                    AS tasudok,
                         a.muud,
                         a.jaak,
                         asutus.regkood,
                         asutus.nimetus::TEXT                               AS asutus,
                         asutus.aadress,
                         asutus.properties ->> 'kmkr'                       AS kmkr,
                         a.doklausid,
                         a.journalid,
                         coalesce(jid.number, 0) :: INTEGER                 AS laus_nr,
                         dp.details :: JSONB ->> 'konto'                    AS konto,
                         dp.details :: JSONB ->> 'kbmkonto'                 AS kbmkonto,
                         dp.selg :: TEXT                                    AS dokprop,
                         dp.vaatalaus                                       AS is_show_journal,
                         d.history -> 0 ->> 'user'                          AS koostaja,
                         a.properties ->> 'aa'                              AS aa,
                         a.properties ->> 'viitenr'                         AS viitenr,
                         l.id                                               AS lapsId,
                         l.isikukood::TEXT,
                         l.nimi::TEXT                                       AS lapse_nimi
                  FROM docs.doc d
                           INNER JOIN docs.arv a ON a.parentId = d.id
                           INNER JOIN libs.asutus AS asutus ON asutus.id = a.asutusId
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                           LEFT OUTER JOIN libs.dokprop dp ON dp.id = a.doklausid
                           LEFT OUTER JOIN docs.journal j ON j.parentid = a.journalid
                           LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
                           LEFT OUTER JOIN lapsed.liidestamine ll ON ll.docid = d.id
                           LEFT OUTER JOIN lapsed.laps l
                  ON l.id = ll.parentid
                  WHERE D.id = $1`,
            sqlAsNew: `SELECT $1 :: INTEGER                                                          AS id,
                              $2 :: INTEGER                                                          AS userid,
                              to_char(now(), 'YYYY-MM-DD HH:MM:SS') :: TEXT                          AS created,
                              to_char(now(), 'YYYY-MM-DD HH:MM:SS') :: TEXT                          AS lastupdate,
                              NULL                                                                   AS bpm,
                              0                                                                      AS doc_status,
                              (SELECT arve
                               FROM ou.aa aa
                               WHERE aa.parentid = u.rekvid
                                 AND NOT empty(default_::INTEGER)
                                 AND NOT empty(kassa::INTEGER)
                                 AND kassa = 1
                               LIMIT 1)::VARCHAR(20)                                                 AS aa,

                              docs.sp_get_number(u.rekvId, 'ARV', year(date()), NULL) :: VARCHAR(20) AS number,
                              0.00                                                                   AS summa,
                              NULL :: INTEGER                                                        AS rekvId,
                              0                                                                      AS liik,
                              NULL :: INTEGER                                                        AS operid,
                              to_char(now() :: DATE, 'YYYY-MM-DD')::TEXT                             AS kpv,
                              NULL :: INTEGER                                                        AS asutusid,
                              NULL :: INTEGER                                                        AS arvId,
                              '' :: VARCHAR(120)                                                     AS lisa,
                              to_char((now() + INTERVAL '14 days') :: DATE, 'YYYY-MM-DD')::TEXT      AS tahtaeg,
                              0 :: NUMERIC                                                           AS kbmta,
                              0.00 :: NUMERIC                                                        AS kbm,
                              0 :: NUMERIC(14, 2)                                                    AS summa,
                              NULL :: DATE                                                           AS tasud,
                              NULL :: VARCHAR(20)                                                    AS tasudok,
                              NULL :: TEXT                                                           AS muud,
                              0.00                                                                   AS jaak,
                              0 :: INTEGER                                                           AS objektId,
                              NULL :: VARCHAR(20)                                                    AS objekt,
                              NULL :: VARCHAR(20)                                                    AS regkood,
                              NULL :: VARCHAR(120)                                                   AS asutus,
                              NULL :: TEXT                                                           AS aadress,
                              NULL :: VARCHAR(120)                                                   AS kmkr,
                              NULL :: INTEGER                                                        AS doklausid,
                              NULL :: VARCHAR(120)                                                   AS dokprop,
                              NULL :: TEXT                                                           AS konto,
                              NULL :: TEXT                                                           AS kbmkonto,
                              NULL :: INTEGER                                                        AS journalid,
                              NULL :: INTEGER                                                        AS laus_nr,
                              NULL :: VARCHAR(120)                                                   AS koostaja,
                              0 ::INTEGER                                                            AS is_show_journal,
                              ''::VARCHAR(120)                                                       AS viitenr,
                              NULL::INTEGER                                                          AS lapsId
                       FROM ou.userid u
                       WHERE u.id = $2 :: INTEGER`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT a1.id,
                         $2 :: INTEGER                           AS userid,
                         a1.nomid,
                         a1.kogus,
                         a1.hind,
                         a1.kbm,
                         a1.kbmta,
                         a1.summa,
                         trim(n.kood) :: VARCHAR(20)             AS kood,
                         trim(n.nimetus) :: VARCHAR(254)         AS nimetus,
                         a1.soodus,
                         a1.kood1,
                         a1.kood2,
                         a1.kood3,
                         a1.kood4,
                         a1.kood5,
                         a1.tunnus,
                         a1.proj,
                         a1.konto,
                         a1.tp,
                         NULL :: TEXT                            AS vastisik,
                         NULL :: TEXT                            AS formula,
                         'EUR' :: VARCHAR(20)                    AS valuuta,
                         1 :: NUMERIC                            AS kuurs,
                         (CASE
                              WHEN a1.kbm_maar IS NULL
                                  THEN coalesce((n.properties :: JSONB ->> 'vat'), '-') :: VARCHAR(20)
                              ELSE a1.kbm_maar END)::VARCHAR(20) AS km,
                         n.uhik,
                         a1.muud
                  FROM docs.arv1 AS a1
                           INNER JOIN docs.arv a ON a.id = a1.parentId
                           INNER JOIN libs.nomenklatuur n ON n.id = a1.nomId
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                  WHERE a.parentid = $1 :: INTEGER`,
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
                  WHERE d.id = $1 :: INTEGER`,
            query: null,
            multiple: true,
            alias: 'relations',
            data: []
        },
        {
            sql: `SELECT Arvtasu.id,
                         arvtasu.kpv,
                         arvtasu.summa,
                         'MK' :: VARCHAR(20)           AS dok,
                         'PANK' :: VARCHAR             AS liik,
                         pankkassa,
                         mk1.journalid,
                         doc_tasu_id,
                         coalesce(journalid.number, 0) AS number,
                         'EUR' :: VARCHAR              AS valuuta,
                         1 :: NUMERIC                  AS kuurs
                  FROM docs.arvtasu arvtasu
                           INNER JOIN docs.mk mk ON (arvtasu.doc_tasu_id = mk.parentid AND arvtasu.pankkassa = 1)
                           INNER JOIN docs.mk1 mk1 ON (mk.id = mk1.parentid)
                           LEFT OUTER JOIN docs.journalid journalid ON mk1.journalId = journalId.journalId
                  WHERE Arvtasu.doc_arv_id = $1
                    AND arvtasu.summa <> 0
                    AND arvtasu.status <> 3
                  UNION ALL
                  SELECT Arvtasu.id,
                         arvtasu.kpv,
                         arvtasu.summa,
                         'KASSAORDER' :: VARCHAR(20)   AS dok,
                         'KASSA' :: VARCHAR            AS liik,
                         pankkassa,
                         korder1.journalid,
                         doc_tasu_id,
                         coalesce(journalid.number, 0) AS number,
                         'EUR' :: VARCHAR              AS valuuta,
                         1 :: NUMERIC                  AS kuurs
                  FROM docs.arvtasu arvtasu
                           INNER JOIN docs.korder1 korder1
                                      ON (arvtasu.doc_tasu_id = korder1.parentid AND arvtasu.pankkassa = 2)
                           LEFT OUTER JOIN docs.journalid journalid ON korder1.journalId = journalId.journalId
                  WHERE Arvtasu.doc_arv_id = $1
                    AND arvtasu.summa <> 0
                    AND arvtasu.status <> 3
                  UNION ALL
                  SELECT Arvtasu.id,
                         arvtasu.kpv,
                         arvtasu.summa,
                         'PAEVARAAMAT' :: VARCHAR(20)  AS dok,
                         'JOURNAL' :: VARCHAR          AS liik,
                         pankkassa,
                         arvtasu.doc_tasu_id           AS journalid,
                         doc_tasu_id,
                         coalesce(journalid.number, 0) AS number,
                         'EUR' :: VARCHAR              AS valuuta,
                         1 :: NUMERIC                  AS kuurs
                  FROM docs.arvtasu arvtasu
                           LEFT OUTER JOIN docs.journal journal
                                           ON (arvtasu.doc_tasu_id = journal.parentId AND arvtasu.pankkassa = 3)
                           LEFT OUTER JOIN docs.journalid journalid ON (journal.id = journalId.journalId)
                  WHERE Arvtasu.doc_arv_id = $1
                    AND arvtasu.summa <> 0
                    AND arvtasu.status <> 3
                    AND arvtasu.pankkassa = 3
                  UNION ALL
                  SELECT Arvtasu.id,
                         arvtasu.kpv,
                         arvtasu.summa,
                         '' :: VARCHAR(20) AS dok,
                         'MUUD' :: VARCHAR AS liik,
                         pankkassa,
                         0                 AS journalid,
                         NULL,
                         0                 AS number,
                         'EUR' :: VARCHAR  AS valuuta,
                         1 :: NUMERIC      AS kuurs
                  FROM docs.arvtasu arvtasu
                  WHERE Arvtasu.doc_arv_id = $1
                    AND arvtasu.summa <> 0
                    AND arvtasu.status <> 3
                    AND arvtasu.pankkassa IN (0, 4)

            `,
            query: null,
            multiple: true,
            alias: 'queryArvTasu',
            data: []
        },
        {
            sql: `SELECT result, error_code, error_message
                  FROM docs.create_new_mk($1::INTEGER, $2::JSONB)`, //$1 - userId, $2 - params -> {"arv_id": ?, "dok":"SMK" }
            query: null,
            multuple: false,
            alias: 'create_new_mk',
            data: []
        },
        {
            sql: `SELECT result, error_code, error_message
                  FROM docs.create_new_order($1::INTEGER, $2::JSONB)`, //$1 - userId, $2 - params -> {"arv_id": ?, "dok":"SORDER" }
            query: null,
            multuple: false,
            alias: 'create_new_order',
            data: []
        },
        {
            sql: `SELECT docs.check_arv_number($1::integer, $2::JSON)::integer as tulemus`, //$1 - rekvId, $2 - params ->'{"tyyp":1, "number":"10", "aasta": 2017, "asutus": 5155}'
            query: null,
            multuple: false,
            alias: 'validate_arve_number',
            data: []

        },
        {
            sql: `SELECT docs.sp_update_doc_bpm_data($1::integer, $2::integer, $3::JSONB)::integer as tulemus`, //$1 - docId, $2 - userId, $3 - params ->'{"omniva":[{"isik":"koostaja", "kpv":"2019-05-31","rolli":"creator"},{"isik":"koostaja", "kpv":"2019-05-31","rolli":"kinnitaja"}]}')
            query: null,
            multuple: false,
            alias: 'update_bpm',
            data: []

        },
        {
            sql: `SELECT *
                  FROM json_to_recordset((SELECT (bpm ->> 'omniva')::JSON
                                          FROM docs.doc
                                          WHERE id = $1)) AS x(kpv VARCHAR(40), isik VARCHAR(254), rolli VARCHAR(20))`, //$1 - docId
            query: null,
            multuple: false,
            alias: 'get_omniva_bpm',
            data: []
        }

    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px", show: false},
            {id: "number", name: "Number", width: "100px"},
            {id: "kpv", name: "Kuupaev", width: "100px"},
            {id: "asutus", name: "Maksja", width: "200px"},
            {id: "summa", name: "Summa", width: "75px"},
            {id: "tahtaeg", name: "Tähtaeg", width: "100px"},
            {id: "jaak", name: "Jääk", width: "100px"},
            {id: "tasud", name: "Tasud", width: "100px"},
            {id: "nimi", name: "Nimi", width: "100px"},
            {id: "isikukood", name: "Isikukood", width: "100px"},
        ],
        sqlString: `SELECT id,
                           number :: VARCHAR(20),
                           rekvid,
                           to_char(kpv, 'DD.MM.YYYY') :: TEXT   AS kpv,
                           summa,
                           to_char(tahtaeg, 'DD.MM.YYYY')::TEXT AS tahtaeg,
                           jaak,
                           lisa,
                           tasud,
                           tasudok,
                           userid,
                           asutus :: TEXT                       AS asutus,
                           vanem_isikukood::TEXT,
                           asutusid,
                           journalid,
                           markused,
                           lausnr,
                           docs_ids,
                           a.arve::TEXT                         AS aa,
                           a.viitenr::TEXT                      AS viitenr,
                           a.isikukood,
                           a.nimi,
                           $2::INTEGER                          AS userId
                    FROM lapsed.cur_laste_arved a
                    WHERE a.rekvId = $1::INTEGER`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curLasteArved'
    },
    returnData: {
        row: {},
        details: [],
        relations: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'nomid', name: 'nomId', width: '0px', show: false, type: 'text', readOnly: false},
            {
                id: 'kood',
                name: 'Kood',
                width: '100px',
                show: true,
                type: 'select',
                readOnly: false,
                dataSet: 'nomenclature',
                valueFieldName: 'nomid'
            },
            {id: 'nimetus', name: 'Nimetus', width: '300px', show: true, readOnly: true},
            {id: 'hind', name: 'Hind', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'kogus', name: 'kogus', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'kbm', name: 'Käibemaks', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'summa', name: 'Summa', width: '100px', show: true, type: 'number', readOnly: false}
        ]
    },
    saveDoc: `select docs.sp_salvesta_arv($1::json, $2::integer, $3::integer) as id`,
    deleteDoc: `SELECT error_code, result, error_message
                FROM docs.sp_delete_arv($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'kpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {
            name: 'tahtaeg',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {name: 'asutusid', type: 'N', min: null, max: null},
        {name: 'lapsid', type: 'N', min: null, max: null},
        {name: 'summa', type: 'N', min: -9999999, max: 999999}
    ],
    executeCommand: {
        command: `select docs.sp_kooperi_arv($1::integer, $2::integer) as result`,
        type: 'sql',
        alias: 'kooperiArv'
    },
    bpm: [
        {
            step: 1,
            name: 'Контировка',
            action: 'generateJournal',
            nextStep: 2,
            task: 'automat',
            data: [],
            status: null,
            actualStep: false
        }
    ],
    generateJournal: {
        command: "SELECT error_code, result, error_message FROM docs.gen_lausend_arv($2::INTEGER, $1::INTEGER)", //$1 - docs.doc.id, $2 - userId
        type: "sql",
        alias: 'generateJournal'
    },
    executeTask: function (task, docId, userId) {
        console.log('executeTask', task, docId, userId);
        // выполнит задачу, переданную в параметре

        let executeTask = task;
        if (executeTask.length == 0) {
            executeTask = ['start'];
        }

        let taskFunction = eval(executeTask[0]);
        return taskFunction(docId, userId, this);
    }
};

module.exports = Arv;
