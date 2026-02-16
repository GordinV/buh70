DROP FUNCTION IF EXISTS docs.pv_rv_kaibe_aruanne(DATE, DATE, INTEGER, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.pv_rv_kaibe_aruanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
                                                    l_kond INTEGER DEFAULT NULL, l_params JSONB DEFAULT NULL::JSONB)
    RETURNS TABLE
            (
                selg          text,
                kood          VARCHAR(20),
                nimetus       VARCHAR(254),
                konto         VARCHAR(20),
                grupp         VARCHAR(254),

                esimise_kpv   DATE,
                alg_soetmaks  NUMERIC(12, 2),
                alg_kulum     NUMERIC(12, 2),
                -- pv osa
                kb_pv_rv01    NUMERIC(12, 2), -- Soetused ja parendused
                kb_pv_rv19    NUMERIC(12, 2), -- Saadud mitterahaline sihtfinantseerimine
                kb_pv_rv14    NUMERIC(12, 2), -- Üleviimine kinnisvarainvesteeringute grupist materiaalse põhivara gruppi
                kb_pv_rv13    NUMERIC(12, 2), -- Üleviimine materiaalse põhivara grupist kinnisvarainvesteeringute gruppi
                kb_pv_rv15    NUMERIC(12, 2), -- Varade mitterahalised siirded (üleandmine)
                kb_pv_rv16    NUMERIC(12, 2), -- Varade mitterahalised siirded (saamine)
                kb_pv_rv23    NUMERIC(12, 2), -- Ümberklassifitseerimine
                kb_pv_rv17    NUMERIC(12, 2), -- Varade üleandmine mitterahalise sissemaksena netovarasse
                kb_pv_rv24    NUMERIC(12, 2), -- Mitterahaline sihtfinantseerimine (üleandmine)
                kb_pv_rv29    NUMERIC(12, 2), -- Muud mitterahalised kanded varadega
                kb_pv_rv21    NUMERIC(12, 2), -- Varade ümberhindlus
                kb_pv_rv02    NUMERIC(12, 2), -- Müüdud põhivara
                kb_pv_rv12    NUMERIC(12, 2), -- Varade mahakandmine

                lopp_soetmaks NUMERIC(12, 2), -- Soetusmaksumus perioodi lõpus
                -- kulum osa
                kb_kulum_rv11 NUMERIC(12, 2), -- Varade kulum ja allahindlus
                kb_kulum_rv02 NUMERIC(12, 2), -- Müüdud põhivara
                kb_kulum_rv12 NUMERIC(12, 2), -- Varade mahakandmine
                kb_kulum_rv14 NUMERIC(12, 2), -- Üleviimine kinnisvarainvesteeringute grupist materiaalse põhivara gruppi
                kb_kulum_rv13 NUMERIC(12, 2), -- Üleviimine materiaalse põhivara grupist kinnisvarainvesteeringute gruppi
                kb_kulum_rv15 NUMERIC(12, 2), -- Varade mitterahalised siirded (üleandmine)
                kb_kulum_rv16 NUMERIC(12, 2), -- Varade mitterahalised siirded (saamine)
                kb_kulum_rv17 NUMERIC(12, 2), -- Varade üleandmine mitterahalise sissemaksena netovarasse
                kb_kulum_rv23 NUMERIC(12, 2), -- Mitterahaline sihtfinantseerimine (üleandmine)
                kb_kulum_rv24 NUMERIC(12, 2), -- Mitterahaline sihtfinantseerimine (üleandmine)
                kb_kulum_rv29 NUMERIC(12, 2), -- Muud mitterahalised kanded varadega

                lopp_kulum    NUMERIC(12, 2),
                vastisik      VARCHAR(254),
                asutus        VARCHAR(254)
            )
AS
$BODY$
WITH
    params AS (
                  SELECT
                      l_kpv1                                          AS kpv1,
                      l_kpv2                                          AS kpv2,
                      l_rekvid                                        as rekvid,
                      coalesce(l_params::jsonb ->> 'kood', '') || '%' AS kood
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
    pv_kaardid AS (
                  SELECT
                      l.id                                                                             AS pv_kaart_id,
                      l.rekvid,
                      (
                          SELECT
                              soetmaks
                          FROM
                              libs.get_pv_kaart_jaak(l.id, params.kpv1)
                      )                                                                                AS alg_soetmaks,
                      coalesce((
                                   SELECT
                                       kulum
                                   FROM
                                       libs.get_pv_kaart_jaak(l.id, params.kpv1)
                               ),
                               0)                                                                      AS alg_kulum,
                      CASE
                          WHEN l.status = 2 THEN 0
                          ELSE (
                                   SELECT
                                       soetmaks
                                   FROM
                                       libs.get_pv_kaart_jaak(l.id, params.kpv2 + 1)
                          ) END                                                                        AS lopp_soetmaks,
                      CASE
                          WHEN l.status = 2 THEN 0
                          ELSE (
                                   SELECT
                                       kulum
                                   FROM
                                       libs.get_pv_kaart_jaak(l.id, params.kpv2 + 1)
                          ) END                                                                        AS lopp_kulum,
                      l.kood::VARCHAR(20),
                      l.nimetus::VARCHAR(254),
                      coalesce((l.properties::JSONB ->> 'pindala')::NUMERIC(12, 4), 0)::NUMERIC(12, 4) AS pindala,
                      (l.properties::JSONB ->> 'kulum')::NUMERIC(12, 2)                                AS kulumi_maar,
                      (l.properties::JSONB ->> 'soetkpv'):: DATE                                       AS esimise_kpv,
                      (l.properties::jsonb ->> 'mahakantud')::date                                     as mahakandmise_kpv,
                      (l.properties :: JSONB ->> 'konto')::VARCHAR(20)                                 AS konto,
--                      libs.get_pv_kaart_konto(l.id, params.kpv1::date)::varchar(20)                    AS konto,
                      l.properties :: JSONB -> 'vastisikid'                                            AS vastisik_id,
                      grupp.nimetus::VARCHAR(254)                                                      AS grupp,
                      (l.properties :: JSONB ->> 'algkulum')::numeric(12, 2)                           as pv_alg_kulum,
                      grupp.properties::jsonb ->> 'kulum_konto'                                        as kulum_konto
                  FROM
                      libs.library          l
                          JOIN libs.library grupp
                               ON (l.properties :: JSONB -> 'gruppid') = to_jsonb(grupp.id),
                                            params
                  WHERE
                        l.library = 'POHIVARA'
                    AND l.status <> 3
                    AND l.rekvid IN (
                                        SELECT
                                            rekv_id
                                        FROM
                                            rekv_ids
                                    )
                    AND (
                            (
                                l.properties :: JSONB ->> 'mahakantud')::DATE IS NULL
                                OR
                            (
                                l.properties :: JSONB ->> 'mahakantud')::DATE >= params.kpv1)
                    AND (
                            l.properties :: JSONB ->> 'soetkpv') :: DATE <= params.kpv2
                    AND (
                            params.kood IS NULL
                                OR l.kood ILIKE coalesce(
                                                        params.kood
                                                    , '') || '%')
                        -- убрать малоценку
                    and not empty(coalesce(l.properties :: JSONB ->> 'konto', ''))

              ),
    po AS (
                  SELECT *
                  FROM
                      docs.pv_oper pv,
                                   params
                  WHERE
                        pv_kaart_id IN (
                                           SELECT
                                               pv_kaart_id
                                           FROM
                                               pv_kaardid
                                       )
                    AND kpv >= params.kpv1
                    AND kpv <= params.kpv2
              ),
    po_rv11 AS (
                  SELECT
                      po.pv_kaart_id                AS pv_kaart_id,
                      sum(po.summa)::NUMERIC(12, 2) AS kb_kulum_rv11
                  FROM
                      po,
                      params p
                  WHERE
                        po.liik = 2
                    and po.kpv >= p.kpv1
                    and po.kpv <= p.kpv2
                    and po.rekvid in (
                                         select
                                             rekv_id
                                         from
                                             rekv_ids
                                     )
                    AND (coalesce(po.kood3, '11') = '11' OR empty(po.kood3))
                  GROUP BY pv_kaart_id
              ),
    po_kulum_rv24 AS (
                  SELECT
                      po.pv_kaart_id                AS pv_kaart_id,
                      sum(po.summa)::NUMERIC(12, 2) AS kb_kulum_rv24
                  FROM
                      po,
                      params p
                  WHERE
                        po.liik = 2
                    and po.kpv >= p.kpv1
                    and po.kpv <= p.kpv2
                    and po.rekvid in (
                                         select
                                             rekv_id
                                         from
                                             rekv_ids
                                     )
                    AND (coalesce(po.kood3, '11') in ('24'))
                  GROUP BY pv_kaart_id
              ),
    po_kulum_rv12 AS (
                  SELECT
                      po.pv_kaart_id                AS pv_kaart_id,
                      sum(po.summa)::NUMERIC(12, 2) AS kb_kulum_rv12
                  FROM
                      po,
                      params p
                  WHERE
                        po.liik = 2
                    and po.kpv >= p.kpv1
                    and po.kpv <= p.kpv2
                    and po.rekvid in (
                                         select
                                             rekv_id
                                         from
                                             rekv_ids
                                     )
                    AND (coalesce(po.kood3, '11') in ('12'))
                  GROUP BY pv_kaart_id
              ),

    po_rv15 AS (
                  SELECT
                      po.pv_kaart_id                AS pv_kaart_id,
                      sum(po.summa)::NUMERIC(12, 2) AS kb_kulum_rv15
                  FROM
                      po,
                      params p
                  WHERE
                        po.liik = 2
                    and po.kpv >= p.kpv1
                    and po.kpv <= p.kpv2
                    and po.rekvid in (
                                         select
                                             rekv_id
                                         from
                                             rekv_ids
                                     )
                    AND coalesce(po.kood3, '11') = '15'
                  GROUP BY pv_kaart_id
              ),

    -- вытащим операции по потокам
    rv_po as (
                  select
                      count(*) over (partition by pv_kaart_id order by kpv) as order,
                      po.*
                  from
                      po
                  where
                      po.kood3 in ('13', '14', '16')
              ),
    -- обороты по потокам
    qryKaibed AS (
                  SELECT
                      l.pv_kaart_id     AS pv_kaart_id,
                      p.kpv1            as kpv,
                      l.alg_soetmaks    AS alg_soetmaks,
                      l.alg_kulum       AS alg_kulum,
                      0::NUMERIC(12, 2) AS kb_pv_rv01,
                      0::NUMERIC(12, 2) AS kb_pv_rv02,
                      0::NUMERIC(12, 2) AS kb_kulum_rv02,
                      0::NUMERIC(12, 2) AS kb_kulum_rv11,
                      0::NUMERIC(12, 2) AS kb_pv_rv12,
                      0::NUMERIC(12, 2) AS kb_kulum_rv12,
                      0::NUMERIC(12, 2) AS kb_pv_rv13,
                      0::NUMERIC(12, 2) AS kb_kulum_rv13,
                      0::NUMERIC(12, 2) AS kb_pv_rv14,
                      0::NUMERIC(12, 2) AS kb_kulum_rv14,
                      0::NUMERIC(12, 2) AS kb_pv_rv15,
                      0::NUMERIC(12, 2) AS kb_kulum_rv15,
                      0::NUMERIC(12, 2) AS kb_pv_rv16,
                      0::NUMERIC(12, 2) AS kb_kulum_rv16,
                      0::NUMERIC(12, 2) AS kb_pv_rv17,
                      0::NUMERIC(12, 2) AS kb_kulum_rv17,
                      0::NUMERIC(12, 2) AS kb_pv_rv19,
                      0::NUMERIC(12, 2) AS kb_pv_rv21,
                      0::NUMERIC(12, 2) AS kb_pv_rv23,
                      0::NUMERIC(12, 2) AS kb_kulum_rv23,
                      0::NUMERIC(12, 2) AS kb_pv_rv24,
                      0::NUMERIC(12, 2) AS kb_kulum_rv24,
                      0::NUMERIC(12, 2) AS kb_pv_rv29,
                      0::NUMERIC(12, 2) AS kb_kulum_rv29,
                      l.lopp_soetmaks,
                      l.lopp_kulum

                  FROM
                      pv_kaardid l,
                      params     p
                  UNION ALL
                  -- rv01
                  SELECT
                      po.pv_kaart_id                AS pv_kaart_id,
                      max(po.kpv)                   as kpv,
                      0:: NUMERIC(12, 2)            AS alg_soetmaks,
                      0:: NUMERIC(12, 2)            AS alg_kulum,
                      sum(po.summa)::NUMERIC(12, 2) AS kb_pv_rv01,
                      0::NUMERIC(12, 2)             AS kb_pv_rv02,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)             AS kb_pv_rv12,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)             AS kb_pv_rv13,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)             AS kb_pv_rv14,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv14,
                      0::NUMERIC(12, 2)             AS kb_pv_rv15,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)             AS kb_pv_rv16,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)             AS kb_pv_rv17,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)             AS kb_pv_rv19,
                      0::NUMERIC(12, 2)             AS kb_pv_rv21,
                      0::NUMERIC(12, 2)             AS kb_pv_rv23,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv23,
                      0::NUMERIC(12, 2)             AS kb_pv_rv24,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)             AS kb_pv_rv29,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv29,
                      0                             as lopp_soetmaks,
                      0                             as lopp_kulum

                  FROM
                      po,
                      params p
                  WHERE
                        po.liik in (1, 3)
                    and po.kpv >= p.kpv1
                    and po.kpv <= p.kpv2
                    AND coalesce(po.kood3, '01') in ('01', '')
                  group by po.pv_kaart_id
                  UNION ALL
                  -- rv02
                  SELECT
                      po.pv_kaart_id                                                AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)                                            AS alg_soetmaks,
                      0:: NUMERIC(12, 2)                                            AS alg_kulum,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv01,
                      po.summa::NUMERIC(12, 2)                                      AS kb_pv_rv02,
                      (pk.alg_kulum + coalesce(k.kb_kulum_rv11, 0))::NUMERIC(12, 2) AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)                                             AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv12,
                      0::NUMERIC(12, 2)                                             AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv13,
                      0::NUMERIC(12, 2)                                             AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv14,
                      0::NUMERIC(12, 2)                                             AS kb_kulum_rv14,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv15,
                      0::NUMERIC(12, 2)                                             AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv16,
                      0::NUMERIC(12, 2)                                             AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv17,
                      0::NUMERIC(12, 2)                                             AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv19,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv21,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv23,
                      0::NUMERIC(12, 2)                                             AS kb_kulum_rv23,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv24,
                      0::NUMERIC(12, 2)                                             AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv29,
                      0::NUMERIC(12, 2)                                             AS kb_kulum_rv29,
                      0                                                             as lopp_soetmaks,
                      0                                                             as lopp_kulum

                  FROM
                      params                         p,
                      po
                          INNER JOIN      pv_kaardid pk ON pk.pv_kaart_id = po.pv_kaart_id
                          LEFT OUTER JOIN po_rv11    k ON k.pv_kaart_id = pk.pv_kaart_id
                  WHERE
                        po.liik = 4
                    AND coalesce(po.kood3, '') = '02'
                    and po.kpv >= p.kpv1
                    and po.kpv <= p.kpv2

                  UNION ALL
                  -- rv11
                  SELECT
                      po.pv_kaart_id           AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)       AS alg_soetmaks,
                      0:: NUMERIC(12, 2)       AS alg_kulum,
                      0::NUMERIC(12, 2)        AS kb_pv_rv01,
                      0::NUMERIC(12, 2)        AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)       AS kb_kulum_rv02,
                      po.summa::NUMERIC(12, 2) AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)        AS kb_pv_rv12,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)        AS kb_pv_rv13,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)        AS kb_pv_rv14,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv14,
                      0::NUMERIC(12, 2)        AS kb_pv_rv15,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)        AS kb_pv_rv16,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)        AS kb_pv_rv17,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)        AS kb_pv_rv19,
                      0::NUMERIC(12, 2)        AS kb_pv_rv21,
                      0::NUMERIC(12, 2)        AS kb_pv_rv23,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv23,
                      0::NUMERIC(12, 2)        AS kb_pv_rv24,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)        AS kb_pv_rv29,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv29,
                      0                        as lopp_soetmaks,
                      0                        as lopp_kulum

                  FROM
                      params p,
                             po
                  WHERE
                        po.liik = 2
                    AND coalesce(po.kood3, '11') in ('11', '')
                    and po.kpv >= p.kpv1
                    and po.kpv <= p.kpv2
                  UNION ALL
                  -- rv12
                  SELECT
                      po.pv_kaart_id                                                     AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)                                                 AS alg_soetmaks,
                      0:: NUMERIC(12, 2)                                                 AS alg_kulum,
                      0::NUMERIC(12, 2)                                                  AS kb_pv_rv01,
                      0::NUMERIC(12, 2)                                                  AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)                                                 AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)                                                  AS kb_kulum_rv11,
                      -1 * po.summa::NUMERIC(12, 2)                                      AS kb_pv_rv12,
                      -1 * (pk.alg_kulum + coalesce(k.kb_kulum_rv11, 0))::NUMERIC(12, 2) AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)                                                  AS kb_pv_rv13,
                      0::NUMERIC(12, 2)                                                  AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)                                                  AS kb_pv_rv14,
                      0::NUMERIC(12, 2)                                                  AS kb_kulum_rv14,
                      0::NUMERIC(12, 2)                                                  AS kb_pv_rv15,
                      0::NUMERIC(12, 2)                                                  AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)                                                  AS kb_pv_rv16,
                      0::NUMERIC(12, 2)                                                  AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)                                                  AS kb_pv_rv17,
                      0::NUMERIC(12, 2)                                                  AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)                                                  AS kb_pv_rv19,
                      0::NUMERIC(12, 2)                                                  AS kb_pv_rv21,
                      0::NUMERIC(12, 2)                                                  AS kb_pv_rv23,
                      0::NUMERIC(12, 2)                                                  AS kb_kulum_rv23,
                      0::NUMERIC(12, 2)                                                  AS kb_pv_rv24,
                      0::NUMERIC(12, 2)                                                  AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)                                                  AS kb_pv_rv29,
                      0::NUMERIC(12, 2)                                                  AS kb_kulum_rv29,
                      0                                                                  as lopp_soetmaks,
                      0                                                                  as lopp_kulum

                  FROM
                      params                         p,
                      po
                          INNER JOIN      pv_kaardid pk ON pk.pv_kaart_id = po.pv_kaart_id
                          LEFT OUTER JOIN po_rv11    k ON k.pv_kaart_id = pk.pv_kaart_id
                  WHERE
                        po.liik = 4
                    AND coalesce(po.kood3, '') = '12'
                    and po.kpv >= p.kpv1
                    and po.kpv <= p.kpv2

                  UNION ALL
                  -- rv 12 paandus ja kumun (22.01.2023 kultuur)
                  SELECT
                      po.pv_kaart_id                                                           AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)                                                       AS alg_soetmaks,
                      0:: NUMERIC(12, 2)                                                       AS alg_kulum,
                      0::NUMERIC(12, 2)                                                        AS kb_pv_rv01,
                      0::NUMERIC(12, 2)                                                        AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)                                                       AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)                                                        AS kb_kulum_rv11,
                      CASE WHEN po.liik IN (1, 3) THEN 1 ELSE 0 END * po.summa::NUMERIC(12, 2) AS kb_pv_rv12,
                      CASE WHEN po.liik = 2 THEN 1 ELSE 0 END * po.summa::NUMERIC(12, 2)       AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)                                                        AS kb_pv_rv13,
                      0::NUMERIC(12, 2)                                                        AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)                                                        AS kb_pv_rv14,
                      0::NUMERIC(12, 2)                                                        AS kb_kulum_rv14,
                      0::NUMERIC(12, 2)                                                        AS kb_pv_rv15,
                      0::NUMERIC(12, 2)                                                        AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)                                                        AS kb_pv_rv16,
                      0::NUMERIC(12, 2)                                                        AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)                                                        AS kb_pv_rv17,
                      0::NUMERIC(12, 2)                                                        AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)                                                        AS kb_pv_rv19,
                      0::NUMERIC(12, 2)                                                        AS kb_pv_rv21,
                      0::NUMERIC(12, 2)                                                        AS kb_pv_rv23,
                      0::NUMERIC(12, 2)                                                        AS kb_kulum_rv23,
                      0::NUMERIC(12, 2)                                                        AS kb_pv_rv24,
                      0::NUMERIC(12, 2)                                                        AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)                                                        AS kb_pv_rv29,
                      0::NUMERIC(12, 2)                                                        AS kb_kulum_rv29,
                      0                                                                        as lopp_soetmaks,
                      0                                                                        as lopp_kulum

                  FROM
                      params                    p,
                      po
                          INNER JOIN pv_kaardid pk ON pk.pv_kaart_id = po.pv_kaart_id
                  WHERE
                        coalesce(po.kood3, '') = '12'
                    and po.kpv >= p.kpv1
                    and po.kpv <= p.kpv2
                    AND po.liik <> 4
