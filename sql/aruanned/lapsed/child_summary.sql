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
        jaak             NUMERIC(12, 2),
        rekvid           INTEGER
    ) AS
$BODY$
SELECT c.nimetus::TEXT   AS maksja_nimi,
       c.regkood::TEXT   AS maksja_isikukood,
       l.nimi::TEXT      AS lapse_nimi,
       l.isikukood::TEXT AS lapse_isikukood,
       a.number::TEXT    AS number,
       a.kpv             AS kpv,
       a.summa           AS summa,
       a.jaak            AS jaak,
       d.rekvid          AS rekvid
FROM docs.doc d
         INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
         INNER JOIN lapsed.laps l ON l.id = ld.parentid
         INNER JOIN docs.arv a ON a.parentid = d.id
         INNER JOIN libs.asutus c ON c.id = a.asutusid
WHERE d.rekvid IN (SELECT rekv_id
                   FROM get_asutuse_struktuur(l_rekvid))

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

*/