DROP FUNCTION IF EXISTS palk.palk_kokku( DATE, DATE, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION palk.palk_kokku(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER)
  RETURNS TABLE(
    nimetus   VARCHAR(254),
    summa     NUMERIC(14, 2),
    liik      CHAR(1),
    lib_id    INTEGER,
    rekv_id   INTEGER,
    isik_id   INTEGER,
    isikukood VARCHAR(20),
    isik      VARCHAR(254),
    konto varchar(20)
  ) AS
$BODY$

SELECT
  po.nimetus :: VARCHAR(254),
  sum(po.summa) :: NUMERIC(14, 2) AS summa,
  po.liik :: CHAR(1),
  po.libId :: INTEGER,
  po.rekvid :: INTEGER,
  po.isikid :: INTEGER,
  po.isikukood :: VARCHAR(20),
  po.isik :: VARCHAR(254),
  po.konto :: VARCHAR(20)
FROM palk.cur_palkoper po
WHERE
  po.kpv >= l_kpv1 AND po.kpv <= l_kpv2
  AND po.rekvid = (CASE WHEN l_kond IS NOT NULL AND NOT empty(l_kond)
    THEN l_rekvid
                   ELSE po.rekvid END)
  AND po.rekvid IN (SELECT rekv_id
                    FROM get_asutuse_struktuur(l_rekvid))
GROUP BY po.rekvid, po.nimetus, po.liik, po.libId, po.isikid, po.isikukood, po.isik, po.konto

$BODY$
LANGUAGE SQL VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION palk.palk_kokku( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.palk_kokku( DATE, DATE, INTEGER, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.palk_kokku( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;


/*

SELECT *
FROM palk.palk_kokku('2018-01-01', '2018-01-31', 63, 1 :: INTEGER);

*/