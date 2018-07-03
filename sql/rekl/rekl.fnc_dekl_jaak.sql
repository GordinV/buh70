DROP FUNCTION IF EXISTS rekl.fnc_dekl_jaak(dekl_id INTEGER );

CREATE or replace FUNCTION rekl.fnc_dekl_jaak(l_dekl_id INTEGER)
  RETURNS NUMERIC
LANGUAGE SQL
AS $$
SELECT sum(dekl) - sum(tasu) AS jaak
FROM (
       SELECT
         t.id,
         t.summa                               AS dekl,
         coalesce(qryTasud.tasu, 0) :: NUMERIC AS tasu,
         t.tyyp
       FROM docs.doc d
         INNER JOIN rekl.toiming t ON t.parentid = d.id
         LEFT OUTER JOIN (
                           SELECT
                             deklid,
                             sum(summa) AS tasu
                           FROM rekl.dekltasu
                           GROUP BY deklid
                         ) qryTasud ON qryTasud.deklid = t.id
       WHERE t.tyyp IN ('DEKL', 'INTRESS', 'PARANDUS')
             AND t.saadetud IS NOT NULL
     ) qry
WHERE id = l_dekl_id
$$;


SELECT rekl.fnc_dekl_jaak(27)