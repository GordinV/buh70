module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "maksja", name: "Maksja", width: "20%"},
            {id: "isikukood", name: "Maksja IK", width: "10%"},
            {id: "viitenumber", name: "Viitenr", width: "10%"},
            {id: "kpv", name: "Maksepäev", width: "10%", type: 'date', interval: true},
            {id: "summa", name: "Summa", width: "10%", type: 'number', interval: true},
            {id: "selg", name: "Makse selgitus", width: "15%"},
            {id: "asutus", name: "Asutus", width: "15%"},
            {id: "pohjus", name: "Põhjus", width: "15%"},
        ],
        sqlString: `WITH report AS
                         (SELECT vv.id,
                                 vv.maksja,
                                 vv.isikukood,
                                 vv.viitenumber,
                                 to_char(vv.kpv, 'YYYY-MM-DD')::TEXT AS kpv,
                                 vv.summa,
                                 vv.selg,
                                 coalesce(v.rekv_id, (left(vv.viitenumber, 3))::INTEGER) AS rekv_id,
                                 case 
                                    WHEN v.viitenumber IS NULL and  (empty(coalesce(vv.viitenumber,''))  or len(vv.viitenumber) <> '10')   THEN 'Vale viitenumber'
                                    when vv.isikukood is null or empty(vv.isikukood) then 'Vale maksja IK'
                                    when vv.kpv::DATE < '2022-09-01' AND v.rekv_id IN (SELECT id
                                                                   FROM ou.rekv r
                                                                   WHERE left(nimetus, 7) NOT IN
                                                                         ('0911008', '0911012', '0911018', '0911027', '0911036', '0911038')
                                                                     AND parentid = 119) 
                                                                     then 'Kuni 01.09.2022'
                                    when vv.properties->>'error_message' is not null then ' Tehnilise viga'
                                    end as pohjus
                          FROM lapsed.pank_vv vv
                                   LEFT OUTER JOIN lapsed.viitenr v ON vv.viitenumber = v.viitenumber
                          WHERE coalesce(doc_id,0) = 0 
                            and coalesce(vv.selg,'') not ilike '%intres%'
                            AND coalesce(vv.isikukood,'') NOT in ('75024260')
                            and vv.maksja not in ('AS SEB PANK')
                            AND kpv >= '2022-01-01'
                            AND NOT left(coalesce(markused, ''), 4) = 'Kuni'
                         )
                SELECT report.*, r.nimetus AS asutus, $1 as rekvId, $2 as userId
                FROM report
                         left outer JOIN ou.rekv r ON report.rekv_id = r.id`,
        params: '',
        notReloadWithoutParameters: true,
        min_params: 0,
        alias: 'selgemata_maksed',
    },
    print: [
        {
            view: 'selgemata_maksed',
            params: 'sqlWhere',
            converter: function (data) {
                let summa_kokku = 0;
                data.forEach(row => {
                    summa_kokku = summa_kokku + Number(row.summa);
                });

                return data.map(row => {
                    row.summa_kokku = summa_kokku;
                    return row;
                })
            }

        },
    ],

};
