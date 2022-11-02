module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "maksja", name: "Maksja", width: "20%"},
            {id: "isikukood", name: "Maksja IK", width: "10%"},
            {id: "viitenumber", name: "Viitenr", width: "10%"},
            {id: "kpv", name: "Maksepäev", width: "10%", type: 'date', interval: true},
            {id: "summa", name: "Summa", width: "10%", type: 'number', interval: true},
            {id: "selg", name: "Makse selgitus", width: "20%"},
            {id: "asutus", name: "Asutus", width: "20%"}
        ],
        sqlString: `WITH report AS
                         (SELECT vv.id,
                                 vv.maksja,
                                 vv.isikukood,
                                 vv.viitenumber,
                                 to_char(vv.kpv, 'YYYY-MM-DD')::TEXT AS kpv,
                                 vv.summa,
                                 vv.selg,
                                 coalesce(v.rekv_id, (left(vv.viitenumber, 3))::INTEGER) AS rekv_id
                          FROM lapsed.pank_vv vv
                                   LEFT OUTER JOIN lapsed.viitenr v ON vv.viitenumber = v.viitenumber
                          WHERE doc_id IS NULL
                            AND kpv >= '2022-01-01'
                            AND NOT left(coalesce(markused, ''), 4) = 'Kuni'
                         )
                SELECT report.*, r.nimetus AS asutus, $1 as rekvId, $2 as userId
                FROM report
                         left outer JOIN ou.rekv r ON report.rekv_id = r.id`,
        params: '',
        notReloadWithoutParameters: true,
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
