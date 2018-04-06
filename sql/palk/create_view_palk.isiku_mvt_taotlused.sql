DROP VIEW IF EXISTS palk.isiku_mvt_taotlused;

CREATE OR REPLACE VIEW palk.isiku_mvt_taotlused AS
  SELECT
    sum(qry.kuu_summa) AS summa,
    qry.isikid,
    qry.kuu,
    qry.aasta
  FROM (SELECT
          tooleping.parentid AS isikid,
          t.lepingid,
          t.summa,
          t.alg_kpv,
          t.lopp_kpv,
          v_month.kuu,
          year(t.lopp_kpv)   AS aasta,
          CASE
          WHEN month(t.alg_kpv) <= v_month.kuu AND month(t.lopp_kpv) >= v_month.kuu
            THEN t.summa
          ELSE 0 :: NUMERIC
          END                AS kuu_summa
        FROM palk.taotlus_mvt t, (((((((((((SELECT 1 AS kuu
                                            UNION
                                            SELECT 2 AS kuu)
                                           UNION
                                           SELECT 3 AS kuu)
                                          UNION
                                          SELECT 4 AS kuu)
                                         UNION
                                         SELECT 5 AS kuu)
                                        UNION
                                        SELECT 6 AS kuu)
                                       UNION
                                       SELECT 7 AS kuu)
                                      UNION
                                      SELECT 8 AS kuu)
                                     UNION
                                     SELECT 9 AS kuu)
                                    UNION
                                    SELECT 10 AS kuu)
                                   UNION
                                   SELECT 11 AS kuu)
                                  UNION
                                  SELECT 12 AS kuu) v_month, palk.tooleping tooleping
        WHERE tooleping.id = t.lepingid
              AND t.summa > 0 :: NUMERIC
              AND t.status <> 'deleted'
       ) qry
  GROUP BY qry.isikid, qry.aasta, qry.kuu;

GRANT ALL ON TABLE palk.isiku_mvt_taotlused TO dbkasutaja;
GRANT ALL ON TABLE palk.isiku_mvt_taotlused TO dbpeakasutaja;

