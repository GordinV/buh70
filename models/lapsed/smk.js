'use strict';

let now = new Date();

const Smk = {
    select: [
        {
            sql: `SELECT d.id,
                         d.docs_ids,
                         (to_char(created, 'DD.MM.YYYY HH:MM:SS')) :: TEXT              AS created,
                         (to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS')) :: TEXT           AS lastupdate,
                         k.number                                                       AS number,
                         to_char(k.maksepaev, 'YYYY-MM-DD')::TEXT                       AS maksepaev,
                         to_char(k.maksepaev, 'DD.MM.YYYY')::TEXT                       AS maksepaev_print,
                         k.viitenr,
                         k.aaid                                                         AS aa_id,
                         aa.pank                                                        AS pank,
                         trim(aa.arve)::VARCHAR(20)                                     AS omaArve,
                         k.rekvId,
                         to_char(k.kpv, 'YYYY-MM-DD')::TEXT                             AS kpv,
                         to_char(k.kpv, 'DD.MM.YYYY')::TEXT                             AS kpv_print,
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
                         (d.history -> 0 ->> 'user')::VARCHAR(120)                      AS koostaja

                  FROM docs.doc d
                           INNER JOIN docs.mk k ON k.parentId = d.id
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                           LEFT OUTER JOIN ou.aa AS aa ON k.aaid = aa.Id
                           LEFT OUTER JOIN docs.arv AS arv ON k.arvid = arv.Id
                           LEFT OUTER JOIN libs.dokprop dp ON dp.id = k.doklausid
                  WHERE d.id = $1`,
            sqlAsNew: `SELECT $1 :: INTEGER                                  AS id,
                              $2 :: INTEGER                                  AS userid,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT  AS created,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT  AS lastupdate,
                              docs.sp_get_number(u.rekvid::INTEGER, 'SMK'::TEXT,
                                                 date_part('year', current_date)::INTEGER,
                                                 NULL::INTEGER)::VARCHAR(20) AS number,
                              to_char(now(), 'YYYY-MM-DD')::TEXT             AS maksepaev,
                              0                                              AS aaid,
                              trim('')::VARCHAR(20)                          AS pank,
                              NULL::INTEGER                                  AS rekvId,
                              to_char(now(), 'YYYY-MM-DD')::TEXT             AS kpv,
                              NULL::VARCHAR(120)                             AS viitenr,
                              NULL::TEXT                                     AS selg,
                              NULL::TEXT                                     AS muud,
                              2                                              AS opt,
                              NULL::VARCHAR(20)                              AS regkood,
                              NULL::VARCHAR(254)                             AS asutus,
                              NULL::INTEGER                                  AS arvid,
                              NULL::VARCHAR(20)                              AS arvnr,
                              0::NUMERIC(12, 2)                              AS summa,
                              NULL::VARCHAR(120)                             AS dokprop,
                              NULL::VARCHAR(20)                              AS konto,
                              0                                              AS doklausid,
                              NULL::INTEGER                                  AS lapsId
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
                         k1.*,
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
        }

    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px", show: false},
            {id: "kpv", name: "Kuupäev", width: "100px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "asutus", name: "Maksja", width: "200px"},
            {id: "deebet", name: "Summa", width: "100px"},
            {id: "asutusid", name: "asutusid", width: "200px", show: false},
            {id: "nomid", name: "nomid", width: "200px", show: false},
            {id: "aa", name: "Arveldus arve", width: "100px"},
            {id: "viitenr", name: "Viite number", width: "100px"},
            {id: "maksepaev", name: "Maksepäev", width: "100px"},
            {id: "nimi", name: "Nimi", width: "100px"},
            {id: "isikukood", name: "Isikukood", width: "100px"},

        ],
        sqlString: `SELECT mk.id,
                           to_char(mk.kpv, 'DD.MM.YYYY')::TEXT AS kpv,
                           mk.selg,
                           mk.asutus,
                           mk.kood,
                           mk.rekvid,
                           mk.deebet,
                           mk.kreedit,
                           mk.number,
                           mk.journalid,
                           mk.aa,
                           mk.journalnr,
                           mk.opt,
                           mk.vanem_isikukood,
                           0                                   AS valitud,
                           mk.isikukood,
                           mk.nimi,
                           $2                                  AS userid,
                           mk.viitenr::text  
                    FROM lapsed.cur_lapsed_mk mk
                    WHERE mk.rekvId = $1`,
//                      AND coalesce(docs.usersRigths(mk.id, 'select', $2::INTEGER), TRUE)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curLasteMk'
    },

    returnData: {
        row: {},
        details: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'nimetus', name: 'Nimetus', width: '100px', show: true, type: 'text', readOnly: false},
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
                  FROM docs.gen_lausend_smk($2::INTEGER, $1::INTEGER)`, // $1 - userId, $2 - docId
        type: "sql",
        alias: 'generateJournal'
    },
    print: [
        {
            view: 'smk_kaart',
            params: 'id'
        },
        {
            view: 'smk_register',
            params: 'sqlWhere'
        },
    ]

};

module.exports = Smk;

