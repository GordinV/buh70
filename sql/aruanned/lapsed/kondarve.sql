DROP FUNCTION IF EXISTS lapsed.kondarve(INTEGER, DATE, DATE);

CREATE OR REPLACE FUNCTION lapsed.kondarve(l_rekvid INTEGER,
                                           kpv_start DATE DEFAULT date(year(current_date), 1, 1),
                                           kpv_end DATE DEFAULT current_date)
    RETURNS TABLE (
        period    DATE,
        parameter TEXT,
        rekvid    INTEGER,
        kood      TEXT,
        summa     NUMERIC(14, 2),
        konto     TEXT
    ) AS
$BODY$

WITH qryPeriod AS (
    SELECT CASE
               WHEN kpv_start IS NULL OR empty(kpv_start::TEXT) THEN date(year(current_date), 1, 1)
               ELSE kpv_start END::DATE AS kpv_start,
           CASE
               WHEN kpv_end IS NULL OR empty(kpv_end::TEXT) THEN date(year(current_date), 12, 31)
               ELSE kpv_end END::DATE   AS kpv_end
)
SELECT qryPeriod.kpv_start                                                                                     AS period,
       (to_char(qryPeriod.kpv_start, 'DD.MM.YYYY') || ' - ' ||
        to_char(qryPeriod.kpv_end, 'DD.MM.YYYY'))::TEXT                                                        AS parameter,
       d.rekvid,
       n.kood::TEXT                                                                                            AS kood,
       sum(a1.summa)                                                                                           AS summa,
       a1.konto::TEXT
FROM docs.doc d
         INNER JOIN docs.arv a ON a.parentid = d.id
         INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
         INNER JOIN lapsed.liidestamine l ON l.docid = d.id
         INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid,
     qryPeriod
WHERE a.rekvid IN (SELECT rekv_id
                   FROM get_asutuse_struktuur($1))

  AND coalesce((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
  AND d.rekvid IN (SELECT rekv_id
                   FROM get_asutuse_struktuur(l_rekvid))
  AND (a.kpv >= qryPeriod.kpv_start AND a.kpv <= qryPeriod.kpv_end)
GROUP BY n.kood, a1.konto, d.rekvid, qryPeriod.kpv_start, qryPeriod.kpv_end

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.kondarve(INTEGER, DATE, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.kondarve(INTEGER, DATE, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.kondarve(INTEGER, DATE, DATE) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.kondarve(INTEGER, DATE, DATE) TO dbvaatleja;


/*
select * from (
SELECT *
FROM lapsed.kondarve(63, null, null)
) qry
where  period  >=  '2019-11-01' and period  <=  '2019-12-31'

*/
