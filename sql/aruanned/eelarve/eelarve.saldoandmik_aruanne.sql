DROP FUNCTION IF EXISTS eelarve.saldoandmik_aruanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER);

CREATE OR REPLACE FUNCTION eelarve.saldoandmik_aruanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER)
    RETURNS TABLE (
        rekv_id  INTEGER,
        konto    VARCHAR(20),
        tp       VARCHAR(20),
        tegev    VARCHAR(20),
        allikas  VARCHAR(20),
        rahavoog VARCHAR(20),
        artikkel VARCHAR(20),
        deebet   NUMERIC(14, 2),
        kreedit  NUMERIC(14, 2)
    ) AS
$BODY$
SELECT rekv_id,
       konto::VARCHAR(20),
       tp::VARCHAR(20),
       tegev::VARCHAR(20),
       allikas::VARCHAR(20),
       rahavoog::VARCHAR(20),
       artikkel::VARCHAR(20),
       sum(deebet)  AS deebet,
       sum(kreedit) AS kreedit
FROM (
         WITH qrySaldoAndmik AS (
             SELECT j.kpv,
                    j.rekvid,
                    j1.deebet                                                       AS konto,
                    coalesce(CASE
                                 WHEN left(l.kood, 3) IN ('154', '155', '156')
                                     THEN ''
                                 ELSE j1.lisa_d END, '')::TEXT             AS tp,
                    coalesce(CASE
                                 WHEN left(l.kood, 3) IN ('154', '155', '156')
                                     THEN ''
                                 ELSE j1.kood1 END, '') :: VARCHAR(20)              AS tegev,
                    coalesce(j1.kood2, '') :: VARCHAR(20)                           AS allikas,
                    coalesce(CASE
                                 WHEN j.kpv < make_date(year(l_kpv2), 1, 1)
                                     THEN '00'
                                 ELSE j1.kood3 :: VARCHAR(20) END, '')::VARCHAR(20) AS rahavoog,
                    coalesce(j1.kood5, '') :: VARCHAR(20)                           AS artikkel,
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
                                                   ltrim(rtrim(l.kood)) = ltrim(rtrim(j1.deebet))
             WHERE d.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
               AND j.kpv <= l_kpv2
             UNION ALL
             SELECT j.kpv,
                    j.rekvid,
                    j1.kreedit                            AS konto,
                    CASE
                        WHEN left(l.kood, 3) IN ('154', '155', '156')
                            THEN ''
                        ELSE j1.lisa_k END::TEXT AS tp,
                    CASE
                        WHEN left(l.kood, 3) IN ('154', '155', '156')
                            THEN ''
                        ELSE j1.kood1 END :: VARCHAR(20)  AS tegev,
                    j1.kood2 :: VARCHAR(20)               AS allikas,
                    CASE
                        WHEN j.kpv < make_date(year(l_kpv2), 1, 1)
                            THEN '00'
                        ELSE j1.kood3 :: VARCHAR(20) END  AS rahavoog,
                    j1.kood5 :: VARCHAR(20)               AS artikkel,
                    0 :: NUMERIC                          AS deebet,
                    j1.summa                              AS kreedit,
                    coalesce(l.tun5, 1)                   AS tyyp,
                    NOT empty(l.tun1)                     AS is_tp,
                    NOT empty(l.tun2)                     AS is_tegev,
                    NOT empty(l.tun3)                     AS is_allikas,
                    NOT empty(l.tun4)                     AS is_rahavoog

             FROM docs.doc d
                      INNER JOIN docs.journal j ON j.parentid = d.id
                      INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                      INNER JOIN libs.library l ON l.library = 'KONTOD' AND
                                                   ltrim(rtrim(l.kood)) = ltrim(rtrim(j1.kreedit))
             WHERE d.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
               AND j.kpv <= l_kpv2
         )
         SELECT rekv_id,
                konto :: VARCHAR(20),
                tp:: CHAR(20),
                tegev :: VARCHAR(20),
                allikas :: VARCHAR(20),
                rahavoog :: VARCHAR(20),
                artikkel :: VARCHAR(20),
                sum(CASE
                        WHEN EMPTY(tyyp) OR tyyp = 1 OR tyyp = 3 THEN deebet - kreedit
                        ELSE 0 END)::NUMERIC(14, 2)                                                                 AS deebet,
                sum(
                        CASE WHEN tyyp = 2 OR tyyp = 4 THEN kreedit - deebet ELSE 000000000.00 END)::NUMERIC(14, 2) AS kreedit
         FROM (
                  SELECT rekvid                  AS rekv_id,
                         left(konto, 6)::TEXT    AS konto,
                         (CASE
                              WHEN is_tp
                                  THEN tp
                              ELSE '' END)::char(20) AS tp,
                         (CASE
                              WHEN is_tegev
                                  THEN tegev
                              ELSE '' END)::TEXT AS tegev,
                         (CASE
                              WHEN is_allikas
                                  THEN allikas
                              ELSE '' END)::TEXT AS allikas,
                         (CASE
                              WHEN is_rahavoog
                                  THEN rahavoog
                              ELSE '' END)::TEXT AS rahavoog,
                         (CASE
                              WHEN is_tegev
                                  THEN artikkel
                              ELSE '' END)::TEXT AS artikkel,
                         CASE
                             WHEN tyyp IS NULL OR tyyp IN (0, 1, 3)
                                 THEN (deebet) - (kreedit)
                             ELSE 0 END          AS deebet,
                         CASE
                             WHEN tyyp IS NOT NULL AND tyyp IN (2, 4)
                                 THEN (kreedit) - (deebet)
                             ELSE 0 END          AS kreedit,
                         tyyp
                  FROM qrySaldoAndmik qry
                  WHERE konto NOT IN ('999999', '000000', '888888')
              ) qry
         WHERE deebet <> 0
            OR kreedit <> 0
         GROUP BY rekv_id, konto, tp, tegev, allikas, artikkel, rahavoog
     ) tmp
WHERE deebet <> 0
   OR kreedit <> 0
GROUP BY rekv_id, konto, tp, tegev, allikas, rahavoog, artikkel
    ;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


SELECT sum(deebet) as db, sum(kreedit), konto, tp
FROM eelarve.saldoandmik_aruanne('2020-01-31' :: DATE, current_date :: DATE, 3 :: INTEGER)
where konto = '103000'
group by konto, tp
