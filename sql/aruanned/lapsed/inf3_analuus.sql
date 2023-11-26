DROP FUNCTION IF EXISTS lapsed.inf3_analuus(INTEGER, TEXT);

CREATE OR REPLACE FUNCTION lapsed.inf3_analuus(l_rekvid INTEGER, l_aasta TEXT DEFAULT year(current_date)::TEXT)
    RETURNS TABLE (
        lapse_isikukood  TEXT,
        lapse_nimi       TEXT,
        maksja_isikukood TEXT,
        maksja_nimi      TEXT,
        asutus           TEXT,
        number           TEXT,
        kpv              DATE,
        summa            NUMERIC(14, 2),
        markused         TEXT
    )
AS
$BODY$
WITH params AS (
    SELECT CASE
               WHEN l_aasta IS NULL OR l_aasta::TEXT = '' THEN year(current_date)::TEXT
               ELSE l_aasta END::INTEGER AS aasta,
           l_rekvid                      AS rekv_id
),
     rekv_ids AS (
         SELECT a.rekv_id
         FROM params p,
              get_asutuse_struktuur(p.rekv_id) a
     ),
     inf3 AS (SELECT *
              FROM lapsed.inf3((SELECT rekv_id FROM params), (SELECT aasta::TEXT FROM params))
     ),
     arved AS (
         WITH docs_types AS (
             SELECT id, kood FROM libs.library WHERE library.library = 'DOK' AND kood IN ('ARV')
         ),
              arv_ids AS (SELECT unnest(string_to_array(inf3.docs_arv_ids, ','))::TEXT AS id
                          FROM inf3)

         SELECT D.id,
                D.rekvid,
                a.kpv,
                a.number,
                a1.summa,
                a.asutusid                                              AS maksja_id,
                l.parentid                                              AS laps_id,
                coalesce((n.properties ->> 'kas_inf3')::BOOLEAN, FALSE) AS kas_inf
         FROM docs.doc D
                  INNER JOIN docs.arv a ON D.id = a.parentid
                  INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                  INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
         WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND D.status < 3
           AND D.doc_type_id IN (SELECT id FROM docs_types)
           AND D.id IN (SELECT id::INTEGER FROM arv_ids WHERE id <> '')
     ),
     tasud AS (
         WITH docs_types AS (
             SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood IN ('SMK', 'MK')
         ),
              tasu_ids AS (SELECT unnest(string_to_array(inf3.docs_tasu_ids, ','))::TEXT AS id
                           FROM inf3)

         SELECT d.id,
                d.rekvid,
                mk.number,
                mk.maksepaev AS kpv,
                at.summa,
                mk1.asutusid AS maksja_id,
                l.parentid   AS laps_id
         FROM docs.doc d
                  INNER JOIN docs.mk mk ON mk.parentid = d.id
                  INNER JOIN docs.mk1 mk1 ON mk.id = mk1.parentid
                  INNER JOIN docs.arvtasu at ON at.doc_tasu_id = mk.parentid
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
         WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND D.status < 3
           AND D.doc_type_id IN (SELECT id FROM docs_types)
           AND D.id IN (SELECT id::INTEGER FROM tasu_ids WHERE id <> '')
           AND mk.opt = 2
           AND mk1.summa > 0
     ),
     tagastused AS (
         WITH docs_types AS (
             SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood IN ('VMK', 'MK')
         ),
              tasu_ids AS (SELECT unnest(string_to_array(inf3.doc_tagastused_ids, ','))::TEXT AS id
                           FROM inf3)

         SELECT d.id,
                d.rekvid,
                mk.number,
                mk.maksepaev AS kpv,
                mk1.summa,
                mk1.asutusid AS maksja_id,
                l.parentid   AS laps_id
         FROM docs.doc d
                  INNER JOIN docs.mk mk ON mk.parentid = d.id
                  INNER JOIN docs.mk1 mk1 ON mk.id = mk1.parentid
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
         WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND D.status < 3
           AND D.doc_type_id IN (SELECT id FROM docs_types)
           AND D.id IN (SELECT id::INTEGER FROM tasu_ids WHERE id <> '')
           AND mk.opt = 2
           AND mk1.summa > 0
     )

SELECT l.isikukood::TEXT AS lapse_isikukood,
       l.nimi::TEXT      AS lapse_nimi,
       i.regkood::TEXT   AS maksja_isikukood,
       i.nimetus::TEXT   AS maksja_nimi,
       r.nimetus::TEXT   AS asutus,
       docs.number::TEXT,
       docs.kpv::DATE,
       docs.summa::NUMERIC(14, 2),
       docs.markused::TEXT
FROM (
         SELECT a.laps_id,
                a.maksja_id,
                a.rekvid,
                a.number::TEXT,
                a.kpv::DATE,
                a.summa:: NUMERIC(14, 2),
                'Usluga INF3 ' || CASE WHEN a.kas_inf THEN 'YES' ELSE 'NO' END::TEXT AS markused
         FROM arved a
         UNION ALL
         SELECT t.laps_id,
                t.maksja_id,
                t.rekvid,
                t.number::TEXT,
                t.kpv::DATE,
                t.summa:: NUMERIC(14, 2),
                'Oplata'::TEXT AS markused
         FROM tasud t
         UNION ALL
         SELECT t.laps_id,
                t.maksja_id,
                t.rekvid,
                t.number::TEXT,
                t.kpv::DATE,
                -1 * t.summa:: NUMERIC(14, 2),
                'Vozvrat'::TEXT AS markused
         FROM tagastused t
     ) docs
         INNER JOIN lapsed.laps l ON l.id = docs.laps_id
         INNER JOIN libs.asutus i ON i.id = docs.maksja_id
         INNER JOIN ou.rekv r
                    ON r.id = docs.rekvid

UNION ALL
SELECT inf3.lapse_isikukood::TEXT                                             AS lapse_isikukood,
       inf3.lapse_nimi::TEXT,
       inf3.maksja_isikukood::TEXT                                            AS maksja_isikukood,
       inf3.maksja_nimi::TEXT,
       r.nimetus::TEXT                                                        AS asutus,
       'INF3 deklaratsioon'::TEXT                                             AS number,
       make_date(inf3.aasta, 01, 01) ::DATE                                   AS kpv,
       inf3.summa:: NUMERIC(14, 2)                                            AS summa,
       'INF3 ' || CASE WHEN inf3.liik = 1 THEN 'LASTEAED' ELSE 'HUVIKOOL' END AS markused
FROM inf3
         INNER JOIN ou.rekv r
                    ON r.id = inf3.rekvid

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT) TO arvestaja;


SELECT *
FROM lapsed.inf3_analuus(119, '2023')


/*

select * from (
SELECT *
FROM lapsed.inf3(119, '2023')
) qry
where lapse_isikukood ilike '%51909200101%'

select get_asutuse_struktuur(119)

*/