--                    and po.pv_kaart_id not in (200934) -- убрать карточку из ваналинна


                  UNION ALL
                  -- rv15
                  SELECT
                      po.pv_kaart_id                                   AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)                               AS alg_soetmaks,
                      0:: NUMERIC(12, 2)                               AS alg_kulum,
                      0::NUMERIC(12, 2)                                AS kb_pv_rv01,
                      0::NUMERIC(12, 2)                                AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)                               AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)                                AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)                                AS kb_pv_rv12,
                      0::NUMERIC(12, 2)                                AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)                                AS kb_pv_rv13,
                      0::NUMERIC(12, 2)                                AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)                                AS kb_pv_rv14,
                      0::NUMERIC(12, 2)                                AS kb_kulum_rv14,
                      po.summa::NUMERIC(12, 2)                         AS kb_pv_rv15,
                      (pk.alg_kulum + coalesce(k.kb_kulum_rv11, 0) +
                       coalesce(k15.kb_kulum_rv15, 0))::NUMERIC(12, 2) AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)                                AS kb_pv_rv16,
                      0::NUMERIC(12, 2)                                AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)                                AS kb_pv_rv17,
                      0::NUMERIC(12, 2)                                AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)                                AS kb_pv_rv19,
                      0::NUMERIC(12, 2)                                AS kb_pv_rv21,
                      0::NUMERIC(12, 2)                                AS kb_pv_rv23,
                      0::NUMERIC(12, 2)                                AS kb_kulum_rv23,
                      0::NUMERIC(12, 2)                                AS kb_pv_rv24,
                      0::NUMERIC(12, 2)                                AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)                                AS kb_pv_rv29,
                      0::NUMERIC(12, 2)                                AS kb_kulum_rv29,
                      0                                                as lopp_soetmaks,
                      0                                                as lopp_kulum

                  FROM
                      params                         p,
                      po
                          INNER JOIN      pv_kaardid pk ON pk.pv_kaart_id = po.pv_kaart_id
                          LEFT OUTER JOIN po_rv11    k ON k.pv_kaart_id = pk.pv_kaart_id
                          LEFT OUTER JOIN po_rv15    k15 ON k15.pv_kaart_id = pk.pv_kaart_id

                  WHERE
                        po.liik = 4
                    AND coalesce(po.kood3, '') = '15'
                    and po.kpv >= p.kpv1
                    and po.kpv <= p.kpv2
                  UNION ALL
                  -- rv15 parendus
                  SELECT
                      po.pv_kaart_id                AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)            AS alg_soetmaks,
                      0:: NUMERIC(12, 2)            AS alg_kulum,
                      0::NUMERIC(12, 2)             AS kb_pv_rv01,
                      0::NUMERIC(12, 2)             AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)            AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)             AS kb_pv_rv12,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)             AS kb_pv_rv13,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)             AS kb_pv_rv14,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv14,
                      -1 * po.summa::NUMERIC(12, 2) AS kb_pv_rv15, --  с братным знаком так как у нас 15 поток уменьшает (списывает) сумму
                      0::NUMERIC(12, 2)             AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)             AS kb_pv_rv16,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)             AS kb_pv_rv17,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)             AS kb_pv_rv19,
                      0::NUMERIC(12, 2)             AS kb_pv_rv21,
                      0::NUMERIC(12, 2)             AS kb_pv_rv23,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv23,
                      0::NUMERIC(12, 2)             AS kb_pv_rv24,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)             AS kb_pv_rv29,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv29,
                      0                             as lopp_soetmaks,
                      0                             as lopp_kulum

                  FROM
                      params                    p,
                      po
                          INNER JOIN pv_kaardid pk
                                     ON pk.pv_kaart_id = po.pv_kaart_id
                  WHERE
                        po.liik in (1, 3)
                    AND COALESCE(po.kood3, '') = '15'
                    and po.kpv >= p.kpv1
                    and po.kpv <= p.kpv2
                  UNION ALL
                  -- rv15 kulum
                  SELECT
                      po.pv_kaart_id                AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)            AS alg_soetmaks,
                      0:: NUMERIC(12, 2)            AS alg_kulum,
                      0::NUMERIC(12, 2)             AS kb_pv_rv01,
                      0::NUMERIC(12, 2)             AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)            AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)             AS kb_pv_rv12,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)             AS kb_pv_rv13,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)             AS kb_pv_rv14,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv14,
                      0::NUMERIC(12, 2)             AS kb_pv_rv15,
                      -1 * po.summa::NUMERIC(12, 2) AS kb_kulum_rv15, --  с братным знаком так как у нас 15 поток уменьшает (списывает) сумму
                      0::NUMERIC(12, 2)             AS kb_pv_rv16,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)             AS kb_pv_rv17,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)             AS kb_pv_rv19,
                      0::NUMERIC(12, 2)             AS kb_pv_rv21,
                      0::NUMERIC(12, 2)             AS kb_pv_rv23,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv23,
                      0::NUMERIC(12, 2)             AS kb_pv_rv24,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)             AS kb_pv_rv29,
                      0::NUMERIC(12, 2)             AS kb_kulum_rv29,
                      0                             as lopp_soetmaks,
                      0                             as lopp_kulum
                  FROM
                      params                    p,
                      po
                          INNER JOIN pv_kaardid pk
                                     ON pk.pv_kaart_id = po.pv_kaart_id
                  WHERE
                        po.liik in (2)
                    AND COALESCE(po.kood3, '') = '15'
                    and po.kpv >= p.kpv1
                    and po.kpv <= p.kpv2

                  UNION ALL
                  -- rv17
                  SELECT
                      po.pv_kaart_id                                                          AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)                                                      AS alg_soetmaks,
                      0:: NUMERIC(12, 2)                                                      AS alg_kulum,
                      0::NUMERIC(12, 2)                                                       AS kb_pv_rv01,
                      0::NUMERIC(12, 2)                                                       AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)                                                      AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)                                                       AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)                                                       AS kb_pv_rv12,
                      0::NUMERIC(12, 2)                                                       AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)                                                       AS kb_pv_rv13,
                      0::NUMERIC(12, 2)                                                       AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)                                                       AS kb_pv_rv14,
                      0::NUMERIC(12, 2)                                                       AS kb_kulum_rv14,
                      0::NUMERIC(12, 2)                                                       AS kb_pv_rv15,
                      0::NUMERIC(12, 2)                                                       AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)                                                       AS kb_pv_rv16,
                      0::NUMERIC(12, 2)                                                       AS kb_kulum_rv16,
                      -- 23.10.2025 V.Nikitina
                      CASE WHEN po.liik = 4 THEN -1 ELSE 1 END * po.summa::NUMERIC(12, 2)     AS kb_pv_rv17,
                      CASE WHEN po.liik = 4 THEN -1 ELSE 1 END * pk.alg_kulum::NUMERIC(12, 2) AS kb_kulum_rv17,

