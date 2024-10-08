module.exports = {
    selectAsLibs: `SELECT *
                   FROM cur_pohivara l
                   WHERE (l.rekvId = $1 OR l.rekvid IS NULL)`,
    select: [{
        sql: `SELECT d.id,
                     $2 :: INTEGER                                                  AS userid,
                     to_char(created, 'DD.MM.YYYY HH:MI:SS') :: TEXT                AS created,
                     to_char(lastupdate, 'DD.MM.YYYY HH:MI:SS') :: TEXT             AS lastupdate,
                     d.bpm,
                     trim(l.nimetus)                                                AS doc,
                     trim(l.kood)                                                   AS doc_type_id,
                     trim(s.nimetus)                                                AS status,
                     d.status                                                       AS doc_status,
                     asutus.regkood,
                     trim(asutus.nimetus) :: VARCHAR(254)                           AS asutus,
                     po.doklausid,
                     po.pv_kaart_id,
                     po.nomid,
                     po.liik,
                     po.kpv,
                     po.summa,
                     po.kood1,
                     po.kood2,
                     po.kood3,
                     po.kood4,
                     po.kood5,
                     po.konto,
                     po.tp,
                     po.asutusid,
                     po.tunnus,
                     po.proj,
                     po.journalid,
                     po.muud,
                     n.kood,
                     n.nimetus,
                     coalesce(jid.number, 0) :: INTEGER                             AS laus_nr,
                     coalesce((dp.details :: JSONB ->> 'konto'), '') :: VARCHAR(20) AS korrkonto,
                     dp.selg :: VARCHAR(120)                                        AS dokprop
              FROM docs.doc d
                       INNER JOIN libs.library l ON l.id = d.doc_type_id
                       INNER JOIN docs.pv_oper po ON po.parentId = d.id
                       INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                       LEFT OUTER JOIN libs.nomenklatuur n ON n.id = po.nomid
                       LEFT OUTER JOIN libs.asutus AS asutus ON asutus.id = po.asutusId
                       LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                       LEFT OUTER JOIN libs.dokprop dp ON dp.id = po.doklausid
                       LEFT OUTER JOIN docs.journal j ON j.parentid = po.journalid
                       LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
              WHERE d.id = $1`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid,
                  'POHIVARA'           AS doc_type_id,
                  NULL :: TEXT         AS kood,
                  NULL :: INTEGER      AS rekvid,
                  NULL :: TEXT         AS nimetus,
                  'POHIVARA' :: TEXT   AS library,
                  0 :: INTEGER         AS status,
                  NULL :: VARCHAR(20)  AS doc_status,
                  NULL :: VARCHAR(20)  AS regkood,
                  NULL :: VARCHAR(254) AS asutus,
                  NULL :: INTEGER      AS doklausid,
                  NULL :: INTEGER      AS pv_kaart_id,
                  NULL :: INTEGER      AS nomid,
                  NULL :: INTEGER      AS liik,
                  now() :: DATE        AS kpv,
                  0 :: NUMERIC(12, 2)  AS summa,
                  NULL :: VARCHAR(20)  AS kood1,
                  NULL :: VARCHAR(20)  AS kood2,
                  NULL :: VARCHAR(20)  AS kood3,
                  NULL :: VARCHAR(20)  AS kood4,
                  NULL :: VARCHAR(20)  AS kood5,
                  NULL :: VARCHAR(20)  AS konto,
                  NULL :: VARCHAR(20)  AS tp,
                  NULL :: INTEGER      AS asutusid,
                  NULL :: VARCHAR(20)  AS tunnus,
                  NULL :: VARCHAR(20)  AS proj,
                  NULL :: INTEGER      AS journalid,
                  NULL::text            as muud,
                  NULL :: VARCHAR(20)  AS kood,
                  NULL :: VARCHAR(254) AS nimetus,
                  'EUR' :: VARCHAR(20) AS valuuta,
                  1 :: NUMERIC(12, 4)  AS kuurs,
                  NULL :: INTEGER      AS laus_nr,
                  '' :: VARCHAR(20)    AS korrkonto,
                  NULL :: VARCHAR(120) AS dokprop`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: ` SELECT *
                   FROM docs.sp_pv_kulum_umber_arvestamine($1::INTEGER, $2::INTEGER)`, // $1 - pvOperId, $2 - userId
            query: null,
            multiple: false,
            alias: 'kulum_umber_arvestamine',
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
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'pv_kaart_id', type: 'I'},
        {name: 'nomid', type: 'I'},
        {name: 'pv_kaart_id', type: 'I'},
        {name: 'kpv', type: 'D'},
        {name: 'summa', type: 'N'}
    ],
    executeCommand: {
        command: `SELECT result, selgitus, summa
                  FROM docs.sp_calc_kulum(?tnId::INTEGER, current_date::DATE)`,
        type: 'sql',
        alias: 'arvestaKulum'
    },

    saveDoc: `select docs.sp_salvesta_pv_oper($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM docs.sp_delete_pv_oper($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "pv_grupp", name: "Grupp", width: "35%"},
        ],
        sqlString: `SELECT *
                    FROM cur_pv_oper l
                    WHERE (l.rekvId = $1 OR l.rekvid IS NULL)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPVoper'
    },
    generateJournal: {
        command: "SELECT error_code, result, error_message FROM docs.gen_lausend_pv_oper($2::INTEGER, $1::INTEGER)", //$1 - docs.doc.id, $2 - userId
        type: "sql",
        alias: 'generateJournal'
    },
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                                                        AS id,
                         (ajalugu ->> 'user')::VARCHAR(20)                                                           AS kasutaja,
                         coalesce(to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS koostatud,
                         coalesce(to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS muudatud,
                         coalesce(to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS prinditud,
                         coalesce(to_char((ajalugu ->> 'email')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'), '')::VARCHAR(20) AS
                                                                                                                        email,
                         coalesce(to_char((ajalugu ->> 'earve')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS earve,
                         coalesce(to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS kustutatud
                  FROM (
                           SELECT jsonb_array_elements(history) AS ajalugu, d.id, d.rekvid
                           FROM docs.doc d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry
                  WHERE (qry.ajalugu ->> 'user') IS NOT NULL`,
        type: "sql",
        alias: "getLogs"
    },


};
