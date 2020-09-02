module.exports = {
    grid: {
        gridConfiguration: [
            {id: "kpv", name: "Kuupäev", width: "10%", type: "date"},
            {id: "aasta", name: "Aasta", width: "10%", type: "integer"},
            {id: "kuu", name: "Kuu", width: "5%", type: "integer", "interval": true},
            {id: "number", name: "Arve nr", width: "10%"},
            {id: "kood", name: "Kood", width: "15%"},
            {id: "hind", name: "Hind", width: "10%", type: "number", "interval": true},
            {id: "uhik", name: "Ühik", width: "10%"},
            {id: "kogus", name: "Kogus", width: "10%", type: "number", "interval": true},
            {id: "summa", name: "Summa", width: "10%", type: "number", "interval": true},
            {id: "asutus", name: "Asutus", width: "20%"},
        ],
        sqlString: `SELECT sum(a1.summa) OVER ()        AS summa_kokku,
                           to_char(a.kpv, 'DD.MM.YYYY') AS kpv,
                           year(a.kpv)                  AS aasta,
                           month(a.kpv)                 AS kuu,
                           a.number::TEXT,
                           n.kood,
                           n.uhik,
                           a1.hind,
                           a1.kogus,
                           a1.summa,
                           r.nimetus::TEXT              AS asutus,
                           $2                           AS user_id
                    FROM docs.doc d
                             INNER JOIN docs.arv a ON d.id = a.parentid
                             INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                             INNER JOIN libs.nomenklatuur n ON a1.nomid = n.id
                             INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                             INNER JOIN ou.rekv r ON r.id = d.rekvid
                    WHERE d.status <> 3
                      AND a.rekvid IN (SELECT rekv_id
                                       FROM get_asutuse_struktuur($1))
                    ORDER BY aasta, kuu, a.number, r.nimetus
        `,     // $1 - rekvid, $3 - kond
        params: '',
        alias: 'arved_koodi_jargi_report'
    },
    print: [
        {
            view: 'arved_koodi_jargi_register',
            params: 'sqlWhere',
            converter: function (data) {
                let summa_kokku = 0;
                let row_id = 0;
                data.forEach(row => {
                    summa_kokku = summa_kokku + Number(row.summa);
                });

                return data.map(row => {
                    row_id++;
                    row.summa_kokku = summa_kokku;
                    row.row_id = row_id;
                    return row;
                })
            }

        },
    ],

};
