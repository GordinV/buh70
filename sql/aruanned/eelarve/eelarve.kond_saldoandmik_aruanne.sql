DROP FUNCTION IF EXISTS eelarve.kond_saldoandmik_aruanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER);
DROP FUNCTION IF EXISTS eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER);
DROP FUNCTION IF EXISTS eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER, INTEGER, BOOLEAN);

CREATE OR REPLACE FUNCTION eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER, is_xml_file BOOLEAN)
    RETURNS TABLE
            (
                konto      VARCHAR(20),
                nimetus    VARCHAR(254),
                tp         VARCHAR(20),
                tegev      VARCHAR(20),
                allikas    VARCHAR(20),
                rahavoog   VARCHAR(20),
                deebet     NUMERIC(14, 2),
                kreedit    NUMERIC(14, 2),
                tyyp       INTEGER,
                arvestatud timestamp
            )
AS
$BODY$

-- rekvid  = 999 (kond)
WITH andmik AS (SELECT s.konto,
                       coalesce(k.nimetus, '') :: VARCHAR(254) AS nimetus,
                       left(s.tp, 6)                           AS tp,
                       s.tegev,
                       left(s.allikas, 2)                      AS allikas,
                       s.rahavoo,
                       sum(s.db)                               AS deebet,
                       sum(s.kr)                               AS kreedit,
                       s.tyyp,
                       max(timestamp)                          as arvestatud
                FROM eelarve.saldoandmik s
                         LEFT OUTER JOIN com_kontoplaan k ON k.kood = s.konto
                WHERE s.aasta = year(l_kpv)
                  AND s.kuu = month(l_kpv)
                  AND s.rekvid = (CASE
                                      WHEN l_kond = 1
                                          THEN s.rekvid
                                      ELSE l_rekvid END
                    )
                  AND s.rekvid IN (SELECT rekv_id
                                   FROM get_asutuse_struktuur(l_rekvid, l_kpv)
                                   UNION ALL
                                   SELECT l_rekvid)
                  AND s.konto NOT IN
                      (SELECT * FROM unnest(CASE WHEN is_xml_file THEN ARRAY ['910019','910029'] ELSE ARRAY [''] END))
                GROUP BY S.konto
                       , k.nimetus
                       , LEFT(S.tp, 6)
                       , S.tegev
                       , LEFT(S.allikas, 2)
                       , S.rahavoo
                       , S.tyyp)
        ,
     pv_kontod
         AS
         (SELECT unnest(ARRAY ['154000',
             '155000',
             '155100',
             '155101',
             '155106',
             '155109',
             '155300',
             '155400',
             '155405',
             '155500',
             '155600',
             '155700',
             '155900',
             '155910',
--                     '155920',
             '156000',
             '156200',
             '156400',
             '156410',
             '156500',
             '156600',
             '156900',
             '156910',
             '156920',
             '157000',
             '157010',
             '157020',
             '157090',
             '150020',
             '150200',
             '150210',
             '151910']) AS kood)

SELECT konto:: VARCHAR(20),
       nimetus:: VARCHAR(254),
       tp:: VARCHAR(20),
       tegev:: VARCHAR(20),
       allikas:: VARCHAR(20),
       rahavoo:: VARCHAR(20),
       sum(deebet):: NUMERIC(14, 2)  AS deebet,
       sum(kreedit):: NUMERIC(14, 2) AS kreedit,
       tyyp::INTEGER,
       max(arvestatud)                as timestamp
FROM (
-- 155
         SELECT konto:: VARCHAR(20),
                nimetus:: VARCHAR(254),
                tp:: VARCHAR(20),
                CASE WHEN rahavoo = '01' THEN tegev ELSE '' END:: VARCHAR(20) AS tegev,
                allikas:: VARCHAR(20),
                rahavoo:: VARCHAR(20),
                deebet:: NUMERIC(14, 2),
                kreedit:: NUMERIC(14, 2),
                tyyp::INTEGER,
                arvestatud
         FROM andmik
         WHERE ltrim(rtrim(konto)) IN (SELECT kood FROM pv_kontod)
         UNION ALL
         SELECT konto:: VARCHAR(20),
                nimetus:: VARCHAR(254),
                tp:: VARCHAR(20),
                tegev:: VARCHAR(20),
                allikas:: VARCHAR(20),
                rahavoo:: VARCHAR(20),
                deebet:: NUMERIC(14, 2),
                kreedit:: NUMERIC(14, 2),
                tyyp::INTEGER,
                arvestatud
         FROM andmik
         WHERE ltrim(rtrim(konto)) NOT IN (SELECT kood FROM pv_kontod)) qry
GROUP BY konto, nimetus, tp, tegev, allikas, rahavoo, tyyp;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER, INTEGER, BOOLEAN) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER, INTEGER, BOOLEAN) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER, INTEGER, BOOLEAN) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER, INTEGER, BOOLEAN) TO dbvaatleja;
/*
select * from (
SELECT *
FROM eelarve.kond_saldoandmik_aruanne('2024-08-31' :: DATE, 119 :: INTEGER,1, true::boolean)
) qry
where konto like '100%'

*/