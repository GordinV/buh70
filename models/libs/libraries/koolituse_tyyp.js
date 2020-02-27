module.exports = {
    selectAsLibs: `SELECT *
                   FROM (
                            SELECT 0 AS id, ''::VARCHAR(20) AS kood, ''::VARCHAR(254) AS nimetus
                            UNION
                            SELECT id, kood::TEXT AS kood, nimetus::TEXT AS name
                            FROM libs.library l
                            WHERE library::TEXT = 'KOOLITUSE_TYYP'
                              AND l.rekvid::INTEGER = $1::INTEGER
                              AND l.status <> 3
                        ) qry
                   ORDER BY kood`,
    select: [{
        sql: `SELECT l.id,
                     l.kood::VARCHAR(20)     AS kood,
                     l.nimetus::VARCHAR(254) AS nimetus,
                     l.library::VARCHAR(20),
                     l.muud,
                     $2::INTEGER             AS userid,
                     'KOOLITUSE_TYYP'        AS doc_type_id
              FROM libs.library l
              WHERE l.library = 'KOOLITUSE_TYYP'
                AND l.id = $1`,
        sqlAsNew: `select  
                    $1::integer as id , 
                    $2::integer as userid, 
                    'KOOLITUSE_TYYP' as doc_type_id,
                    null::TEXT as  kood,
                    null::integer as rekvid,
                    null::TEXT as nimetus,
                    'KOOLITUSE_TYYP'::varchar(20) as library,
                    null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    returnData: {
        row: {},
        details: [],
        gridConfig: []
    },
    requiredFields: [
        {name: 'kood', type: 'C'},
        {name: 'nimetus', type: 'C'},
        {name: 'library', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_library($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_library($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"}
        ],
        sqlString: `SELECT l.*, $1::INTEGER AS rekv_id, $2::INTEGER AS userId
                    FROM libs.library l
                    WHERE l.library::TEXT = 'KOOLITUSE_TYYP'
                      AND l.rekvid = $1
                      AND l.status <> 3`,
        params: '',
        alias: 'curLiik'
    },
    print: [
        {
            view: 'koolituse_tyyp',
            params: 'id'
        },
        {
            view: 'koolituse_tyyp',
            params: 'sqlWhere'
        },
    ]

};
