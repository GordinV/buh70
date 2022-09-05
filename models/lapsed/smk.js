'use strict';

let now = new Date();

const Smk = {
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
                         k.jaak

                  FROM docs.doc D
                           INNER JOIN docs.mk k
                                      ON k.parentId = D.id
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                           LEFT OUTER JOIN ou.aa AS aa ON k.aaid = aa.Id
                           LEFT OUTER JOIN docs.arv AS arv ON k.arvid = arv.parentId
                           LEFT OUTER JOIN libs.dokprop dp ON dp.id = k.doklausid
                  WHERE D.id = $1`,
            sqlAsNew: `SELECT $1 :: INTEGER                                                AS id,
                              $2 :: INTEGER                                                AS userid,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT                AS created,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT                AS lastupdate,
                              coalesce(docs.sp_get_number(u.rekvid::INTEGER, 'SMK'::TEXT,
                                                          date_part('year', current_date)::INTEGER,
                                                          NULL::INTEGER)::VARCHAR(20), '') AS number,
                              to_char(now(), 'YYYY-MM-DD')::TEXT                           AS maksepaev,
                              0                                                            AS aaid,
                              trim('')::VARCHAR(20)                                        AS pank,
                              NULL::INTEGER                                                AS rekvId,
                              to_char(now(), 'YYYY-MM-DD')::TEXT                           AS kpv,
                              NULL::VARCHAR(120)                                           AS viitenr,
                              NULL::TEXT                                                   AS selg,
                              NULL::TEXT                                                   AS muud,
                              2                                                            AS opt,
                              NULL::VARCHAR(20)                                            AS regkood,
                              NULL::VARCHAR(254)                                           AS asutus,
                              NULL::INTEGER                                                AS arvid,
                              NULL::VARCHAR(20)                                            AS arvnr,
                              0::NUMERIC(12, 2)                                            AS summa,
                              NULL::VARCHAR(120)                                           AS dokprop,
                              NULL::VARCHAR(20)                                            AS konto,
                              0                                                            AS doklausid,
                              NULL::INTEGER                                                AS lapsId,
                              0                                                            AS jaak
                       FROM ou.userid u
                       WHERE u.id = $2 :: INTEGER
            `,
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
            sql: ` SELECT t.id,
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
                          $2                           AS user_id
                   FROM docs.arvtasu t
                            INNER JOIN docs.doc d ON d.id = t.doc_arv_id
                            INNER JOIN docs.arv a ON a.parentid = d.id
                            INNER JOIN libs.asutus asutus ON asutus.id = a.asutusid
                   WHERE t.doc_tasu_id = $1
                     AND t.status <> 3
                   ORDER BY t.kpv
                           , t.id`,
            query: null,
            multiple: true,
            alias: 'queryArvTasu',
            data: []
        },

    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "kpv", name: "Maksepäev", width: "10%", type: "date", interval: true},
            {id: "number", name: "Number", width: "5%"},
            {id: "asutus", name: "Maksja", width: "20%"},
            {id: "deebet", name: "Summa", width: "10%", type: "number", interval: true},
            {id: "aa", name: "Arveldus arve", width: "15%"},
            {id: "viitenr", name: "Viite number", width: "7%"},
            {id: "nimi", name: "Nimi", width: "15%"},
            {id: "isikukood", name: "Isikukood", width: "10%"},
            {id: "yksused", name: "Yksus", width: "7%"},

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
                           mk.viitenr::TEXT,
                           mk.yksused::TEXT
                    FROM lapsed.cur_lapsed_mk mk
                    WHERE mk.opt = 2
                      AND mk.rekvId = $1`,
//                      AND coalesce(docs.usersRigths(mk.id, 'select', $2::INTEGER), TRUE)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        totals: `sum(deebet) over() as deebet_total,
                sum(kreedit) over() as kreedit_total`,
        alias: 'curLasteMk'
    },

    returnData: {
        row: {},
        details: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'nimetus', name: 'Nimetus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'asutus', name: 'Maksja', width: '200px', show: true, type: 'text', readOnly: false},
            {id: 'aa', name: 'Maksja arveldusarve', width: '150px', show: true, type: 'text', readOnly: false},
            {id: 'summa', name: 'Summa', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'konto', name: 'Korr.konto', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'tunnus', name: 'Tunnus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'proj', name: 'Projekt', width: '100px', show: true, type: 'text', readOnly: false}
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
        return taskFunction(docId, userId);
    },
    register: {
        command: `UPDATE docs.doc
                  SET status = 1
                  WHERE id = $1`, type: "sql"
    },
    generateJournal: {
        command: `SELECT error_code, result, error_message
                  FROM docs.gen_lausend_smk($1::INTEGER, $2::INTEGER)`, // $1 - docId $2- userId
        type: "sql",
        alias: 'generateJournal'
    },
    koostaMK: {
        command: `SELECT error_code, result, error_message
                  FROM lapsed.koosta_mk_arve_alusel($2::INTEGER, $1::INTEGER, $3::DATE) row`, //$1 - docs.doc.id, $2 - userId
        type: "sql",
        alias: 'koostaMK'
    },
    print: [
        {
            view: 'smk_kaart',
            params: 'id',
            register: `UPDATE docs.doc
                       SET history = history ||
                                     (SELECT row_to_json(row)
                                      FROM (SELECT now()                                                AS print,
                                                   (SELECT kasutaja FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                       WHERE id = $1`
        },
        {
            view: 'smk_register',
            params: 'sqlWhere'
        },
    ],
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                               AS id,
                         (ajalugu ->> 'user')::TEXT                                         AS kasutaja,
                         to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS') AS koostatud,
                         to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS') AS muudatud,
                         to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS')   AS prinditud,
                         to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS') AS kustutatud

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
    bpm: [
        {
            id: 0,
            name: 'Контировка',
            action: 'generateJournal',
            type: 'automat',
            actualStep: false
        },
        {
            id: 1,
            name: 'Koosta tagasimakse',
            task: 'KoostaTagasimakse',
            action: 'KoostaTagasimakse',
            type: 'manual',
            showDate: true,
            showKogus: false,
            actualStep: false,

        },
        {
            id: 2,
            name: 'Koosta ulekannemakse',
            task: 'KoostaUlekanneMakse',
            action: 'KoostaUlekanneMakse',
            type: 'manual',
            showDate: true,
            titleDate: 'Seisuga:',
            showViitenumber: true,
            titleViitenumber: 'Viitenumber:',
            showKogus: true,
            titleKogus: 'Summa:',
            actualStep: false,

        },


    ],

    KoostaTagasimakse: {
        command: `SELECT error_code, result, error_message, doc_type_id
                  FROM docs.create_return_mk($2::INTEGER, (SELECT to_jsonb(row.*)
                                                           FROM (SELECT $1 AS mk_id, $3::DATE AS maksepaev) row))`, //$1 - docs.doc.id, $2 - userId, $3 - maksepaev
        type: "sql",
        alias: 'KoostaTagasimakse'
    },

    KoostaUlekanneMakse: {
        command: `SELECT error_code, result, error_message, doc_type_id
                  FROM docs.ulekanne_makse($2::INTEGER, (SELECT to_jsonb(row.*)
                                                         FROM (SELECT $1          AS mk_id,
                                                                      $3::DATE    AS maksepaev,
                                                                      $4::TEXT    AS viitenumber,
                                                                      $5::NUMERIC AS kogus) row))`, //$1 - docs.doc.id, $2 - userId, $3 - maksepaev
        type: "sql",
        alias: 'KoostaUlekanneMakse'
    },

};

module.exports = Smk;

