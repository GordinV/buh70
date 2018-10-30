DROP FUNCTION IF EXISTS palk.palk_leht( DATE, DATE, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION palk.palk_leht(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER)
  RETURNS TABLE(
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
    tootunnid INTEGER
  ) AS
$BODY$
SELECT
  isikid :: INTEGER                AS isik_id,
  isikukood :: VARCHAR(20),
  isik :: VARCHAR(254),
  kuu :: INTEGER,
  aasta :: INTEGER,
  sum(deebet) :: NUMERIC(14, 2)    AS deebet,
  sum(kreedit) :: NUMERIC(14, 2)   AS kreedit,
  sum(sotsmaks) :: NUMERIC(14, 2)  AS sotsmaks,
  sum(jaak) :: NUMERIC(14, 2)      AS jaak,
  sum(mvt) :: NUMERIC(14, 2)       AS mvt,
  nimetus :: VARCHAR(254),
  sum(paev) :: NUMERIC(12, 4)      AS paev,
  sum(ohtu) :: NUMERIC(12, 4)      AS ohtu,
  sum(oo) :: NUMERIC(12, 4)        AS oo,
  sum(puhapaev) :: NUMERIC(12, 4)  AS puhapaev,
  sum(tahtpaev) :: NUMERIC(12, 4)  AS tahtpaev,
  sum(uleajatoo) :: NUMERIC(12, 4) AS uleajatoo,
  sum(tootunnid) :: INTEGER        AS tootunnid
FROM (
       SELECT
         po.isikid,
         po.isikukood,
         po.isik,
         month(kpv)                                                      AS kuu,
         year(kpv)                                                       AS aasta,
         (CASE WHEN liik = '+'
           THEN summa
          ELSE 0 END)                                                    AS deebet,
         (CASE WHEN liik = '-'
           THEN summa
          ELSE 0 END)                                                    AS kreedit,
         (CASE WHEN liik = '%'
           THEN summa
          ELSE 0 END)                                                    AS sotsmaks,
         j.jaak,
         j.g31                                                           AS mvt,
         nimetus,
         liik,
         osakondid,
         coalesce(tbl.ohtu,0) as ohtu,
         coalesce(tbl.paev,0) as paev,
         coalesce(tbl.puhapaev,0) as puhapaev,
         coalesce(tbl.oo,0) as oo,
         coalesce(tbl.tahtpaev,0) as tahtpaev,
         coalesce(tbl.uleajatoo,0) as uleajatoo,
         palk.get_work_hours(to_jsonb((SELECT po.lepingid AS lepingid))) AS tootunnid

       FROM palk.cur_palkoper po
         LEFT OUTER JOIN palk.palk_jaak j
           ON j.lepingid = po.lepingid AND j.kuu = month(po.kpv) AND j.aasta = year(po.kpv)
         LEFT OUTER JOIN palk.cur_palk_taabel tbl
           ON tbl.lepingid = po.lepingid AND tbl.kuu = month(po.kpv) AND tbl.aasta = year(po.kpv)
       WHERE po.kpv >= l_kpv1 AND po.kpv <= l_kpv2
             AND po.rekvid = l_rekvid
       --             AND po.rekvid = (CASE WHEN l_kond IS NOT NULL AND NOT empty(l_kond)
       --         THEN l_rekvid
       --                              ELSE po.rekvid END)
       --             AND po.rekvid IN (SELECT rekv_id
       --                               FROM get_asutuse_struktuur(l_rekvid))
     ) qry
GROUP BY isikid, isikukood, isik, nimetus, kuu, aasta
$BODY$
LANGUAGE SQL VOLATILE
COST 100;

/*

SELECT *
FROM palk.palk_leht('2018-01-01', '2018-01-31', 63, 1 :: INTEGER);

*/