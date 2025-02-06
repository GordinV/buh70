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
                      (l.properties :: JSONB ->> 'algkulum')::numeric(12, 2)                           as pv_alg_kulum
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
                      po.pv_kaart_id           AS pv_kaart_id,
                      po.kpv                   as kpv,
                      0:: NUMERIC(12, 2)       AS alg_soetmaks,
                      0:: NUMERIC(12, 2)       AS alg_kulum,
                      po.summa::NUMERIC(12, 2) AS kb_pv_rv01,
                      0::NUMERIC(12, 2)        AS kb_pv_rv02,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv02,
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
                      0::NUMERIC(12, 2)        AS kb_pv_rv21,
                      0::NUMERIC(12, 2)        AS kb_pv_rv23,
                      0::NUMERIC(12, 2)        AS kb_pv_rv24,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)        AS kb_pv_rv29,
                      0::NUMERIC(12, 2)        AS kb_kulum_rv29,
                      0                        as lopp_soetmaks,
                      0                        as lopp_kulum

                  FROM
                      po,
                      params p
                  WHERE
                        po.liik = 1
                    and po.kpv >= p.kpv1
                    and po.kpv <= p.kpv2
                    AND coalesce(po.kood3, '01') in ('01', '')
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
                      po.pv_kaart_id                                                                                 AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)                                                                             AS alg_soetmaks,
                      0:: NUMERIC(12, 2)                                                                             AS alg_kulum,
                      0::NUMERIC(12, 2)                                                                              AS kb_pv_rv01,
                      0::NUMERIC(12, 2)                                                                              AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)                                                                             AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)                                                                              AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)                                                                              AS kb_pv_rv12,
                      0::NUMERIC(12, 2)                                                                              AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)                                                                              AS kb_pv_rv13,
                      0::NUMERIC(12, 2)                                                                              AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)                                                                              AS kb_pv_rv14,
                      0::NUMERIC(12, 2)                                                                              AS kb_kulum_rv14,
                      po.summa::NUMERIC(12, 2)                                                                       AS kb_pv_rv15,
                      (pk.alg_kulum + coalesce(k.kb_kulum_rv11, 0) +
                       coalesce(k15.kb_kulum_rv15, 0))::NUMERIC(12, 2)                                               AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)                                                                              AS kb_pv_rv16,
                      0::NUMERIC(12, 2)                                                                              AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)                                                                              AS kb_pv_rv17,
                      0::NUMERIC(12, 2)                                                                              AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)                                                                              AS kb_pv_rv19,
                      0::NUMERIC(12, 2)                                                                              AS kb_pv_rv21,
                      0::NUMERIC(12, 2)                                                                              AS kb_pv_rv23,
                      0::NUMERIC(12, 2)                                                                              AS kb_pv_rv24,
                      0::NUMERIC(12, 2)                                                                              AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)                                                                              AS kb_pv_rv29,
                      0::NUMERIC(12, 2)                                                                              AS kb_kulum_rv29,
                      0                                                                                              as lopp_soetmaks,
                      0                                                                                              as lopp_kulum

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
                  -- rv17
                  SELECT
                      po.pv_kaart_id               AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)           AS alg_soetmaks,
                      0:: NUMERIC(12, 2)           AS alg_kulum,
                      0::NUMERIC(12, 2)            AS kb_pv_rv01,
                      0::NUMERIC(12, 2)            AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)           AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)            AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)            AS kb_pv_rv12,
                      0::NUMERIC(12, 2)            AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)            AS kb_pv_rv13,
                      0::NUMERIC(12, 2)            AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)            AS kb_pv_rv14,
                      0::NUMERIC(12, 2)            AS kb_kulum_rv14,
                      0::NUMERIC(12, 2)            AS kb_pv_rv15,
                      0::NUMERIC(12, 2)            AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)            AS kb_pv_rv16,
                      0::NUMERIC(12, 2)            AS kb_kulum_rv16,
                      po.summa::NUMERIC(12, 2)     AS kb_pv_rv17,
                      pk.alg_kulum::NUMERIC(12, 2) AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)            AS kb_pv_rv19,
                      0::NUMERIC(12, 2)            AS kb_pv_rv21,
                      0::NUMERIC(12, 2)            AS kb_pv_rv23,
                      0::NUMERIC(12, 2)            AS kb_pv_rv24,
                      0::NUMERIC(12, 2)            AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)            AS kb_pv_rv29,
                      0::NUMERIC(12, 2)            AS kb_kulum_rv29,
                      0                            as lopp_soetmaks,
                      0                            as lopp_kulum

                  FROM
                      params                    p,
                      po
                          INNER JOIN pv_kaardid pk
                                     ON pk.pv_kaart_id = po.pv_kaart_id
                  WHERE
                        po.liik = 1
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
                      0::NUMERIC(12, 2)                                                   AS kb_pv_rv24,
                      0::NUMERIC(12, 2)                                                   AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)                                                   AS kb_pv_rv29,
                      0::NUMERIC(12, 2)                                                   AS kb_kulum_rv29,
                      0                                                                   as lopp_soetmaks,
                      0                                                                   as lopp_kulum

                  FROM
                      po
                  WHERE
                        po.liik IN (1, 3, 4) -- 22.01.2024 lisatud mahakandmine
                    AND COALESCE(po.kood3, '') = '23'
                  UNION ALL
                  -- rv24
                  SELECT
                      po.pv_kaart_id                                                AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)                                            AS alg_soetmaks,
                      0:: NUMERIC(12, 2)                                            AS alg_kulum,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv01,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)                                            AS kb_kulum_rv02,
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
                      po.summa::NUMERIC(12, 2)                                      AS kb_pv_rv24,
                      (pk.alg_kulum + coalesce(k.kb_kulum_rv11, 0))::NUMERIC(12, 2) AS kb_kulum_rv24,
                      0::NUMERIC(12, 2)                                             AS kb_pv_rv29,
                      0::NUMERIC(12, 2)                                             AS kb_kulum_rv29,
                      0                                                             as lopp_soetmaks,
                      0                                                             as lopp_kulum

                  FROM
                      po
                          INNER JOIN      pv_kaardid pk
                                          ON pk.pv_kaart_id = po.pv_kaart_id
                          LEFT OUTER JOIN po_rv11    k ON k.pv_kaart_id = pk.pv_kaart_id

                  WHERE
                        po.liik = 4
                    AND COALESCE(po.kood3, '') = '24'
                  UNION ALL
                  -- rv29
                  SELECT
                      po.pv_kaart_id                                                                                AS pv_kaart_id,
                      po.kpv,
                      0:: NUMERIC(12, 2)                                                                            AS alg_soetmaks,
                      0:: NUMERIC(12, 2)                                                                            AS alg_kulum,
                      0::NUMERIC(12, 2)                                                                             AS kb_pv_rv01,
                      0::NUMERIC(12, 2)                                                                             AS kb_pv_rv02,
                      0 ::NUMERIC(12, 2)                                                                            AS kb_kulum_rv02,
                      0::NUMERIC(12, 2)                                                                             AS kb_kulum_rv11,
                      0::NUMERIC(12, 2)                                                                             AS kb_pv_rv12,
                      0::NUMERIC(12, 2)                                                                             AS kb_kulum_rv12,
                      0::NUMERIC(12, 2)                                                                             AS kb_pv_rv13,
                      0::NUMERIC(12, 2)                                                                             AS kb_kulum_rv13,
                      0::NUMERIC(12, 2)                                                                             AS kb_pv_rv14,
                      0::NUMERIC(12, 2)                                                                             AS kb_kulum_rv14,
                      0::NUMERIC(12, 2)                                                                             AS kb_pv_rv15,
                      0::NUMERIC(12, 2)                                                                             AS kb_kulum_rv15,
                      0::NUMERIC(12, 2)                                                                             AS kb_pv_rv16,
                      0::NUMERIC(12, 2)                                                                             AS kb_kulum_rv16,
                      0::NUMERIC(12, 2)                                                                             AS kb_pv_rv17,
                      0::NUMERIC(12, 2)                                                                             AS kb_kulum_rv17,
                      0::NUMERIC(12, 2)                                                                             AS kb_pv_rv19,
                      0::NUMERIC(12, 2)                                                                             AS kb_pv_rv21,
                      0::NUMERIC(12, 2)                                                                             AS kb_pv_rv23,
                      0::NUMERIC(12, 2)                                                                             AS kb_pv_rv24,
                      0::NUMERIC(12, 2)                                                                             AS kb_kulum_rv24,
                      CASE WHEN po.liik = 1 THEN 1 ELSE -1 END * po.summa::NUMERIC(12, 2)                           AS kb_pv_rv29,
                      CASE
                          WHEN po.liik = 1 THEN pk.alg_kulum
                          ELSE -1 *
                               ((pk.alg_kulum + coalesce(k.kb_kulum_rv11, 0))::NUMERIC(12, 2)) END ::NUMERIC(12, 2) AS kb_kulum_rv29,
                      0                                                                                             as lopp_soetmaks,
                      0                                                                                             as lopp_kulum

                  FROM
                      po
                          INNER JOIN      pv_kaardid pk
                                          ON pk.pv_kaart_id = po.pv_kaart_id
                          LEFT OUTER JOIN po_rv11    k ON k.pv_kaart_id = pk.pv_kaart_id

                  WHERE
                        po.liik IN (1, 4)
                    AND COALESCE(po.kood3, '') = '29'
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
    kb_pv_rv01:: NUMERIC(12, 2),                                                                       -- Soetused ja parendused
    kb_pv_rv19:: NUMERIC(12, 2),                                                                       -- Saadud mitterahaline sihtfinantseerimine
    kb_pv_rv14:: NUMERIC(12, 2),                                                                       -- Üleviimine kinnisvarainvesteeringute grupist materiaalse põhivara gruppi
    kb_pv_rv13:: NUMERIC(12, 2),                                                                       -- Üleviimine materiaalse põhivara grupist kinnisvarainvesteeringute gruppi
    kb_pv_rv15:: NUMERIC(12, 2),                                                                       -- Varade mitterahalised siirded (üleandmine)
    kb_pv_rv16:: NUMERIC(12, 2),                                                                       -- Varade mitterahalised siirded (saamine)
    kb_pv_rv23:: NUMERIC(12, 2),                                                                       -- Ümberklassifitseerimine
    kb_pv_rv17:: NUMERIC(12, 2),                                                                       -- Varade üleandmine mitterahalise sissemaksena netovarasse
    kb_pv_rv24:: NUMERIC(12, 2),                                                                       -- Mitterahaline sihtfinantseerimine (üleandmine)
    kb_pv_rv29:: NUMERIC(12, 2),                                                                       -- Muud mitterahalised kanded varadega
    kb_pv_rv21:: NUMERIC(12, 2),                                                                       -- Varade ümberhindlus
    kb_pv_rv02:: NUMERIC(12, 2),                                                                       -- Müüdud põhivara
    kb_pv_rv12:: NUMERIC(12, 2),                                                                       -- Varade mahakandmine

    (alg_soetmaks + kb_pv_rv01 - kb_pv_rv02 + kb_pv_rv12 + kb_pv_rv13 + kb_pv_rv14 + kb_pv_rv16 + kb_pv_rv19 +
     kb_pv_rv23 - kb_pv_rv15 + kb_pv_rv29 -
     kb_pv_rv24):: NUMERIC(12, 2)                                                    as lopp_soetmaks, -- Soetusmaksumus perioodi lõpus
    -- kulum osa
    kb_kulum_rv11:: NUMERIC(12, 2),                                                                    -- Varade kulum ja allahindlus
    kb_kulum_rv02:: NUMERIC(12, 2),                                                                    -- Müüdud põhivara
    kb_kulum_rv12:: NUMERIC(12, 2),                                                                    -- Varade mahakandmine
    kb_kulum_rv14:: NUMERIC(12, 2),                                                                    -- Üleviimine kinnisvarainvesteeringute grupist materiaalse põhivara gruppi
    kb_kulum_rv13:: NUMERIC(12, 2),                                                                    -- Üleviimine materiaalse põhivara grupist kinnisvarainvesteeringute gruppi
    kb_kulum_rv15:: NUMERIC(12, 2),                                                                    -- Varade mitterahalised siirded (üleandmine)
    kb_kulum_rv16:: NUMERIC(12, 2),                                                                    -- Varade mitterahalised siirded (saamine)
    kb_kulum_rv17:: NUMERIC(12, 2),                                                                    -- Varade üleandmine mitterahalise sissemaksena netovarasse
    kb_kulum_rv24:: NUMERIC(12, 2),                                                                    -- Mitterahaline sihtfinantseerimine (üleandmine)
    kb_kulum_rv29:: NUMERIC(12, 2),                                                                    -- Muud mitterahalised kanded varadega

    (alg_kulum - kb_kulum_rv02 + kb_kulum_rv11 + kb_kulum_rv12 + kb_kulum_rv13 + kb_kulum_rv14 +
     kb_kulum_rv16 - kb_kulum_rv15 + kb_kulum_rv29 - kb_kulum_rv24):: NUMERIC(12, 2) as lopp_kulum,
    vastisik:: VARCHAR(254),
    asutus:: VARCHAR(254)
