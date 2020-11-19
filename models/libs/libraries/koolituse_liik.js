module.exports = {
    selectAsLibs: `SELECT *
                   FROM (
                            SELECT 0                AS id,
                                   ''::VARCHAR(20)  AS kood,
                                   ''::VARCHAR(254) AS nimetus,
                                   $1               AS rekv_id,
                                   NULL::DATE       AS VALID

                            UNION
                            SELECT id,
                                   kood::TEXT                             AS kood,
                                   nimetus::TEXT                          AS name,
                                   $1                                     AS rekv_id,
                                   (l.properties::JSON ->> 'valid')::DATE AS valid
                            FROM libs.library l
                            WHERE library::TEXT = 'KOOLITUSE_LIIK'
                              AND l.status <> 3
                        ) qry
                   ORDER BY kood`,
    select: [{
        sql: `SELECT l.id,
                     l.kood::VARCHAR(20)                     AS kood,
                     l.nimetus::VARCHAR(254)                 AS nimetus,
                     l.library::VARCHAR(20),
                     l.muud,
                     $2::INTEGER                             AS userid,
                     'KOOLITUSE_LIIK'                        AS doc_type_id,
                     (l.properties::JSONB ->> 'valid')::DATE AS valid
              FROM libs.library l
              WHERE l.library = 'KOOLITUSE_LIIK'
                AND l.id = $1`,
        sqlAsNew: `select  
                    $1::integer as id , 
                    $2::integer as userid, 
                    'KOOLITUSE_LIIK' as doc_type_id,
                    null::TEXT as  kood,
                    null::integer as rekvid,
                    null::TEXT as nimetus,
                    'KOOLITUSE_LIIK'::varchar(20) as library,
                    null::date as valid,                                        
                    null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: [],
        converter: function (data) {
//преобразует дату к формату yyyy-mm-dd
            data.map(row => {
                if (row.valid) {
                    console.log('valid', row.valid);
                    row.valid = row.valid.toISOString().slice(0, 10);
                }
                return row;
            });
            return data;
        }

    },
        {
            sql: `SELECT $1 AS rekv_id, *
                  FROM jsonb_to_recordset(
                               get_koolituse_liik_kasutus($2::INTEGER, $3::DATE)
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
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "valid", name: "Kehtivus", width: "10%", type: 'date', show: false},
        ],
        sqlString: `SELECT l.*,
                           $1::INTEGER                            AS rekv_id,
                           $2::INTEGER                            AS userId,
                           (l.properties::JSON ->> 'valid')::DATE AS valid
                    FROM libs.library l
                    WHERE l.library::TEXT = 'KOOLITUSE_LIIK'
                      AND l.status <> 3`,
        params: '',
        alias: 'curLiik'
    },
    print: [
        {
            view: 'koolituse_liik',
            params: 'id'
        },
        {
            view: 'koolituse_liik',
            params: 'sqlWhere'
        },
    ]

};
