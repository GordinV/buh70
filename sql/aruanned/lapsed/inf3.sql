DROP FUNCTION IF EXISTS lapsed.inf3(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.inf3(l_rekvid INTEGER, l_aasta INTEGER DEFAULT year(current_date))
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
         WITH rekv_ids AS (
             SELECT rekv_id
             FROM get_asutuse_struktuur(l_rekvid)
         ),
              arved AS (
                  SELECT a.parentid    AS id,
                         sum(a1.summa) AS a1_summa,
                         a.summa       AS a_kokku
                  FROM docs.arv a
                           INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
                           INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                  WHERE a.rekvid IN (SELECT rekv_id
                                     FROM rekv_ids)
                    AND a.tasud IS NOT NULL
                    AND year(a.tasud) >= l_aasta
                    AND coalesce((n.properties ->> 'kas_inf3')::BOOLEAN, FALSE)
                    AND coalesce(a.properties ->> 'tyyp', '') <> 'ETTEMAKS'

                  GROUP BY a.parentid, a.summa
              ),
              tasud AS (
                  SELECT DISTINCT asutusid, m.parentid AS tasu_id
                  FROM docs.mk m
                           INNER JOIN docs.mk1 m1 ON m.id = m1.parentid
                           INNER JOIN lapsed.liidestamine l ON l.docid = m.parentid
                  WHERE m.rekvid IN (SELECT rekv_id
                                     FROM rekv_ids)
                    AND year(m.maksepaev) = l_aasta
              )
         SELECT at.rekvid                                             AS rekvid,
                l.nimi                                                AS lapse_nimi,
                l.isikukood                                           AS lapse_isikukood,
                round((arved.a1_summa / arved.a_kokku) * at.summa, 2) AS summa,
                tasud.asutusid                                        AS asutusId,
                year(at.kpv)                                          AS aasta,
                at.doc_arv_id
         FROM docs.arvtasu at
                  INNER JOIN lapsed.liidestamine ld ON ld.docid = at.doc_tasu_id
                  INNER JOIN lapsed.laps l ON l.id = ld.parentid
                  INNER JOIN arved ON arved.id = at.doc_arv_id
                  INNER JOIN tasud ON tasud.tasu_id = at.doc_tasu_id
         WHERE at.rekvid IN (SELECT rekv_id
                             FROM rekv_ids)
           AND at.status <> 3
     ) qry
         INNER JOIN libs.asutus a ON a.id = qry.asutusId
WHERE qry.summa IS NOT NULL
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
FROM lapsed.inf3(83, 1)

*/