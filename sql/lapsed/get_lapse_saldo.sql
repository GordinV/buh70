DROP FUNCTION IF EXISTS lapsed.lapse_saldod(l_laps_Id INTEGER, l_kpv DATE);
DROP FUNCTION IF EXISTS lapsed.lapse_saldod(l_kpv DATE);

CREATE OR REPLACE FUNCTION lapsed.lapse_saldod(l_kpv DATE DEFAULT now())
    RETURNS TABLE (
        jaak     NUMERIC(14, 2),
        laps_id  INTEGER,
        rekv_id  INTEGER,
        docs_ids INTEGER[]
    ) AS
$BODY$


SELECT sum(a.jaak)::NUMERIC(14, 2) AS jaak,
       l.parentid                  AS laps_id,
       a.rekvid                    AS rekv_id,
       array_agg(d.id)             AS docs_ids
FROM docs.doc d
         INNER JOIN docs.arv a ON a.parentid = d.id
         INNER JOIN lapsed.liidestamine l ON l.docid = d.id
WHERE a.kpv < l_kpv
  AND (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
  AND a.jaak <> 0
  AND d.status <> 3

GROUP BY a.rekvid, l.parentid;
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE) TO arvestaja;


/*
SELECT jaak
FROM lapsed.lapse_saldod('2019-11-27'::date)
where laps_id = 16
and rekv_id = 63
*/