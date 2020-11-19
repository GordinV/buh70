
const doc = [
    {
    sql: `SELECT l.id,
                 l.kood::VARCHAR(20)                     AS kood,
                 l.nimetus::VARCHAR(254)                 AS nimetus,
                 l.library::VARCHAR(20),
                 l.muud,
                 $2::INTEGER                             AS userid,
                 l.rekvid                                AS rekvid,
                 'TUNNUS'                                AS doc_type_id,
                 (l.properties::JSONB ->> 'valid')::DATE AS valid
          FROM libs.library l
          WHERE l.library = 'TUNNUS'
            AND l.id = $1`,
    sqlAsNew: `select  
                    $1::integer as id , 
                    $2::integer as userid, 
                    'TUNNUS' as doc_type_id,
                    ''::varchar(20) as  kood,
                    0::integer as rekvid,
                    ''::varchar(254) as nimetus,
                    'TUNNUS'::varchar(20) as library,
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
                           get_tunnus_kasutus($2::INTEGER, $3::DATE)
                       ) AS x (error_message TEXT, error_code INTEGER)
              WHERE error_message IS NOT NULL
        `, //$1 rekvid, $2 v_nom.kood
        query: null,
        multiple: true,
        alias: 'validate_lib_usage',
        data: [],
        not_initial_load: true
    }
];

let result = doc.find(row => {
    console.log('row', row);
    if (row.alias && row.alias == 'validate_lib_usage') {
        return row;
    }
});

console.log('result', result);