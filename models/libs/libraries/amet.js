module.exports = {
    selectAsLibs: `SELECT *
                   FROM com_ametid l
                   WHERE l.rekvId = $1`,
    select: [{
        sql: `SELECT l.id,
                     l.rekvid,
                     l.kood::VARCHAR(20)                                  AS kood,
                     l.nimetus::VARCHAR(254)                              AS nimetus,
                     l.muud,
                     l.status,
                     l.library::VARCHAR(20)                               AS library,
                     $2::INTEGER                                          AS userid,
                     'AMET'                                               AS doc_type_id,
                     (l.properties:: JSONB ->> 'osakondid') :: INTEGER    AS osakondId,
                     (l.properties:: JSONB ->> 'kogus') :: NUMERIC(18, 2) AS kogus,
                     (l.properties:: JSONB ->> 'palgamaar') ::INTEGER     AS palgamaar,
                     (l.properties:: JSONB ->> 'tunnusid') ::INTEGER      AS tunnusId,
                     (l.properties::JSONB ->> 'valid')::DATE              AS valid
              FROM libs.library l
              WHERE l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            $2::integer as userid, 
            'AMET' as doc_type_id,
            null::varchar(20) as  kood,
            0::integer as rekvid,
            null::varchar(254) as nimetus,
            'AMET'::varchar(20) as library,
            0::integer as status,
            null::integer as osakondId,
            null::numeric(18,2) as kogus,
            null::integer as palgamaar,
            null::integer as tunnusId,
            null::date as valid,
            null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT tmpl.id,
                         tmpl.parentid,
                         tmpl.libid,
                         tmpl.summa,
                         tmpl.percent_,
                         tmpl.tulumaks,
                         tmpl.tulumaar,
                         tmpl.tunnus,
                         tmpl.amet,
                         tmpl.kood :: VARCHAR(20),
                         tmpl.nimetus :: VARCHAR(254),
                         tmpl.liik,
                         tmpl.tund,
                         tmpl.maks,
                         tmpl.asutusest,
                         tmpl.tululiik,
                         tmpl.liik_ :: VARCHAR(20),
                         tmpl.tund_ :: VARCHAR(20),
                         tmpl.maks_ :: VARCHAR(20),
                         $2::INTEGER AS userid
                  FROM palk.cur_palk_tmpl tmpl
                  WHERE parentid = $1`,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        },
        {
            sql: `SELECT *
                  FROM jsonb_to_recordset(
                               fnc_check_libs($2::JSON, $3::date, $1::INTEGER))
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
                               get_amet_kasutus($2::INTEGER, $3::DATE,
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
    returnData: {
        row: {},
        details: []
    },
    requiredFields: [
        {name: 'kood', type: 'C'},
        {name: 'nimetus', type: 'C'},
        {name: 'osakondid', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_amet($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_library($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "osakond", name: "Osakond", width: "30%"},
            {id: "amet", name: "Amet", width: "30%"},
            {id: "kogus", name: "Kogus", width: "20%"},
            {id: "palgamaar", name: "Palgamaar", width: "20%"},
        ],
        sqlString: `SELECT *
                    FROM cur_ametid a
                    WHERE (a.rekvId = $1 OR a.rekvid IS NULL)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curAmetid'
    },

};
