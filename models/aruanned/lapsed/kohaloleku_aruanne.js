module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0px", type: "integer", show: false},
            {id: "kuu", name: "Kuu", width: "5%", type: "integer"},
            {id: "aasta", name: "Aasta", width: "5%", type: "integer"},
            {id: "asutus", name: "Teenus", width: "30%"},
            {id: "koolituse_tyyp", name: "Koolituse tüüp", width: "20%"},
            {id: "yksuse_kogus", name: "Üksuse kogus", width: "10%", type: "integer"},
            {id: "nimekirje_kogus", name: "Laste kogus nimekirjas", width: "10%", type: "integer"},
            {id: "faktiline_kogus", name: "Laste faktiline kogus", width: "10%", type: "integer"},
            {id: "kogus", name: "Laste/päevad", width: "10%", type: "integer"},
        ],
        sqlString: `SELECT row_number() OVER ()                            AS id,
                           row_number() OVER (PARTITION BY asutus)         AS row_id,
                           *,
                           sum(yksuse_kogus) OVER (PARTITION BY asutus)    AS yksuse_kogus_kokku,
                           sum(nimekirje_kogus) OVER (PARTITION BY asutus) AS nimekirje_kogus_kokku,
                           sum(faktiline_kogus) OVER (PARTITION BY asutus) AS faktiline_kogus_kokku,
                           sum(kogus) OVER (PARTITION BY asutus)           AS kogus_kokku
                    FROM lapsed.kohaloleku_aruanne($1::INTEGER, CASE
                                                                   WHEN $2::INTEGER < 1 OR $2::INTEGER > 12 THEN NULL
                                                                   ELSE $2::INTEGER END,
                                                  CASE
                                                      WHEN $3::INTEGER < year(current_date) - 10 OR
                                                           $3::INTEGER > year(current_date) + 1
                                                          THEN NULL
                                                      ELSE $3::INTEGER END) qryReport
                    ORDER BY asutus, koolituse_tyyp
        `,     // $1 - rekvid, $2-KUU $3 - aasta
        params: ['rekvid', 'kuu', 'aasta'],
        alias: 'kohaloleku_report',
        subtotals: ['yksuse_kogus', 'nimekirje_kogus', 'faktiline_kogus', 'kogus']

    },
    print: [
        {
            view: 'kohaloleku_aruanne_register',
            params: 'sqlWhere',
            group: 'asutus'

        },
    ],

};
