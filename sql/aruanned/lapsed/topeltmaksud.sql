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
        koht        TEXT,
        id          INTEGER

    )
AS
$BODY$
WITH qryRekv AS (SELECT rekv_id
                 FROM get_asutuse_struktuur(l_rekvid)),
     qryTabel AS (
         SELECT lt.nimi::TEXT,
                lt.isikukood::TEXT,
                lapsed.get_viitenumber(lt.rekvid, l.id)::TEXT AS viitenumber,
                r.nimetus::TEXT                               AS asutus,
                ltrim(rtrim(lt.teenus))::TEXT                 AS nimetus,
                n.kood,
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
                'KUUTABEL'                                    AS koht,
                1                                             AS id
         FROM lapsed.cur_lapse_taabel lt
                  INNER JOIN libs.nomenklatuur n ON n.id = lt.nomid
                  INNER JOIN lapsed.laps l ON l.id = lt.parentid
                  INNER JOIN (
             SELECT id, nimetus
             FROM ou.rekv r
             WHERE id IN (SELECT rekv_id
                          FROM qryRekv
             )
               AND (r.properties ->> 'liik') = 'LASTEAED'
         ) r ON r.id = lt.rekvid
                  INNER JOIN (SELECT isikukood, ltrim(rtrim(teenus)) AS teenus
                              FROM lapsed.cur_lapse_taabel
                              WHERE kuu = l_kuu
                                AND aasta = l_aasta
                                AND teenus IN ('Õppetasu', 'Kohatasu')
                              GROUP BY isikukood, ltrim(rtrim(teenus))
                              HAVING count(*) > 1) dbl
                             ON dbl.isikukood = lt.isikukood AND ltrim(rtrim(dbl.teenus)) = ltrim(rtrim(lt.teenus))
         WHERE lt.kuu = l_kuu
           AND lt.aasta = l_aasta
           AND n.nimetus IN ('Õppetasu', 'Kohatasu')
           AND l.staatus < 3
     ),
     qryKaart AS (
         WITH laste_kaart AS
                  (
                      SELECT lk.id,
                             n.kood,
                             ltrim(rtrim(n.nimetus))                     AS nimetus,
                             lk.parentid                                 AS laps_id,
                             lk.rekvid                                   AS rekv_id,
                             (lk.properties ->> 'alg_kpv')::DATE         AS alg_kpv,
                             (lk.properties ->> 'lopp_kpv')::DATE        AS lopp_kpv,
                             lk.hind,
                             1                                           AS kogus,
                             CASE
                                 WHEN (n.properties ->> 'tyyp') IS NOT NULL AND (n.properties ->> 'tyyp') = 'SOODUSTUS'
                                     THEN lk.hind
                                 WHEN lk.properties ->> 'soodus' IS NOT NULL
                                     THEN coalesce((lk.properties ->> 'soodus')::NUMERIC, 0)
                                 ELSE 0 END ::NUMERIC                    AS soodustus,
                             (lk.properties ->> 'kas_protsent')::BOOLEAN AS kas_protsent,
                             CASE
                                 WHEN (n.properties ->> 'tyyp') IS NOT NULL AND (n.properties ->> 'tyyp') = 'SOODUSTUS'
                                     THEN -1
                                 WHEN (lk.properties ->> 'sooduse_alg')::DATE <=
                                      ((make_date(l_aasta, l_kuu, 1) + INTERVAL '1 month')::DATE - 1)
                                     AND (lk.properties ->> 'sooduse_lopp')::DATE >=
                                         CASE
                                             WHEN upper(n.uhik) = ('KUU')
                                                 THEN ((make_date(l_aasta, l_kuu, 1) + INTERVAL '1 month')::DATE - 1)
                                             WHEN (lk.properties ->> 'sooduse_lopp')::DATE <
                                                  ((make_date(l_aasta, l_kuu, 1) + INTERVAL '1 month')::DATE - 1) +
                                                  INTERVAL '1 month' - INTERVAL '1 day' AND
                                                  (lk.properties ->> 'lopp_kpv')::DATE =
                                                  (lk.properties ->> 'sooduse_lopp')::DATE
                                                 THEN ((make_date(l_aasta, l_kuu, 1) + INTERVAL '1 month')::DATE - 1)
                                             ELSE ((make_date(l_aasta, l_kuu, 1) + INTERVAL '1 month')::DATE - 1) +
                                                  INTERVAL '1 month' - INTERVAL '1 day' END
                                     THEN 1
                                 ELSE 0 END                              AS sooduse_kehtivus,
                             (lk.properties ->> 'sooduse_alg')::DATE     AS sooduse_alg,
                             (lk.properties ->> 'sooduse_lopp')::DATE    AS sooduse_lopp,
                             coalesce(n.properties ->> 'tyyp', '')       AS tyyp,
                             r.nimetus::TEXT                             AS asutus
                      FROM lapsed.lapse_kaart lk
                               INNER JOIN libs.nomenklatuur n
                                          ON n.id = lk.nomid AND ltrim(rtrim(n.nimetus)) IN ('Õppetasu', 'Kohatasu')
                               INNER JOIN (
                          SELECT id, nimetus
                          FROM ou.rekv r
                          WHERE id IN (SELECT rekv_id
                                       FROM qryRekv
                          )
                            AND (r.properties ->> 'liik') = 'LASTEAED'
                      ) r ON r.id = lk.rekvid

                      WHERE lk.staatus <> 3
                        AND (n.properties ->> 'kas_inf3')::BOOLEAN IS NOT NULL
                        AND (n.properties ->> 'kas_inf3')::BOOLEAN
                  )
         SELECT hind.laps_id,
                hind.asutus,
                hind.rekv_id,
                hind.hind,
                hind.summa,
                hind.teenuse_kood,
                hind.nimetus,
                hind.id
         FROM (
                  SELECT lk.id,
                         lk.kood                                                                      AS teenuse_kood,
                         lk.nimetus,
                         lk.asutus,
                         lk.laps_id,
                         lk.rekv_id,
                         lk.hind,
                         (CASE
                              WHEN lk.kas_protsent THEN (lk.hind * lk.kogus)::NUMERIC(12, 2) *
                                                        ((lk.soodustus * lk.sooduse_kehtivus) / 100)
                              ELSE lk.soodustus * lk.kogus * lk.sooduse_kehtivus END)::NUMERIC(12, 2) AS soodustus,
                         ((lk.hind * lk.kogus - (CASE
                                                     WHEN lk.kas_protsent THEN (lk.hind * lk.kogus)::NUMERIC(12, 2) *
                                                                               ((lk.soodustus * lk.sooduse_kehtivus) / 100)
                                                     ELSE lk.soodustus * lk.kogus * lk.sooduse_kehtivus *
                                                          (CASE WHEN lk.tyyp IS NOT NULL AND lk.tyyp = 'SOODUSTUS' THEN 0 ELSE 1 END)
                             END)))::NUMERIC(12, 2)                                                   AS summa

                  FROM laste_kaart lk
                  WHERE alg_kpv <= ((make_date(l_aasta, l_kuu, 1) + INTERVAL '1 month')::DATE - 1)
                    AND lopp_kpv >= make_date(l_aasta, l_kuu, 1)
              ) hind
                  INNER JOIN (
             SELECT lk.nimetus, lk.laps_id
             FROM laste_kaart lk
             WHERE alg_kpv <= (make_date(l_aasta, l_kuu, 1) + INTERVAL '1 month')::DATE - 1
               AND lopp_kpv >= make_date(l_aasta, l_kuu, 1)
             GROUP BY lk.nimetus, lk.laps_id
             HAVING count(*) > 1) dbl
                             ON hind.nimetus = dbl.nimetus AND
                                hind.laps_id = dbl.laps_id
     )
SELECT nimi,
       isikukood::TEXT,
       viitenumber::TEXT,
       t.asutus::TEXT,
       kood::TEXT,
       nimetus::TEXT,
       hind,
       kogus,
       summa,
       kuu,
       aasta,
       koht,
       t.id
FROM qryTabel t
UNION ALL
SELECT l.nimi,
       l.isikukood,
       lapsed.get_viitenumber(k.rekv_id, l.id)::TEXT AS viitenumber,
       k.asutus,
       k.teenuse_kood,
       k.nimetus,
       k.hind,
       1                                             AS kogus,
       k.summa,
       l_kuu                                         AS kuu,
       l_aasta                                       AS aasta,
       'KAART'                                       AS koht,
       k.id
FROM qryKaart k
         INNER JOIN lapsed.laps l ON l.id = k.laps_id

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.topeltmaksud(INTEGER, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.topeltmaksud(INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.topeltmaksud(INTEGER, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.topeltmaksud(INTEGER, INTEGER, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.topeltmaksud(INTEGER, INTEGER, INTEGER) TO arvestaja;

/*
SELECT *
FROM lapsed.topeltmaksud(119, 08, 2023)
where isikukood = '52006030027'
;
*/
