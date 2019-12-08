DROP FUNCTION IF EXISTS lapsed.soodustused(INTEGER, INTEGER, DATE, DATE);

CREATE OR REPLACE FUNCTION lapsed.soodustused(l_rekvid INTEGER, l_kond INTEGER DEFAULT 1,
                                              kpv_start DATE DEFAULT date(year(current_date), 1, 1),
                                              kpv_end DATE DEFAULT current_date)
    RETURNS TABLE (
        soodustus       NUMERIC(12, 2),
        period          DATE,
        lapse_isikukood TEXT,
        lapse_nimi      TEXT,
        vanem_nimi      TEXT,
        vanem_isikukood TEXT,
        lapsed          INTEGER,
        pered_kokku INTEGER,
        asutus          TEXT,
        rekvid          INTEGER
    ) AS
$BODY$
with qry as (
    (
        SELECT l.isikukood::TEXT            AS lapse_isikukood,
               l.nimi::TEXT                 AS lapse_nimi,
               lk.soodustus::NUMERIC(12, 2) AS soodustus,
               r.nimetus::TEXT              AS asutus,
               (SELECT asutusid
                FROM lapsed.vanemad v
                WHERE v.parentid = l.id
                  AND v.staatus <> 3
                ORDER BY properties ->> 'arved'
                LIMIT 1)                    AS vanem_id,
               lk.rekvid
        FROM lapsed.laps l
                 INNER JOIN (SELECT lk.parentid,
                                    lk.rekvid,
                                    max((CASE
                                             WHEN (lk.properties ->> 'kas_protsent')::BOOLEAN
                                                 THEN (lk.properties ->> 'soodus')::NUMERIC(12, 2)
                                             ELSE (lk.properties ->> 'soodus')::NUMERIC / lk.hind * 100 END)::NUMERIC(12, 2)) AS soodustus
                             FROM lapsed.lapse_kaart lk
                             WHERE (lk.properties ->> 'soodus')::NUMERIC > 0
                               AND ((lk.properties ->> 'sooduse_alg')::DATE >= kpv_start OR
                                    (lk.properties ->> 'sooduse_alg')::DATE <= kpv_end)
                               AND ((lk.properties ->> 'sooduse_lopp')::DATE >= kpv_end OR
                                    (lk.properties ->> 'sooduse_lopp')::DATE <= kpv_start)
                               AND lk.staatus <> 3
                             GROUP BY lk.rekvid, lk.parentid
        ) lk ON lk.parentid = l.id
                 INNER JOIN ou.rekv r ON r.id = lk.rekvid
    )
)
SELECT soodustus::NUMERIC(12, 2)                                                     AS soodustus,
       kpv_start::DATE                                                               AS period,
       lapse_isikukood,
       lapse_nimi,
       a.nimetus::TEXT                                                               AS vanem_nimi,
       a.regkood::TEXT                                                               AS vanem_isikukood,
       (SELECT count(id) FROM lapsed.vanemad WHERE asutusid = qry.vanem_id)::INTEGER AS lapsed,
       (select count(distinct vanem_id) from qry)::INTEGER as pered_kokku,
       qry.asutus,
       qry.rekvid
FROM  qry
         INNER JOIN libs.asutus a ON a.id = qry.vanem_id


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.soodustused(INTEGER, INTEGER, DATE, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.soodustused(INTEGER, INTEGER, DATE, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.soodustused(INTEGER, INTEGER, DATE, DATE) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.soodustused(INTEGER, INTEGER, DATE, DATE) TO dbvaatleja;


/*
select * from lapsed.soodustused(63, 1)
order by vanem_isikukood, lapse_nimi, asutus
*/
