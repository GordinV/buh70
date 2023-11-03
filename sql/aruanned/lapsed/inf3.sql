DROP FUNCTION IF EXISTS lapsed.inf3(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.inf3(INTEGER, TEXT);

CREATE OR REPLACE FUNCTION lapsed.inf3(l_rekvid INTEGER, l_aasta TEXT DEFAULT year(current_date)::TEXT)
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
WITH params AS (
    SELECT CASE
               WHEN l_aasta IS NULL OR l_aasta::TEXT = '' THEN year(current_date)::TEXT
               ELSE l_aasta END::INTEGER AS aasta
)

SELECT sum(summa)            AS summa,
       a.nimetus::TEXT       AS maksja_nimi,
       a.regkood::TEXT       AS maksja_isikukood,
       lapse_nimi::TEXT      AS lapse_nimi,
       lapse_isikukood::TEXT AS lapse_isikukood,
       qry.aasta::INTEGER    AS aasta,
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
                           INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid,
                       params
                  WHERE a.rekvid IN (SELECT rekv_id
                                     FROM rekv_ids)
                    AND a.tasud IS NOT NULL
                    AND YEAR(a.tasud) >= params.aasta
                    AND COALESCE((n.properties ->> 'kas_inf3')::BOOLEAN, FALSE)
                    AND COALESCE(a.properties ->> 'tyyp', '') <> 'ETTEMAKS'

                  GROUP BY a.parentid, a.summa
              ),
              tasud AS (
                  SELECT DISTINCT asutusid, M.parentid AS tasu_id
                  FROM docs.mk M
                           INNER JOIN docs.mk1 m1 ON M.id = m1.parentid
                           INNER JOIN lapsed.liidestamine l ON l.docid = M.parentid,
                       params
                  WHERE M.rekvid IN (SELECT rekv_id
                                     FROM rekv_ids)
                    AND YEAR(M.maksepaev) = params.aasta
              )
         SELECT AT.rekvid                                             AS rekvid,
                l.nimi                                                AS lapse_nimi,
                l.isikukood                                           AS lapse_isikukood,
                round((arved.a1_summa / arved.a_kokku) * AT.summa, 2) AS summa,
                tasud.asutusid                                        AS asutusId,
                YEAR(AT.kpv)                                          AS aasta,
                AT.doc_arv_id
         FROM docs.arvtasu AT
                  INNER JOIN lapsed.liidestamine ld
                             ON ld.docid = AT.doc_tasu_id
                  INNER JOIN lapsed.laps l ON l.id = ld.parentid
                  INNER JOIN arved ON arved.id = AT.doc_arv_id
                  INNER JOIN tasud ON tasud.tasu_id = AT.doc_tasu_id
         WHERE AT.rekvid IN (SELECT rekv_id
                             FROM rekv_ids)
           AND AT.status <> 3
     ) qry
         INNER JOIN libs.asutus a ON a.id = qry.asutusId,
     params
WHERE qry.summa IS NOT NULL
  AND len(ltrim(rtrim(a.regkood))) >= 11 -- только частники
  AND extract('year' FROM age(make_date(params.aasta, 01, 01), palk.get_sunnipaev(qry.lapse_isikukood))) <
      18                                 -- только до 18 лет
GROUP BY lapse_isikukood, lapse_nimi, a.nimetus, a.regkood, qry.aasta, qry.rekvid;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, TEXT) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, TEXT) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, TEXT) TO arvestaja;


/*

SELECT *
FROM lapsed.inf3(83, '2023')

*/