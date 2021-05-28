DROP FUNCTION IF EXISTS lapsed.lapse_saldod(l_laps_Id INTEGER, l_kpv DATE);
DROP FUNCTION IF EXISTS lapsed.lapse_saldod(l_kpv DATE);
DROP FUNCTION IF EXISTS lapsed.lapse_saldod(l_kpv DATE, INTEGER);
DROP FUNCTION IF EXISTS lapsed.lapse_saldod(l_kpv DATE, INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.lapse_saldod(l_kpv DATE DEFAULT now(), l_laps_id INTEGER DEFAULT NULL,
                                               l_rekv_id INTEGER DEFAULT NULL, l_kond INTEGER DEFAULT 0)
    RETURNS TABLE (
        jaak       NUMERIC(14, 4),
        laps_id    INTEGER,
        yksus      TEXT,
        rekv_id    INTEGER,
        docs_ids   INTEGER[],
        laekumised NUMERIC(14, 4), -- всего оплат за прошлый период
        arv_tasud  NUMERIC(14, 4), -- всего оплат за прошлый период
        ettemaksud NUMERIC(14, 4), -- в.т. числе переплат
        tagastused NUMERIC(14, 4)  -- возвраты

    ) AS
$BODY$

SELECT sum(jaak)::NUMERIC(14, 4)       AS jaak,
       laps_id,
       yksus,
       rekv_id,
       array_agg(docs_id)              AS docs_ids,
       sum(laekumised)::NUMERIC(14, 4) AS laekumised,
       sum(arv_tasud)::NUMERIC(14, 4)  AS arv_tasud,
       sum(ettemaksud)::NUMERIC(14, 4) AS ettemaksud,
       sum(tagastused)::NUMERIC(14, 4) AS tagastused

FROM (
-- ettemaksud или не распределенные авансовые платежи
         SELECT CASE WHEN ymk.opt = 2 THEN -1 ELSE 1 END * ymk.summa::NUMERIC(14, 4) AS jaak, -- summa не связанных со счетами платежек (нач. сальдо или предоплата)
                l.parentid                                                           AS laps_id,
                ymk.yksus                                                            AS yksus,
                d.rekvid                                                             AS rekv_id,
                d.id                                                                 AS docs_id,
                0                                                                    AS laekumised,
                0                                                                    AS arv_tasud,
                CASE WHEN ymk.opt = 2 THEN ymk.summa ELSE 0 END ::NUMERIC(14, 4)     AS ettemaksud,
                CASE WHEN ymk.opt = 1 THEN ymk.summa ELSE 0 END ::NUMERIC(14, 4)     AS tagastused
         FROM docs.doc d
                  INNER JOIN (SELECT mk.parentid, opt
                              FROM docs.mk mk
                              WHERE mk.maksepaev < l_kpv
                                AND mk.jaak <> 0 --// поправил для оборотки 23.01.2021
                                AND (l_rekv_id IS NULL OR mk.rekvid IN (SELECT rekv_id
                                                                        FROM get_asutuse_struktuur(l_rekv_id)))
         ) mk ON mk.parentid = D.id
                  INNER JOIN lapsed.liidestamine l
                             ON l.docid = D.id,
              lapsed.get_group_part_from_mk(D.id, l_kpv) AS ymk
         WHERE D.status <> 3
           AND (l.parentid = l_laps_id OR l_laps_id IS NULL)
         UNION ALL
         -- распределенные авансовые платежи
         SELECT -1 * ((a1.summa / a.summa) * at.summa) AS jaak,
                l.parentid                             AS laps_id,
                a1.properties ->> 'yksus'              AS yksus,
                at.rekvid                              AS rekv_id,
                at.doc_tasu_id                         AS docs_id,
                0                                      AS laekumised,
                0                                      AS arv_tasud,
                0                                      AS ettemaksud,
                0                                      AS tagastused
         FROM docs.arvtasu at
                  INNER JOIN docs.arv a ON at.doc_arv_id = a.parentid
                  INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                  INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
         WHERE at.kpv < l_kpv::DATE
           AND (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
           AND (l.parentid = l_laps_id OR l_laps_id IS NULL)
           AND (l_rekv_id IS NULL OR a.rekvid IN (SELECT rekv_id
                                                  FROM get_asutuse_struktuur(l_rekv_id)))
         UNION ALL


         -- laekumised, поступления (не распределенные)
         SELECT 0                                               AS jaak,
                l.parentid                                      AS laps_id,
                ymk.yksus                                       AS yksus,
                d.rekvid                                        AS rekv_id,
                d.id                                            AS docs_id,
                CASE WHEN ymk.opt = 2 THEN ymk.summa ELSE 0 END AS laekumised,
                0                                               AS arv_tasud,
                0                                               AS ettemaksud,
                CASE WHEN ymk.opt = 1 THEN ymk.summa ELSE 0 END AS tagastused
         FROM docs.doc d,
              lapsed.get_group_part_from_mk(d.id, l_kpv) AS ymk,
              docs.mk mk,
              lapsed.liidestamine l
         WHERE mk.parentid = d.id
           AND l.docid = d.id
           AND d.status <> 3
           AND year(mk.maksepaev) = year(l_kpv - 1)
           AND month(mk.maksepaev) = month(l_kpv - 1)
           AND d.status <> 3
           AND (l.parentid = l_laps_id OR l_laps_id IS NULL)
           AND (l_rekv_id IS NULL OR mk.rekvid IN (SELECT rekv_id
                                                   FROM get_asutuse_struktuur(l_rekv_id)))

         UNION ALL
         -- распределенные авансовые платежи
         SELECT 0                                 AS jaak,
                l.parentid                        AS laps_id,
                a1.properties ->> 'yksus'         AS yksus,
                at.rekvid                         AS rekv_id,
                at.doc_tasu_id                    AS docs_id,
                0                                 AS laekumised,
                ((a1.summa / a.summa) * at.summa) AS arv_tasud,
                0                                 AS ettemaksud,
                0                                 AS tagastused
         FROM docs.arvtasu at
                  INNER JOIN docs.arv a ON at.doc_arv_id = a.parentid
                  INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                  INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
         WHERE year(at.kpv) = year(l_kpv - 1)
           AND month(at.kpv) = month(l_kpv - 1)
           AND (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
           AND (l.parentid = l_laps_id OR l_laps_id IS NULL)
           AND (l_rekv_id IS NULL OR a.rekvid IN (SELECT rekv_id
                                                  FROM get_asutuse_struktuur(l_rekv_id)))
         UNION ALL
         --jaak, arved, сумма счетов начисленных до периода
         SELECT a1.summa::NUMERIC(14, 4)    AS jaak,
                l.parentid                  AS laps_id,
                (a1.properties ->> 'yksus') AS yksus,
                a.rekvid                    AS rekv_id,
                d.id                        AS docs_id,
                0                           AS laekumised,
                0                           AS arv_tasud,
                0                           AS ettemaksud,
                0                           AS tagastused

         FROM docs.doc d
                  INNER JOIN docs.arv a ON a.parentid = d.id
                  INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
         WHERE (a.kpv < l_kpv)
           AND (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
           AND d.status <> 3
           AND (l.parentid = l_laps_id OR l_laps_id IS NULL)
           AND (l_rekv_id IS NULL OR a.rekvid IN (SELECT rekv_id
                                                  FROM get_asutuse_struktuur(l_rekv_id)))
     ) qry

--WHERE (coalesce(jaak, 0) <> 0
--    OR coalesce(laekumised, 0) <> 0
--    OR coalesce(ettemaksud, 0) <> 0)

GROUP BY qry.rekv_id, qry.laps_id, yksus

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE, INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE, INTEGER, INTEGER, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE, INTEGER, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE, INTEGER, INTEGER, INTEGER) TO arvestaja;


/*
SELECT sum(jaak) over(), *
FROM lapsed.lapse_saldod('2020-10-14'::date)
where 1=1
and laps_id = 6370
and rekv_id = 69
*/