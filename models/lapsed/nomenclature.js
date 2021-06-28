module.exports = {
    select: [{
        sql: `SELECT n.kood::TEXT,
                     n.id,
                     n.nimetus::TEXT                                                        AS nimetus,
                     n.dok::TEXT,
                     n.muud,
                     n.rekvid,
                     $2::INTEGER                                                            AS userid,
                     'NOMENCLATURE'                                                         AS doc_type_id,
                     'EUR'                                                                  AS valuuta,
                     1                                                                      AS kuurs,
                     n.uhik::TEXT                                                           AS uhik,
                     n.hind                                                                 AS hind,
                     (n.properties::JSONB ->> 'luno')::TEXT                                 AS luno,
                     (n.properties::JSONB ->> 'vat')::VARCHAR(20)                           AS vat,
                     (n.properties::JSONB ->> 'konto')::VARCHAR(20)                         AS konto,
                     (n.properties::JSONB ->> 'projekt')::VARCHAR(20)                       AS projekt,
                     (n.properties::JSONB ->> 'tunnus')::VARCHAR(20)                        AS tunnus,
                     (n.properties::JSONB ->> 'tegev')::VARCHAR(20)                         AS tegev,
                     (n.properties::JSONB ->> 'allikas')::VARCHAR(20)                       AS allikas,
                     (n.properties::JSONB ->> 'rahavoog')::VARCHAR(20)                      AS rahavoog,
                     (n.properties::JSONB ->> 'artikkel')::VARCHAR(20)                      AS artikkel,
                     coalesce((n.properties::JSONB ->> 'kas_inf3')::BOOLEAN, FALSE)         AS kas_inf3,
                     coalesce((n.properties::JSONB ->> 'oppe_tyyp')::TEXT, 'Põhiõpe')::TEXT AS oppe_tyyp,
                     (n.properties ->> 'tyyp')::TEXT                                        AS tyyp,
                     to_char((n.properties::JSONB ->> 'valid')::DATE,
                             'YYYY-MM-DD')                                                  AS VALID,
                     (n.properties::JSONB ->> 'tyyp')::TEXT                         AS tyyp,
                     (n.properties::JSONB ->> 'algoritm')::TEXT                         AS algoritm       
              FROM libs.nomenklatuur n
              WHERE n.id = $1`,
        sqlAsNew: `select  $1::integer as id , $2::integer as userid, 'NOMENCLATURE' as doc_type_id,
            ''::varchar(20) as  kood,
            0::integer as rekvid,
            ''::varchar(254) as nimetus,
            null::text as luno,
            ''::varchar(20) as dok,
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
            null::varchar(20) as konto,
            null::varchar(20) as projekt,
            null::varchar(20) as tunnus,
            null::varchar(20) as tegev,
            null::varchar(20) as allikas,
            null::varchar(20) as rahavoog,
            null::varchar(20) as artikkel,
            luhi_nimi::text as luhi_nimi,
            'Põhiõpe'::TEXT AS oppe_tyyp,
            null::text as tyyp,  
            'konstantne'::text as algoritm,          
            null::date as valid`,
        query: null,
        multiple: false,
        alias: 'row',
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
            data: [],
            not_initial_load: true
        }


    ],
    selectAsLibs: `SELECT id,
                          kood,
                          trim(nimetus) || ' (' || (hind::NUMERIC(12, 2))::TEXT || ') ' || uhik::TEXT AS nimetus,
                          dok,
                          hind,
                          vat,
                          kogus,
                          tyyp,
                          konto,
                          tegev,
                          allikas,
                          artikkel,
                          tunnus,
                          kas_inf3,
                          valid
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
            {id: "kood", name: "Kood", width: "20%"},
            {id: "nimetus", name: "Nimetus", width: "30%"},
            {id: "hind", name: "Hind", width: "20%", type: "number"},
            {id: "uhik", name: "Mõttühik", width: "10%"},
            {id: "dok", name: "Dokument", width: "10%"},
            {id: "tyyp", name: "Tüüp", width: "10%"},
            {id: "valid", name: "Kehtivus", width: "0%", type: 'date', show: false},
        ],
        sqlString: `SELECT id,
                           coalesce(kood, '')::VARCHAR(20)        AS kood,
                           coalesce(nimetus, '')::VARCHAR(254)    AS nimetus,
                           $2::INTEGER                            AS userId,
                           n.dok,
                           (n.properties ->> 'konto')::TEXT       AS konto,
                           (n.properties ->> 'tunnus')::TEXT      AS tunnus,
                           n.hind::NUMERIC(12, 2),
                           n.uhik,
                           (n.properties ->> 'tyyp')::TEXT     AS tyyp,
                           (n.properties::JSON ->> 'valid')::DATE AS valid
                    FROM libs.nomenklatuur n
                    WHERE (n.rekvId = $1 OR n.rekvid IS NULL)
                      AND n.status <> 3`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curNomenklatuur'
    },
    bpm: [
        {
            name: 'Uuendada hinnad',
            task: 'uuendaHinnad',
            type: 'manual',
            action: 'uuendaHinnad',
        }
    ],

    print: [
        {
            view: 'noms_register',
            params: 'id'
        },
        {
            view: 'noms_register',
            params: 'sqlWhere'
        },
    ],
    uuendaHinnad: {
        command: `SELECT error_code, result, error_message, doc_type_id
                  FROM lapsed.update_teenuste_hinnad($2::INTEGER, $1::INTEGER)`,//$1 docId, $2 - userId
        type: 'sql',
        alias: 'uuendaHinnad'
    },
    importNoms: {
        command: `SELECT error_code, result, error_message
                  FROM lapsed.import_noms($1::JSONB, $2::INTEGER, $3::INTEGER)`,//$1 data [], $2 - userId, $3 rekvid
        type: 'sql',
        alias: 'importNoms'
    },


};
