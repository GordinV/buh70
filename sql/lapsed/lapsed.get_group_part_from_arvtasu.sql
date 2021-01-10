DROP FUNCTION IF EXISTS lapsed.get_group_part_from_arvtasu(INTEGER);

CREATE OR REPLACE FUNCTION lapsed.get_group_part_from_arvtasu(l_arvtasu_id INTEGER)
    RETURNS TABLE (
        arv_id   INTEGER,
        yksus   TEXT,
        summa   NUMERIC(14, 2),
        laps_id INTEGER
    ) AS
$BODY$
    -- на входе платеж
    -- ищем по карте действующие на момент платежа услуги

    -- считаем пропорцию
    -- возвращаем сумму по группам
WITH qryArvTasu AS (
    (
        SELECT mk.parentid                                                      AS id,
               l.parentid                                                       AS laps_id,
               lk.properties ->> 'yksus'                                        AS yksus,
               (lk.properties ->> 'alg_kpv')::DATE                              AS alg_kp,
               (lk.properties ->> 'lopp_kpv')::DATE                             AS lopp_kp,
               lk.hind,
               sum(lk.hind) OVER ()                                             AS total_amount,
               (SELECT sum(summa) FROM docs.mk1 mk1 WHERE mk1.parentid = mk.id) AS makse_summa
        FROM docs.arvtasu at
                 INNER JOIN docs.arv a ON a.parentid = at.doc_arv_id
        WHERE at.id = l_arvtasu_id)
)
SELECT qryArvTasu.id                                                                AS mk_id,
       qryArvTasu.yksus::TEXT,
       ((qryArvTasu.hind / qryArvTasu.total_amount) * qryArvTasu.makse_summa)::NUMERIC(14, 2) AS summa,
       qryArvTasu.laps_id
FROM qryArvTasu


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.get_group_part_from_arvtasu(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_group_part_from_arvtasu(INTEGER, DATE) TO dbvaatleja;
/*


select * from lapsed.get_group_part_from_arvtasu(87857, '2020-09-01'::DATE)

87857
87858

*/