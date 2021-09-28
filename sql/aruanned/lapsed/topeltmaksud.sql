DROP FUNCTION IF EXISTS lapsed.topeltmaksud(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.topeltmaksud(l_rekvid INTEGER,
                                               l_kuu INTEGER DEFAULT month(current_date),
                                               l_aasta INTEGER DEFAULT year(current_date))
    RETURNS TABLE (
        nimi        TEXT,
        isikukood   TEXT,
        viitenumber TEXT,
        asutus      TEXT,
        kood        TEXT,
        nimetus     TEXT,
        hind        NUMERIC(14, 4),
        kogus       NUMERIC(14, 4),
        summa       NUMERIC(14, 4),
        kuu         INTEGER,
        aasta       INTEGER,
        koht text

    )
AS
$BODY$
SELECT lt.nimi::TEXT,
       lt.isikukood::TEXT,
       lapsed.get_viitenumber(lt.rekvid, l.id)::TEXT AS viitenumber,
       r.nimetus::TEXT                               AS asutus,
       lt.kood::TEXT,
       ltrim(rtrim(lt.teenus))::TEXT                 AS nimetus,
       lt.hind,
       lt.kogus::NUMERIC(14, 4),
       ((lt.hind * lt.kogus - (CASE
                                   WHEN lt.kas_protsent THEN (lt.hind * lt.kogus)::NUMERIC(12, 2) *
                                                             ((lt.soodustus * lt.sooduse_kehtivus) / 100)
                                   ELSE lt.soodustus * lt.kogus * lt.sooduse_kehtivus *
                                        (CASE WHEN lt.tyyp IS NOT NULL AND lt.tyyp = 'SOODUSTUS' THEN 0 ELSE 1 END)
           END)))::NUMERIC(12, 2)
                                                     AS summa,
       lt.kuu::INTEGER,
       lt.aasta::INTEGER,
       'KUUTABEL' as koht
FROM lapsed.cur_lapse_taabel lt
         INNER JOIN lapsed.laps l ON l.id = lt.parentid
         INNER JOIN (
    SELECT id, nimetus
    FROM ou.rekv r
    WHERE id IN (SELECT rekv_id
                 FROM get_asutuse_struktuur(l_rekvid)
    )
      AND (r.properties ->> 'liik') = 'LASTEAED'
) r ON r.id = lt.rekvid
         INNER JOIN (SELECT isikukood, kood
                     FROM lapsed.cur_lapse_taabel
                     WHERE kuu = l_kuu
                       AND aasta = l_aasta
                     GROUP BY isikukood, kood
                     HAVING count(*) > 1) dbl ON dbl.isikukood = lt.isikukood AND dbl.kood = lt.kood
WHERE lt.kuu = l_kuu
  AND lt.aasta = l_aasta
  AND lt.kas_inf3 IS NOT NULL
  AND lt.kas_inf3

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.topeltmaksud(INTEGER, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.topeltmaksud(INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.topeltmaksud(INTEGER, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.topeltmaksud(INTEGER, INTEGER, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.topeltmaksud(INTEGER, INTEGER, INTEGER) TO arvestaja;


SELECT *
FROM lapsed.topeltmaksud(119, 1, 2021);

