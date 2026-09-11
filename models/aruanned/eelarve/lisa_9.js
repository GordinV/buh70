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
        sqlString: `with
                        report as (
                                      SELECT
                                          qryReport.*,
                                          sum(qryReport.summa) over (partition by saaja_regkood, maksja_regkood, tehingu_arv) as saaja_summa,
                                          r.nimetus                                              as asutus
                                      FROM
                                          eelarve.lisa_9($1::DATE, $2::DATE, $3::INTEGER, $4::INTEGER) qryReport
                                              INNER JOIN ou.rekv                                       r ON r.id = qryReport.rekv_id
                        )
                    select *
                    from
                        report r
                    where
                        r.saaja_summa > 0
                    ORDER BY
                        maksja_regkood, asutus, saaja_nimi, kpv, artikkel, tegev
        `,     // $1 - alg_kpv $2 - lopp_kpv, $3 - rekvid, $4 - kond
        params: '',
        alias: 'lisa_9'
    },
    ai : {
        endpoint: `https://check-xml-1088344506167.europe-north1.run.app`,
        type: `link`,
        alias: `ai`
    },

};
