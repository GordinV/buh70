module.exports = {
    grid: {
        gridConfiguration: [
            {id: "yksus", name: "Üksus", width: "6%"},
            {id: "viitenr", name: "Viitenr.", width: "6%"},
            {id: "vana_vn", name: "Vana VN", width: "5%"},
            {id: "nimi", name: "Nimi", width: "7%"},
            {id: "teenus", name: "Teenus", width: "6%"},
            {id: "kuu", name: "Kuu", width: "2%", type: "integer"},
            {id: "aasta", name: "Aasta", width: "3%", type: "integer"},
            {
                id: "day_1",
                name: "1",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_2",
                name: "2",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_3",
                name: "3",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_4",
                name: "4",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer",
            },
            {
                id: "day_5",
                name: "5",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_6",
                name: "6",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_7",
                name: "7",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_8",
                name: "8",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_9",
                name: "9",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_10",
                name: "10",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_11",
                name: "11",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_12",
                name: "12",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_13",
                name: "13",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_14",
                name: "14",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_15",
                name: "15",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"

            },
            {
                id: "day_16",
                name: "16",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_17",
                name: "17",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_18",
                name: "18",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_19",
                name: "19",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_20",
                name: "20",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_21",
                name: "21",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_22",
                name: "22",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_23",
                name: "23",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_24",
                name: "24",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_25",
                name: "25",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"

            },
            {
                id: "day_26",
                name: "26",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_27",
                name: "27",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_28",
                name: "28",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_29",
                name: "29",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_30",
                name: "30",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"
            },
            {
                id: "day_31",
                name: "31",
                width: "2%",
                hideFilter: true,
                hideEmptyValue: true,
                type: "integer"

            },
            {id: "kogus", name: "kokku", width: "2%", hideFilter: true, type: "integer"}
//            {id: "tuhi", name: " ", width: "1px", hideFilter: true},
        ],
        sqlString: `
            SELECT qry.*,
                   vn.vn                                    AS vana_vn                   
            FROM (
                     SELECT row_number() OVER (PARTITION BY yksus, isikukood
                         ORDER BY
                             yksus,
                             nimi,
                             isikukood,
                             nom_id DESC
                             ,is_row) AS rea_count,
                            *
                     FROM (
                              WITH yksuse_taabel AS (
                                  SELECT yksus,
                                         nom_id,
                                         teenus,
                                         isikukood,
                                         viitenr,
                                         nimi,
                                         kuu,
                                         aasta,
                                         kogus,
                                         CASE WHEN nom_id <> 999999999 AND day_1 = 0 THEN 0 ELSE day_1 END   AS day_1,
                                         CASE WHEN nom_id <> 999999999 AND day_2 = 0 THEN 0 ELSE day_2 END   AS day_2,
                                         CASE WHEN nom_id <> 999999999 AND day_3 = 0 THEN 0 ELSE day_3 END   AS day_3,
                                         CASE WHEN nom_id <> 999999999 AND day_4 = 0 THEN 0 ELSE day_4 END   AS day_4,
                                         CASE WHEN nom_id <> 999999999 AND day_5 = 0 THEN 0 ELSE day_5 END   AS day_5,
                                         CASE WHEN nom_id <> 999999999 AND day_6 = 0 THEN 0 ELSE day_6 END   AS day_6,
                                         CASE WHEN nom_id <> 999999999 AND day_7 = 0 THEN 0 ELSE day_7 END   AS day_7,
                                         CASE WHEN nom_id <> 999999999 AND day_8 = 0 THEN 0 ELSE day_8 END   AS day_8,
                                         CASE WHEN nom_id <> 999999999 AND day_9 = 0 THEN 0 ELSE day_9 END   AS day_9,
                                         CASE WHEN nom_id <> 999999999 AND day_10 = 0 THEN 0 ELSE day_10 END AS day_10,
                                         CASE WHEN nom_id <> 999999999 AND day_11 = 0 THEN 0 ELSE day_11 END AS day_11,
                                         CASE WHEN nom_id <> 999999999 AND day_12 = 0 THEN 0 ELSE day_12 END AS day_12,
                                         CASE WHEN nom_id <> 999999999 AND day_13 = 0 THEN 0 ELSE day_13 END AS day_13,
                                         CASE WHEN nom_id <> 999999999 AND day_14 = 0 THEN 0 ELSE day_14 END AS day_14,
                                         CASE WHEN nom_id <> 999999999 AND day_15 = 0 THEN 0 ELSE day_15 END AS day_15,
                                         CASE WHEN nom_id <> 999999999 AND day_16 = 0 THEN 0 ELSE day_16 END AS day_16,
                                         CASE WHEN nom_id <> 999999999 AND day_17 = 0 THEN 0 ELSE day_17 END AS day_17,
                                         CASE WHEN nom_id <> 999999999 AND day_18 = 0 THEN 0 ELSE day_18 END AS day_18,
                                         CASE WHEN nom_id <> 999999999 AND day_19 = 0 THEN 0 ELSE day_19 END AS day_19,
                                         CASE WHEN nom_id <> 999999999 AND day_20 = 0 THEN 0 ELSE day_20 END AS day_20,
                                         CASE WHEN nom_id <> 999999999 AND day_21 = 0 THEN 0 ELSE day_21 END AS day_21,
                                         CASE WHEN nom_id <> 999999999 AND day_22 = 0 THEN 0 ELSE day_22 END AS day_22,
                                         CASE WHEN nom_id <> 999999999 AND day_23 = 0 THEN 0 ELSE day_23 END AS day_23,
                                         CASE WHEN nom_id <> 999999999 AND day_24 = 0 THEN 0 ELSE day_24 END AS day_24,
                                         CASE WHEN nom_id <> 999999999 AND day_25 = 0 THEN 0 ELSE day_25 END AS day_25,
                                         CASE WHEN nom_id <> 999999999 AND day_26 = 0 THEN 0 ELSE day_26 END AS day_26,
                                         CASE WHEN nom_id <> 999999999 AND day_27 = 0 THEN 0 ELSE day_27 END AS day_27,
                                         CASE WHEN nom_id <> 999999999 AND day_28 = 0 THEN 0 ELSE day_28 END AS day_28,
                                         CASE WHEN nom_id <> 999999999 AND day_29 = 0 THEN 0 ELSE day_29 END AS day_29,
                                         CASE WHEN nom_id <> 999999999 AND day_30 = 0 THEN 0 ELSE day_30 END AS day_30,
                                         CASE WHEN nom_id <> 999999999 AND day_31 = 0 THEN 0 ELSE day_31 END AS day_31,
                                         week_ends::INTEGER[]                                                AS week_ends
                                  FROM lapsed.yksuse_taabel($1::INTEGER, $2::INTEGER, $3::INTEGER) qryReport
                                  ORDER BY yksus,
                                           nimi,
                                           nom_id DESC
                              )
                              SELECT TRUE                                                  AS is_row,
                                     CASE WHEN nom_id = 999999999 THEN TRUE ELSE FALSE END AS is_osa,
                                     *
                              FROM yksuse_taabel
                              UNION ALL
                              SELECT FALSE                                                 AS is_row,
                                     CASE WHEN nom_id = 999999999 THEN TRUE ELSE FALSE END AS is_osa,
                                     yksus,
                                     nom_id,
                                     teenus,
                                     'XXXXXXXXXXX',
                                     'XXXXXXXXXXX',
                                     'Kokku'                                               AS nimi,
                                     kuu,
                                     aasta,
                                     sum(kogus)                                            AS kogus,
                                     sum(day_1)                                            AS day_1,
                                     sum(day_2)                                            AS day_2,
                                     sum(day_3)                                            AS day_3,
                                     sum(day_4)                                            AS day_4,
                                     sum(day_5)                                            AS day_5,
                                     sum(day_6)                                            AS day_6,
                                     sum(day_7)                                            AS day_7,
                                     sum(day_8)                                            AS day_8,
                                     sum(day_9)                                            AS day_9,
                                     sum(day_10)                                           AS day_10,
                                     sum(day_11)                                           AS day_11,
                                     sum(day_12)                                           AS day_12,
                                     sum(day_13)                                           AS day_13,
                                     sum(day_14)                                           AS day_14,
                                     sum(day_15)                                           AS day_15,
                                     sum(day_16)                                           AS day_16,
                                     sum(day_17)                                           AS day_17,
                                     sum(day_18)                                           AS day_18,
                                     sum(day_19)                                           AS day_19,
                                     sum(day_20)                                           AS day_20,
                                     sum(day_21)                                           AS day_21,
                                     sum(day_22)                                           AS day_22,
                                     sum(day_23)                                           AS day_23,
                                     sum(day_24)                                           AS day_24,
                                     sum(day_25)                                           AS day_25,
                                     sum(day_26)                                           AS day_26,
                                     sum(day_27)                                           AS day_27,
                                     sum(day_28)                                           AS day_28,
                                     sum(day_29)                                           AS day_29,
                                     sum(day_30)                                           AS day_30,
                                     sum(day_31)                                           AS day_31,
                                     NULL::INTEGER[]                                       AS week_ends
                              FROM yksuse_taabel
                              GROUP BY yksus,
                                       nom_id,
                                       teenus,
                                       kuu,
                                       aasta
                              UNION ALL
                              SELECT FALSE                                      AS is_row,
                                     FALSE                                      AS is_osa,
                                     yksus,
                                     1,
                                     'Kalendripäevad kokku',
                                     'XXXXXXXXXXX',
                                     'XXXXXXXXXXX',
                                     'Kokku'                                    AS nimi,
                                     kuu,
                                     aasta,
                                     day(gomonth(make_date($3, $2, 01), 1) - 1) AS kogus,
                                     NULL                                       AS day_1,
                                     NULL                                       AS day_2,
                                     NULL                                       AS day_3,
                                     NULL                                       AS day_4,
                                     NULL                                       AS day_5,
                                     NULL                                       AS day_6,
                                     NULL                                       AS day_7,
                                     NULL                                       AS day_8,
                                     NULL                                       AS day_9,
                                     NULL                                       AS day_10,
                                     NULL                                       AS day_11,
                                     NULL                                       AS day_12,
                                     NULL                                       AS day_13,
                                     NULL                                       AS day_14,
                                     NULL                                       AS day_15,
                                     NULL                                       AS day_16,
                                     NULL                                       AS day_17,
                                     NULL                                       AS day_18,
                                     NULL                                       AS day_19,
                                     NULL                                       AS day_20,
                                     NULL                                       AS day_21,
                                     NULL                                       AS day_22,
                                     NULL                                       AS day_23,
                                     NULL                                       AS day_24,
                                     NULL                                       AS day_25,
                                     NULL                                       AS day_26,
                                     NULL                                       AS day_27,
                                     NULL                                       AS day_28,
                                     NULL                                       AS day_29,
                                     NULL                                       AS day_30,
                                     NULL                                       AS day_31,
                                     NULL::INTEGER[]                            AS week_ends
                              FROM yksuse_taabel
                              GROUP BY yksus,
                                       kuu,
                                       aasta
                              UNION ALL
                              -- toopaevad
                              SELECT FALSE           AS is_row,
                                     FALSE           AS is_osa,
                                     yksus,
                                     2,
                                     'Tööpäevad kokku',
                                     'XXXXXXXXXXX',
                                     'XXXXXXXXXXX',
                                     'Kokku'         AS nimi,
                                     kuu,
                                     aasta,
                                     palk.get_work_days((SELECT row_to_json(row)
                                                         FROM (SELECT $2 AS kuu,
                                                                      $3 AS aasta,
                                                                      $1 AS rekvid) row))
                                                     AS kogus,
                                     NULL            AS day_1,
                                     NULL            AS day_2,
                                     NULL            AS day_3,
                                     NULL            AS day_4,
                                     NULL            AS day_5,
                                     NULL            AS day_6,
                                     NULL            AS day_7,
                                     NULL            AS day_8,
                                     NULL            AS day_9,
                                     NULL            AS day_10,
                                     NULL            AS day_11,
                                     NULL            AS day_12,
                                     NULL            AS day_13,
                                     NULL            AS day_14,
                                     NULL            AS day_15,
                                     NULL            AS day_16,
                                     NULL            AS day_17,
                                     NULL            AS day_18,
                                     NULL            AS day_19,
                                     NULL            AS day_20,
                                     NULL            AS day_21,
                                     NULL            AS day_22,
                                     NULL            AS day_23,
                                     NULL            AS day_24,
                                     NULL            AS day_25,
                                     NULL            AS day_26,
                                     NULL            AS day_27,
                                     NULL            AS day_28,
                                     NULL            AS day_29,
                                     NULL            AS day_30,
                                     NULL            AS day_31,
                                     NULL::INTEGER[] AS week_ends
                              FROM yksuse_taabel
                              GROUP BY yksus,
                                       kuu,
                                       aasta
                              UNION ALL
                              -- tabelite kogus
                              SELECT FALSE           AS is_row,
                                     FALSE           AS is_osa,
                                     l.nimetus::TEXT AS yksus,
                                     3,
                                     'Koostatud tabelite kokku',
                                     'XXXXXXXXXXX',
                                     'XXXXXXXXXXX',
                                     'Kokku'         AS nimi,
                                     $2              AS kuu,
                                     $3              AS aasta,
                                     count(t.id)
                                                     AS kogus,
                                     NULL            AS day_1,
                                     NULL            AS day_2,
                                     NULL            AS day_3,
                                     NULL            AS day_4,
                                     NULL            AS day_5,
                                     NULL            AS day_6,
                                     NULL            AS day_7,
                                     NULL            AS day_8,
                                     NULL            AS day_9,
                                     NULL            AS day_10,
                                     NULL            AS day_11,
                                     NULL            AS day_12,
                                     NULL            AS day_13,
                                     NULL            AS day_14,
                                     NULL            AS day_15,
                                     NULL            AS day_16,
                                     NULL            AS day_17,
                                     NULL            AS day_18,
                                     NULL            AS day_19,
                                     NULL            AS day_20,
                                     NULL            AS day_21,
                                     NULL            AS day_22,
                                     NULL            AS day_23,
                                     NULL            AS day_24,
                                     NULL            AS day_25,
                                     NULL            AS day_26,
                                     NULL            AS day_27,
                                     NULL            AS day_28,
                                     NULL            AS day_29,
                                     NULL            AS day_30,
                                     NULL            AS day_31,
                                     NULL::INTEGER[] AS week_ends
                              FROM lapsed.day_taabel t
                                       INNER JOIN libs.library l ON l.id = t.grupp_id
                              WHERE month(t.kpv) = coalesce($2, month(current_date))::INTEGER
                                AND year(t.kpv) = coalesce($3, month(current_date))::INTEGER
                                AND t.rekv_id = $1
                                AND t.staatus <> 3
                              GROUP BY t.rekv_id, t.grupp_id, l.nimetus
                          ) qry
                 ) qry
                     LEFT OUTER JOIN (SELECT string_agg(viitenumber, ', ') AS vn, vn.isikukood
                                      FROM lapsed.viitenr vn
                                      WHERE vn.rekv_id IN (SELECT rekv_id
                                                           FROM get_asutuse_struktuur($1))
                                      GROUP BY vn.isikukood
            ) vn
                                     ON vn.isikukood = qry.isikukood

            ORDER BY yksus,
                     is_row DESC,
                     nimi,
                     is_osa DESC, teenus`,     // $1 - rekvid, $2-KUU $3 - aasta
        params: ['rekvid', 'kuu', 'aasta'],
        notReloadWithoutParameters: true,
        alias: 'yksuse_taabel_report',
        subtotals: ['day_1', 'day_2', 'day_3', 'day_4', 'day_5', 'day_6', 'day_7', 'day_8', 'day_9', 'day_10', 'day_11', 'day_12', 'day_13', 'day_14', 'day_15', 'day_16', 'day_17', 'day_18', 'day_19', 'day_20', 'day_21', 'day_22', 'day_23', 'day_24', 'day_25', 'day_26', 'day_27', 'day_28', 'day_29', 'day_30', 'day_31']
    },
    print: [
        {
            view: 'yksuse_taabel_register',
            params: 'sqlWhere',
            group: 'yksus'

        },
    ],

};
