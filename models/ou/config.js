module.exports = {
    select: [{
        sql: `SELECT
                'CONFIG'     AS doc_type_id,
                $2::INTEGER AS userid,
                c.id,
                c.rekvid,
                coalesce(c.number,'')::VARCHAR(20) as number,
                coalesce((u.properties->>'keel')::integer,2)::integer as keel,
                coalesce((u.properties->>'port')::varchar(100))::varchar(100) as port,
                coalesce((u.properties->>'smtp')::varchar(100))::varchar(100) as smtp,
                coalesce((u.properties->>'user')::varchar(100))::varchar(100) as user,
                coalesce((u.properties->>'pass')::varchar(100))::varchar(100) as pass,
                coalesce((u.properties->>'email')::varchar(254))::varchar(254) as email,
                coalesce((c.properties->>'earved')::varchar(254))::varchar(254) as earved,
                c.tahtpaev
              FROM ou.config c, ou.userid u
              WHERE c.rekvid = $1 and u.id = $2`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER         AS id,
                      $2 :: INTEGER         AS userid,
                      'CONFIG'              AS doc_type_id,
                      0 :: INTEGER          AS rekvid,
                      '' :: VARCHAR(20)   AS number,
                      1 :: integer          AS keel,
                      ''::varchar(254) as port,
                      ''::varchar(254) as smtp,
                      ''::varchar(254) as user,
                      ''::varchar(254) as pass,
                      ''::varchar(254) as email,
                      ''::varchar(254) as earved,
                      5::integer as tahtpaev`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    returnData: {
        row: {},
        details: []
    },
    requiredFields: [],
    saveDoc: `select ou.sp_salvesta_config($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: null, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "regkood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"}
        ],
        sqlString: `SELECT
                      $2 AS user_id,
                      c.*
                    FROM ou.config c
                          where c.rekvid IN (SELECT rekv_id
                                       FROM get_asutuse_struktuur($1::integer))`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curConfig'
    },

};
