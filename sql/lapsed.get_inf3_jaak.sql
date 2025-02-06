DROP FUNCTION IF EXISTS lapsed.get_inf3_jaak(INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.get_inf3_jaak(l_arv_id INTEGER, l_kpv DATE)
    RETURNS NUMERIC
AS
$BODY$
WITH arve AS (
    SELECT a.parentid    AS id,
           sum(a1.summa) AS a1_summa,
           a.summa       AS a_kokku
    FROM docs.arv a
             INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
             INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
    WHERE a.parentid = l_arv_id
      AND coalesce((n.properties ->> 'kas_inf3')::BOOLEAN, FALSE)
      AND a.summa > 0
    GROUP BY a.parentid, a.summa
),
     tasud AS (
         SELECT sum(summa) AS summa,
                sum(case when at.pankkassa = 4 then 0 else 1 end * summa) as ilma_kreedit_arvedeta
         FROM docs.arvtasu at
         WHERE at.doc_arv_id = l_arv_id
           AND at.kpv <= l_kpv
           AND at.status < 3),
     pre_arv AS (
         SELECT (a.a_kokku - coalesce(t.summa, 0)) AS jaak,
                (a.a_kokku - coalesce(t.ilma_kreedit_arvedeta, 0)) as jaak_ilma_kreedit_arvedeta,
                a.a1_summa / a.a_kokku             AS inf3_osa
         FROM arve a,
              tasud t)
SELECT round(jaak_ilma_kreedit_arvedeta * inf3_osa, 2) AS inf3_jaak
FROM pre_arv
$BODY$ LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.get_inf3_jaak(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_inf3_jaak(INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_inf3_jaak(INTEGER, DATE) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.get_inf3_jaak(INTEGER, DATE) TO arvestaja;

--SELECT lapsed.get_inf3_jaak(5381068, current_date)

/*

SELECT *
FROM lapsed.cur_lapsed
WHERE isikukood = '60903043720'

SELECT *
FROM lapsed.cur_laste_arved
WHERE laps_id = 16130

select * from docs.arvtasu where doc_arv_id = 5379629

*/