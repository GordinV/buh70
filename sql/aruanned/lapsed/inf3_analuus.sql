DROP FUNCTION IF EXISTS lapsed.inf3_analuus(INTEGER, TEXT);
DROP FUNCTION IF EXISTS lapsed.inf3_analuus(INTEGER, TEXT, DATE, DATE);
DROP FUNCTION IF EXISTS lapsed.inf3_analuus(INTEGER, TEXT, DATE, DATE, TEXT, TEXT);

CREATE OR REPLACE FUNCTION lapsed.inf3_analuus(l_rekvid INTEGER, l_aasta TEXT DEFAULT year(current_date)::TEXT,
                                               kpv_start DATE DEFAULT make_date(date_part('year', current_date)::INTEGER, 1, 1),
                                               kpv_end DATE DEFAULT current_date, lapse_isikukood TEXT DEFAULT NULL,
                                               maksja_isikukood TEXT DEFAULT NULL)
    RETURNS TABLE (
        doc_id           INTEGER,
        lapse_isikukood  TEXT,
        lapse_nimi       TEXT,
        maksja_isikukood TEXT,
        maksja_nimi      TEXT,
        asutus           TEXT,
        number           TEXT,
        kpv              DATE,
        summa            NUMERIC(14, 2),
        inf3_summa       NUMERIC(14, 2),
        markused         TEXT,
        kas_inf3_liik    BOOLEAN -- входит в INF3 или нет (NULL, true, false)
    )
