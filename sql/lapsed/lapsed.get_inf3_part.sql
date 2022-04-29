DROP FUNCTION IF EXISTS lapsed.get_inf3_part(INTEGER);

CREATE OR REPLACE FUNCTION lapsed.get_inf3_part(l_arvtasu_id INTEGER)
    RETURNS NUMERIC
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_summa NUMERIC = 0;
BEGIN
    -- на входе платеж
    -- ищем в счета inf3 услуги и считаем их долю
    l_summa = (SELECT round(inf3_summa / summa * makse_summa, 2)
               FROM (
                        SELECT sum(a1.summa) OVER ()                   AS inf3_summa,
                               a.summa,
                               at.summa                                AS makse_summa,
                               CASE WHEN mk.opt = 1 THEN -1 ELSE 1 END AS mk_tyyp_muudatus -- если возврат, то сумма inf3 идет с минусом
                        FROM docs.arvtasu at
                                 INNER JOIN docs.arv a ON a.parentid = at.doc_arv_id
                                 INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                                 INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                                 INNER JOIN docs.mk mk ON mk.parentid = at.doc_tasu_id
                        WHERE at.id = l_arvtasu_id
                          AND coalesce((n.properties ->> 'kas_inf3')::BOOLEAN, FALSE)
                          AND at.pankkassa < 3
                        LIMIT 1
                    ) qry);


    RETURN l_summa;
END;
$$;


GRANT EXECUTE ON FUNCTION lapsed.get_inf3_part(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_inf3_part(INTEGER) TO dbvaatleja;

SELECT lapsed.get_inf3_part(102054)
