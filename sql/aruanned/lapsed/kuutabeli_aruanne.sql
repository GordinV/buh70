DROP FUNCTION IF EXISTS lapsed.kuutabeli_aruanne(INTEGER, INTEGER, INTEGER);
-- Rühm    Lapse nimi    Isikukood        Viitenumber    Arvestatud    Soodustus    Arvestatud ja Soodustus
CREATE OR REPLACE FUNCTION lapsed.kuutabeli_aruanne(l_rekvid INTEGER,
                                                    l_kuu INTEGER DEFAULT month(current_date),
                                                    l_aasta INTEGER DEFAULT year(current_date))
    RETURNS TABLE (
        ruhm        TEXT,
        nimi        TEXT,
        isikukood   TEXT,
        viitenumber TEXT,
        arvestatud  NUMERIC(14, 4),
        soodustus   NUMERIC(14, 4),
        kuu         INTEGER,
        aasta       INTEGER

    )
AS
$BODY$
WITH preReport AS (
    SELECT lt.yksus::TEXT                                  AS ruhm,
           lt.nimi::TEXT,
           lt.isikukood::TEXT,
           lapsed.get_viitenumber(lt.rekvid, l.id)::TEXT   AS viitenumber,
--           (CASE WHEN lt.tyyp IS NOT NULL AND lt.tyyp = 'SOODUSTUS' THEN 0 ELSE 1 END) *
           lt.arv_summa - lt.arv_soodustus_kokku - lt.vahe AS arvestatud,
           lt.arv_soodustus_kokku                          AS soodustus,
           lt.kuu::INTEGER,
           lt.aasta::INTEGER
    FROM lapsed.cur_lapse_taabel lt
             INNER JOIN lapsed.laps l ON l.id = lt.parentid
             INNER JOIN (
        SELECT id, nimetus
        FROM ou.rekv r
        WHERE id = l_rekvid
        -- id IN (SELECT rekv_id                 FROM get_asutuse_struktuur(l_rekvid))
    ) r ON r.id = lt.rekvid
    WHERE lt.kuu = l_kuu
      AND lt.aasta = l_aasta
)
SELECT ruhm::TEXT,
       nimi:: TEXT,
       isikukood:: TEXT,
       viitenumber:: TEXT,
       sum(arvestatud):: NUMERIC(14, 2),
       sum(soodustus):: NUMERIC(14, 2),
       kuu:: INTEGER,
       aasta
FROM preReport
GROUP BY ruhm, nimi, isikukood, viitenumber, kuu, aasta

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.kuutabeli_aruanne(INTEGER, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.kuutabeli_aruanne(INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.kuutabeli_aruanne(INTEGER, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.kuutabeli_aruanne(INTEGER, INTEGER, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.kuutabeli_aruanne(INTEGER, INTEGER, INTEGER) TO arvestaja;


SELECT *
FROM (
         SELECT *
         FROM lapsed.kuutabeli_aruanne(83, 2, 2021)
     ) qry
WHERE isikukood LIKE '51507300%'

/*select * from lapsed.cur_lapse_taabel lt
where isikukood like '51507300%'
and kuu = 2
and aasta = 2021*/