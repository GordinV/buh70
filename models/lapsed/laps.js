module.exports = {
    selectAsLibs: `SELECT l.*,
                          exists(
                                  SELECT id
                                  FROM lapsed.lapse_kaart lk
                                  WHERE lk.rekvid = $1
                                    AND lk.parentid = l.id
                              ) AS is_exists
                   FROM lapsed.laps l
                   ORDER BY nimi`,
    libGridConfig: {
        grid: [
            {id: "id", name: "id", width: "50px", show: false},
            {id: "isikukood", name: "Isikukood", width: "100px"},
            {id: "nimi", name: "Nimi", width: "100px"}
        ]
    },

    select: [{
        sql: `SELECT l.id,
                     l.isikukood,
                     l.nimi,
                     l.properties ->> 'viitenumber' AS viitenumber,
                     l.muud,
                     $2::INTEGER                    AS userid,
                     coalesce(ll.jaak, 0)::NUMERIC  AS jaak
              FROM lapsed.laps l
                       LEFT OUTER JOIN lapsed.lapse_saldod() ll ON ll.laps_id = l.id AND
                                                                   ll.rekv_id IN (SELECT rekvid FROM ou.userid u WHERE u.id = $2)
              WHERE l.id = $1::INTEGER`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid,
                  0::integer as vanemid,
                  null::text as isikukood,
                  null::text as nimi,
                  null::text as viitenumber,
                  null::text as muud,
                  0::numeric(14,2) as jaak`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT v.id,
                         v.parentid,
                         v.asutusid,
                         a.nimetus,
                         a.tel,
                         a.email,
                         v.properties ->> 'arved'     AS arved,
                         v.properties ->> 'suhtumine' AS suhtumine,
                         $2                           AS userid
                  FROM lapsed.vanemad v
                           INNER JOIN libs.asutus a ON a.id = v.asutusid
                  WHERE v.parentid = $1
                    AND v.staatus < 3`,
            query: null,
            multiple: true,
            alias: 'vanemad',
            data: []
        },
        {
            sql: `SELECT k.id,
                         k.parentid,
                         k.nomid,
                         n.kood,
                         n.nimetus,
                         k.hind,
                         k.properties ->> 'yksus' AS yksus
                  FROM lapsed.lapse_kaart k
                           INNER JOIN libs.nomenklatuur n ON n.id = k.nomid
                  WHERE k.parentid = $1
                    AND k.staatus <> 3
                    AND k.rekvid IN (SELECT rekvid FROM ou.userid WHERE id = $2)`,
            query: null,
            multiple: true,
            alias: 'teenused',
            data: []
        }

    ],
    returnData:
        {
            row: {}
            ,
            details: [],
            teenused:
                [],
            vanemad:
                [],
            gridConfig:
                [
                    {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
                    {id: 'parentid', name: 'parentid', width: '0px', show: false, type: 'text', readOnly: true},
                    {id: 'asutusid', name: 'asutusid', width: '0px', show: false, type: 'text', readOnly: true},
                    {id: 'nimetus', name: 'Nimetus', width: '100px', show: true, type: 'text', readOnly: false},
                    {id: 'tel', name: 'Tel. nr', width: '100px', show: true, type: 'text', readOnly: false},
                    {id: 'email', name: 'E-mail', width: '100px', show: true, type: 'text', readOnly: false},
                ],
            gridTeenusteConfig:
                [
                    {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
                    {id: 'kood', name: 'Kood', width: '100px', show: true, type: 'text', readOnly: false},
                    {id: 'nimetus', name: 'Nimetus', width: '100px', show: true, type: 'text', readOnly: false},
                    {id: 'hind', name: 'Hind', width: '100px', show: true, type: 'text', readOnly: false},
                    {id: 'yksus', name: 'Üksus', width: '100px', show: true, type: 'text', readOnly: false}
                ]
        }
    ,


    requiredFields: [
        {name: 'isikukood', type: 'C'},
        {name: 'nimi', type: 'T'}
    ],
    /*
    executeCommand: {
        command: `SELECT result, selgitus, summa
                  FROM docs.sp_calc_kulum(?tnId::INTEGER, current_date::DATE)`,
        type: 'sql',
        alias: 'arvestaKulum'
    },
*/
    saveDoc:
        `select lapsed.sp_salvesta_laps($1::jsonb, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc:
            `SELECT error_code, result, error_message
             FROM lapsed.sp_delete_laps($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid:
        {
            gridConfiguration: [
                {id: "id", name: "id", width: "10%", show: false},
                {id: "isikukood", name: "Isikukood", width: "30%"},
                {id: "nimi", name: "Nimi", width: "40%"},
                {id: "yksused", name: "Üksused", width: "30%"}
            ],
            sqlString:
                    `SELECT id,
                            isikukood,
                            nimi,
                            yksused,
                            $1::INTEGER AS rekvid,
                            $2::INTEGER AS user_id
                     FROM lapsed.cur_lapsed l
                     WHERE rekv_ids @> ARRAY [$1::INTEGER]::INTEGER[]
            `,     //  $1 всегда ид учреждения, $2 - userId
            params:
                '',
            alias:
                'curLapsed'
        },
    koostaArve: {
        command: `SELECT error_code, result, error_message, doc_type_id 
                  FROM lapsed.koosta_arve_taabeli_alusel($1::integer, $2::integer)`,
        type: 'sql',
        alias: 'koostaArve'
    },


}
;

