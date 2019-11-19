DROP FUNCTION IF EXISTS lapsed.inf3(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.inf3(l_rekvid INTEGER, l_kond INTEGER DEFAULT 0)
    RETURNS TABLE (
        summa            NUMERIC(14, 2),
        maksja_nimi      TEXT,
        maksja_isikukood TEXT,
        lapse_nimi       TEXT,
        lapse_isikukood   TEXT,
        aasta            INTEGER,
        rekvid           INTEGER
    ) AS
$BODY$
SELECT sum(summa)            AS summa,
       a.nimetus::TEXT       AS maksja_nimi,
       a.regkood::TEXT       AS maksja_isikukood,
       lapse_nimi::TEXT      AS lapse_nimi,
       lapse_isikukood::TEXT AS lapse_isikukood,
       aasta::INTEGER        AS aasta,
       qry.rekvid                AS rekvid
FROM (
         SELECT d.rekvid                                                                  AS rekvid,
                l.nimi                                                                    AS lapse_nimi,
                l.isikukood                                                               AS lapse_isikukood,
                a1.summa                                                                  AS summa,
                (SELECT asutusid FROM docs.arvtasu at WHERE at.doc_arv_id = d.id LIMIT 1) AS asutusId,
                year(a.kpv)                                                               AS aasta
         FROM docs.doc d
                  INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                  INNER JOIN lapsed.laps l ON l.id = ld.parentid
                  INNER JOIN docs.arv a ON a.parentid = d.id
                  INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                  INNER JOIN lapsed.lapse_kaart lk ON lk.parentid = ld.parentid AND lk.nomid = a1.nomid

         WHERE d.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))

           AND a.parentid IN (
             SELECT d.id
             FROM docs.doc d
                      INNER JOIN docs.arv a ON a.parentId = d.id
                      INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
             WHERE a.jaak = 0
         )
           AND (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
           AND coalesce((lk.properties ->> 'kas_inf3')::BOOLEAN, FALSE)::BOOLEAN
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

/*

SELECT *
FROM lapsed.inf3(63, 1)

*/