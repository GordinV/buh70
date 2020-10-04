DROP FUNCTION IF EXISTS lapsed.lapse_saldod(l_laps_Id INTEGER, l_kpv DATE);
DROP FUNCTION IF EXISTS lapsed.lapse_saldod(l_kpv DATE);

CREATE OR REPLACE FUNCTION lapsed.lapse_saldod(l_kpv DATE DEFAULT now())
    RETURNS TABLE (
        jaak       NUMERIC(14, 2),
        laps_id    INTEGER,
        yksus      TEXT,
        rekv_id    INTEGER,
        docs_ids   INTEGER[],
        laekumised NUMERIC(14, 2), -- всего оплат за прошлый период
        ettemaksud NUMERIC(14, 2)  -- в.т. числе переплат
    ) AS
$BODY$

SELECT sum(jaak)::NUMERIC(14, 2)       AS jaak,
       laps_id,
       yksus,
       rekv_id,
       array_agg(docs_id)              AS docs_ids,
       sum(laekumised)::NUMERIC(14, 2) AS laekumised,
       sum(ettemaksud)::NUMERIC(14, 2) AS ettemaksud
FROM (
-- ettemaksud
         SELECT 0::NUMERIC(14, 2)         AS jaak,
                l.parentid                AS laps_id,
                ymk.yksus                 AS yksus,
                d.rekvid                  AS rekv_id,
                d.id                      AS docs_id,
                0                         AS laekumised,
                ymk.summa::NUMERIC(14, 2) AS ettemaksud
         FROM docs.doc d,
              lapsed.get_group_part_from_mk(d.id, l_kpv) AS ymk,
              docs.mk mk,
              lapsed.liidestamine l
         WHERE mk.parentid = d.id
           AND mk.maksepaev < l_kpv
           AND l.docid = d.id
           AND (mk.arvid IS NULL OR mk.arvid = 0)
           AND d.status <> 3
         UNION ALL
         SELECT 0          AS jaak,
                l.parentid AS laps_id,
                ymk.yksus  AS yksus,
                d.rekvid   AS rekv_id,
                d.id       AS docs_id,
                ymk.summa  AS laekumised,
                0          AS ettemaksud
         FROM docs.doc d,
              lapsed.get_group_part_from_mk(d.id, l_kpv) AS ymk,
              docs.mk mk,
              lapsed.liidestamine l
         WHERE mk.parentid = d.id
           AND l.docid = d.id
           AND d.status <> 3
           AND (year(mk.maksepaev) * 100 + month(mk.maksepaev)) =
               year(make_date(year(l_kpv), month(l_kpv), 1)::DATE - 1) * 100 +
               month(make_date(year(l_kpv), month(l_kpv), 1)::DATE - 1)
           AND d.status <> 3
         UNION ALL
         -- jaak, maksed
         SELECT -1 * ymk.summa AS jaak,
                l.parentid     AS laps_id,
                ymk.yksus      AS yksus,
                d.rekvid       AS rekv_id,
                d.id           AS docs_id,
                0              AS laekumised,
                0              AS ettemaksud
         FROM docs.doc d,
              lapsed.get_group_part_from_mk(d.id, l_kpv) AS ymk,
              docs.mk mk,
              lapsed.liidestamine l
         WHERE mk.parentid = d.id
           AND mk.maksepaev < l_kpv
           AND l.docid = d.id
           AND d.status <> 3
         UNION ALL
         --jaak, arved
         SELECT a1.summa::NUMERIC(14, 2)    AS jaak,
                l.parentid                  AS laps_id,
                (a1.properties ->> 'yksus') AS yksus,
                a.rekvid                    AS rekv_id,
                d.id                        AS docs_id,
                0                           AS laekumised,
                0                           AS ettemaksud
         FROM docs.doc d
                  INNER JOIN docs.arv a ON a.parentid = d.id
                  INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
         WHERE (a.kpv < l_kpv)
           AND (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
           AND d.status <> 3
     ) qry
GROUP BY qry.rekv_id, qry.laps_id, yksus

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE) TO arvestaja;


/*
SELECT *
FROM lapsed.lapse_saldod('2020-09-01'::date)
where laps_id = 11748
and rekv_id = 69
*/