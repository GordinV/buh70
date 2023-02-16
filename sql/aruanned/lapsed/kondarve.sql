DROP FUNCTION IF EXISTS lapsed.kondarve(INTEGER, DATE, DATE);

CREATE OR REPLACE FUNCTION lapsed.kondarve(l_rekvid INTEGER,
                                           kpv_start DATE DEFAULT date(year(current_date), 1, 1),
                                           kpv_end DATE DEFAULT current_date)
    RETURNS TABLE (
        period       DATE,
        parameter    TEXT,
        rekvid       INTEGER,
        summa        NUMERIC(14, 2),
        summa_322000 NUMERIC(14, 2),
        summa_322020 NUMERIC(14, 2),
        summa_322030 NUMERIC(14, 2),
        summa_322040 NUMERIC(14, 2),
        konto        TEXT,
        nimetus      TEXT
    )
AS
$BODY$

WITH qryPeriod AS (
    SELECT CASE
               WHEN kpv_start IS NULL OR empty(kpv_start::TEXT) THEN date(year(current_date), 1, 1)
               ELSE kpv_start END::DATE AS kpv_start,
           CASE
               WHEN kpv_end IS NULL OR empty(kpv_end::TEXT) THEN date(year(current_date), 12, 31)
               ELSE kpv_end END::DATE   AS kpv_end
),
     rekv_ids AS (
         SELECT rekv_id
         FROM public.get_asutuse_struktuur(l_rekvid)),
     docs_types AS (
         SELECT id, kood FROM libs.library WHERE library.library = 'DOK' AND kood IN ('ARV')
     )
SELECT qry.*, r.nimetus::text
FROM (
         SELECT qryPeriod.kpv_start                                              AS period,
                (to_char(qryPeriod.kpv_start, 'DD.MM.YYYY') || ' - ' ||
                 to_char(qryPeriod.kpv_end, 'DD.MM.YYYY'))::TEXT                 AS parameter,
                d.rekvid,
                sum(a1.summa)::NUMERIC(14, 2)                                    AS summa,
                sum(a1.summa) FILTER (WHERE a1.konto = '322000')::NUMERIC(14, 2) AS summa_322000,
                sum(a1.summa) FILTER (WHERE a1.konto = '322020')::NUMERIC(14, 2) AS summa_322020,
                sum(a1.summa) FILTER (WHERE a1.konto = '322030')::NUMERIC(14, 2) AS summa_322030,
                sum(a1.summa) FILTER (WHERE a1.konto = '322020')::NUMERIC(14, 2) AS summa_322040,
                a1.konto::TEXT
         FROM docs.doc d
                  INNER JOIN docs.arv a ON a.parentid = d.id
                  INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id,
              qryPeriod
         WHERE a.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND d.doc_type_id IN (SELECT id FROM docs_types)

           AND coalesce((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
           AND (a.kpv >= qryPeriod.kpv_start AND a.kpv <= qryPeriod.kpv_end)
         GROUP BY a1.konto, d.rekvid, qryPeriod.kpv_start, qryPeriod.kpv_end
     ) qry
         INNER JOIN ou.rekv r ON r.id = qry.rekvid
ORDER BY r.nimetus, qry.konto
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
FROM lapsed.kondarve(119, '2023-01-01', '2023-01-31')
) qry
where  period  >=  '2019-11-01' and period  <=  '2019-12-31'

*/
