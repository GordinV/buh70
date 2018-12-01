DROP FUNCTION IF EXISTS docs.kontoasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER );

CREATE OR REPLACE FUNCTION docs.kontoasutusandmik(l_konto  TEXT, l_asutus INTEGER, l_kpv1 DATE, l_kpv2 DATE,
                                                  l_rekvid INTEGER)
  RETURNS TABLE(
    rekv_id    INTEGER,
    asutus_id  INTEGER,
    kpv        DATE,
    deebet     NUMERIC(14, 2),
    kreedit    NUMERIC(14, 2),
    konto      VARCHAR(20),
    korr_konto VARCHAR(20),
    dok        VARCHAR(120),
    number     INTEGER,
    kood1      VARCHAR(20),
    kood2      VARCHAR(20),
    kood3      VARCHAR(20),
    kood4      VARCHAR(20),
    kood5      VARCHAR(20),
    proj       VARCHAR(20),
    tunnus     VARCHAR(20)
  ) AS
$BODY$
WITH algsaldo AS (
    SELECT
      rekv_id,
      sum(deebet) - sum(kreedit) AS alg_saldo,
      asutus_id,
      konto
    FROM (
           SELECT
             d.rekvid            AS rekv_id,
             asutusid            AS asutus_id,
             deebet              AS konto,
             summa               AS deebet,
             0 :: NUMERIC(14, 2) AS kreedit
           FROM docs.doc d
             INNER JOIN docs.journal j ON j.parentid = d.id
             INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
           WHERE j.asutusid IS NOT NULL
                 AND (empty(l_asutus)  OR j.asutusid = l_asutus)
                 AND j.kpv < l_kpv1
                 AND j.rekvid IN (SELECT rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid))
           UNION ALL
           SELECT
             d.rekvid            AS rekv_id,
             asutusid            AS asutus_id,
             kreedit             AS konto,
             0 :: NUMERIC(14, 2) AS deebet,
             summa               AS kreedit
           FROM docs.doc d
             INNER JOIN docs.journal j ON j.parentid = d.id
             INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
           WHERE j.asutusid IS NOT NULL
                 AND (empty(l_asutus) OR j.asutusid = l_asutus)
                 AND j.kpv < l_kpv1
                 AND j.rekvid IN (SELECT rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid))
         ) qry
    WHERE (empty(l_konto) OR qry.konto LIKE ltrim(rtrim(l_konto)) || '%')
    GROUP BY rekv_id, asutus_id, konto)
SELECT
  a.rekv_id,
  a.asutus_id,
  null::date           AS kpv,
  a.alg_saldo          AS deebet,
  0 :: NUMERIC(14, 2)  AS kreedit,
  a.konto,
  NULL :: VARCHAR(20)  AS korr_konto,
  NULL :: VARCHAR(120) AS dok,
  NULL :: INTEGER      AS number,
  NULL :: VARCHAR(20)  AS kood1,
  NULL :: VARCHAR(20)  AS kood2,
  NULL :: VARCHAR(20)  AS kood3,
  NULL :: VARCHAR(20)  AS kood4,
  NULL :: VARCHAR(20)  AS kood5,
  NULL :: VARCHAR(20)  AS proj,
  NULL :: VARCHAR(20)  AS tunnus
FROM algsaldo a
UNION ALL
SELECT
  qry.rekv_id,
  qry.asutus_id,
  qry.kpv,
  qry.deebet  AS deebet,
  qry.kreedit AS kreedit,
  qry.konto,
  qry.korr_konto,
  qry.dok,
  qry.number,
  qry.kood1,
  qry.kood2,
  qry.kood3,
  qry.kood4,
  qry.kood5,
  qry.proj,
  qry.tunnus
FROM (
       SELECT
         j.rekvid     AS rekv_id,
         j.kpv,
         j.summa      AS deebet,
         0 :: NUMERIC AS kreedit,
         j.deebet     AS konto,
         j.kreedit    AS korr_konto,
         j.dok,
         j.number,
         j.asutusid   AS asutus_id,
         j.kood1,
         j.kood2,
         j.kood3,
         j.kood4,
         j.kood5,
         j.proj,
         j.tunnus
       FROM cur_journal j
       WHERE j.asutusid IS NOT NULL
             AND (empty(l_asutus) OR j.asutusid = l_asutus)
             AND j.kpv >= l_kpv1
             AND j.kpv <= l_kpv2
             AND j.rekvid IN (SELECT rekv_id
                              FROM get_asutuse_struktuur(l_rekvid))
       UNION ALL
       SELECT
         j.rekvid     AS rekv_id,
         j.kpv,
         0 :: NUMERIC AS deebet,
         j.summa      AS kreedit,
         j.kreedit    AS konto,
         j.deebet     AS korr_konto,
         j.dok,
         j.number,
         j.asutusid   AS asutus_id,
         j.kood1,
         j.kood2,
         j.kood3,
         j.kood4,
         j.kood5,
         j.proj,
         j.tunnus
       FROM cur_journal j
       WHERE j.asutusid IS NOT NULL
             AND (empty(l_asutus) OR j.asutusid = l_asutus)
             AND j.kpv >= l_kpv1
             AND j.kpv <= l_kpv2
             AND j.rekvid IN (SELECT rekv_id
                              FROM get_asutuse_struktuur(l_rekvid))
     ) qry
WHERE (empty(l_konto) OR qry.konto LIKE ltrim(rtrim(l_konto)) || '%');

$BODY$
LANGUAGE SQL VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION docs.kontoasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kontoasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kontoasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER ) TO dbkasutaja;


/*
  SELECT
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
    kpv,
    rekv_id,
    asutus_id,
    konto,
    korr_konto,
    dok,
    number,
    kood1,
    kood2,
    kood3,
    kood4,
    kood5,
    proj,
    tunnus
  FROM docs.kontoasutusandmik(null::text, NULL :: INTEGER, '2018-06-10', current_date :: DATE, 1)
*/