from
    (
        SELECT
            ''                                             as selg,
            pk.kood::VARCHAR(20),
            pk.nimetus:: VARCHAR(254),
/*            case
                when pk.konto = '154000' then libs.get_pv_kaart_konto(
                        pk.pv_kaart_id, p.kpv1)
                else pk.konto end:: VARCHAR(20),
*/
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
            0:: NUMERIC(12, 2),                                           -- Saadud mitterahaline sihtfinantseerimine
            coalesce(kb.rv14_summa, 0):: NUMERIC(12, 2),                  -- Üleviimine kinnisvarainvesteeringute grupist materiaalse põhivara gruppi
            coalesce(kb.rv13_summa, 0):: NUMERIC(12, 2),                  -- Üleviimine materiaalse põhivara grupist kinnisvarainvesteeringute gruppi
            0:: NUMERIC(12, 2),                                           -- Varade mitterahalised siirded (üleandmine)
            coalesce(kb.rv16_summa, 0):: NUMERIC(12, 2),                  -- Varade mitterahalised siirded (saamine)
            kb.rv23_summa:: NUMERIC(12, 2),                               -- Ümberklassifitseerimine
            0:: NUMERIC(12, 2),                                           -- Varade üleandmine mitterahalise sissemaksena netovarasse
            0:: NUMERIC(12, 2),                                           -- Mitterahaline sihtfinantseerimine (üleandmine)
            kb.rv29_summa:: NUMERIC(12, 2),                               -- Muud mitterahalised kanded varadega
            0:: NUMERIC(12, 2),                                           -- Varade ümberhindlus
            coalesce(kb.rv02_summa, 0):: NUMERIC(12, 2),                  -- Müüdud põhivara
            0:: NUMERIC(12, 2),                                           -- Varade mahakandmine

            coalesce(kb.rv_lopp_summa, 0):: NUMERIC(12, 2),               -- Soetusmaksumus perioodi lõpus
            -- kulum osa
            coalesce(kb.rv11_summa, 0):: NUMERIC(12, 2),                  -- Varade kulum ja allahindlus
            coalesce(kb.km02_summa, 0)::numeric(12, 2)  as kb_kulum_rv02, -- Müüdud põhivara
            0:: NUMERIC(12, 2),                                           -- Varade mahakandmine
            coalesce(kb.km14_summa, 0)::numeric(12, 2)  as kb_kulum_rv14, -- Üleviimine kinnisvarainvesteeringute grupist materiaalse põhivara gruppi
            coalesce(kb.km13_summa, 0)::numeric(12, 2)  as kb_kulum_rv13, -- Üleviimine materiaalse põhivara grupist kinnisvarainvesteeringute gruppi
            0:: NUMERIC(12, 2),                                           -- Varade mitterahalised siirded (üleandmine)
            coalesce(kb.km16_summa, 0)::numeric(12, 2)  as kb_kulum_rv16, -- Varade mitterahalised siirded (saamine)
            0:: NUMERIC(12, 2),                                           -- Varade üleandmine mitterahalise sissemaksena netovarasse
            0:: NUMERIC(12, 2),                                           -- Mitterahaline sihtfinantseerimine (üleandmine)
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
                                                           po.kood3 in ('13', '14', '16', '02')
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
                                                                       end,
                                                                   '00')                                                           as rv13_prev_rv,
                                                           coalesce(case
                                                                        when coalesce(rv02.order, 999) < rv13.order
                                                                            then rv02.summa
                                                                        when coalesce(rv14.order, 999) < rv14.order
                                                                            then rv14.summa
                                                                        end,
                                                                    rv00.summa)                                                    as rv13_prev_summa,
                                                           rv14.summa                                                              as rv14_summa,
                                                           rv14.rv                                                                 as rv14_rv,
                                                           rv14.kpv                                                                as rv14_kpv,
                                                           coalesce(
                                                                   case
                                                                       when coalesce(rv02.order, 999) < rv14.order
                                                                           then rv02.rv
                                                                       when coalesce(rv13.order, 999) < rv14.order
                                                                           then rv13.rv
                                                                       end,
                                                                   '00')                                                           as rv14_prev_rv,
                                                           coalesce(case
                                                                        when coalesce(rv02.order, 999) < rv14.order
                                                                            then rv02.summa
                                                                        when coalesce(rv13.order, 999) < rv14.order
                                                                            then rv13.summa
                                                                        end,
                                                                    rv00.summa)                                                    as rv14_prev_summa,
                                                           rv02.summa                                                              as rv02_summa,
                                                           rv02.kpv                                                                as rv02_kpv,
                                                           case when rv02.summa is not null then '13' else null end::text          as rv02_prev_rv,
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
                                                                       end,
                                                                   '00')                                                           as rv16_prev_rv,
                                                           coalesce(case
                                                                        when coalesce(rv02.order, 999) < rv16.order
                                                                            then rv02.summa
                                                                        when coalesce(rv13.order, 999) < rv16.order
                                                                            then rv13.summa
                                                                        when coalesce(rv14.order, 999) < rv16.order
                                                                            then rv13.summa
                                                                        end,
                                                                    0)                                                             as rv16_prev_summa


                                                       from
                                                           rv00
                                                               left outer join rv02 on rv00.pv_kaart_id = rv02.pv_kaart_id
                                                               left outer join rv11 on rv00.pv_kaart_id = rv11.pv_kaart_id
                                                               left outer join rv13 on rv00.pv_kaart_id = rv13.pv_kaart_id
                                                               left outer join rv14 on rv00.pv_kaart_id = rv14.pv_kaart_id
                                                               left outer join rv16 on rv00.pv_kaart_id = rv16.pv_kaart_id
                                                   ),
                                        -- износ korrection
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
                                                                   po_.rv00_summa,
                                                                   po_.km00_summa                   as km00_summa,
                                                                   po_.rv11_summa                   as rv11_summa,
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
                                                                   case
                                                                       -- 00 ->14
                                                                       when rv14_summa is not null and rv14_prev_rv = '00'
                                                                           then -1 * rv14_summa
                                                                       end                          as rv14_summa,
                                                                   coalesce(case
                                                                                -- 00 ->14
                                                                                when rv14_summa is not null and rv14_prev_rv = '00'
                                                                                    then -1 * (
                                                                                                  SELECT
                                                                                                      kulum
                                                                                                  FROM
                                                                                                      libs.get_pv_kaart_jaak(po_.pv_kaart_id, po_.rv14_kpv)
                                                                                              )
                                                                                else 0 end, 0)      as km14_summa,
                                                                   0                                as rv16_summa,
                                                                   0                                as km16_summa,
                                                                   0                                as rv23_summa,
                                                                   0                                as km23_summa,
                                                                   0                                as rv29_summa,
                                                                   0                                as km29_summa
                                                               from
                                                                   params p,
                                                                          po_
                                                               union all
                                                               -- корректировка rv11
                                                               select
                                                                   po_.pv_kaart_id,
                                                                   libs.get_pv_kaart_konto(
                                                                           po_.pv_kaart_id, p.kpv1) as konto,
                                                                   '00'                             as selg,
                                                                   0,
                                                                   0                                as km00_summa,
                                                                   -1 * coalesce((
                                                                                     select
                                                                                         sum(po_k.summa) as summa
                                                                                     from
                                                                                         po11_korr po_k
                                                                                     where
                                                                                           po_k.pv_kaart_id = po_.pv_kaart_id
                                                                                       and po_k.kpv >= po_.rv13_kpv
                                                                                 ), 0)              as rv11_summa,
                                                                   0                                as rv13_summa,
                                                                   0                                as km13_summa,
                                                                   0                                as rv02_summa,
                                                                   0                                as km02_summa,
                                                                   0                                as rv14_summa,
                                                                   0                                as km14_summa,
                                                                   0                                as rv16_summa,
                                                                   0                                as km16_summa,
                                                                   0                                as rv23_summa,
                                                                   0                                as km23_summa,
                                                                   0                                as rv29_summa,
                                                                   0                                as km29_summa
                                                               from
                                                                   params p,
                                                                          po_

                                                               union all
                                                               -- корректировка rv11 (rv14)
                                                               select
                                                                   po_.pv_kaart_id,
                                                                   libs.get_pv_kaart_konto(
                                                                           po_.pv_kaart_id, p.kpv1) as konto,
                                                                   '00'                             as selg,
                                                                   0,
                                                                   0                                as km00_summa,
                                                                   -1 * coalesce((
                                                                                     select
                                                                                         sum(po_k.summa) as summa
                                                                                     from
                                                                                         po11_korr po_k
                                                                                     where
                                                                                           po_k.pv_kaart_id = po_.pv_kaart_id
                                                                                       and po_k.kpv >= po_.rv14_kpv
                                                                                 ), 0)              as rv11_summa,
                                                                   0                                as rv13_summa,
                                                                   0                                as km13_summa,
                                                                   0                                as rv02_summa,
                                                                   0                                as km02_summa,
                                                                   0                                as rv14_summa,
                                                                   0                                as km14_summa,
                                                                   0                                as rv16_summa,
                                                                   0                                as km16_summa,
                                                                   0                                as rv23_summa,
                                                                   0                                as km23_summa,

                                                                   0                                as rv29_summa,
                                                                   0                                as km29_summa
                                                               from
                                                                   params p,
                                                                          po_

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
                                                                           coalesce((
                                                                                        select
                                                                                            sum(po_k.summa) as summa
                                                                                        from
                                                                                            po11_korr po_k
                                                                                        where
                                                                                              po_k.pv_kaart_id = po_.pv_kaart_id
                                                                                          and po_k.kpv >= po_.rv13_kpv
                                                                                    ), 0)        as rv11_summa,
                                                                           rv13_summa            as rv13_summa,
                                                                           (
                                                                               SELECT
                                                                                   kulum
                                                                               FROM
                                                                                   libs.get_pv_kaart_jaak(po_.pv_kaart_id, po_.rv13_kpv)
                                                                           )                     as km13_summa,
                                                                           0                     as rv02_summa,
                                                                           0                     as km02_summa,
                                                                           case
                                                                               when po_.rv14_prev_rv = '13'
                                                                                   then -1 * po_.rv14_prev_summa
                                                                               end               as rv14_summa,
                                                                           0                     as km14_summa,
                                                                           0                     as rv16_summa,
                                                                           0                     as km16_summa,
                                                                           0                     as rv23_summa,
                                                                           0                     as km23_summa,

                                                                           0                     as rv29_summa,
                                                                           0                     as km29_summa
                                                                       from
                                                                           po_

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
                                                                   0                                      as km29_summa
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
                                                                           coalesce((
                                                                                        select
                                                                                            sum(po_k.summa) as summa
                                                                                        from
                                                                                            po11_korr po_k
                                                                                        where
                                                                                              po_k.pv_kaart_id = po_.pv_kaart_id
                                                                                          and po_k.kpv >= po_.rv14_kpv
                                                                                    ), 0)                 as rv11_summa,
                                                                           0                              as rv13_summa,
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
                                                                           0                              as km29_summa
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
                                                                                   po_.rv14_kpv) as konto,
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
                                                                           0                     as km29_summa
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
                                                                           )               as km29_summa
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
                                                                           0                                                   as km23_summa,
                                                                           0                                                   as rv29_summa,
                                                                           0                                                   as km29_summa
                                                                       from
                                                                           po
                                                                       where
                                                                             po.kood3 = '23'
                                                                         and liik in (1, 4, 3)
                                                                   ) rv23_

                                                           )                           rep
                                                               inner join cur_pohivara pv on pv.id = rep.pv_kaart_id
                                                       order by
                                                           pv_kaart_id, rv00_summa desc, konto
                                                   )
                                    select
                                        r.pv_kaart_id,
                                        r.konto,
                                        string_agg(selg, ',')            as selg,
                                        sum(r.rv00_summa)                as rv00_summa,
                                        sum(r.km00_summa)                as km00_summa,
                                        sum(r.rv02_summa)                as rv02_summa,
                                        sum(r.km02_summa)                as km02_summa,
                                        sum(r.rv11_summa)                as rv11_summa,
                                        sum(r.rv13_summa)                as rv13_summa,
                                        sum(r.km13_summa)                as km13_summa,
                                        sum(r.rv14_summa)                as rv14_summa,
                                        sum(r.km14_summa)                as km14_summa,
                                        sum(r.rv16_summa)                as rv16_summa,
                                        sum(r.km16_summa)                as km16_summa,
                                        sum(r.rv23_summa)                as rv23_summa,
                                        sum(r.km23_summa)                as km23_summa,
                                        sum(r.rv29_summa)                as rv29_summa,
                                        sum(r.km29_summa)                as km29_summa,
                                        sum(r.rv00_summa + r.rv13_summa + r.rv14_summa + r.rv16_summa +
                                            r.rv29_summa - r.rv23_summa) as rv_lopp_summa,
                                        sum(r.km00_summa + r.rv11_summa + r.km16_summa + r.km29_summa -
                                            r.km23_summa)                as rv_lopp_kulum

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

