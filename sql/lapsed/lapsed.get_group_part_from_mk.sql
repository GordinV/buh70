DROP FUNCTION IF EXISTS lapsed.get_group_part_from_mk(INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.get_group_part_from_mk(l_mk_id INTEGER, l_kpv DATE DEFAULT current_date)
    RETURNS TABLE (
        mk_id   INTEGER,
        yksus   TEXT,
        summa   NUMERIC(14, 2),
        laps_id INTEGER
    ) AS
$BODY$
    -- на входе платеж
    -- ищем по карте действующие на момент платежа услуги

    -- считаем пропорцию
    -- возвращаем сумму по группам
WITH qryMk AS (
    (
        SELECT mk.parentid                          AS id,
               mk.maksepaev                         AS kpv,
               l.parentid                           AS laps_id,
               lk.properties ->> 'yksus'            AS yksus,
               (lk.properties ->> 'alg_kpv')::DATE  AS alg_kp,
               (lk.properties ->> 'lopp_kpv')::DATE AS lopp_kp,
               lk.hind,
               sum(lk.hind) OVER ()                 AS total_amount,
               mk.jaak                              AS makse_summa
        FROM docs.mk mk
                 INNER JOIN lapsed.liidestamine l ON l.docid = mk.parentid
                 LEFT OUTER JOIN lapsed.lapse_kaart lk
                                 ON lk.parentid = l.parentid
                                     AND lk.staatus <> 3
                                     AND (lk.properties ->> 'alg_kpv')::DATE <= l_kpv::DATE
                                     AND (lk.properties ->> 'lopp_kpv')::DATE >= l_kpv::DATE
                                     AND lk.rekvid = mk.rekvid
        WHERE mk.parentid = l_mk_id)
),
     -- Последняя действующая услуга
     qryViimaneTeenus AS (
         SELECT lk.properties ->> 'yksus' AS yksus,
                lk.parentid               AS laps_id
         FROM lapsed.lapse_kaart lk
                  INNER JOIN qryMk ON lk.parentid = qryMk.laps_id
         WHERE (lk.properties ->> 'lopp_kpv')::DATE <= qryMk.kpv
           AND lk.staatus <> 3
             ORDER BY lk.id DESC LIMIT 1
     ),
     -- Первая действующая услуга
     qryEsimineTeenus AS (
         SELECT lk.properties ->> 'yksus' AS yksus,
                lk.parentid               AS laps_id
         FROM lapsed.lapse_kaart lk
                  INNER JOIN qryMk ON lk.parentid = qryMk.laps_id
         WHERE (lk.properties ->> 'alg_kpv')::DATE >= qryMk.kpv
           AND lk.staatus <> 3
             ORDER BY lk.id LIMIT 1
     )
    SELECT
     qryMk.id AS mk_id,
     coalesce(qryMk.yksus, coalesce(qryViimaneTeenus.yksus, qryEsimineTeenus.yksus)) ::TEXT AS yksus,
     (coalesce((qryMk.hind / qryMk.total_amount), 1) * qryMk.makse_summa)::NUMERIC(14, 2) AS summa,
     qryMk.laps_id
    FROM
     qryMK
         LEFT OUTER JOIN qryViimaneTeenus ON qryMk.laps_id = qryViimaneTeenus.laps_id
         LEFT OUTER JOIN qryEsimineTeenus ON qryMk.laps_id = qryEsimineTeenus.laps_id


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.get_group_part_from_mk(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_group_part_from_mk(INTEGER, DATE) TO dbvaatleja;
/*


select * from lapsed.get_group_part_from_mk(2283669, '2020-09-01'::DATE)



        SELECT mk.parentid                          AS id,
               mk.maksepaev                         AS kpv,
               l.parentid                           AS laps_id,
               lk.properties ->> 'yksus'            AS yksus,
               (lk.properties ->> 'alg_kpv')::DATE  AS alg_kp,
               (lk.properties ->> 'lopp_kpv')::DATE AS lopp_kp,
               lk.hind,
               sum(lk.hind) OVER ()                 AS total_amount,
               mk.jaak                              AS makse_summa
        FROM docs.mk mk
                 INNER JOIN lapsed.liidestamine l ON l.docid = mk.parentid
                 LEFT OUTER JOIN lapsed.lapse_kaart lk
                                 ON lk.parentid = l.parentid
                                     AND lk.staatus <> 3
                                     AND (lk.properties ->> 'alg_kpv')::DATE <= '2020-09-01'::DATE
                                     AND (lk.properties ->> 'lopp_kpv')::DATE >= '2020-09-01'::DATE
                                     AND lk.rekvid = mk.rekvid
        WHERE mk.parentid = 2283669
*/