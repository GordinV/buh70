module.exports = {
    selectAsLibs: `SELECT *
                   FROM (
                            SELECT 0 AS id, ''::VARCHAR(20) AS kood, ''::VARCHAR(254) AS nimetus, $1 AS rekv_id
                            UNION
                            SELECT id, kood::TEXT AS kood, nimetus::TEXT AS name, $1 AS rekv_id
                            FROM libs.library l
                            WHERE library::TEXT = 'ASUTUSE_LIIK'
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
                     'ASUTUSE_LIIK'          AS doc_type_id
              FROM libs.library l
              WHERE l.library = 'ASUTUSE_LIIK'
                AND l.id = $1`,
        sqlAsNew: `select  
                    $1::integer as id , 
                    $2::integer as userid, 
                    'ASUTUSE_LIIK' as doc_type_id,
                    null::TEXT as  kood,
                    null::integer as rekvid,
                    null::TEXT as nimetus,
                    'ASUTUSE_LIIK'::varchar(20) as library,
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
                    WHERE l.library::TEXT = 'ASUTUSE_LIIK'
                      AND l.status <> 3`,
        params: '',
        alias: 'curLiik'
    },
    print: [
        {
            view: 'asutuse_liik',
            params: 'id'
        },
        {
            view: 'asutuse_liik',
            params: 'sqlWhere'
        },
    ]

};
