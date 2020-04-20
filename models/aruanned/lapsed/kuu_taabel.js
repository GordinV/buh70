module.exports = {
    grid: {
        gridConfiguration: [
            {id: "yksus", name: "Üksus", width: "10%"},
            {id: "tyyp", name: "Koolituse tüüp", hideFilter: false, show: false},
            {id: "teenus", name: "Teenus", width: "10%"},
            {id: "kuu", name: "Kuu", width: "3%", type: "integer"},
            {id: "aasta", name: "Aasta", width: "4%", type: "integer"},
            {
                id: "day_1", name: "1", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_2", name: "2", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_3", name: "3", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_4", name: "4", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_5", name: "5", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_6", name: "6", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_7", name: "7", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_8", name: "8", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_9", name: "9", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_10", name: "10", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_11", name: "11", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_12", name: "12", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_13", name: "13", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_14", name: "14", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_15", name: "15", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_16", name: "16", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_17", name: "17", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_18", name: "18", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_19", name: "19", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_20", name: "20", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_21", name: "21", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_22", name: "22", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_23", name: "23", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_24", name: "24", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_25", name: "25", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_26", name: "26", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_27", name: "27", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_28", name: "28", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_29", name: "29", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_30", name: "30", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "day_31", name: "31", width: "2%", hideFilter: true,
                type: "integer",
            },
            {
                id: "kogus", name: "Kokku", width: "2%", hideFilter: true,
                type: "integer"
            }
        ],
        sqlString: `
            SELECT row_number() OVER (PARTITION BY yksus
                ORDER BY tyyp, yksus,
                    nom_id desc,
                    teenus, 
                    is_row ) AS id,
                   row_number()  over(PARTITION BY tyyp, yksus) as rea_count,                   
                   *
            FROM (
                     WITH kuu_taabel AS (
                         SELECT yksus,
                                tyyp,
                                nom_id,
                                teenus,
                                kuu,
                                aasta,
                                kogus,
                                day_1,
                                day_2,
                                day_3,
                                day_4,
                                day_5,
                                day_6,
                                day_7,
                                day_8,
                                day_9,
                                day_10,
                                day_11,
                                day_12,
                                day_13,
                                day_14,
                                day_15,
                                day_16,
                                day_17,
                                day_18,
                                day_19,
                                day_20,
                                day_21,
                                day_22,
                                day_23,
                                day_24,
                                day_25,
                                day_26,
                                day_27,
                                day_28,
                                day_29,
                                day_30,
                                day_31,
                                week_ends::INTEGER[] AS week_ends
                         FROM lapsed.kuu_taabel($1::INTEGER, $2::INTEGER, $3::INTEGER) qryReport
                         order by tyyp, yksus, nom_id desc
                     )
                     SELECT TRUE AS is_row,
                            *
                     FROM kuu_taabel tyyp
                         UNION ALL
                     SELECT FALSE AS is_row,
                         tyyp::TEXT || ' kokku:' AS yksus,
                         tyyp,
                         nom_id,
                         teenus,
                         kuu,
                         aasta,
                         sum(kogus) AS kogus,
                         sum(day_1) AS day_1,
                         sum(day_2) AS day_2,
                         sum(day_3) AS day_3,
                         sum(day_4) AS day_4,
                         sum(day_5) AS day_5,
                         sum(day_6) AS day_6,
                         sum(day_7) AS day_7,
                         sum(day_8) AS day_8,
                         sum(day_9) AS day_9,
                         sum(day_10) AS day_10,
                         sum(day_11) AS day_11,
                         sum(day_12) AS day_12,
                         sum(day_13) AS day_13,
                         sum(day_14) AS day_14,
                         sum(day_15) AS day_15,
                         sum(day_16) AS day_16,
                         sum(day_17) AS day_17,
                         sum(day_18) AS day_18,
                         sum(day_19) AS day_19,
                         sum(day_20) AS day_20,
                         sum(day_21) AS day_21,
                         sum(day_22) AS day_22,
                         sum(day_23) AS day_23,
                         sum(day_24) AS day_24,
                         sum(day_25) AS day_25,
                         sum(day_26) AS day_26,
                         sum(day_27) AS day_27,
                         sum(day_28) AS day_28,
                         sum(day_29) AS day_29,
                         sum(day_30) AS day_30,
                         sum(day_31) AS day_31,
                         NULL::INTEGER [] AS week_ends
                     FROM kuu_taabel kt
                     GROUP BY tyyp,
                         nom_id,
                         teenus,
                         kuu,
                         aasta
                 ) qry
            ORDER BY tyyp, yksus, nom_id desc, is_row
        `,     // $1 - rekvid, $2-KUU $3 - aasta
        params: ['rekvid', 'kuu', 'aasta'],
        alias: 'kuu_taabel_report',
        subtotals: ['day_1', 'day_2', 'day_3', 'day_4', 'day_5', 'day_6', 'day_7', 'day_8', 'day_9', 'day_10', 'day_11', 'day_12', 'day_13', 'day_14', 'day_15', 'day_16', 'day_17', 'day_18', 'day_19', 'day_20', 'day_21', 'day_22', 'day_23', 'day_24', 'day_25', 'day_26', 'day_27', 'day_28', 'day_29', 'day_30', 'day_31']
    },
    print: [
        {
            view: 'kuu_taabel_register',
            params: 'sqlWhere',
            group: 'tyyp'

        },
    ],

};
