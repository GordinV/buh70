module.exports = {
    select: [{
        sql: `SELECT n.kood,
                     n.id,
                     n.nimetus,
                     n.dok::VARCHAR(20),
                     n.muud,
                     n.rekvid,
                     $2::INTEGER                                                              AS userid,
                     'NOMENCLATURE'                                                           AS doc_type_id,
                     'EUR'                                                                    AS valuuta,
                     1                                                                        AS kuurs,
                     n.uhik                                                                   AS uhik,
                     n.hind                                                                   AS hind,
                     (n.properties::JSONB ->> 'vat')::VARCHAR(20)                             AS vat,
                     (n.properties::JSONB ->> 'konto')::VARCHAR(20)                           AS konto,
                     (n.properties::JSONB ->> 'projekt')::VARCHAR(20)                         AS projekt,
                     (n.properties::JSONB ->> 'tunnus')::VARCHAR(20)                          AS tunnus,
                     (n.properties::JSONB ->> 'tegev')::VARCHAR(20)                           AS tegev,
                     (n.properties::JSONB ->> 'allikas')::VARCHAR(20)                         AS allikas,
                     (n.properties::JSONB ->> 'rahavoog')::VARCHAR(20)                        AS rahavoog,
                     (n.properties::JSONB ->> 'artikkel')::VARCHAR(20)                        AS artikkel,
                     (n.properties::JSONB ->> 'uritus')::VARCHAR(20)                          AS uritus,
                     coalesce((n.properties::JSONB ->> 'kas_inf3')::BOOLEAN, FALSE)           AS kas_inf3,
                     (n.properties::JSONB ->> 'valid')::DATE                                  AS valid,
                     (n.properties::JSONB ->> 'tyyp')::TEXT                                   AS tyyp,
                     coalesce((n.properties::JSONB ->> 'kas_inf3')::BOOLEAN, FALSE)           AS kas_inf3,
                     coalesce((n.properties::JSONB ->> 'kas_umberarvestus')::BOOLEAN, FALSE)  AS kas_umberarvestus,
                     coalesce((n.properties::JSONB ->> 'oppe_tyyp')::TEXT, 'Põhiõpe')::TEXT   AS oppe_tyyp,
                     coalesce((n.properties::JSONB ->> 'algoritm')::TEXT, 'konstantne')::TEXT AS algoritm

              FROM libs.nomenklatuur n
              WHERE n.id = $1`,
        sqlAsNew: `select  $1::integer as id , $2::integer as userid, 'NOMENCLATURE' as doc_type_id,
            ''::varchar(20) as  kood,
            0::integer as rekvid,
            ''::varchar(254) as nimetus,
            'ARV'::varchar(20) as dok,
            ''::varchar(20) as uhik,
            0::numeric as hind,
            0::numeric as ulehind,
            1::numeric as kogus,
            null::text as formula,
            0::integer as status,
            null::text as muud,
            null::text as properties,
            'EUR' as valuuta, 1 as kuurs,
            '20'::varchar(20) as vat,
            false as kas_inf3,
            false as kas_umberarvestus,
            null::varchar(20) as konto,
            null::varchar(20) as projekt,
            null::varchar(20) as tunnus,
            null::varchar(20) as tegev,
            null::varchar(20) as allikas,
            null::varchar(20) as rahavoog,
            null::varchar(20) as artikkel,
            null::varchar(20) as uritus,
            null::date as valid,
            'konstantne'::text as algoritm,                      
            null::text as tyyp`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT *
                  FROM jsonb_to_recordset(
                               fnc_check_libs($2::JSON, $3::DATE, $1::INTEGER))
                           AS x (error_message TEXT)
                  WHERE error_message IS NOT NULL
            `, //$1 rekvid, $2 tunnus, $3 kuupaev
            query: null,
            multiple: true,
            alias: 'validate_libs',
            data: []

        },
        {
            sql: `SELECT *
                  FROM jsonb_to_recordset(
                               get_nom_kasutus($2::INTEGER, $3::DATE,
                                               $1::INTEGER)
                           ) AS x (error_message TEXT, error_code INTEGER)
                  WHERE error_message IS NOT NULL
            `, //$1 rekvid, $2 v_nom.kood
            query: null,
            multiple: true,
            alias: 'validate_lib_usage',
            data: []

        }

    ],
    selectAsLibs: `SELECT *
                   FROM com_nomenclature
                   WHERE (rekvid = $1 OR rekvid IS NULL)
                   ORDER BY kood`,
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'kood', type: 'C'},
        {name: 'nimetus', type: 'C'},
        {name: 'dok', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_nomenclature($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_nomenclature($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "40%"},
            {id: "dok", name: "Dokument", width: "15%"},
            {id: "tyyp", name: "Tüüp", width: "10%"},
            {id: "liik", name: "Koolituse liik", width: "10%"},
        ],
        sqlString: `SELECT id,
                           coalesce(kood, '')::VARCHAR(20)      AS kood,
                           coalesce(nimetus, '')::VARCHAR(254)  AS nimetus,
                           $2::INTEGER                          AS userId,
                           n.dok,
                           (n.properties ->> 'konto')::TEXT     AS konto,
                           (n.properties ->> 'tunnus')::TEXT    AS tunnus,
                           n.hind,
                           (n.properties ->> 'tyyp')::TEXT      AS tyyp,
                           (n.properties ->> 'oppe_tyyp')::TEXT AS liik,
                           (n.properties ->> 'valid')::DATE     AS valid
                    FROM libs.nomenklatuur n
                    WHERE (n.rekvId = $1 OR n.rekvid IS NULL)
                      AND n.status <> 3`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curNomenklatuur'
    },
    print: [
        {
            view: 'noms_register',
            params: 'id'
        },
        {
            view: 'noms_register',
            params: 'sqlWhere'
        },
    ]

};