AS
$BODY$
WITH params AS (
    SELECT CASE
               WHEN l_aasta IS NULL OR l_aasta::TEXT = '' THEN year(current_date)::TEXT
               ELSE l_aasta END::INTEGER                                               AS aasta,
           l_rekvid                                                                    AS rekv_id,
           kpv_start::DATE                                                             AS kpv1,
           kpv_end::DATE                                                               AS kpv2,
           CASE WHEN empty(lapse_isikukood) THEN NULL ELSE lapse_isikukood END::TEXT   AS lapse_ik,
           CASE WHEN empty(maksja_isikukood) THEN NULL ELSE maksja_isikukood END::TEXT AS maksja_ik
),
     rekv_ids AS (
         SELECT a.rekv_id
         FROM params p,
              get_asutuse_struktuur(p.rekv_id) a
     ),
     inf3 AS (SELECT *, params.kpv2 AS kpv_end
              FROM params,
                   lapsed.inf3(params.rekv_id, params.aasta::TEXT)
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
                coalesce((n.properties ->> 'kas_inf3')::BOOLEAN, FALSE) AS kas_inf,
                TRUE                                                    AS inf3
         FROM docs.doc D
                  INNER JOIN docs.arv a ON D.id = a.parentid
                  INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                  INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                  INNER JOIN lapsed.laps laps ON laps.id = l.parentid,
              params
         WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND D.status < 3
           AND D.doc_type_id IN (SELECT id FROM docs_types)
           AND a.kpv >= params.kpv1
           AND a.kpv <= params.kpv2
           AND D.id IN (SELECT id::INTEGER FROM arv_ids WHERE id <> '')
           AND (params.lapse_ik IS NULL OR laps.isikukood LIKE '%' || params.lapse_ik || '%')
         UNION ALL
         SELECT D.id,
                D.rekvid,
                a.kpv,
                a.number,
                a1.summa,
                a.asutusid                                              AS maksja_id,
                l.parentid                                              AS laps_id,
                coalesce((n.properties ->> 'kas_inf3')::BOOLEAN, FALSE) AS kas_inf,
                FALSE                                                   AS inf3
         FROM docs.doc D
                  INNER JOIN docs.arv a ON D.id = a.parentid
                  INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                  INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                  INNER JOIN lapsed.laps laps ON laps.id = l.parentid,
              params
         WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND D.status < 3
           AND D.doc_type_id IN (SELECT id FROM docs_types)
           AND a.kpv >= params.kpv1
           AND a.kpv <= params.kpv2
           AND D.id NOT IN (SELECT id::INTEGER FROM arv_ids WHERE id <> '')
           AND (params.lapse_ik IS NULL OR laps.isikukood LIKE '%' || params.lapse_ik || '%')
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
                mk1.summa,
                0            AS inf3_summa,
                mk1.asutusid AS maksja_id,
                l.parentid   AS laps_id,
                TRUE         AS inf3
         FROM docs.doc d
                  INNER JOIN docs.mk mk ON mk.parentid = d.id
                  INNER JOIN docs.mk1 mk1 ON mk.id = mk1.parentid
--                  INNER JOIN docs.arvtasu at ON at.doc_tasu_id = mk.parentid
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                  INNER JOIN lapsed.laps laps ON laps.id = l.parentid,
              params
         WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND D.status < 3
           AND D.doc_type_id IN (SELECT id FROM docs_types)
           AND D.id IN (SELECT id::INTEGER FROM tasu_ids WHERE id <> '')
           AND mk.maksepaev >= params.kpv1
           AND mk.maksepaev <= params.kpv2
           AND mk.opt = 2
           AND mk1.summa > 0
           AND (params.lapse_ik IS NULL OR laps.isikukood LIKE '%' || params.lapse_ik || '%')
           AND (params.maksja_ik IS NULL OR
                mk1.asutusid IN (SELECT id FROM libs.asutus WHERE regkood ILIKE '%' || params.maksja_ik || '%'))

         UNION ALL
         SELECT d.id,
                d.rekvid,
                mk.number,
                mk.maksepaev AS kpv,
                mk1.summa,
                0            AS inf3_summa,
                mk1.asutusid AS maksja_id,
                l.parentid   AS laps_id,
                FALSE        AS inf3
         FROM docs.doc d
                  INNER JOIN docs.mk mk ON mk.parentid = d.id
                  INNER JOIN docs.mk1 mk1 ON mk.id = mk1.parentid
--                  INNER JOIN docs.arvtasu at ON at.doc_tasu_id = mk.parentid
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                  INNER JOIN lapsed.laps laps ON laps.id = l.parentid,
              params
         WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND D.status < 3
           AND D.doc_type_id IN (SELECT id FROM docs_types)
           AND D.id NOT IN (SELECT id::INTEGER FROM tasu_ids WHERE id <> '')
           AND mk.maksepaev >= params.kpv1
           AND mk.maksepaev <= params.kpv2
           AND mk.opt = 2
           AND mk1.summa > 0
           AND (params.lapse_ik IS NULL OR laps.isikukood LIKE '%' || params.lapse_ik || '%')
           AND (params.maksja_ik IS NULL OR
                mk1.asutusid IN (SELECT id FROM libs.asutus WHERE regkood ILIKE '%' || params.maksja_ik || '%'))
     ),
     tagastused AS (
         WITH docs_types AS (
             SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood IN ('VMK', 'MK', 'SMK')
         ),
              tasu_ids AS (SELECT unnest(string_to_array(inf3.doc_tagastused_ids, ','))::TEXT AS id
                           FROM inf3)

         SELECT d.id,
                d.rekvid,
                mk.number,
                mk.maksepaev   AS kpv,
                -1 * mk1.summa AS summa,
                mk1.asutusid   AS maksja_id,
                l.parentid     AS laps_id,
                TRUE           AS inf3,
                FALSE          AS kas_tagastused
         FROM docs.doc d
                  INNER JOIN docs.mk mk ON mk.parentid = d.id
                  INNER JOIN docs.mk1 mk1 ON mk.id = mk1.parentid
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                  INNER JOIN lapsed.laps laps ON laps.id = l.parentid,
              params
         WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND D.status < 3
           AND D.doc_type_id IN (SELECT id FROM docs_types)
           AND D.id IN (SELECT id::INTEGER FROM tasu_ids WHERE id <> '')
           AND mk.maksepaev >= params.kpv1
           AND mk.maksepaev <= params.kpv2
           AND mk.opt = 2
           AND mk1.summa < 0
           AND (params.lapse_ik IS NULL OR laps.isikukood LIKE '%' || params.lapse_ik || '%')
           AND (params.maksja_ik IS NULL OR
                mk1.asutusid IN (SELECT id FROM libs.asutus WHERE regkood ILIKE '%' || params.maksja_ik || '%'))

         UNION ALL
         SELECT d.id,
                d.rekvid,
                mk.number,
                mk.maksepaev   AS kpv,
                -1 * mk1.summa AS summa,
                mk1.asutusid   AS maksja_id,
                l.parentid     AS laps_id,
                FALSE          AS inf3,
                FALSE          AS kas_tagastused

         FROM docs.doc d
                  INNER JOIN docs.mk mk ON mk.parentid = d.id
                  INNER JOIN docs.mk1 mk1 ON mk.id = mk1.parentid
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                  INNER JOIN lapsed.laps laps ON laps.id = l.parentid,
              params
         WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND D.status < 3
           AND D.doc_type_id IN (SELECT id FROM docs_types)
           AND D.id NOT IN (SELECT id::INTEGER FROM tasu_ids WHERE id <> '')
           AND mk.maksepaev >= params.kpv1
           AND mk.maksepaev <= params.kpv2
           AND mk.opt = 2
           AND mk1.summa < 0
           AND (params.lapse_ik IS NULL OR laps.isikukood LIKE '%' || params.lapse_ik || '%')
           AND (params.maksja_ik IS NULL OR
                mk1.asutusid IN (SELECT id FROM libs.asutus WHERE regkood ILIKE '%' || params.maksja_ik || '%'))

         UNION ALL
         SELECT d.id,
                d.rekvid,
                mk.number,
                mk.maksepaev AS kpv,
                mk1.summa,
                mk1.asutusid AS maksja_id,
                l.parentid   AS laps_id,
                TRUE         AS inf3,
                TRUE         AS kas_tagastused

         FROM docs.doc d
                  INNER JOIN docs.mk mk ON mk.parentid = d.id
                  INNER JOIN docs.mk1 mk1 ON mk.id = mk1.parentid
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                  INNER JOIN lapsed.laps laps ON laps.id = l.parentid,
              params
         WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND D.status < 3
           AND D.doc_type_id IN (SELECT id FROM docs_types)
           AND D.id IN (SELECT id::INTEGER FROM tasu_ids WHERE id <> '')
           AND mk.maksepaev >= params.kpv1
           AND mk.maksepaev <= params.kpv2
           AND mk.opt = 1
           AND (params.lapse_ik IS NULL OR laps.isikukood LIKE '%' || params.lapse_ik || '%')
           AND (params.maksja_ik IS NULL OR
                mk1.asutusid IN (SELECT id FROM libs.asutus WHERE regkood ILIKE '%' || params.maksja_ik || '%'))

         UNION ALL
         SELECT d.id,
                d.rekvid,
                mk.number,
                mk.maksepaev AS kpv,
                mk1.summa,
                mk1.asutusid AS maksja_id,
                l.parentid   AS laps_id,
                FALSE        AS inf3,
                TRUE         AS kas_tagastused

         FROM docs.doc d
                  INNER JOIN docs.mk mk ON mk.parentid = d.id
                  INNER JOIN docs.mk1 mk1 ON mk.id = mk1.parentid
                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                  INNER JOIN lapsed.laps laps ON laps.id = l.parentid,
              params
         WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND D.status < 3
           AND D.doc_type_id IN (SELECT id FROM docs_types)
           AND D.id NOT IN (SELECT id::INTEGER FROM tasu_ids WHERE id <> '')
           AND mk.maksepaev >= params.kpv1
           AND mk.maksepaev <= params.kpv2
           AND mk.opt = 1
           AND (params.lapse_ik IS NULL OR laps.isikukood LIKE '%' || params.lapse_ik || '%')
           AND (params.maksja_ik IS NULL OR
                mk1.asutusid IN (SELECT id FROM libs.asutus WHERE regkood ILIKE '%' || params.maksja_ik || '%'))
     )