--                      po.summa::NUMERIC(12, 2)     AS kb_pv_rv17,
--                      pk.alg_kulum::NUMERIC(12, 2) AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)                                                       AS kb_pv_rv19,
                      0::NUMERIC(12, 2)                                                       AS kb_pv_rv21,
                      0::NUMERIC(12, 2)                                                       AS kb_pv_rv23,
                      0::NUMERIC(12, 2)                                                       AS kb_kulum_rv23,
                      0::NUMERIC(12, 2)                                                       AS kb_pv_rv24,
                      0::NUMERIC(12, 2)                                                       AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)                                                       AS kb_pv_rv29,
                      0::NUMERIC(12, 2)                                                       AS kb_kulum_rv29,
                      0                                                                       as lopp_soetmaks,
                      0                                                                       as lopp_kulum

                  FROM
                      params                    p,
                      po
                          INNER JOIN pv_kaardid pk
                                     ON pk.pv_kaart_id = po.pv_kaart_id
                  WHERE
                        po.liik in (1, 4)
                    AND COALESCE(po.kood3, '') = '17'
                    and po.kpv >= p.kpv1
                    and po.kpv <= p.kpv2

                  UNION ALL
                  -- rv19
                  SELECT
                      po.pv_kaart_id           AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)       AS alg_soetmaks,
                      0:: NUMERIC(12, 2)       AS alg_kulum,
                      0::NUMERIC(12, 2)        AS kb_pv_rv01,
                      0::NUMERIC(12, 2)        AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)       AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)        AS kb_pv_rv12,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)        AS kb_pv_rv13,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)        AS kb_pv_rv14,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv14,
                      0::NUMERIC(12, 2)        AS kb_pv_rv15,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)        AS kb_pv_rv16,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)        AS kb_pv_rv17,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv17,
                      po.summa::NUMERIC(12, 2) AS kb_pv_rv19,
                      0::NUMERIC(12, 2)        AS kb_pv_rv21,
                      0::NUMERIC(12, 2)        AS kb_pv_rv23,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv23,
                      0::NUMERIC(12, 2)        AS kb_pv_rv24,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)        AS kb_pv_rv29,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv29,
                      0                        as lopp_soetmaks,
                      0                        as lopp_kulum

                  FROM
                      params p,
                             po
                  WHERE
                        po.liik IN (1, 3)
                    AND COALESCE(po.kood3, '') = '19'
                  UNION ALL
                  -- rv21
                  SELECT
                      po.pv_kaart_id           AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)       AS alg_soetmaks,
                      0:: NUMERIC(12, 2)       AS alg_kulum,
                      0::NUMERIC(12, 2)        AS kb_pv_rv01,
                      0::NUMERIC(12, 2)        AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)       AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)        AS kb_pv_rv12,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)        AS kb_pv_rv13,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)        AS kb_pv_rv14,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv14,
                      0::NUMERIC(12, 2)        AS kb_pv_rv15,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)        AS kb_pv_rv16,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)        AS kb_pv_rv17,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)        AS kb_pv_rv19,
                      po.summa::NUMERIC(12, 2) AS kb_pv_rv21,
                      0::NUMERIC(12, 2)        AS kb_pv_rv23,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv23,
                      0::NUMERIC(12, 2)        AS kb_pv_rv24,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)        AS kb_pv_rv29,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv29,
                      0                        as lopp_soetmaks,
                      0                        as lopp_kulum

                  FROM
                      po
                  WHERE
                        po.liik IN (1, 3)
                    AND COALESCE(po.kood3, '') = '21'
                  UNION ALL
                  -- rv23
                  SELECT
                      po.pv_kaart_id                                                      AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)                                                  AS alg_soetmaks,
                      0:: NUMERIC(12, 2)                                                  AS alg_kulum,
                      0::NUMERIC(12, 2)                                                   AS kb_pv_rv01,
                      0::NUMERIC(12, 2)                                                   AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)                                                  AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)                                                   AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)                                                   AS kb_pv_rv12,
                      0::NUMERIC(12, 2)                                                   AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)                                                   AS kb_pv_rv13,
                      0::NUMERIC(12, 2)                                                   AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)                                                   AS kb_pv_rv14,
                      0::NUMERIC(12, 2)                                                   AS kb_kulum_rv14,
                      0::NUMERIC(12, 2)                                                   AS kb_pv_rv15,
                      0::NUMERIC(12, 2)                                                   AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)                                                   AS kb_pv_rv16,
                      0::NUMERIC(12, 2)                                                   AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)                                                   AS kb_pv_rv17,
                      0::NUMERIC(12, 2)                                                   AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)                                                   AS kb_pv_rv19,
                      0::NUMERIC(12, 2)                                                   AS kb_pv_rv21,
                      CASE WHEN po.liik = 4 THEN -1 ELSE 1 END * po.summa::NUMERIC(12, 2) AS kb_pv_rv23,
                      -- спишем износ (только при списании) 23.10.2025
                      CASE WHEN po.liik = 4 THEN -1 else 0 end *
                      (pk.alg_kulum + coalesce(k.kb_kulum_rv11, 0))::NUMERIC(12, 2)       AS kb_kulum_rv23,
                      0::NUMERIC(12, 2)                                                   AS kb_pv_rv24,
                      0::NUMERIC(12, 2)                                                   AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)                                                   AS kb_pv_rv29,
                      0::NUMERIC(12, 2)                                                   AS kb_kulum_rv29,
                      0                                                                   as lopp_soetmaks,
                      0                                                                   as lopp_kulum

                  FROM
                      po
                          INNER JOIN      pv_kaardid pk
                                          ON pk.pv_kaart_id = po.pv_kaart_id
                          LEFT OUTER JOIN po_rv11    k ON k.pv_kaart_id = pk.pv_kaart_id
                  WHERE
                        po.liik IN (1, 3, 4) -- 22.01.2024 lisatud mahakandmine
                    AND COALESCE(po.kood3, '') = '23'
                  UNION ALL
                  -- rv24
                  SELECT
                      po.pv_kaart_id                                 AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)                             AS alg_soetmaks,
                      0:: NUMERIC(12, 2)                             AS alg_kulum,
                      0::NUMERIC(12, 2)                              AS kb_pv_rv01,
                      0::NUMERIC(12, 2)                              AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)                             AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)                              AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)                              AS kb_pv_rv12,
                      0::NUMERIC(12, 2)                              AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)                              AS kb_pv_rv13,
                      0::NUMERIC(12, 2)                              AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)                              AS kb_pv_rv14,
                      0::NUMERIC(12, 2)                              AS kb_kulum_rv14,
                      0::NUMERIC(12, 2)                              AS kb_pv_rv15,
                      0::NUMERIC(12, 2)                              AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)                              AS kb_pv_rv16,
                      0::NUMERIC(12, 2)                              AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)                              AS kb_pv_rv17,
                      0::NUMERIC(12, 2)                              AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)                              AS kb_pv_rv19,
                      0::NUMERIC(12, 2)                              AS kb_pv_rv21,
                      0::NUMERIC(12, 2)                              AS kb_pv_rv23,
                      0::NUMERIC(12, 2)                              AS kb_kulum_rv23,
                      po.summa::NUMERIC(12, 2)                       AS kb_pv_rv24,
--                      (pk.alg_kulum + coalesce(k.kb_kulum_rv11, 0)) ::NUMERIC(12, 2) AS kb_kulum_rv24,
                      coalesce(k24.kb_kulum_rv24, 0)::NUMERIC(12, 2) AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)                              AS kb_pv_rv29,
                      0::NUMERIC(12, 2)                              AS kb_kulum_rv29,
                      0                                              as lopp_soetmaks,
                      0                                              as lopp_kulum

                  FROM
                      po
                          INNER JOIN      pv_kaardid    pk
                                          ON pk.pv_kaart_id = po.pv_kaart_id
--                          LEFT OUTER JOIN po_rv11       k ON k.pv_kaart_id = pk.pv_kaart_id
                          LEFT OUTER JOIN po_kulum_rv24 k24 ON k24.pv_kaart_id = pk.pv_kaart_id

                  WHERE
                        po.liik = 4
                    AND COALESCE(po.kood3, '') = '24'
                  UNION ALL
                  -- rv29
                  SELECT
                      po.pv_kaart_id                                                                      AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)                                                                  AS alg_soetmaks,
                      0:: NUMERIC(12, 2)                                                                  AS alg_kulum,
                      0::NUMERIC(12, 2)                                                                   AS kb_pv_rv01,
                      0::NUMERIC(12, 2)                                                                   AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)                                                                  AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)                                                                   AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)                                                                   AS kb_pv_rv12,
                      0::NUMERIC(12, 2)                                                                   AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)                                                                   AS kb_pv_rv13,
                      0::NUMERIC(12, 2)                                                                   AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)                                                                   AS kb_pv_rv14,
                      0::NUMERIC(12, 2)                                                                   AS kb_kulum_rv14,
                      0::NUMERIC(12, 2)                                                                   AS kb_pv_rv15,
                      0::NUMERIC(12, 2)                                                                   AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)                                                                   AS kb_pv_rv16,
                      0::NUMERIC(12, 2)                                                                   AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)                                                                   AS kb_pv_rv17,
                      0::NUMERIC(12, 2)                                                                   AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)                                                                   AS kb_pv_rv19,
                      0::NUMERIC(12, 2)                                                                   AS kb_pv_rv21,
                      0::NUMERIC(12, 2)                                                                   AS kb_pv_rv23,
                      0::NUMERIC(12, 2)                                                                   AS kb_kulum_rv23,
                      0::NUMERIC(12, 2)                                                                   AS kb_pv_rv24,
                      0::NUMERIC(12, 2)                                                                   AS kb_kulum_rv24,
                      CASE WHEN po.liik = 1 THEN 1 ELSE -1 END * po.summa::NUMERIC(12, 2)                 AS kb_pv_rv29,
                      CASE
                          WHEN po.liik = 1 THEN pk.alg_kulum
                          ELSE -1 *
                               (
                                   (
                                       pk.alg_kulum + coalesce(
                                               k.kb_kulum_rv11,
                                               0))::NUMERIC(12, 2)) END ::NUMERIC(12, 2)                  AS kb_kulum_rv29,
                      0                                                                                   as lopp_soetmaks,
                      0                                                                                   as lopp_kulum

                  FROM
                      po
                          INNER JOIN      pv_kaardid pk
                                          ON pk.pv_kaart_id = po.pv_kaart_id
                          LEFT OUTER JOIN po_rv11    k ON k.pv_kaart_id = pk.pv_kaart_id

                  WHERE
                        po.liik IN (
                                    1, 4)
                    AND COALESCE(
                                po.kood3
                            , '') = '29'
              )
