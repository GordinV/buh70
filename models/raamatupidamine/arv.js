'use strict';
//var co = require('co');
let now = new Date();
const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');

const Arv = {
    selectAsLibs: `SELECT *
                   FROM com_arved a
                   WHERE (a.rekvId = $1)
                     AND docs.usersRigths(a.id, 'select', $2)`, //$1 - rekvid, $2 userid
    select: [
        {
            sql: `SELECT d.id,
                         $2 :: INTEGER                                                     AS userid,
                         to_char(created, 'DD.MM.YYYY HH:MM:SS') :: TEXT                   AS created,
                         to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS') :: TEXT                AS lastupdate,
                         d.bpm,
                         trim(l.nimetus)                                                   AS doc,
                         trim(l.kood)                                                      AS doc_type_id,
                         trim(s.nimetus)                                                   AS status,
                         d.status                                                          AS doc_status,
                         trim(a.number) :: VARCHAR(20)                                     AS number,
                         a.summa,
                         a.rekvId,
                         a.liik,
                         a.operid,
                         a.kpv                                                             AS kpv,
                         a.asutusid,
                         a.arvId,
                         trim(a.lisa) :: VARCHAR(120)                                      AS lisa,
                         a.tahtaeg                                                         AS tahtaeg,
                         a.kbmta,
                         a.kbm,
                         a.summa,
                         a.tasud,
                         trim(a.tasudok)                                                   AS tasudok,
                         a.muud,
                         a.jaak,
                         a.objektId,
                         trim(a.objekt)                                                    AS objekt,
                         asutus.regkood,
                         trim(asutus.nimetus)                                              AS asutus,
                         asutus.aadress,
                         (asutus.properties->>'kmkr') :: VARCHAR(20)                       AS kmkr,
                         a.doklausid,
                         a.journalid,
                         coalesce(jid.number, 0) :: INTEGER                                AS laus_nr,
                         coalesce((dp.details :: JSONB ->> 'konto'), '') :: VARCHAR(20)    AS konto,
                         coalesce((dp.details :: JSONB ->> 'kbmkonto'), '') :: VARCHAR(20) AS kbmkonto,
                         dp.selg :: VARCHAR(120)                                           AS dokprop,
                         (d.history->0->>'user') :: VARCHAR(120)                           AS koostaja
                  FROM docs.doc d
                         INNER JOIN libs.library l ON l.id = d.doc_type_id
                         INNER JOIN docs.arv a ON a.parentId = d.id
                         INNER JOIN libs.asutus AS asutus ON asutus.id = a.asutusId
                         INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                         LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                         LEFT OUTER JOIN libs.dokprop dp ON dp.id = a.doklausid
                         LEFT OUTER JOIN docs.journal j ON j.parentid = a.journalid
                         LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
                  WHERE d.id = $1`,
            sqlAsNew: `SELECT $1 :: INTEGER                                                          AS id,
                              $2 :: INTEGER                                                          AS userid,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT                          AS created,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT                          AS lastupdate,
                              NULL                                                                   AS bpm,
                              trim(l.nimetus)                                                        AS doc,
                              trim(l.kood)                                                           AS doc_type_id,
                              trim(s.nimetus)                                                        AS status,
                              0                                                                      AS doc_status,
                              docs.sp_get_number(u.rekvId, 'ARV', year(date()), NULL) :: VARCHAR(20) AS number,
                              0.00                                                                   AS summa,
                              NULL :: INTEGER                                                        AS rekvId,
                              0                                                                      AS liik,
                              NULL :: INTEGER                                                        AS operid,
                              now() :: DATE                                                          AS kpv,
                              NULL :: INTEGER                                                        AS asutusid,
                              NULL :: INTEGER                                                        AS arvId,
                              NULL :: VARCHAR(120)                                                   AS lisa,
                              (now() + INTERVAL '14 days') :: DATE                                   AS tahtaeg,
                              0 :: NUMERIC                                                           AS kbmta,
                              0.00 :: NUMERIC                                                        AS kbm,
                              0 :: NUMERIC(14, 2)                                                    AS summa,
                              NULL :: DATE                                                           AS tasud,
                              NULL :: VARCHAR(20)                                                    AS tasudok,
                              NULL :: TEXT                                                           AS muud,
                              0.00                                                                   AS jaak,
                              NULL :: INTEGER                                                        AS objektId,
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
                              NULL :: VARCHAR(120)                                                   AS koostaja
                       FROM libs.library l,
                            libs.library s,
                            ou.userid u
                       WHERE l.library = 'DOK'
                         AND l.kood = 'ARV'
                         AND u.id = $2 :: INTEGER
                         AND s.library = 'STATUS'
                         AND s.kood = '0'`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT a1.id,
                         $2 :: INTEGER                                                   AS userid,
                         a1.nomid,
                         a1.kogus,
                         a1.hind,
                         a1.kbm,
                         a1.kbmta,
                         a1.summa,
                         trim(n.kood) :: VARCHAR(20)                                     AS kood,
                         trim(n.nimetus) :: VARCHAR(254)                                 AS nimetus,
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
                         NULL :: TEXT                                                    AS vastisik,
                         NULL :: TEXT                                                    AS formula,
                         'EUR' :: VARCHAR(20)                                            AS valuuta,
                         1 :: NUMERIC                                                    AS kuurs,
                         coalesce((n.properties :: JSONB ->> 'vat'), '-') :: VARCHAR(20) AS km,
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
                  FROM docs.create_new_mk($1, $2)`, //$1 - userId, $2 - params -> {"arv_id": ?, "dok":"SMK" }
            query: null,
            multuple: false,
            alias: 'create_new_mk',
            data: []
        },
        {
            sql: `SELECT result, error_code, error_message
                  FROM docs.create_new_order($1, $2)`, //$1 - userId, $2 - params -> {"arv_id": ?, "dok":"SORDER" }
            query: null,
            multuple: false,
            alias: 'create_new_order',
            data: []
        }

    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px", show: false},
            {id: "number", name: "Number", width: "100px"},
            {id: "kpv", name: "Kuupaev", width: "100px"},
            {id: "summa", name: "Summa", width: "75px"},
            {id: "tahtaeg", name: "Tähtaeg", width: "100px"},
            {id: "jaak", name: "Jääk", width: "100px"},
            {id: "tasud", name: "Tasud", width: "100px"},
            {id: "asutus", name: "Asutus", width: "200px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Staatus", width: "100px"},
        ],
        sqlString: `SELECT id,
                           arv_id,
                           number :: VARCHAR(20),
                           rekvid,
                           kpv,
                           summa,
                           tahtaeg,
                           jaak,
                           tasud,
                           tasudok,
                           userid,
                           asutus :: VARCHAR(254),
                           asutusid,
                           journalid,
                           liik,
                           ametnik,
                           objektid,
                           objekt :: VARCHAR(254),
                           markused,
                           lausnr,
                           docs_ids
                    FROM cur_arved a
                    WHERE a.rekvId = $1
                      AND docs.usersRigths(a.id, 'select', $2)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curArved'
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
    saveDoc: `select docs.sp_salvesta_arv($1, $2, $3) as id`,
    deleteDoc: `SELECT error_code, result, error_message
                FROM docs.sp_delete_arv($1, $2)`, // $1 - userId, $2 - docId
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
        {name: 'summa', type: 'N', min: -9999999, max: 999999}
    ],
    executeCommand: {
        command: `select docs.sp_kooperi_arv(?gnUser, ?tnId) as result`,
        type: 'sql',
        alias: 'kooperiArv'
    },
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
    register: {
        command: `UPDATE docs.doc
                  SET status = 1
                  WHERE id = $1`, type: "sql"
    },
    generateJournal: {
        command: "SELECT error_code, result, error_message FROM docs.gen_lausend_arv($2, $1)", //$1 - docs.doc.id, $2 - userId
        type: "sql",
        alias: 'generateJournal'
    },
    endProcess: {command: "UPDATE docs.doc SET status = 2 WHERE id = $1", type: "sql"},
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

