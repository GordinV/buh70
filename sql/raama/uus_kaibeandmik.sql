-- C:/development/buh70/sql/raama/uus_kaibeandmik.sql
DROP FUNCTION IF EXISTS docs.kaibeandmik(DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeandmik(DATE, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeandmik(DATE, DATE, INTEGER, INTEGER, TEXT);
DROP FUNCTION IF EXISTS docs.kaibeandmik(DATE, DATE, INTEGER, INTEGER, TEXT, JSONB);

CREATE OR REPLACE FUNCTION docs.kaibeandmik(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER DEFAULT 0,
                                            l_tunnus TEXT DEFAULT '%', l_params JSONB DEFAULT NULL::JSONB)
    RETURNS TABLE
            (
                alg_saldo NUMERIC(14, 2),
                deebet    NUMERIC(14, 2),
                kreedit   NUMERIC(14, 2),
                konto     VARCHAR(20)
            )
AS
$BODY$
BEGIN
    -- Если запрос начинается с 2026 года, используем оптимизацию через MATERIALIZED VIEW
    IF l_kpv1 >= '2026-01-01'::DATE THEN
        RETURN QUERY
            WITH
                rekv_ids AS (
                                SELECT
                                    rekv_id
                                FROM
                                    public.get_asutuse_struktuur(l_rekvid) r
                                WHERE
                                    CASE
                                        WHEN l_kond = 1 THEN TRUE
                                        ELSE l_rekvid = rekv_id END
                            ),
                params AS (
                                SELECT
                                    coalesce(l_params::JSONB ->> 'konto', '')::TEXT || '%'   AS konto,
                                    coalesce(l_params::JSONB ->> 'tunnus', '')::TEXT || '%'  AS tunnus,
                                    coalesce(l_params::JSONB ->> 'proj', '')::TEXT || '%'    AS proj,
                                    coalesce(l_params::JSONB ->> 'uritus', '')::TEXT || '%'  AS uritus,
                                    coalesce(l_params::JSONB ->> 'objekt', '')::TEXT || '%'  AS objekt, -- ДОБАВЛЕНО
                                    coalesce(l_params::JSONB ->> 'allikas', '')::TEXT || '%' AS allikas,
                                    l_kpv1                                                   AS kpv_1,
                                    l_kpv2                                                   AS kpv_2
                            ),
                -- 1. Данные из архива (до 31.12.2025 включительно) через VIEW
                archive_data AS (
                                SELECT
                                    k.rekvid,
                                    k.kpv,
                                    k.deebet,
                                    k.kreedit,
                                    k.summa,
                                    k.tunnus,
                                    k.proj,
                                    k.kood4,
                                    k.kood2,
                                    k.objekt, -- ДОБАВЛЕНО
                                    k.docs_id AS docs_ids
                                FROM
                                    docs.kaibed             k
                                        INNER JOIN rekv_ids r ON k.rekvid = r.rekv_id
                                        INNER JOIN params   p ON TRUE
                                WHERE
                                      (k.deebet LIKE p.konto OR k.kreedit LIKE p.konto)
                                  AND (l_params ->> 'tunnus' IS NULL OR coalesce(k.tunnus, '') ILIKE p.tunnus)
                                  AND (l_params ->> 'proj' IS NULL OR coalesce(k.proj, '') ILIKE p.proj)
                                  AND (l_params ->> 'uritus' IS NULL OR coalesce(k.kood4, '') ILIKE p.uritus)
                                  AND (l_params ->> 'objekt' IS NULL OR coalesce(k.objekt, '') ILIKE p.objekt) -- ДОБАВЛЕНО
                                  AND (l_params ->> 'allikas' IS NULL OR coalesce(k.kood2, '') ILIKE p.allikas)
                            ),
                -- 2. Оперативные данные (с 01.01.2026)
                live_data AS (
                                SELECT
                                    d.id as doc_id,
                                    d.rekvid,
                                    j.kpv,
                                    j1.deebet,
                                    j1.kreedit,
                                    j1.summa,
                                    j1.tunnus,
                                    j1.proj,
                                    j1.objekt, -- ДОБАВЛЕНО
                                    j1.kood4,
                                    j1.kood2
                                FROM
                                    docs.doc                           d
                                        INNER JOIN      docs.journal   j ON j.parentid = d.id
                                        INNER JOIN      docs.journal1  j1 ON j1.parentid = j.id
                                        INNER JOIN      rekv_ids       r ON r.rekv_id = d.rekvid
                                        INNER JOIN      params         p ON TRUE
                                        LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                                WHERE
                                      j.kpv >= '2026-01-01'::DATE
                                  AND j.kpv <= p.kpv_2
                                  AND d.status < 3
                                  AND d.doc_type_id = 57
                                  AND (j1.deebet LIKE p.konto OR j1.kreedit LIKE p.konto)
                                  AND (a.id IS NULL OR a.kpv <> '2025-12-31'::DATE)
                                  AND (l_params ->> 'tunnus' IS NULL OR coalesce(j1.tunnus, '') ILIKE p.tunnus)
                                  AND (l_params ->> 'proj' IS NULL OR coalesce(j1.proj, '') ILIKE p.proj)
                                  AND (l_params ->> 'uritus' IS NULL OR coalesce(j1.kood4, '') ILIKE p.uritus)
                                  AND (l_params ->> 'objekt' IS NULL OR coalesce(j1.objekt, '') ILIKE p.objekt) -- ДОБАВЛЕНО
                                  AND (l_params ->> 'allikas' IS NULL OR coalesce(j1.kood2, '') ILIKE p.allikas)
                            ),
                -- Объединяем архив и живые данные
                combined_rows AS (
                                     -- Архив (View), docs_ids уже массив
                                SELECT
                                    ad.rekvid,
                                    ad.kpv,
                                    ad.deebet as konto,
                                    ad.summa,
                                    1         as is_deebet,
                                    ad.docs_ids
                                FROM
                                    archive_data ad
                                UNION ALL
                                SELECT
                                    ad.rekvid,
                                    ad.kpv,
                                    ad.kreedit as konto,
                                    summa,
                                    0          as is_deebet,
                                    ad.docs_ids
                                FROM
                                    archive_data ad
                                UNION ALL
                                -- Живые (Live), doc_id скаляр, превращаем в массив для совместимости в combined_rows
                                SELECT
                                    ld.rekvid,
                                    kpv,
                                    ld.deebet         as konto,
                                    ld.summa,
                                    1                 as is_deebet,
                                    ARRAY [ld.doc_id] as docs_ids
                                FROM
                                    live_data ld
                                UNION ALL
                                SELECT
                                    ld.rekvid,
                                    ld.kpv,
                                    ld.kreedit        as konto,
                                    ld.summa,
                                    0                 as is_deebet,
                                    ARRAY [ld.doc_id] as docs_ids
                                FROM
                                    live_data ld
                            ),
                -- Агрегация СУММ
                pre_aggregation_sums AS (
                                SELECT
                                    c.konto,
                                    SUM(
                                            CASE
                                                WHEN c.kpv < p.kpv_1 THEN
                                                    CASE
                                                        WHEN extract(year from c.kpv) < extract(year from p.kpv_1) AND
                                                             left(c.konto, 1) IN ('8', '9') THEN 0
                                                        ELSE 1
                                                        END * (CASE WHEN c.is_deebet = 1 THEN c.summa ELSE -c.summa END)
                                                ELSE 0
                                                END
                                    )                                                                           as alg_saldo,
                                    SUM(CASE WHEN c.kpv >= p.kpv_1 AND c.is_deebet = 1 THEN c.summa ELSE 0 END) as turnover_deebet,
                                    SUM(CASE WHEN c.kpv >= p.kpv_1 AND c.is_deebet = 0 THEN c.summa ELSE 0 END) as turnover_kreedit
                                FROM
                                    combined_rows c,
                                    params        p
                                WHERE
                                    c.konto LIKE p.konto
                                GROUP BY c.konto
                            ),
                -- Агрегация ID (разворачиваем массивы и собираем уникальные)
                pre_aggregation_ids AS (
                                SELECT
                                    c.konto,
                                    array_agg(DISTINCT u_id) as docs_ids
                                FROM
                                    combined_rows      c,
                                    params             p,
                                    unnest(c.docs_ids) u_id
                                WHERE
                                    c.konto LIKE p.konto
                                GROUP BY c.konto
                            )

            SELECT
                q.alg_saldo::NUMERIC(14, 2),
                q.turnover_deebet::NUMERIC(14, 2)  AS deebet,
                q.turnover_kreedit::NUMERIC(14, 2) AS kreedit,
                q.konto::VARCHAR(20)
            FROM
                pre_aggregation_sums               q
                    INNER JOIN pre_aggregation_ids i ON i.konto = q.konto
            WHERE
                  (q.alg_saldo <> 0 OR q.turnover_deebet <> 0 OR q.turnover_kreedit <> 0)
              AND left(q.konto, 1) NOT IN ('0')
              AND q.konto NOT IN (
                                     SELECT
                                         kood
                                     FROM
                                         com_kontoplaan
                                     WHERE
                                         kas_virtual > 0
                                 );


    ELSE
        -- СТАРАЯ ЛОГИКА (Legacy) для запросов до 2026 года
        RETURN QUERY
            WITH
                rekv_ids AS (
                                SELECT
                                    rekv_id
                                FROM
                                    public.get_asutuse_struktuur(l_rekvid) r
                                WHERE
                                    CASE
                                        WHEN l_kond = 1 THEN TRUE
                                        ELSE l_rekvid = rekv_id END
                            ),
                params AS (
                                SELECT
                                    coalesce(l_params::JSONB ->> 'konto', '')::TEXT || '%'   AS konto,
                                    coalesce(l_params::JSONB ->> 'tunnus', '')::TEXT || '%'  AS tunnus,
                                    coalesce(l_params::JSONB ->> 'proj', '')::TEXT || '%'    AS proj,
                                    coalesce(l_params::JSONB ->> 'uritus', '')::TEXT || '%'  AS uritus,
                                    coalesce(l_params::JSONB ->> 'objekt', '')::TEXT || '%'  AS objekt, -- ДОБАВЛЕНО
                                    coalesce(l_params::JSONB ->> 'allikas', '')::TEXT || '%' AS allikas,
                                    l_kpv1                                                   AS kpv_1,
                                    l_kpv2                                                   AS kpv_2
                            ),

                alg_docs AS (
                                SELECT
                                    d.id         as doc_id,
                                    d.rekvid,
                                    (j1.summa)   AS summa,
                                    j1.deebet    AS deebet,
                                    j1.kreedit   AS kreedit,
                                    j1.tunnus,
                                    j1.kood4,
                                    j1.kood2,
                                    j1.proj,
                                    j1.objekt, -- ДОБАВЛЕНО
                                    calc_kpv.kpv AS kpv
                                FROM
                                    docs.doc                                                                      d
                                        INNER JOIN      docs.journal                                              j ON j.parentid = d.id
                                        INNER JOIN      docs.journal1                                             j1 ON j1.parentid = j.id
                                        INNER JOIN      rekv_ids                                                  r ON r.rekv_id = d.rekvid
                                        LEFT OUTER JOIN docs.alg_saldo                                            a ON a.journal_id = d.id
                                        CROSS JOIN      params
                                        CROSS JOIN      LATERAL (SELECT
                                                                     docs.get_alg_saldo_kpv(a.kpv, j.kpv,
                                                                                            make_date(year(params.kpv_1), 01, 01),
                                                                                            params.kpv_2) AS kpv) calc_kpv
                                WHERE
                                      calc_kpv.kpv < params.kpv_1
                                  AND d.status < 3
                                  AND d.doc_type_id = 57 -- проводки
                                  AND (j1.deebet LIKE params.konto || '%' OR j1.kreedit LIKE params.konto || '%')
                            ),

                algsaldo AS (
                                SELECT
                                    sum(qry.deebet) - sum(qry.kreedit) AS alg_saldo,
                                    qry.konto,
                                    qry.rekvid,
                                    null::integer                      as docs_ids -- Возвращаем скалярный ID
                                FROM
                                    (
                                        SELECT
                                            d.rekvid,
                                            sum(CASE
                                                    WHEN date_part('year', d.kpv) < date_part('year', l_kpv1) AND
                                                         lpad(d.deebet, 1) IN ('8', '9') THEN 0
                                                    ELSE 1 END * d.summa) AS deebet,
                                            0 :: NUMERIC(14, 2)           AS kreedit,
                                            trim(d.deebet)::VARCHAR(20)   AS konto,
                                            null::integer                 as doc_id
                                        FROM
                                            alg_docs d
                                        WHERE
                                            d.kpv < make_date(year(l_kpv1), 01, 01)
                                          AND (((CASE
                                                     WHEN left(d.deebet, 1) IN ('1', '2') THEN l_params::JSONB
                                                     ELSE '{}'::JSONB END) ->>
                                                'tunnus') IS NULL OR
                                               COALESCE(d.tunnus, '') ILIKE
                                               COALESCE((l_params::JSONB ->> 'tunnus'), '') || '%')
                                          AND (((CASE
                                                     WHEN left(d.deebet, 1) IN ('1', '2') THEN l_params::JSONB
                                                     ELSE '{}'::JSONB END) ->>
                                                'proj') IS NULL OR
                                               COALESCE(d.proj, '') ILIKE
                                               COALESCE((l_params::JSONB ->> 'proj'), '') || '%')
                                          AND (((CASE
                                                     WHEN left(d.deebet, 1) IN ('1', '2') THEN l_params::JSONB
                                                     ELSE '{}'::JSONB END) ->>
                                                'uritus') IS NULL OR
                                               COALESCE(d.kood4, '') ILIKE
                                               COALESCE((l_params::JSONB ->> 'uritus'), '') || '%')
                                          AND (((CASE
                                                     WHEN left(d.deebet, 1) IN ('1', '2') THEN l_params::JSONB
                                                     ELSE '{}'::JSONB END) ->>
                                                'objekt') IS NULL OR
                                               COALESCE(d.objekt, '') ILIKE
                                               COALESCE((l_params::JSONB ->> 'objekt'), '') || '%') -- ДОБАВЛЕНО
                                          AND (l_params::JSONB ->> 'allikas' IS NULL OR
                                               COALESCE(d.kood2, '') ILIKE
                                               COALESCE((l_params::JSONB ->> 'allikas'), '') || '%')
                                        GROUP BY d.deebet, d.rekvid
                                        UNION ALL
                                        SELECT
                                            d.rekvid,
                                            sum(d.summa)                AS deebet,
                                            0 :: NUMERIC(14, 2)         AS kreedit,
                                            trim(d.deebet)::VARCHAR(20) AS konto,
                                            null::integer               as doc_id
                                        FROM
                                            alg_docs d
                                        WHERE
                                            d.kpv >= make_date(year(l_kpv1), 01, 01)
                                          AND d.kpv < l_kpv1
                                          AND (l_params::JSONB ->> 'tunnus' IS NULL OR
                                               COALESCE(d.tunnus, '') ILIKE
                                               COALESCE((l_params::JSONB ->> 'tunnus'), '') || '%')
                                          AND (l_params::JSONB ->> 'proj' IS NULL OR
                                               COALESCE(d.proj, '') ILIKE
                                               COALESCE((l_params::JSONB ->> 'proj'), '') || '%')
                                          AND (l_params::JSONB ->> 'uritus' IS NULL OR
                                               COALESCE(d.kood4, '') ILIKE
                                               COALESCE((l_params::JSONB ->> 'uritus'), '') || '%')
                                          AND (l_params::JSONB ->> 'objekt' IS NULL OR
                                               COALESCE(d.objekt, '') ILIKE
                                               COALESCE((l_params::JSONB ->> 'objekt'), '') || '%') -- ДОБАВЛЕНО
                                          AND (l_params::JSONB ->> 'allikas' IS NULL OR
                                               COALESCE(d.kood2, '') ILIKE
                                               COALESCE((l_params::JSONB ->> 'allikas'), '') || '%')
                                        GROUP BY d.deebet, d.rekvid
                                        UNION ALL
                                        SELECT
                                            d.rekvid,
                                            0 :: NUMERIC                  AS deebet,
                                            sum(CASE
                                                    WHEN date_part('year', d.kpv) < date_part('year', l_kpv1) AND
                                                         lpad(d.kreedit, 1) IN ('8', '9') THEN 0
                                                    ELSE 1 END * d.summa) AS kreedit,
                                            trim(d.kreedit)::VARCHAR(20)  AS konto,
                                            null::integer                 as doc_id
                                        FROM
                                            alg_docs d
                                        WHERE
                                            d.kpv < make_date(year(l_kpv1), 01, 01)
                                          AND (((CASE
                                                     WHEN left(d.kreedit, 1) IN ('1', '2') THEN l_params::JSONB
                                                     ELSE '{}'::JSONB END) ->>
                                                'tunnus') IS NULL OR
                                               COALESCE(d.tunnus, '') ILIKE
                                               COALESCE((l_params::JSONB ->> 'tunnus'), '') || '%')
                                          AND (((CASE
                                                     WHEN left(d.kreedit, 1) IN ('1', '2') THEN l_params::JSONB
                                                     ELSE '{}'::JSONB END) ->>
                                                'proj') IS NULL OR
                                               coalesce(d.proj, '') ILIKE
                                               coalesce((l_params::JSONB ->> 'proj'), '') || '%')
                                          AND (((CASE
                                                     WHEN left(d.kreedit, 1) IN ('1', '2') THEN l_params::JSONB
                                                     ELSE '{}'::JSONB END) ->>
                                                'uritus') IS NULL OR
                                               left(d.kreedit, 1) IN ('1', '2') OR
                                               coalesce(d.kood4, '') ILIKE
                                               coalesce((l_params::JSONB ->> 'uritus'), '') || '%')
                                          AND (((CASE
                                                     WHEN left(d.kreedit, 1) IN ('1', '2') THEN l_params::JSONB
                                                     ELSE '{}'::JSONB END) ->>
                                                'objekt') IS NULL OR
                                               COALESCE(d.objekt, '') ILIKE
                                               COALESCE((l_params::JSONB ->> 'objekt'), '') || '%') -- ДОБАВЛЕНО
                                          AND (l_params::JSONB ->> 'allikas' IS NULL OR
                                               coalesce(d.kood2, '') ILIKE
                                               coalesce((l_params::JSONB ->> 'allikas'), '') || '%')

                                        GROUP BY d.kreedit, d.rekvid
                                        UNION ALL
                                        SELECT
                                            d.rekvid,
                                            0 :: NUMERIC                 AS deebet,
                                            sum(d.summa)                 AS kreedit,
                                            trim(d.kreedit)::VARCHAR(20) AS konto,
                                            null::integer                as doc_id
                                        FROM
                                            alg_docs d
                                        WHERE
                                            d.kpv >= make_date(year(l_kpv1), 01, 01)
                                          AND d.kpv < l_kpv1
                                          AND ((l_params::JSONB ->> 'tunnus') IS NULL OR
                                               COALESCE(d.tunnus, '') ILIKE
                                               COALESCE((l_params::JSONB ->> 'tunnus'), '') || '%')
                                          AND ((l_params::JSONB ->>
                                                'proj') IS NULL OR
                                               coalesce(d.proj, '') ILIKE
                                               coalesce((l_params::JSONB ->> 'proj'), '') || '%')
                                          AND ((l_params::JSONB ->>
                                                'uritus') IS NULL OR
                                               coalesce(d.kood4, '') ILIKE
                                               coalesce((l_params::JSONB ->> 'uritus'), '') || '%')
                                          AND ((l_params::JSONB ->>
                                                'objekt') IS NULL OR
                                               coalesce(d.objekt, '') ILIKE
                                               coalesce((l_params::JSONB ->> 'objekt'), '') || '%') -- ДОБАВЛЕНО
                                          AND (l_params::JSONB ->> 'allikas' IS NULL OR
                                               coalesce(d.kood2, '') ILIKE
                                               coalesce((l_params::JSONB ->> 'allikas'), '') || '%')
                                        GROUP BY d.kreedit, d.rekvid
                                    ) qry
                                group by qry.konto, qry.rekvid
                                -- Убираем GROUP BY здесь, возвращаем плоские строки, чтобы избежать сложной агрегации массивов
                            )

            SELECT
                sum(qry.alg_saldo) AS alg_saldo,
                sum(qry.deebet)    AS deebet,
                sum(qry.kreedit)   AS kreedit,
                qry.konto
            FROM
                (
                    WITH
                        docs AS (
                                    SELECT
                                        d.rekvid,
                                        0 :: NUMERIC(14, 2)                                     AS alg_saldo,
                                        sum(CASE WHEN v.is_deebet THEN j1.summa ELSE 0 END)     AS deebet,
                                        sum(CASE WHEN NOT v.is_deebet THEN j1.summa ELSE 0 END) AS kreedit,
                                        v.konto::VARCHAR(20)                                    AS konto,
                                        j1.proj,
                                        j1.tunnus,
                                        j1.kood4,
                                        j1.kood2,
                                        j1.objekt,                                                        -- ДОБАВЛЕНО
                                        null::integer                                           as doc_id -- Возвращаем скаляр
                                    FROM
                                        docs.doc                           d
                                            INNER JOIN      docs.journal   j ON j.parentid = d.id
                                            INNER JOIN      docs.journal1  j1 ON j1.parentid = j.id
                                            LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                                            CROSS JOIN      params
                                            CROSS JOIN      LATERAL (
                                                                SELECT
                                                                    trim(j1.deebet) AS konto,
                                                                    TRUE            AS is_deebet
                                                                UNION ALL
                                                                SELECT
                                                                    trim(j1.kreedit),
                                                                    FALSE
                                                                )          v
                                    WHERE
                                          docs.get_alg_saldo_kpv(a.kpv, j.kpv, params.kpv_1, params.kpv_2) >=
                                          params.kpv_1
                                      AND docs.get_alg_saldo_kpv(a.kpv, j.kpv, params.kpv_1, params.kpv_2) <=
                                          params.kpv_2
                                      AND d.status < 3
                                      AND d.rekvid IN (
                                                          SELECT
                                                              rekv_id
                                                          FROM
                                                              rekv_ids
                                                      )
                                      AND d.doc_type_id = 57
                                      AND v.konto LIKE params.konto
                                    GROUP BY d.rekvid, v.konto, j1.proj, j1.tunnus, j1.kood4, j1.kood2, j1.objekt
                        )
                    SELECT
                        algsaldo.rekvid,
                        algsaldo.alg_saldo,
                        0 :: NUMERIC(14, 2) AS deebet,
                        0 :: NUMERIC(14, 2) AS kreedit,
                        algsaldo.konto,
                        algsaldo.docs_ids   as doc_id
                    FROM
                        algsaldo
                    UNION ALL
                    SELECT
                        d.rekvid,
                        0 :: NUMERIC(14, 2)  AS alg_saldo,
                        d.deebet             AS deebet,
                        d.kreedit            AS kreedit,
                        d.konto::VARCHAR(20) AS konto,
                        d.doc_id
                    FROM
                        docs d
                    WHERE
                        coalesce(d.tunnus, '') ILIKE coalesce(l_tunnus, '%')
                      AND (l_params ->> 'tunnus' IS NULL OR
                           coalesce(d.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus'), '') || '%')
                      AND (l_params ->> 'proj' IS NULL OR
                           coalesce(d.proj, '') ILIKE coalesce((l_params ->> 'proj'), '') || '%')
                      AND (l_params ->> 'uritus' IS NULL OR
                           coalesce(d.kood4, '') ILIKE coalesce((l_params ->> 'uritus'), '') || '%')
                      AND (l_params ->> 'objekt' IS NULL OR
                           coalesce(d.objekt, '') ILIKE coalesce((l_params ->> 'objekt'), '') || '%') -- ДОБАВЛЕНО
                      AND (l_params ->> 'allikas' IS NULL OR
                           coalesce(d.kood2, '') ILIKE coalesce((l_params ->> 'allikas'), '') || '%')
                ) qry,
                  params
            WHERE
                  NOT empty(qry.konto)
              AND left(qry.konto, 1) NOT IN ('8', '9', '0')
              AND qry.konto NOT IN (
                                       SELECT
                                           kood
                                       FROM
                                           com_kontoplaan
                                       WHERE
                                           kas_virtual > 0
                                   )
              AND qry.konto LIKE params.konto
            GROUP BY
                qry.konto;
    END IF;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.kaibeandmik( DATE, DATE, INTEGER,INTEGER , TEXT, JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kaibeandmik( DATE, DATE, INTEGER, INTEGER, TEXT, JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kaibeandmik( DATE, DATE, INTEGER,INTEGER, TEXT, JSONB ) TO dbkasutaja;