DROP FUNCTION IF EXISTS eelarve.saldoandmik_aruanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER);
DROP FUNCTION IF EXISTS eelarve.saldoandmik_aruanne(l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER);


CREATE OR REPLACE FUNCTION eelarve.saldoandmik_aruanne(l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE (
        rekv_id  INTEGER,
        konto    VARCHAR(20),
        tp       VARCHAR(20),
        tegev    VARCHAR(20),
        allikas  VARCHAR(20),
        rahavoog VARCHAR(20),
        deebet   NUMERIC(14, 2),
        kreedit  NUMERIC(14, 2),
        tyyp     INTEGER
    ) AS
$BODY$
SELECT rekv_id,
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
                                 WHEN j.kpv < make_date(year(l_kpv2), 1, 1)
                                     THEN '00'
                                 ELSE j1.kood3 :: VARCHAR(20) END, '')::VARCHAR(20) AS rahavoog,
                    j1.summa                                                        AS deebet,
                    0 :: NUMERIC                                                    AS kreedit,
                    coalesce(l.tun5, 1)                                             AS tyyp,
                    NOT empty(l.tun1)                                               AS is_tp,
                    NOT empty(l.tun2)                                               AS is_tegev,
                    NOT empty(l.tun3)                                               AS is_allikas,
                    NOT empty(l.tun4)                                               AS is_rahavoog
             FROM docs.doc d
                      INNER JOIN docs.journal j ON j.parentid = d.id
                      INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                      INNER JOIN libs.library l ON l.library = 'KONTOD' AND
                                                   l.status <> 3 AND
                                                   ltrim(rtrim(l.kood)) = ltrim(rtrim(j1.deebet))
                 -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                      LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
             WHERE d.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
               -- если свод, то оставим только учреждение, иначе все под
               AND d.rekvid = CASE WHEN l_kond IS NULL THEN l_rekvid ELSE d.rekvid END
               AND j.kpv <= l_kpv2
             UNION ALL
             SELECT coalesce(a.kpv, j.kpv),
                    j.rekvid,
                    j1.kreedit                           AS konto,
                    j1.lisa_k:: VARCHAR(20)              AS tp,
                    j1.kood1 :: VARCHAR(20)              AS tegev,
                    j1.kood2 :: VARCHAR(20)              AS allikas,
                    CASE
                        WHEN j.kpv < make_date(year(l_kpv2), 1, 1)
                            THEN '00'
                        ELSE j1.kood3 :: VARCHAR(20) END AS rahavoog,
                    0 :: NUMERIC                         AS deebet,
                    j1.summa                             AS kreedit,
                    COALESCE(l.tun5, 1)                  AS tyyp,
                    NOT empty(l.tun1)                    AS is_tp,
                    (NOT empty(l.tun2))                  AS is_tegev,
                    NOT empty(l.tun3)                    AS is_allikas,
                    NOT empty(l.tun4)                    AS is_rahavoog
             FROM docs.doc D
                      INNER JOIN docs.journal j
                                 ON j.parentid = D.id
                      INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                      INNER JOIN libs.library l ON l.library = 'KONTOD' AND
                                                   ltrim(rtrim(l.kood)) = ltrim(rtrim(j1.kreedit))
                 -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                      LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
             WHERE D.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
               -- если свод, то оставим только учреждение, иначе все под
               AND d.rekvid = CASE WHEN l_kond IS NULL THEN l_rekvid ELSE d.rekvid END
               AND j.kpv <= l_kpv2
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
                  -- algsaldo
                  SELECT rekvid                      AS rekv_id,
                         left(konto, 6)::TEXT        AS konto,
                         (CASE
                              WHEN is_tp
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
                             WHEN qry.tyyp IS NULL OR qry.tyyp IN (0, 1, 3)
                                 THEN (deebet) - (kreedit)
                             ELSE 0 END              AS deebet,
                         CASE
                             WHEN qry.tyyp IS NOT NULL AND qry.tyyp IN (2, 4)
                                 THEN (kreedit) - (deebet)
                             ELSE 0 END              AS kreedit,
                         qry.tyyp
                  FROM qrySaldoAndmik qry
                  WHERE konto NOT IN ('999999', '000000', '888888')
                    AND qry.kpv < make_date(year(l_kpv2), 1, 1)
                    AND qry.tyyp < 3
                  UNION ALL
                  -- kaibed
                  SELECT rekvid                      AS rekv_id,
                         left(konto, 6)::TEXT        AS konto,
                         (CASE
                              WHEN is_tp
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
                             WHEN qry.tyyp IS NULL OR qry.tyyp IN (0, 1, 3)
                                 THEN (deebet) - (kreedit)
                             ELSE 0 END              AS deebet,
                         CASE
                             WHEN qry.tyyp IS NOT NULL AND qry.tyyp IN (2, 4)
                                 THEN (kreedit) - (deebet)
                             ELSE 0 END              AS kreedit,
                         qry.tyyp
                  FROM qrySaldoAndmik qry
                  WHERE konto NOT IN ('999999', '000000', '888888')
                    AND qry.kpv >= make_date(year(l_kpv2), 1, 1)
              ) qry
         WHERE deebet <> 0
            OR kreedit <> 0
         GROUP BY rekv_id, konto, tp, tegev, allikas, rahavoog, qry.tyyp
     ) tmp
WHERE deebet <> 0
   OR kreedit <> 0
GROUP BY rekv_id, konto, tp, tegev, allikas, rahavoog, tmp.tyyp
    ;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION eelarve.saldoandmik_aruanne(DATE, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.saldoandmik_aruanne(DATE, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.saldoandmik_aruanne(DATE, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.saldoandmik_aruanne(DATE, INTEGER, INTEGER) TO dbvaatleja;


/*
SELECT *
FROM eelarve.saldoandmik_aruanne(current_date :: DATE, 63 :: INTEGER, null::integer)
WHERE konto = '100100'
GROUP BY konto, tp
*/