module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "number", name: "Arve nr", width: "10%"},
            {id: "print_kpv", name: "Arve kuupäev", width: "10%", type: "date", interval: true},
            {id: "maksja", name: "Maksja nimi", width: "20%", show: true},
            {id: "lapse_nimi", name: "Lapse nimi", width: "20%"},
            {id: "viitenumber", name: "Viitenumber", width: "10%"},
            {id: "saadetud", name: "Saatmise aeg", width: "10%"},
            {id: "saatmise_staatus", name: "Saatmise staatus", width: "10%"},
            {id: "asutus", name: "Asutus", width: "20%"},
        ],
        sqlString: `SELECT a.id,
                           a.number,
                           to_char(a.kpv, 'DD.MM.YYYY') AS print_kpv,
                           a.kpv::DATE                  AS kpv,
                           a.viitenumber,
                           a.maksja,
                           a.lapse_nimi,
                           a.saadetud,
                           a.saatmise_staatus,
                           a.asutus                     AS asutus,
                           $2                           AS user_id
                    FROM lapsed.arved_emailiga($1::INTEGER, $3::DATE, $4::DATE) a
        `,     // $1 - rekvid, $3 - kond
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
        min_params: 2,
        alias: 'arved_emailiga'
    },
    print: [
        {
            view: 'arved_emailiga',
            params: 'sqlWhere'
        },
    ],

};