-- собираем отчет для карточек без переквалификации (RV13,14,16)
select
    (selg || 'Rv00:' || alg_soetmaks::text || 'Rv12:' || kb_pv_rv12::text || 'RV15:' || kb_pv_rv15::text) :: text,
    kood:: VARCHAR(20),
    nimetus:: VARCHAR(254),
    konto:: VARCHAR(20),
    grupp:: VARCHAR(254),

    esimise_kpv:: DATE,
    alg_soetmaks:: NUMERIC(12, 2),
    alg_kulum:: NUMERIC(12, 2),
    -- pv osa
    kb_pv_rv01:: NUMERIC(12, 2),                                                -- Soetused ja parendused
    kb_pv_rv19:: NUMERIC(12, 2),                                                -- Saadud mitterahaline sihtfinantseerimine
    kb_pv_rv14:: NUMERIC(12, 2),                                                -- Üleviimine kinnisvarainvesteeringute grupist materiaalse põhivara gruppi
    kb_pv_rv13:: NUMERIC(12, 2),                                                -- Üleviimine materiaalse põhivara grupist kinnisvarainvesteeringute gruppi
    kb_pv_rv15:: NUMERIC(12, 2),                                                -- Varade mitterahalised siirded (üleandmine)
    kb_pv_rv16:: NUMERIC(12, 2),                                                -- Varade mitterahalised siirded (saamine)
    kb_pv_rv23:: NUMERIC(12, 2),                                                -- Ümberklassifitseerimine
    kb_pv_rv17:: NUMERIC(12, 2),                                                -- Varade üleandmine mitterahalise sissemaksena netovarasse
    kb_pv_rv24:: NUMERIC(12, 2),                                                -- Mitterahaline sihtfinantseerimine (üleandmine)
    kb_pv_rv29:: NUMERIC(12, 2),                                                -- Muud mitterahalised kanded varadega
    kb_pv_rv21:: NUMERIC(12, 2),                                                -- Varade ümberhindlus
    kb_pv_rv02:: NUMERIC(12, 2),                                                -- Müüdud põhivara
    kb_pv_rv12:: NUMERIC(12, 2),                                                -- Varade mahakandmine

    (alg_soetmaks + kb_pv_rv01 - kb_pv_rv02 + kb_pv_rv12 + kb_pv_rv13 + kb_pv_rv14 + kb_pv_rv16 + kb_pv_rv19 +
     kb_pv_rv23 - kb_pv_rv15 + kb_pv_rv29 -
     kb_pv_rv24 + kb_pv_rv21 +  kb_pv_rv17):: NUMERIC(12, 2) as lopp_soetmaks, -- Soetusmaksumus perioodi lõpus
    -- kulum osa
    kb_kulum_rv11:: NUMERIC(12, 2),                                             -- Varade kulum ja allahindlus
    kb_kulum_rv02:: NUMERIC(12, 2),                                             -- Müüdud põhivara
    kb_kulum_rv12:: NUMERIC(12, 2),                                             -- Varade mahakandmine
    kb_kulum_rv14:: NUMERIC(12, 2),                                             -- Üleviimine kinnisvarainvesteeringute grupist materiaalse põhivara gruppi
    kb_kulum_rv13:: NUMERIC(12, 2),                                             -- Üleviimine materiaalse põhivara grupist kinnisvarainvesteeringute gruppi
    kb_kulum_rv15:: NUMERIC(12, 2),                                             -- Varade mitterahalised siirded (üleandmine)
    kb_kulum_rv16:: NUMERIC(12, 2),                                             -- Varade mitterahalised siirded (saamine)
    kb_kulum_rv17:: NUMERIC(12, 2),                                             -- Varade üleandmine mitterahalise sissemaksena netovarasse
    kb_kulum_rv23:: NUMERIC(12, 2),
    kb_kulum_rv24:: NUMERIC(12, 2),                                             -- Mitterahaline sihtfinantseerimine (üleandmine)
    kb_kulum_rv29:: NUMERIC(12, 2),                                             -- Muud mitterahalised kanded varadega

    (alg_kulum - kb_kulum_rv02 + kb_kulum_rv11 + kb_kulum_rv12 + kb_kulum_rv13 + kb_kulum_rv14 +
     kb_kulum_rv16 - kb_kulum_rv15 + kb_kulum_rv29 + kb_kulum_rv24 + kb_kulum_rv17 +
     kb_kulum_rv23):: NUMERIC(12, 2)                          as lopp_kulum,
    vastisik:: VARCHAR(254),
    asutus:: VARCHAR(254)
