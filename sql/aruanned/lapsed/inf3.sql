DROP FUNCTION IF EXISTS lapsed.inf3(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.inf3(l_rekvid INTEGER, l_kond INTEGER DEFAULT 0)
    RETURNS TABLE (
        summa            NUMERIC(14, 2),
        maksja_nimi      TEXT,
        maksja_isikukood TEXT,
        lapse_nimi       TEXT,
        lapse_isikukood  TEXT,
        aasta            INTEGER,
        rekvid           INTEGER
    )
AS
$BODY$
SELECT sum(summa)            AS summa,
       a.nimetus::TEXT       AS maksja_nimi,
       a.regkood::TEXT       AS maksja_isikukood,
       lapse_nimi::TEXT      AS lapse_nimi,
       lapse_isikukood::TEXT AS lapse_isikukood,
       aasta::INTEGER        AS aasta,
       qry.rekvid            AS rekvid
FROM (
         SELECT at.rekvid     AS rekvid,
                l.nimi        AS lapse_nimi,
                l.isikukood   AS lapse_isikukood,
                at.inf3_summa AS summa,
                (SELECT m1.asutusid
                 FROM docs.mk m
                          INNER JOIN docs.mk1 m1 ON m.id = m1.parentid
                 WHERE at.doc_tasu_id = m.parentid
                 LIMIT 1)     AS asutusId,
                year(at.kpv)  AS aasta,
                at.doc_arv_id
         FROM docs.arvtasu at
                  INNER JOIN lapsed.liidestamine ld ON ld.docid = at.doc_tasu_id
                  INNER JOIN lapsed.laps l ON l.id = ld.parentid
                  INNER JOIN docs.arv a ON a.parentid = at.doc_arv_id
         WHERE at.rekvid IN (SELECT rekv_id
                             FROM get_asutuse_struktuur(l_rekvid))
           AND at.status <> 3
           AND coalesce(a.properties ->> 'tyyp', '') <> 'ETTEMAKS'
     ) qry
         INNER JOIN libs.asutus a ON a.id = qry.asutusId
GROUP BY lapse_isikukood, lapse_nimi, a.nimetus, a.regkood, aasta, qry.rekvid;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, INTEGER) TO arvestaja;

/*

SELECT *
FROM lapsed.inf3(88, 1)

*/