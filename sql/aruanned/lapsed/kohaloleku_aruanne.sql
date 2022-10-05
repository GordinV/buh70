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

    )
AS
$BODY$

SELECT r.nimetus::TEXT                                AS asutus,
       t.nimetus::TEXT                                AS koolituse_tyyp,
       count(*)::INTEGER                              AS yksuse_kogus,
       sum(coalesce(lk.nimekirje_kogus, 0))::INTEGER  AS nimekirje_kogus,
       sum(coalesce(tab.faktiline_kogus, 0))::INTEGER AS faktiline_kogus,
       sum(coalesce(qry_kogus.kogus, 0))::INTEGER     AS kogus,
       coalesce(l_kuu, month(current_date))           AS kuu,
       coalesce(l_aasta, year(current_date))          AS aasta
FROM (
         SELECT DISTINCT lk.rekvid,
                         (lk.properties ->> 'yksus') AS yksus
         FROM lapsed.lapse_kaart lk
         WHERE staatus <> 3
           AND ((lk.properties ->> 'alg_kpv')::DATE IS NULL OR
                (lk.properties ->> 'alg_kpv')::DATE <=
                get_last_day(make_date(l_aasta, coalesce(l_kuu, month(current_date)), 1)))
           AND ((lk.properties ->> 'lopp_kpv')::DATE IS NULL OR
                (lk.properties ->> 'lopp_kpv')::DATE >= (
                    make_date(coalesce(l_aasta, year(current_date)), coalesce(l_kuu, month(current_date)), 1)))
     ) g
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
                    (lk.properties ->> 'alg_kpv')::DATE <=
                    get_last_day(make_date(l_aasta, coalesce(l_kuu, month(current_date)), 1)))
               AND ((lk.properties ->> 'lopp_kpv')::DATE IS NULL OR
                    (lk.properties ->> 'lopp_kpv')::DATE >= (
                        make_date(coalesce(l_aasta, year(current_date)), coalesce(l_kuu, month(current_date)), 1)))
         ) lk
    GROUP BY rekvid, yksus) lk ON lk.rekvid = g.rekvid AND lk.yksus::TEXT = g.yksus::TEXT
    -- фактическая посещаемость
         LEFT OUTER JOIN (
    SELECT rekv_id, yksus, count(laps_id) AS faktiline_kogus
    FROM (
             SELECT DISTINCT t.rekv_id, l.kood AS yksus, t1.laps_id
             FROM lapsed.day_taabel t
                      INNER JOIN lapsed.day_taabel1 t1 ON t.id = t1.parent_id
                      INNER JOIN libs.library l ON l.id = t.grupp_id
             WHERE t.staatus <> 3
               AND month(t.kpv) = coalesce(l_kuu, month(current_date))
               AND year(t.kpv) = coalesce(l_aasta, year(current_date))
               AND t1.osalemine IS NOT NULL
               AND t1.osalemine > 0
         ) tab
    GROUP BY rekv_id, yksus
) tab ON tab.yksus = g.yksus AND tab.rekv_id = g.rekvid
    -- Детодни – сумма данных всех посещений за все дни и всех детей в отделении за данный период
         LEFT OUTER JOIN (SELECT yksus, count(laps_id) AS kogus, rekv_id
                          FROM (
                                   SELECT DISTINCT l.kood AS yksus, t.id, t1.laps_id, t.rekv_id
                                   FROM lapsed.day_taabel1 t1
                                            INNER JOIN lapsed.day_taabel t ON t.id = t1.parent_id
                                            INNER JOIN libs.library l ON l.id = t.grupp_id
                                   WHERE month(t.kpv) = coalesce(l_kuu, month(current_date))
                                     AND year(t.kpv) = coalesce(l_aasta, year(current_date))
                                     AND t.staatus <> 3
                                     AND t1.osalemine IS NOT NULL
                                     AND t1.osalemine > 0
                               ) qry
                          GROUP BY yksus, rekv_id
) qry_kogus ON qry_kogus.yksus = g.yksus AND qry_kogus.rekv_id = g.rekvid
         INNER JOIN ou.rekv r ON r.id = g.rekvid
         INNER JOIN libs.library l ON l.kood = g.yksus AND l.library = 'LAPSE_GRUPP' AND
                                      l.rekvid = lk.rekvid
         LEFT OUTER JOIN libs.library t
                         ON (l.properties::JSONB ->> 'tyyp')::INTEGER = t.id AND t.library = 'KOOLITUSE_TYYP'

WHERE g.rekvid IN (SELECT rekv_id
                   FROM get_asutuse_struktuur(l_rekvid))
  AND l.status <> 3
  AND t.status <> 3
    GROUP BY t.nimetus
    , r.nimetus ;

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
FROM lapsed.kohaloleku_aruanne(101, 1, 2022)

*/