from
    (
        SELECT
            ''                                             as selg,
            pk.kood::VARCHAR(20),
            pk.nimetus:: VARCHAR(254),
            libs.get_pv_kaart_konto(
                    pk.pv_kaart_id, p.kpv1)                as konto,
            pk.grupp::VARCHAR(254),
            pk.esimise_kpv:: DATE,
            kb.alg_soetmaks:: NUMERIC(12, 2),
            coalesce(kb.alg_kulum, 0):: NUMERIC(12, 2)     as alg_kulum,
            -- pv osa
            coalesce(kb.kb_pv_rv01, 0):: NUMERIC(12, 2)    as kb_pv_rv01,    -- Soetused ja parendused
            coalesce(kb.kb_pv_rv19, 0):: NUMERIC(12, 2)    as kb_pv_rv19,    -- Saadud mitterahaline sihtfinantseerimine
            coalesce(kb.kb_pv_rv14, 0):: NUMERIC(12, 2)    as kb_pv_rv14,    -- Üleviimine kinnisvarainvesteeringute grupist materiaalse põhivara gruppi
            coalesce(kb.kb_pv_rv13, 0):: NUMERIC(12, 2)    as kb_pv_rv13,    -- Üleviimine materiaalse põhivara grupist kinnisvarainvesteeringute gruppi
            coalesce(kb.kb_pv_rv15, 0):: NUMERIC(12, 2)    as kb_pv_rv15,    -- Varade mitterahalised siirded (üleandmine)
            coalesce(kb.kb_pv_rv16, 0):: NUMERIC(12, 2)    as kb_pv_rv16,    -- Varade mitterahalised siirded (saamine)
            coalesce(kb.kb_pv_rv23, 0):: NUMERIC(12, 2)    as kb_pv_rv23,    -- Ümberklassifitseerimine
            coalesce(kb.kb_pv_rv17, 0):: NUMERIC(12, 2)    as kb_pv_rv17,    -- Varade üleandmine mitterahalise sissemaksena netovarasse
            coalesce(kb.kb_pv_rv24, 0):: NUMERIC(12, 2)    as kb_pv_rv24,    -- Mitterahaline sihtfinantseerimine (üleandmine)
            coalesce(kb.kb_pv_rv29, 0):: NUMERIC(12, 2)    as kb_pv_rv29,    -- Muud mitterahalised kanded varadega
            coalesce(kb.kb_pv_rv21, 0):: NUMERIC(12, 2)    as kb_pv_rv21,    -- Varade ümberhindlus
            coalesce(kb.kb_pv_rv02, 0):: NUMERIC(12, 2)    as kb_pv_rv02,    -- Müüdud põhivara
            coalesce(kb.kb_pv_rv12, 0):: NUMERIC(12, 2)    as kb_pv_rv12,    -- Varade mahakandmine

            coalesce(kb.lopp_soetmaks, 0):: NUMERIC(12, 2) as lopp_soetmaks, -- Soetusmaksumus perioodi lõpus
            -- kulum osa
            coalesce(kb.kb_kulum_rv11, 0):: NUMERIC(12, 2) as kb_kulum_rv11, -- Varade kulum ja allahindlus
            coalesce(kb.kb_kulum_rv02, 0):: NUMERIC(12, 2) as kb_kulum_rv02, -- Müüdud põhivara
            coalesce(kb.kb_kulum_rv12, 0):: NUMERIC(12, 2) as kb_kulum_rv12, -- Varade mahakandmine
            coalesce(kb.kb_kulum_rv14, 0):: NUMERIC(12, 2) as kb_kulum_rv14, -- Üleviimine kinnisvarainvesteeringute grupist materiaalse põhivara gruppi
            coalesce(kb.kb_kulum_rv13, 0):: NUMERIC(12, 2) as kb_kulum_rv13, -- Üleviimine materiaalse põhivara grupist kinnisvarainvesteeringute gruppi
            coalesce(kb.kb_kulum_rv15, 0):: NUMERIC(12, 2) as kb_kulum_rv15, -- Varade mitterahalised siirded (üleandmine)
            coalesce(kb.kb_kulum_rv16, 0):: NUMERIC(12, 2) as kb_kulum_rv16, -- Varade mitterahalised siirded (saamine)
            coalesce(kb.kb_kulum_rv17, 0):: NUMERIC(12, 2) as kb_kulum_rv17, -- Varade üleandmine mitterahalise sissemaksena netovarasse
            coalesce(kb.kb_kulum_rv23, 0):: NUMERIC(12, 2) as kb_kulum_rv23,
            coalesce(kb.kb_kulum_rv24, 0):: NUMERIC(12, 2) as kb_kulum_rv24, -- Mitterahaline sihtfinantseerimine (üleandmine)
            coalesce(kb.kb_kulum_rv29, 0):: NUMERIC(12, 2) as kb_kulum_rv29, -- Muud mitterahalised kanded varadega
            coalesce(kb.lopp_kulum, 0) :: NUMERIC(12, 2)   as lopp_kulum,
            coalesce(a.nimetus, ''):: VARCHAR(254)         AS vastisik,
            r.nimetus:: VARCHAR(254)                       AS asutus

        FROM
            params                          p,
            pv_kaardid                      pk
                INNER JOIN      (
                                    with
                                        kb_rv00 as (
                                                       -- карточки нач.сальдо и обороты по прочим потокам
                                                       select
                                                           pv_kaart_id,
                                                           sum(alg_soetmaks)  AS alg_soetmaks,
                                                           sum(alg_kulum)     AS alg_kulum,
                                                           sum(kb_pv_rv01)    AS kb_pv_rv01,
                                                           sum(kb_pv_rv02)    AS kb_pv_rv02,
                                                           sum(kb_kulum_rv02) AS kb_kulum_rv02,
                                                           sum(kb_kulum_rv11) AS kb_kulum_rv11,
                                                           sum(kb_pv_rv12)    AS kb_pv_rv12,
                                                           sum(kb_kulum_rv12) AS kb_kulum_rv12,
                                                           0                  AS kb_pv_rv13,
                                                           0                  AS kb_kulum_rv13,
                                                           0                  AS kb_pv_rv14,
                                                           0                  AS kb_kulum_rv14,
                                                           sum(kb_pv_rv15)    AS kb_pv_rv15,
                                                           sum(kb_kulum_rv15) AS kb_kulum_rv15,
                                                           0                  AS kb_pv_rv16,
                                                           0                  AS kb_kulum_rv16,
                                                           sum(kb_pv_rv17)    AS kb_pv_rv17,
                                                           sum(kb_kulum_rv17) AS kb_kulum_rv17,
                                                           sum(kb_pv_rv19)    AS kb_pv_rv19,
                                                           sum(kb_pv_rv21)    AS kb_pv_rv21,
                                                           sum(kb_pv_rv23)    AS kb_pv_rv23,
                                                           sum(kb_kulum_rv23) AS kb_kulum_rv23,
                                                           sum(kb_pv_rv24)    AS kb_pv_rv24,
                                                           sum(kb_kulum_rv24) AS kb_kulum_rv24,
                                                           sum(kb_pv_rv29)    AS kb_pv_rv29,
                                                           sum(kb_kulum_rv29) AS kb_kulum_rv29,
                                                           max(lopp_soetmaks) as lopp_soetmaks,
                                                           max(lopp_kulum)    as lopp_kulum
                                                       from
                                                           qryKaibed kb

                                                       group by pv_kaart_id
                                        )

                                    -- суммируем обороты по потокам
                                    SELECT
                                        pv_kaart_id,
                                        sum(alg_soetmaks)     AS alg_soetmaks,
                                        sum(alg_kulum)        AS alg_kulum,
                                        sum(kb_pv_rv01)       AS kb_pv_rv01,
                                        sum(kb_pv_rv02)       AS kb_pv_rv02,
                                        sum(kb_kulum_rv02)    AS kb_kulum_rv02,
                                        sum(kb_kulum_rv11)    AS kb_kulum_rv11,
                                        sum(kb_pv_rv12)       AS kb_pv_rv12,
                                        sum(kb_kulum_rv12)    AS kb_kulum_rv12,
                                        sum(kb_pv_rv13)       AS kb_pv_rv13,
                                        sum(kb_kulum_rv13)    AS kb_kulum_rv13,
                                        sum(kb_pv_rv14)       AS kb_pv_rv14,
                                        sum(kb_kulum_rv14)    AS kb_kulum_rv14,
                                        sum(kb_pv_rv15)       AS kb_pv_rv15,
                                        sum(kb_kulum_rv15)    AS kb_kulum_rv15,
                                        sum(kb_pv_rv16)       AS kb_pv_rv16,
                                        sum(kb_kulum_rv16)    AS kb_kulum_rv16,
                                        sum(kb_pv_rv17)       AS kb_pv_rv17,
                                        sum(kb_kulum_rv17)    AS kb_kulum_rv17,
                                        sum(kb_pv_rv19)       AS kb_pv_rv19,
                                        sum(kb_pv_rv21)       AS kb_pv_rv21,
                                        sum(kb_pv_rv23)       AS kb_pv_rv23,
                                        sum(kb_kulum_rv23)    AS kb_kulum_rv23,
                                        sum(kb_pv_rv24)       AS kb_pv_rv24,
                                        sum(kb_kulum_rv24)    AS kb_kulum_rv24,
                                        sum(kb_pv_rv29)       AS kb_pv_rv29,
                                        sum(kb_kulum_rv29)    AS kb_kulum_rv29,
                                        sum(kb.lopp_soetmaks) as lopp_soetmaks,
                                        sum(kb.lopp_kulum)    as lopp_kulum
                                    FROM
                                        (
                                            -- Rv00
                                            select
                                                0                     as type,
                                                pv_kaart_id,
                                                (alg_soetmaks)        AS alg_soetmaks,
                                                (alg_kulum)           AS alg_kulum,
                                                (kb_pv_rv01)          AS kb_pv_rv01,
                                                kb_pv_rv02            AS kb_pv_rv02,
                                                kb_rv00.kb_kulum_rv02 AS kb_kulum_rv02,
                                                (kb_kulum_rv11)       AS kb_kulum_rv11,
                                                (kb_pv_rv12)          AS kb_pv_rv12,
                                                (kb_kulum_rv12)       AS kb_kulum_rv12,
                                                0                     AS kb_pv_rv13,
                                                0                     AS kb_kulum_rv13,
                                                0                     AS kb_pv_rv14,
                                                0                     AS kb_kulum_rv14,
                                                (kb_pv_rv15)          AS kb_pv_rv15,
                                                (kb_kulum_rv15)       AS kb_kulum_rv15,
                                                (kb_pv_rv16)          AS kb_pv_rv16,
                                                (kb_kulum_rv16)       AS kb_kulum_rv16,
                                                (kb_pv_rv17)          AS kb_pv_rv17,
                                                (kb_kulum_rv17)       AS kb_kulum_rv17,
                                                (kb_pv_rv19)          AS kb_pv_rv19,
                                                (kb_pv_rv21)          AS kb_pv_rv21,
                                                (kb_pv_rv23)          AS kb_pv_rv23,
                                                kb_kulum_rv23         as kb_kulum_rv23,
                                                (kb_pv_rv24)          AS kb_pv_rv24,
                                                (kb_kulum_rv24)       AS kb_kulum_rv24,
                                                (kb_pv_rv29)          AS kb_pv_rv29,
                                                (kb_kulum_rv29)       AS kb_kulum_rv29,
                                                lopp_soetmaks         as lopp_soetmaks,
                                                lopp_kulum            as lopp_kulum
                                            from
                                                kb_rv00,
                                                params p

                                            union all
                                            -- Rv29 (kulum)
                                            select
                                                0                                            as type,
                                                pv_kaart_id,
                                                0                                            AS alg_soetmaks,
                                                0                                            AS alg_kulum,
                                                0                                            AS kb_pv_rv01,
                                                0                                            AS kb_pv_rv02,
                                                0                                            AS kb_kulum_rv02,
                                                0                                            AS kb_kulum_rv11,
                                                0                                            AS kb_pv_rv12,
                                                0                                            AS kb_kulum_rv12,
                                                0                                            AS kb_pv_rv13,
                                                0                                            AS kb_kulum_rv13,
                                                0                                            AS kb_pv_rv14,
                                                0                                            AS kb_kulum_rv14,
                                                0                                            AS kb_pv_rv15,
                                                0                                            AS kb_kulum_rv15,
                                                0                                            AS kb_pv_rv16,
                                                0                                            AS kb_kulum_rv16,
                                                0                                            AS kb_pv_rv17,
                                                0                                            AS kb_kulum_rv17,
                                                0                                            AS kb_pv_rv19,
                                                0                                            AS kb_pv_rv21,
                                                0                                            AS kb_pv_rv23,
                                                0                                            as kb_kulum_rv23,
                                                0                                            AS kb_pv_rv24,
                                                0                                            AS kb_kulum_rv24,
                                                0                                            AS kb_pv_rv29,
                                                coalesce(pk.pV_alg_kulum, 0)::numeric(12, 2) AS kb_kulum_rv29,
                                                0                                            as lopp_soetmaks,
                                                0                                            as lopp_kulum
                                            from
                                                (
                                                    select *
                                                    from
                                                        pv_kaardid p
                                                    where
                                                        p.pv_kaart_id in (
                                                                             select
                                                                                 pv_kaart_id
                                                                             from
                                                                                 po
                                                                             where
                                                                                   po.kood3 = '29'
                                                                               and po.liik = 1
                                                                         )
                                                )      pk,
                                                params p
                                            union all
                                            -- Rv15 (kulum)
                                            select
                                                0                     as type,
                                                po.pv_kaart_id,
                                                0                     AS alg_soetmaks,
                                                0                     AS alg_kulum,
                                                0                     AS kb_pv_rv01,
                                                0                     AS kb_pv_rv02,
                                                0                     AS kb_kulum_rv02,
                                                0                     AS kb_kulum_rv11,
                                                0                     AS kb_pv_rv12,
                                                0                     AS kb_kulum_rv12,
                                                0                     AS kb_pv_rv13,
                                                0                     AS kb_kulum_rv13,
                                                0                     AS kb_pv_rv14,
                                                0                     AS kb_kulum_rv14,
                                                0                     AS kb_pv_rv15, -- корректируем на списание износа 12 потоком
                                                -1 * po.kb_kulum_rv12 AS kb_kulum_rv15,
                                                0                     AS kb_pv_rv16,
                                                0                     AS kb_kulum_rv16,
                                                0                     AS kb_pv_rv17,
                                                0                     AS kb_kulum_rv17,
                                                0                     AS kb_pv_rv19,
                                                0                     AS kb_pv_rv21,
                                                0                     AS kb_pv_rv23,
                                                0                     as kb_kulum_rv23,
                                                0                     AS kb_pv_rv24,
                                                0                     AS kb_kulum_rv24,
                                                0                     AS kb_pv_rv29,
                                                0::numeric(12, 2)     AS kb_kulum_rv29,
                                                0                     as lopp_soetmaks,
                                                0                     as lopp_kulum
                                            from
                                                (
                                                    select *
                                                    from
                                                        kb_rv00 kb
                                                    where
                                                          kb.kb_kulum_rv12 <> 0
                                                      and kb.pv_kaart_id in
                                                          (
                                                              select
                                                                  po.pv_kaart_id
                                                              from
                                                                  po
                                                              where
                                                                    po.kood3 = '15'
                                                                and po.liik = 4
                                                          )
                                                ) po
                                        ) kb
                                    group by pv_kaart_id
                                )           kb ON kb.pv_kaart_id = pk.pv_kaart_id
                INNER JOIN      ou.rekv     r ON r.id = pk.rekvid
                LEFT OUTER JOIN libs.asutus a ON pk.vastisik_id = to_jsonb(a.id)
        where
            pk.pv_kaart_id not in (
                                      select
                                          pv_kaart_id
                                      from
                                          rv_po
                                  )
        union all
-- rv 13, 14
        SELECT
            kb.selg,
            pk.kood::VARCHAR(20),
            pk.nimetus:: VARCHAR(254),
            kb.konto:: VARCHAR(20),
            pk.grupp::VARCHAR(254),
            pk.esimise_kpv:: DATE,
            kb.rv00_summa                               as alg_soetmaks,
            coalesce(kb.km00_summa, 0):: NUMERIC(12, 2) as alg_kulum,
            -- pv osa
            0:: NUMERIC(12, 2),                                           -- Soetused ja parendused
            coalesce(kb.rv19_summa, 0):: NUMERIC(12, 2),                  -- Saadud mitterahaline sihtfinantseerimine
            coalesce(kb.rv14_summa, 0):: NUMERIC(12, 2),                  -- Üleviimine kinnisvarainvesteeringute grupist materiaalse põhivara gruppi
            coalesce(kb.rv13_summa, 0):: NUMERIC(12, 2),                  -- Üleviimine materiaalse põhivara grupist kinnisvarainvesteeringute gruppi
            0:: NUMERIC(12, 2),                                           -- Varade mitterahalised siirded (üleandmine)
            coalesce(kb.rv16_summa, 0):: NUMERIC(12, 2),                  -- Varade mitterahalised siirded (saamine)
            kb.rv23_summa:: NUMERIC(12, 2),                               -- Ümberklassifitseerimine
            coalesce(kb.rv17_summa, 0):: NUMERIC(12, 2) as rv17_summa,    -- Varade üleandmine mitterahalise sissemaksena netovarasse
            0:: NUMERIC(12, 2),                                           -- Mitterahaline sihtfinantseerimine (üleandmine)
            kb.rv29_summa:: NUMERIC(12, 2),                               -- Muud mitterahalised kanded varadega
            0:: NUMERIC(12, 2),                                           -- Varade ümberhindlus
            coalesce(kb.rv02_summa, 0):: NUMERIC(12, 2),                  -- Müüdud põhivara
            coalesce(kb.rv12_summa, 0):: NUMERIC(12, 2),                  -- Varade mahakandmine

            coalesce(kb.rv_lopp_summa, 0):: NUMERIC(12, 2),               -- Soetusmaksumus perioodi lõpus
            -- kulum osa
            coalesce(kb.rv11_summa, 0):: NUMERIC(12, 2),                  -- Varade kulum ja allahindlus
            coalesce(kb.km02_summa, 0)::numeric(12, 2)  as kb_kulum_rv02, -- Müüdud põhivara
            coalesce(kb.km12_summa, 0):: NUMERIC(12, 2) as km12_summa,    -- Varade mahakandmine
            coalesce(kb.km14_summa, 0)::numeric(12, 2)  as kb_kulum_rv14, -- Üleviimine kinnisvarainvesteeringute grupist materiaalse põhivara gruppi
            coalesce(kb.km13_summa, 0)::numeric(12, 2)  as kb_kulum_rv13, -- Üleviimine materiaalse põhivara grupist kinnisvarainvesteeringute gruppi
            0:: NUMERIC(12, 2),                                           -- Varade mitterahalised siirded (üleandmine)
            coalesce(kb.km16_summa, 0)::numeric(12, 2)  as kb_kulum_rv16, -- Varade mitterahalised siirded (saamine)
            coalesce(kb.km17_summa, 0):: NUMERIC(12, 2) as kb_kulum_rv17, -- Varade üleandmine mitterahalise sissemaksena netovarasse
            coalesce(kb.km23_summa, 0):: NUMERIC(12, 2) as kb_kulum_rv23, -- Mitterahaline sihtfinantseerimine (üleandmine)
            0:: NUMERIC(12, 2)                          as kb_kulum_rv24,
            kb.km29_summa:: NUMERIC(12, 2),                               -- Muud mitterahalised kanded varadega
            case when kb.rv_lopp_summa <> 0 then pk.lopp_kulum else 0 end:: NUMERIC(12, 2),
            coalesce(a.nimetus, ''):: VARCHAR(254)      AS vastisik,
            r.nimetus:: VARCHAR(254)                    AS asutus

        FROM
            pv_kaardid                      pk
                INNER JOIN      (
                                    with
                                        po_rv13 as (
                                                       select
                                                           count(*) over (partition by pv_kaart_id order by kpv) as order,
                                                           po.*
                                                       from
                                                           params p,
                                                                  po
                                                       where
                                                           po.kood3 in ('13', '14', '16', '02', '19', '23')
                                                   ),
                                        rv11 as (
                                                       select
                                                           po.pv_kaart_id,
                                                           sum(po.kb_kulum_rv11) as summa,
                                                           '11'                  as rv
                                                       from
                                                           po_rv11 po,
                                                           params  p
                                                       where
                                                           po.pv_kaart_id in (
                                                                                 select
                                                                                     pv_kaart_id
                                                                                 from
                                                                                     po_rv13
                                                                             )
                                                       group by po.pv_kaart_id
                                                   ),
                                        rv00 as (
                                                       select
                                                           pv.pv_kaart_id,
                                                           '00'            as rv,
                                                           pv.alg_soetmaks as summa,
                                                           pv.alg_kulum    as kulum,
                                                           p.kpv1          as kpv,
                                                           0               as order
                                                       from
                                                           params     p,
                                                           pv_kaardid pv
                                                       where
                                                           pv_kaart_id in (
                                                                              select
                                                                                  pv_kaart_id
                                                                              from
                                                                                  po_rv13
                                                                          )
                                                   ),
-- rv13
                                        rv13 as (
                                                       select
                                                           po.pv_kaart_id,
                                                           po.summa,
                                                           po.kood3 as rv,
                                                           po.kpv,
                                                           po.order
                                                       from
                                                           po_rv13 po
                                                       where
                                                           kood3 = '13'
                                                   ),
                                        rv14 as (
                                                       select
                                                           po.pv_kaart_id,
                                                           po.summa,
                                                           po.kood3 as rv,
                                                           po.kpv,
                                                           po.order
                                                       from
                                                           po_rv13 po
                                                       where
                                                           kood3 = '14'
                                                   ),
                                        rv16 as (
                                                       select
                                                           po.pv_kaart_id,
                                                           sum(po.summa) as summa,
                                                           po.kood3      as rv,
                                                           max(po.kpv)   as kpv,
                                                           max(po.order) as order
                                                       from
                                                           po_rv13 po
                                                       where
                                                           kood3 = '16'
                                                       group by po.pv_kaart_id, po.kood3
                                                   ),
                                        rv19 as (
                                                       select
                                                           po.pv_kaart_id,
                                                           sum(po.summa) as summa,
                                                           po.kood3      as rv,
                                                           max(po.kpv)   as kpv,
                                                           max(po.order) as order
                                                       from
                                                           po_rv13 po
                                                       where
                                                           kood3 = '19'
                                                       group by po.pv_kaart_id, po.kood3
                                                   ),
                                        rv23 as (
                                                       select
                                                           po.pv_kaart_id,
                                                           sum(po.summa) as summa,
                                                           po.kood3      as rv,
                                                           max(po.kpv)   as kpv,
                                                           max(po.order) as order
                                                       from
                                                           po_rv13 po
                                                       where
                                                             po.liik = 6 --только переквалификации 23 потоком
                                                         and kood3 = '23'
                                                       group by po.pv_kaart_id, po.kood3
                                                   ),

                                        rv02 as (
                                                       select
                                                           pv_kaart_id,
                                                           summa,
                                                           po.kood3 as rv,
                                                           kpv,
                                                           po.order
                                                       from
                                                           po_rv13 po
                                                       where
                                                           kood3 = '02'
                                                   ),
                                        po_ as (
                                                       select
                                                           rv00.pv_kaart_id,
                                                           rv00.summa                                                              as rv00_summa,
                                                           rv00.kulum                                                              as km00_summa,
                                                           rv13.summa                                                              as rv13_summa,
                                                           rv11.summa                                                              as rv11_summa,
                                                           rv13.rv                                                                 as rv13_rv,
                                                           rv13.kpv                                                                as rv13_kpv,
                                                           coalesce(
                                                                   case
                                                                       when coalesce(rv02.order, 999) < rv13.order
                                                                           then rv02.rv
                                                                       when coalesce(rv14.order, 999) < rv13.order
                                                                           then rv14.rv
                                                                       when coalesce(rv23.order, 999) < rv13.order
                                                                           then rv23.rv
                                                                       end,
                                                                   '00')                                                           as rv13_prev_rv,
                                                           coalesce(case
                                                                        when coalesce(rv02.order, 999) < rv13.order
                                                                            then rv02.summa
                                                                        when coalesce(rv14.order, 999) < rv14.order
                                                                            then rv14.summa
                                                                        when coalesce(rv23.order, 999) < rv13.order
                                                                            then rv23.summa
                                                                        end,
                                                                    rv00.summa)                                                    as rv13_prev_summa,
                                                           rv14.summa                                                              as rv14_summa,
                                                           rv14.rv                                                                 as rv14_rv,
                                                           rv14.kpv                                                                as rv14_kpv,
                                                           coalesce(
                                                                   case
                                                                       when coalesce(rv00.order, 999) < rv14.order
                                                                           then rv00.rv
                                                                       when coalesce(rv02.order, 999) < rv14.order
                                                                           then rv02.rv
                                                                       when coalesce(rv13.order, 999) < rv14.order
                                                                           then rv13.rv
                                                                       when coalesce(rv19.order, 999) < rv14.order
                                                                           then rv19.rv
                                                                       when coalesce(rv23.order, 999) < rv14.order
                                                                           then rv23.rv
                                                                       end,
                                                                   '00')                                                           as rv14_prev_rv,
                                                           coalesce(case
                                                                        when coalesce(rv00.order, 999) < rv14.order
                                                                            then rv00.summa
                                                                        when coalesce(rv02.order, 999) < rv14.order
                                                                            then rv02.summa
                                                                        when coalesce(rv13.order, 999) < rv14.order
                                                                            then rv13.summa
                                                                        when coalesce(rv19.order, 999) < rv14.order
                                                                            then rv19.summa
                                                                        when coalesce(rv23.order, 999) < rv14.order
                                                                            then rv23.summa
                                                                        end,
                                                                    rv00.summa)                                                    as rv14_prev_summa,
                                                           rv02.summa                                                              as rv02_summa,
                                                           rv02.kpv                                                                as rv02_kpv,
                                                           case
                                                               when rv02.summa is not null then '13'
                                                               else null end::text                                                 as rv02_prev_rv,
                                                           case when rv02.summa is not null then rv13.summa else null end::numeric as rv02_prev_summa,
                                                           rv16.summa                                                              as rv16_summa,
                                                           rv16.rv                                                                 as rv16_rv,
                                                           rv16.kpv                                                                as rv16_kpv,
                                                           coalesce(
                                                                   case
                                                                       when coalesce(rv02.order, 999) < rv16.order
                                                                           then rv02.rv
                                                                       when coalesce(rv13.order, 999) < rv16.order
                                                                           then rv13.rv
                                                                       when coalesce(rv14.order, 999) < rv16.order
                                                                           then rv14.rv
                                                                       when coalesce(rv23.order, 999) < rv16.order
                                                                           then rv23.rv
                                                                       end,
                                                                   '00')                                                           as rv16_prev_rv,
                                                           coalesce(case
                                                                        when coalesce(rv02.order, 999) < rv16.order
                                                                            then rv02.summa
                                                                        when coalesce(rv13.order, 999) < rv16.order
                                                                            then rv13.summa
                                                                        when coalesce(rv14.order, 999) < rv16.order
                                                                            then rv13.summa
                                                                        when coalesce(rv23.order, 999) < rv16.order
                                                                            then rv23.summa
                                                                        end,
                                                                    0)                                                             as rv16_prev_summa,
                                                           rv23.summa                                                              as rv23_summa,
                                                           rv23.rv                                                                 as rv23_rv,
                                                           rv23.kpv                                                                as rv23_kpv,

                                                           coalesce(
                                                                   case
                                                                       when coalesce(rv02.order, 999) < rv23.order
                                                                           then rv02.rv
                                                                       when coalesce(rv13.order, 999) < rv23.order
                                                                           then rv13.rv
                                                                       when coalesce(rv14.order, 999) < rv23.order
                                                                           then rv14.rv
                                                                       when coalesce(rv16.order, 999) < rv23.order
                                                                           then rv16.rv
                                                                       end,
                                                                   '00')                                                           as rv23_prev_rv,
                                                           coalesce(case
                                                                        when coalesce(rv02.order, 999) < rv23.order
                                                                            then rv02.summa
                                                                        when coalesce(rv13.order, 999) < rv23.order
                                                                            then rv13.summa
                                                                        when coalesce(rv14.order, 999) < rv23.order
                                                                            then rv13.summa
                                                                        when coalesce(rv16.order, 999) < rv23.order
                                                                            then rv16.summa
                                                                        end,
                                                                    0)                                                             as rv23_prev_summa


                                                       from
                                                           rv00
                                                               left outer join rv02 on rv00.pv_kaart_id = rv02.pv_kaart_id
                                                               left outer join rv11 on rv00.pv_kaart_id = rv11.pv_kaart_id
                                                               left outer join rv13 on rv00.pv_kaart_id = rv13.pv_kaart_id
                                                               left outer join rv14 on rv00.pv_kaart_id = rv14.pv_kaart_id
                                                               left outer join rv16 on rv00.pv_kaart_id = rv16.pv_kaart_id
                                                               left outer join rv19 on rv00.pv_kaart_id = rv19.pv_kaart_id
                                                               left outer join rv23 on rv00.pv_kaart_id = rv23.pv_kaart_id
                                                   ),
                                        -- износ korrection
                                        po11_upd as (
                                                       select
                                                           sum(summa) over (partition by konto) as konto_summa,
                                                           po.pv_kaart_id,
                                                           libs.get_pv_kaart_konto(
                                                                   po.pv_kaart_id, po.kpv)      as konto,
                                                           po.kpv,
                                                           po.summa
                                                       from
                                                           docs.pv_oper po,
                                                           params       p
                                                       where
                                                             po.kpv >= p.kpv1
                                                         and po.kpv <= p.kpv2
                                                         and po.liik = 2
                                                         and po.kood3 = '11'
                                                         and po.pv_kaart_id in (
                                                                                   select
                                                                                       rv13.pv_kaart_id
                                                                                   from
                                                                                       rv13
                                                                                   union all
                                                                                   select
                                                                                       rv14.pv_kaart_id
                                                                                   from
                                                                                       rv14
                                                                                   union all
                                                                                   select
                                                                                       rv16.pv_kaart_id
                                                                                   from
                                                                                       rv16

                                                                               )
                                                   ),

                                        po11_korr as (
                                                       select
                                                           po.pv_kaart_id,
                                                           po.kpv,
                                                           po.summa
                                                       from
                                                           docs.pv_oper po,
                                                           params       p
                                                       where
                                                             po.kpv >= p.kpv1
                                                         and po.kpv <= p.kpv2
                                                         and po.liik = 2
                                                         and po.kood3 = '11'
                                                         and po.pv_kaart_id in (
                                                                                   select
                                                                                       rv13.pv_kaart_id
                                                                                   from
                                                                                       rv13
                                                                                   union all
                                                                                   select
                                                                                       rv14.pv_kaart_id
                                                                                   from
                                                                                       rv14

                                                                               )
                                                   ),
-- 00
                                        report as (
                                                       select
                                                           pv.kood,
                                                           rep.*
                                                       from
                                                           (
                                                               select
                                                                   po_.pv_kaart_id,
                                                                   libs.get_pv_kaart_konto(
                                                                           po_.pv_kaart_id, p.kpv1) as konto,
                                                                   '00' || rv14_summa::text         as selg,
                                                                   po_.rv00_summa                   as rv00_summa,
                                                                   po_.km00_summa                   as km00_summa,
                                                                   0                                as rv11_summa,
                                                                   coalesce(case
                                                                                -- 00 ->13
                                                                                when rv13_summa is not null and rv13_prev_rv = '00'
                                                                                    then -1 * rv13_summa
                                                                                end, 0)             as rv13_summa,
                                                                   coalesce(case
                                                                                -- 00 ->13
                                                                                when rv13_summa is not null and rv13_prev_rv = '00'
                                                                                    then -1 * (
                                                                                                  SELECT
                                                                                                      kulum
                                                                                                  FROM
                                                                                                      libs.get_pv_kaart_jaak(po_.pv_kaart_id, po_.rv13_kpv)
                                                                                              )
                                                                                else 0 end, 0)      as km13_summa,
                                                                   0                                as rv02_summa,
                                                                   0                                as km02_summa,
                                                                   0                                as rv14_summa,
                                                                   0                                as km14_summa,
                                                                   0                                as rv16_summa,
                                                                   0                                as km16_summa,
                                                                   0                                as rv23_summa,
                                                                   0                                as km23_summa,
                                                                   0                                as rv29_summa,
                                                                   0                                as km29_summa,
                                                                   0                                as rv19_summa,
                                                                   0                                as km19_summa,
                                                                   0                                as rv17_summa,
                                                                   0                                as km17_summa,
                                                                   0                                as rv12_summa,
                                                                   0                                as km12_summa
                                                               from
                                                                   params p,
                                                                          po_
                                                               union all
                                                               --rv11
                                                               select
                                                                   po.pv_kaart_id,
                                                                   po.konto as konto,
                                                                   'Rv11'   as selg,
                                                                   0        as rv00_summa,
                                                                   0        as km00_summa,
                                                                   po.summa as rv11_summa,
                                                                   0        as rv13_summa,
                                                                   0        as km13_summa,
                                                                   0        as rv02_summa,
                                                                   0        as km02_summa,
                                                                   0        as rv14_summa,
                                                                   0        as km14_summa,
                                                                   0        as rv16_summa,
                                                                   0        as km16_summa,
                                                                   0        as rv23_summa,
                                                                   0        as km23_summa,
                                                                   0        as rv29_summa,
                                                                   0        as km29_summa,
                                                                   0        as rv19_summa,
                                                                   0        as km19_summa,
                                                                   0        as rv17_summa,
                                                                   0        as km17_summa,
                                                                   0        as rv12_summa,
                                                                   0        as km12_summa

                                                               from
                                                                   params   p,
                                                                   po11_upd po

                                                               union all
-- (02) -13
                                                               select *
                                                               from
                                                                   (
                                                                       select
                                                                           po_.pv_kaart_id,
                                                                           libs.get_pv_kaart_konto(
                                                                                   po_.pv_kaart_id,
                                                                                   po_.rv13_kpv) as konto,
                                                                           '->13'                as selg,
                                                                           0                     as rv00_summa,
                                                                           0                     as km00_summa,
                                                                           0                     as rv11_summa,
                                                                           rv13_summa            as rv13_summa,
                                                                           (
                                                                               SELECT
                                                                                   kulum
                                                                               FROM
                                                                                   libs.get_pv_kaart_jaak(po_.pv_kaart_id, po_.rv13_kpv)
                                                                           )                     as km13_summa,
                                                                           0                     as rv02_summa,
                                                                           0                     as km02_summa,
                                                                           0                     as rv14_summa,
                                                                           0                     as km14_summa,
                                                                           0                     as rv16_summa,
                                                                           0                     as km16_summa,
                                                                           0                     as rv23_summa,
                                                                           0                     as km23_summa,

                                                                           0                     as rv29_summa,
                                                                           0                     as km29_summa,
                                                                           0                     as rv19_summa,
                                                                           0                     as km19_summa,
                                                                           0                     as rv17_summa,
                                                                           0                     as km17_summa,
                                                                           0                     as rv12_summa,
                                                                           0                     as km12_summa


                                                                       from
                                                                           po_
                                                                       where
                                                                           po_.rv13_summa is not null
                                                                       union all
                                                                       -- korrigerimised 14->13
                                                                       select
                                                                           po_.pv_kaart_id,
                                                                           libs.get_pv_kaart_konto(
                                                                                   po_.pv_kaart_id,
                                                                                   (po_.rv13_kpv - 1))         as konto,
                                                                           '14 -> 13 ' || po_.rv13_summa::text as selg,
                                                                           0                                   as rv00_summa,
                                                                           0                                   as km00_summa,
                                                                           0                                   as rv11_summa,
                                                                           case
                                                                               when po_.rv13_prev_rv = '14'
                                                                                   then -1 * po_.rv13_summa
                                                                               else 0
                                                                               end                             as rv13_summa,
                                                                           case
                                                                               when po_.rv13_prev_rv = '14' then
                                                                                   -1 * (
                                                                                            SELECT
                                                                                                kulum
                                                                                            FROM
                                                                                                libs.get_pv_kaart_jaak(po_.pv_kaart_id, po_.rv13_kpv)
                                                                                        )
                                                                               else 0 end                      as km13_summa,
                                                                           0                                   as rv02_summa,
                                                                           0                                   as km02_summa,
                                                                           0                                   as rv14_summa,
                                                                           0                                   as km14_summa,
                                                                           0                                   as rv16_summa,
                                                                           0                                   as km16_summa,
                                                                           0                                   as rv23_summa,
                                                                           0                                   as km23_summa,
                                                                           0                                   as rv29_summa,
                                                                           0                                   as km29_summa,
                                                                           0                                   as rv19_summa,
                                                                           0                                   as km19_summa,
                                                                           0                                   as rv17_summa,
                                                                           0                                   as km17_summa,
                                                                           0                                   as rv12_summa,
                                                                           0                                   as km12_summa

                                                                       from
                                                                           po_
                                                                       where
                                                                           po_.rv13_summa is not null

                                                                   ) rv13_
                                                               where
                                                                   rv13_summa is not null
                                                               union all
-- 02
                                                               select
                                                                   po_.pv_kaart_id,
                                                                   libs.get_pv_kaart_konto(
                                                                           po_.pv_kaart_id, po_.rv02_kpv) as konto,
                                                                   '->02'                                 as selg,
                                                                   0                                      as rv00_summa,
                                                                   0                                      as km00_summa,
                                                                   0                                      as rv11_summa,
                                                                   0                                      as rv13_summa,
                                                                   0                                      as km13_summa,
                                                                   po_.rv02_summa,
                                                                   (
                                                                       SELECT
                                                                           kulum
                                                                       FROM
                                                                           libs.get_pv_kaart_jaak(po_.pv_kaart_id, po_.rv02_kpv)
                                                                   )                                      as km02_summa,
                                                                   0                                      as rv14_summa,
                                                                   0                                      as km14_summa,
                                                                   0                                      as rv16_summa,
                                                                   0                                      as km16_summa,
                                                                   0                                      as rv23_summa,
                                                                   0                                      as km23_summa,
                                                                   0                                      as rv29_summa,
                                                                   0                                      as km29_summa,
                                                                   0                                      as rv19_summa,
                                                                   0                                      as km19_summa,
                                                                   0                                      as rv17_summa,
                                                                   0                                      as km17_summa,
                                                                   0                                      as rv12_summa,
                                                                   0                                      as km12_summa


                                                               from
                                                                   po_
                                                               where
                                                                   po_.rv02_summa is not null
                                                               union all
-- ->14
                                                               select *
                                                               from
                                                                   (
                                                                       select
                                                                           po_.pv_kaart_id,
                                                                           libs.get_pv_kaart_konto(
                                                                                   po_.pv_kaart_id,
                                                                                   po_.rv14_kpv)          as konto,
                                                                           '->14' || po_.rv14_summa::text as selg,
                                                                           0                              as rv00_summa,
                                                                           0                              as km00_summa,
                                                                           0                              as rv11_summa,
                                                                           case
                                                                               when po_.rv14_prev_rv = '13'
                                                                                   then -1 * po_.rv14_prev_summa
                                                                               else 0
                                                                               end                        as rv13_summa,
                                                                           0                              as km13_summa,
                                                                           0                              as rv02_summa,
                                                                           0                              as km02_summa,
                                                                           po_.rv14_summa                 as rv14_summa,
                                                                           (
                                                                               SELECT
                                                                                   kulum
                                                                               FROM
                                                                                   libs.get_pv_kaart_jaak(po_.pv_kaart_id, po_.rv14_kpv)
                                                                           )                              as km14_summa,
                                                                           0                              as rv16_summa,
                                                                           0                              as km16_summa,
                                                                           0                              as rv23_summa,
                                                                           0                              as km23_summa,
                                                                           0                              as rv29_summa,
                                                                           0                              as km29_summa,
                                                                           0                              as rv19_summa,
                                                                           0                              as km19_summa,
                                                                           0                              as rv17_summa,
                                                                           0                              as km17_summa,
                                                                           0                              as rv12_summa,
                                                                           0                              as km12_summa

                                                                       from
                                                                           po_
                                                                       where
                                                                           po_.rv14_summa is not null
                                                                       union all
                                                                       -- korrigerimised 19->14
                                                                       select
                                                                           po_.pv_kaart_id,
                                                                           libs.get_pv_kaart_konto(
                                                                                   po_.pv_kaart_id,
                                                                                   (po_.rv14_kpv - 1))        as konto,
                                                                           '19 -> 14' || po_.rv14_summa::text as selg,
                                                                           0                                  as rv00_summa,
                                                                           0                                  as km00_summa,
                                                                           0                                  as rv11_summa,
                                                                           0                                  as rv13_summa,
                                                                           0                                  as km13_summa,
                                                                           0                                  as rv02_summa,
                                                                           0                                  as km02_summa,
                                                                           -1 * po_.rv14_summa                as rv14_summa,
                                                                           -1 * (
                                                                                    SELECT
                                                                                        kulum
                                                                                    FROM
                                                                                        libs.get_pv_kaart_jaak(po_.pv_kaart_id, po_.rv14_kpv)
                                                                                )                             as km14_summa,
                                                                           0                                  as rv16_summa,
                                                                           0                                  as km16_summa,
                                                                           0                                  as rv23_summa,
                                                                           0                                  as km23_summa,
                                                                           0                                  as rv29_summa,
                                                                           0                                  as km29_summa,
                                                                           0                                  as rv19_summa,
                                                                           0                                  as km19_summa,
                                                                           0                                  as rv17_summa,
                                                                           0                                  as km17_summa,
                                                                           0                                  as rv12_summa,
                                                                           0                                  as km12_summa

                                                                       from
                                                                           po_
                                                                       where
                                                                           po_.rv14_summa is not null

                                                                   ) rv14_
                                                               union all
-- ->16
                                                               select *
                                                               from
                                                                   (
                                                                       select
                                                                           po_.pv_kaart_id,
                                                                           libs.get_pv_kaart_konto(
                                                                                   po_.pv_kaart_id,
                                                                                   po_.rv16_kpv) as konto,
                                                                           '->16'                as selg,
                                                                           0                     as rv00_summa,
                                                                           0                     as km00_summa,
                                                                           0                     as rv11_summa,
                                                                           0                     as rv13_summa,
                                                                           0                     as km13_summa,
                                                                           0                     as rv02_summa,
                                                                           0                     as km02_summa,
                                                                           0                     as rv14_summa,
                                                                           0                     as km14_summa,
                                                                           po_.rv16_summa        as rv16_summa,
                                                                           case
                                                                               when coalesce(po_.rv16_summa, 0) = 0
                                                                                   then 0
                                                                               else 1 end *
                                                                           (
                                                                               select
                                                                                   (l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 4)
                                                                               from
                                                                                   libs.library l
                                                                               where
                                                                                   id = po_.pv_kaart_id
                                                                           )
                                                                                                 as km16_summa,
                                                                           0                     as rv23_summa,
                                                                           0                     as km23_summa,
                                                                           0                     as rv29_summa,
                                                                           0                     as km29_summa,
                                                                           0                     as rv19_summa,
                                                                           0                     as km19_summa,
                                                                           0                     as rv17_summa,
                                                                           0                     as km17_summa,
                                                                           0                     as rv12_summa,
                                                                           0                     as km12_summa

                                                                       from
                                                                           po_
                                                                       where
                                                                           po_.rv16_summa is not null
                                                                   ) rv16_
                                                               union all
-- ->29
                                                               select *
                                                               from
                                                                   (
                                                                       select
                                                                           po.pv_kaart_id,
                                                                           libs.get_pv_kaart_konto(
                                                                                   po.pv_kaart_id,
                                                                                   po.kpv) as konto,
                                                                           '->29'          as selg,
                                                                           0               as rv00_summa,
                                                                           0               as km00_summa,
                                                                           0               as rv11_summa,
                                                                           0               as rv13_summa,
                                                                           0               as km13_summa,
                                                                           0               as rv02_summa,
                                                                           0               as km02_summa,
                                                                           0               as rv14_summa,
                                                                           0               as km14_summa,
                                                                           0               as rv16_summa,
                                                                           0               as km16_summa,
                                                                           0               as rv23_summa,
                                                                           0               as km23_summa,
                                                                           po.summa        as rv29_summa,
                                                                           (
                                                                               select
                                                                                   (l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 4)
                                                                               from
                                                                                   libs.library l
                                                                               where
                                                                                   id = po.pv_kaart_id
                                                                           )               as km29_summa,
                                                                           0               as rv19_summa,
                                                                           0               as km19_summa,
                                                                           0               as rv17_summa,
                                                                           0               as km17_summa,
                                                                           0               as rv12_summa,
                                                                           0               as km12_summa

                                                                       from
                                                                           po
                                                                       where
                                                                             po.kood3 = '29'
                                                                         and liik = 1
                                                                   ) rv29_
                                                               union all
-- ->23
                                                               select *
                                                               from
                                                                   (
                                                                       select
                                                                           po.pv_kaart_id,
                                                                           libs.get_pv_kaart_konto(
                                                                                   po.pv_kaart_id,
                                                                                   po.kpv)                                     as konto,
                                                                           '->23'                                              as selg,
                                                                           0                                                   as rv00_summa,
                                                                           0                                                   as km00_summa,
                                                                           0                                                   as rv11_summa,
                                                                           0                                                   as rv13_summa,
                                                                           0                                                   as km13_summa,
                                                                           0                                                   as rv02_summa,
                                                                           0                                                   as km02_summa,
                                                                           0                                                   as rv14_summa,
                                                                           0                                                   as km14_summa,
                                                                           0                                                   as rv16_summa,
                                                                           0                                                   as km16_summa,
                                                                           CASE WHEN po.liik = 4 THEN -1 ELSE 1 END * po.summa as rv23_summa,
                                                                           CASE WHEN po.liik = 4 THEN -1 ELSE 0 END * (
                                                                                                                          select
                                                                                                                              (l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 4)
                                                                                                                          from
                                                                                                                              libs.library l
                                                                                                                          where
                                                                                                                              id = po.pv_kaart_id
                                                                                                                      )        as km23_summa,
                                                                           0                                                   as rv29_summa,
                                                                           0                                                   as km29_summa,
                                                                           0                                                   as rv19_summa,
                                                                           0                                                   as km19_summa,
                                                                           0                                                   as rv17_summa,
                                                                           0                                                   as km17_summa,
                                                                           0                                                   as rv12_summa,
                                                                           0                                                   as km12_summa

                                                                       from
                                                                           po
                                                                       where
                                                                             po.kood3 = '23'
                                                                         and liik in (1, 4, 3)
                                                                       union all
                                                                       -- kulum korrigeerimine 23.10.2025 V. Nikitina, kui mahakantud Rv17 ja parandesed lausendiga
                                                                       select
                                                                           po.pv_kaart_id,
                                                                           libs.get_pv_kaart_konto(
                                                                                   po.pv_kaart_id,
                                                                                   po.kpv)       as konto,
                                                                           '->23'                as selg,
                                                                           0                     as rv00_summa,
                                                                           0                     as km00_summa,
                                                                           0                     as rv11_summa,
                                                                           0                     as rv13_summa,
                                                                           0                     as km13_summa,
                                                                           0                     as rv02_summa,
                                                                           0                     as km02_summa,
                                                                           0                     as rv14_summa,
                                                                           0                     as km14_summa,
                                                                           0                     as rv16_summa,
                                                                           0                     as km16_summa,
                                                                           0                     as rv23_summa,
                                                                           coalesce(j1.summa, 0) as km23_summa,
                                                                           0                     as rv29_summa,
                                                                           0                     as km29_summa,
                                                                           0                     as rv19_summa,
                                                                           0                     as km19_summa,
                                                                           0                     as rv17_summa,
                                                                           case
                                                                               when exists
                                                                               (
                                                                                   select
                                                                                       1
                                                                                   from
                                                                                       po po_17
                                                                                   where
                                                                                         po_17.pv_kaart_id = pk.pv_kaart_id
                                                                                     and po_17.liik = 4
                                                                                     and po_17.kood3 = '17'
                                                                               ) then -1 * coalesce(j1.summa, 0)
                                                                               else 0 end        as km17_summa,
                                                                           0                     as rv12_summa,
                                                                           0                     as km12_summa

                                                                       from
                                                                           po
                                                                               inner join pv_kaardid    pk on po.pv_kaart_id = pk.pv_kaart_id
                                                                               inner join docs.journal  j on po.journalid = j.parentid
                                                                               inner join docs.journal1 j1 on j.id = j1.parentid

                                                                       where
                                                                             po.kood3 = '23'
                                                                         and liik in (3)
                                                                         and j1.deebet = pk.kulum_konto
                                                                         and j1.kood3 = po.kood3
                                                                       union all
-- переквалификация
                                                                       select
                                                                           po.pv_kaart_id,
                                                                           libs.get_pv_kaart_konto(
                                                                                   po.pv_kaart_id,
                                                                                   po.kpv) as konto,
                                                                           '->23'          as selg,
                                                                           0               as rv00_summa,
                                                                           0               as km00_summa,
                                                                           0               as rv11_summa,
                                                                           0               as rv13_summa,
                                                                           0               as km13_summa,
                                                                           0               as rv02_summa,
                                                                           0               as km02_summa,
                                                                           0               as rv14_summa,
                                                                           0               as km14_summa,
                                                                           0               as rv16_summa,
                                                                           0               as km16_summa,
                                                                           po.summa        as rv23_summa,
                                                                           (
                                                                               SELECT
                                                                                   kulum
                                                                               FROM
                                                                                   libs.get_pv_kaart_jaak(po.pv_kaart_id, po.kpv)
                                                                           )               as km23_summa,
                                                                           0               as rv29_summa,
                                                                           0               as km29_summa,
                                                                           0               as rv19_summa,
                                                                           0               as km19_summa,
                                                                           0               as rv17_summa,
                                                                           0               as km17_summa,
                                                                           0               as rv12_summa,
                                                                           0               as km12_summa

                                                                       from
                                                                           po
                                                                       where
                                                                             po.kood3 = '23'
                                                                         and liik in (6)
                                                                       union all
                                                                       -- корректирование rv16 ->Rv23
                                                                       select
                                                                           po.pv_kaart_id,
                                                                           libs.get_pv_kaart_konto(
                                                                                   po.pv_kaart_id,
                                                                                   po.kpv - 1) as konto,
                                                                           '16->23'            as selg,
                                                                           0                   as rv00_summa,
                                                                           0                   as km00_summa,
                                                                           0                   as rv11_summa,
                                                                           0                   as rv13_summa,
                                                                           0                   as km13_summa,
                                                                           0                   as rv02_summa,
                                                                           0                   as km02_summa,
                                                                           0                   as rv14_summa,
                                                                           0                   as km14_summa,
                                                                           0                   as rv16_summa,
                                                                           0                   as km16_summa,
                                                                           -1 * case
                                                                                    when po_.rv23_prev_rv = '16'
                                                                                        then po.summa
                                                                                    else 0
                                                                               end             as rv23_summa,
                                                                           -1 * case
                                                                                    when po_.rv23_prev_rv = '16' then (
                                                                                                                          SELECT
                                                                                                                              kulum
                                                                                                                          FROM
                                                                                                                              libs.get_pv_kaart_jaak(po.pv_kaart_id, po.kpv)
                                                                                    )
                                                                                    else 0
                                                                               end             as km23_summa,
                                                                           0                   as rv29_summa,
                                                                           0                   as km29_summa,
                                                                           0                   as rv19_summa,
                                                                           0                   as km19_summa,
                                                                           0                   as rv17_summa,
                                                                           0                   as km17_summa,
                                                                           0                   as rv12_summa,
                                                                           0                   as km12_summa

                                                                       from
                                                                           po_,
                                                                           po
                                                                       where
                                                                             po.pv_kaart_id = po_.pv_kaart_id
                                                                         and po.kood3 = '23'
                                                                         and po.liik in (6)

                                                                   ) rv23_
                                                               union all
-- ->19
                                                               select *
                                                               from
                                                                   (
                                                                       select
                                                                           po.pv_kaart_id,
                                                                           libs.get_pv_kaart_konto(
                                                                                   po.pv_kaart_id,
                                                                                   po.kpv) as konto,
                                                                           '->19'          as selg,
                                                                           0               as rv00_summa,
                                                                           0               as km00_summa,
                                                                           0               as rv11_summa,
                                                                           0               as rv13_summa,
                                                                           0               as km13_summa,
                                                                           0               as rv02_summa,
                                                                           0               as km02_summa,
                                                                           0               as rv14_summa,
                                                                           0               as km14_summa,
                                                                           0               as rv16_summa,
                                                                           0               as km16_summa,
                                                                           0               as rv23_summa,
                                                                           0               as km23_summa,
                                                                           0               as rv29_summa,
                                                                           0               as km29_summa,
                                                                           po.summa        as rv19_summa,
                                                                           0               as km19_summa,
                                                                           0               as rv17_summa,
                                                                           0               as km17_summa,
                                                                           0               as rv12_summa,
                                                                           0               as km12_summa
                                                                       from
                                                                           po
                                                                       where
                                                                             po.kood3 = '19'
                                                                         and liik in (1, 3)
                                                                   ) rv19_
                                                               union all
-- ->17
                                                               select *
                                                               from
                                                                   (
                                                                       select
                                                                           po.pv_kaart_id,
                                                                           libs.get_pv_kaart_konto(
                                                                                   po.pv_kaart_id,
                                                                                   po.kpv)                                     as konto,
                                                                           '->17'                                              as selg,
                                                                           0                                                   as rv00_summa,
                                                                           0                                                   as km00_summa,
                                                                           0                                                   as rv11_summa,
                                                                           0                                                   as rv13_summa,
                                                                           0                                                   as km13_summa,
                                                                           0                                                   as rv02_summa,
                                                                           0                                                   as km02_summa,
                                                                           0                                                   as rv14_summa,
                                                                           0                                                   as km14_summa,
                                                                           0                                                   as rv16_summa,
                                                                           0                                                   as km16_summa,
                                                                           0                                                   as rv23_summa,
                                                                           0                                                   as km23_summa,
                                                                           0                                                   as rv29_summa,
                                                                           0                                                   as km29_summa,
                                                                           0                                                   as rv19_summa,
                                                                           0                                                   as km19_summa,

                                                                           CASE WHEN po.liik = 4 THEN -1 ELSE 1 END * po.summa as rv17_summa,
                                                                           CASE WHEN po.liik = 4 THEN -1 ELSE 1 END * (
                                                                                                                          select
                                                                                                                              (l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 4)
                                                                                                                          from
                                                                                                                              libs.library l
                                                                                                                          where
                                                                                                                              id = po.pv_kaart_id
                                                                                                                      )        as km17_summa,
                                                                           0                                                   as rv12_summa,
                                                                           0                                                   as km12_summa
                                                                       from
                                                                           po
                                                                       where
                                                                             po.kood3 = '17'
                                                                         and liik in (1, 4)
                                                                   ) rv17_
                                                               union all
-- ->12
                                                               select *
                                                               from
                                                                   (
                                                                       select
                                                                           po.pv_kaart_id,
                                                                           libs.get_pv_kaart_konto(
                                                                                   po.pv_kaart_id,
                                                                                   po.kpv)                                     as konto,
                                                                           '->12'                                              as selg,
                                                                           0                                                   as rv00_summa,
                                                                           0                                                   as km00_summa,
                                                                           0                                                   as rv11_summa,
                                                                           0                                                   as rv13_summa,
                                                                           0                                                   as km13_summa,
                                                                           0                                                   as rv02_summa,
                                                                           0                                                   as km02_summa,
                                                                           0                                                   as rv14_summa,
                                                                           0                                                   as km14_summa,
                                                                           0                                                   as rv16_summa,
                                                                           0                                                   as km16_summa,
                                                                           0                                                   as rv23_summa,
                                                                           0                                                   as km23_summa,
                                                                           0                                                   as rv29_summa,
                                                                           0                                                   as km29_summa,
                                                                           0                                                   as rv19_summa,
                                                                           0                                                   as km19_summa,
                                                                           0                                                   as rv17_summa,
                                                                           0                                                   as km17_summa,

                                                                           CASE WHEN po.liik = 4 THEN -1 ELSE 1 END * po.summa as rv12_summa,
                                                                           CASE WHEN po.liik = 4 THEN -1 ELSE 1 END * (
                                                                                                                          SELECT
                                                                                                                              kulum
                                                                                                                          FROM
                                                                                                                              libs.get_pv_kaart_jaak(po.pv_kaart_id, po.kpv)
                                                                                                                      )        as km12_summa
                                                                       from
                                                                           po
                                                                       where
                                                                             po.kood3 = '12'
                                                                         and liik in (4)
                                                                   ) rv12_


                                                           )                           rep
                                                               inner join cur_pohivara pv on pv.id = rep.pv_kaart_id
                                                       order by
                                                           pv_kaart_id, rv00_summa desc, konto
                                                   )
                                    select
                                        r.pv_kaart_id,
                                        r.konto,
                                        string_agg(selg, ',') as selg,
                                        sum(r.rv00_summa)     as rv00_summa,
                                        sum(r.km00_summa)     as km00_summa,
                                        sum(r.rv02_summa)     as rv02_summa,
                                        sum(r.km02_summa)     as km02_summa,
                                        sum(r.rv11_summa)     as rv11_summa,
                                        sum(r.rv13_summa)     as rv13_summa,
                                        sum(r.km13_summa)     as km13_summa,
                                        sum(r.rv14_summa)     as rv14_summa,
                                        sum(r.km14_summa)     as km14_summa,
                                        sum(r.rv16_summa)     as rv16_summa,
                                        sum(r.km16_summa)     as km16_summa,
                                        sum(r.rv23_summa)     as rv23_summa,
                                        sum(r.km23_summa)     as km23_summa,
                                        sum(r.rv29_summa)     as rv29_summa,
                                        sum(r.km29_summa)     as km29_summa,
                                        sum(r.rv19_summa)     as rv19_summa,
                                        sum(r.km19_summa)     as km19_summa,
                                        sum(r.rv17_summa)     as rv17_summa,
                                        sum(r.km17_summa)     as km17_summa,
                                        sum(r.rv12_summa)     as rv12_summa,
                                        sum(r.km12_summa)     as km12_summa,
                                        sum(r.rv00_summa + r.rv13_summa + r.rv14_summa + r.rv16_summa +
                                            r.rv29_summa - r.rv23_summa + rv19_summa + rv17_summa +
                                            rv12_summa)       as rv_lopp_summa,
                                        sum(r.km00_summa + r.rv11_summa + r.km16_summa + r.km29_summa -
                                            r.km23_summa + r.km19_summa + r.km17_summa +
                                            km12_summa)       as rv_lopp_kulum

                                    from
                                        report r
                                    group by r.pv_kaart_id, r.konto
                                )           kb ON kb.pv_kaart_id = pk.pv_kaart_id

                INNER JOIN      ou.rekv     r ON r.id = pk.rekvid
                LEFT OUTER JOIN libs.asutus a ON pk.vastisik_id = to_jsonb(a.id)
        where
            pk.pv_kaart_id in (
                                  select
                                      pv_kaart_id
                                  from
                                      rv_po
                              )
    ) report

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.pv_rv_kaibe_aruanne( DATE, DATE, INTEGER, INTEGER, JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.pv_rv_kaibe_aruanne( DATE, DATE, INTEGER, INTEGER, JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.pv_rv_kaibe_aruanne( DATE, DATE, INTEGER , INTEGER, JSONB) TO dbkasutaja;


SELECT
*
      FROM docs.pv_rv_kaibe_aruanne('2025-01-01', '2025-12-31' :: DATE, 119, 0, '{"kood":"155109-024-00"}'::jsonb);



