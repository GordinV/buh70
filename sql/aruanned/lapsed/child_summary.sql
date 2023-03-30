DROP FUNCTION IF EXISTS lapsed.child_summary(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.child_summary(INTEGER, INTEGER, TEXT, TEXT);
DROP FUNCTION IF EXISTS lapsed.child_summary(INTEGER, INTEGER, TEXT, TEXT, DATE, DATE);

CREATE OR REPLACE FUNCTION lapsed.child_summary(l_rekvid INTEGER, l_kond INTEGER DEFAULT 0, l_ik TEXT DEFAULT '%',
                                                l_nimi TEXT DEFAULT '%',
                                                l_kpv1 DATE DEFAULT make_date(year(now()::DATE), 01, 01),
                                                l_kpv2 DATE DEFAULT NOW()::DATE)
    RETURNS TABLE
    (
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
        rekvid           INTEGER,
        maksekpv         DATE,
        maksesumma       NUMERIC(12, 2)

    )
AS
$BODY$
WITH qryRekv AS (
    SELECT rekv_id
    FROM get_asutuse_struktuur(l_rekvid)
),
     qryParams AS (
         SELECT coalesce(l_kpv1, make_date(year(now()::DATE) - 1, 01, 01)) AS kpv_1,
                coalesce(l_kpv2, make_date(year(now()::DATE), 12, 31))     AS kpv_2
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
                d.rekvid                                    AS rekvid,
                d.id
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
                                  ON t.doc_arv_id = d.id,
              qryParams
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
                mk1.summa                           AS summa,
                mk_tyyp * mk1.summa::NUMERIC(12, 2) AS tasutud,
                0                                   AS mahakandmine,
                -1 * mk_tyyp * mk.jaak,
                d.rekvid                            AS rekvid,
                arv_ids
         FROM docs.doc D
                  INNER JOIN (SELECT mk.id,
                                     mk.parentid,
                                     mk.viitenr,
                                     mk.jaak,
                                     mk.maksepaev,
                                     CASE WHEN mk.opt = 1 THEN -1 ELSE 1 END AS mk_tyyp,
                                     (SELECT array_agg(doc_arv_id)
                                      FROM docs.arvtasu at
                                      WHERE doc_tasu_id = mk.parentid
                                        AND at.status < 3)                   AS arv_ids
                              FROM docs.mk mk
                              WHERE rekvid IN (SELECT rekv_id
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
         ) mk1 ON mk1.parentid = mk.id,
              qryParams
              --                ,
              --             lapsed.get_group_part_from_mk(D.id, current_date) AS ymk
         WHERE D.status <> 3
           AND D.rekvid IN (SELECT rekv_id
                            FROM qryRekv)
           AND l.parentid IN (SELECT id FROM qryLapsed)
           AND mk.maksepaev >= qryParams.kpv_1
           AND mk.maksepaev <= qryParams.kpv_2
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
       qryDoc.rekvid:: INTEGER,
       qryDoc.maksekpv::DATE,
       qryDoc.maksesumma::NUMERIC(12, 2)

FROM (
         SELECT qryArved.asutusid,
                qryArved.laps_id,
                qryArved.number,
                qryArved.kpv,
                qryArved.summa,
                qryArved.tasutud,
                qryArved.mahakandmine,
                qryArved.jaak,
                qryArved.rekvid,
                t.kpv::DATE AS maksekpv,
                t.summa     AS maksesumma
         FROM qryArved
                  LEFT OUTER JOIN qrytasud t ON ARRAY [qryArved.id] <@ t.arv_ids,
              qryParams
         WHERE qryArved.kpv >= qryParams.kpv_1
           AND qryArved.kpv <= qryParams.kpv_2
         UNION ALL
         SELECT asutusid,
                laps_id               AS laps_id,
                'Alg.saldo'::TEXT     AS number,
                qryParams.kpv_1::DATE AS kpv,
                summa                 AS summa,
                0::NUMERIC(12, 2)     AS tasutud,
                0                     AS mahakandmine,
                0                     AS jaak,
                rekvid,
                NULL::DATE            AS maksekpv,
                0                     AS maksesumma
         FROM (
                  WITH qryAlg AS (
                      SELECT sum(-1 * tasutud) AS summa, laps_id, rekvid, asutusid
                      FROM qrytasud t,
                           qryParams
                      WHERE kpv < qryParams.kpv_1
                      GROUP BY laps_id, rekvid, asutusid
                      UNION ALL
                      SELECT sum(summa) AS summa, laps_id, rekvid, t.asutusid
                      FROM qryArved t,
                           qryParams
                      WHERE kpv < qryParams.kpv_1
                      GROUP BY laps_id, rekvid, asutusid
                  )
                  SELECT sum(summa) AS summa, laps_id, rekvid, asutusid
                  FROM qryAlg
                  GROUP BY laps_id, rekvid, asutusid
              ) alg,
              qryParams
         UNION ALL
         SELECT qrytasud.asutusid,
                qrytasud.laps_id      AS laps_id,
                qrytasud.number::TEXT AS number,
                qrytasud.kpv::DATE            AS kpv,
                NULL::NUMERIC         AS summa,
                NULL::NUMERIC(12, 2)  AS tasutud,
                0                     AS mahakandmine,
                0                     AS jaak,
                qrytasud.rekvid,
                qrytasud.kpv ::DATE   AS maksekpv,
                qrytasud.summa        AS maksesumma
         FROM qrytasud,
              qryParams
         WHERE (qrytasud.arv_ids IS NULL OR
                NOT exists(SELECT (id)
                           FROM qryArved
                           WHERE ARRAY [id] @> qrytasud.arv_ids
                             AND qryArved.kpv >= qryParams.kpv_1
                             AND qryArved.kpv <= qryParams.kpv_2
                    )
             )
           AND qrytasud.kpv >= qryParams.kpv_1
           AND qrytasud.kpv <= qryParams.kpv_2
     ) qryDoc,
     libs.asutus a,
     qryLapsed l
WHERE qryDoc.asutusid = a.id
  AND l.id = qryDoc.laps_id


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.child_summary(INTEGER, INTEGER, TEXT, TEXT, DATE, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.child_summary(INTEGER, INTEGER, TEXT, TEXT, DATE, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.child_summary(INTEGER, INTEGER, TEXT, TEXT, DATE, DATE) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.child_summary(INTEGER, INTEGER, TEXT, TEXT, DATE, DATE) TO dbvaatleja;

/*

SELECT *
FROM lapsed.child_summary(97, 1, '36006133727%','%', '2023-01-01'::date,'2023-03-31'::date)


select * from ou.rekv where id = 85
*/