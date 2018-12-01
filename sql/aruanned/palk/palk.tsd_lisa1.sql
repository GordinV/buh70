DROP FUNCTION IF EXISTS palk.tsd_lisa_1( DATE, DATE, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION palk.tsd_lisa_1(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER)
  RETURNS TABLE(isikukood     VARCHAR(20),
                isik          VARCHAR(254),
                tululiik      VARCHAR(20),
                liik          INTEGER,
                minsots       NUMERIC(14, 2),
                sm_arv        INTEGER,
                tk_arv        INTEGER,
                minpalk       NUMERIC(14, 2),
                summa         NUMERIC(14, 2),
                puhkused      NUMERIC(14, 2),
                haigused      NUMERIC(14, 2),
                tm            NUMERIC(14, 2),
                sm            NUMERIC(14, 2),
                tki           NUMERIC(14, 2),
                pm            NUMERIC(14, 2),
                tka           NUMERIC(14, 2),
                tulubaas      NUMERIC(14, 2),
                puhkus        NUMERIC(14, 2),
                v1040         NUMERIC(14, 2),
                lopp          DATE,
                arv_min_sots  NUMERIC(14, 2),
                min_sots_alus NUMERIC(14, 2)
  ) AS
$BODY$

WITH qryKoormus AS (
    SELECT
      a.regkood :: VARCHAR(20)                   AS isikukood,
      a.nimetus :: VARCHAR(254)                  AS isik,
      sum(koormus) :: NUMERIC                    AS koormus,
      max(coalesce(qryMinSots.arv_min_sots, 0))  AS arv_min_sots,
      max(coalesce(qryMinSots.min_sots_alus, 0)) AS min_sots_alus,
      t.rekvid
    FROM palk.tooleping t
      INNER JOIN libs.asutus a ON a.id = t.parentId
      INNER JOIN ou.rekv ON rekv.id = t.rekvId
      LEFT OUTER JOIN (
                        SELECT
                          po.lepingid,
                          po.rekvid,
                          po.summa    AS arv_min_sots,
                          po.sotsmaks AS min_sots_alus
                        FROM palk.palk_oper po INNER JOIN com_palklib pl
                            ON pl.id = po.libid AND pl.liik = 5 AND po.sotsmaks <> 0
                        WHERE po.kpv >= l_kpv1 AND po.kpv <= l_kpv2
                      ) qryMinSots ON qryMinSots.lepingid = t.id AND qryMinSots.rekvid = rekv.id
    WHERE rekv.id = (CASE WHEN l_kond IS NOT NULL
      THEN l_rekvid
                     ELSE rekv.id END)
          AND rekv.Id IN (SELECT rekv_id
                          FROM get_asutuse_struktuur(l_rekvid))
          AND algab <= l_kpv2
          AND (lopp IS NULL OR lopp >= l_kpv1)
          AND t.resident = 1
    GROUP BY a.regkood, a.nimetus, t.rekvid
)

SELECT
  (CASE WHEN qry.isikukood IS NULL
    THEN qryKoormus.isikukood
   ELSE qry.isikukood END) :: VARCHAR(20),
  (CASE WHEN qry.isik IS NULL
    THEN qryKoormus.isik
   ELSE qry.isik END) :: VARCHAR(253),
  qry.tululiik,
  qry.liik,
  coalesce(qry.minsots, 0) :: NUMERIC(14, 2) AS minsots,
  qry.sm_arv,
  qry.tk_arv,
  coalesce(qry.minpalk, 0) :: NUMERIC(14, 2) AS minpalk,
  sum(qry.summa)                             AS summa,
  sum(qry.puhkused)                          AS puhkused,
  sum(qry.haigused)                          AS haigused,
  sum(qry.tm)                                AS tm,
  sum(qry.sm)                                AS sm,
  sum(qry.tki)                               AS tki,
  sum(qry.pm)                                AS pm,
  sum(qry.tka)                               AS tka,
  sum(qry.tulubaas)                          AS tulubaas,
  sum(qry.puhkus)                            AS puhkus,

  sum(round(CASE WHEN qry.koormus IS NULL
    THEN qryKoormus.koormus
      ELSE qry.koormus END / 100,2))            AS v1040,

  MAX(qry.lopp)                              AS lopp,
  max(qry.arv_min_sots)                      AS arv_min_sots,
  max(qry.min_sots_alus)                     AS min_sots_alus
FROM (
       SELECT
         a.regkood                                                         AS isikukood,
         a.nimetus                                                         AS isik,
         po.summa                                                          AS summa,
         (CASE WHEN pl.liik = 1 AND pl.kood ILIKE '%PUHKUS%'
           THEN po.summa
          ELSE 0 END)                                                      AS puhkused,
         (CASE WHEN pl.liik = 1 AND pl.kood ILIKE '%HAIGUS%'
           THEN po.summa
          ELSE 0 END)                                                      AS haigused,
         (po.tulumaks)                                                     AS tm,
         (po.sotsmaks)                                                     AS sm,
         (po.tootumaks)                                                    AS tki,
         (po.pensmaks)                                                     AS pm,
         (po.tka)                                                          AS tka,
         (po.tulubaas)                                                     AS tulubaas,
         po.tululiik,
         pl.liik,
         COALESCE(l.tun1, 0)                                               AS tm_maar,
         COALESCE(l.tun4, 0)                                               AS tk_arv,
         COALESCE(l.tun5, 0)                                               AS pm_arv,
         COALESCE(l.tun1, 0)                                               AS tm_arv,
         COALESCE(l.tun2, 0)                                               AS sm_arv,
         t.riik,
         po.period,
         (pc.minpalk * (
           SELECT minsots
           FROM palk.palk_kaart pk_
             INNER JOIN com_palklib pl_ ON pl_.id = pk_.libid AND pl_.liik = 5
           WHERE pk_.lepingid = t.id
                 AND pk_.status = 1
           LIMIT 1) * pc.sm / 100)                                         AS minsots,
         pc.minpalk,
         a.id,
         t.rekvId,
         coalesce(t.lopp, '2099-12-31' :: DATE)                            AS lopp,
         coalesce(qryMinSots.arv_min_sots, 0)                              AS arv_min_sots,
         coalesce(qryMinSots.min_sots_alus, 0)                             AS min_sots_alus,
         coalesce(sp_puudumise_paevad(l_kpv1 :: DATE, t.id), 0) :: NUMERIC AS puhkus,
         coalesce(t.koormus, 0)                                            AS koormus

       FROM palk.tooleping t
         INNER JOIN libs.asutus a ON a.id = t.parentid
         INNER JOIN palk.palk_oper po ON po.lepingid = t.id
         INNER JOIN com_palklib pl ON pl.id = po.libId
         LEFT OUTER JOIN palk.palk_kaart pk ON pk.lepingId = t.id AND pk.libid = po.libid
         INNER JOIN ou.rekv ON rekv.id = po.rekvid
         LEFT OUTER JOIN libs.LIBRARY l ON l.kood = po.tululiik AND l.library = 'MAKSUKOOD'
         LEFT OUTER JOIN palk.palk_config pc ON pc.rekvid = rekv.id
         LEFT OUTER JOIN (SELECT
                            po.lepingid,
                            po.rekvid,
                            po.summa    AS arv_min_sots,
                            po.sotsmaks AS min_sots_alus
                          FROM palk.palk_oper po
                            INNER JOIN com_palklib pl ON pl.id = po.libid AND pl.liik = 5 AND po.sotsmaks <> 0
                          WHERE po.kpv >= l_kpv1 AND po.kpv <= l_kpv2
                         ) qryMinSots ON qryMinSots.lepingid = t.id AND qryMinSots.rekvid = rekv.id

       WHERE po.kpv >= l_kpv1 AND po.kpv <= l_kpv2
             AND period IS NULL
             AND pl.liik = 1
             AND t.resident = 1
             AND rekv.id = (CASE WHEN l_kond IS NOT NULL
         THEN l_rekvid
                            ELSE rekv.id END)
             AND rekv.Id IN (SELECT rekv_id
                             FROM get_asutuse_struktuur(l_rekvid))
     ) qry
  FULL OUTER JOIN qryKoormus ON qryKoormus.isikukood = qry.isikukood
GROUP BY qry.id, qry.isikukood, qryKoormus.isikukood, qry.isik, qryKoormus.isik,
  tululiik, liik, riik, period, minsots, sm_arv, tk_arv, minpalk

$BODY$
LANGUAGE SQL VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION palk.tsd_lisa_1( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.tsd_lisa_1( DATE, DATE, INTEGER, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.tsd_lisa_1( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;


/*

SELECT *
FROM palk.tsd_lisa_1('2018-10-01', '2018-10-31', 63, 1 :: INTEGER);

*/