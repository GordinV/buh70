DROP FUNCTION IF EXISTS lapsed.child_summary(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.child_summary(INTEGER, INTEGER, TEXT, TEXT);

CREATE OR REPLACE FUNCTION lapsed.child_summary(l_rekvid INTEGER, l_kond INTEGER DEFAULT 0, l_ik TEXT DEFAULT '%',
                                                l_nimi TEXT DEFAULT '%')
    RETURNS TABLE (
        maksja_nimi      TEXT,
        maksja_isikukood TEXT,
        lapse_nimi       TEXT,
        lapse_isikukood  TEXT,
        number           TEXT,
        kpv              DATE,
        summa            NUMERIC(12, 2),
        tasutud          NUMERIC(12, 2),
        mahakandmine     NUMERIC(12, 2),
        jaak             NUMERIC(12, 2),
        rekvid           INTEGER
    )
AS
$BODY$
WITH qryRekv AS (
    SELECT rekv_id
    FROM get_asutuse_struktuur(l_rekvid)
),
     qryLapsed AS (
         SELECT *
         FROM lapsed.laps l
         WHERE staatus <> 3
           AND l.isikukood LIKE rtrim(l_ik) || '%'
           AND l.nimi ILIKE '%' || ltrim(rtrim(l_nimi)) || '%'
     ),
     qryArved AS (
         SELECT a.asutusid,
                ld.parentid                                 AS laps_id,
                a.number::TEXT                              AS number,
                a.kpv                                       AS kpv,
                a.summa::NUMERIC(12, 2)                     AS summa,
                coalesce(t.summa, 0)::NUMERIC(12, 2)        AS tasutud,
                coalesce(t.mahakandmine, 0)::NUMERIC(12, 2) AS mahakandmine,
                a.jaak::NUMERIC(12, 2)                      AS jaak,
                d.rekvid                                    AS rekvid
         FROM docs.doc d
                  INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                  INNER JOIN docs.arv a ON a.parentid = d.id
                  LEFT OUTER JOIN (SELECT doc_arv_id,
                                          sum(CASE WHEN at.pankkassa < 3 THEN summa ELSE 0 END) AS summa,
                                          sum(CASE WHEN at.pankkassa = 3 THEN summa ELSE 0 END) AS mahakandmine
                                   FROM docs.arvtasu at
                                   WHERE at.rekvid IN (SELECT rekv_id
                                                       FROM qryRekv)
                                     AND at.status < 3
                                   GROUP BY doc_arv_id) t
                                  ON t.doc_arv_id = d.id
         WHERE d.rekvid IN (SELECT rekv_id
                            FROM qryRekv)
           AND (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
           AND ld.parentid IN (SELECT id FROM qryLapsed)
     ),
     qrytasud AS (
         SELECT mk1.asutusid,
                l.parentid                          AS laps_id,
                NULL::TEXT                          AS number,
                mk.maksepaev                        AS kpv,
                0                                   AS summa,
                mk_tyyp * mk1.summa::NUMERIC(12, 2) AS tasutud,
                0                                   AS mahakandmine,
--                -1 * mk_tyyp * ymk.summa::NUMERIC(12, 2) AS jaak,
                -1 * mk_tyyp * mk.jaak,
                d.rekvid                            AS rekvid
         FROM docs.doc D
                  INNER JOIN (SELECT mk.id,
                                     mk.parentid,
                                     mk.viitenr,
                                     mk.jaak,
                                     mk.maksepaev,
                                     CASE WHEN mk.opt = 1 THEN -1 ELSE 1 END AS mk_tyyp
                              FROM docs.mk mk
                              WHERE mk.jaak <> 0
                                AND rekvid IN (SELECT rekv_id
                                               FROM qryRekv)
         ) mk ON mk.parentid = D.id
                  INNER JOIN lapsed.liidestamine l
                             ON l.docid = D.id
                  INNER JOIN (SELECT DISTINCT mk1.parentid, mk1.asutusid, sum(mk1.summa) AS summa
                              FROM docs.mk1,
                                   docs.mk
                              WHERE mk.id = mk1.parentid
                                AND mk.rekvid IN (SELECT rekv_id
                                                  FROM qryRekv)
                              GROUP BY mk1.asutusid, mk1.parentid
         ) mk1 ON mk1.parentid = mk.id
              --                ,
              --             lapsed.get_group_part_from_mk(D.id, current_date) AS ymk
         WHERE D.status <> 3
           AND D.rekvid IN (SELECT rekv_id
                            FROM qryRekv)
           AND l.parentid IN (SELECT id FROM qryLapsed)
     )
SELECT a.nimetus::TEXT   AS maksja_nimi,
       a.regkood::TEXT   AS maksja_isikukood,
       l.nimi::TEXT      AS lapse_nimi,
       l.isikukood::TEXT AS lapse_isikukood,
       qryDoc.number::TEXT,
       qryDoc.kpv::DATE,
       qryDoc.summa:: NUMERIC(12, 2),
       qryDoc.tasutud:: NUMERIC(12, 2),
       qryDoc.mahakandmine:: NUMERIC(12, 2),
       qryDoc.jaak:: NUMERIC(12, 2),
       qryDoc.rekvid:: INTEGER

FROM (
         SELECT *
         FROM qryArved
         UNION ALL
         SELECT *
         FROM qrytasud
     ) qryDoc,
     libs.asutus a,
     qryLapsed l
WHERE qryDoc.asutusid = a.id
  AND l.id = qryDoc.laps_id

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.child_summary(INTEGER, INTEGER, TEXT, TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.child_summary(INTEGER, INTEGER, TEXT, TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.child_summary(INTEGER, INTEGER, TEXT, TEXT) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.child_summary(INTEGER, INTEGER, TEXT, TEXT) TO dbvaatleja;

/*

SELECT *
FROM lapsed.child_summary(69, 1)
where lapse_isikukood = '60901163721'

*/