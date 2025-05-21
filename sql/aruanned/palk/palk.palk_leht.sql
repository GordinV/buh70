DROP FUNCTION IF EXISTS palk.palk_leht(DATE, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.palk_leht(DATE, DATE, INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.palk_leht(DATE, DATE, INTEGER, INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION palk.palk_leht(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER,
                                          l_osakond_id INTEGER DEFAULT 0, l_isik_id INTEGER DEFAULT 0)
    RETURNS TABLE
            (
                isik_id   INTEGER,
                isikukood VARCHAR(20),
                isik      VARCHAR(254),
                amet      VARCHAR(254),
                amet_id   INTEGER,
                leping_id INTEGER,
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
                tootunnid NUMERIC(12, 4),
                palk_liik TEXT
            )
AS
$BODY$
WITH
    qry_taabel AS (
                      SELECT
                          t.isik_id,
                          sum(paev)                   AS paev,
                          sum(ohtu)                   AS ohtu,
                          sum(oo)                     AS oo,
                          sum(puhapaev)               AS puhapaev,
                          sum(tahtpaev)               AS tahtpaev,
                          sum(uleajatoo)              AS uleajatoo,
                          sum(kokku)                  AS kokku,
                          sum(palk.get_work_hours((
                                                      SELECT
                                                          to_jsonb(qry)
                                                      FROM
                                                          (
                                                              SELECT t.lepingid AS lepingid, l_kpv2 AS kpv, TRUE AS kas_tahtpaevad
                                                          ) qry
                                                  ))) AS tootunnid

                      FROM
                          palk.cur_palk_taabel t
                      WHERE
                            t.aasta = year(l_kpv2)
                        AND t.kuu = month(l_kpv2)
                        AND t.rekvid = l_rekvid
                        AND (t.isik_id = l_isik_id OR l_isik_id = 0)
                      GROUP BY t.isik_id
    )

SELECT
    qry.isikid :: INTEGER                AS isik_id,
    qry.isikukood :: VARCHAR(20),
    qry.isik :: VARCHAR(254),
    qry.amet :: VARCHAR(254),
    qry.amet_id,
    qry.lepingid                         AS lepind_id,
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
    max(tbl.tootunnid) :: NUMERIC(12, 4) AS tootunnid,
    qry.palk_liik
FROM
    (
        WITH
            qry_mvt AS (
                           SELECT
                               t.parentid AS isikid,
                               sum(j.g31) AS mvt,
                               sum(jaak)  AS jaak
                           FROM
                               palk.palk_jaak                j
                                   INNER JOIN palk.tooleping t ON j.lepingid = t.id
                           WHERE
                                 j.aasta = year(l_kpv2)
                             AND j.kuu = month(l_kpv2)
                             AND t.rekvid = l_rekvid
                             AND (t.parentid = l_isik_id OR l_isik_id = 0)
                           GROUP BY t.parentid
            )
        SELECT
            po.isikid,
            po.isikukood,
            po.isik,
            month(kpv)                               AS kuu,
            year(kpv)                                AS aasta,
            (CASE
                 WHEN po.liik = '+'
                     THEN po.summa
                 ELSE 0 END)                         AS deebet,
            (CASE
                 WHEN po.liik = '-'
                     THEN po.summa
                 ELSE 0 END)                         AS kreedit,
            (CASE
                 WHEN po.liik = '%'
                     THEN po.summa
                 ELSE 0 END)                         AS sotsmaks,
            qry_mvt.jaak,
            qry_mvt.mvt                              AS mvt,
            po.nimetus                               AS nimetus,
            po.liik,
            po.palk_liik,
            po.osakondid,
            case
                when amet.nimetus ilike '%kvalifikatsiooninõuetele vastav%'
                    then replace(amet.nimetus, 'kvalifikatsiooninõuetele vastav', ' ')
                when amet.nimetus ilike '%kvalifikatsiooninõuetele mittevastav%'
                    then replace(amet.nimetus, 'kvalifikatsiooninõuetele mittevastav', ' ')
                else amet.nimetus end:: varchar(254) AS amet,
            amet.id                                  AS amet_id,
            po.lepingid
        FROM
            (
                SELECT
                    a.id                                                                                            AS isikid,
                    a.regkood                                                                                       AS isikukood,
                    a.nimetus                                                                                       AS isik,
                    t.osakondid,
                    o.kood                                                                                          AS osakond,
                    lib.kood,
                    lib.nimetus,
                    ((enum_range(NULL :: PALK_OPER_LIIK))[CASE ((lib.properties :: JSONB ->> 'liik') ||
                                                                (lib.properties :: JSONB ->> 'asutusest')) :: TEXT
                                                              WHEN '10'
                                                                  THEN 1
                                                              WHEN '20'
                                                                  THEN 2
                                                              WHEN '40'
                                                                  THEN 2
                                                              WHEN '70'
                                                                  THEN 2
                                                              WHEN '71'
                                                                  THEN 3
                                                              WHEN '80'
                                                                  THEN 2
                                                              WHEN '60'
                                                                  THEN 2
                                                              ELSE 3 END]) :: VARCHAR(20)                           AS liik,
                    ((enum_range(NULL :: PALK_LIIK))[(lib.properties :: JSONB ->> 'liik') :: INTEGER]) :: TEXT      AS palk_liik,
                    ((enum_range(NULL :: PALK_TUND_LIIK))[(lib.properties :: JSONB ->> 'tund') :: INTEGER]) :: TEXT AS tund,
                    p.kpv,
                    p.summa,
                    t.ametid,
                    p.lepingid,
                    p.rekvid
                FROM
                    docs.doc                           d
                        INNER JOIN      palk.palk_oper p ON p.parentid = d.id
                        INNER JOIN      libs.library   lib ON p.libid = lib.id AND lib.library = 'PALK'
                        INNER JOIN      palk.tooleping t ON p.lepingid = t.id
                        INNER JOIN      libs.asutus    a ON t.parentid = a.id
                        LEFT OUTER JOIN libs.library   o ON o.id = t.osakondid
                WHERE
                      d.status <> 3
                  AND (l_osakond_id IS NULL OR empty(l_osakond_id) OR t.osakondid = l_osakond_id)
                  AND p.kpv >= l_kpv1
                  AND p.kpv <= l_kpv2
                  AND p.rekvid = l_rekvid
                  AND (t.parentid = l_isik_id OR l_isik_id IS NULL OR l_isik_id = 0)
            )                                  po
                LEFT OUTER JOIN libs.library   amet ON amet.id = po.ametid
                LEFT OUTER JOIN palk.palk_jaak j
                                ON j.lepingid = po.lepingid AND j.kuu = month(po.kpv) AND j.aasta = year(po.kpv)

                LEFT JOIN       qry_mvt ON qry_mvt.isikid = po.isikid
    )                              qry
        LEFT OUTER JOIN qry_taabel tbl
                        ON tbl.isik_id = qry.isikid

GROUP BY
    isikid, isikukood, isik, amet, amet_id, lepingid, mvt, jaak, qry.nimetus, kuu, aasta, palk_liik
    -- $BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION palk.palk_leht( DATE, DATE, INTEGER, INTEGER, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.palk_leht( DATE, DATE, INTEGER, INTEGER, INTEGER, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.palk_leht( DATE, DATE, INTEGER, INTEGER, INTEGER, INTEGER) TO dbkasutaja;


/*

SELECT *
FROM palk.palk_leht('2021-02-01', '2021-02-28', 119, 0 :: INTEGER)
where isikukood = '46212213710'
*/