DROP FUNCTION IF EXISTS lapsed.lapse_saldod(l_laps_Id INTEGER, l_kpv DATE);
DROP FUNCTION IF EXISTS lapsed.lapse_saldod(l_kpv DATE);

CREATE OR REPLACE FUNCTION lapsed.lapse_saldod(l_kpv DATE DEFAULT now())
    RETURNS TABLE (
        jaak       NUMERIC(14, 2),
        laps_id    INTEGER,
        rekv_id    INTEGER,
        docs_ids   INTEGER[],
        laekumised NUMERIC(14, 2), -- всего оплат за прошлый период
        ettemaksud NUMERIC(14, 2)  -- в.т. числе переплат
    ) AS
$BODY$

SELECT sum(jaak)          AS jaak,
       laps_id,
       rekv_id,
       array_agg(docs_id) AS docs_ids,
       sum(laekumised)    AS laekumised,
       sum(ettemaksud)    AS ettemaksud
FROM (
         SELECT a.jaak::NUMERIC(14, 2) AS jaak,
                l.parentid             AS laps_id,
                a.rekvid               AS rekv_id,
                d.id                   AS docs_id,
                0                      AS laekumised,
                0                      AS ettemaksud
         FROM docs.doc d
                  INNER JOIN docs.arv a ON a.parentid = d.id
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
         WHERE a.kpv < l_kpv
           AND (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
           AND a.jaak <> 0
           AND d.status <> 3
         UNION ALL
-- ettemaksud
         SELECT -1 * mk1.summa::NUMERIC(14, 2) AS jaak,
                l.parentid                     AS laps_id,
                d.rekvid                       AS rekv_id,
                d.id                           AS docs_id,
                0                              AS laekumised,
                0                              AS ettemaksud
         FROM docs.doc d
                  INNER JOIN docs.mk mk ON mk.parentid = d.id
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                  INNER JOIN docs.mk1 mk1 ON mk1.parentid = mk.id
         WHERE mk.kpv < l_kpv
           AND (mk.arvid IS NULL OR mk.arvid = 0)
           AND d.status <> 3
         UNION ALL
         SELECT 0          AS jaak,
                l.parentid AS laps_id,
                d.rekvid   AS rekv_id,
                d.id       AS docs_id,
                mk1.summa  AS laekumised,
                0          AS ettemaksud
         FROM docs.doc d
                  INNER JOIN docs.mk mk ON mk.parentid = d.id
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                  INNER JOIN docs.mk1 mk1 ON mk1.parentid = mk.id
         WHERE (year(mk.kpv) * 100 + month(mk.kpv)) = year(make_date(year(l_kpv), month(l_kpv), 1)::DATE - 1) * 100 +
                                                      month(make_date(year(l_kpv), month(l_kpv), 1)::DATE - 1)
           AND d.status <> 3
         UNION ALL
         SELECT 0          AS jaak,
                l.parentid AS laps_id,
                d.rekvid   AS rekv_id,
                d.id       AS docs_id,
                0          AS laekumised,
                mk1.summa  AS ettemaksud
         FROM docs.doc d
                  INNER JOIN docs.mk mk ON mk.parentid = d.id
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                  INNER JOIN docs.mk1 mk1 ON mk1.parentid = mk.id
         WHERE mk.kpv < l_kpv
           AND (mk.arvid IS NULL OR mk.arvid = 0)
           AND d.status <> 3
     ) qry
GROUP BY qry.rekv_id, qry.laps_id

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