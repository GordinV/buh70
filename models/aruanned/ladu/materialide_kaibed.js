module.exports = {
    grid: {
        gridConfiguration: [
            {id: "konto", name: "konto", width: "25px", show: false},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "alg_db", name: "Alg.Deebet", width: "100px"},
            {id: "alg_kr", name: "Alg.Kreedit", width: "75px"},
            {id: "deebet", name: "Deebet", width: "100px"},
            {id: "kreedit", name: "Kreedit", width: "100px"},
            {id: "lopp_db", name: "Lõpp deebet", width: "100px"},
            {id: "lopp_kr", name: "Lõpp kreedit", width: "200px"}
        ],
        sqlString: `SELECT l.kood::varchar(20)                   AS ladu_kood,
                           l.nimetus::varchar(254)                AS ladu,
                           n.kood::varchar(20),
                           n.nimetus::varchar(254),
                           n.uhik::varchar(20), 
                           (n.properties ->> 'grupp')::varchar(254) AS grupp,       
                           k.*
                    FROM ladu.matkaibed_aruanne($1::date, $2::date, $3::integer, $4::integer, $5::integer) k
                           INNER JOIN libs.library l ON l.id = k.ladu_id
                           INNER JOIN libs.nomenklatuur n ON n.id = k.vara_id
        `,     // $1 - kpv1, $2 - kpv2, $3- rekvid, $4 - ladu_id, $5 - vara_id
        params: '',
        alias: 'materialide_kaibed_aruanne'
    }
};
