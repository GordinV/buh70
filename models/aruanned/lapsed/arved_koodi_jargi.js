module.exports = {
    grid: {
        gridConfiguration: [
            {id: "kpv", name: "Kuupäev", width: "7%", type: "date", interval: true},
            {id: "aasta", name: "Aasta", width: "7%", type: "integer"},
            {id: "kuu", name: "Kuu", width: "5%", type: "integer", "interval": true},
            {id: "number", name: "Arve nr", width: "7%"},
            {id: "kood", name: "Kood", width: "7%"},
            {id: "hind", name: "Hind", width: "7%", type: "number", "interval": true},
            {id: "uhik", name: "Ühik", width: "5%"},
            {id: "kogus", name: "Kogus", width: "7%", type: "number", "interval": true},
            {id: "summa", name: "Summa", width: "10%", type: "number", "interval": true},
            {id: "asutus", name: "Asutus", width: "20%"},
            {id: "pank", name: "E-arve kanal(SEB, SWED)", width: "5%"},
            {id: "yksus", name: "Üksus", width: "10%"},
            {id: "koolituse_tyyp", name: "Koolituse tüüp", width: "10%"},
            {id: "select", name: "Valitud", width: "5%", show: false, type: 'boolean', hideFilter: true}

        ],
        sqlString: `
            SELECT l.nimetus AS koolituse_tyyp,
                   arved.*
            FROM (
                     SELECT sum(a1.summa) OVER ()              AS summa_kokku,
                            to_char(a.kpv, 'DD.MM.YYYY')       AS kpv,
                            year(a.kpv)                        AS aasta,
                            month(a.kpv)                       AS kuu,
                            a.number::TEXT,
                            n.kood,
                            n.uhik,
                            a1.hind,
                            a1.kogus,
                            a1.summa,
                            r.nimetus::TEXT                    AS asutus,
                            $2                                 AS user_id,
                            v.properties ->> 'pank'            AS pank,
                            v.properties ->> 'iban'            AS iban,
                            v.properties ->> 'e-arve'          AS earve,
                            TRUE                               AS select,
                            d.id,
                            a1.properties ->> 'yksus'          AS yksus,
                            yksus.properties::JSONB ->> 'tyyp' AS tyyp
                     FROM docs.doc d
                              INNER JOIN docs.arv a ON d.id = a.parentid
                              INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                              INNER JOIN libs.nomenklatuur n ON a1.nomid = n.id
                              INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                              INNER JOIN ou.rekv r ON r.id = d.rekvid
                              LEFT OUTER JOIN lapsed.vanemad v ON v.asutusid = a.asutusid
                         AND v.parentid = l.parentid
                              LEFT OUTER JOIN libs.library yksus ON (a1.properties ->> 'yksus')::TEXT = yksus.kood::TEXT
                         AND yksus.rekvid = a.rekvid AND yksus.status <> 3
                         AND yksus.library = 'LAPSE_GRUPP'
                     WHERE d.status <> 3
                       AND a.rekvid IN (SELECT rekv_id
                                        FROM get_asutuse_struktuur($1))
                       AND ((a.properties ->> 'ettemaksu_period') IS NULL
                         OR a.properties ->> 'tyyp' = 'ETTEMAKS')
                     ORDER BY aasta, kuu, a.number, r.nimetus
                 ) arved
                     LEFT OUTER JOIN libs.library l
                                     ON l.id = arved.tyyp::INTEGER
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
