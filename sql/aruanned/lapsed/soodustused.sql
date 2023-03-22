DROP FUNCTION IF EXISTS lapsed.soodustused(INTEGER, INTEGER, DATE, DATE);

CREATE OR REPLACE FUNCTION lapsed.soodustused(l_rekvid INTEGER, l_kond INTEGER DEFAULT 1,
                                              kpv_start DATE DEFAULT date(year(current_date), 1, 1),
                                              kpv_end DATE DEFAULT current_date)
    RETURNS TABLE (
        soodustus       NUMERIC(12, 2),
        summa           NUMERIC(12, 2),
        arv_percent     NUMERIC(12, 4),
        period          DATE,
        lapse_isikukood TEXT,
        lapse_nimi      TEXT,
        vanem_nimi      TEXT,
        vanem_isikukood TEXT,
        lapsed          INTEGER,
        pered_kokku     INTEGER,
        asutus          TEXT,
        rekvid          INTEGER,
        viitenumber     TEXT,
        vead_kokku      INTEGER,
        percent         TEXT,
        viga            TEXT,
        kood            TEXT,
        vanem_id        INTEGER
    )
AS
$BODY$
WITH qry AS (
    (
        WITH params AS (
            SELECT alg_kpv,
                   lopp_kpv,
                   make_date(date_part('year', kp.alg_kpv)::INTEGER, date_part('month', kp.alg_kpv)::INTEGER,
                             1)      AS arv_alg_kpv,
                   make_date(date_part('year', kp.lopp_kpv)::INTEGER, date_part('month', kp.lopp_kpv)::INTEGER,
                             1)      AS arv_lopp_kpv,
                   ('[' ||
                    format_date(coalesce(kp.alg_kpv::TEXT, make_date(year(current_date), 01, 01)::TEXT))::TEXT ||
                    ',' ||
                    (format_date((kp.lopp_kpv::DATE + CASE
                                                          WHEN kp.alg_kpv::DATE = kp.lopp_kpv::DATE
                                                              THEN INTERVAL '1 day'
                                                          ELSE INTERVAL '0 day' END)::TEXT)::TEXT) ||
                    ')') ::DATERANGE AS range

            FROM (
                     SELECT kpv_start::DATE AS alg_kpv,
                            kpv_end::DATE   AS lopp_kpv) kp
        ),
             rekv_ids AS (
                 SELECT rekv_id
                 FROM public.get_asutuse_struktuur(l_rekvid) r
                 WHERE CASE
                           WHEN l_kond = 1 THEN TRUE
                           ELSE l_rekvid = rekv_id END
                   AND rekv_id IN (SELECT id
                                   FROM ou.rekv rekv
                                   WHERE rekv.parentid = 119
                                     AND rekv.properties ->> 'liik' = 'LASTEAED')
             ),
             soodustused AS (
                 SELECT sum(summa)      AS summa,
                        sum(soodustus)  AS soodustus,
                        lt.parentid     AS laps_id,
                        lt.rekvid,
                        sum(tais_summa) AS tais_summa,
                        lt.kood
                 FROM (SELECT lt.summa, lt.soodustus, lt.parentid, lt.rekvid, (lt.hind * lt.kogus) AS tais_summa, n.kood
                       FROM lapsed.lapse_taabel lt,
                            libs.nomenklatuur n,
                            params
                       WHERE lt.staatus <> 3
                         AND lt.hind <> 0
                         AND lt.nomid = n.id
                         AND make_date(aasta, kuu, 1) >= params.arv_alg_kpv
                         AND make_date(aasta, kuu, 1) <= params.arv_lopp_kpv
                         AND lt.rekvid IN (SELECT rekv_id FROM rekv_ids)
                      ) lt
                 WHERE lt.soodustus <> 0
                 GROUP BY lt.parentid
                         , lt.rekvid
                         , lt.kood
             ),
             esindajad AS (
                 SELECT asutusid,
                        parentid                               AS laps_id,
                        count(id) OVER (PARTITION BY asutusid) AS lapsed_peres
                 FROM lapsed.vanemad v,
                      params
                 WHERE v.staatus <> 3
                   AND coalesce((v.properties ->> 'kas_esindaja')::BOOLEAN, FALSE)
                   AND exists(SELECT id
                              FROM lapsed.lapse_kaart lk
                              WHERE lk.parentid = v.parentid
                                AND (params.range && (('[' || ((lk.properties ->> 'alg_kpv')::DATE)::TEXT || ',' ||
                                                       (CASE
                                                            WHEN (lk.properties ->> 'alg_kpv')::DATE >=
                                                                 (lk.properties ->> 'lopp_kpv')::DATE
                                                                THEN (lk.properties ->> 'alg_kpv')::DATE
                                                            ELSE (lk.properties ->> 'lopp_kpv')::DATE END)::TEXT ||
                                                       ')') ::DATERANGE)
                                  OR ((lk.properties ->> 'alg_kpv')::DATE,
                                      (lk.properties ->> 'lopp_kpv')::DATE) OVERLAPS
                                     (params.arv_alg_kpv, params.arv_lopp_kpv))
                                AND lk.rekvid IN
                                    (SELECT id
                                     FROM ou.rekv rekv
                                     WHERE rekv.parentid = 119
                                       AND rekv.properties ->> 'liik' = 'LASTEAED')
                                AND lk.staatus < 3
                     )
             )

        SELECT l.isikukood::TEXT                          AS lapse_isikukood,
               l.nimi::TEXT                               AS lapse_nimi,
               s.kood,
               s.soodustus::NUMERIC(12, 2)                AS soodustus,
               s.summa::NUMERIC(12, 2)                    AS summa,
               round(s.soodustus / s.tais_summa * 100, 0) AS arv_percent,
               r.nimetus::TEXT                            AS asutus,
               e.asutusid                                 AS vanem_id,
               e.lapsed_peres                             AS lapsed_peres,
               (SELECT count(*)
                FROM (SELECT DISTINCT asutusid
                      FROM esindajad es
                      WHERE es.laps_id IN (SELECT sd.laps_id FROM soodustused sd)
                     ) es)
                                                          AS pered_kokku,
               s.rekvid,
               lapsed.get_viitenumber(s.rekvid, l.id)     AS viitenumber

        FROM lapsed.laps l
                 INNER JOIN soodustused s ON s.laps_id = l.id
                 INNER JOIN ou.rekv r ON r.id = s.rekvid
                 LEFT OUTER JOIN esindajad e ON e.laps_id = l.id
        WHERE s.soodustus <> 0
    )
)
SELECT soodustus::NUMERIC(12, 2)                    AS soodustus,
       summa::NUMERIC(12, 2)                        AS summa,
       arv_percent::NUMERIC(12, 4)                  AS arv_percent,
       kpv_start::DATE                              AS period,
       lapse_isikukood,
       lapse_nimi,
       a.nimetus::TEXT                              AS vanem_nimi,
       coalesce(a.regkood, 'Esindaja puudub')::TEXT AS vanem_isikukood,
       coalesce(qry.lapsed_peres, 0) ::INTEGER      AS lapsed,
       qry.pered_kokku ::INTEGER                    AS pered_kokku,
       qry.asutus,
       qry.rekvid,
       qry.viitenumber::TEXT,
       sum(CASE
               WHEN lapsed_peres < 2 AND soodustus > 0 THEN 1
               WHEN lapsed_peres <= 2 AND arv_percent > 25 THEN 1
               WHEN lapsed_peres = 2 AND arv_percent <> 25 THEN 1
               WHEN lapsed_peres > 2 AND arv_percent < 100 THEN 1
               ELSE 0 END) OVER ()::INTEGER         AS vead_kokku,
       CASE
           WHEN lapsed_peres = 1 THEN '0'
           WHEN lapsed_peres = 2 THEN '25'
           WHEN lapsed_peres >= 3 THEN '100'
           ELSE '' END::TEXT                        AS percent,
       CASE
           WHEN coalesce(lapsed_peres, 0) < 2 AND arv_percent > 0 THEN 'Viga, <> 0'
           WHEN lapsed_peres = 2 AND arv_percent <> 25 THEN 'Viga, <> 25'
           WHEN lapsed_peres > 2 AND arv_percent < 100 THEN 'Viga, < 100'
           ELSE NULL::TEXT
           END::TEXT                                AS viga,
       qry.kood::TEXT,
       qry.vanem_id
FROM qry
         LEFT OUTER JOIN libs.asutus a ON a.id = qry.vanem_id


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.soodustused(INTEGER, INTEGER, DATE, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.soodustused(INTEGER, INTEGER, DATE, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.soodustused(INTEGER, INTEGER, DATE, DATE) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.soodustused(INTEGER, INTEGER, DATE, DATE) TO dbvaatleja;


/*



*/
