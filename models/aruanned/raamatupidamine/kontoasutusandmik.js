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
                        coalesce(sum(deebet)
                          FILTER (WHERE kpv is null) OVER (
                          PARTITION BY rekv_id, asutus_id, konto ),0)::numeric(14,2) AS alg_saldo,
                        CASE WHEN kpv is not null
                          THEN deebet
                        ELSE 0 END                                 AS deebet,
                        kreedit,
                        coalesce(sum(deebet - kreedit)
                        OVER (
                          PARTITION BY rekv_id, asutus_id, konto ),0)::numeric(14,2) AS lopp_saldo,
                        qryReport.kpv,
                        qryReport.rekv_id,
                        qryReport.asutus_id,
                        qryReport.konto::varchar(20),
                        qryReport.korr_konto::varchar(20),
                        qryReport.dok::varchar(120),
                        qryReport.number::varchar(20),
                        qryReport.kood1::varchar(20),
                        qryReport.kood2::varchar(20),
                        qryReport.kood3::varchar(20),
                        qryReport.kood4::varchar(20),
                        qryReport.kood5::varchar(20),
                        qryReport.proj::varchar(20),
                        qryReport.tunnus::varchar(20),
                        a.regkood::varchar(20), a.nimetus::varchar(254) as asutus, a.tp::varchar(20), a.aadress,
                        l.nimetus::varchar(254),
                        r.nimetus::varchar(254) as rekv_nimetus,
                        r.parentid 
                      FROM docs.kontoasutusandmik($1::text, $2 :: INTEGER, $3::date, $4 :: DATE, $5::integer) qryReport
                      inner join libs.asutus a on a.id = qryReport.asutus_id
                      inner join com_kontoplaan l on l.kood = qryReport.konto
                      inner join com_rekv r on r.id = qryReport.rekv_id
                      where qryReport.konto is not null and qryReport.asutus_id is not null
                      order by qryReport.rekv_id, qryReport.konto, a.nimetus, qryReport.kpv`,     // $1- konto, $2 - asutus_id, $3 - kpv1, $4 - kpv2, $5 - rekvid (svod)
        params: '',
        alias: 'kontoasutusandmik_report'
    }
};
