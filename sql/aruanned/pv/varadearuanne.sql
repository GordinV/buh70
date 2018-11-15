DROP FUNCTION IF EXISTS docs.varadearuanne( DATE, INTEGER );
DROP FUNCTION IF EXISTS docs.varadearuanne( DATE, DATE, INTEGER );

CREATE OR REPLACE FUNCTION docs.varadearuanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER)
  RETURNS TABLE(
    rekv_id     INTEGER,
    kood        VARCHAR(20),
    nimetus     VARCHAR(254),
    konto       VARCHAR(20),
    grupp       VARCHAR(254),
    soet_kpv    DATE,
    soetmaks    NUMERIC(14, 2),
    vastisik_id INTEGER,
    alg_kulum   NUMERIC(14, 2),
    kulum       NUMERIC(14, 2),
    parandus    NUMERIC(14, 2),
    mahakantud  NUMERIC(14, 2),
    jaak        NUMERIC(14, 2),
    grupp_id    INTEGER
  ) AS
$BODY$
SELECT
  rekv_id,
  kood :: VARCHAR(20),
  nimetus :: VARCHAR(254),
  konto :: VARCHAR(20),
  grupp :: VARCHAR(254),
  soetkpv,
  soetmaks,
  vastisikid,
  alg_kulum,
  kulum,
  parandus,
  mahakantud,
  (CASE WHEN umberhindamine > 0
    THEN umberhindamine
   ELSE soetmaks END + parandus - alg_kulum - kulum) AS jaak,
  gruppid
FROM (
       SELECT
         p.rekvid                                                                              AS rekv_id,
         p.kood,
         p.nimetus,
         p.grupp,
         p.gruppid,
         p.konto,
         p.soetkpv,
         p.vastisikid,
         coalesce((SELECT sum(summa)
                   FROM docs.pv_oper po
                   WHERE pv_kaart_id = p.id AND liik = 2 AND kpv < l_kpv1), 0) + p.algkulum       AS alg_kulum,
         coalesce((SELECT sum(summa)
                   FROM docs.pv_oper po
                   WHERE pv_kaart_id = p.id AND liik = 2 AND kpv >= l_kpv1 AND kpv <= l_kpv2), 0) AS kulum,
         coalesce((SELECT sum(summa)
                   FROM docs.pv_oper po
                   WHERE pv_kaart_id = p.id AND liik = 3 AND kpv >= l_kpv1 AND kpv <= l_kpv2), 0) AS parandus,
         coalesce((SELECT sum(summa)
                   FROM docs.pv_oper po
                   WHERE pv_kaart_id = p.id AND liik = 4 AND kpv <= l_kpv2),
                  0)                                                                           AS mahakantud,
         coalesce((SELECT sum(summa)
                   FROM docs.pv_oper po
                   WHERE pv_kaart_id = p.id AND liik = 5 AND kpv < l_kpv2),
                  0)                                                                           AS umberhindamine,
         coalesce((SELECT sum(summa)
                   FROM docs.pv_oper po
                   WHERE pv_kaart_id = p.id AND liik IN (1, 3) AND kpv < l_kpv1), 0)              AS soetmaks
       FROM cur_pohivara p
       WHERE (p.mahakantud IS NULL OR p.mahakantud > l_kpv1)
            AND p.rekvid = l_rekvid
     ) qry;

$BODY$
LANGUAGE SQL VOLATILE
COST 100;

/*
SELECT *
FROM docs.varadearuanne('2018-01-01', current_date :: DATE, 1)

*/