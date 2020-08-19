DROP FUNCTION IF EXISTS lapsed.kohaoleku_aruanne(INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.kohaloleku_aruanne(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.kohaloleku_aruanne(l_rekvid INTEGER,
                                                     l_kuu INTEGER DEFAULT month(current_date),
                                                     l_aasta INTEGER DEFAULT year(current_date))
    RETURNS TABLE (
        asutus          TEXT,
        koolituse_tyyp  TEXT,
        yksuse_kogus    INTEGER,
        nimekirje_kogus INTEGER,
        faktiline_kogus INTEGER,
        kogus           INTEGER,
        kuu             INTEGER,
        aasta           INTEGER

    ) AS
$BODY$

SELECT r.nimetus::TEXT                                AS asutus,
       t.nimetus::TEXT                                AS koolituse_tyyp,
       count(g.kood)::INTEGER                         AS yksuse_kogus,
       sum(coalesce(lk.nimekirje_kogus, 0))::INTEGER  AS nimekirje_kogus,
       sum(coalesce(tab.faktiline_kogus, 0))::INTEGER AS faktiline_kogus,
       sum(coalesce(qry_kogus.kogus, 0))::INTEGER     AS kogus,
       coalesce(l_kuu, month(current_date))           AS kuu,
       coalesce(l_aasta, year(current_date))          AS aasta
FROM libs.library g
         INNER JOIN libs.library t ON (g.properties::JSONB ->> 'tyyp')::INTEGER = t.id
--- списочная численность
         LEFT OUTER JOIN (
    SELECT rekvid, yksus, count(laps_id) AS nimekirje_kogus
    FROM (
             SELECT DISTINCT lk.rekvid,
                             lk.parentId                 AS laps_id,
                             (lk.properties ->> 'yksus') AS yksus
             FROM lapsed.lapse_kaart lk
             WHERE staatus <> 3
               AND ((lk.properties ->> 'alg_kpv')::DATE IS NULL OR
                    (lk.properties ->> 'alg_kpv')::DATE >= make_date(l_aasta, coalesce(l_kuu, month(current_date)), 1))
               AND ((lk.properties ->> 'lopp_kpv')::DATE IS NULL OR
                    (lk.properties ->> 'lopp_kpv')::DATE >= get_last_day(
                            make_date(coalesce(l_aasta, year(current_date)), coalesce(l_kuu, month(current_date)), 1)))
         ) lk
    GROUP BY rekvid, yksus) lk ON lk.rekvid = g.rekvid AND lk.yksus::TEXT = g.kood::TEXT
    -- фактическая посещаемость
         LEFT OUTER JOIN (
    SELECT rekv_id, grupp_id, count(laps_id) AS faktiline_kogus
    FROM (
             SELECT DISTINCT t.rekv_id, t.grupp_id, t1.laps_id
             FROM lapsed.day_taabel t
                      INNER JOIN lapsed.day_taabel1 t1 ON t.id = t1.parent_id
             WHERE t.staatus <> 3
               AND month(t.kpv) = coalesce(l_kuu, month(current_date))
               AND year(t.kpv) = coalesce(l_aasta, year(current_date))
               AND t1.osalemine IS NOT NULL
               AND t1.osalemine > 0
         ) tab
    GROUP BY rekv_id, grupp_id
) tab ON tab.grupp_id = g.id
    -- Детодни – сумма данных всех посещений за все дни и всех детей в отделении за данный период
         LEFT OUTER JOIN (SELECT grupp_id, count(laps_id) AS kogus
                          FROM (
                                   SELECT DISTINCT t.grupp_id, t.id, t1.laps_id
                                   FROM lapsed.day_taabel1 t1
                                            INNER JOIN lapsed.day_taabel t ON t.id = t1.parent_id
                                   WHERE month(t.kpv) = coalesce(l_kuu, month(current_date))
                                     AND year(t.kpv) = coalesce(l_aasta, year(current_date))
                                     AND t.staatus <> 3
                                     AND t1.osalemine IS NOT NULL
                                     AND t1.osalemine > 0
                               ) qry
                          GROUP BY grupp_id
) qry_kogus ON qry_kogus.grupp_id = g.id
         INNER JOIN ou.rekv r ON r.id = g.rekvid
WHERE g.rekvid IN (SELECT rekv_id
                   FROM get_asutuse_struktuur(l_rekvid))
  AND g.library = 'LAPSE_GRUPP'
  AND t.library = 'KOOLITUSE_TYYP'
  AND g.status <> 3
GROUP BY t.nimetus, r.nimetus ;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.kohaloleku_aruanne(INTEGER, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.kohaloleku_aruanne(INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.kohaloleku_aruanne(INTEGER, INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.kohaloleku_aruanne(INTEGER, INTEGER, INTEGER) TO dbvaatleja;


/*
SELECT *
FROM lapsed.kohaoleku_aruanne(63, 3, 2020)

*/
