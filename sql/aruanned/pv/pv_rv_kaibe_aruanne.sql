DROP FUNCTION IF EXISTS docs.pv_rv_kaibe_aruanne(DATE, DATE, INTEGER, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.pv_rv_kaibe_aruanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
                                                    l_kond INTEGER DEFAULT NULL, l_params JSONB DEFAULT NULL::JSONB)
    RETURNS TABLE (
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
WITH params AS (
    SELECT l_kpv1              AS kpv1,
           l_kpv2              AS kpv2,
           l_params ->> 'kood' AS kood
),

     rekv_ids AS (
         SELECT rekv_id
         FROM get_asutuse_struktuur(l_rekvid)
         WHERE rekv_id = CASE
                             WHEN l_kond = 1
                                 THEN rekv_id
                             ELSE l_rekvid END),
     pv_kaardid AS (
         SELECT l.id                                                                              AS pv_kaart_id,
                l.rekvid,
                (SELECT soetmaks FROM libs.get_pv_kaart_jaak(l.id, params.kpv1))                  AS alg_soetmaks,
                (SELECT kulum FROM libs.get_pv_kaart_jaak(l.id, params.kpv1))                     AS alg_kulum,
                CASE
                    WHEN l.status = 2 THEN 0
                    ELSE (SELECT soetmaks FROM libs.get_pv_kaart_jaak(l.id, params.kpv2 + 1)) END AS lopp_soetmaks,
                CASE
                    WHEN l.status = 2 THEN 0
                    ELSE (SELECT kulum FROM libs.get_pv_kaart_jaak(l.id, params.kpv2 + 1)) END    AS lopp_kulum,
                l.kood::VARCHAR(20),
                l.nimetus::VARCHAR(254),
                coalesce((l.properties::JSONB ->> 'pindala')::NUMERIC(12, 4), 0)::NUMERIC(12, 4)  AS pindala,
                (l.properties::JSONB ->> 'kulum')::NUMERIC(12, 2)                                 AS kulumi_maar,
                (l.properties::JSONB ->> 'soetkpv'):: DATE                                        AS esimise_kpv,
                (l.properties :: JSONB ->> 'konto')::VARCHAR(20)                                  AS konto,
                l.properties :: JSONB -> 'vastisikid'                                             AS vastisik_id,
                grupp.nimetus::VARCHAR(254)                                                       AS grupp
         FROM libs.library l
                  JOIN libs.library grupp ON (l.properties :: JSONB -> 'gruppid') = to_jsonb(grupp.id),
              params
         WHERE l.library = 'POHIVARA'
           AND l.status <> 3
           AND l.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND ((l.properties :: JSONB ->> 'mahakantud')::DATE IS NULL OR
                (l.properties :: JSONB ->> 'mahakantud')::DATE >= params.kpv1)
           AND (l.properties :: JSONB ->> 'soetkpv') :: DATE <= params.kpv2
           AND (params.kood IS NULL OR l.kood ILIKE coalesce(params.kood, '') || '%')
     ),
     po AS (
         SELECT *
         FROM docs.pv_oper pv,
              params
         WHERE pv_kaart_id IN (
             SELECT pv_kaart_id
             FROM pv_kaardid
         )
           AND kpv >= params.kpv1
           AND kpv <= params.kpv2
     ),
     po_rv11 AS (
         SELECT po.pv_kaart_id                AS pv_kaart_id,
                sum(po.summa)::NUMERIC(12, 2) AS kb_kulum_rv11
         FROM po
         WHERE po.liik = 2
           AND (coalesce(po.kood3, '11') = '11' OR empty(po.kood3))
         GROUP BY pv_kaart_id
     ),
     qryKaibed AS (
         SELECT pv_kaart_id,
                sum(alg_soetmaks)  AS alg_soetmaks,
                sum(alg_kulum)     AS alg_kulum,
                sum(kb_pv_rv01)    AS kb_pv_rv01,
                sum(kb_pv_rv02)    AS kb_pv_rv02,
                sum(kb_kulum_rv02) AS kb_kulum_rv02,
                sum(kb_kulum_rv11) AS kb_kulum_rv11,
                sum(kb_pv_rv12)    AS kb_pv_rv12,
                sum(kb_kulum_rv12) AS kb_kulum_rv12,
                sum(kb_pv_rv13)    AS kb_pv_rv13,
                sum(kb_kulum_rv13) AS kb_kulum_rv13,
                sum(kb_pv_rv14)    AS kb_pv_rv14,
                sum(kb_kulum_rv14) AS kb_kulum_rv14,
                sum(kb_pv_rv15)    AS kb_pv_rv15,
                sum(kb_kulum_rv15) AS kb_kulum_rv15,
                sum(kb_pv_rv16)    AS kb_pv_rv16,
                sum(kb_kulum_rv16) AS kb_kulum_rv16,
                sum(kb_pv_rv17)    AS kb_pv_rv17,
                sum(kb_kulum_rv17) AS kb_kulum_rv17,
                sum(kb_pv_rv19)    AS kb_pv_rv19,
                sum(kb_pv_rv21)    AS kb_pv_rv21,
                sum(kb_pv_rv23)    AS kb_pv_rv23,
                sum(kb_pv_rv24)    AS kb_pv_rv24,
                sum(kb_kulum_rv24) AS kb_kulum_rv24,
                sum(kb_pv_rv29)    AS kb_pv_rv29,
                sum(kb_kulum_rv29) AS kb_kulum_rv29


         FROM (
                  SELECT l.pv_kaart_id     AS pv_kaart_id,
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
                         0::NUMERIC(12, 2) AS kb_kulum_rv29

                  FROM pv_kaardid l
                  UNION ALL
                  -- rv01
                  SELECT po.pv_kaart_id           AS pv_kaart_id,
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
                         0::NUMERIC(12, 2)        AS kb_kulum_rv29
                  FROM po
                  WHERE po.liik = 1
                    AND (coalesce(po.kood3, '01') = '01'
                      OR empty(po.kood3))
                  UNION ALL
                  -- rv02
                  SELECT po.pv_kaart_id                 AS pv_kaart_id,
                         0:: NUMERIC(12, 2)             AS alg_soetmaks,
                         0:: NUMERIC(12, 2)             AS alg_kulum,
                         0::NUMERIC(12, 2)              AS kb_pv_rv01,
                         po.summa::NUMERIC(12, 2)       AS kb_pv_rv02,
                         (pk.alg_kulum + coalesce(k.kb_kulum_rv11, 0))::NUMERIC(12, 2)  AS kb_kulum_rv02,
                         0::NUMERIC(12, 2)              AS kb_kulum_rv11,
                         0::NUMERIC(12, 2)              AS kb_pv_rv12,
                         0::NUMERIC(12, 2)              AS kb_kulum_rv12,
                         0::NUMERIC(12, 2)              AS kb_pv_rv13,
                         0::NUMERIC(12, 2)              AS kb_kulum_rv13,
                         0::NUMERIC(12, 2)              AS kb_pv_rv14,
                         0::NUMERIC(12, 2)              AS kb_kulum_rv14,
                         0::NUMERIC(12, 2)              AS kb_pv_rv15,
                         0::NUMERIC(12, 2)              AS kb_kulum_rv15,
                         0::NUMERIC(12, 2)              AS kb_pv_rv16,
                         0::NUMERIC(12, 2)              AS kb_kulum_rv16,
                         0::NUMERIC(12, 2)              AS kb_pv_rv17,
                         0::NUMERIC(12, 2)              AS kb_kulum_rv17,
                         0::NUMERIC(12, 2)              AS kb_pv_rv19,
                         0::NUMERIC(12, 2)              AS kb_pv_rv21,
                         0::NUMERIC(12, 2)              AS kb_pv_rv23,
                         0::NUMERIC(12, 2)              AS kb_pv_rv24,
                         0::NUMERIC(12, 2)              AS kb_kulum_rv24,
                         0::NUMERIC(12, 2)              AS kb_pv_rv29,
                         0::NUMERIC(12, 2)              AS kb_kulum_rv29
                  FROM po
                           INNER JOIN pv_kaardid pk ON pk.pv_kaart_id = po.pv_kaart_id
                           LEFT OUTER JOIN po_rv11 k ON k.pv_kaart_id = pk.pv_kaart_id
                  WHERE po.liik = 4
                    AND coalesce(po.kood3, '') = '02'
                  UNION ALL
                  -- rv11
                  SELECT po.pv_kaart_id           AS pv_kaart_id,
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
                         0::NUMERIC(12, 2)        AS kb_kulum_rv29
                  FROM po
                  WHERE po.liik = 2
                    AND (coalesce(po.kood3, '11') = '11' OR empty(po.kood3))
                  UNION ALL
                  -- rv12
                  SELECT po.pv_kaart_id                                                AS pv_kaart_id,
                         0:: NUMERIC(12, 2)                                            AS alg_soetmaks,
                         0:: NUMERIC(12, 2)                                            AS alg_kulum,
                         0::NUMERIC(12, 2)                                             AS kb_pv_rv01,
                         0::NUMERIC(12, 2)                                             AS kb_pv_rv02,
                         0 ::NUMERIC(12, 2)                                            AS kb_kulum_rv02,
                         0::NUMERIC(12, 2)                                             AS kb_kulum_rv11,
                         po.summa::NUMERIC(12, 2)                                      AS kb_pv_rv12,
                         (pk.alg_kulum + coalesce(k.kb_kulum_rv11, 0))::NUMERIC(12, 2) AS kb_kulum_rv12,
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
                         0::NUMERIC(12, 2)                                             AS kb_kulum_rv29
                  FROM po
                           INNER JOIN pv_kaardid pk ON pk.pv_kaart_id = po.pv_kaart_id
                           LEFT OUTER JOIN po_rv11 k ON k.pv_kaart_id = pk.pv_kaart_id
                  WHERE po.liik = 4
                    AND coalesce(po.kood3, '') = '12'
                  UNION ALL
                  -- rv13
                  SELECT po.pv_kaart_id                AS pv_kaart_id,
                         0:: NUMERIC(12, 2)            AS alg_soetmaks,
                         0:: NUMERIC(12, 2)            AS alg_kulum,
                         0::NUMERIC(12, 2)             AS kb_pv_rv01,
                         0::NUMERIC(12, 2)             AS kb_pv_rv02,
                         0 ::NUMERIC(12, 2)            AS kb_kulum_rv02,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv11,
                         0::NUMERIC(12, 2)             AS kb_pv_rv12,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv12,
                         po.summa::NUMERIC(12, 2)      AS kb_pv_rv13,
                         pk.lopp_kulum::NUMERIC(12, 2) AS kb_kulum_rv13,
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
                         0::NUMERIC(12, 2)             AS kb_pv_rv24,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv24,
                         0::NUMERIC(12, 2)             AS kb_pv_rv29,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv29
                  FROM po
                           INNER JOIN pv_kaardid pk ON pk.pv_kaart_id = po.pv_kaart_id
                  WHERE po.liik = 6
                    AND coalesce(po.kood3, '') = '13'
                  UNION ALL
                  -- rv14
                  SELECT po.pv_kaart_id                AS pv_kaart_id,
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
                         po.summa::NUMERIC(12, 2)      AS kb_pv_rv14,
                         pk.lopp_kulum::NUMERIC(12, 2) AS kb_kulum_rv14,
                         0::NUMERIC(12, 2)             AS kb_pv_rv15,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv15,
                         0::NUMERIC(12, 2)             AS kb_pv_rv16,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv16,
                         0::NUMERIC(12, 2)             AS kb_pv_rv17,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv17,
                         0::NUMERIC(12, 2)             AS kb_pv_rv19,
                         0::NUMERIC(12, 2)             AS kb_pv_rv21,
                         0::NUMERIC(12, 2)             AS kb_pv_rv23,
                         0::NUMERIC(12, 2)             AS kb_pv_rv24,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv24,
                         0::NUMERIC(12, 2)             AS kb_pv_rv29,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv29
                  FROM po
                           INNER JOIN pv_kaardid pk ON pk.pv_kaart_id = po.pv_kaart_id
                  WHERE po.liik = 6
                    AND coalesce(po.kood3, '') = '14'
                  UNION ALL
                  -- rv15
                  SELECT po.pv_kaart_id                AS pv_kaart_id,
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
                         po.summa::NUMERIC(12, 2)      AS kb_pv_rv15,
                         (pk.alg_kulum + coalesce(k.kb_kulum_rv11, 0))::NUMERIC(12, 2) AS kb_kulum_rv15,
                         0::NUMERIC(12, 2)             AS kb_pv_rv16,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv16,
                         0::NUMERIC(12, 2)             AS kb_pv_rv17,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv17,
                         0::NUMERIC(12, 2)             AS kb_pv_rv19,
                         0::NUMERIC(12, 2)             AS kb_pv_rv21,
                         0::NUMERIC(12, 2)             AS kb_pv_rv23,
                         0::NUMERIC(12, 2)             AS kb_pv_rv24,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv24,
                         0::NUMERIC(12, 2)             AS kb_pv_rv29,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv29
                  FROM po
                           INNER JOIN pv_kaardid pk ON pk.pv_kaart_id = po.pv_kaart_id
                           LEFT OUTER JOIN po_rv11 k ON k.pv_kaart_id = pk.pv_kaart_id

                  WHERE po.liik = 4
                    AND coalesce(po.kood3, '') = '15'
                  UNION ALL
                  -- rv16
                  SELECT po.pv_kaart_id               AS pv_kaart_id,
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
                         po.summa::NUMERIC(12, 2)     AS kb_pv_rv16,
                         pk.alg_kulum::NUMERIC(12, 2) AS kb_kulum_rv16,
                         0::NUMERIC(12, 2)            AS kb_pv_rv17,
                         0::NUMERIC(12, 2)            AS kb_kulum_rv17,
                         0::NUMERIC(12, 2)            AS kb_pv_rv19,
                         0::NUMERIC(12, 2)            AS kb_pv_rv21,
                         0::NUMERIC(12, 2)            AS kb_pv_rv23,
                         0::NUMERIC(12, 2)            AS kb_pv_rv24,
                         0::NUMERIC(12, 2)            AS kb_kulum_rv24,
                         0::NUMERIC(12, 2)            AS kb_pv_rv29,
                         0::NUMERIC(12, 2)            AS kb_kulum_rv29
                  FROM po
                           INNER JOIN pv_kaardid pk
                                      ON pk.pv_kaart_id = po.pv_kaart_id
                  WHERE po.liik = 1
                    AND COALESCE(po.kood3
                            , '') = '16'
                  UNION ALL
                  -- rv17
                  SELECT po.pv_kaart_id               AS pv_kaart_id,
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
                         0::NUMERIC(12, 2)            AS kb_kulum_rv29
                  FROM po
                           INNER JOIN pv_kaardid pk
                                      ON pk.pv_kaart_id = po.pv_kaart_id
                  WHERE po.liik = 1
                    AND COALESCE(po.kood3
                            , '') = '17'
                  UNION ALL
                  -- rv19
                  SELECT po.pv_kaart_id           AS pv_kaart_id,
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
                         0::NUMERIC(12, 2)        AS kb_kulum_rv29
                  FROM po
                  WHERE po.liik IN (1, 3)
                    AND COALESCE(po.kood3
                            , '') = '19'
                  UNION ALL
                  -- rv21
                  SELECT po.pv_kaart_id           AS pv_kaart_id,
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
                         0::NUMERIC(12, 2)        AS kb_kulum_rv29
                  FROM po
                  WHERE po.liik IN (1, 3)
                    AND COALESCE(po.kood3
                            , '') = '21'
                  UNION ALL
                  -- rv23
                  SELECT po.pv_kaart_id           AS pv_kaart_id,
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
                         0::NUMERIC(12, 2)        AS kb_pv_rv21,
                         po.summa::NUMERIC(12, 2) AS kb_pv_rv23,
                         0::NUMERIC(12, 2)        AS kb_pv_rv24,
                         0::NUMERIC(12, 2)        AS kb_kulum_rv24,
                         0::NUMERIC(12, 2)        AS kb_pv_rv29,
                         0::NUMERIC(12, 2)        AS kb_kulum_rv29
                  FROM po
                  WHERE po.liik IN (1, 3)
                    AND COALESCE(po.kood3
                            , '') = '23'
                  UNION ALL
                  -- rv24
                  SELECT po.pv_kaart_id                AS pv_kaart_id,
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
                         0::NUMERIC(12, 2)             AS kb_kulum_rv15,
                         0::NUMERIC(12, 2)             AS kb_pv_rv16,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv16,
                         0::NUMERIC(12, 2)             AS kb_pv_rv17,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv17,
                         0::NUMERIC(12, 2)             AS kb_pv_rv19,
                         0::NUMERIC(12, 2)             AS kb_pv_rv21,
                         0::NUMERIC(12, 2)             AS kb_pv_rv23,
                         po.summa::NUMERIC(12, 2)      AS kb_pv_rv24,
                         (pk.alg_kulum + coalesce(k.kb_kulum_rv11, 0))::NUMERIC(12, 2)  AS kb_kulum_rv24,
                         0::NUMERIC(12, 2)             AS kb_pv_rv29,
                         0::NUMERIC(12, 2)             AS kb_kulum_rv29
                  FROM po
                           INNER JOIN pv_kaardid pk
                                      ON pk.pv_kaart_id = po.pv_kaart_id
                           LEFT OUTER JOIN po_rv11 k ON k.pv_kaart_id = pk.pv_kaart_id

                  WHERE po.liik = 4
                    AND COALESCE(po.kood3, '') = '24'
                  UNION ALL
                  -- rv29
                  SELECT po.pv_kaart_id                                                                       AS pv_kaart_id,
                         0:: NUMERIC(12, 2)                                                                   AS alg_soetmaks,
                         0:: NUMERIC(12, 2)                                                                   AS alg_kulum,
                         0::NUMERIC(12, 2)                                                                    AS kb_pv_rv01,
                         0::NUMERIC(12, 2)                                                                    AS kb_pv_rv02,
                         0 ::NUMERIC(12, 2)                                                                   AS kb_kulum_rv02,
                         0::NUMERIC(12, 2)                                                                    AS kb_kulum_rv11,
                         0::NUMERIC(12, 2)                                                                    AS kb_pv_rv12,
                         0::NUMERIC(12, 2)                                                                    AS kb_kulum_rv12,
                         0::NUMERIC(12, 2)                                                                    AS kb_pv_rv13,
                         0::NUMERIC(12, 2)                                                                    AS kb_kulum_rv13,
                         0::NUMERIC(12, 2)                                                                    AS kb_pv_rv14,
                         0::NUMERIC(12, 2)                                                                    AS kb_kulum_rv14,
                         0::NUMERIC(12, 2)                                                                    AS kb_pv_rv15,
                         0::NUMERIC(12, 2)                                                                    AS kb_kulum_rv15,
                         0::NUMERIC(12, 2)                                                                    AS kb_pv_rv16,
                         0::NUMERIC(12, 2)                                                                    AS kb_kulum_rv16,
                         0::NUMERIC(12, 2)                                                                    AS kb_pv_rv17,
                         0::NUMERIC(12, 2)                                                                    AS kb_kulum_rv17,
                         0::NUMERIC(12, 2)                                                                    AS kb_pv_rv19,
                         0::NUMERIC(12, 2)                                                                    AS kb_pv_rv21,
                         0::NUMERIC(12, 2)                                                                    AS kb_pv_rv23,
                         0::NUMERIC(12, 2)                                                                    AS kb_pv_rv24,
                         0::NUMERIC(12, 2)                                                                    AS kb_kulum_rv24,
                         CASE WHEN po.liik = 1 THEN 1 ELSE -1 END * po.summa::NUMERIC(12, 2)                  AS kb_pv_rv29,
                         CASE WHEN po.liik = 1 THEN pk.alg_kulum ELSE -1 * ((pk.alg_kulum + coalesce(k.kb_kulum_rv11, 0))::NUMERIC(12, 2)) END ::NUMERIC(12, 2) AS kb_kulum_rv29
                  FROM po
                           INNER JOIN pv_kaardid pk
                                      ON pk.pv_kaart_id = po.pv_kaart_id
                           LEFT OUTER JOIN po_rv11 k ON k.pv_kaart_id = pk.pv_kaart_id

                  WHERE po.liik IN (1, 4)
                    AND COALESCE(po.kood3, '') = '29'
              ) kaibed
         GROUP BY pv_kaart_id
     )
SELECT pk.kood::VARCHAR(20),
       pk.nimetus:: VARCHAR(254),
       pk.konto:: VARCHAR(20),
       pk.grupp::VARCHAR(254),
       pk.esimise_kpv:: DATE,
       pk.alg_soetmaks:: NUMERIC(12, 2),
       pk.alg_kulum:: NUMERIC(12, 2),
       -- pv osa
       kb.kb_pv_rv01:: NUMERIC(12, 2),    -- Soetused ja parendused
       kb.kb_pv_rv19:: NUMERIC(12, 2),    -- Saadud mitterahaline sihtfinantseerimine
       kb.kb_pv_rv14:: NUMERIC(12, 2),    -- Üleviimine kinnisvarainvesteeringute grupist materiaalse põhivara gruppi
       kb.kb_pv_rv13:: NUMERIC(12, 2),    -- Üleviimine materiaalse põhivara grupist kinnisvarainvesteeringute gruppi
       kb.kb_pv_rv15:: NUMERIC(12, 2),    -- Varade mitterahalised siirded (üleandmine)
       kb.kb_pv_rv16:: NUMERIC(12, 2),    -- Varade mitterahalised siirded (saamine)
       kb.kb_pv_rv23:: NUMERIC(12, 2),    -- Ümberklassifitseerimine
       kb.kb_pv_rv17:: NUMERIC(12, 2),    -- Varade üleandmine mitterahalise sissemaksena netovarasse
       kb.kb_pv_rv24:: NUMERIC(12, 2),    -- Mitterahaline sihtfinantseerimine (üleandmine)
       kb.kb_pv_rv29:: NUMERIC(12, 2),    -- Muud mitterahalised kanded varadega
       kb.kb_pv_rv21:: NUMERIC(12, 2),    -- Varade ümberhindlus
       kb.kb_pv_rv02:: NUMERIC(12, 2),    -- Müüdud põhivara
       kb.kb_pv_rv12:: NUMERIC(12, 2),    -- Varade mahakandmine

       pk.lopp_soetmaks:: NUMERIC(12, 2), -- Soetusmaksumus perioodi lõpus
       -- kulum osa
       kb.kb_kulum_rv11:: NUMERIC(12, 2), -- Varade kulum ja allahindlus
       kb.kb_kulum_rv02:: NUMERIC(12, 2), -- Müüdud põhivara
       kb.kb_kulum_rv12:: NUMERIC(12, 2), -- Varade mahakandmine
       kb.kb_kulum_rv14:: NUMERIC(12, 2), -- Üleviimine kinnisvarainvesteeringute grupist materiaalse põhivara gruppi
       kb.kb_kulum_rv13:: NUMERIC(12, 2), -- Üleviimine materiaalse põhivara grupist kinnisvarainvesteeringute gruppi
       kb.kb_kulum_rv15:: NUMERIC(12, 2), -- Varade mitterahalised siirded (üleandmine)
       kb.kb_kulum_rv16:: NUMERIC(12, 2), -- Varade mitterahalised siirded (saamine)
       kb.kb_kulum_rv17:: NUMERIC(12, 2), -- Varade üleandmine mitterahalise sissemaksena netovarasse
       kb.kb_kulum_rv24:: NUMERIC(12, 2), -- Mitterahaline sihtfinantseerimine (üleandmine)
       kb.kb_kulum_rv29:: NUMERIC(12, 2), -- Muud mitterahalised kanded varadega

       lopp_kulum:: NUMERIC(12, 2),
       a.nimetus:: VARCHAR(254) AS vastisik,
       r.nimetus:: VARCHAR(254) AS asutus

FROM pv_kaardid pk
         INNER JOIN qryKaibed kb ON kb.pv_kaart_id = pk.pv_kaart_id
         INNER JOIN ou.rekv r ON r.id = pk.rekvid
         LEFT OUTER JOIN libs.asutus a ON pk.vastisik_id = to_jsonb(a.id)

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.pv_rv_kaibe_aruanne( DATE, DATE, INTEGER, INTEGER, JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.pv_rv_kaibe_aruanne( DATE, DATE, INTEGER, INTEGER, JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.pv_rv_kaibe_aruanne( DATE, DATE, INTEGER , INTEGER, JSONB) TO dbkasutaja;



SELECT *
FROM docs.pv_rv_kaibe_aruanne('2023-01-01', '2023-12-31' :: DATE, 63, 1, null::JSONB)
WHERE kb_pv_rv02 > 0