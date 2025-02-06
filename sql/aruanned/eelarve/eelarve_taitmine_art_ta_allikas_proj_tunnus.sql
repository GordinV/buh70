DROP FUNCTION IF EXISTS eelarve.eelarve_taitmine_art_ta_allikas_proj_tunnus(INTEGER, DATE, DATE, INTEGER, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION eelarve.eelarve_taitmine_art_ta_allikas_proj_tunnus(l_aasta INTEGER,
                                                                               l_kpv_1 DATE,
                                                                               l_kpv_2 DATE,
                                                                               l_rekvid INTEGER,
                                                                               l_kond INTEGER,
                                                                               l_params JSONB DEFAULT NULL)
    RETURNS TABLE
            (
                rekv_id                  INTEGER,
                eelarve_kinni            NUMERIC(14, 2),
                eelarve_parandatud       NUMERIC(14, 2),
                eelarve_kassa_kinni      NUMERIC(14, 2),
                eelarve_kassa_parandatud NUMERIC(14, 2),
                tegelik                  NUMERIC(14, 2),
                kassa                    NUMERIC(14, 2),
                tegev                    VARCHAR(20),
                allikas                  VARCHAR(20),
                artikkel                 VARCHAR(20),
                rahavoog                 VARCHAR(20),
                tunnus                   VARCHAR(20),
                proj                     VARCHAR(20),
                uritus                   VARCHAR(20),
                objekt                   VARCHAR(20),
                idx                      INTEGER
            )
AS
$BODY$
WITH
    params AS (
                  SELECT
                      l_kpv_1                                             AS kpv1,
                      l_kpv_2                                             AS kpv2,
                      l_rekvid                                            AS rekv_id,
                      coalesce((l_params ->> 'tunnus')::TEXT, '') + '%'   AS tunnus,
                      coalesce((l_params ->> 'tegev')::TEXT, '') + '%'    AS tegev,
                      coalesce((l_params ->> 'artikkel')::TEXT, '') + '%' AS artikkel,
                      coalesce((l_params ->> 'allikas')::TEXT, '') + '%'  AS allikas,
                      coalesce((l_params ->> 'rahavoog')::TEXT, '') + '%' AS rahavoog,
                      coalesce((l_params ->> 'proj')::TEXT, '') + '%'     AS proj,
                      coalesce((l_params ->> 'uritus')::TEXT, '') + '%'   AS uritus,
                      coalesce((l_params ->> 'objekt')::TEXT, '') + '%'   AS objekt,
                      l_aasta                                             AS aasta
              ),
    rekv_ids AS (
                  SELECT
                      r.rekv_id
                  FROM
                      params,
                      get_asutuse_struktuur(params.rekv_id) r
                  WHERE
                      r.rekv_id = CASE
                                      WHEN l_kond = 1
                                          -- kond
                                          THEN r.rekv_id
                                      ELSE params.rekv_id END
              ),
    docs_types AS (
                  SELECT id, kood FROM libs.library WHERE library.library = 'DOK' AND kood IN ('JOURNAL')
              ),
    cur_kulude_kassa_taitmine AS (
                                     -- kontod
                  WITH
                      qryKontodKulud AS (
                                            SELECT
                                                l.kood,
                                                l.tun5 AS tyyp
                                            FROM
                                                libs.library                       l
                                                    INNER JOIN eelarve.kassa_kulud kassakulud
                                                               ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~
                                                                    ltrim(rtrim((kassakulud.kood) :: TEXT))))
                                            WHERE
                                                  l.library = 'KONTOD'
                                              AND L.status <> 3
                                        ),
                      qryKassaKontod AS (
                                            SELECT
                                                l.kood,
                                                l.tun5 AS tyyp
                                            FROM
                                                libs.library             l
                                                    INNER JOIN
                                                    eelarve.kassa_kontod kassakontod
                                                    ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~
                                                         ltrim(rtrim((kassakontod.kood) :: TEXT))))
                                            WHERE
                                                  l.library = 'KONTOD'
                                              AND L.status <> 3
                                        )
                  SELECT
                      qry.rekvid     AS rekv_id,
                      sum(qry.summa) AS summa,
                      qry.tegev,
                      qry.allikas,
                      qry.artikkel,
                      qry.rahavoog,
                      qry.tunnus,
                      qry.proj,
                      qry.uritus,
                      qry.objekt
                  FROM
                      (
                          -- расход
                          SELECT
                              d.id,
                              (summa)                       AS summa,
                              j1.kood1::TEXT                AS tegev,
                              j1.kood2::TEXT                AS allikas,
                              j1.kood3::TEXT                AS rahavoog,
                              j1.kood5::TEXT                AS artikkel,
                              coalesce(j1.tunnus, '')::TEXT AS tunnus,
                              coalesce(j1.proj, '')::TEXT   AS proj,
                              coalesce(j1.kood4, '')        AS uritus,
                              coalesce(j1.objekt, '')       AS objekt,
                              j.rekvid
                          FROM
                              docs.doc                           d
                                  INNER JOIN      docs.journal   j ON j.parentid = D.id
                                  INNER JOIN      docs.journal1  j1 ON j1.parentid = j.id
                                  INNER JOIN      qryKontodKulud k ON k.kood = j1.deebet
                                  INNER JOIN      qryKassaKontod kassa ON kassa.kood = j1.kreedit
                                                      -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
                                                                 params
                          WHERE
                                coalesce(a.kpv, j.kpv) >= params.kpv1
                            AND coalesce(a.kpv, j.kpv) <= params.kpv2
                            AND d.rekvid IN (
                                                SELECT rekv_id
                                                FROM rekv_ids
                                            )
                            AND d.doc_type_id IN (
                                                     SELECT id
                                                     FROM docs_types
                                                 )

                          UNION ALL
                          -- востановление расходов
                          SELECT
                              d.id,
                              (-1 * j1.summa)               AS summa,
                              j1.kood1::TEXT                AS tegev,
                              j1.kood2::TEXT                AS allikas,
                              j1.kood3::TEXT                AS rahavoog,
                              j1.kood5::TEXT                AS artikkel,
                              coalesce(j1.tunnus, '')::TEXT AS tunnus,
                              coalesce(j1.proj, '')::TEXT   AS proj,
                              coalesce(j1.kood4, '')        AS uritus,
                              coalesce(j1.objekt, '')       AS objekt,
                              j.rekvid
                          FROM
                              docs.doc                           d
                                  INNER JOIN      docs.journal   j ON j.parentid = d.id
                                  INNER JOIN      docs.journal1  j1 ON j1.parentid = j.id
                                  INNER JOIN      qryKontodKulud k ON k.kood = j1.kreedit
                                  INNER JOIN      qryKassaKontod kassa ON kassa.kood = j1.deebet
                                  INNER JOIN      libs.library   l
                                                  ON l.kood = j1.kood5 AND l.tun5 = 2 AND library = 'TULUDEALLIKAD' --kulud
                                  -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
                                                                 params

                          WHERE
                                coalesce(a.kpv, j.kpv) >= params.kpv1
                            AND coalesce(a.kpv, j.kpv) <= params.kpv2
                            AND d.rekvid IN (
                                                SELECT rekv_id
                                                FROM rekv_ids
                                            )
                            AND d.doc_type_id IN (
                                                     SELECT id
                                                     FROM docs_types
                                                 )
                      ) qry,
                        params
                  WHERE
                        NOT empty(qry.artikkel)
                    AND summa <> 0
                        -- lisa filtrid
                    AND coalesce(qry.tunnus, '') ILIKE params.tunnus
                    AND coalesce(qry.tegev, '') ILIKE params.tegev
                    AND coalesce(qry.artikkel, '') ILIKE params.artikkel
                    AND coalesce(qry.allikas, '') ILIKE params.allikas
                    AND coalesce(qry.rahavoog, '') ILIKE params.rahavoog
                    AND coalesce(qry.proj, '') ILIKE params.proj
                    AND coalesce(qry.uritus, '') ILIKE params.uritus
                    AND coalesce(qry.objekt, '') ILIKE params.objekt
                  GROUP BY
                      qry.rekvid, qry.tegev, qry.allikas, qry.artikkel, qry.tunnus, qry.rahavoog, qry.proj, qry.uritus,
                      qry.objekt
