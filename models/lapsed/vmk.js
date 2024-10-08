'use strict';

let now = new Date();


const Vmk = {
    select: [
        {
            sql: `SELECT d.id,
                         d.docs_ids,
                         (to_char(created, 'DD.MM.YYYY HH:MM:SS')) :: TEXT    AS created,
                         (to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS')) :: TEXT AS lastupdate,
                         k.number                                             AS number,
                         to_char(k.maksepaev, 'YYYY-MM-DD')::TEXT             AS maksepaev,
                         to_char(k.maksepaev, 'DD.MM.YYYY')::TEXT             AS maksepaev_print,
                         k.viitenr,
                         k.aaid                                               AS aa_id,
                         aa.pank                                              AS pank,
                         trim(aa.arve)::VARCHAR(20)                           AS omaArve,
                         k.rekvId,
                         to_char(k.kpv, 'YYYY-MM-DD')::TEXT                   AS kpv,
                         to_char(k.kpv, 'DD.MM.YYYY')::TEXT                   AS kpv_print,
                         k.selg,
                         k.muud,
                         k.opt,
                         k.arvid,
                         k.aaid,
                         ('Number:' || arv.number :: TEXT || ' Kuupäev:' || arv.kpv :: TEXT || ' Jääk:' ||
                          (arv.jaak::NUMERIC(12, 2)) :: TEXT)                 AS arvnr,
                         (SELECT sum(summa)
                          FROM docs.mk1
                          WHERE parentid = k.id):: NUMERIC(12, 2)             AS summa,
                         COALESCE((dp.details :: JSONB ->>
                                   'konto'),
                                  '') :: VARCHAR(20)                          AS konto,
                         dp.selg::VARCHAR(120)                                AS dokprop,
                         k.doklausid,
                         (D.history -> 0 ->>
                          'user')::VARCHAR(120)                               AS koostaja,
                         laps.nimi                                            AS lapse_nimi,
                         laps.id                                              AS lapsid,
                         TRUE                                                 AS is_data_loaded

                  FROM docs.doc D
                           INNER JOIN docs.mk k
                                      ON k.parentId = D.id
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                           LEFT OUTER JOIN ou.aa AS aa ON k.aaid = aa.Id
                           LEFT OUTER JOIN docs.arv AS arv ON k.arvid = arv.parentId
                           LEFT OUTER JOIN lapsed.liidestamine l ON l.docid = d.id
                           LEFT OUTER JOIN lapsed.laps laps ON laps.id = l.parentid
                           LEFT OUTER JOIN libs.dokprop dp ON dp.id = k.doklausid
                  WHERE D.id = $1`,
            sqlAsNew: `SELECT $1 :: INTEGER                                  AS id,
                              $2 :: INTEGER                                  AS userid,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT  AS created,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT  AS lastupdate,
                              docs.sp_get_number(u.rekvid::INTEGER, 'VMK'::TEXT,
                                                 date_part('year', current_date)::INTEGER,
                                                 NULL::INTEGER)::VARCHAR(20) AS number,
                              to_char(now(), 'YYYY-MM-DD')::TEXT             AS maksepaev,
                              (SELECT id
                               FROM ou.aa
                               WHERE parentid = u.rekvid
                                 AND kassa = 1
                                   ORDER BY default_ DESC
                                   LIMIT 1)                                  AS aa_id,
                              trim('')::VARCHAR(20)                          AS pank,
                              NULL::INTEGER                                  AS rekvId,
                              to_char(now(), 'YYYY-MM-DD')::TEXT             AS kpv,
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
                              NULL::INTEGER                                  AS lapsId,
                              TRUE                                           AS is_data_loaded
                       FROM ou.userid u
                       WHERE u.id = $2 :: INTEGER`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT $2 :: INTEGER      AS userid,
                         trim(n.kood)       AS kood,
                         trim(n.nimetus)    AS nimetus,
                         trim(a.nimetus)    AS asutus,
                         trim(a.aadress)    AS aadress,
                         k.parentid         AS parent_id,
                         k1.aa::TEXT        AS aa,
                         k1.asutusid,
                         k1.konto,
                         k1.nomid,
                         k1.proj,
                         k1.summa,
                         k1.tunnus,
                         k1.journalid,
                         'EUR'::VARCHAR(20) AS valuuta,
                         1::NUMERIC(12, 4)  AS kuurs,
                         jid.number         AS lausnr
                  FROM docs.mk1 AS k1
                           INNER JOIN docs.mk k ON k.id = k1.parentId
                           INNER JOIN libs.nomenklatuur n ON n.id = k1.nomid
                           INNER JOIN libs.asutus a ON a.id = k1.asutusid
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                           LEFT OUTER JOIN docs.doc d ON k1.journalid = d.id
                           LEFT OUTER JOIN docs.journal j ON j.parentid = d.id
                           LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
                  WHERE k.parentid = $1`,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        },
        {
            sql: `SELECT rd.id, $2::INTEGER AS userid, trim(l.kood) AS doc_type, trim(l.nimetus) AS name
                  FROM docs.doc d
                           LEFT OUTER JOIN docs.doc rd ON rd.id IN (SELECT unnest(d.docs_ids))
                           LEFT OUTER JOIN libs.library l ON rd.doc_type_id = l.id
                           INNER JOIN ou.userid u ON u.id = $2::INTEGER
                  WHERE d.id = $1`,
            query: null,
            multiple: true,
            alias: 'relations',
            data: []
        },
        {
            sql: `WITH params AS (
                               SELECT $1::integer AS doc_id,
                                      $2::integer    AS user_id
                           )
                        SELECT t.id,
                          t.kpv,
                          to_char(a.kpv, 'DD.MM.YYYY') AS print_kpv,
                          t.summa                      AS tasu_summa,
                          a.summa                      AS arv_summa,
                          CASE WHEN coalesce((a.properties ->> 'tyyp'), '') = 'ETTEMAKS' THEN 0 ELSE 1 END *
                          coalesce(t.inf3_summa, 0)    AS inf3_summa,
                          a.number,
                          asutus.nimetus               AS asutus,
                          a.properties ->> 'tyyp'      AS tyyp,
                          a.jaak,
                          params.user_id               AS user_id
                           FROM docs.arvtasu t
                                    INNER JOIN docs.doc d ON d.id = t.doc_arv_id
                                    INNER JOIN docs.arv a ON a.parentid = d.id
                                    INNER JOIN libs.asutus asutus ON asutus.id = a.asutusid,
                                    params
                           WHERE t.doc_tasu_id = params.doc_id
                             AND t.status <> 3
                       UNION ALL
                    SELECT t.id,
                           t.kpv,
                           to_char(mk.kpv, 'DD.MM.YYYY') AS print_kpv,
                           t.summa                       AS tasu_summa,
                           mk1.summa                     AS arv_summa,
                           0                             AS inf3_summa,
                           mk.number,
                           asutus.nimetus                AS asutus,
                           'ETTEMAKS'                    AS tyyp,
                           mk.jaak,
                           params.user_id                AS user_id
                    FROM docs.arvtasu t
                             INNER JOIN docs.doc d ON d.id = t.doc_arv_id
                             INNER JOIN docs.mk mk ON mk.parentid = d.id
                             INNER JOIN docs.mk1 mk1 ON mk1.parentid = mk.id
                             INNER JOIN libs.asutus asutus ON asutus.id = mk1.asutusid,
                         params
                    WHERE t.doc_tasu_id = params.doc_id
                      AND t.pankkassa = 4 -- ettemaksu ulekanne
                      AND t.status <> 3
                       `,
            query: null,
            multiple: true,
            alias: 'queryArvTasu',
            data: []
        },

    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "maksepaev", name: "Maksepäev", width: "10%", type: "date", interval: true},
            {id: "number", name: "Number", width: "10%"},
            {id: "asutus", name: "Maksja", width: "15%"},
            {id: "vanem_isikukood", name: "Maksja IK", width: "7%"},
            {id: "kreedit", name: "Summa", width: "7%", type: "number", interval: true},
            {id: "aa", name: "Arveldus arve", width: "10%"},
            {id: "viitenr", name: "Viite number", width: "10%"},
            {id: "nimi", name: "Nimi", width: "17%"},
            {id: "isikukood", name: "Isikukood", width: "7%"},

        ],
        sqlString: `SELECT mk.id,
                           to_char(mk.kpv, 'DD.MM.YYYY')::TEXT       AS kpv,
                           to_char(mk.maksepaev, 'DD.MM.YYYY')::TEXT AS maksepaev,
                           mk.selg,
                           mk.asutus,
                           mk.kood,
                           mk.rekvid,
                           mk.deebet::NUMERIC(12, 2),
                           mk.kreedit::NUMERIC(12, 2),
                           mk.number,
                           mk.journalid,
                           mk.aa,
                           mk.journalnr,
                           mk.opt,
                           mk.vanem_isikukood,
                           0                                         AS valitud,
                           mk.isikukood,
                           mk.nimi,
                           $2                                        AS userid,
                           mk.viitenr::TEXT
                    FROM lapsed.cur_lapsed_mk mk
                    WHERE mk.opt = 1
                      AND mk.rekvId = $1`,
        params: '',
        alias: 'curLasteMk'
    },
    returnData: {
        row: {},
        details: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'nimetus', name: 'Nimetus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: "nomid", name: "nomid", width: "200px", show: false},
            {id: 'asutus', name: 'Saaja', width: '200px', show: true, type: 'text', readOnly: false},
            {id: 'aa', name: 'Arveldus arve', width: '150px', show: true, type: 'text', readOnly: false},
            {id: 'summa', name: 'Summa', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'konto', name: 'Korr.konto', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'tunnus', name: 'Tunnus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'proj', name: 'Projekt', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'lausnr', name: 'Lausend', width: '100px', show: true, type: 'text', readOnly: false}
        ],
        gridArvConfig:
            [
                {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
                {id: 'tyyp', name: 'Arv. tüüp', width: '10%', show: true, type: 'text', readOnly: true},
                {id: 'number', name: 'Number', width: '10%', show: true, type: 'text', readOnly: true},
                {id: 'print_kpv', name: 'Kuupäev', width: '10%', show: true, type: 'text', readOnly: true},
                {id: 'asutus', name: 'Maksja', width: '20%', show: true, type: 'text', readOnly: true},
                {id: 'tasu_summa', name: 'Tasu summa', width: '10%', show: true, type: 'text', readOnly: true},
                {id: 'arv_summa', name: 'Arve summa', width: '10%', show: true, type: 'text', readOnly: true},
                {id: 'jaak', name: 'Arve jääk', width: '10%', show: true, type: 'text', readOnly: true},
                {id: 'inf3_summa', name: 'INF3 Summa', width: '10%', show: true, readOnly: true},
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
    executeTask: (task, docId, userId) => {
        // выполнит задачу, переданную в параметре

        let executeTask = task;
        if (executeTask.length == 0) {
            executeTask = ['start'];
        }

        let taskFunction = eval(executeTask[0]);
        return taskFunction(docId, userId, Vmk);
    },
    generateJournal: {
        command: `SELECT error_code, result, error_message
                  FROM docs.gen_lausend_vmk($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
        type: "sql",
        alias: 'generateJournal'
    },
    MakseUmberJaotada: {
        command: `SELECT error_code, result, error_message, doc_type_id 
                  FROM docs.makse_umber_jaotada( $2::INTEGER, $1::INTEGER, 0)`, //$2 - docs.doc.id, $1 - userId, $3 - liik (0 - default, 1-delete arvtasu)
        type: "sql",
        alias: 'MakseUmberJaotada'
    },
    TuhistaMakseJaotamine: {
        command: `SELECT error_code, result, error_message, doc_type_id
                  FROM docs.makse_umber_jaotada( $2::INTEGER, $1::INTEGER, 1)`, //$2 - docs.doc.id, $1 - userId, $3 - maksepaev
        type: "sql",
        alias: 'TuhistaMakseJaotamine'
    },

    bpm: [
        {
            id:0,
            name: 'Контировка',
            action: 'generateJournal',
            type: 'automat',
            actualStep: false
        },
        {
            id: 3,
            name: 'Makse ümber jaotada',
            task: 'MakseUmberJaotada',
            action: 'MakseUmberJaotada',
            type: 'manual',
            showDate: false,
            titleDate: 'Seisuga:',
            showViitenumber: false,
            titleViitenumber: 'Viitenumber:',
            showKogus: false,
            titleKogus: 'Summa:',
            actualStep: false,

        },
        {
            id: 4,
            name: 'Tühista makse jaotamine',
            task: 'TuhistaMakseJaotamine',
            action: 'TuhistaMakseJaotamine',
            type: 'manual',
            showDate: false,
            titleDate: 'Seisuga:',
            showViitenumber: false,
            titleViitenumber: 'Viitenumber:',
            showKogus: false,
            titleKogus: 'Summa:',
            actualStep: false,

        },

    ],

    print: [
        {
            view: 'vmk_kaart',
            params: 'id',
            register: `UPDATE docs.doc
                       SET history = history ||
                                     (SELECT row_to_json(row)
                                      FROM (SELECT now()                                                AS print,
                                                   (SELECT kasutaja FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                       WHERE id = $1`
        },
        {
            view: 'vmk_register',
            params: 'sqlWhere'
        },
    ],
    sepa: [
        {
            register: `UPDATE docs.doc
                       SET history = history ||
                                     (SELECT row_to_json(row)
                                      FROM (SELECT now()                                                AS earve,
                                                   (SELECT kasutaja FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                       WHERE id = $1`
        }
    ],
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                               AS id,
                         (ajalugu ->> 'user')::TEXT                                         AS kasutaja,
                         to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS') AS koostatud,
                         to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS') AS muudatud,
                         to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS')   AS prinditud,
                         to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS') AS kustutatud

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
