module.exports = {
    grid: {
        gridConfiguration: [
            {id: "kpv", name: "Kuupäev", width: "7%", type: "date", interval: true},
            {id: "aasta", name: "Aasta", width: "5%", type: "integer"},
            {id: "kuu", name: "Kuu", width: "5%", type: "integer", "interval": true},
            {id: "number", name: "Arve nr", width: "7%"},
            {id: "kood", name: "Kood", width: "5%"},
            {id: "inf3", name: "INF3",  width: "3%", type: 'select', data: ['', 'JAH', 'EI']},
            {id: "hind", name: "Hind", width: "7%", type: "number", "interval": true},
            {id: "uhik", name: "Ühik", width: "5%"},
            {id: "kogus", name: "Kogus", width: "5%", type: "number", "interval": true},
            {id: "summa", name: "Summa", width: "10%", type: "number", "interval": true},
            {id: "asutus", name: "Asutus", width: "15%"},
            {id: "pank", name: "E-arve kanal(SEB, SWED)", width: "5%"},
            {id: "isikukood", name: "Lapse IK", width: "7%"},
            {id: "yksus", name: "Üksus", width: "7%"},
            {id: "liik", name: "Asutuse liik", width: "10%"},
            {id: "select", name: "Valitud", width: "5%", show: false, type: 'boolean', hideFilter: true}

        ],
        sqlString: `WITH rekv_ids AS (
            SELECT rekv_id
            FROM public.get_asutuse_struktuur($1)),
             docs_types AS (
                 SELECT id, kood FROM libs.library WHERE library.library = 'DOK' AND kood IN ('ARV')
             ),
             arved AS (
                 SELECT d.id,
                        d.rekvid,
                        a.kpv,
                        a.number,
                        a1.hind,
                        a1.kogus,
                        a1.summa,
                        a1.nomid,
                        a1.properties ->> 'yksus' AS yksus,
                        a.asutusid
                 FROM docs.doc d
                          INNER JOIN docs.arv a ON d.id = a.parentid
                          INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                 WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                   AND d.status < 3
                   AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                   AND a.kpv >= $3::date
                   AND a.kpv <= $4::date
        
                   AND ((a.properties ->> 'ettemaksu_period') IS NULL
                     OR a.properties ->> 'tyyp' = 'ETTEMAKS')
             )
        SELECT liik.nimetus                           AS liik,
               sum(a.summa) OVER ()                   AS summa_kokku,
               to_char(a.kpv, 'DD.MM.YYYY')           AS kpv,
               year(a.kpv)                            AS aasta,
               month(a.kpv)                           AS kuu,
               a.number::TEXT,
               n.kood,
               n.uhik,
               a.hind,
               a.kogus,
               a.summa,
               r.nimetus::TEXT                        AS asutus,
               $2                                 AS user_id,
               CASE
                   WHEN coalesce((va.properties ->> 'kas_earve')::BOOLEAN, FALSE)::BOOLEAN AND
                        NOT empty(va.properties ->> 'pank') THEN va.properties ->> 'pank'
                   ELSE '' END                        AS pank,
               CASE
                   WHEN coalesce((va.properties ->> 'kas_earve')::BOOLEAN, FALSE)::BOOLEAN AND
                        NOT empty(va.properties ->> 'pank') THEN va.properties ->> 'iban'
                   ELSE '' END                        AS iban,
               va.properties ->> 'e-arve'             AS earve,
               TRUE                                   AS select,
               a.id,
               a.yksus::TEXT                          AS yksus,
               yksus.properties::JSONB ->> 'tyyp'     AS tyyp,
               laps.isikukood                         AS isikukood,
               case when coalesce((n.properties ->> 'kas_inf3')::BOOLEAN, FALSE) then 'Jah' else 'Ei' end AS inf3
        FROM arved a
                 INNER JOIN libs.nomenklatuur n ON a.nomid = n.id
                 INNER JOIN lapsed.liidestamine l ON l.docid = a.id
                 INNER JOIN lapsed.laps laps ON laps.id = l.parentid
                 INNER JOIN ou.rekv r ON r.id = a.rekvid
                 LEFT OUTER JOIN lapsed.vanem_arveldus va
                                 ON l.parentid = va.parentid AND va.asutusid = a.asutusid AND va.rekvid = a.rekvid
                 LEFT OUTER JOIN libs.library yksus ON a.yksus = yksus.kood::TEXT
            AND yksus.rekvid = a.rekvid AND yksus.status <> 3
            AND yksus.library = 'LAPSE_GRUPP'
                 LEFT OUTER JOIN libs.library liik ON r.properties ->> 'liik' = liik.kood
            AND liik.library = 'ASUTUSE_LIIK'
            AND liik.status <> 3
            ORDER BY a.number, r.nimetus`,     // $1 - rekvid, $3 - kond
        params: ['rekvid', 'userid', 'kpv_start', 'kpv_end'],
        min_params: 2,
        alias: 'arved_koodi_jargi_report',
        notReloadWithoutParameters: true

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
