--DROP FUNCTION IF EXISTS rekl.fnc_dekl_jaak(dekl_id INTEGER);

CREATE OR REPLACE FUNCTION rekl.fnc_dekl_jaak(l_dekl_id INTEGER)
  RETURNS NUMERIC
LANGUAGE SQL
AS $$
SELECT sum(coalesce(dekl, 0)) - sum(coalesce(tasu, 0)) AS jaak
FROM (SELECT t.summa AS dekl, coalesce((SELECT sum(summa)
                               FROM rekl.toiming t
                               WHERE t.tyyp = 'TASU'
                                 AND t.staatus <> 'deleted'
                                 AND t.parentid IN (SELECT unnest(d.docs_ids::integer[]))),0) AS tasu
      FROM docs.doc d
             INNER JOIN rekl.toiming t ON d.id = t.parentid
      WHERE d.id = l_dekl_id
        AND t.tyyp IN ('DEKL', 'INTRESS', 'PARANDUS')
        AND t.saadetud IS NOT NULL
        AND t.staatus <> 'deleted') qry

/*
SELECT sum(coalesce(dekl,0)) - sum(coalesce(tasu,0)) AS jaak
FROM (
       SELECT
         t.parentid as id,
         t.summa                                                                         AS dekl,
         (SELECT sum(summa)
          FROM jsonb_to_recordset((t.lisa ->> 'dekltasu') :: JSONB) AS x(summa NUMERIC)) AS tasu
       FROM rekl.toiming t
       WHERE t.tyyp IN ('DEKL', 'INTRESS', 'PARANDUS')
             AND t.saadetud IS NOT NULL
             AND t.staatus <> 'deleted'
     ) qry
WHERE id = l_dekl_id
*/
$$;

/*
SELECT rekl.fnc_dekl_jaak(1443427)

*/