DROP FUNCTION IF EXISTS lapsed.get_inf3_summa(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.get_inf3_summa(l_arv_id INTEGER, l_tasu_id INTEGER)
    RETURNS NUMERIC
AS
$BODY$
WITH
    arve AS (
                SELECT
                    a.parentid    AS id,
                    sum(a1.summa) AS a1_summa,
                    a.summa       AS a_kokku
                FROM
                    docs.arv                         a
                        INNER JOIN docs.arv1         a1 ON a.id = a1.parentid
                        INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                WHERE
                      a.parentid = l_arv_id
                  AND coalesce((n.properties ->> 'kas_inf3')::BOOLEAN, FALSE)
                GROUP BY a.parentid, a.summa
    )
SELECT
    round((a1_summa / a_kokku) * at.summa * (case when at.pankkassa in (1, 2) then 1 else 0 end), 2) AS inf3_summa
FROM
    arve
        INNER JOIN docs.arvtasu at ON at.doc_arv_id = arve.id
WHERE
    at.doc_tasu_id = l_tasu_id;
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.get_inf3_summa(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_inf3_summa(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_inf3_summa(INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.get_inf3_summa(INTEGER, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.get_inf3_summa(INTEGER, INTEGER) TO arvestaja;

select lapsed.get_inf3_summa(5379629, 5473656)

/*

SELECT *
FROM lapsed.cur_lapsed
WHERE isikukood = '60903043720'

SELECT *
FROM lapsed.cur_laste_arved
WHERE laps_id = 16130

select * from docs.arvtasu where doc_arv_id = 5379629

*/