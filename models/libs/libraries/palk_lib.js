module.exports = {
    selectAsLibs: `SELECT *
                   FROM palk.com_palk_lib l
                   WHERE l.rekvId = $1`,
    select: [{
        sql: `SELECT l.id,
                     l.rekvid,
                     l.kood,
                     l.nimetus,
                     l.status,
                     l.library,
                     l.tun1,
                     l.tun5,
                     $2::INTEGER                                          AS userid,
                     'PALK_LIB'                                           AS doc_type_id,
                     (l.properties::JSONB ->> 'liik') :: INTEGER          AS liik,
                     (l.properties::JSONB ->> 'tund') :: INTEGER          AS tund,
                     (l.properties::JSONB ->> 'maks') :: INTEGER          AS maks,
                     (l.properties::JSONB ->> 'asutusest') :: INTEGER     AS asutusest,
                     (l.properties::JSONB ->> 'palgafond') :: INTEGER     AS palgafond,
                     (l.properties::JSONB ->> 'sots') :: INTEGER          AS sots,
                     (l.properties::JSONB ->> 'round') :: NUMERIC(12, 4)  AS round,
                     (l.properties::JSONB ->> 'konto') :: VARCHAR(20)     AS konto,
                     (l.properties::JSONB ->> 'korrkonto') :: VARCHAR(20) AS korrkonto,
                     (l.properties::JSONB ->> 'tunnusid') :: INTEGER      AS tunnusId,
                     (l.properties::JSONB ->> 'elatis') :: INTEGER        AS elatis,
                     (l.properties::JSONB ->> 'uuritus') :: VARCHAR(20)   AS uuritus,
                     (l.properties::JSONB ->> 'proj') :: VARCHAR(20)      AS proj,
                     (l.properties::JSONB ->> 'tegev') :: VARCHAR(20)     AS tegev,
                     (l.properties::JSONB ->> 'allikas') :: VARCHAR(20)   AS allikas,
                     (l.properties::JSONB ->> 'artikkel') :: VARCHAR(20)  AS artikkel,
                     (l.properties::JSONB ->> 'tululiik') :: VARCHAR(20)  AS tululiik,
                     (l.properties::JSONB ->> 'valid')::DATE              AS valid,
                     l.muud
              FROM libs.library l
              WHERE l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            null::integer as tun1, null::integer as tun5,
            $2::integer as userid, 
            'PALK_LIB' as doc_type_id,
            null::text as  kood,
            null::integer as rekvid,
            null::text as nimetus,
            'PALK'::text as library,
            0::integer as status,
            null::integer as liik,
            null::integer as tund,
            null::integer as maks,
            null::integer as asutusest,
            null::integer as palgafond,
            null::integer as sots,
            null::numeric(12,4) as round,
            NULL::varchar(20) as konto,
            NULL::varchar(20) as korrkonto,
            null::integer as tunnusId,
            null::integer as elatis,
            null::varchar(20) as uuritus,
            null::varchar(20) as proj,
            null::varchar(20) as tegev,
            null::varchar(20) as allikas,
            null::varchar(20) as artikkel,
            null::varchar(20) as tululiik,
            null::date as valid,
            null::text as muud`,
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
                               get_palk_lib_kasutus($1::INTEGER, $2::DATE)
                           ) AS x (error_message TEXT, error_code INTEGER)
                  WHERE error_message IS NOT NULL
            `, //$1 rekvid, $2 v_nom.kood
            query: null,
            multiple: true,
            alias: 'validate_lib_usage',
            data: []

        }

    ],
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'kood', type: 'C'},
        {name: 'nimetus', type: 'C'},
        {name: 'library', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_palk_lib($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_library($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "tululiik", name: "Maksukood", width: "25%"}
        ],
        sqlString: `SELECT l.id,
                           l.kood,
                           l.nimetus,
                           l.tun5                                                          AS kehtiv,
                           coalesce((l.properties::JSONB ->> 'tululiik'), '')::VARCHAR(20) AS tululiik,
                           coalesce((l.properties::JSONB ->> 'liik')::INTEGER, 1)          AS liik,
                           $2::INTEGER                                                     AS userId,
                           l.tun5                                                          AS is_arhiiv,
                           (l.properties::JSONB ->> 'valid')::DATE                         AS valid
                    FROM libs.library l
                    WHERE l.library = 'PALK'
                      AND l.status <> 3
                      AND (l.rekvId = $1 OR l.rekvid IS NULL)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPalklib'
    },

};
