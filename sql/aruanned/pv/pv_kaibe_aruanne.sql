DROP FUNCTION IF EXISTS docs.pv_kaibe_aruanne(DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.pv_kaibe_aruanne(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.pv_kaibe_aruanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
                                                 l_kond INTEGER DEFAULT NULL)
    RETURNS TABLE (
        kood           VARCHAR(20),
        nimetus        VARCHAR(254),
        pindala        NUMERIC(12, 4),
        kulumi_maar    NUMERIC(12, 2),
        eluiga         NUMERIC(12, 4),
        esimise_kpv    DATE,
        alg_kogus      NUMERIC(12, 4),
        alg_soetmaks   NUMERIC(12, 2),
        alg_kulum      NUMERIC(12, 2),
        db_kogus       NUMERIC(12, 4),
        db_soetmaks    NUMERIC(12, 2),
        db_kulum       NUMERIC(12, 2),
        kr_kogus       NUMERIC(12, 4),
        kr_soetmaks    NUMERIC(12, 2),
        kr_kulum       NUMERIC(12, 2),
        lopp_kogus     NUMERIC(12, 4),
        lopp_soetmaks  NUMERIC(12, 2),
        lopp_kulum     NUMERIC(12, 2),
        konto          VARCHAR(20),
        kulum_konto    VARCHAR(20),
        kulu_konto     VARCHAR(20),
        grupp          VARCHAR(254),
        aadress        VARCHAR(254),
        vastisik       VARCHAR(254),
        kinnitus_osa   NUMERIC(12, 4),
        motteline_osa  VARCHAR(254),
        ehituse_objekt VARCHAR(254),
        rentnik        VARCHAR(254),
        tegevus_alla   VARCHAR(20),
        turu_vaartsus  NUMERIC(12, 2),
        rekv_id        INTEGER
    )
AS
$BODY$
WITH rekv_ids AS (
    SELECT rekv_id
    FROM get_asutuse_struktuur(l_rekvid)
    WHERE rekv_id = CASE
                        WHEN l_kond = 1
                            THEN rekv_id
                        ELSE l_rekvid END),
     qryKaibed AS (
         SELECT pv_kaart_id,
                sum(alg_soetmaks) AS alg_soetmaks,
                sum(alg_kulum)    AS alg_kulum,
                sum(db_soetmaks)  AS db_soetmaks,
                sum(db_kulum)     AS db_kulum,
                sum(kr_soetmaks)  AS kr_soetmaks,
                sum(kr_kulum)     AS kr_kulum
         FROM (
                  SELECT l.id                                                        AS pv_kaart_id,
                         (SELECT soetmaks FROM libs.get_pv_kaart_jaak(l.id, l_kpv1)) AS alg_soetmaks,
                         (SELECT kulum FROM libs.get_pv_kaart_jaak(l.id, l_kpv1))    AS alg_kulum,
                         0::NUMERIC(12, 2)                                           AS db_soetmaks,
                         0::NUMERIC(12, 2)                                           AS db_kulum,
                         0::NUMERIC(12, 2)                                           AS kr_soetmaks,
                         0::NUMERIC(12, 2)                                           AS kr_kulum
                  FROM libs.library l
                  WHERE l.library = 'POHIVARA'
                    AND l.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND ((l.properties :: JSONB ->> 'mahakantud')::DATE IS NULL OR
                         (l.properties :: JSONB ->> 'mahakantud')::DATE > l_kpv1)
                    AND (l.properties :: JSONB ->> 'soetkpv') :: DATE < l_kpv2
                  UNION ALL
                  -- обороты в периоде
                  SELECT po.pv_kaart_id                                AS pv_kaart_id
                          ,
                         0::NUMERIC(12, 2)                             AS alg_soetmaks
                          ,
                         0::NUMERIC(12, 2)                             AS alg_kulum
                          ,
                         sum(summa) FILTER ( WHERE po.liik IN (1, 3) ) AS db_soetmaks
                          ,
                         (sum(summa) FILTER ( WHERE po.liik = 2)) +
                         sum(CASE
                                 WHEN (l.properties :: JSONB ->> 'soetkpv') :: DATE >= l_kpv1 AND
                                      (l.properties :: JSONB ->> 'soetkpv') :: DATE <= l_kpv2
                                     THEN COALESCE((l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 4), 0)
                                 ELSE 0 END)                           AS db_kulum
                          ,
                         0::NUMERIC(12, 2)                             AS kr_soetmaks
                          ,
                         0::NUMERIC(12, 2)                             AS kr_kulum
                  FROM docs.doc D
                           INNER JOIN docs.pv_oper po ON po.parentid = D.id
                           INNER JOIN libs.library l ON l.id = po.pv_kaart_id
                  WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND po.kpv >= l_kpv1
                    AND po.kpv <= l_kpv2
                    AND ((l.properties :: JSONB ->> 'mahakantud')::DATE IS NULL
                      OR (l.properties :: JSONB ->> 'mahakantud')::DATE > l_kpv2
                      )
                  GROUP BY po.pv_kaart_id
                  UNION ALL
                  SELECT l.id                                                        AS pv_kaart_id
                          ,
                         0::NUMERIC(12, 2)                                           AS alg_soetmaks
                          ,
                         0::NUMERIC(12, 2)                                           AS alg_kulum
                          ,
                         0::NUMERIC(12, 2)                                           AS db_soetmaks
                          ,
                         0::NUMERIC(12, 2)                                           AS db_kulum
                          ,
                         (SELECT soetmaks FROM libs.get_pv_kaart_jaak(l.id, l_kpv2)) AS kr_soetmaks
                          ,
                         (SELECT kulum FROM libs.get_pv_kaart_jaak(l.id, l_kpv2))    AS kr_kulum
                  FROM docs.doc D
                           INNER JOIN docs.pv_oper po ON po.parentid = D.id
                           INNER JOIN libs.library l ON l.id = po.pv_kaart_id
                  WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND l.library = 'POHIVARA'
                    AND l.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND (l.properties :: JSONB ->> 'mahakantud')::DATE IS NOT NULL
                    AND (l.properties :: JSONB ->> 'mahakantud')::DATE >= l_kpv1
                    AND (l.properties :: JSONB ->> 'mahakantud')::DATE <= l_kpv2
                  GROUP BY po.pv_kaart_id, l.id
              ) qry
         GROUP BY pv_kaart_id
     )
SELECT l.kood::VARCHAR(20),
       l.nimetus::VARCHAR(254),
       (l.properties::JSONB ->> 'pindala')::NUMERIC(12, 4)                                      AS pindala,
       (l.properties::JSONB ->> 'kulum')::NUMERIC(12, 2)                                        AS kulumi_maar,
       (SELECT eluiga FROM libs.get_pv_kaart_jaak(l.id, l_kpv1))::NUMERIC(12, 4)                AS eluiga,
       (l.properties::JSONB ->> 'soetkpv'):: DATE                                               AS esimise_kpv,
       1::NUMERIC(12, 4)                                                                        AS alg_kogus,
       qryKaibed.alg_soetmaks::NUMERIC(12, 2)                                                   AS alg_soetmaks,
       qryKaibed.alg_kulum::NUMERIC(12, 2)                                                      AS alg_kulum,
       1::NUMERIC(12, 4)                                                                        AS db_kogus,
       qryKaibed.db_soetmaks::NUMERIC(12, 2)                                                    AS db_soetmaks,
       qryKaibed.db_kulum::NUMERIC(12, 2)                                                       AS db_kulum,
       1::NUMERIC(12, 4)                                                                        AS kr_kogus,
       qryKaibed.kr_soetmaks::NUMERIC(12, 2)                                                    AS kr_soetmaks,
       qryKaibed.kr_kulum::NUMERIC(12, 2)                                                       AS kr_kulum,
       1::NUMERIC(12, 4)                                                                        AS lopp_kogus,
       (qryKaibed.alg_soetmaks + qryKaibed.db_soetmaks - qryKaibed.kr_soetmaks)::NUMERIC(12, 2) AS lopp_soetmaks,
       (qryKaibed.alg_kulum + qryKaibed.db_kulum - qryKaibed.kr_kulum)::NUMERIC(12, 2)          AS lopp_kulum,
       (l.properties :: JSONB ->> 'konto')::VARCHAR(20)                                         AS konto,
       (grupp.properties::JSONB ->> 'kulum_konto')::VARCHAR(20)                                 AS kulum_konto,
       (SELECT konto
        FROM docs.pv_oper po
        WHERE po.pv_kaart_id = l.id
          AND liik = 2
        ORDER BY kpv DESC
        LIMIT 1)::VARCHAR(20)                                                                   AS kulu_konto,
       grupp.nimetus::VARCHAR(254)                                                              AS grupp,
       (l.properties::JSONB ->> 'aadress')::VARCHAR(254)                                        AS aadress,
       COALESCE(a.nimetus, ''):: VARCHAR(254)                                                   AS vastisik,
       (l.properties::JSONB ->> 'kinnitus_osa'):: NUMERIC(12, 4)                                AS kinnitus_osa,
       (l.properties::JSONB ->> 'motteline_osa')::VARCHAR(254)                                  AS motteline_osa,
       (l.properties::JSONB ->> 'ehituse_objekt')::VARCHAR(254)                                 AS ehituse_objekt,
       (l.properties :: JSONB ->> 'rentnik')::VARCHAR(254)                                      AS rentnik,
       '04900'::VARCHAR(20)                                                                     AS tegevus_alla,
       (SELECT turu_vaartsus FROM libs.get_pv_kaart_jaak(l.id, l_kpv1))::NUMERIC(12, 4)         AS turu_vaartsus,
       l.rekvid                                                                                 AS rekv_id
FROM libs.library l
         INNER JOIN qryKaibed ON qryKaibed.pv_kaart_id = l.id
         JOIN libs.library grupp ON (l.properties :: JSONB -> 'gruppid') = to_jsonb(grupp.id)
         LEFT JOIN libs.asutus a ON (l.properties :: JSONB -> 'vastisikid') = to_jsonb(a.id)
         LEFT JOIN libs.library p ON (l.properties :: JSONB -> 'parent_id') = to_jsonb(p.id)
WHERE l.library = 'POHIVARA'
  AND l.status <> 3
  AND l.rekvid IN (SELECT rekv_id FROM rekv_ids)
  AND (l.properties :: JSONB ->> 'soetkpv') :: DATE < l_kpv2
  AND ((l.properties :: JSONB ->> 'mahakantud')::DATE IS NULL
    OR
       (l.properties :: JSONB ->> 'mahakantud')::DATE > l_kpv1) ;


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.pv_kaibe_aruanne( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.pv_kaibe_aruanne( DATE, DATE, INTEGER, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.pv_kaibe_aruanne( DATE, DATE, INTEGER , INTEGER) TO dbkasutaja;


/*
SELECT *
FROM docs.pv_kaibe_aruanne('2022-01-01', '2022-12-31' :: DATE,28)
where kood like 'ARV155500-13/1%'

		SELECT (row_number() over())::INTEGER as jrnr, *  from (SELECT                      *
		FROM docs.pv_kaibe_aruanne('2019-01-01', current_date :: DATE, 63::integer) qry
		ORDER by konto, kood   ) qry
		WHERE 	konto ilike '%'
	and grupp ilike '%%'
	and vastisik ilike '%%'
*/