DROP FUNCTION IF EXISTS lapsed.inf3_analuus(INTEGER, TEXT);
DROP FUNCTION IF EXISTS lapsed.inf3_analuus(INTEGER, TEXT, DATE, DATE);
DROP FUNCTION IF EXISTS lapsed.inf3_analuus(INTEGER, TEXT, DATE, DATE, TEXT, TEXT);

CREATE OR REPLACE FUNCTION lapsed.inf3_analuus(l_rekvid INTEGER, l_aasta TEXT DEFAULT year(current_date)::TEXT,
                                               kpv_start DATE DEFAULT make_date(date_part('year', current_date)::INTEGER, 1, 1),
                                               kpv_end DATE DEFAULT current_date, lapse_isikukood TEXT DEFAULT NULL,
                                               maksja_isikukood TEXT DEFAULT NULL)
    RETURNS TABLE
            (
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
WITH
    params AS (
                  SELECT
                      CASE
                          WHEN l_aasta IS NULL OR l_aasta::TEXT = '' THEN year(current_date)::TEXT
                          ELSE l_aasta END::INTEGER                     AS aasta,
                      l_rekvid                                          AS rekv_id,
                      kpv_start::DATE                                   AS kpv1,
                      kpv_end::DATE                                     AS kpv2,
                      CASE
                          WHEN empty(coalesce(lapse_isikukood, '')) THEN NULL
                          ELSE ltrim(rtrim(lapse_isikukood)) END::TEXT  AS lapse_ik,
                      CASE
                          WHEN empty(coalesce(maksja_isikukood, '')) THEN NULL
                          ELSE ltrim(rtrim(maksja_isikukood)) END::TEXT AS maksja_ik
              ),
    rekv_ids AS (
                  SELECT
                      a.rekv_id
                  FROM
                      params                           p,
                      get_asutuse_struktuur(p.rekv_id) a
              ),
    inf3 AS (
                  SELECT *,
                         params.kpv2 AS kpv_end
                  FROM
                      params,
                      lapsed.inf3(params.rekv_id, params.aasta::TEXT) inf3
                  WHERE
                      (params.lapse_ik IS NULL
                          OR inf3.lapse_isikukood LIKE '%' || params.lapse_ik || '%'
                          )
              ),
    docs_types AS (
                  SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood IN ('SMK', 'MK', 'VMK')
              ),
    lapsed AS (
                  SELECT
                      l.id
                  FROM
                      lapsed.laps l,
                                  params
                  WHERE
                        staatus < 3
--           AND (isikukood IN (SELECT lapse_isikukood FROM inf3)
                    AND (params.lapse_ik IS NULL OR isikukood LIKE '%' || params.lapse_ik || '%')
              ),

    alg_saldo AS (
                  SELECT
                      rekv_id           as rekvid,
                      sum(db - kr)      AS summa,
                      0                 as inf3_summa,
                      isik_id           as laps_id,
                      array_agg(doc_id) as docs_ids
                  FROM
                      (
                          -- laekumised
                          SELECT
                              0          AS db,
                              mk1.summa  AS kr,
                              mk.rekvid  AS rekv_id,
                              l.parentid AS isik_id,
                              d.id       as doc_id
                          FROM
                              docs.doc                           d
                                  INNER JOIN docs.mk             mk ON d.id = mk.parentid
                                  INNER JOIN docs.mk1            mk1 ON mk1.parentid = mk.id
                                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id,
                              params                             p
                          WHERE
                                d.rekvid IN (
                                                SELECT
                                                    rekv_id
                                                FROM
                                                    rekv_ids
                                            )
                            AND d.status < 3
                            AND d.doc_type_id IN (
                                                     SELECT
                                                         id
                                                     FROM
                                                         docs_types
                                                 )
                            AND mk.maksepaev < p.kpv1
                            AND mk.opt = 2
                            AND l.parentid in (
                                                  select
                                                      id
                                                  from
                                                      lapsed
                                              )
                          UNION ALL
                          -- tagastused
                          SELECT
                              0              AS db,
                              -1 * mk1.summa AS kr,
                              mk.rekvid      AS rekv_id,
                              l.parentid     AS isik_id,
                              d.id           as doc_id

                          FROM
                              docs.doc                           d
                                  INNER JOIN docs.mk             mk ON d.id = mk.parentid
                                  INNER JOIN docs.mk1            mk1 ON mk1.parentid = mk.id
                                  INNER JOIN lapsed.liidestamine l ON l.docid = d.id,
                              params                             p
                          WHERE
                                d.rekvid IN (
                                                SELECT
                                                    rekv_id
                                                FROM
                                                    rekv_ids
                                            )
                            AND d.status < 3
                            AND d.doc_type_id IN (
                                                     SELECT
                                                         id
                                                     FROM
                                                         docs_types
                                                 )
                            AND mk.maksepaev < p.kpv1
                            AND mk.opt = 1
                            AND l.parentid in (
                                                  select
                                                      id
                                                  from
                                                      lapsed
                                              )
                          UNION ALL
                          SELECT
                              a.summa     AS db,
                              0           AS kr,
                              d.rekvid    AS rekv_id,
                              ld.parentid AS isik_id,
                              d.id        as doc_id

                          FROM
                              docs.doc                           d
                                  INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                                  INNER JOIN docs.arv            a ON a.parentid = d.id AND a.liik = 0, -- только счета исходящие
                              params                             p
                          WHERE
                                coalesce((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
                            AND d.rekvid IN (
                                                SELECT
                                                    rekv_id
                                                FROM
                                                    rekv_ids
                                            )
--                        AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                            AND a.liik = 0 -- только счета исходящие
                            AND a.kpv < p.kpv1
                            AND d.status < 3
                            AND ld.parentid in (
                                                   select
                                                       id
                                                   from
                                                       lapsed
                                               )

-- mahakandmine
                          UNION ALL
                          SELECT
                              -1 * a.summa AS db,
                              0            AS kr,
                              a.rekvid     AS rekv_id,
                              l.parentid   AS isik_id,
                              arv.parentid as doc_id

                          FROM
                              docs.arvtasu                       a
                                  INNER JOIN lapsed.liidestamine l ON l.docid = a.doc_arv_id
                                  INNER JOIN docs.arv            arv ON a.doc_arv_id = arv.parentid,
                              params                             p
                          WHERE
                              a.pankkassa = 3 -- только проводки
                            AND a.rekvid IN (
                                                SELECT
                                                    rekv_id
                                                FROM
                                                    rekv_ids
                                            )
                            AND a.kpv < p.kpv1
                            AND arv.liik = 0
                            AND a.status <> 3
                            AND (arv.properties ->> 'tyyp' IS NULL OR
                                 arv.properties ->> 'tyyp' <> 'ETTEMAKS') -- уберем предоплаты
                            AND l.parentid in (
                                                  select
                                                      id
                                                  from
                                                      lapsed
                                              )
                      ) alg_saldo
                  GROUP BY rekv_id, isik_id
              ),
    inf3_jaak as (
                  select
                      inf3.doc_id,
                      inf3.number,
                      inf3.kpv,
                      inf3.rekvid,
                      lapsed.get_arv_jaak(inf3.doc_id,p.kpv1 ) as summa,
                      inf3.inf3_jaak as inf3_summa,
                      inf3.laps_id
                  from
                      params p,
                      (
                          select
                              a.parentid                                 as doc_id,
                              a.number                                   as number,
                              a.kpv,
                              a.summa,
                              (lapsed.get_inf3_jaak(a.parentid, p.kpv1)) as inf3_jaak,
                              a.rekvid,
                              l.parentid                                 as laps_id
                          from
                              docs.arv                           a
                                  inner join lapsed.liidestamine l on l.docid = a.parentid,
                              params                             p,
                              alg_saldo                          s
                          where
                                s.summa > 0
                            and a.rekvid = s.rekvid
                            and a.parentid in (
                                                  select unnest(s.docs_ids)
                                              )
                            and a.kpv < p.kpv1
--                          group by a.rekvid, l.parentid, a.rekvid
                      ) inf3
--                  where                      inf3_jaak <> 0
              ),

    tasu_ids AS (
                  SELECT
                      unnest(string_to_array(inf3.docs_tasu_ids, ','))::TEXT AS id
                  FROM
                      inf3
              ),
    maksjad AS (
                  SELECT
                      a.id
                  FROM
                      libs.asutus                   a
                          INNER JOIN lapsed.vanemad v ON v.asutusid = a.id,
                                                    params
                  WHERE
                        v.parentid IN (
                                          SELECT
                                              id
                                          FROM
                                              lapsed
                                      )
                    AND (params.maksja_ik IS NULL OR a.regkood LIKE '%' || params.maksja_ik || '%')
              ),

    arved AS (
                  WITH
                      docs_types AS (
                                        SELECT
                                            id,
                                            kood
                                        FROM
                                            libs.library
                                        WHERE
                                              library.library = 'DOK'
                                          AND kood IN ('ARV')
                                    ),
                      arv_ids AS (
                                        SELECT
                                            unnest(string_to_array(inf3.docs_arv_ids, ','))::TEXT AS id
                                        FROM
                                            inf3
                                    ),

                      docs AS (
                                        SELECT
                                            D.id,
                                            D.rekvid,
                                            a.kpv,
                                            a.number,
                                            a1.summa,
                                            a.asutusid                                              AS maksja_id,
                                            l.parentid                                              AS laps_id,
                                            coalesce((n.properties ->> 'kas_inf3')::BOOLEAN, FALSE) AS kas_inf,
                                            TRUE                                                    AS inf3
                                        FROM
                                            docs.doc                           D
                                                INNER JOIN docs.arv            a ON D.id = a.parentid
                                                INNER JOIN docs.arv1           a1 ON a1.parentid = a.id
                                                INNER JOIN libs.nomenklatuur   n ON n.id = a1.nomid
                                                INNER JOIN lapsed.liidestamine l ON l.docid = d.id,
--              lapsed.laps laps
                                                                               params
                                        WHERE
                                              D.rekvid IN (
                                                              SELECT
                                                                  rekv_id
                                                              FROM
                                                                  rekv_ids
                                                          )
                                          AND D.status < 3
                                          AND D.doc_type_id IN (
                                                                   SELECT
                                                                       id
                                                                   FROM
                                                                       docs_types
                                                               )
                                          AND a.kpv >= params.kpv1
                                          AND a.kpv <= params.kpv2
--                    AND D.id IN (SELECT id::INTEGER FROM arv_ids WHERE id <> '')
                                          AND l.parentid IN (
                                                                SELECT
                                                                    id
                                                                FROM
                                                                    lapsed
                                                            )
                                    )
                  SELECT
                      D.id,
                      D.rekvid,
                      d.kpv,
                      d.number,
                      d.summa,
                      d.maksja_id,
                      d.laps_id,
                      d.kas_inf,
                      FALSE AS inf3
                  FROM
                      docs d
                  WHERE
                      D.id NOT IN (
                                      SELECT
                                          id::INTEGER
                                      FROM
                                          arv_ids
                                      WHERE
                                          id <> ''
                                  )
                  UNION ALL
                  SELECT
                      D.id,
                      D.rekvid,
                      d.kpv,
                      d.number,
                      d.summa,
                      d.maksja_id,
                      d.laps_id,
                      d.kas_inf,
                      TRUE AS inf3
                  FROM
                      docs d
                  WHERE
                      D.id IN (
                                  SELECT
                                      id::INTEGER
                                  FROM
                                      arv_ids
                                  WHERE
                                      id <> ''
                              )
              ),
    tasud AS (
                  SELECT
                      d.id,
                      d.rekvid,
                      mk.number,
                      mk.maksepaev       AS kpv,
                      mk1.summa,
                      0                  AS inf3_summa,
                      mk1.asutusid       AS maksja_id,
                      l.parentid         AS laps_id,
                      mk.opt,
                      TRUE               AS inf3,
                      CASE
                          WHEN mk.selg ILIKE 'Tagasimakse %' OR mk.selg ILIKE 'Ülekannemakse %' THEN TRUE
                          ELSE FALSE END AS kas_ullekanne
                  FROM
                      docs.doc                           d
                          INNER JOIN docs.mk             mk ON mk.parentid = d.id
                          INNER JOIN docs.mk1            mk1 ON mk.id = mk1.parentid
--                  INNER JOIN libs.asutus a ON a.id = mk1.asutusid
                          INNER JOIN lapsed.liidestamine l ON l.docid = d.id,
--                  INNER JOIN lapsed.laps laps ON laps.id = l.parentid,
                                                         params
                  WHERE
                        D.rekvid IN (
                                        SELECT
                                            rekv_id
                                        FROM
                                            rekv_ids
                                    )
                    AND D.status < 3
                    AND D.doc_type_id IN (
                                             SELECT
                                                 id
                                             FROM
                                                 docs_types
                                         )
                    AND mk.maksepaev >= params.kpv1
                    AND mk.maksepaev <= params.kpv2
                    AND l.parentid IN (
                                          SELECT
                                              id
                                          FROM
                                              lapsed
                                      )
                    AND mk1.asutusid IN (
                                            SELECT
                                                id
                                            FROM
                                                maksjad
                                        )
--           AND (params.maksja_ik IS NULL OR a.regkood LIKE '%' || params.maksja_ik || '%')
              )
SELECT
    doc_id::INTEGER,
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
FROM
    (
        SELECT
            a.id                                                                 AS doc_id,
            a.laps_id,
            a.maksja_id,
            a.rekvid,
            a.number::TEXT,
            a.kpv::DATE,
            a.summa:: NUMERIC(14, 2),
            (CASE WHEN a.kas_inf THEN 1 ELSE 0 END * a.summa):: NUMERIC(14, 2)   AS inf3_summa,
            'Teenus INF3 ' || CASE WHEN a.kas_inf THEN 'YES' ELSE 'NO' END::TEXT AS markused,
            a.inf3                                                               AS kas_inf3_liik
        FROM
            arved a
        UNION ALL
        SELECT
            t.id                                                      AS doc_id,
            t.laps_id,
            t.maksja_id,
            t.rekvid,
            t.number::TEXT,
            t.kpv::DATE,
            summa                                                     AS summa,
            coalesce(at.inf3_summa, 0)                                AS inf3_summa,
            CASE WHEN t.kas_ullekanne THEN 'Ülekanne' ELSE 'Tasu' END AS markused,
            TRUE                                                      AS kas_inf3_liik
        FROM
            tasud                 t
                LEFT OUTER JOIN (
                                    SELECT
                                        at.doc_tasu_id                                            AS id,
                                        sum(lapsed.get_inf3_summa(at.doc_arv_id, at.doc_tasu_id)) AS inf3_summa
                                    FROM
                                        docs.arvtasu at
                                    WHERE
                                        at.doc_tasu_id IN (
                                                              SELECT
                                                                  id::INTEGER
                                                              FROM
                                                                  tasu_ids
                                                              WHERE
                                                                  id <> ''
                                                          )
                                    GROUP BY at.doc_tasu_id
                                ) at ON at.id = t.id
        WHERE
              t.opt = 2
          AND t.id IN (
                          SELECT
                              id::INTEGER
                          FROM
                              tasu_ids
                          WHERE
                              id <> ''
                      )
        UNION ALL
        SELECT
            t.id                                                      AS doc_id,
            t.laps_id,
            t.maksja_id,
            t.rekvid,
            t.number::TEXT,
            t.kpv::DATE,
            summa                                                     AS summa,
            coalesce(at.inf3_summa, 0)                                AS inf3_summa,
            CASE WHEN t.kas_ullekanne THEN 'Ülekanne' ELSE 'Tasu' END AS markused,
            FALSE                                                     AS kas_inf3_liik
        FROM
            tasud                 t
                LEFT OUTER JOIN (
                                    SELECT
                                        at.doc_tasu_id                                            AS id,
                                        sum(lapsed.get_inf3_summa(at.doc_arv_id, at.doc_tasu_id)) AS inf3_summa
                                    FROM
                                        docs.arvtasu at
                                    WHERE
                                        at.doc_tasu_id IN (
                                                              SELECT
                                                                  id::INTEGER
                                                              FROM
                                                                  tasu_ids
                                                              WHERE
                                                                  id <> ''
                                                          )
                                    GROUP BY at.doc_tasu_id
                                ) at ON at.id = t.id
        WHERE
              t.opt = 2
          AND t.id NOT IN (
                              SELECT
                                  id::INTEGER
                              FROM
                                  tasu_ids
                              WHERE
                                  id <> ''
                          )
        UNION ALL
        SELECT
            t.id       AS doc_id,
            t.laps_id,
            t.maksja_id,
            t.rekvid,
            t.number::TEXT,
            t.kpv::DATE,
            -1 * summa AS summa,
            0          AS inf3_summa,
            'Tagastus' AS markused,
            FALSE      AS kas_inf3_liik
        FROM
            tasud t
        WHERE
            t.opt = 1
    )                          docs

        INNER JOIN lapsed.laps l
                   ON l.id = docs.laps_id
        INNER JOIN libs.asutus i ON i.id = docs.maksja_id
        INNER JOIN ou.rekv     r
                   ON r.id = docs.rekvid

UNION ALL
SELECT
    0                                                                      AS doc_id,
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
FROM
    inf3
        INNER JOIN ou.rekv r
                   ON r.id = inf3.rekvid
union all
select
    0                 as doc_id,
    l.isikukood       as lapse_isikukood,
    l.nimi            as lapse_nimi,
    null::text        as maksja_isikukood,
    null::text        as maksja_nimi,
    r.nimetus         as asutus,
    ''::text          as number,
    p.kpv1            as kpv,
    a_s.summa         as summa,
    0                 as inf3_summa,
    'AS (Tasu)'::text as markused,
    NULL::BOOLEAN     as kas_inf3_liik
from
    alg_saldo                  a_s
        inner join lapsed.laps l on l.id = a_s.laps_id
        INNER JOIN ou.rekv     r
                   ON r.id = a_s.rekvid,
    params                     p
where
    a_s.summa < 0
union all
select
    inf3.doc_id                                           as doc_id,
    l.isikukood                                           as lapse_isikukood,
    l.nimi                                                as lapse_nimi,
    null::text                                            as maksja_isikukood,
    null::text                                            as maksja_nimi,
    r.nimetus                                             as asutus,
    to_char(inf3.kpv, 'DD.MM.YYYY') || '_' || inf3.number as number,
    p.kpv1                                                as kpv,
    inf3.inf3_summa                                       as summa,
    inf3.inf3_summa                                       as inf3_summa,
    'AS (Teenus INF3 YES)'::text                          as markused,
    NULL::BOOLEAN                                         as kas_inf3_liik
from
    alg_saldo                       a_s
        left outer join inf3_jaak   inf3 on inf3.rekvid = a_s.rekvid and a_s.laps_id = inf3.laps_id
        inner join      lapsed.laps l on l.id = a_s.laps_id
        INNER JOIN      ou.rekv     r
                        ON r.id = a_s.rekvid,
    params                          p
where
    coalesce(inf3.inf3_summa, 0) > 0
union all
select
    inf3.doc_id                                           as doc_id,
    l.isikukood                                           as lapse_isikukood,
    l.nimi                                                as lapse_nimi,
    null::text                                            as maksja_isikukood,
    null::text                                            as maksja_nimi,
    r.nimetus                                             as asutus,
    to_char(inf3.kpv, 'DD.MM.YYYY') || '_' || inf3.number as number,
    p.kpv1                                                as kpv,
    inf3.summa - inf3.inf3_summa                          as summa,
    0                                                     as inf3_summa,
    'AS (Teenus INF3 NO)'::text                           as markused,
    NULL::BOOLEAN                                         as kas_inf3_liik
from
    alg_saldo                       a_s
        left outer join inf3_jaak   inf3 on inf3.rekvid = a_s.rekvid and a_s.laps_id = inf3.laps_id
        inner join      lapsed.laps l on l.id = a_s.laps_id
        INNER JOIN      ou.rekv     r
                        ON r.id = a_s.rekvid,
    params                          p
where
    (coalesce(inf3.summa, 0) - coalesce(inf3.inf3_summa, 0)) > 0


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT, DATE, DATE, TEXT, TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT, DATE, DATE, TEXT, TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT, DATE, DATE, TEXT, TEXT) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT, DATE, DATE, TEXT, TEXT) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.inf3_analuus(INTEGER, TEXT, DATE, DATE, TEXT, TEXT) TO arvestaja;

SELECT *
FROM
    lapsed.inf3_analuus(66, '2024', '2024-01-01', '2024-12-31', '62005080091', null)



/*

select * from (
SELECT *
FROM lapsed.inf3_analuus(72, '2024', '2024-01-01', '2024-12-31', '61401230145',null)
--order by lapse_isikukood, maksja_isikukood
) qry
where markused ilike '%vozvrat%'
and number = '2327'
*/

-- Aleksandr Kazimov IK 30.07.2003