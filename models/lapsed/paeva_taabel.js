module.exports = {
    selectAsLibs: ``,

    select: [{
        sql: `WITH v_grupp AS (
    SELECT grupp_id
    FROM lapsed.day_taabel
    WHERE id = $1::INTEGER
)
SELECT t.id,
       $2                                                                                   AS userid,
       to_char(t.kpv, 'YYYY-MM-DD')::TEXT                                                   AS kpv,
       t.muud,
       t.grupp_id,
       l.kood::TEXT                                                                         AS yksus,
       s.nimetus                                                                            AS status,
       t.staatus                                                                            AS doc_status,
       json_agg(json_build_object('nom_id', to_json(n.nomid), 'teenus', to_json(n.teenus))) AS noms
FROM lapsed.day_taabel t
         INNER JOIN libs.library l ON l.id = t.grupp_id
         LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = t.staatus :: TEXT,

     (SELECT x.*, n.uhik, coalesce((n.properties ->> 'luno')::TEXT, n.kood)::TEXT AS teenus
      FROM jsonb_to_recordset((SELECT properties::JSONB ->> 'teenused'
                               FROM libs.library l
                                        INNER JOIN v_grupp ON v_grupp.grupp_id = l.id)::JSONB) AS x(nomid INTEGER)
               LEFT OUTER JOIN libs.nomenklatuur n ON n.id = x.nomid AND lower(n.uhik) IN ('paev', 'päev')) n

WHERE t.id = $1::INTEGER
GROUP BY t.id, t.kpv, t.grupp_id, l.kood, s.nimetus, t.staatus`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid,
                  to_char(current_date,'YYYY-MM-DD')::text as kpv,
                  1::integer as docStatus,
                  null::integer as grupp_id,
                  null::text as status,
                  null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }, {
        sql: ` SELECT $2                                         AS userid,
                      row_number() OVER ()                       AS id,
                      parent_id,
                      lk.parentid                                AS lapsId,
                      laps.isikukood,
                      laps.nimi,
                      lapsed.get_viitenumber(lk.rekvid, laps.id) AS viitenr,
                      l.id                                       AS grupp_id,
                      lk.rekvid,
                      max(t1.osalemine)                          AS osalemine,
                      json_agg(
                              json_build_object('nom_id', to_json(lk.nomid),
                                                'teenus', to_json(COALESCE((n.properties ->>
                                                                            'luno')::TEXT,
                                                                           n.kood)),
                                                'kogus', to_json(t1.kogus),
                                                'id', to_json(t1.id)))
                                                                 AS noms
               FROM lapsed.lapse_kaart lk
                        INNER JOIN lapsed.day_taabel1 t1
                                   ON lk.parentid = t1.laps_id AND lk.nomid = t1.nom_id
                        INNER JOIN lapsed.day_taabel t ON t.id = t1.parent_id
                        INNER JOIN libs.library l ON l.kood = lk.properties ->>
                                                              'yksus' AND l.library =
                                                                          'LAPSE_GRUPP'
                   AND l.id = t.grupp_id
                        INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
                        INNER JOIN lapsed.laps laps ON laps.id = lk.parentid
               WHERE lk.staatus <> 3
                 AND t1.parent_id = $1
               GROUP BY parent_id, lk.parentid, laps.id, laps.isikukood, laps.nimi, lk.rekvid, l.id`,
        query: null,
        multiple: false,
        alias: 'details',
        data: []
    }
    ],
    returnData:
        {
            row: {},
            details: [],
            gridConfig: [
                {id: 'id', name: 'id', width: '10px', show: true, type: 'text', readOnly: true},
                {id: 'isikukood', name: 'Isikukood', width: '50px', show: false, type: 'text', readOnly: true},
                {id: 'viitenr', name: 'Viitenumber', width: '50px', show: true, type: 'text', readOnly: true},
                {id: 'nimi', name: 'Nimi', width: '100px', show: true, type: 'text', readOnly: true},
                {
                    id: 'osalemine',
                    name: 'Osalemine',
                    width: '50px',
                    show: true,
                    type: 'boolean',
                    readOnly: false,
                    boolSumbolYes: '\u25CF',
                    yesBackgroundColor: '#b9edb9',
                    boolSumbolNo: '\u2716'
                },
            ]

        }
    ,


    requiredFields: [
        {name: 'grupp_id', type: 'I'},
        {name: 'kpv', type: 'D'},
        {
            trigger: () => {
                console.log('called trigger');
            }
        }

    ],
    saveDoc:
        `select lapsed.convert_day_taabel($1::jsonb, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc:
            `SELECT error_code, result, error_message
             FROM lapsed.sp_delete_paeva_taabel($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid:
        {
            gridConfiguration: [
                {id: "id", name: "id", width: "10%", show: false},
                {id: "kpv", name: "Kuupäev", width: "30%", type: "date", interval: true},
                {id: "yksus", name: "Üksus", width: "50%"},
                {id: "staatus", name: "Staatus", width: "20%"},
            ],
            sqlString:
                    `SELECT t.id,
                            to_char(t.kpv, 'DD.MM.YYYY') AS kpv,
                            t.yksus,
                            $2::INTEGER                  AS userid,
                            t.staatus
                     FROM lapsed.cur_paeva_taabel t
                     WHERE rekv_id = $1::INTEGER
                     ORDER BY kpv DESC, yksus
            `,     //  $1 всегда ид учреждения, $2 - userId
            params:
                '',
            alias:
                'curPaevaTaabel'
        },
    print: [
        {
            view: 'paeva_taabel_kaart',
            params: 'id',
            converter: (data) => {
                // создать поля
                const totals = {};
                let osalemine = 0;
                data.details = data.details.map((row) => {
                    // считаем кол-во
                    if (row.osalemine) {
                        osalemine++;
                    }

                    //дополнить строки полями
                    data[0].noms.forEach((column, index) => {
                        // ищем количество
                        let kogus = 0;
                        let findRow = row.noms.find(nom => nom.nom_id == column.nom_id);
                        if (findRow && findRow.kogus) {
                            kogus = findRow.kogus;
                        }

                        row[`header_${index}`] = column.teenus;
                        row[`data_${index}`] = kogus;
                        totals[index] = (totals[index] ? totals[index] : 0) + kogus;
                    });
                    return row;
                });

                // totals
                totals['osalemine'] = osalemine;
                data[0].totals = totals;
                return data;
            }

        },
        {
            view: 'paeva_taabel_register',
            params: 'sqlWhere'
        },
    ],
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                                 AS id,
                         (ajalugu ->> 'user')::TEXT                                           AS kasutaja,
                         to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS') AS koostatud,
                         to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS') AS muudatud,
                         to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS')   AS prinditud,
                         to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS') AS kustutatud

                  FROM (
                           SELECT jsonb_array_elements(d.ajalugu) AS ajalugu
                           FROM lapsed.day_taabel d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry`,
        type: "sql",
        alias: "getLogs"
    },

    arvestaPaevaTaabel: {
        command: `SELECT error_code, result, error_message, doc_type_id
                  FROM lapsed.koosta_paevad_taabel((SELECT to_jsonb(row.*) FROM (SELECT $1 AS grupp_id, $3 AS kpv) row),
                                                   $2::INTEGER)`, //$1 - grupp_id, $2 - userId, $3 - kpv
        type: "sql",
        alias: 'arvestaPaevaTaabel'
    },


};

