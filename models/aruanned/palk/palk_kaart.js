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
        sqlString: `        with
                                params as (
                                              select
                                                  $1::date as kpv_1,
                                                  $2::date as kpv_2,
                                                  $3                 as rekv_id,
                                                  $4                  as kond
                                )
                            select
                                qry.*
                            FROM
                                params                                                                             p,
                                palk.palk_kaart(p.kpv_1::date, p.kpv_2::date, p.rekv_id::integer, p.kond::integer) qry
                            where
                                p.kpv_2::date < '2025-01-01'::date
                            union all
                            select
                                qry.*
                            FROM
                                params                                                                                  p,
                                palk.palk_kaart_2025(p.kpv_1::date, p.kpv_2::date, p.rekv_id::integer, p.kond::integer) qry
                            where
                                p.kpv_1::date >= '2025-01-01'::date`,     //  $1 - kpv1, $2 - kpv2, $3 - rekvid, $4 svod (null)
        params: '',
        alias: 'palk_kaart'
    }
};
