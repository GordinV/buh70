module.exports = {
    selectAsLibs: `select id, nimetus::varchar(254), regkood::varchar(20), parentid from com_rekv`,
    select: [{
        sql: `SELECT
                'REKV' as doc_type_id,
                 $2::integer as userid,
                  r.id,
                  r.parentid,
                  r.nimetus,
                  r.aadress,
                  r.email,
                  r.faks,
                  r.haldus,
                  r.juht,
                  r.raama,
                  r.kbmkood,
                  r.muud,
                  r.regkood,
                  r.tel,
                  ((r.properties->>'arved')::jsonb->>'tahtpaev')::integer as tahtpaev,
                  ((r.properties->>'reklftp')::jsonb->>'ftp')::varchar(120) as ftp,
                  ((r.properties->>'reklftp')::jsonb->>'login')::varchar(120) as login,
                  ((r.properties->>'reklftp')::jsonb->>'parool')::varchar(120) as parool                  
                FROM ou.rekv r 
                where id = $1`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER        AS id,
                      $2 :: INTEGER        AS userid,
                      'REKV'               AS doc_type_id,
                      NULL :: INTEGER      AS parentid,
                      NULL :: VARCHAR(20)  AS regkood,
                      NULL :: VARCHAR(254) AS nimetus,
                      NULL :: VARCHAR(20)  AS kbmkood,
                      NULL :: TEXT         AS aadress,
                      NULL :: TEXT         AS haldus,
                      NULL :: VARCHAR(254) AS tel,
                      NULL :: VARCHAR(254) AS faks,
                      NULL :: VARCHAR(254) AS email,
                      NULL :: VARCHAR(254) AS juht,
                      NULL :: VARCHAR(254) AS raama,
                      NULL :: TEXT         AS muud,
                      null::integer as tahtpaev,
                     NULL :: VARCHAR(120) AS ftp,
                     NULL :: VARCHAR(120) AS login,
                     NULL :: VARCHAR(120) AS parool`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
        sql: `SELECT aa.* , 
                kassa as kassapank 
                FROM ou.Aa aa
                WHERE Aa.parentid = $1`,
        query: null,
        multiple: false,
        alias: 'details',
        data: []
    },
        {
            sql: `SELECT * 
                FROM ou.config 
                WHERE rekvid = $1`,
            query: null,
            multiple: false,
            alias: 'config',
            data: []
        },

    ],
    returnData: {
        row: {},
        details:[]
    },
    requiredFields: [
        {name: 'regkood', type: 'C'},
        {name: 'nimetus', type: 'C'}
    ],
    saveDoc: `select ou.sp_salvesta_rekv($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from ou.sp_delete_rekv($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "regkood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"}
        ],
        sqlString: `SELECT
                      $2 AS user_id,
                      r.*
                    FROM cur_rekv r
                    WHERE r.status <> 3
                          AND r.id IN (SELECT rekv_id
                                       FROM get_asutuse_struktuur($1))`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curRekv'
    },

};
