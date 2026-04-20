module.exports = {
    grid: {
        gridConfiguration: [
            {id: "period", name: "Period", width: "10%", show: false, type: "date", interval: true},
            {id: "nimi", name: "Lapse nimi", width: "30%"},
            {id: "ik", name: "Lapse IK", width: "10%", show: false},
            {id: "vn", name: "Viitenumber", width: "10%", show: true},
            {id: "arvete_jaak", name: "Arvete jääk", width: "10%", type: "number", interval: true},
            {id: "mk_jaak", name: "Maksekorralduse ettemaks", width: "10%", type: "number", interval: true},
            {id: "asutus", name: "Asutus", width: "20%", type: "text", show: true, interval: true},
        ],
        sqlString: `select *,
                           $2 as user_id
                    from
                        lapsed.jaotamata_jaak($1, $3)
        `,     // $1 - rekvid, $3 - kpv
        params: ['rekvid', 'userid', 'period'],
        min_params: 2,
        alias: 'jaotamata_jaak_report',
        notReloadWithoutParameters: true
    },
    print: [
        {
            view: 'jaotamata_jaak_register',
            params: 'sqlWhere',
            }
    ],

};
