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
        sqlString: `SELECT rekv_id,
                     konto::VARCHAR(20),
                     tp::VARCHAR(20),
                     tegev::VARCHAR(20),
                     allikas::VARCHAR(20),
                     rahavoog::VARCHAR(20),
                     sum(deebet)   AS deebet,
                     sum(kreedit)  AS kreedit,
                     tyyp::INTEGER AS tyyp
              FROM (
                       WITH qrySaldoAndmik AS (
                           SELECT coalesce(a.kpv, j.kpv)                                          AS kpv,
                                  j.rekvid,
                                  j1.deebet                                                       AS konto,
                                  coalesce(j1.lisa_d, '')::TEXT                                   AS tp,
                                  coalesce(j1.kood1, '') :: VARCHAR(20)                           AS tegev,
                                  coalesce(j1.kood2, '') :: VARCHAR(20)                           AS allikas,
                                  coalesce(CASE
                                               WHEN j.kpv < make_date(year($1::DATE), 1, 1)
                                                   THEN '00'
                                               ELSE j1.kood3 :: VARCHAR(20) END, '')::VARCHAR(20) AS rahavoog,
                                  sum(j1.summa)                                                   AS deebet,
                                  0 :: NUMERIC                                                    AS kreedit
                           FROM docs.doc d
                                    INNER JOIN docs.journal j ON j.parentid = d.id
                                    INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                                    LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                           WHERE d.rekvid IN (SELECT rekv_id
                                              FROM get_asutuse_struktuur($2::INTEGER))
                             AND d.rekvid = CASE WHEN $3::INTEGER IS NULL THEN $2::INTEGER ELSE d.rekvid END
                             AND j.kpv <= $1::DATE
                             AND (($4::jsonb ->> 'tunnus') IS NULL OR coalesce(j1.tunnus, '') ILIKE coalesce(($4::jsonb ->> 'tunnus'), '') || '%')
                             AND (($4::jsonb ->> 'proj') IS NULL OR coalesce(j1.proj, '') ILIKE coalesce(($4::jsonb ->> 'proj'), '') || '%')                             
                             AND d.status <> 3
                           GROUP BY coalesce(a.kpv, j.kpv), j.kpv, j.rekvid, j1.deebet, j1.lisa_d, j1.kood1, j1.kood2,j1.kood3
                           UNION ALL
                           SELECT coalesce(a.kpv, j.kpv),
                                  j.rekvid,
                                  j1.kreedit                           AS konto,
                                  j1.lisa_k:: VARCHAR(20)              AS tp,
                                  j1.kood1 :: VARCHAR(20)              AS tegev,
                                  j1.kood2 :: VARCHAR(20)              AS allikas,
                                  CASE
                                      WHEN j.kpv < make_date(year($1::DATE), 1, 1)
                                          THEN '00'
                                      ELSE j1.kood3 :: VARCHAR(20) END AS rahavoog,
                                  0 :: NUMERIC                         AS deebet,
                                  sum(j1.summa)                        AS kreedit
                           FROM docs.doc d
                                    INNER JOIN docs.journal j
                                               ON j.parentid = D.id
                                    INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                                    INNER JOIN libs.library l ON l.library = 'KONTOD' AND
                                                                 l.status <> 3 AND
                                                                 ltrim(rtrim(l.kood)) = ltrim(rtrim(j1.kreedit))
                                    LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                           WHERE d.rekvid IN (SELECT rekv_id
                                              FROM get_asutuse_struktuur($2::INTEGER))
                             AND d.rekvid = CASE WHEN $3::INTEGER IS NULL THEN $2::INTEGER ELSE d.rekvid END
                             AND j.kpv <= $1::DATE
                             AND (($4::jsonb ->> 'tunnus') IS NULL OR coalesce(j1.tunnus, '') ILIKE coalesce(($4::jsonb ->> 'tunnus'), '') || '%')
                             AND (($4::jsonb ->> 'proj') IS NULL OR coalesce(j1.proj, '') ILIKE coalesce(($4::jsonb ->> 'proj'), '') || '%')
                             AND d.status <> 3
                           GROUP BY coalesce(a.kpv, j.kpv), j.kpv, j.rekvid, j1.kreedit, j1.lisa_k, j1.kood1, j1.kood2, j1.kood3
                       ),
                            qryKontod AS (
                                (SELECT l.kood,
                                        NOT empty(l.tun1)   AS is_tp,
                                        NOT empty(l.tun2)   AS is_tegev,
                                        NOT empty(l.tun3)   AS is_allikas,
                                        NOT empty(l.tun4)   AS is_rahavoog,
                                        coalesce(l.tun5, 1) AS tyyp,
                                        l.muud
                                 FROM libs.library l
                                 WHERE l.library = 'KONTOD'
                                   AND l.status <> 3)
                            )
                       SELECT rekv_id,
                              konto :: VARCHAR(20),
                              tp:: CHAR(20),
                              tegev :: VARCHAR(20),
                              allikas :: VARCHAR(20),
                              rahavoog :: VARCHAR(20),
                              sum(CASE
                                      WHEN EMPTY(qry.tyyp) OR qry.tyyp = 1 OR qry.tyyp = 3 THEN deebet - kreedit
                                      ELSE 0 END)::NUMERIC(14, 2)                AS deebet,
                              sum(
                                      CASE
                                          WHEN qry.tyyp = 2 OR qry.tyyp = 4 THEN kreedit - deebet
                                          ELSE 000000000.00 END)::NUMERIC(14, 2) AS kreedit,
                              qry.tyyp::INTEGER
                       FROM (
                                SELECT qry.rekvid                  AS rekv_id,
                                       left(konto, 6)::TEXT        AS konto,
                                       (CASE
                                            WHEN l.is_tp AND (ltrim(rtrim(coalesce(l.muud, ''))) <> '*' OR ltrim(rtrim(qry.rahavoog)) in ('01','00','21','17'))
                                                THEN tp                                           
                                            WHEN l.is_tp
                                                THEN tp
                                            ELSE '' END)::CHAR(20) AS tp,
                                       (CASE
                                            WHEN is_tegev AND
                                                 ltrim(rtrim(coalesce(l.muud, ''))) = '*' AND ltrim(rtrim(coalesce(qry.rahavoog, ''))) = '00'
                                                THEN
                                                ''
                                           
                                            WHEN l.is_tegev
                                                THEN tegev
                                            ELSE '' END)::TEXT     AS tegev,
                                       (CASE
                                            WHEN l.is_allikas
                                                THEN allikas
                                            ELSE '' END)::TEXT     AS allikas,
                                       (CASE
                                            WHEN l.is_rahavoog
                                                THEN rahavoog
                                            ELSE '' END)::TEXT     AS rahavoog,
                                       CASE
                                           WHEN l.tyyp IS NULL OR l.tyyp IN (0, 1, 3)
                                               THEN (deebet) - (kreedit)
                                           ELSE 0 END              AS deebet,
                                       CASE
                                           WHEN l.tyyp IS NOT NULL AND l.tyyp IN (2, 4)
                                               THEN (kreedit) - (deebet)
                                           ELSE 0 END              AS kreedit,
                                       l.tyyp                      AS tyyp
                                FROM qrySaldoAndmik qry
                                         INNER JOIN qryKontod l ON ltrim(rtrim(l.kood)) = ltrim(rtrim(qry.konto))

                                WHERE konto NOT IN ('999999', '000000', '888888')
                                  AND qry.kpv < make_date(year($1::DATE), 1, 1)
                                  AND l.tyyp < 3
                                UNION ALL
                                SELECT rekvid                      AS rekv_id,
                                       left(konto, 6)::TEXT        AS konto,
                                       (CASE
                                            WHEN is_tp AND (ltrim(rtrim(coalesce(l.muud, ''))) <> '*' OR ltrim(rtrim(qry.rahavoog)) in ('01','00','21','17'))
                                                THEN tp
                                            ELSE '' END)::CHAR(20) AS tp,
                                       (CASE
                                            WHEN is_tegev
                                                THEN tegev
                                            ELSE '' END)::TEXT     AS tegev,
                                       (CASE
                                            WHEN is_allikas
                                                THEN allikas
                                            ELSE '' END)::TEXT     AS allikas,
                                       (CASE
                                            WHEN is_rahavoog
                                                THEN rahavoog
                                            ELSE '' END)::TEXT     AS rahavoog,
                                       CASE
                                           WHEN l.tyyp IS NULL OR l.tyyp IN (0, 1, 3)
                                               THEN (deebet) - (kreedit)
                                           ELSE 0 END              AS deebet,
                                       CASE
                                           WHEN l.tyyp IS NOT NULL AND l.tyyp IN (2, 4)
                                               THEN (kreedit) - (deebet)
                                           ELSE 0 END              AS kreedit,
                                       l.tyyp
                                FROM qrySaldoAndmik qry
                                         INNER JOIN qryKontod l ON
                                    ltrim(rtrim(l.kood)) = ltrim(rtrim(qry.konto))
                                WHERE konto NOT IN ('999999', '000000', '888888')
                                  AND qry.kpv >= make_date(year($1::DATE), 1, 1)
                            ) qry
                       WHERE deebet <> 0
                          OR kreedit <> 0
                       GROUP BY rekv_id
                              , konto
                              , tp
                              , tegev
                              , allikas
                              , rahavoog
                              , tyyp
                   ) tmp
              WHERE deebet <> 0
                 OR kreedit <> 0
              GROUP BY rekv_id
                     , konto
                     , tp
                     , tegev
                     , allikas
                     , rahavoog
                     , tyyp`,
        sqlStringVana: `
            SELECT rekv_id,
                   sum(deebet)  AS deebet,
                   sum(kreedit) AS kreedit,
                   konto,
                   tp,
                   tegev,
                   allikas,
                   rahavoog
            FROM eelarve.saldoandmik_aruanne($1::DATE, $2::INTEGER, $3::INTEGER, $4::TEXT)
            GROUP BY rekv_id,
                     konto,
                     tp,
                     tegev,
                     allikas,
                     rahavoog
            ORDER BY konto, tp, tegev, allikas, rahavoog`,     // $1 - kpv $2 - rekvid , $3 - KOND, $4 tunnus
        params: '',
        alias: 'saldoandmik_report'
    }
};
