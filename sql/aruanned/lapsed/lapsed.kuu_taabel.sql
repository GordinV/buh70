DROP FUNCTION IF EXISTS lapsed.kuu_taabel(JSONB, INTEGER);
DROP FUNCTION IF EXISTS lapsed.kuu_taabel(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.kuu_taabel(l_rekvid INTEGER, l_kuu INTEGER, l_aasta INTEGER)
    RETURNS TABLE (
        rekv_id   INTEGER,
        asutus    TEXT,
        yksus     TEXT,
        teenus    TEXT,
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
        week_ends INTEGER[]

    ) AS
$BODY$
SELECT qry.rekv_id,
       r.nimetus::TEXT                                                AS asutus,
       l.nimetus::TEXT                                                AS yksus,
       coalesce((l.properties::JSONB ->> 'luno')::TEXT, n.kood)::TEXT AS teenus,
       l_kuu::INTEGER                                                 AS kuu,
       l_aasta::INTEGER                                               AS aasta,
       coalesce(qry.kogus, 0)::INTEGER                                AS kogus,
       coalesce(qry.day_1, 0)::INTEGER                                AS day_1,
       coalesce(qry.day_2, 0)::INTEGER                                AS day_2,
       coalesce(qry.day_3, 0)::INTEGER                                AS day_3,
       coalesce(qry.day_4, 0)::INTEGER                                AS day_4,
       coalesce(qry.day_5, 0)::INTEGER                                AS day_5,
       coalesce(qry.day_6, 0)::INTEGER                                AS day_6,
       coalesce(qry.day_7, 0)::INTEGER                                AS day_7,
       coalesce(qry.day_8, 0)::INTEGER                                AS day_8,
       coalesce(qry.day_9, 0)::INTEGER                                AS day_9,
       coalesce(qry.day_10, 0)::INTEGER                               AS day_10,
       coalesce(qry.day_11, 0)::INTEGER                               AS day_11,
       coalesce(qry.day_12, 0)::INTEGER                               AS day_12,
       coalesce(qry.day_13, 0)::INTEGER                               AS day_13,
       coalesce(qry.day_14, 0)::INTEGER                               AS day_14,
       coalesce(qry.day_15, 0)::INTEGER                               AS day_15,
       coalesce(qry.day_16, 0)::INTEGER                               AS day_16,
       coalesce(qry.day_17, 0)::INTEGER                               AS day_17,
       coalesce(qry.day_18, 0)::INTEGER                               AS day_18,
       coalesce(qry.day_19, 0)::INTEGER                               AS day_19,
       coalesce(qry.day_20, 0)::INTEGER                               AS day_20,
       coalesce(qry.day_21, 0)::INTEGER                               AS day_21,
       coalesce(qry.day_22, 0)::INTEGER                               AS day_22,
       coalesce(qry.day_23, 0)::INTEGER                               AS day_23,
       coalesce(qry.day_24, 0)::INTEGER                               AS day_24,
       coalesce(qry.day_25, 0)::INTEGER                               AS day_25,
       coalesce(qry.day_26, 0)::INTEGER                               AS day_26,
       coalesce(qry.day_27, 0)::INTEGER                               AS day_27,
       coalesce(qry.day_28, 0)::INTEGER                               AS day_28,
       coalesce(qry.day_29, 0)::INTEGER                               AS day_29,
       coalesce(qry.day_30, 0)::INTEGER                               AS day_30,
       coalesce(qry.day_31, 0)::INTEGER                               AS day_31,
       get_week_ends(l_kuu, l_aasta, l_rekvid)::INTEGER[]             AS week_ends
FROM (
         SELECT t.rekv_id,
                t.grupp_id                                   AS grupp_id,
                t1.nom_id                                    AS nom_id,
                sum(t1.kogus)                                AS kogus,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 1)  AS day_1,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 2)  AS day_2,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 3)  AS day_3,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 4)  AS day_4,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 5)  AS day_5,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 6)  AS day_6,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 7)  AS day_7,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 8)  AS day_8,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 9)  AS day_9,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 10) AS day_10,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 11) AS day_11,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 12) AS day_12,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 13) AS day_13,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 14) AS day_14,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 15) AS day_15,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 16) AS day_16,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 17) AS day_17,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 18) AS day_18,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 19) AS day_19,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 20) AS day_20,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 21) AS day_21,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 22) AS day_22,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 23) AS day_23,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 24) AS day_24,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 25) AS day_25,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 26) AS day_26,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 27) AS day_27,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 28) AS day_28,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 29) AS day_29,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 30) AS day_30,
                sum(t1.kogus) FILTER (WHERE day(t.kpv) = 31) AS day_31
         FROM lapsed.day_taabel t
                  INNER JOIN lapsed.day_taabel1 t1 ON t.id = t1.parent_id
                  INNER JOIN libs.library l ON l.id = t.grupp_id
         WHERE month(t.kpv) = l_kuu::INTEGER
           AND year(t.kpv) = l_aasta::INTEGER
           AND t.rekv_id = l_rekvid
           AND t.staatus <> 3
         GROUP BY t.rekv_id, t.grupp_id, t1.nom_id
     ) qry
         INNER JOIN libs.nomenklatuur n ON n.id = qry.nom_id
         INNER JOIN libs.library l ON l.id = qry.grupp_id
         INNER JOIN ou.rekv r ON r.id = qry.rekv_id

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.kuu_taabel(INTEGER, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.kuu_taabel(INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.kuu_taabel(INTEGER, INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.kuu_taabel(INTEGER, INTEGER, INTEGER) TO dbvaatleja;


/*
select * from lapsed.kuu_taabel(63, 3, 2020)
*/