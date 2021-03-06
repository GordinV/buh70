DROP FUNCTION IF EXISTS lapsed.aasta_naitajad(INTEGER, DATE);
DROP FUNCTION IF EXISTS lapsed.aasta_naitajad(INTEGER, DATE, TEXT, TEXT);

CREATE OR REPLACE FUNCTION lapsed.aasta_naitajad(l_rekvid INTEGER,
                                                 l_kpv DATE DEFAULT current_date,
                                                 l_liik TEXT DEFAULT '',
                                                 l_tyyp TEXT DEFAULT '')
    RETURNS TABLE (
        period       DATE,
        rekvid       INTEGER,
        liik         TEXT,
        yksused      TEXT,
        lapsed_kokku INTEGER,
        jaanuar      INTEGER,
        veebruar     INTEGER,
        marts        INTEGER,
        apriil       INTEGER,
        mai          INTEGER,
        juuni        INTEGER,
        juuli        INTEGER,
        august       INTEGER,
        september    INTEGER,
        oktoober     INTEGER,
        november     INTEGER,
        detsember    INTEGER
    ) AS
$BODY$

SELECT l_kpv                                                   AS period,
       rekvid,
       liik::TEXT,
       array_to_string(array_agg(DISTINCT yksused), ',')::TEXT AS yksused,
       count(*)::INTEGER                                       AS lapsed_kokku,
       count(laps_id) FILTER ( WHERE kuu = 1 )::INTEGER        AS jaanuar,
       count(laps_id) FILTER ( WHERE kuu = 2 )::INTEGER        AS veebruar,
       count(laps_id) FILTER ( WHERE kuu = 3 )::INTEGER        AS marts,
       count(laps_id) FILTER ( WHERE kuu = 4 )::INTEGER        AS apriil,
       count(laps_id) FILTER ( WHERE kuu = 5 )::INTEGER        AS mai,
       count(laps_id) FILTER ( WHERE kuu = 6 )::INTEGER        AS juuni,
       count(laps_id) FILTER ( WHERE kuu = 7 )::INTEGER        AS juuli,
       count(laps_id) FILTER ( WHERE kuu = 8 )::INTEGER        AS august,
       count(laps_id) FILTER ( WHERE kuu = 9 )::INTEGER        AS september,
       count(laps_id) FILTER ( WHERE kuu = 10 )::INTEGER       AS oktoober,
       count(laps_id) FILTER ( WHERE kuu = 11 )::INTEGER       AS november,
       count(laps_id) FILTER ( WHERE kuu = 12 )::INTEGER       AS detsember
FROM (
         WITH qryPeriod AS (
             SELECT CASE
                        WHEN l_kpv IS NULL OR empty(l_kpv::TEXT) THEN date(year(current_date), 12, 31)
                        ELSE l_kpv END::DATE AS kpv
         ),
              qry_liik AS (
                  SELECT DISTINCT coalesce((n.properties ->> 'oppe_tyyp')::TEXT, 'Põhiõpe')::TEXT AS liik,
                                  d.id,
                                  array_agg(DISTINCT
                                            lg.kood::TEXT || '-' || coalesce(r.properties ->> 'liik', '') || '-' ||
                                            lg.tyyp)                                              AS yksused
                  FROM qryPeriod,
                       docs.doc d
                           INNER JOIN docs.arv a ON d.id = a.parentid
                           INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                           INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                           INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                           INNER JOIN lapsed.lapse_kaart lk ON lk.parentid = l.parentid AND lk.nomid = a1.nomid
                           INNER JOIN (SELECT l.rekvid,
                                              l.kood,
                                              t.kood AS tyyp
                                       FROM libs.library l
                                                LEFT OUTER JOIN libs.library t ON (l.properties::JSONB ->> 'tyyp')::INTEGER = t.id
                                       WHERE l.library = 'LAPSE_GRUPP'
                       ) lg ON lg.rekvid = d.rekvid AND lg.kood::TEXT = lk.properties ->> 'yksus'
                           INNER JOIN ou.rekv r ON r.id = a.rekvid
                  WHERE year(a.kpv) = year(qryPeriod.kpv)
                    AND a.kpv <= qryPeriod.kpv
                    AND (l_liik IS NULL OR coalesce(r.properties ->> 'liik', '') ILIKE l_liik || '%')
                    AND (l_tyyp IS NULL OR lg.tyyp ILIKE l_tyyp || '%')
                    AND r.id IN (SELECT rekv_id
                                 FROM get_asutuse_struktuur(l_rekvid))

                  GROUP BY (n.properties ->> 'oppe_tyyp')
                         , d.id
              )
         SELECT DISTINCT l.parentid                             AS laps_id,
                         d.rekvid,
                         qry_liik.liik,
                         date_part('month', a.kpv)              AS kuu,
                         array_to_string(qry_liik.yksused, ',') AS yksused
         FROM qryPeriod,
              docs.doc d
                  INNER JOIN docs.arv a ON a.parentid = d.id
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                  INNER JOIN qry_liik ON qry_liik.id = d.id
         WHERE year(a.kpv) = year(qryPeriod.kpv)
           AND a.kpv <= qryPeriod.kpv
           AND a.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
     ) qry
WHERE qry.rekvid IN (SELECT rekv_id
                     FROM get_asutuse_struktuur(l_rekvid))
GROUP BY liik
       , rekvid

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.aasta_naitajad(INTEGER, DATE, TEXT, TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.aasta_naitajad(INTEGER, DATE, TEXT, TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.aasta_naitajad(INTEGER, DATE, TEXT, TEXT) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.aasta_naitajad(INTEGER, DATE, TEXT, TEXT) TO dbvaatleja;


/*
SELECT *
FROM lapsed.aasta_naitajad(85, '2021-03-31')

*/
