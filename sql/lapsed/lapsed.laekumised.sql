DROP FUNCTION IF EXISTS lapsed.laekumised(INTEGER, DATE, DATE);

CREATE OR REPLACE FUNCTION lapsed.laekumised(l_rekvid INTEGER,
                                             kpv_start DATE DEFAULT date(year(current_date), 1, 1),
                                             kpv_end DATE DEFAULT current_date)
    RETURNS TABLE (
        doc_id  INTEGER,
        summa   NUMERIC(14, 4),
        kpv     DATE,
        yksus   TEXT,
        laps_id INTEGER,
        rekv_id INTEGER
    ) AS
$BODY$

-- распределенные платежи
WITH arvtasu AS (
    SELECT at.doc_tasu_id, sum(summa) AS summa, kpv, yksus, laps_id, rekv_id
    FROM (
             SELECT at.doc_tasu_id,
                    ((a1.summa / a.summa) * AT.summa) AS summa,
                    at.kpv,
                    a1.properties ->> 'yksus'         AS yksus,
                    laps.id                           AS laps_id,
                    a.rekvid                          AS rekv_id,
                    a.asutusid                        AS asutus_id
             FROM docs.arvtasu at
                      INNER JOIN docs.arv a ON a.parentid = at.doc_arv_id
                      INNER JOIN docs.doc d ON d.id = a.parentid
                      INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                      INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
                      INNER JOIN lapsed.laps laps ON laps.id = l.parentid
             WHERE a.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
               AND at.kpv >= kpv_start
               AND at.kpv <= kpv_end
               AND d.status <> 3
               AND (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
         ) at
    GROUP BY doc_tasu_id, kpv, yksus, laps_id, rekv_id
),
     ettemaksud AS (
         SELECT mk.id AS doc_tasu_id, ymk.summa, mk.kpv, ymk.yksus, ymk.laps_id, mk.rekvid
         FROM lapsed.cur_lapsed_mk mk
                  INNER JOIN lapsed.get_group_part_from_mk(mk.id, '2020-12-31') ymk ON ymk.mk_id = mk.id

         WHERE mk.rekvid IN (SELECT rekv_id
                             FROM get_asutuse_struktuur(l_rekvid))
           AND mk.maksepaev >= kpv_start
           AND mk.maksepaev <= kpv_end
           AND mk.jaak <> 0
     )
SELECT qry.doc_tasu_id, sum(summa) AS summa, kpv, yksus, laps_id, rekv_id
FROM (
         SELECT *
         FROM arvtasu
         UNION ALL
         SELECT *
         FROM ettemaksud
     ) qry
GROUP BY doc_tasu_id, kpv, laps_id, rekv_id, yksus


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.laekumised(INTEGER, DATE, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.laekumised(INTEGER, DATE, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.laekumised(INTEGER, DATE, DATE) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.laekumised(INTEGER, DATE, DATE) TO dbvaatleja;


/*
select * from lapsed.laekumised(69, DATE(2020,10,01), DATE(2020,10,31)) where laps_id = 6370

*/
