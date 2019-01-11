DROP FUNCTION IF EXISTS ladu.matkaibed_aruanne(DATE, DATE, INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION ladu.matkaibed_aruanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
                                                  l_ladu_id INTEGER, l_vara_id INTEGER)
  RETURNS TABLE(
    rekv_id INTEGER,
    ladu_id INTEGER,
    vara_id INTEGER,
    alg_jaak NUMERIC(14,4),
    alg_summa NUMERIC(14,2),
    db_kaibed NUMERIC(14,4),
    db_summa NUMERIC(14,2),
    kr_kaibed NUMERIC(14,4),
    kr_summa NUMERIC(14,2),
    lopp_jaak NUMERIC(14,4),
    lopp_summa NUMERIC(14,4)
    ) AS
$BODY$

WITH qryOper AS (
  SELECT
    a.rekvid                                                  AS rekv_id,
    a.operid                                                  AS ladu_id,
    a1.nomid                                                  AS vara_id,
    (CASE WHEN a.liik = 1 THEN a1.kogus ELSE 0 END)::NUMERIC  AS deebet,
    (CASE WHEN a.liik <> 1 THEN a1.kogus ELSE 0 END)::NUMERIC AS kreedit,
    a1.hind,
    a.kpv
  FROM docs.arv a
         INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
  WHERE (l_rekvid IS NULL OR a.rekvid = l_rekvid)
    AND a.kpv <= l_kpv2
    AND ((l_vara_id IS NULL OR l_vara_id = 0) OR a1.nomid = l_vara_id)
    AND ((l_ladu_id IS NULL OR l_ladu_id = 0) OR a.operid = l_ladu_id)
)
SELECT rekv_id,
       ladu_id,
       vara_id,
       sum(alg_jaak)                         AS alg_jaak,
       sum(alg_summa)                        AS alg_summa,
       sum(db_kaibed)                        AS db_kaibed,
       sum(db_summa)                         AS db_summa,
       sum(kr_kaibed)                        AS kr_kaibed,
       sum(kr_summa)                         AS kr_summa,
       sum(alg_jaak + db_kaibed - kr_kaibed) AS lopp_jaak,
       sum(alg_summa + db_summa - kr_summa)  AS lopp_summa
FROM (
       -- algjaak
       SELECT
         s.rekv_id,
         s.ladu_id,
         s.vara_id,
         sum(coalesce(s.deebet, 0)) - sum(coalesce(s.kreedit, 0)) AS alg_jaak,
         sum(coalesce(s.deebet, 0) * coalesce(s.hind, 0)) -
         sum(coalesce(s.kreedit, 0) * coalesce(s.hind, 0))        AS alg_summa,
         0::NUMERIC(14,4)                                         AS db_kaibed,
         0::NUMERIC(14,2)                                         AS db_summa,
         0::NUMERIC(14,4)                                         AS kr_kaibed,
         0::NUMERIC(14,2)                                         AS kr_summa
       FROM qryOper s
       WHERE s.kpv < l_kpv1
       GROUP BY rekv_id, ladu_id, vara_id
       UNION ALL
         -- kaibed
       SELECT
         s.rekv_id,
         s.ladu_id,
         s.vara_id,
         0::NUMERIC(14,4)                                             AS alg_jaak,
         0::NUMERIC(14,2)                                             AS alg_summa,
         sum(coalesce(deebet, 0))::NUMERIC(14,4)                      AS db_kaibed,
         sum(coalesce(deebet, 0) * coalesce(hind, 0))::NUMERIC(14,2)  AS db_summa,
         sum(coalesce(kreedit, 0))::NUMERIC(14,4)                     AS kr_kaibed,
         sum(coalesce(kreedit, 0) * coalesce(hind, 0))::NUMERIC(14,2) AS kr_summa
       FROM qryOper s
       WHERE s.kpv >= l_kpv1
         AND s.kpv <= l_kpv2
       GROUP BY rekv_id, ladu_id, vara_id
     ) qry
GROUP BY rekv_id, ladu_id, vara_id

$BODY$
  LANGUAGE SQL
  VOLATILE
  COST 100;

--GRANT EXECUTE ON FUNCTION ladu.matkaibed_aruanne(DATE, DATE, INTEGER,  INTEGER, INTEGER) TO dbladukasutaja;
GRANT EXECUTE ON FUNCTION ladu.matkaibed_aruanne(DATE, DATE, INTEGER, INTEGER, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION ladu.matkaibed_aruanne(DATE, DATE, INTEGER, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ladu.matkaibed_aruanne(DATE, DATE, INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;


/*
SELECT l.kood as ladu_kood, l.nimetus as ladu,
n.kood, n.nimetus, n.properties->>'grupp' as grupp,

k.*
FROM ladu.matkaibed_aruanne('2018-01-01', current_date :: DATE, 1,  null::INTEGER, null::INTEGER) k
inner join libs.library l on l.id = k.ladu_id
inner join libs.nomenklatuur n on n.id = k.vara_id
*/