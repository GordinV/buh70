module.exports = {
    selectAsLibs: `select * from cur_pohivara    l
        where  (l.rekvId = $1 or l.rekvid is null)`,
    select: [{
        sql: `SELECT
                  d.id,
                  $2 :: INTEGER                                                  AS userid,
                  to_char(created, 'DD.MM.YYYY HH:MM:SS') :: TEXT                AS created,
                  to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS') :: TEXT             AS lastupdate,
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
                  coalesce(v.valuuta, 'EUR')                                     AS valuuta,
                  coalesce(v.kuurs, 1) :: NUMERIC(12, 4)                         AS kuurs,
                  coalesce(jid.number, 0) :: INTEGER                             AS laus_nr,
                  coalesce((dp.details :: JSONB ->> 'konto'), '') :: VARCHAR(20) AS korrkonto,
                  dp.selg :: VARCHAR(120)                                        AS dokprop
                FROM docs.doc d
                  INNER JOIN libs.library l ON l.id = d.doc_type_id
                  INNER JOIN docs.pv_oper po ON po.parentId = d.id
                  INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                  INNER JOIN libs.nomenklatuur n ON n.id = po.nomid
                  LEFT OUTER JOIN libs.asutus AS asutus ON asutus.id = po.asutusId
                  LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                  LEFT OUTER JOIN libs.dokprop dp ON dp.id = po.doklausid
                  LEFT OUTER JOIN docs.journal j ON j.parentid = po.journalid
                  LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
                  LEFT OUTER JOIN docs.dokvaluuta1 v ON (v.dokid = po.id AND v.dokliik = array_position((enum_range(NULL :: DOK_VALUUTA)), 'pv_oper'))
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
    }],
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
        command: `SELECT result, selgitus, summa from docs.sp_calc_kulum(?tnId)`,
        type:'sql',
        alias:'arvestaKulum'
    },

    saveDoc: `select docs.sp_salvesta_pv_oper($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from docs.sp_delete_pv_oper($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "pv_grupp", name: "Grupp", width: "35%"},
        ],
        sqlString: `select * 
            from cur_pv_oper l
            where (l.rekvId = $1 or l.rekvid is null)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPVoper'
    },
    generateJournal: {
        command: "select error_code, result, error_message from docs.gen_lausend_pv_oper($2, $1)", //$1 - docs.doc.id, $2 - userId
        type: "sql",
        alias: 'generateJournal'
    },


};