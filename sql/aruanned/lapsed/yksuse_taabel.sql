DROP FUNCTION IF EXISTS lapsed.yksuse_taabel(JSONB, INTEGER);
DROP FUNCTION IF EXISTS lapsed.yksuse_taabel(INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.yksuse_taabel(INTEGER, INTEGER, INTEGER, DATE, DATE);

CREATE OR REPLACE FUNCTION lapsed.yksuse_taabel(l_rekvid INTEGER, l_kuu INTEGER DEFAULT month(current_date),
                                                 l_aasta INTEGER DEFAULT year(current_date), l_kpv1 DATE DEFAULT NULL,
                                                 l_kpv2 DATE DEFAULT NULL)
    RETURNS TABLE (
        rekv_id   INTEGER,
        asutus    TEXT,
        yksus     TEXT,
        nom_id    INTEGER,
        teenus    TEXT,
        isikukood TEXT,
        nimi      TEXT,
        viitenr   TEXT,
        kuu       INTEGER,
        aasta     INTEGER,
        kogus     INTEGER,
        day_1     INTEGER,
        day_2     INTEGER,
        day_3     INTEGER,
        day_4     INTEGER,
        day_5     INTEGER,
        day_6     INTEGER,
        day_7     INTEGER,
        day_8     INTEGER,
        day_9     INTEGER,
        day_10    INTEGER,
        day_11    INTEGER,
        day_12    INTEGER,
        day_13    INTEGER,
        day_14    INTEGER,
        day_15    INTEGER,
        day_16    INTEGER,
        day_17    INTEGER,
        day_18    INTEGER,
        day_19    INTEGER,
        day_20    INTEGER,
        day_21    INTEGER,
        day_22    INTEGER,
        day_23    INTEGER,
        day_24    INTEGER,
        day_25    INTEGER,
        day_26    INTEGER,
        day_27    INTEGER,
        day_28    INTEGER,
        day_29    INTEGER,
        day_30    INTEGER,
        day_31    INTEGER,
        week_ends INTEGER[],
        men_count INTEGER

    )
AS
$BODY$
SELECT qry.rekv_id,
       r.nimetus::TEXT                                                     AS asutus,
       l.nimetus::TEXT                                                     AS yksus,
       n.id                                                                AS nom_id,
       coalesce((l.properties::JSONB ->> 'luno')::TEXT, n.kood)::TEXT      AS teenus,
       laps.isikukood::TEXT                                                AS isikukood,
       laps.nimi::TEXT                                                     AS nimi,
       lapsed.get_viitenumber(qry.rekv_id, laps.id)::TEXT                  AS viitenr,
       coalesce(l_kuu, month(current_date))::INTEGER                       AS kuu,
       coalesce(l_aasta, year(current_date))::INTEGER                      AS aasta,
       (coalesce(qry.day_1, 0) +
        coalesce(qry.day_2, 0) +
        coalesce(qry.day_3, 0) +
        coalesce(qry.day_4, 0) +
        coalesce(qry.day_5, 0) +
        coalesce(qry.day_6, 0) +
        coalesce(qry.day_7, 0) +
        coalesce(qry.day_8, 0) +
        coalesce(qry.day_9, 0) +
        coalesce(qry.day_10, 0) +
        coalesce(qry.day_11, 0) +
        coalesce(qry.day_12, 0) +
        coalesce(qry.day_13, 0) +
        coalesce(qry.day_14, 0) +
        coalesce(qry.day_15, 0) +
        coalesce(qry.day_16, 0) +
        coalesce(qry.day_17, 0) +
        coalesce(qry.day_18, 0) +
        coalesce(qry.day_19, 0) +
        coalesce(qry.day_20, 0) +
        coalesce(qry.day_21, 0) +
        coalesce(qry.day_22, 0) +
        coalesce(qry.day_23, 0) +
        coalesce(qry.day_24, 0) +
        coalesce(qry.day_25, 0) +
        coalesce(qry.day_26, 0) +
        coalesce(qry.day_27, 0) +
        coalesce(qry.day_28, 0) +
        coalesce(qry.day_29, 0) +
        coalesce(qry.day_30, 0) +
        coalesce(qry.day_31, 0)
           )::INTEGER                                                      AS kogus,
       qry.day_1::INTEGER                                                  AS day_1,
       qry.day_2::INTEGER                                                  AS day_2,
       qry.day_3::INTEGER                                                  AS day_3,
       qry.day_4::INTEGER                                                  AS day_4,
       qry.day_5::INTEGER                                                  AS day_5,
       qry.day_6::INTEGER                                                  AS day_6,
       qry.day_7::INTEGER                                                  AS day_7,
       qry.day_8::INTEGER                                                  AS day_8,
       qry.day_9::INTEGER                                                  AS day_9,
       qry.day_10::INTEGER                                                 AS day_10,
       qry.day_11::INTEGER                                                 AS day_11,
       qry.day_12::INTEGER                                                 AS day_12,
       qry.day_13::INTEGER                                                 AS day_13,
       qry.day_14::INTEGER                                                 AS day_14,
       qry.day_15::INTEGER                                                 AS day_15,
       qry.day_16::INTEGER                                                 AS day_16,
       qry.day_17::INTEGER                                                 AS day_17,
       qry.day_18::INTEGER                                                 AS day_18,
       qry.day_19::INTEGER                                                 AS day_19,
       qry.day_20::INTEGER                                                 AS day_20,
       qry.day_21::INTEGER                                                 AS day_21,
       qry.day_22::INTEGER                                                 AS day_22,
       qry.day_23::INTEGER                                                 AS day_23,
       qry.day_24::INTEGER                                                 AS day_24,
       qry.day_25::INTEGER                                                 AS day_25,
       qry.day_26::INTEGER                                                 AS day_26,
       qry.day_27::INTEGER                                                 AS day_27,
       qry.day_28::INTEGER                                                 AS day_28,
       qry.day_29::INTEGER                                                 AS day_29,
       qry.day_30::INTEGER                                                 AS day_30,
       qry.day_31::INTEGER                                                 AS day_31,
       get_week_ends(COALESCE(l_kuu, MONTH(CURRENT_DATE))::INTEGER, COALESCE(l_aasta, YEAR(CURRENT_DATE))::INTEGER,
                     l_rekvid)::INTEGER[]                                  AS week_ends,
       ROW_NUMBER() OVER (PARTITION BY qry.laps_id, qry.grupp_id)::INTEGER AS men_count
FROM (
         SELECT t.rekv_id,
                t.grupp_id                                   AS grupp_id,
                t1.nom_id                                    AS nom_id,
                t1.laps_id                                   AS laps_id,
                sum(t1.kogus)                                AS kogus,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 1)  AS day_1,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 2)  AS day_2,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 3)  AS day_3,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 4)  AS day_4,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 5)  AS day_5,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 6)  AS day_6,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 7)  AS day_7,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 8)  AS day_8,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 9)  AS day_9,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 10) AS day_10,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 11) AS day_11,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 12) AS day_12,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 13) AS day_13,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 14) AS day_14,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 15) AS day_15,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 16) AS day_16,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 17) AS day_17,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 18) AS day_18,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 19) AS day_19,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 20) AS day_20,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 21) AS day_21,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 22) AS day_22,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 23) AS day_23,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 24) AS day_24,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 25) AS day_25,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 26) AS day_26,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 27) AS day_27,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 28) AS day_28,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 29) AS day_29,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 30) AS day_30,
                sum(t1.kogus) FILTER (WHERE DAY(t.kpv) = 31) AS day_31
         FROM lapsed.day_taabel t
                  INNER JOIN lapsed.day_taabel1 t1 ON t.id = t1.parent_id
                  INNER JOIN libs.library l ON l.id = t.grupp_id
         WHERE MONTH(t.kpv) = COALESCE(l_kuu, MONTH(CURRENT_DATE))::INTEGER
           AND YEAR(t.kpv) = COALESCE(l_aasta, YEAR(CURRENT_DATE))::INTEGER
           AND t.rekv_id = l_rekvid
           AND t.staatus <> 3
           AND (t.kpv >= l_kpv1 OR l_kpv1 IS NULL)
           AND (t.kpv <= l_kpv2 OR l_kpv2 IS NULL)
         GROUP BY t.rekv_id,
                  t.grupp_id,
                  t1.nom_id,
                  t1.laps_id
         UNION ALL
         SELECT t.rekv_id,
                t.grupp_id                                       AS grupp_id,
                999999999                                        AS nom_id,
                t1.laps_id                                       AS laps_id,
                0                                                AS kogus,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 1)  AS day_1,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 2)  AS day_2,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 3)  AS day_3,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 4)  AS day_4,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 5)  AS day_5,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 6)  AS day_6,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 7)  AS day_7,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 8)  AS day_8,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 9)  AS day_9,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 10) AS day_10,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 11) AS day_11,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 12) AS day_12,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 13) AS day_13,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 14) AS day_14,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 15) AS day_15,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 16) AS day_16,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 17) AS day_17,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 18) AS day_18,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 19) AS day_19,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 20) AS day_20,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 21) AS day_21,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 22) AS day_22,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 23) AS day_23,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 24) AS day_24,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 25) AS day_25,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 26) AS day_26,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 27) AS day_27,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 28) AS day_28,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 29) AS day_29,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 30) AS day_30,
                max(t1.osalemine) FILTER (WHERE DAY(t.kpv) = 31) AS day_31
         FROM lapsed.day_taabel t
                  INNER JOIN lapsed.day_taabel1 t1 ON t.id = t1.parent_id
                  INNER JOIN libs.library l ON l.id = t.grupp_id
         WHERE MONTH(t.kpv) = COALESCE(l_kuu, MONTH(CURRENT_DATE))::INTEGER
           AND YEAR(t.kpv) = COALESCE(l_aasta, YEAR(CURRENT_DATE))::INTEGER
           AND t.rekv_id = l_rekvid
           AND t.staatus <> 3
           AND (t.kpv >= l_kpv1 OR l_kpv1 IS NULL)
           AND (t.kpv <= l_kpv2 OR l_kpv2 IS NULL)

         GROUP BY t.rekv_id,
                  t.grupp_id,
                  t1.laps_id
     ) qry
         INNER JOIN (
    SELECT id,
           coalesce(n.properties ->> 'luno', kood)::TEXT AS kood,
           nimetus
    FROM libs.nomenklatuur n
    WHERE n.rekvid = l_rekvid
      AND (n.uhik) IN ('paev', 'päev', 'PAEV', 'PÄEV')
    UNION ALL
    SELECT 999999999     AS id,
           'Külastamine' AS kood,
           'Külastamine' AS nimetus
) n ON n.id = qry.nom_id
         INNER JOIN libs.library l ON l.id = qry.grupp_id
         INNER JOIN ou.rekv r ON r.id = qry.rekv_id
         INNER JOIN lapsed.laps laps ON laps.id = qry.laps_id


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.yksuse_taabel(INTEGER, INTEGER, INTEGER, DATE, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.yksuse_taabel(INTEGER, INTEGER, INTEGER, DATE, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.yksuse_taabel(INTEGER, INTEGER, INTEGER, DATE, DATE) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.yksuse_taabel(INTEGER, INTEGER, INTEGER, DATE, DATE) TO dbvaatleja;


/*
select * from lapsed.yksuse_taabel_(100, 9, 2023, '2023-09-04','2023-09-10')
where yksus like '02%'
and nom_id < 999999
order by nom_id

kogus
13
7

*/
