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
        sqlString: `WITH qryReport AS (
            WITH rekv_ids AS
                     (
                         SELECT r.*
                         FROM get_asutuse_struktuur($2) r        
                         WHERE rekv_id = CASE
                                             WHEN $3 = 1
                                                 THEN rekv_id
                                             ELSE $2 END
                     ),
                    report AS (        
                        SELECT CASE
                                WHEN r.tase > 2 THEN r.parent_id else r.rekv_id end as rekv_id,
                               konto::VARCHAR(20),
                               tp::VARCHAR(20),
                               tegev::VARCHAR(20),
                               allikas::VARCHAR(20),
                               rahavoog::VARCHAR(20),
                               (deebet)   AS deebet,
                               (kreedit)  AS kreedit,
                               tyyp::INTEGER AS tyyp
                         FROM eelarve.saldoandmik_aruanne($1 :: DATE, $2 :: INTEGER, $3 ::INTEGER, $4::JSONB) s
                              INNER JOIN rekv_ids r ON r.rekv_id = s.rekv_id                         
                        WHERE deebet <> 0
                           OR kreedit <> 0
                   )
                    SELECT rekv_id,
                           konto::VARCHAR(20),
                           tp::VARCHAR(20),
                           tegev::VARCHAR(20),
                           allikas::VARCHAR(20),
                           rahavoog::VARCHAR(20),
                           sum(deebet)   AS deebet,
                           sum(kreedit)  AS kreedit,
                           tyyp::INTEGER AS tyyp
                     FROM report
                    WHERE deebet <> 0
                       OR kreedit <> 0
                    GROUP BY rekv_id
                            , konto
                            , tp
                            , tegev
                            , allikas
                            , rahavoog
                            , tyyp
                   
                ),
                 kond AS (
                     SELECT 999999        AS rekv_id,
                            konto::VARCHAR(20),
                            tp::VARCHAR(20),
                            tegev::VARCHAR(20),
                            allikas::VARCHAR(20),
                            rahavoog::VARCHAR(20),
                            sum(deebet)   AS deebet,
                            sum(kreedit)  AS kreedit,
                            tyyp::INTEGER AS tyyp
                     FROM qryReport r
                     where not empty($3 ::INTEGER)
                     GROUP BY konto
                             , tp
                             , tegev
                             , allikas
                             , rahavoog
                             , tyyp
                 ),
                 report AS (
                     SELECT rekv_id       AS rekv_id,
                            konto::VARCHAR(20),
                            tp::VARCHAR(20),
                            tegev::VARCHAR(20),
                            allikas::VARCHAR(20),
                            rahavoog::VARCHAR(20),
                            deebet        AS deebet,
                            kreedit       AS kreedit,
                            tyyp::INTEGER AS tyyp
                     FROM kond r
                     UNION ALL
                     SELECT rekv_id       AS rekv_id,
                            konto::VARCHAR(20),
                            tp::VARCHAR(20),
                            tegev::VARCHAR(20),
                            allikas::VARCHAR(20),
                            rahavoog::VARCHAR(20),
                            deebet        AS deebet,
                            kreedit       AS kreedit,
                            tyyp::INTEGER AS tyyp
                     FROM qryReport
                 )
                SELECT Report.*,
                       r.regkood::VARCHAR(20),
                       r.nimetus::VARCHAR(254) AS asutus
                FROM Report
                         INNER JOIN (SELECT id, parentid, regkood, nimetus
                                     FROM ou.rekv
                                     WHERE parentid < 999
                                     UNION ALL
                                     SELECT 999999, 0, '' AS regkood, 'Koond' AS nimetus) r
                                    ON r.id = Report.rekv_id
                         LEFT OUTER JOIN ou.rekv p ON r.parentid = p.id
                ORDER BY CASE WHEN rekv_id = 999999 THEN 0 ELSE 1 END, r.parentid, r.nimetus, Report.konto, Report.tp,
                         Report.tegev, allikas, rahavoog`,
        // $1 - kpv $2 - rekvid , $3 - KOND, $4 tunnus
        params: '',
        alias: 'saldoandmik_report'
    }
};
