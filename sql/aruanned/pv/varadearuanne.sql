DROP FUNCTION IF EXISTS docs.varadearuanne(DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.varadearuanne(DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.varadearuanne(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.varadearuanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER DEFAULT 0)
    RETURNS TABLE
            (
                rekv_id       INTEGER,
                kood          VARCHAR(20),
                nimetus       VARCHAR(254),
                konto         VARCHAR(20),
                grupp         VARCHAR(254),
                soet_kpv      DATE,
                soetmaks      NUMERIC(14, 2),
                vastisik_id   INTEGER,
                vastisik      TEXT,
                alg_kulum     NUMERIC(14, 2),
                kulum         NUMERIC(14, 2),
                kulum_percent NUMERIC(14, 2),
                parandus      NUMERIC(14, 2),
                mahakantud    NUMERIC(14, 2),
                jaak          NUMERIC(14, 2),
                grupp_id      INTEGER
            )
AS
$BODY$
WITH
    umberklassifitseerimine AS (
                                   SELECT
                                       max(id) AS id,
                                       pv_kaart_id
                                   FROM
                                       docs.pv_oper po
                                   WHERE
                                         liik = 6 -- umeberklassifitseerimine
                                     AND kpv <= l_kpv2
                                   GROUP BY pv_kaart_id
                               ),
    rekv_ids AS (
                                   SELECT
                                       rekv_id
                                   FROM
                                       get_asutuse_struktuur(l_rekvid)
                                   WHERE
                                       rekv_id = CASE
                                                     WHEN l_kond = 1
                                                         THEN rekv_id
                                                     ELSE l_rekvid END
                               ),
    uusPv AS (
                                   SELECT
                                       p.rekvid                    AS rekv_id,
                                       p.kood,
                                       p.nimetus,
                                       p.grupp,
                                       p.gruppid,
                                       p.konto,
                                       l.properties::JSONB ->>
                                       'korr_konto'                AS eelmise_konto,
                                       p.soetkpv,
                                       p.vastisikid,
                                       COALESCE((
                                                    SELECT
                                                        sum(summa)
                                                    FROM
                                                        docs.pv_oper po
                                                    WHERE
                                                          pv_kaart_id = p.id
                                                      AND liik = 2
                                                      AND kpv < l_kpv1
                                                ), 0) + p.algkulum AS alg_kulum,
                                       COALESCE((
                                                    SELECT
                                                        sum(summa)
                                                    FROM
                                                        docs.pv_oper po
                                                    WHERE
                                                          pv_kaart_id = p.id
                                                      AND liik = 2
                                                      AND kpv >= l_kpv1
                                                      AND kpv <= l_kpv2
                                                ), 0)              AS kulum,
                                       p.kulum                     AS kulum_percent,
                                       COALESCE((
                                                    SELECT
                                                        sum(summa)
                                                    FROM
                                                        docs.pv_oper po
                                                    WHERE
                                                          pv_kaart_id = p.id
                                                      AND liik = 3
                                                      AND kpv >= l_kpv1
                                                      AND kpv <= l_kpv2
                                                ), 0)              AS parandus,
                                       COALESCE((
                                                    SELECT
                                                        sum(summa)
                                                    FROM
                                                        docs.pv_oper po
                                                    WHERE
                                                          pv_kaart_id = p.id
                                                      AND liik = 4
                                                      AND kpv <= l_kpv2
                                                ),
                                                0)                 AS mahakantud,
                                       COALESCE((
                                                    SELECT
                                                        sum(summa)
                                                    FROM
                                                        docs.pv_oper po
                                                    WHERE
                                                          pv_kaart_id = p.id
                                                      AND liik = 5
                                                      AND kpv < l_kpv2
                                                ),
                                                0)                 AS umberhindamine,
                                       (
                                           SELECT
                                               sum(summa)
                                           FROM
                                               (
                                                   SELECT
                                                       summa
                                                   FROM
                                                       docs.pv_oper po
                                                   WHERE
                                                         pv_kaart_id = p.id
                                                     AND liik = 1
                                                   UNION ALL
                                                   SELECT
                                                       summa
                                                   FROM
                                                       docs.pv_oper po
                                                   WHERE
                                                         pv_kaart_id = p.id
                                                     AND liik = 3
                                                     AND kpv < l_kpv1
                                               ) qry
                                       )                           AS soetmaks,
                                       po.konto                    AS korr_konto,
                                       po.kood3                    AS rv
                                   FROM
                                       cur_pohivara                           p
                                           INNER JOIN umberklassifitseerimine u ON p.id = u.pv_kaart_id
                                           INNER JOIN libs.library            l ON l.id = p.id
                                           INNER JOIN docs.pv_oper            po ON po.id = u.id
                                   WHERE
                                         (p.mahakantud IS NULL OR p.mahakantud > l_kpv1)
                                     AND p.rekvid IN (
                                                         SELECT
                                                             rekv_id
                                                         FROM
                                                             rekv_ids
                                                     )
                               )

SELECT
    rekv_id,
    kood :: VARCHAR(20),
    qry.nimetus :: VARCHAR(254),
    konto :: VARCHAR(20),
    grupp :: VARCHAR(254),
    soetkpv,
    soetmaks,
    vastisikid,
    a.nimetus::TEXT                                                    AS vastisik,
    alg_kulum,
    kulum,
    kulum_percent,
    parandus,
    mahakantud,
    CASE WHEN coalesce(mahakantud, 0) <> 0 THEN 0 ELSE 1 END * (CASE
                                                                    WHEN umberhindamine > 0
                                                                        THEN umberhindamine
                                                                    ELSE soetmaks END + parandus - alg_kulum -
                                                                kulum) AS jaak,
    gruppid
FROM
    (
        SELECT
            p.rekvid                                                AS rekv_id,
            p.kood,
            p.nimetus,
            p.grupp,
            p.gruppid,
            coalesce(l.properties::JSONB ->> 'korr_konto', p.konto) AS konto,
            p.soetkpv,
            p.vastisikid,
            coalesce((
                         SELECT
                             sum(summa)
                         FROM
                             docs.pv_oper po
                         WHERE
                               pv_kaart_id = p.id
                           AND liik = 2
                           AND kpv < l_kpv1
                     ), 0) + p.algkulum                             AS alg_kulum,
            coalesce((
                         SELECT
                             sum(summa)
                         FROM
                             docs.pv_oper po
                         WHERE
                               pv_kaart_id = p.id
                           AND liik = 2
                           and coalesce(po.kood3, '') <> '12'
                           AND kpv >= l_kpv1
                           AND kpv <= l_kpv2
                     ), 0)                                          AS kulum,
            p.kulum                                                 AS kulum_percent,
            coalesce((
                         SELECT
                             sum(summa)
                         FROM
                             docs.pv_oper po
                         WHERE
                               pv_kaart_id = p.id
                           AND liik = 3
                           and coalesce(po.kood3, '') <> '12'
                           AND kpv >= l_kpv1
                           AND kpv <= l_kpv2
                     ), 0)                                          AS parandus,
            coalesce((
                         with
                             opers as (
                                          SELECT
                                              (summa)
                                          FROM
                                              docs.pv_oper po
                                          WHERE
                                                pv_kaart_id = p.id
                                            AND liik = 4
                                            AND kpv <= l_kpv2
                                          union all
                                          SELECT
                                              -1 * (summa)
                                          FROM
                                              docs.pv_oper po
                                          WHERE
                                                pv_kaart_id = p.id
                                            AND liik = 2
                                            and coalesce(po.kood3, '') = '12'
                                            AND kpv <= l_kpv2

                             )
                         SELECT
                             sum(summa)
                         FROM
                             opers
                     ),
                     0)                                             AS mahakantud,
            coalesce((
                         SELECT
                             sum(summa)
                         FROM
                             docs.pv_oper po
                         WHERE
                               pv_kaart_id = p.id
                           AND liik = 5
                           AND kpv < l_kpv2
                     ),
                     0)                                             AS umberhindamine,
            (
                SELECT
                    sum(summa)
                FROM
                    (
                        SELECT
                            summa
                        FROM
                            docs.pv_oper po
                        WHERE
                              pv_kaart_id = p.id
                          AND liik = 1
                        UNION ALL
                        SELECT
                            summa
                        FROM
                            docs.pv_oper po
                        WHERE
                              pv_kaart_id = p.id
                          AND liik = 3
                          AND kpv < l_kpv1
                    ) qry
            )
                                                                    AS soetmaks
        FROM
            cur_pohivara                p
                INNER JOIN libs.library l ON l.id = p.id
        WHERE
            (p.mahakantud IS NULL OR p.mahakantud > l_kpv1)
          AND p.rekvid IN (
                              SELECT
                                  rekv_id
                              FROM
                                  rekv_ids
                          )
          AND p.id NOT IN (
                              SELECT
                                  pv_kaart_id
                              FROM
                                  umberklassifitseerimine u
                          ) -- основной отчет, без переквалификации

        UNION ALL
        SELECT
            p.rekv_id
                ,
            p.kood
                ,
            p.nimetus
                ,
            p.grupp
                ,
            p.gruppid
                ,
            coalesce(p.eelmise_konto, p.konto)                                    AS konto
                ,
            p.soetkpv
                ,
            p.vastisikid
                ,
            p.alg_kulum
                ,
            p.kulum
                ,
            p.kulum_percent
                ,
            p.parandus
                ,
            CASE WHEN p.mahakantud = 0 AND p.rv = '13' THEN p.soetmaks ELSE 0 END AS mahakantud
                , -- если не списано но передано в инвестиции
            p.umberhindamine
                ,
            p.soetmaks
        FROM
            uusPv p
        UNION ALL
        SELECT
            p.rekv_id
                ,
            p.kood
                ,
            p.nimetus
                ,
            p.grupp
                ,
            p.gruppid
                ,
            p.korr_konto
                ,
            p.soetkpv
                ,
            p.vastisikid
                ,
            p.alg_kulum
                ,
            p.kulum
                ,
            p.kulum_percent
                ,
            p.parandus
                ,
            p.mahakantud
                , -- если не списано но передано в инвестиции
            p.umberhindamine
                ,
            p.soetmaks
        FROM
            uusPv p
        WHERE
            p.rv <> '14' -- не дублируем, если был возврат
    )                               qry
        LEFT OUTER JOIN libs.asutus a
                        ON a.id = qry.vastisikid
WHERE
    qry.soetkpv <= l_kpv2
    ;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.varadearuanne( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.varadearuanne( DATE, DATE, INTEGER, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.varadearuanne( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;


/*
SELECT sum(soetmaks) over(), *
FROM docs.varadearuanne('2022-01-01', '2022-01-31' :: DATE, 119, 1)
where kood like 'HOONE180%'
*/


