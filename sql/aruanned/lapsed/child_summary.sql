DROP FUNCTION IF EXISTS lapsed.child_summary(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.child_summary(l_rekvid INTEGER, l_kond INTEGER DEFAULT 0)
    RETURNS TABLE (
        maksja_nimi      TEXT,
        maksja_isikukood TEXT,
        lapse_nimi       TEXT,
        lapse_isikukood  TEXT,
        number           TEXT,
        kpv              DATE,
        summa            NUMERIC(12, 2),
        tasutud          NUMERIC(12, 2),
        jaak             NUMERIC(12, 2),
        rekvid           INTEGER
    ) AS
$BODY$
WITH qryArved AS (
    SELECT c.nimetus::TEXT                      AS maksja_nimi,
           c.regkood::TEXT                      AS maksja_isikukood,
           l.nimi::TEXT                         AS lapse_nimi,
           l.isikukood::TEXT                    AS lapse_isikukood,
           a.number::TEXT                       AS number,
           a.kpv                                AS kpv,
           a.summa::NUMERIC(12, 2)              AS summa,
           coalesce(t.summa, 0)::NUMERIC(12, 2) AS tasutud,
           a.jaak::NUMERIC(12, 2)               AS jaak,
           d.rekvid                             AS rekvid
    FROM docs.doc d
             INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
             INNER JOIN lapsed.laps l ON l.id = ld.parentid
             INNER JOIN docs.arv a ON a.parentid = d.id
             INNER JOIN libs.asutus c ON c.id = a.asutusid
             LEFT OUTER JOIN (SELECT doc_arv_id, sum(summa) AS summa FROM docs.arvtasu at GROUP BY doc_arv_id) t
                             ON t.doc_arv_id = d.id
    WHERE d.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
),
     qrytasud AS (
         SELECT a.nimetus::TEXT                AS maksja_nimi,
                a.regkood::TEXT                AS maksja_isikukood,
                laps.nimi::TEXT                AS lapse_nimi,
                laps.isikukood::TEXT           AS lapse_isikukood,
                NULL::TEXT                     AS number,
                mk.maksepaev                   AS kpv,
                0                              AS summa,
                ymk.summa::NUMERIC(12, 2)      AS tasutud,
                -1 * ymk.summa::NUMERIC(12, 2) AS jaak,
                d.rekvid                       AS rekvid
         FROM docs.doc D
                  INNER JOIN (SELECT mk.id, mk.parentid, mk.viitenr, mk.jaak, mk.maksepaev
                              FROM docs.mk mk
                              WHERE mk.jaak <> 0
         ) mk ON mk.parentid = D.id
                  INNER JOIN lapsed.liidestamine l
                             ON l.docid = D.id
                  INNER JOIN docs.mk1 mk1 ON mk1.parentid = mk.id
                  INNER JOIN libs.asutus a ON a.id = mk1.asutusid
                  INNER JOIN lapsed.laps laps ON laps.id = l.parentid
                 ,
              lapsed.get_group_part_from_mk(D.id, current_date) AS ymk
         WHERE D.status <> 3
           AND D.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
     )
SELECT *
FROM qryArved
UNION ALL
SELECT *
FROM qrytasud


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.child_summary(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.child_summary(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.child_summary(INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.child_summary(INTEGER, INTEGER) TO dbvaatleja;

/*

SELECT *
FROM lapsed.child_summary(63, 1)
where lapse_isikukood = '40308233762'

*/