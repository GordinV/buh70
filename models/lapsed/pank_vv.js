module.exports = {
    selectAsLibs: ``,
    libGridConfig: {
        grid: [
            {id: "id", name: "id", width: "50px", show: false},
        ]
    },
    select: [{
        sql: `SELECT id, $2 AS userid
              FROM lapsed.pank_vv pank_vv
              WHERE pank_vv.id = $1::INTEGER`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    returnData: {
        row: {}
    },


    requiredFields: [],
    saveDoc: `select result as id, result, stamp, error_message from lapsed.sp_salvesta_pank_vv($1::jsonb, $2::integer, $3::integer)`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: ``, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kasutaja", name: "Kasutaja", width: "30%"},
            {id: "kpv", name: "Kuupäev", width: "40%"}
        ],
        sqlString: `SELECT id,
                           to_char(TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                           userid.ametnik AS kasutaja,
                           $1::INTEGER    AS rekvid,
                           $2::INTEGER    AS user_id
                    FROM lapsed.pank_vv v
                             INNER JOIN ou.userid u ON u.id = v.userid`,     //  $1 всегда ид учреждения, $2 - userId
        params: '',
        alias: 'curPankVV'
    },
    koostaMK: {
        command: `SELECT result, error_message
                  FROM lapsed.read_pank_vv($2::integer, $1::text)`, //$1 - docs.doc.id, $2 - userId
        type: "sql",
        alias: 'koostaMK'
    },


};