/*
with
    test as (
                with
                    sum as (
                               SELECT *
                               FROM
                                   docs.pv_rv_kaibe_aruanne('2024-01-01', '2024-09-30' :: DATE, 63, 1, '{
                                     "kood": ""
                                   }'::jsonb)
                               where
                                   kood in
                                   ('00790-01KM', '00536-01KM', '00536-02KK', '00790-01KM', '02292-02PH', '00171-02KK',
                                    '00156-01PM',
                                    '00542-02KK', '02322-14', '00557-02PK', '00480-01PM', '00480-02PK', '02323-04',
                                    '02292-02PH', '00171-02KK', '02292-03PH', '00116-01KM', '00116-02KK', '00555-02PK',
                                    '00536-02KK')
                    )
                select
                    sum.*,
                    case
                        when kood = '02292-02PH' and konto = '155100' and sum.alg_soetmaks <> 221707.21 then 'RV00'
                        when kood = '02292-02PH' and konto = '155100' and sum.kb_pv_rv13 <> -221707.21
                            then '155100(RV13)'
                        when kood = '02292-02PH' and konto = '154000' and sum.kb_pv_rv13 <> 221707.21
                            then '154000(RV13)'
                        when kood = '02292-02PH' and konto = '154000' and sum.kb_kulum_rv13 <> 51012.57
                            then '154000(KM13)'
                        when kood = '02292-02PH' and konto = '154000' and sum.kb_pv_rv02 <> 221707.21
                            then '154000(RV02)'
                        when kood = '02292-02PH' and konto = '155100' and sum.alg_kulum <> 49857.82 then '155100(KM00)'
                        when kood = '02292-02PH' and konto = '155100' and sum.kb_kulum_rv11 <> 1154.75
                            then '155100(RV11)'
                        when kood = '02292-02PH' and konto = '154000' and sum.alg_kulum <> 0 then '154000(KM00)'
                        when kood = '02292-02PH' and konto = '154000' and sum.kb_kulum_rv11 <> 461.9 then '154000(RV11)'
                        when kood = '02292-02PH' and konto = '154000' and sum.lopp_soetmaks <> 0
                            then '154000(LOPP_SUMMA)'
                        when kood = '02292-02PH' and konto = '155100' and sum.lopp_soetmaks <> 0
                            then '155100(LOPP_SUMMA)'
                        when kood = '02292-02PH' and konto = '154000' and sum.lopp_kulum <> 0 then '154000(LOPP_KULUM)'
                        when kood = '02292-02PH' and konto = '155100' and sum.lopp_kulum <> 0 then '155100(LOPP_KULUM)'
                        -- 00156-01PM
                        when kood = '00156-01PM' and konto = '155000' and alg_soetmaks <> 83.09 then '155000(RV00)'
                        when kood = '00156-01PM' and konto = '155000' and kb_pv_rv14 <> 83.09 then '155000(RV14)'
                        when kood = '00156-01PM' and konto = '155000' and kb_pv_rv13 <> -83.09 then '155000(RV13)'
                        when kood = '00156-01PM' and konto = '154000' and alg_soetmaks <> 0 then '154000(RV00)'
                        when kood = '00156-01PM' and konto = '154000' and kb_pv_rv14 <> -83.09 then '154000(RV14)'
                        when kood = '00156-01PM' and konto = '154000' and kb_pv_rv13 <> 83.09 then '154000(RV13)'
                        when kood = '00156-01PM' and konto = '155000' and sum.lopp_soetmaks <> 83.09
                            then '155000(LOPP_SUMMA)'
                        when kood = '00156-01PM' and konto = '154000' and sum.lopp_soetmaks <> 0
                            then '154000(LOPP_SUMMA)'
                        when kood = '00156-01PM' and konto = '155000' and sum.lopp_kulum <> 0
                            then '155000(LOPP_KULUM)'
                        when kood = '00156-01PM' and konto = '154000' and sum.lopp_kulum <> 0
                            then '154000(LOPP_KULUM)'

                        -- 00171-02KK
                        when kood = '00171-02KK' and konto = '154000' and alg_soetmaks <> 21857.78 then '154000(RV00)'
                        when kood = '00171-02KK' and konto = '154000' and kb_pv_rv14 <> -21857.78 then '154000(RV14)'
                        when kood = '00171-02KK' and konto = '155101' and kb_pv_rv14 <> 21857.78 then '155101(RV14)'
                        when kood = '00171-02KK' and konto = '155101' and kb_kulum_rv14 <> 3692.72 then '155101(KM14)'
                        when kood = '00171-02KK' and konto = '154000' and lopp_soetmaks <> 0 then '154000(LOPP_SUMMA)'
                        when kood = '00171-02KK' and konto = '155101' and lopp_soetmaks <> 21857.78
                            then '155101(LOPP_SUMMA)'
                        when kood = '00171-02KK' and konto = '154000' and lopp_kulum <> 0 then '154000(LOPP_KULUM)'
                        when kood = '00171-02KK' and konto = '155101' and lopp_kulum <> 3811.30
                            then '155101(LOPP_KULUM)'

                        -- 00542-02KK
                        when kood = '00542-02KK' and konto = '154000' and alg_soetmaks <> 18694.16 then '154000(RV00)'
                        when kood = '00542-02KK' and konto = '154000' and kb_pv_rv14 <> -18694.16 then '154000(RV14)'
                        when kood = '00542-02KK' and konto = '155101' and kb_pv_rv14 <> 18694.16 then '155101(RV14)'
                        when kood = '00542-02KK' and konto = '155101' and kb_kulum_rv14 <> 3804.38 then '155101(KM14)'
                        when kood = '00542-02KK' and konto = '154000' and alg_kulum <> 3701.54 then '154000(RV00)'
                        when kood = '00542-02KK' and konto = '154000' and kb_kulum_rv11 <> 102.84 then '154000(RV11)'
                        when kood = '00542-02KK' and konto = '154000' and lopp_soetmaks <> 0 then '154000(LOPP_SUMMA)'
                        when kood = '00542-02KK' and konto = '155101' and lopp_soetmaks <> 18694.16
                            then '155101(LOPP_SUMMA)'
                        when kood = '00542-02KK' and konto = '154000' and lopp_kulum <> 0 then '154000(LOPP_KULUM)'
                        when kood = '00542-02KK' and konto = '155101' and lopp_kulum <> 3855.80
                            then '155101(LOPP_KULUM)'
-- 02322-14
                        when kood = '02322-14' and konto = '155400' and alg_soetmaks <> 0 then '155400 (RV00)'
                        when kood = '02322-14' and konto = '155400' and kb_pv_rv16 <> 20448.37 then '155400(RV16)'
                        when kood = '02322-14' and konto = '155400' and kb_kulum_rv16 <> 20448.37 then '155400(KM16)'
                        when kood = '02322-14' and konto = '155400' and lopp_soetmaks <> 20448.37
                            then '155400(LOPP_SUMMA)'
                        when kood = '02322-14' and konto = '155400' and lopp_kulum <> 20448.37 then '155400(LOPP_KULUM)'
                        -- 00480-01PM
                        when kood = '00480-01PM' and konto = '154000' then '154000 (KONTO)'
                        when kood = '00480-01PM' and konto = '155000' and alg_soetmaks <> 108.65 then '155000 (RV00)'
                        when kood = '00480-01PM' and konto = '155000' and lopp_soetmaks <> 108.65
                            then '155000 (LOPP_SUMMA)'
                        -- ' 00536-01KM','00536-02KK','00790-01KM'
                        when kood = '00536-01KM' and konto is null then 'KONTO'
                        when kood = '00536-01KM' and konto = '154000' and alg_soetmaks <> 98.81 then '154000(RV00)'
                        when kood = '00536-01KM' and konto = '154000' and kb_pv_rv14 <> -98.81 then '154000(RV14)'
                        when kood = '00536-01KM' and konto = '155000' and kb_pv_rv14 <> 98.81 then '155000(RV14)'
                        when kood = '00536-01KM' and konto = '155000' and lopp_soetmaks <> 98.81
                            then '155000(LOPP_SUMMA)'
                        when kood = '00536-01KM' and konto = '154000' and lopp_soetmaks <> 0 then '154000(LOPP_SUMMA)'
                        -- 02323-04
                        when kood = '02323-04' and konto = '155100' and alg_soetmaks <> 0 then '155100(RV00)'
                        when kood = '02323-04' and konto = '155100' and kb_pv_rv16 <> 12566.37 then '155100(RV16)'
                        when kood = '02323-04' and konto = '155100' and kb_kulum_rv16 <> 6531.44 then '155100(KM16)'
                        when kood = '02323-04' and konto = '155100' and lopp_soetmaks <> 12566.37
                            then '155100(LOPP_SUMMA)'
                        when kood = '02323-04' and konto = '155100' and lopp_kulum <> 6636.16 then '155100(LOPP_KULUM)'
-- 02292-02PH
                        when kood = '02292-02PH' and konto = '155100' and alg_soetmaks <> 221707.21 then '155100(RV00)'
                        when kood = '02292-02PH' and konto = '155100' and alg_kulum <> 49857.82 then '155100(KM00)'
                        when kood = '02292-02PH' and konto = '155100' and kb_pv_rv13 <> -221707.21 then '155100(RV13)'
                        when kood = '02292-02PH' and konto = '154000' and kb_pv_rv13 <> 221707.21 then '154000(RV13)'
                        when kood = '02292-02PH' and konto = '154000' and kb_kulum_rv13 <> 51012.57 then '154000(KM13)'
                        when kood = '02292-02PH' and konto = '154000' and lopp_soetmaks <> 0 then '154000(LOPP_SUMMA)'
                        when kood = '02292-02PH' and konto = '154000' and lopp_kulum <> 0 then '154000(LOPP_KULUM)'
                        when kood = '02292-02PH' and konto = '154000' and kb_kulum_rv02 <> 51474.47 then '154000(KM02)'
                        when kood = '02292-02PH' and konto = '154000' and kb_pv_rv02 <> 221707.21 then '154000(Rv02)'
-- 00171-02KK
                        when kood = '00171-02KK' and konto = '154000' and alg_soetmaks <> 21857.78 then '154000(RV00)'
                        when kood = '00171-02KK' and konto = '154000' and alg_kulum <> 3658.84 then '154000(KM00)'
                        when kood = '00171-02KK' and konto = '154000' and kb_pv_rv14 <> -21857.78 then '154000(RV14)'
                        when kood = '00171-02KK' and konto = '155101' and kb_pv_rv14 <> 21857.78 then '155101(RV14)'
                        when kood = '00171-02KK' and konto = '155101' and kb_kulum_rv14 <> 3692.72 then '155101(KM14)'
                        when kood = '00171-02KK' and konto = '155101' and lopp_soetmaks <> 21857.78
                            then '155101(LOPP_summa)'
                        when kood = '00171-02KK' and konto = '155101' and lopp_kulum <> 3811.3 then '155101(LOPP_kulum)'
-- 02292-03PH
                        when kood = '02292-03PH' and konto = '155100' and alg_soetmaks <> 12362.77 then '155100(RV00)'
                        when kood = '02292-03PH' and konto = '155100' and alg_kulum <> 7916.04 then '155100(KM00)'
                        when kood = '02292-03PH' and konto = '155100' and kb_pv_rv13 <> -12362.77 then '155100(RV13)'
                        when kood = '02292-03PH' and konto = '154000' and kb_pv_rv13 <> 12362.77 then '154000(RV13)'
                        when kood = '02292-03PH' and konto = '154000' and kb_kulum_rv13 <> 8122.09 then '154000(KM13)'
                        when kood = '02292-03PH' and konto = '154000' and kb_kulum_rv02 <> 8204.51 then '154000(KM02)'
                        when kood = '02292-03PH' and konto = '154000' and kb_pv_rv02 <> 12362.77 then '154000(Rv02)'
                        when kood = '02292-03PH' and konto = '154000' and lopp_soetmaks <> 0 then '154000(LOPP_SUMMA)'
                        when kood = '02292-03PH' and konto = '154000' and lopp_kulum <> 0 then '154000(LOPP_KULUM)'
-- '00116-01KM'
                        when kood = '00116-01KM' and konto = '154000' and alg_soetmaks <> 38.35 then '154000(RV00)'
                        when kood = '00116-01KM' and konto = '154000' and kb_pv_rv02 <> 38.35 then '154000(RV02)'
                        -- '00116-02KK'
                        when kood = '00116-02KK' and konto = '154000' and alg_soetmaks <> 11216.49 then '154000(RV00)'
                        when kood = '00116-02KK' and konto = '154000' and kb_pv_rv02 <> 11216.49 then '154000(RV02)'
                        when kood = '00116-02KK' and konto = '154000' and kb_kulum_rv02 <> 2000.21 then '154000(KM02)'
                        -- 00555-02PK
                        when kood = '00555-02PK' and konto = '155101' and alg_soetmaks <> 10353.69 then '155100(RV00)'
                        when kood = '00555-02PK' and konto = '155101' and alg_kulum <> 3204.69 then '155100(KM00)'
                        when kood = '00555-02PK' and konto = '155101' and kb_pv_rv13 <> -10353.69 then '155100(RV13)'
                        when kood = '00555-02PK' and konto = '155101' and kb_kulum_rv13 <> -3249.21 then '155100(KM13)'
                        when kood = '00555-02PK' and konto = '154000' and kb_pv_rv13 <> 10353.69 then '154000(RV13)'
                        when kood = '00555-02PK' and konto = '154000' and kb_kulum_rv13 <> 3249.21 then '154000(KM13)'
                        when kood = '00555-02PK' and konto = '154000' and lopp_soetmaks <> 0 then '154000(LOPP_SUMMA)'
                        when kood = '00555-02PK' and konto = '154000' and lopp_kulum <> 0 then '154000(LOPP_KULUM)'
-- 00536-02KK
                        when kood = '00536-02KK' and konto = '154000' and alg_soetmaks <> 17831.35 then '154000(RV00)'
                        when kood = '00536-02KK' and konto = '154000' and alg_kulum <> 3561.79 then '154000(KM00)'
                        when kood = '00536-02KK' and konto = '154000' and kb_pv_rv14 <> -17831.35 then '154000(RV14)'
                        when kood = '00536-02KK' and konto = '154000' and kb_kulum_rv14 <> -3594.77 then '154000(KM14)'
                        when kood = '00536-02KK' and konto = '155101' and kb_pv_rv14 <> 17831.35 then '155101(RV14)'
                        when kood = '00536-02KK' and konto = '155101' and kb_kulum_rv14 <> 3594.77 then '155101(KM14)'
                        when kood = '00536-02KK' and konto = '155101' and lopp_soetmaks <> 17831.35
                            then '155101(LOPP_summa)'
                        when kood = '00536-02KK' and konto = '155101' and lopp_kulum <> 3710.2 then '155101(LOPP_kulum)'

                        else ''
                        end as test
                from
                    sum
    )

SELECT
    test,
    *
FROM
    test
--where
--    kood in ('00116-01KM', '00116-02KK', '00555-02PK','00536-02KK')
order by
    kood
;
*/

/*
SELECT *
FROM (
) qry
WHERE kood ILIKE '00790-01KM%'
SELECT
*
      FROM docs.pv_rv_kaibe_aruanne('2024-01-01', '2024-11-30' :: DATE, 130, 1, '{"kood":"00480-02PK"}'::jsonb)



 */