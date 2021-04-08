DROP FUNCTION IF EXISTS palk.palk_leht(DATE, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.palk_leht(DATE, DATE, INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.palk_leht(DATE, DATE, INTEGER, INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION palk.palk_leht(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER,
                                          l_osakond_id INTEGER DEFAULT 0, l_isik_id INTEGER DEFAULT 0)
    RETURNS TABLE (
        isik_id   INTEGER,
        isikukood VARCHAR(20),
        isik      VARCHAR(254),
        kuu       INTEGER,
        aasta     INTEGER,
        deebet    NUMERIC(14, 2),
        kreedit   NUMERIC(14, 2),
        sotsmaks  NUMERIC(14, 2),
        jaak      NUMERIC(14, 2),
        mvt       NUMERIC(14, 2),
        nimetus   VARCHAR(254),
        paev      NUMERIC(12, 4),
        ohtu      NUMERIC(12, 4),
        oo        NUMERIC(12, 4),
        puhapaev  NUMERIC(12, 4),
        tahtpaev  NUMERIC(12, 4),
        uleajatoo NUMERIC(12, 4),
        kokku     NUMERIC(12, 4),
        tootunnid NUMERIC(12, 4)
    ) AS
$BODY$
WITH qry_taabel AS (
    SELECT t.isik_id,
           sum(paev)                                                                           AS paev,
           sum(ohtu)                                                                           AS ohtu,
           sum(oo)                                                                             AS oo,
           sum(puhapaev)                                                                       AS puhapaev,
           sum(tahtpaev)                                                                       AS tahtpaev,
           sum(uleajatoo)                                                                      AS uleajatoo,
           sum(kokku)                                                                          AS kokku,
           sum(palk.get_work_hours((SELECT to_jsonb(qry)
                                    FROM (SELECT t.lepingid AS lepingid, l_kpv2 AS kpv) qry))) AS tootunnid

    FROM palk.cur_palk_taabel t
    WHERE t.aasta = year(l_kpv2)
      AND t.kuu = month(l_kpv2)
      AND t.rekvid = l_rekvid
      AND (t.isik_id = l_isik_id OR l_isik_id = 0)
    GROUP BY t.isik_id
)

SELECT qry.isikid :: INTEGER                AS isik_id,
       qry.isikukood :: VARCHAR(20),
       qry.isik :: VARCHAR(254),
       qry.kuu :: INTEGER,
       qry.aasta :: INTEGER,
       sum(qry.deebet) :: NUMERIC(14, 2)    AS deebet,
       sum(qry.kreedit) :: NUMERIC(14, 2)   AS kreedit,
       sum(qry.sotsmaks) :: NUMERIC(14, 2)  AS sotsmaks,
       qry.jaak :: NUMERIC(14, 2)           AS jaak,
       qry.mvt :: NUMERIC(14, 2)            AS mvt,
       qry.nimetus :: VARCHAR(254),
       max(tbl.paev) :: NUMERIC(12, 4)      AS paev,
       max(tbl.ohtu) :: NUMERIC(12, 4)      AS ohtu,
       max(tbl.oo) :: NUMERIC(12, 4)        AS oo,
       max(tbl.puhapaev) :: NUMERIC(12, 4)  AS puhapaev,
       max(tbl.tahtpaev) :: NUMERIC(12, 4)  AS tahtpaev,
       max(tbl.uleajatoo) :: NUMERIC(12, 4) AS uleajatoo,
       max(tbl.kokku) :: NUMERIC(12, 4)     AS kokku,
       max(tbl.tootunnid) :: NUMERIC(12, 4) AS tootunnid
FROM (
         WITH qry_mvt AS (
             SELECT t.parentid AS isikid, sum(j.g31) AS mvt, sum(jaak) AS jaak
             FROM palk.palk_jaak j
                      INNER JOIN palk.tooleping t ON j.lepingid = t.id
             WHERE j.aasta = year(l_kpv2)
               AND j.kuu = month(l_kpv2)
               AND t.rekvid = l_rekvid
               AND (t.parentid = l_isik_id OR l_isik_id = 0)
             GROUP BY t.parentid
         )
         SELECT po.isikid,
                po.isikukood,
                po.isik,
                month(kpv)       AS kuu,
                year(kpv)        AS aasta,
                (CASE
                     WHEN liik = '+'
                         THEN summa
                     ELSE 0 END) AS deebet,
                (CASE
                     WHEN liik = '-'
                         THEN summa
                     ELSE 0 END) AS kreedit,
                (CASE
                     WHEN liik = '%'
                         THEN summa
                     ELSE 0 END) AS sotsmaks,
                qry_mvt.jaak,
                qry_mvt.mvt      AS mvt,
                nimetus,
                liik,
                osakondid
         FROM palk.cur_palkoper po
                  LEFT OUTER JOIN palk.palk_jaak j
                                  ON j.lepingid = po.lepingid AND j.kuu = month(po.kpv) AND j.aasta = year(po.kpv)
                  LEFT JOIN qry_mvt ON qry_mvt.isikid = po.isikid
         WHERE po.kpv >= l_kpv1
           AND po.kpv <= l_kpv2
           AND po.rekvid = l_rekvid
           AND (l_osakond_id IS NULL OR empty(l_osakond_id) OR po.osakondid = l_osakond_id)
           AND (po.isikid = l_isik_id OR l_isik_id = 0)
     ) qry
         LEFT OUTER JOIN qry_taabel tbl
                         ON tbl.isik_id = qry.isikid

GROUP BY isikid, isikukood, isik, mvt, jaak, nimetus, kuu, aasta
    -- $BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION palk.palk_leht( DATE, DATE, INTEGER, INTEGER, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.palk_leht( DATE, DATE, INTEGER, INTEGER, INTEGER, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.palk_leht( DATE, DATE, INTEGER, INTEGER, INTEGER, INTEGER) TO dbkasutaja;


/*

SELECT *
FROM palk.palk_leht('2021-02-01', '2021-02-28', 125, 1 :: INTEGER);

*/