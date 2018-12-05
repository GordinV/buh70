--DROP FUNCTION IF EXISTS ladu.get_stock(DATE, INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION ladu.get_stock(l_kpv DATE, l_rekvid INTEGER, l_vara_id INTEGER,
                                          l_ladu_id INTEGER)
  RETURNS TABLE(
    rekv_id INTEGER,
    ladu_id INTEGER,
    vara_id INTEGER,
    kogus NUMERIC(14,4),
    hind NUMERIC(14,2),
    doc_ids INTEGER[]

    ) AS
$BODY$

WITH qrySisse AS (
  SELECT
    a.rekvid        AS rekv_id,
    a.operid        AS ladu_id,
    a1.nomid        AS vara_id,
    sum(a1.kogus)   AS deebet,
    array_agg(a.parentid) AS doc_ids,
    a1.hind
  FROM docs.arv a
         INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
  WHERE a.liik = 1 -- приход
    AND (l_rekvid is null or a.rekvid = l_rekvid)
    AND a.kpv <= l_kpv
    AND (l_vara_id IS NULL OR a1.nomid = l_vara_id)
    AND (l_ladu_id IS NULL OR a.operid = l_ladu_id)
  GROUP BY a.rekvid, a.operid, a1.nomid, a1.hind
)
SELECT
  s.rekv_id,
  s.ladu_id,
  s.vara_id,
  s.deebet - coalesce(v.kreedit, 0) AS kogus,
  s.hind,
  s.doc_ids

FROM qrySisse s
       INNER JOIN libs.nomenklatuur vara ON s.vara_id = vara.id AND vara.dok = 'VARA'
       LEFT OUTER JOIN (
    SELECT
      a.rekvid      AS rekv_id,
      a.operid      AS ladu_id,
      a1.nomid      AS vara_id,
      sum(a1.kogus) AS kreedit
    FROM docs.arv a
           INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
    WHERE a.liik = 0 -- приход
      AND (l_rekvid is null or a.rekvid = l_rekvid)
      AND a.kpv <= l_kpv
      AND (l_vara_id IS NULL OR a1.nomid = l_vara_id)
      AND (l_ladu_id IS NULL OR a.operid = l_ladu_id)
    GROUP BY a.rekvid, a.operid, a1.nomid, a1.hind
  ) v ON s.ladu_id = v.ladu_id
    AND s.vara_id = v.vara_id
    AND s.rekv_id = v.rekv_id;


$BODY$
  LANGUAGE SQL
  VOLATILE
  COST 100;


GRANT EXECUTE ON FUNCTION ladu.get_stock(DATE, INTEGER, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ladu.get_stock(DATE, INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION ladu.get_stock(DATE, INTEGER, INTEGER, INTEGER) TO ladukasutaja;
GRANT EXECUTE ON FUNCTION ladu.get_stock(DATE, INTEGER, INTEGER, INTEGER) TO dbvaatleja;

DROP INDEX IF EXISTS libs.idx_nom_vara;
CREATE INDEX idx_nom_vara ON libs.nomenklatuur
  USING BTREE (id)
  WHERE dok = 'VARA';


/*

SELECT *
FROM ladu.get_stock(current_date, 1, null, null)

*/