--         HAVING sum(qry.summa) <> 0
              ),

    cur_kulude_taitmine AS (
                  WITH
                      qryKontodKassaKulud AS (
                                                 SELECT
                                                     l.kood,
                                                     l.tun5
                                                 FROM
                                                     libs.library           l
                                                         INNER JOIN
                                                         eelarve.fakt_kulud fakt_kulud
                                                         ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~
                                                              ltrim(rtrim((fakt_kulud.kood) :: TEXT))))
                                                 WHERE
                                                       l.library = 'KONTOD'
                                                   AND L.status <> 3
                                             ),
                      qryArt AS (
                                                 SELECT
                                                     kood
                                                 FROM
                                                     libs.library l
                                                 WHERE
                                                       l.tun5 = 2 --kulud
                                                   AND l.library = 'TULUDEALLIKAD'
                                                   AND status < 3
                                             )
                  SELECT
                      qry.rekvid     AS rekv_id,
                      sum(qry.summa) AS summa,
                      qry.tegev,
                      qry.allikas,
                      qry.artikkel,
                      qry.rahavoog,
                      qry.tunnus,
                      qry.proj,
                      qry.uritus,
                      qry.objekt
                  FROM
                      (
                          -- расходы
                          SELECT
                              1                           AS kulud,
                              sum(CASE
                                      WHEN left(j1.kood5, 2) = '15' AND NOT empty(j1.kood3) AND j1.kood3 NOT IN ('01')
                                          THEN 0
                                      ELSE j1.summa END)  AS summa,
                              j1.kood1                    AS tegev,
                              j1.kood2                    AS allikas,
                              j1.kood3                    AS rahavoog,
                              j1.kood5                    AS artikkel,
                              j1.tunnus,
                              coalesce(j1.proj, '')::TEXT AS proj,
                              coalesce(j1.kood4, '')      AS uritus,
                              coalesce(j1.objekt, '')     AS objekt,
                              j.rekvid
                          FROM
                              docs.doc                                d
                                  INNER JOIN      docs.journal        j ON j.parentid = d.id
                                  INNER JOIN      docs.journal1       j1 ON j1.parentid = j.id
                                  INNER JOIN      qryKontodKassaKulud k ON k.kood = j1.deebet
                                                      -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                                  LEFT OUTER JOIN docs.alg_saldo      a ON a.journal_id = d.id,
                                                                      params

                          WHERE
                                coalesce(a.kpv, j.kpv) >= params.kpv1
                            AND coalesce(a.kpv, j.kpv) <= params.kpv2
                            AND d.rekvid IN (
                                                SELECT rekv_id
                                                FROM rekv_ids
                                            )
                            AND d.status < 3
                            AND d.doc_type_id IN (
                                                     SELECT id
                                                     FROM docs_types
                                                 )
                            AND j1.kood5 IN (
                                                SELECT kood
                                                FROM qryArt
                                            )
                            AND NOT empty(j1.kood5)
                          GROUP BY
                              j1.kood1, j1.kood2, j1.kood3, coalesce(j1.kood4, ''), j1.kood5, j1.tunnus,
                              coalesce(j1.proj, ''), coalesce(j1.objekt, ''), j.rekvid
                          UNION ALL
                          -- востановление расходов
                          SELECT
                              2                                 AS tulud,
                              sum(-1 * (CASE
                                            WHEN left(j1.kood5, 2) = '15' AND NOT empty(j1.kood3) AND
                                                 j1.kood3 NOT IN ('01')
                                                THEN 0
                                            ELSE j1.summa END)) AS summa,
                              j1.kood1                          AS tegev,
                              j1.kood2                          AS allikas,
                              j1.kood3                          AS rahavoog,
                              j1.kood5                          AS artikkel,
                              j1.tunnus,
                              coalesce(j1.proj, '')::TEXT       AS proj,
                              coalesce(j1.kood4, '')            AS uritus,
                              coalesce(j1.objekt, '')           AS objekt,
                              j.rekvid
                          FROM
                              docs.doc                                d
                                  INNER JOIN      docs.journal        j ON j.parentid = d.id
                                  INNER JOIN      docs.journal1       j1 ON j1.parentid = j.id
                                  INNER JOIN      qryKontodKassaKulud k ON k.kood = j1.kreedit
                                                      -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                                  LEFT OUTER JOIN docs.alg_saldo      a ON a.journal_id = d.id,
                                                                      params
                          WHERE
                                coalesce(a.kpv, j.kpv) >= params.kpv1
                            AND coalesce(a.kpv, j.kpv) <= params.kpv2
                            AND d.rekvid IN (
                                                SELECT rekv_id
                                                FROM rekv_ids
                                            )
                            AND d.status < 3
                            AND d.doc_type_id IN (
                                                     SELECT id
                                                     FROM docs_types
                                                 )
                            AND j1.kood5 IN (
                                                SELECT kood
                                                FROM qryArt
                                            )
                            AND NOT empty(j1.kood5)
                          GROUP BY
                              j1.kood1, j1.kood2, j1.kood3, coalesce(j1.kood4, ''), j1.kood5, j1.tunnus,
                              coalesce(j1.proj, ''), coalesce(j1.objekt, ''), j.rekvid
                      ) qry,
                        params
                  WHERE
                        NOT empty(qry.artikkel)
                    AND qry.summa <> 0
                    AND coalesce(qry.tunnus, '') ILIKE params.tunnus
                    AND coalesce(qry.tegev, '') ILIKE params.tegev
                    AND coalesce(qry.artikkel, '') ILIKE params.artikkel
                    AND coalesce(qry.allikas, '') ILIKE params.allikas
                    AND coalesce(qry.rahavoog, '') ILIKE params.rahavoog
                    AND coalesce(qry.proj, '') ILIKE params.proj
                    AND coalesce(qry.uritus, '') ILIKE params.uritus
                    AND coalesce(qry.objekt, '') ILIKE params.objekt
                  GROUP BY
                      qry.rekvid, qry.tegev, qry.allikas, qry.artikkel, qry.tunnus, qry.rahavoog, qry.proj, qry.uritus,
                      qry.objekt
              ),
    qryReport AS (
                  SELECT
                      rekvid,
                      sum(eelarve_kinni)            AS eelarve_kinni,
                      sum(eelarve_parandatud)       AS eelarve_parandatud,
                      sum(eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
                      sum(eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
                      sum(tegelik)                  AS tegelik,
                      sum(kassa)                    AS kassa,
                      COALESCE(qry.tegev, '')       AS tegev,
                      COALESCE(qry.allikas, '')     AS allikas,
                      COALESCE(qry.artikkel, '')    AS artikkel,
                      COALESCE(qry.rahavoog, '')    AS rahavoog,
                      qry.tunnus,
                      qry.proj,
                      qry.uritus,
                      qry.objekt,
                      idx
                  FROM
                      (
                          SELECT
                              e.rekvid,
                              e.summa                                         AS eelarve_kinni,
                              e.summa_kassa                                   AS eelarve_kassa_kinni,
                              0:: NUMERIC                                     AS eelarve_parandatud,
                              0:: NUMERIC                                     AS eelarve_kassa_parandatud,
                              0 :: NUMERIC                                    AS tegelik,
                              0 :: NUMERIC                                    AS kassa,
                              e.kood1                                         AS tegev,
                              e.kood2                                         AS allikas,
                              e.kood5                                         AS artikkel,
                              CASE
                                  WHEN e.kood5 = '2586'
                                      AND e.kood2 LIKE 'LE%' THEN '06'
                                  ELSE coalesce(e.kood3, '') END::VARCHAR(20) AS rahavoog,
                              COALESCE(e.tunnus, '')::VARCHAR(20)             AS tunnus,
                              coalesce(t1.proj, '')::VARCHAR(20)              AS proj,
                              coalesce(t1.kood4, '')::VARCHAR(20)             AS uritus,
                              coalesce(t1.objekt, '')                         AS objekt,
                              210                                             AS idx
                          FROM
                              eelarve.kulud                   e
                                  INNER JOIN eelarve.taotlus1 t1 ON t1.eelarveid = e.id,
                                                              params
                          WHERE
                                e.rekvid IN (
                                                SELECT rekv_id
                                                FROM rekv_ids
                                            )
                            AND e.aasta = params.aasta
                            AND e.kpv IS NULL
                            AND e.kood5 NOT LIKE '3%'
                            AND e.status <> 3
                            AND COALESCE(e.tunnus, '') ILIKE params.tunnus
                            AND COALESCE(e.kood1, '') ILIKE params.tegev
                            AND COALESCE(e.kood5, '') ILIKE params.artikkel
                            AND COALESCE(e.kood2, '') ILIKE params.allikas
                            AND coalesce(t1.proj, '') ILIKE params.proj
                            AND coalesce(t1.kood4, '') ILIKE params.uritus
                            AND coalesce(t1.objekt, '') ILIKE params.objekt
                            AND COALESCE((CASE
                                              WHEN e.kood5 = '2586'
                                                  AND e.kood2 LIKE 'LE%' THEN '06'
                                              ELSE coalesce(e.kood3, '') END::VARCHAR(20)), '') ILIKE params.rahavoog
                          UNION ALL
                          SELECT
                              e.rekvid,
                              0 :: NUMERIC                         AS eelarve_kinni,
                              0 :: NUMERIC                         AS eelarve_kassa_kinni,
                              e.summa                              AS eelarve_parandatud,
                              e.summa_kassa                        AS eelarve_kassa_parandatud,
                              0 :: NUMERIC                         AS tegelik,
                              0 :: NUMERIC                         AS kassa,
                              e.kood1                              AS tegev,
                              e.kood2                              AS allikas,
                              e.kood5                              AS artikkel,
                              CASE
                                  WHEN e.kood5 = '2586'
                                      AND e.kood2 LIKE 'LE%' THEN '06'
                                  ELSE e.kood3 END::VARCHAR(20)    AS rahavoog,
                              COALESCE(e.tunnus, '')               AS tunnus,
                              coalesce(t1.proj, '')::VARCHAR(20)   AS proj,
                              coalesce(t1.kood4, '')::VARCHAR(20)  AS uritus,
                              coalesce(t1.objekt, '')::VARCHAR(20) AS objekt,
                              210                                  AS idx
                          FROM
                              eelarve.kulud                        e
                                  LEFT OUTER JOIN eelarve.taotlus1 t1 ON t1.eelarveid = e.id,
                                                                   params
                          WHERE
                                e.rekvid IN (
                                                SELECT rekv_id
                                                FROM rekv_ids
                                            )
                            AND e.aasta = params.aasta
                            AND e.kood5 NOT LIKE '3%'
                            AND (e.kpv IS NULL OR e.kpv <= COALESCE(params.kpv2, CURRENT_DATE))
                            AND e.status <> 3
                            AND COALESCE(e.tunnus, '') ILIKE params.tunnus
                            AND COALESCE(e.kood1, '') ILIKE params.tegev
                            AND COALESCE(e.kood5, '') ILIKE params.artikkel
                            AND COALESCE(e.kood2, '') ILIKE params.allikas
                            AND coalesce(t1.proj, '') ILIKE params.proj
                            AND coalesce(t1.kood4, '') ILIKE params.uritus
                            AND coalesce(t1.objekt, '') ILIKE params.objekt
                            AND COALESCE((CASE
                                              WHEN e.kood5 = '2586'
                                                  AND e.kood2 LIKE 'LE%' THEN '06'
                                              ELSE coalesce(e.kood3, '') END::VARCHAR(20)), '') ILIKE params.rahavoog
                          UNION ALL
                          SELECT
                              ft.rekv_id                AS rekvid,
                              0 :: NUMERIC              AS eelarve_kinni,
                              0 :: NUMERIC              AS eelarve_parandatud,
                              0 :: NUMERIC              AS eelarve_kassa_kinni,
                              0 :: NUMERIC              AS eelarve_kassa_parandatud,
                              summa                     AS tegelik,
                              0 :: NUMERIC              AS kassa,
                              COALESCE(ft.tegev, '')    AS tegev,
                              COALESCE(ft.allikas, '')  AS allikas,
                              COALESCE(ft.artikkel, '') AS artikkel,
                              COALESCE(ft.rahavoog, '') AS rahavoog,
                              coalesce(ft.tunnus, '')   AS tunnus,
                              coalesce(ft.proj, '')     AS proj,
                              coalesce(ft.uritus, '')   AS uritus,
                              coalesce(ft.objekt, '')   AS objekt,
                              CASE
                                  WHEN (ft.artikkel LIKE '3%' OR ft.artikkel LIKE '655%') THEN 110
                                  WHEN ft.artikkel LIKE '4%' OR ft.artikkel LIKE '5%' OR
                                       (ft.artikkel LIKE '6%'
                                           AND ft.artikkel NOT LIKE '655%') OR
                                       ft.artikkel LIKE '15%' THEN 210
                                  ELSE 200 END          AS idx
                          FROM
                              cur_kulude_taitmine ft,
                                                  params
                          WHERE
                              ft.artikkel <> '2586'
                          --                    AND coalesce(ft.objekt, '') ILIKE params.objekt
--                    AND coalesce(ft.proj, '') ILIKE params.proj
                          -- Valentina B 24.10.2022
--                    AND CASE WHEN ft.artikkel = '4502' AND coalesce(ft.rahavoog = '24') THEN FALSE ELSE TRUE END
                          UNION ALL
                          SELECT
                              kt.rekv_id       AS rekvid,
                              0 :: NUMERIC     AS eelarve_kinni,
                              0 :: NUMERIC     AS eelarve_parandatud,
                              0 :: NUMERIC     AS eelarve_kassa_kinni,
                              0 :: NUMERIC     AS eelarve_kassa_parandatud,
                              0 :: NUMERIC     AS tegelik,
                              summa            AS kassa,
                              kt.tegev,
                              kt.allikas,
                              kt.artikkel,
                              kt.rahavoog,
                              kt.tunnus        AS tunnus,
                              kt.proj          AS proj,
                              kt.uritus        AS uritus,
                              kt.objekt        AS objekt,
                              CASE
                                  WHEN (kt.artikkel LIKE '3%' OR kt.artikkel LIKE '655%' OR
                                        ltrim(rtrim(kt.artikkel)) = '2585')
                                      THEN 110
                                  WHEN kt.artikkel LIKE '4%' OR kt.artikkel LIKE '5%' OR
                                       (kt.artikkel LIKE '6%'
                                           AND kt.artikkel NOT LIKE '655%') OR
                                       kt.artikkel LIKE '15%' THEN 210
                                  ELSE 200 END AS idx
                          FROM
                              cur_kulude_kassa_taitmine kt,
                                                        params
                          WHERE
                                kt.artikkel IS NOT NULL
                            AND NOT empty(kt.artikkel)
                            AND kt.artikkel <> '2586'
--                    AND coalesce(kt.objekt, '') ILIKE params.objekt

                          UNION ALL
                          SELECT
                              kt.rekv_id              AS rekvid,
                              0 :: NUMERIC            AS eelarve_kinni,
                              0 :: NUMERIC            AS eelarve_parandatud,
                              0 :: NUMERIC            AS eelarve_kassa_kinni,
                              0 :: NUMERIC            AS eelarve_kassa_parandatud,
                              0 :: NUMERIC            AS tegelik,
                              summa                   AS kassa,
                              kt.tegev,
                              kt.allikas,
                              kt.artikkel,
                              kt.rahavoog,
                              coalesce(kt.tunnus, '') AS tunnus,
                              coalesce(kt.proj, '')   AS proj,
                              coalesce(kt.uritus, '') AS uritus,
                              coalesce(kt.objekt, '') AS objekt,
                              CASE
                                  WHEN (kt.artikkel LIKE '3%' OR kt.artikkel LIKE '655%' OR
                                        ltrim(rtrim(kt.artikkel)) = '2585')
                                      THEN 110
                                  WHEN kt.artikkel LIKE '4%' OR kt.artikkel LIKE '5%' OR
                                       (kt.artikkel LIKE '6%'
                                           AND kt.artikkel NOT LIKE '655%') OR
                                       kt.artikkel LIKE '15%' THEN 210
                                  ELSE 210 END        AS idx
                          FROM
                              cur_kulude_kassa_taitmine kt,
                                                        params
                          WHERE
                                kt.artikkel IS NOT NULL
                            AND kt.artikkel = '2586'
                            AND kt.rahavoog = '06'
                          --                    AND coalesce(kt.objekt, '') ILIKE params.objekt
--                    AND coalesce(kt.proj, '') ILIKE params.proj
                          UNION ALL
                          SELECT
                              kt.rekv_id              AS rekvid,
                              0 :: NUMERIC            AS eelarve_kinni,
                              0 :: NUMERIC            AS eelarve_parandatud,
                              0 :: NUMERIC            AS eelarve_kassa_kinni,
                              0 :: NUMERIC            AS eelarve_kassa_parandatud,
                              0 :: NUMERIC            AS tegelik,
                              (summa)                 AS kassa,
                              kt.tegev,
                              kt.allikas,
                              '2586',
                              kt.rahavoog,
                              coalesce(kt.tunnus, '') AS tunnus,
                              coalesce(kt.proj, '')   AS proj,
                              coalesce(kt.uritus, '') AS uritus,
                              kt.objekt               AS objekt,
                              100                     AS idx
                          FROM
                              cur_kulude_kassa_taitmine kt,
                                                        params
                          WHERE
                                kt.artikkel IS NOT NULL
                            AND kt.artikkel = '2586'
                            AND kt.allikas = '80'
                          --                    AND coalesce(kt.objekt, '') ILIKE params.objekt
--                    AND coalesce(kt.proj, '') ILIKE params.proj
                          UNION ALL
                          SELECT
                              D.rekvid,
                              0 :: NUMERIC            AS eelarve_kinni,
                              0 :: NUMERIC            AS eelarve_parandatud,
                              0 :: NUMERIC            AS eelarve_kassa_kinni,
                              0 :: NUMERIC            AS eelarve_kassa_parandatud,
                              (summa)                 AS tegelik,
                              0 :: NUMERIC            AS kassa,
                              COALESCE(j1.kood1, '')  AS tegev,
                              COALESCE(j1.kood2, '')  AS allikas,
                              COALESCE('2586 ', '')   AS artikkel,
                              COALESCE(j1.kood3, '')  AS rahavoog,
                              coalesce(j1.tunnus, '') AS tunnus,
                              coalesce(j1.proj, '')   AS proj,
                              coalesce(j1.kood4, '')  AS uritus,
                              coalesce(j1.objekt, '') AS objekt,
                              210                     AS idx
                          FROM
                              docs.doc                     D
                                  INNER JOIN docs.journal  j ON D.id = j.parentid
                                  INNER JOIN docs.journal1 j1 ON j.id = j1.parentid,
                                                           params
                          WHERE
                                D.rekvid IN (
                                                SELECT rekv_id
                                                FROM rekv_ids
                                            )
                            AND D.status < 3
                            AND D.doc_type_id IN (
                                                     SELECT id
                                                     FROM docs_types
                                                 )
                            AND j.kpv < gomonth(make_date(params.aasta, MONTH(params.kpv2), 1), 1)
                            AND j.kpv >= make_date(params.aasta, MONTH(params.kpv1), 1)
                            AND j1.kood5 IS NOT NULL
                            AND NOT empty(j1.kood5)
                            AND ((LEFT(j1.deebet, 3) = '208'
                              AND j1.kood3 = '06')
                              OR (LEFT(j1.deebet, 3) = '258'
                                  AND j1.kood3 = '06'))
                      ) qry,
                        params
                  WHERE
                        coalesce(qry.objekt,'') ILIKE params.objekt
                    AND coalesce(qry.proj,'') ILIKE params.proj
                    AND coalesce(qry.tunnus,'') ILIKE params.tunnus
                    AND coalesce(qry.tegev,'') ILIKE params.tegev
                    AND qry.artikkel ILIKE params.artikkel
                    AND qry.allikas ILIKE params.allikas
                    AND coalesce(qry.rahavoog,'') ILIKE params.rahavoog
                    AND coalesce(qry.objekt,'') ILIKE params.objekt
                    AND coalesce(qry.proj,'') ILIKE params.proj

                  -- 23.02.2024
                  GROUP BY
                      qry.rekvid,
                      qry.tegev,
                      qry.allikas,
                      qry.artikkel,
                      qry.rahavoog,
                      qry.tunnus,
                      qry.proj,
                      qry.uritus,
                      qry.objekt,
                      idx
              ),
    preReport AS (
                  SELECT
                      rekvid,
                      sum(eelarve_kinni)                                AS eelarve_kinni,
                      sum(eelarve_parandatud)                           AS eelarve_parandatud,
                      sum(eelarve_kassa_kinni)                          AS eelarve_kassa_kinni,
                      SUM(eelarve_kassa_parandatud)                     AS eelarve_kassa_parandatud,
                      sum(tegelik)                                      AS tegelik,
                      sum(kassa)                                        AS kassa,
                      tegev,
                      allikas,
                      artikkel,
                      rahavoog,
                      tunnus,
                      proj,
                      uritus,
                      coalesce(objekt, '')::VARCHAR(20)                 AS objekt,
                      CASE WHEN artikkel = '1532' THEN 110 ELSE idx END AS idx
                  FROM
                      qryReport
                  GROUP BY
                      rekvid,
                      tegev,
                      allikas,
                      artikkel,
                      rahavoog,
                      tunnus,
                      proj,
                      uritus,
                      objekt,
                      idx
                  UNION ALL
-- 2586 свод
                  SELECT
                      rekvid,
                      sum(eelarve_kinni)            AS eelarve_kinni,
                      sum(eelarve_parandatud)       AS eelarve_parandatud,
                      sum(eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
                      SUM(eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
                      sum(tegelik)                  AS tegelik,
                      sum(kassa)                    AS kassa,
                      ''                            AS tegev,
                      '80'                          AS allikas,
                      '2586(A80)'                   AS artikkel,
                      ''                            AS rahavoog,
                      ''                            AS tunnus,
                      ''                            AS proj,
                      ''                            AS uritus,
                      ''                            AS objekt,
                      095                           AS idx
                  FROM
                      qryReport
                  WHERE
                        artikkel = '2586'
                    AND allikas = '80'
                  GROUP BY rekvid
                  UNION ALL
                  -- Põhitegevuse kulud                  (здесь  art 2586 с RV 06, 4*, 5*, 6 )
                  SELECT
                      rekvid,
                      sum(eelarve_kinni)            AS eelarve_kinni,
                      sum(eelarve_parandatud)       AS eelarve_parandatud,
                      sum(eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
                      SUM(eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
                      sum(tegelik)                  AS tegelik,
                      sum(kassa)                    AS kassa,
                      ''                            AS tegev,
                      ''                            AS allikas,
                      '15,2586,4,5,6'               AS artikkel,
                      ''                            AS rahavoog,
                      ''                            AS tunnus,
                      ''                            AS proj,
                      ''                            AS uritus,
                      ''                            AS objekt,
                      200                           AS idx
                  FROM
                      qryReport
                  WHERE
                        idx >= 200
                    AND qryReport.artikkel NOT IN ('2585', '1532')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT
                      kt.rekvid    AS rekvid,
                      0 :: NUMERIC AS eelarve_kinni,
                      0 :: NUMERIC AS eelarve_parandatud,
                      0 :: NUMERIC AS eelarve_kassa_kinni,
                      0 :: NUMERIC AS eelarve_kassa_parandatud,
                      0 :: NUMERIC AS tegelik,
                      sum(kassa)   AS kassa,
                      ''           AS tegev,
                      ''           AS allikas,
                      '15, 3, 655' AS artikkel,
                      ''           AS rahavoog,
                      ''           AS tunnus,
                      ''           AS proj,
                      ''           AS uritus,
                      ''           AS objekt,
                      110          AS idx
                  FROM
                      qryReport kt
                  WHERE
                        kt.artikkel IS NOT NULL
                    AND (artikkel LIKE '3%' OR artikkel LIKE '655%'
                      OR artikkel = '1532'
                      OR artikkel = '2585'
                            )
                  GROUP BY rekvid
              )
SELECT *
FROM
    (
        SELECT *
        FROM
            preReport
        UNION ALL
-- kond
        SELECT
            999999,
            sum(eelarve_kinni)            AS eelarve_kinni,
            sum(eelarve_parandatud)       AS eelarve_parandatud,
            sum(eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
            SUM(eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
            sum(tegelik)                  AS tegelik,
            sum(kassa)                    AS kassa,
            tegev,
            allikas,
            artikkel,
            rahavoog,
            tunnus,
            proj,
            uritus,
            objekt,
            idx
        FROM
            preReport
        WHERE
            l_kond > 0
        GROUP BY
            tegev,
            allikas,
            artikkel,
            rahavoog,
            tunnus,
            proj,
            uritus,
            objekt,
            idx
    ) qry
WHERE
    (eelarve_kinni <> 0 OR eelarve_parandatud <> 0 OR eelarve_kassa_kinni <> 0 OR
     eelarve_kassa_parandatud <> 0 OR tegelik <> 0 OR kassa <> 0)

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_art_ta_allikas_proj_tunnus(INTEGER, DATE, DATE, INTEGER, INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_art_ta_allikas_proj_tunnus(INTEGER, DATE, DATE, INTEGER, INTEGER,JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_art_ta_allikas_proj_tunnus(INTEGER, DATE, DATE, INTEGER, INTEGER, JSONB) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_art_ta_allikas_proj_tunnus(INTEGER, DATE, DATE, INTEGER, INTEGER, JSONB) TO dbvaatleja;


SELECT *
FROM
    eelarve.eelarve_taitmine_art_ta_allikas_proj_tunnus(2024::INTEGER, '2024-12-01'::date, '2024-12-31'::DATE, 125, 0,
                                                        '        {
                                                          "artikkel": "5002",
                                                          "tegev": "",
                                                          "allikas": "",
                                                          "rahavoog": "",
                                                          "tunnus": "",
                                                          "proj": "",
                                                          "objekt": "",
                                                          "uritus": ""
                                                        }        ')


/*
SELECT *
FROM eelarve.eelarve_taitmine_art_ta_allikas_proj_tunnus(2023::INTEGER, '2023-01-01'::DATE, '2023-12-31'::DATE, 63, 0,
                                                         '{
                                                           "allikas": null,
                                                           "artikkel": null,
                                                           "proj": ""
                                                         }')
*/
/*
--artikkel like
         SELECT *
         FROM eelarve.eelarve_taitmine_art_ta_allikas_proj_tunnus(2024::INTEGER,'2024-12-01'::date, '2024-12-31'::DATE, 125, 0,'{"allikas":"60", "artikkel":"5002", "tunnus":null}')
where tunnus is not null and not empty(tunnus)
lep.2023013916

*/