SELECT doc_id::INTEGER,
       l.isikukood::TEXT AS lapse_isikukood,
       l.nimi::TEXT      AS lapse_nimi,
       i.regkood::TEXT   AS maksja_isikukood,
       i.nimetus::TEXT   AS maksja_nimi,
       r.nimetus::TEXT   AS asutus,
       docs.number::TEXT,
       docs.kpv::DATE,
       docs.summa::NUMERIC(14, 2),
       docs.inf3_summa::NUMERIC(14, 2),
       docs.markused::TEXT,
       kas_inf3_liik
FROM (
         SELECT a.id                                                                 AS doc_id,
                a.laps_id,
                a.maksja_id,
                a.rekvid,
                a.number::TEXT,
                a.kpv::DATE,
                a.summa:: NUMERIC(14, 2),
                (CASE WHEN a.kas_inf THEN 1 ELSE 0 END * a.summa):: NUMERIC(14, 2)   AS inf3_summa,
                'Usluga INF3 ' || CASE WHEN a.kas_inf THEN 'YES' ELSE 'NO' END::TEXT AS markused,
                a.inf3                                                               AS kas_inf3_liik
         FROM arved a
         UNION ALL
         SELECT t.id                       AS doc_id,
                t.laps_id,
                t.maksja_id,
                t.rekvid,
                t.number::TEXT,
                t.kpv::DATE,
                summa                      AS summa,
                coalesce(at.inf3_summa, 0) AS inf3_summa,
                'Oplata'                   AS markused,
                t.inf3                     AS kas_inf3_liik
         FROM tasud t
                  LEFT OUTER JOIN (
             SELECT t.id, sum(lapsed.get_inf3_summa(at.doc_arv_id, at.doc_tasu_id)) AS inf3_summa
             FROM tasud t
                      INNER JOIN docs.arvtasu at ON at.doc_tasu_id = t.id
             GROUP BY t.id
         ) at ON at.id = t.id
         UNION ALL
         SELECT t.id                                                               AS doc_id,
                t.laps_id,
                t.maksja_id,
                t.rekvid,
                t.number::TEXT,
                t.kpv::DATE,
                -1 * t.summa:: NUMERIC(14, 2),
                CASE WHEN t.inf3 THEN -1 ELSE 0 END * t.summa                      AS inf3_summa,
                CASE WHEN t.kas_tagastused THEN 'Vozvrat'::TEXT ELSE 'Perenos' END AS markused,
                t.inf3                                                             AS kas_inf3_liik
         FROM tagastused t) docs
         INNER JOIN lapsed.laps l
                    ON l.id = docs.laps_id
         INNER JOIN libs.asutus i ON i.id = docs.maksja_id
         INNER JOIN ou.rekv r
                    ON r.id = docs.rekvid

