module.exports = {
    select: [{
        sql: `SELECT n.*,
                     $2::INTEGER                                   AS userid,
                     'VARA'                                         AS doc_type_id,
                     'EUR'::VARCHAR(20)                             AS valuuta,
                     1                                              AS kuurs,
                     n.uhik,
                     n.hind,
                     n.ulehind,
                     n.dok,
                     n.kogus,
                     (n.properties::JSONB ->> 'grupp')::VARCHAR(254)   AS grupp,
                     (n.properties::JSONB ->> 'vat')::VARCHAR(10)          AS vat,
                     (n.properties::JSONB ->> 'konto')::VARCHAR(20)        AS konto,
                     (n.properties::JSONB ->> 'projekt')::VARCHAR(20)      AS projekt,
                     (n.properties::JSONB ->> 'tunnus')::VARCHAR(20)       AS tunnus,
                     (n.properties::JSONB ->> 'tegev')::VARCHAR(20)        AS tegev,
                     (n.properties::JSONB ->> 'allikas')::VARCHAR(20)      AS allikas,
                     (n.properties::JSONB ->> 'artikkel')::VARCHAR(20)     AS artikkel,
                     (n.properties::JSONB ->> 'kalor')::VARCHAR(20)     AS kalor,
                     (n.properties::JSONB ->> 'valid')::DATE        AS valid,
                     (n.properties::JSONB ->> 'sahharid')::NUMERIC  AS sahharid,
                     (n.properties::JSONB ->> 'rasv')::NUMERIC      AS rasv,
                     (n.properties::JSONB ->> 'vailkaine')::NUMERIC AS vailkaine
              FROM libs.nomenklatuur n
              WHERE n.id = $1`,
        sqlAsNew: `select  $1::integer as id , $2::integer as userid, 'VARA' as doc_type_id,
           ''::VARCHAR(254) as  kood,
            0::integer as rekvid,
            ''::VARCHAR(254) as nimetus,
            'VARA'::text as dok,
            ''::VARCHAR(254) as uhik,
            0::numeric as hind,
            0::numeric as ulehind,
            0::numeric as kogus,
            null::text as formula,
            0::integer as status,
            null::text as muud,
            'EUR' as valuuta, 1 as kuurs,
            '20'::text as vat,
            ''::VARCHAR(254) as grupp,
            ''::VARCHAR(20) as konto,
            ''::VARCHAR(20) as projekt,
            ''::VARCHAR(20) as tunnus,
            ''::VARCHAR(20) as tegev,
            ''::VARCHAR(20) as allikas,
            ''::VARCHAR(20) as artikkel,
            0::numeric as kalor,
            null::date as valid,
            0::numeric as sahharid,
            0::numeric as rasv,
            0::numeric as vailkaine`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    selectAsLibs: `SELECT *
                   FROM com_varad
                   WHERE (rekvid = $1 OR rekvid IS NULL)
                     AND status <> 3
                   ORDER BY kood`,
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'kood', type: 'C'},
        {name: 'nimetus', type: 'C'},
        {name: 'grupp', type: 'I'},
        {name: 'dok', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_nomenclature($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_nomenclature($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "grupp", name: "Grupp", width: "30%"}
        ],
        sqlString: `SELECT n.id,
                           coalesce(n.kood, '')                            AS kood,
                           coalesce(n.nimetus, '')                         AS nimetus,
                           $2::INTEGER                                     AS userId,
                           (n.properties::JSONB ->> 'grupp')::VARCHAR(120) AS grupp,
                           n.hind,
                           n.uhik,
                           coalesce(v.kogus, 0)                            AS kogus,
                           coalesce(l.nimetus, '')::VARCHAR(254)           AS ladu
                    FROM libs.nomenklatuur n
                           LEFT OUTER JOIN (SELECT sum(kogus) AS kogus, vara_id, ladu_id, rekv_id
                                            FROM ladu.get_stock(current_date, NULL, NULL,
                                                                NULL)
                                            GROUP BY vara_id, ladu_id, rekv_id) v ON n.id = v.vara_id AND n.rekvid = v.rekv_id
                           LEFT OUTER JOIN libs.library l ON l.id = v.ladu_id
                    WHERE (n.rekvId = $1 OR n.rekvid IS NULL)
                      AND
                      n.dok = 'VARA'
                      AND n.status <> 3`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curVara'
    },

};
