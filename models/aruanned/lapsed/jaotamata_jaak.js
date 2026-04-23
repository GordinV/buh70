module.exports = {
    grid: {
        gridConfiguration: [
            {id: "period", name: "Seisuga", width: "10%", show: false, type: "date"},
            {id: "kulastatavus", name: "Külastatavus", width: "7%", show: true},
            {id: "nimi", name: "Lapse nimi", width: "30%"},
            {id: "ik", name: "Lapse IK", width: "10%", show: true},
            {id: "vn", name: "Viitenumber", width: "10%", show: true},
            {id: "arvete_jaak", name: "Arvete jääk", width: "10%", type: "number", interval: true},
            {id: "mk_jaak", name: "Maksekorralduse ettemaks", width: "10%", type: "number", interval: true},
            {id: "asutus", name: "Asutus", width: "20%", type: "text", show: true, interval: true},
        ],
        sqlString: `select *,
                           $2 as user_id
                    from
                        lapsed.jaotamata_jaak($1, case when ($3::text = '') then null::date else $3::date end)
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
