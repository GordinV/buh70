DROP FUNCTION IF EXISTS lapsed.kuutabeli_aruanne(INTEGER, INTEGER, INTEGER);
-- Rühm    Lapse nimi    Isikukood        Viitenumber    Arvestatud    Soodustus    Arvestatud ja Soodustus
CREATE OR REPLACE FUNCTION lapsed.kuutabeli_aruanne(l_rekvid INTEGER,
                                                    l_kuu INTEGER DEFAULT month(current_date),
                                                    l_aasta INTEGER DEFAULT year(current_date))
    RETURNS TABLE (
        ruhm          TEXT,
        nimi          TEXT,
        isikukood     TEXT,
        viitenumber   TEXT,
        arvestatud    NUMERIC(14, 2),
        soodustus     NUMERIC(14, 2),
        umberarvestus NUMERIC(14, 2),
        vahe          NUMERIC(14, 2),
        vana_vn       TEXT,
        kuu           INTEGER,
        aasta         INTEGER

    )
AS
$BODY$
WITH preReport AS (
    SELECT lt.yksus::TEXT                                                    AS ruhm,
           lt.nimi::TEXT,
           lt.isikukood::TEXT,
           lapsed.get_viitenumber(lt.rekvid, l.id)::TEXT                     AS viitenumber,
           (CASE
                WHEN lt.umberarvestus
                    THEN 0
                ELSE 1 END) *
           (lt.arv_summa - lt.arv_soodustus_kokku - lt.vahe)::NUMERIC(12, 2) AS arvestatud,
           (CASE
                WHEN lt.umberarvestus
                    THEN 1
                ELSE 0 END) *
           (lt.arv_summa - lt.arv_soodustus_kokku - lt.vahe)::NUMERIC(12, 2) AS umberarvestus,
           lt.vahe                                                           AS vahe,
           lt.viitenr                                                        AS vana_vn,
           lt.arv_soodustus_kokku::NUMERIC(12, 2)                            AS soodustus,
           lt.kuu::INTEGER,
           lt.aasta::INTEGER
    FROM lapsed.cur_lapse_taabel lt
             INNER JOIN lapsed.laps l ON l.id = lt.parentid
             INNER JOIN (
        SELECT id, nimetus
        FROM ou.rekv r
        WHERE 
              -- id = l_rekvid
         id IN (SELECT rekv_id                 FROM get_asutuse_struktuur(l_rekvid))
    ) r ON r.id = lt.rekvid
    WHERE lt.kuu = l_kuu
      AND lt.aasta = l_aasta
)
SELECT ruhm::TEXT,
       nimi:: TEXT,
       isikukood:: TEXT,
       viitenumber:: TEXT,
       sum(arvestatud):: NUMERIC(14, 2)    AS arvestatud,
       sum(soodustus):: NUMERIC(14, 2)     AS soodustus,
       sum(umberarvestus):: NUMERIC(14, 2) AS umberarvestus,
       sum(vahe)::NUMERIC(14, 2)           AS vahe,
       vana_vn                             AS vana_vn,
       kuu:: INTEGER,
       aasta
FROM preReport
GROUP BY ruhm, nimi, isikukood, viitenumber, vana_vn, kuu, aasta

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