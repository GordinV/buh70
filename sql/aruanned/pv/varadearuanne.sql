DROP FUNCTION IF EXISTS docs.varadearuanne(DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.varadearuanne(DATE, DATE, INTEGER);

CREATE OR REPLACE FUNCTION docs.varadearuanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER)
    RETURNS TABLE (
        rekv_id     INTEGER,
        kood        VARCHAR(20),
        nimetus     VARCHAR(254),
        konto       VARCHAR(20),
        grupp       VARCHAR(254),
        soet_kpv    DATE,
        soetmaks    NUMERIC(14, 2),
        vastisik_id INTEGER,
        vastisik    TEXT,
        alg_kulum   NUMERIC(14, 2),
        kulum       NUMERIC(14, 2),
        parandus    NUMERIC(14, 2),
        mahakantud  NUMERIC(14, 2),
        jaak        NUMERIC(14, 2),
        grupp_id    INTEGER
    )
AS
$BODY$
SELECT rekv_id,
       kood :: VARCHAR(20),
       qry.nimetus :: VARCHAR(254),
       konto :: VARCHAR(20),
       grupp :: VARCHAR(254),
       soetkpv,
       soetmaks,
       vastisikid,
       a.nimetus::TEXT                                        AS vastisik,
       alg_kulum,
       kulum,
       parandus,
       mahakantud,
       (CASE
            WHEN umberhindamine > 0
                THEN umberhindamine
            ELSE soetmaks END + parandus - alg_kulum - kulum) AS jaak,
       gruppid
FROM (
         SELECT p.rekvid                                       AS rekv_id,
                p.kood,
                p.nimetus,
                p.grupp,
                p.gruppid,
                p.konto,
                p.soetkpv,
                p.vastisikid,
                coalesce((SELECT sum(summa)
                          FROM docs.pv_oper po
                          WHERE pv_kaart_id = p.id
                            AND liik = 2
                            AND kpv < l_kpv1), 0) + p.algkulum AS alg_kulum,
                coalesce((SELECT sum(summa)
                          FROM docs.pv_oper po
                          WHERE pv_kaart_id = p.id
                            AND liik = 2
                            AND kpv >= l_kpv1
                            AND kpv <= l_kpv2), 0)             AS kulum,
                coalesce((SELECT sum(summa)
                          FROM docs.pv_oper po
                          WHERE pv_kaart_id = p.id
                            AND liik = 3
                            AND kpv >= l_kpv1
                            AND kpv <= l_kpv2), 0)             AS parandus,
                coalesce((SELECT sum(summa)
                          FROM docs.pv_oper po
                          WHERE pv_kaart_id = p.id
                            AND liik = 4
                            AND kpv <= l_kpv2),
                         0)                                    AS mahakantud,
                coalesce((SELECT sum(summa)
                          FROM docs.pv_oper po
                          WHERE pv_kaart_id = p.id
                            AND liik = 5
                            AND kpv < l_kpv2),
                         0)                                    AS umberhindamine,
                (SELECT sum(summa)
                 FROM (
                          SELECT summa
                          FROM docs.pv_oper po
                          WHERE pv_kaart_id = p.id
                            AND liik = 1
                          UNION ALL
                          SELECT summa
                          FROM docs.pv_oper po
                          WHERE pv_kaart_id = p.id
                            AND liik = 3
                            AND kpv < l_kpv1
                      ) qry
                )
                                                               AS soetmaks
         FROM cur_pohivara p
         WHERE (p.mahakantud IS NULL OR p.mahakantud > l_kpv1)
           AND p.rekvid = l_rekvid
     ) qry
         LEFT OUTER JOIN libs.asutus a
                         ON a.id = qry.vastisikid
    ;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.varadearuanne( DATE, DATE, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.varadearuanne( DATE, DATE, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.varadearuanne( DATE, DATE, INTEGER ) TO dbkasutaja;


/*
SELECT *
FROM docs.varadearuanne('2021-01-01', '2021-08-31' :: DATE, 130)
where kood = '01365-14'

*/