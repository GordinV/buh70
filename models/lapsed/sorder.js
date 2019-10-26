'use strict';

let now = new Date();

const Sorder = {
    select: [
        {
            sql: `SELECT d.id,
                         d.docs_ids,
                         (to_char(created, 'DD.MM.YYYY HH:MM:SS')) :: TEXT              AS created,
                         (to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS')) :: TEXT           AS lastupdate,
                         d.bpm,
                         k.number::VARCHAR(20)                                          AS number,
                         k.summa,
                         k.kassaid                                                      AS kassa_id,
                         trim(aa.nimetus)                                               AS kassa,
                         k.rekvId,
                         to_char(k.kpv, 'YYYY-MM-DD')::TEXT                             AS kpv,
                         to_char(k.kpv, 'MM.DD.YYYY')::TEXT                             AS kpv_print,
                         k.asutusid,
                         trim(k.dokument)                                               AS dokument,
                         k.alus,
                         k.muud,
                         k.nimi,
                         k.aadress,
                         k.tyyp,
                         asutus.regkood,
                         trim(asutus.nimetus)                                           AS asutus,
                         k.arvid,
                         ('Number:' || arv.number :: TEXT || ' Kuupäev:' || to_char(arv.kpv, 'DD.MM.YYYY') :: TEXT ||
                          ' Jääk:' ||
                          arv.jaak :: TEXT)                                             AS arvnr,
                         k.doklausid,
                         k.journalid,
                         coalesce(jid.number, 0)::INTEGER                               AS lausnr,
                         coalesce((dp.details :: JSONB ->> 'konto'), '') :: VARCHAR(20) AS konto,
                         dp.selg::VARCHAR(120)                                          AS dokprop,
                         (SELECT sum(summa)
                          FROM docs.korder2 k2
                          WHERE parentid = k.id) :: NUMERIC(12, 2)                      AS kokku,
                         (d.history -> 0 ->> 'user')::VARCHAR(120)                      AS koostaja

                  FROM docs.doc d
                           INNER JOIN libs.library l ON l.id = d.doc_type_id
                           INNER JOIN docs.korder1 k ON k.parentId = d.id
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                           LEFT OUTER JOIN libs.asutus AS asutus ON asutus.id = k.asutusId
                           LEFT OUTER JOIN ou.aa AS aa ON k.kassaid = aa.Id
                           LEFT OUTER JOIN docs.arv AS arv ON k.arvid = arv.Id
                           LEFT OUTER JOIN docs.journal j ON j.parentid = k.journalid
                           LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
                           LEFT OUTER JOIN libs.dokprop dp ON dp.id = k.doklausid
                  WHERE d.id = $1`,
            sqlAsNew: `SELECT $1 :: INTEGER                                                     AS id,
                              $2 :: INTEGER                                                     AS userid,
                              (now() :: DATE || 'T' || now() :: TIME) :: TEXT                   AS created,
                              (now() :: DATE || 'T' || now() :: TIME) :: TEXT                   AS lastupdate,
                              docs.sp_get_number((SELECT rekvid FROM ou.userid WHERE id = $2)::INTEGER, 'SORDER'::TEXT,
                                                 year(now()::DATE), NULL::INTEGER)::VARCHAR(20) AS number,
                              0                                                                 AS summa,
                              aa.id                                                             AS kassa_id,
                              trim(aa.name)                                                     AS kassa,
                              NULL::INTEGER                                                     AS rekvId,
                              to_char(now()::DATE, 'YYYY-MM-DD')::TEXT                          AS kpv,
                              NULL::INTEGER                                                     AS asutusid,
                              NULL::VARCHAR(120)                                                AS dokument,
                              NULL::TEXT                                                        AS alus,
                              NULL::TEXT                                                        AS muud,
                              NULL::TEXT                                                        AS nimi,
                              NULL::TEXT                                                        AS aadress,
                              1                                                                 AS tyyp,
                              0::NUMERIC(12, 2)                                                 AS summa,
                              NULL::VARCHAR(20)                                                 AS regkood,
                              NULL::VARCHAR(254)                                                AS asutus,
                              NULL::INTEGER                                                     AS arvid,
                              NULL::INTEGER                                                     AS arvnr,
                              NULL::INTEGER                                                     AS doklausid,
                              0::INTEGER                                                        AS journalid,
                              NULL::INTEGER                                                     AS lausnr,
                              NULL::VARCHAR(120)                                                AS dokprop,
                              NULL::VARCHAR(20)                                                 AS konto,
                              0::NUMERIC                                                        AS kokku,
                              NULL::INTEGER                                                     AS lapsId

                       FROM (SELECT id,
                                    trim(nimetus) AS name
                             FROM ou.aa
                             WHERE kassa = 1
                             ORDER BY default_
                             LIMIT 1) AS aa,
                            ou.userid AS u
                       WHERE u.id = $2 :: INTEGER`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT k1.id,
                         $2 :: INTEGER                AS userid,
                         trim(n.kood)::VARCHAR(20)    AS kood,
                         trim(n.nimetus)::VARCHAR(20) AS nimetus,
                         trim(n.uhik)                 AS uhik,
                         k1.*,
                         'EUR'                        AS valuuta,
                         1::NUMERIC(12, 4)            AS kuurs
                  FROM docs.korder2 AS k1
                           INNER JOIN docs.korder1 k ON k.id = k1.parentId
                           INNER JOIN libs.nomenklatuur n ON n.id = k1.nomid
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                  WHERE k.parentid = $1`,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        },
        {
            sql: `SELECT rd.id,
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
            {id: "id", name: "id", width: "25px", show: false},
            {id: "kpv", name: "Kuupäev", width: "100px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "kassa", name: "Kassa", width: "200px"},
            {id: "asutus", name: "Maksja", width: "200px"},
            {id: "summa", name: "Summa", width: "100px"},
            {id: "nimi", name: "Lapse nimi", width: "150px"},
            {id: "isikukood", name: "Isikukood", width: "150px"},
            {id: "konto", name: "Korr.konto", width: "100px"}
        ],
        sqlString: `SELECT id,
                           to_char(kpv, 'DD.MM.YYYY') AS kpv,
                           number,
                           asutus,
                           dokument,
                           summa,
                           nimi,
                           isikukood,
                           konto,
                           kassa,
                           $2                         AS userid
                    FROM lapsed.cur_lapse_korder k
                    WHERE k.rekvId = $1`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
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
    saveDoc: `select docs.sp_salvesta_korder($1::json, $2::integer, $3::integer) as id`,
    deleteDoc: `SELECT error_code, result, error_message
                FROM docs.sp_delete_korder($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
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
    generateJournal: {
        command: `SELECT error_code, result, error_message
                  FROM docs.gen_lausend_sorder($2::INTEGER, $1::INTEGER)`, // $1 - userId, $2 - docId
        type: "sql",
        alias: 'generateJournal'
    },
    print: [
        {
            view: 'sorder_kaart',
            params: 'id'
        },
        {
            view: 'sorder_register',
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

};

module.exports = Sorder;
