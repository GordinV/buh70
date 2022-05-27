module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0px", type: "integer", show: false},
            {id: "kuu", name: "Kuu", width: "5%", type: "integer"},
            {id: "aasta", name: "Aasta", width: "5%", type: "integer"},
            {id: "asutus", name: "Asutus", width: "30%"},
            {id: "koolituse_tyyp", name: "Koolituse tüüp", width: "20%"},
            {id: "yksuse_kogus", name: "Üksuste arv", width: "10%", type: "integer"},
            {id: "nimekirje_kogus", name: "Laste arv nimekirjas", width: "10%", type: "integer"},
            {id: "faktiline_kogus", name: "Tegelik külastatavus", width: "10%", type: "integer"},
            {id: "kogus", name: "Lastepäevade arv", width: "10%", type: "integer"},
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
        subtotals: ['yksuse_kogus', 'nimekirje_kogus', 'faktiline_kogus', 'kogus'],
        notReloadWithoutParameters: true

    },
    print: [
        {
            view: 'kohaloleku_aruanne_register',
            params: 'sqlWhere',
            group: 'asutus',
            converter: function (data) {
                let yksuse_kogus_kokku = 0;
                let nimekirje_kogus_kokku = 0;
                let faktiline_kogus_kokku = 0;
                let kogus_kokku = 0;
                let row_id = 0;
                data.forEach(row => {
                    yksuse_kogus_kokku = yksuse_kogus_kokku + row.yksuse_kogus;
                    nimekirje_kogus_kokku = nimekirje_kogus_kokku + row.nimekirje_kogus;
                    faktiline_kogus_kokku = faktiline_kogus_kokku + row.faktiline_kogus;
                    kogus_kokku = kogus_kokku + row.kogus;
                });

                return data.map(row => {
                    row_id++;
                    row.yksuse_kogus_kokku = yksuse_kogus_kokku;
                    row.nimekirje_kogus_kokku = nimekirje_kogus_kokku;
                    row.faktiline_kogus_kokku = faktiline_kogus_kokku;
                    row.kogus_kokku = kogus_kokku;
                    row.row_id = row_id;
                    return row;
                })

            }

        },
    ],

};
