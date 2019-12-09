DROP FUNCTION IF EXISTS lapsed.statistika(INTEGER, INTEGER, DATE, DATE);



CREATE OR REPLACE FUNCTION lapsed.statistika(l_rekvid INTEGER, l_kond INTEGER DEFAULT 1,
                                             kpv_start DATE DEFAULT date(year(current_date), 1, 1),
                                             kpv_end DATE DEFAULT current_date)
    RETURNS TABLE (
        rekvid         INTEGER,
        nimetus        TEXT,
        text_indikator TEXT,
        indikator_1    NUMERIC(12, 2),
        indikator_2    NUMERIC(12, 2),
        indikator_3    NUMERIC(12, 2),
        indikator_4    NUMERIC(12, 2),
        period         DATE,
        aruanne        TEXT

    )
AS
$$
DECLARE
    is_kond BOOLEAN = NOT empty(l_kond);
BEGIN
    IF kpv_start IS NULL OR empty(kpv_start::TEXT)
    THEN
        kpv_start = date(year(current_date), 1, 1);
    END IF;
    IF kpv_end IS NULL OR empty(kpv_end::TEXT)
    THEN
        kpv_end = date(year(current_date), 12, 31);
    END IF;
    -- кол-во детей в семье
    RETURN QUERY
        SELECT *
        FROM (
                 SELECT l_rekvid,
                        'Lapsed peres (pere suurus / lapsed) '::TEXT AS nimetus,
                        NULL::TEXT,
                        lapsed_peres::NUMERIC(12, 2)                 AS indikator_1,
                        count(*)::NUMERIC(12, 2)                     AS indikator_2,
                        NULL::NUMERIC                                AS indikator_3,
                        NULL::NUMERIC                                AS indikator_4,
                        kpv_start                                    AS period,
                        'stat1'                                      AS aruanne
                 FROM (
                          SELECT array_length(pere, 1) AS lapsed_peres, l_rekvid AS rekvid
                          FROM (
                                   WITH v_lapsed AS (
                                       SELECT l.id      AS laps_id,
                                              (SELECT asutusid
                                               FROM lapsed.vanemad v
                                               WHERE v.parentid = l.id
                                                 AND v.staatus <> 3
                                               ORDER BY properties ->> 'arved'
                                               LIMIT 1) AS vanem_id
                                       FROM lapsed.laps l
                                       WHERE l.staatus <> 3
                                         AND l.id IN (
                                           SELECT parentid
                                           FROM lapsed.lapse_kaart lk
                                           WHERE ((properties ->> 'alg_kpv') IS NULL
                                               OR (properties ->> 'lopp_kpv')::DATE >= kpv_start
                                               OR (properties ->> 'alg_kpv')::DATE <= kpv_end)
                                             AND lk.staatus <> 3
                                             AND lk.rekvid IN (SELECT rekv_id
                                                               FROM get_asutuse_struktuur(l_rekvid))
                                             AND (lk.rekvid = l_rekvid OR l_kond = 1)
                                       )
                                   )
                                   SELECT DISTINCT array_agg(DISTINCT v.laps_id) AS pere, vanem_id
                                   FROM v_lapsed v
                                   WHERE vanem_id IS NOT NULL
                                   GROUP BY vanem_id
                               ) pere
                          GROUP BY pere
                      ) qry
                 GROUP BY lapsed_peres
                 ORDER BY lapsed_peres DESC
             ) subqry
        UNION ALL
        SELECT l_rekvid                                                AS rekvid,
               'soodustuse saajad, kood, kogus, protsent, summa'::TEXT AS nimetus,
               kood::TEXT,
               count(laps_id)::NUMERIC                                 AS indikator_1,
               soodustuse_protsent::NUMERIC                            AS indikator_2,
               sum(soodustus)::NUMERIC                                 AS indikator_3,
               NULL::NUMERIC                                           AS indikator_4,
               kpv_start                                               AS period,
               'stat2'                                                 AS aruanne

        FROM (
                 SELECT l.parentid                                          AS laps_id,
                        n.kood::TEXT                                        AS kood,
                        a1.kogus * (a1.properties ->> 'soodustus')::NUMERIC AS soodustus,
                        round(coalesce((a1.properties ->> 'soodustus')::NUMERIC, 0)::NUMERIC /
                              ((coalesce((a1.properties ->> 'soodustus')::NUMERIC, 0)::NUMERIC + a1.hind)) *
                              100)                                          AS soodustuse_protsent
                 FROM docs.doc d
                          INNER JOIN docs.arv a ON a.parentid = d.id
                          INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                          INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                          INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
                          INNER JOIN (
                     SELECT lk.nomid, parentid AS laps_id, hind, (properties ->> 'soodus')::NUMERIC AS soodustus
                     FROM lapsed.lapse_kaart lk
                     WHERE properties ->> 'soodus' IS NOT NULL
                       AND (properties ->> 'soodus')::NUMERIC > 0
                 ) lk ON lk.laps_id = l.parentid AND lk.nomid = a1.nomid
                 WHERE a1.properties ->> 'soodustus' IS NOT NULL
                   AND (a1.properties ->> 'soodustus')::NUMERIC > 0
                   AND a.kpv >= kpv_start
                   AND a.kpv <= kpv_end
                   AND d.rekvid IN (SELECT rekv_id
                                    FROM get_asutuse_struktuur(l_rekvid))
                   AND (d.rekvid = l_rekvid OR l_kond = 1)
             ) qry
        GROUP BY kood, soodustuse_protsent;

END;
$$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.statistika(INTEGER, INTEGER, DATE, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.statistika(INTEGER, INTEGER, DATE, DATE) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.statistika(INTEGER, INTEGER, DATE, DATE) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.statistika(INTEGER, INTEGER, DATE, DATE) TO arvestaja;

/*

SELECT *
FROM lapsed.statistika(63, 1)

--test
*/