UNION ALL
SELECT 0                                                                      AS doc_id,
       inf3.lapse_isikukood::TEXT                                             AS lapse_isikukood,
       inf3.lapse_nimi::TEXT,
       inf3.maksja_isikukood::TEXT                                            AS maksja_isikukood,
       inf3.maksja_nimi::TEXT,
       r.nimetus::TEXT                                                        AS asutus,
       'INF3 deklaratsioon'::TEXT                                             AS number,
       inf3.kpv_end ::DATE                                                    AS kpv,
       inf3.summa:: NUMERIC(14, 2)                                            AS summa,
       inf3.summa:: NUMERIC(14, 2)                                            AS inf3_summa,
       'INF3 ' || CASE WHEN inf3.liik = 1 THEN 'LASTEAED' ELSE 'HUVIKOOL' END AS markused,
       NULL::BOOLEAN                                                          AS kas_inf3_liik
FROM inf3
         INNER JOIN ou.rekv r
                    ON r.id = inf3.rekvid

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT, DATE, DATE, TEXT, TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT, DATE, DATE, TEXT, TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT, DATE, DATE, TEXT, TEXT) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT, DATE, DATE, TEXT, TEXT) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT, DATE, DATE, TEXT, TEXT) TO arvestaja;


/*

select * from (
SELECT *
FROM lapsed.inf3_analuus(119, '2023', '2022-12-31', '2023-12-31', '50805140044','48508050110')
--order by lapse_isikukood, maksja_isikukood
) qry
where lapse_isikukood ilike '%50805140044%'
and number = '2327'
*/

-- Aleksandr Kazimov IK 30.07.2003