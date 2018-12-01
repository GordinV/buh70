DROP FUNCTION IF EXISTS palk.palk_lausend( DATE, DATE, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION palk.palk_lausend(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER)
  RETURNS TABLE(
    deebet    VARCHAR(20),
    kreedit   VARCHAR(20),
    summa     NUMERIC(14, 2),
    tegev     VARCHAR(20),
    allikas   VARCHAR(20),
    rahavoog  VARCHAR(20),
    artikkel  VARCHAR(20),
    tunnus    VARCHAR(20),
    osakondid INTEGER
  ) AS
$BODY$

SELECT
  deebet :: VARCHAR(20),
  kreedit :: VARCHAR(20),
  sum(po.summa)          AS summa,
  j.kood1 :: VARCHAR(20) AS tegev,
  j.kood2 :: VARCHAR(20) AS allikas,
  j.kood3 :: VARCHAR(20) AS rahavoog,
  j.kood5 :: VARCHAR(20) AS artikkel,
  j.tunnus :: VARCHAR(20),
  t.osakondid
FROM palk.palk_oper po
  INNER JOIN palk.tooleping t ON t.id = po.lepingid
  INNER JOIN cur_journal j ON po.journalId = j.id
WHERE
  po.kpv >= l_kpv1 AND po.kpv <= l_kpv2
  AND po.rekvid = (CASE WHEN l_kond IS NOT NULL AND NOT empty(l_kond)
    THEN l_rekvid
                   ELSE po.rekvid END)
  AND po.rekvid IN (SELECT rekv_id
                    FROM get_asutuse_struktuur(l_rekvid))
GROUP BY j.kreedit, j.deebet, j.kood1, j.kood2, j.kood3, j.kood4, j.kood5, j.tunnus, t.osakondid

$BODY$
LANGUAGE SQL VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION palk.palk_lausend( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.palk_lausend( DATE, DATE, INTEGER, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.palk_lausend( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;

/*

SELECT *
FROM palk.palk_lausend('2018-01-01', '2018-12-31', 63, 1 :: INTEGER);

*/