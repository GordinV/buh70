DROP FUNCTION IF EXISTS lapsed.kohaoleku_aruanne(INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.kohaloleku_aruanne(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.kohaloleku_aruanne(l_rekvid INTEGER,
                                                     l_kuu INTEGER DEFAULT month(current_date),
                                                     l_aasta INTEGER DEFAULT year(current_date))
    RETURNS TABLE
            (
                asutus          TEXT,
                koolituse_tyyp  TEXT,
                yksuse_kogus    INTEGER,
                nimekirje_kogus INTEGER,
                rist_kasutus    INTEGER,
                faktiline_kogus INTEGER,
                kogus           INTEGER,
                kuu             INTEGER,
                aasta           INTEGER


            )
AS
$BODY$

WITH
    params AS (
                  SELECT
                      l_kuu    AS kuu,
                      l_aasta  AS aasta,
                      l_rekvid AS rekvid
              ),
    rekv_ids AS (
                  SELECT
                      rekv_id
                  FROM
                      params p, public.get_asutuse_struktuur(p.rekvid)
              )
SELECT
    r.nimetus::TEXT                                       AS asutus,
    t.nimetus::TEXT                                       AS koolituse_tyyp,
    COUNT(*)::INTEGER                                     AS yksuse_kogus,
    SUM(COALESCE(lk.nimekirje_kogus, 0))::INTEGER         AS nimekirje_kogus,
    count(*) filter ( where lk.rist_kasutus > 1)::INTEGER AS rist_kasutus,
    SUM(COALESCE(tab.faktiline_kogus, 0))::INTEGER        AS faktiline_kogus,
    SUM(COALESCE(qry_kogus.kogus, 0))::INTEGER            AS kogus,
    COALESCE(MIN(p.kuu), month(CURRENT_DATE))             AS kuu,
    COALESCE(MIN(p.aasta), year(CURRENT_DATE))            AS aasta
FROM
    params                           p,
    (
        SELECT DISTINCT
            lk.rekvid,
            (lk.properties ->> 'yksus') AS yksus
        FROM
            params             p,
            lapsed.lapse_kaart lk
        WHERE
              staatus <> 3
          AND ((lk.properties ->> 'alg_kpv')::DATE IS NULL OR
               (lk.properties ->> 'alg_kpv')::DATE <=
               public.get_last_day(MAKE_DATE(p.aasta, COALESCE(p.kuu, month(CURRENT_DATE)), 1)))
          AND ((lk.properties ->> 'lopp_kpv')::DATE IS NULL OR
               (lk.properties ->> 'lopp_kpv')::DATE >= (
                   MAKE_DATE(COALESCE(p.aasta, year(CURRENT_DATE)), COALESCE(p.kuu, month(CURRENT_DATE)), 1)))
    )                                g
--- списочная численность
        LEFT OUTER JOIN (
                            SELECT
                                rekvid,
                                yksus,
                                COUNT(laps_id)    AS nimekirje_kogus,
                                max(rist_kasutus) AS rist_kasutus

                            FROM
                                (
                                    SELECT
                                        qry.rekvid,
                                        qry.laps_id,
                                        qry.yksus,
                                        COUNT(*) OVER (PARTITION BY qry.laps_id, qry.rekvid) AS rist_kasutus

                                    FROM
                                        (
                                            SELECT DISTINCT
                                                lk.rekvid,
                                                lk.parentId                 AS laps_id,
                                                (lk.properties ->> 'yksus') AS yksus
                                            FROM
                                                params             p,
                                                lapsed.lapse_kaart lk
                                            WHERE
                                                  lk.staatus <> 3
                                              AND ((lk.properties ->> 'alg_kpv')::DATE IS NULL OR
                                                   (lk.properties ->> 'alg_kpv')::DATE <=
                                                   public.get_last_day(MAKE_DATE(p.aasta, COALESCE(p.kuu, month(CURRENT_DATE)), 1)))
                                              AND ((lk.properties ->> 'lopp_kpv')::DATE IS NULL OR
                                                   (lk.properties ->> 'lopp_kpv')::DATE >= (
                                                       MAKE_DATE(COALESCE(p.aasta, year(CURRENT_DATE)),
                                                                 COALESCE(p.kuu, month(CURRENT_DATE)), 1)))
                                              AND lk.rekvid IN (
                                                                   SELECT
                                                                       rekv_id
                                                                   FROM
                                                                       rekv_ids
                                                               )
                                        ) qry
                                ) lk
                            GROUP BY rekvid, yksus
                        )            lk ON lk.rekvid = g.rekvid AND lk.yksus::TEXT = g.yksus::TEXT
                            -- фактическая посещаемость
        LEFT OUTER JOIN (
                            SELECT
                                rekv_id,
                                yksus,
                                COUNT(laps_id) AS faktiline_kogus
                            FROM
                                (
                                    SELECT DISTINCT
                                        t.rekv_id,
                                        l.kood AS yksus,
                                        t1.laps_id
                                    FROM
                                        params                            p,
                                        lapsed.day_taabel                 t
                                            INNER JOIN lapsed.day_taabel1 t1 ON t.id = t1.parent_id
                                            INNER JOIN libs.library       l ON l.id = t.grupp_id
                                    WHERE
                                          t.staatus <> 3
                                      AND month(t.kpv) = COALESCE(p.kuu, month(CURRENT_DATE))
                                      AND year(t.kpv) = COALESCE(p.aasta, year(CURRENT_DATE))
                                      AND t1.osalemine IS NOT NULL
                                      AND t1.osalemine > 0
                                ) tab
                            GROUP BY rekv_id, yksus
                        )            tab ON tab.yksus = g.yksus AND tab.rekv_id = g.rekvid
                            -- Детодни – сумма данных всех посещений за все дни и всех детей в отделении за данный период
        LEFT OUTER JOIN (
                            SELECT
                                yksus,
                                COUNT(laps_id) AS kogus,
                                rekv_id
                            FROM
                                (
                                    SELECT DISTINCT
                                        l.kood AS yksus,
                                        t.id,
                                        t1.laps_id,
                                        t.rekv_id
                                    FROM
                                        lapsed.day_taabel1               t1
                                            INNER JOIN lapsed.day_taabel t ON t.id = t1.parent_id
                                            INNER JOIN libs.library      l ON l.id = t.grupp_id,
                                        params                           p
                                    WHERE
                                          month(t.kpv) = COALESCE(p.kuu, month(CURRENT_DATE))
                                      AND year(t.kpv) = COALESCE(p.aasta, year(CURRENT_DATE))
                                      AND t.staatus <> 3
                                      AND t1.osalemine IS NOT NULL
                                      AND t1.osalemine > 0
                                ) qry
                            GROUP BY yksus, rekv_id
                        )            qry_kogus
                        ON qry_kogus.yksus = g.yksus AND qry_kogus.rekv_id = g.rekvid
        INNER JOIN      ou.rekv      r ON r.id = g.rekvid
        INNER JOIN      libs.library l ON l.kood = g.yksus AND l.library = 'LAPSE_GRUPP' AND
                                          l.rekvid = lk.rekvid
        LEFT OUTER JOIN libs.library t
                        ON (l.properties::JSONB ->> 'tyyp')::INTEGER = t.id AND t.library = 'KOOLITUSE_TYYP'

WHERE
      g.rekvid IN (
                      SELECT
                          rekv_id
                      FROM
                          rekv_ids
                  )
  AND COALESCE(l.status, 1) <> 3
  AND COALESCE(t.status, 1) <> 3
GROUP BY
    t.nimetus
  , r.nimetus;


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
FROM lapsed.kohaloleku_aruanne(84, 9, 2024)

*/
