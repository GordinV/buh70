DROP FUNCTION IF EXISTS lapsed.get_group_part_from_mk(INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.get_group_part_from_mk(l_mk_id INTEGER, l_kpv DATE DEFAULT current_date)
    RETURNS TABLE (
        mk_id   INTEGER,
        yksus   TEXT,
        summa   NUMERIC(14, 4),
        laps_id INTEGER,
        opt     INTEGER

    )
AS
$BODY$
    -- на входе платеж
    -- ищем по карте действующие на момент платежа услуги

    -- считаем пропорцию
    -- возвращаем сумму по группам
WITH qryMk AS (
    SELECT mk.parentid          AS id,
           mk.maksepaev         AS kpv,
           l.parentid           AS laps_id,
           yksus,
           lk.hind,
           sum(lk.hind) OVER () AS total_amount,
           lk.count,
           mk.jaak              AS makse_summa,
           mk.rekvid,
           mk.opt
    FROM docs.mk mk
             INNER JOIN lapsed.liidestamine l ON l.docid = mk.parentid

             LEFT OUTER JOIN (SELECT lk.parentid,
                                     lk.rekvid,
                                     lk.properties ->> 'yksus' AS yksus,
                                     sum(lk.hind)              AS hind,
                                     count(*) over(PARTITION BY (parentid::text || '-' || lk.rekvid::text )) as count
                              FROM lapsed.lapse_kaart lk
                              WHERE lk.staatus <> 3
                                AND (lk.properties ->> 'alg_kpv')::DATE <= l_kpv::DATE
                                AND (lk.properties ->> 'lopp_kpv')::DATE >= l_kpv::DATE
                              GROUP BY lk.parentid, lk.rekvid, (lk.properties ->> 'yksus')
    ) lk
                             ON lk.parentid = l.parentid
                                 AND lk.rekvid = mk.rekvid

    WHERE mk.parentid = l_mk_id
),
     -- Последняя действующая услуга
     qryViimaneTeenus AS (
         SELECT lk.properties ->> 'yksus' AS yksus,
                lk.parentid               AS laps_id
         FROM lapsed.lapse_kaart lk
                  INNER JOIN qryMk ON lk.parentid = qryMk.laps_id
         WHERE lk.staatus <> 3
           AND lk.rekvid = qryMk.rekvid
         ORDER BY (lk.properties ->> 'lopp_kpv')::DATE DESC
         LIMIT 1
     ),
     -- Первая действующая услуга
     qryEsimineTeenus AS (
         SELECT lk.properties ->> 'yksus' AS yksus,
                lk.parentid               AS laps_id
         FROM lapsed.lapse_kaart lk
                  INNER JOIN qryMk ON lk.parentid = qryMk.laps_id
         WHERE lk.staatus <> 3
           AND lk.rekvid = qryMk.rekvid
         ORDER BY (lk.properties ->> 'alg_kpv')::DATE
         LIMIT 1
     ),
     qryLaekumised AS (
         SELECT qryMk.id                                                                               AS mk_id,
                coalesce(qryMk.yksus, coalesce(qryViimaneTeenus.yksus, qryEsimineTeenus.yksus)) ::TEXT AS yksus,
                CASE
                    WHEN qryMk.total_amount = 0 THEN qryMk.makse_summa / qryMk.count
                    ELSE ((coalesce((qryMk.hind /
                                     CASE WHEN qryMk.total_amount = 0 THEN NULL ELSE qryMk.total_amount END), 1) *
                           qryMk.makse_summa)) END::NUMERIC(14, 4)                                     AS summa,
                qryMk.laps_id,
                qryMk.opt
         FROM qryMK
                  LEFT OUTER JOIN qryViimaneTeenus ON qryMk.laps_id = qryViimaneTeenus.laps_id
                  LEFT OUTER JOIN qryEsimineTeenus ON qryMk.laps_id = qryEsimineTeenus.laps_id
     )
SELECT mk_id, yksus, sum(summa) AS summa, laps_id, opt
FROM qryLaekumised
GROUP BY yksus, laps_id, mk_id, opt


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.get_group_part_from_mk(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_group_part_from_mk(INTEGER, DATE) TO dbvaatleja;
/*


select * from lapsed.get_group_part_from_mk(2329755, '2021-01-01'::DATE)



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