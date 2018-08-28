DROP FUNCTION IF EXISTS docs.kontoandmik( DATE, DATE, INTEGER );
DROP FUNCTION IF EXISTS docs.kontoandmik( TEXT, DATE, DATE, INTEGER );

CREATE OR REPLACE FUNCTION docs.kontoandmik(l_konto TEXT, l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER)
  RETURNS TABLE(alg_saldo  NUMERIC(14, 2),
                db_kokku   NUMERIC(14, 2),
                kr_kokku   NUMERIC(14, 2),
                rekv_id    INTEGER,
                kpv        DATE,
                deebet     NUMERIC(14, 2),
                kreedit    NUMERIC(14, 2),
                konto      VARCHAR(20),
                dok        VARCHAR(120),
                asutus     VARCHAR(254),
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
WITH qry AS (
    SELECT
      j.rekvid,
      j.kpv,
      CASE WHEN j.deebet = l_konto
        THEN j.summa
      ELSE 0 :: NUMERIC(14, 2) END AS deebet,
      CASE WHEN j.kreedit = l_konto
        THEN j.summa
      ELSE 0 :: NUMERIC(14, 2) END AS kreedit,
      CASE WHEN j.deebet = l_konto
        THEN j.kreedit
      ELSE j.deebet END            AS konto,
      j.dok,
      j.asutus,
      j.number,
      j.kood1,
      j.kood2,
      j.kood3,
      j.kood4,
      j.kood5,
      j.proj,
      j.tunnus
    FROM cur_journal j
    WHERE (j.deebet = l_konto OR j.kreedit = l_konto)
          AND kpv <= l_kpv2
          AND j.rekvid IN (SELECT rekv_id
                           FROM get_asutuse_struktuur(l_rekvid)))
SELECT
  coalesce((SELECT sum(deebet - kreedit)
            FROM qry
            WHERE kpv < l_kpv1), 0 :: NUMERIC(12, 2)) AS algsaldo,
  sum(deebet) over() as db_kokku,
  sum(kreedit) over() as kr_kokku,
  qry.*
FROM qry
WHERE qry.kpv >= l_kpv1 AND qry.kpv <= l_kpv2
$BODY$
LANGUAGE SQL VOLATILE
COST 100;

/*
SELECT *
FROM docs.kontoandmik('113', '2018-01-01', current_date :: DATE, 1)

*/