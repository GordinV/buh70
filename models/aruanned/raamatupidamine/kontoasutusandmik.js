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
        sqlString: `  SELECT
                        sum(deebet)
                          FILTER (WHERE kpv is null) OVER (
                          PARTITION BY rekv_id, asutus_id, konto ) AS alg_saldo,
                        CASE WHEN kpv is not null
                          THEN deebet
                        ELSE 0 END                                 AS deebet,
                        kreedit,
                        sum(deebet - kreedit)
                        OVER (
                          PARTITION BY rekv_id, asutus_id, konto ) AS lopp_saldo,
                        qryReport.kpv,
                        qryReport.rekv_id,
                        qryReport.asutus_id,
                        qryReport.konto,
                        qryReport.korr_konto,
                        qryReport.dok,
                        qryReport.number,
                        qryReport.kood1,
                        qryReport.kood2,
                        qryReport.kood3,
                        qryReport.kood4,
                        qryReport.kood5,
                        qryReport.proj,
                        qryReport.tunnus,
                        a.regkood, a.nimetus as asutus, a.tp, a.aadress,
                        l.nimetus,
                        r.nimetus as rekv_nimetus,
                        r.parentid 
                      FROM docs.kontoasutusandmik($1::text, $2 :: INTEGER, $3::date, $4 :: DATE, $5::integer) qryReport
                      inner join libs.asutus a on a.id = qryReport.asutus_id
                      inner join com_kontoplaan l on l.kood = qryReport.konto
                      inner join com_rekv r on r.id = qryReport.rekv_id
                      where qryReport.konto is not null`,     // $1- konto, $2 - asutus_id, $3 - kpv1, $4 - kpv2, $5 - rekvid (svod)
        params: '',
        alias: 'kontoasutusandmik_report'
    }
};
