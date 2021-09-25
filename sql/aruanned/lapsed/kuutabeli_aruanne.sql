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
    SELECT lt.yksus::TEXT                                AS ruhm,
           lt.nimi::TEXT,
           lt.isikukood::TEXT,
           lapsed.get_viitenumber(lt.rekvid, l.id)::TEXT AS viitenumber,
           (lt.hind * lt.kogus)::NUMERIC(14, 4)          AS arvestatud,
           (CASE
                WHEN lt.kas_protsent THEN (lt.hind * lt.kogus)::NUMERIC(12, 2) *
                                          ((lt.soodustus * lt.sooduse_kehtivus) / 100)
                ELSE lt.soodustus * lt.kogus * lt.sooduse_kehtivus *
                     (CASE WHEN lt.tyyp IS NOT NULL AND lt.tyyp = 'SOODUSTUS' THEN 0 ELSE 1 END)
               END)::NUMERIC(12, 2)
                                                         AS soodustus,
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
       sum(arvestatud):: NUMERIC(14, 4),
       sum(soodustus):: NUMERIC(14, 4),
       kuu:: INTEGER,
       aasta
from preReport
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
FROM lapsed.kuutabeli_aruanne(89, 1, 2021);

