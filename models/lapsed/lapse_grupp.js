module.exports = {
    selectAsLibs: `SELECT *
                   FROM (
                            SELECT 0           AS id,
                                   ''::TEXT    AS kood,
                                   ''::TEXT    AS nimetus,
                                   '[]'::JSONB AS all_yksused,
                                   '[]'::JSONB AS teenused
                            UNION
                            SELECT id,
                                   kood::TEXT,
                                   nimetus::TEXT,
                                   all_yksused::JSONB,
                                   teenused::JSONB
                            FROM lapsed.com_lapse_grupp lg
                            WHERE lg.rekvid = $1
                            ORDER BY kood
                        ) qry`,
    select: [{
        sql: `SELECT l.id,
                     l.rekvid,
                     l.muud,
                     l.kood,
                     l.nimetus,
                     ((l.properties::JSONB -> 'all_yksused') #>> '{0}')::TEXT       AS all_yksus_1,
                     ((l.properties::JSONB -> 'all_yksused') #>> '{1}')::TEXT       AS all_yksus_2,
                     ((l.properties::JSONB -> 'all_yksused') #>> '{2}')::TEXT       AS all_yksus_3,
                     ((l.properties::JSONB -> 'all_yksused') #>> '{3}')::TEXT       AS all_yksus_4,
                     ((l.properties::JSONB -> 'all_yksused') #>> '{4}')::TEXT       AS all_yksus_5,
                     $2                                                             AS userid,
                     rtrim(regexp_replace((properties::JSONB ->> 'all_yksused'), '[^a-zA-Z0-9,]', '', 'g'),
                           ',')                                                     AS all_yksused,
                     coalesce((l.properties::JSONB ->> 'liik')::INTEGER, 1)::INTEGER AS liik,
                     coalesce((l.properties::JSONB ->> 'tyyp')::INTEGER, 1)::INTEGER AS tyyp
              FROM libs.library l
              WHERE l.id = $1::INTEGER`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid,
                  null::text as all_yksus_1,
                  null::text as all_yksus_2,
                  null::text as all_yksus_3,
                  null::text as all_yksus_4,
                  null::text as all_yksus_5,
                  null::text as kood,
                  null::text as nimetus,
                  null::text as muud,
                  1 as liik,
                  1 as tyyp`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT x.*,
                         n.id AS id,
                         n.kood::TEXT,
                         n.nimetus::TEXT,
                         n.uhik::TEXT,
                         $2   AS userid
                  FROM jsonb_to_recordset((SELECT properties::JSONB -> 'teenused'
                                           FROM libs.library
                                           WHERE id = $1)) AS x(hind NUMERIC(12, 2), kogus NUMERIC(12, 2), nomid INTEGER)
                           INNER JOIN libs.nomenklatuur n ON n.id = x.nomid`,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        }
    ],
    returnData:
        {
            row: {},
            details: [],
            teenused: [],
            gridConfig:
                [
                    {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
                    {id: 'kood', name: 'Kood', width: '20%', show: true, type: 'text', readOnly: false},
                    {id: 'nimetus', name: 'Nimetus', width: '30%', show: true, type: 'text', readOnly: false},
                    {id: 'kogus', name: 'Kogus', width: '20%', show: true, type: 'text', readOnly: false},
                    {id: 'hind', name: 'Hind', width: '20%', show: true, type: 'text', readOnly: false},
                    {id: 'uhik', name: 'Mõttühik', width: '10%', show: true, type: 'text', readOnly: false},
                ],
        }
    ,


    requiredFields: [
        {name: 'kood', type: 'C'},
        {name: 'nimetus', type: 'C'}

    ],
    saveDoc:
        `select lapsed.sp_salvesta_lapse_grupp($1::jsonb, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc:
            `SELECT error_code, result, error_message
             FROM lapsed.sp_delete_lapse_grupp($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid:
        {
            gridConfiguration: [
                {id: "id", name: "id", width: "1%", show: false},
                {id: "kood", name: "Kood", width: "20%"},
                {id: "nimetus", name: "Nimetus", width: "40%"},
                {id: "all_yksused", name: "All üksused", width: "40%"}
            ],
            sqlString:
                    `SELECT id,
                            kood,
                            nimetus,
                            all_yksused,
                            $1::INTEGER AS rekvid,
                            $2::INTEGER AS user_id
                     FROM lapsed.cur_lapse_grupp v
                     WHERE rekvid = $1::INTEGER
                     ORDER BY kood`,     //  $1 всегда ид учреждения, $2 - userId
            params:
                '',
            alias:
                'curLapseGrupp'
        },
    print: [
        {
            view: 'lapse_grupp_register',
            params: 'id'
        },
        {
            view: 'lapse_grupp_register',
            params: 'sqlWhere'
        },
    ],

    uuendaHinnad: {
        command: `SELECT error_code, result, error_message, doc_type_id
                  FROM lapsed.update_prices_in_group($2::INTEGER, $1::INTEGER)`,//$1 docId, $2 - userId
        type: 'sql',
        alias: 'uuendaHinnad'
    },
    importGroups: {
        command: `SELECT error_code, result, error_message
                  FROM lapsed.import_groups( $1::JSONB, $2::INTEGER, $3::INTEGER)`,//$1 data [], $2 - userId, $3 rekvid
        type: 'sql',
        alias: 'importGroups'
    },

    bpm: [
        {
            name: 'Uuendada hinnad',
            task: 'uuendaHinnad',
            type: 'manual',
            action: 'uuendaHinnad',
        }
    ],



};

