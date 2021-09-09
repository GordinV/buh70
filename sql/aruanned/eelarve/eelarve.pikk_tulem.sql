DROP FUNCTION IF EXISTS eelarve.pikk_tulem(DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.pikk_tulem(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE (
        rekv_id INTEGER,
        konto   VARCHAR(20),
        nimetus VARCHAR(254),
        summa   NUMERIC(14, 2),
        idx     INTEGER
    ) AS
$BODY$

WITH qrySaldo AS (
    SELECT s.rekvid,
           s.konto,
           sum(coalesce(s.db, 0))          AS db,
           sum(coalesce(s.kr, 0))          AS kr,
           left(s.konto, 2)::INTEGER * 100 AS idx
    FROM eelarve.saldoandmik s
    WHERE s.aasta = year(l_kpv)
      AND s.kuu = month(l_kpv)
      AND rekvid = (CASE
                        WHEN l_kond = 1 AND l_rekvid <> 63
                            THEN s.rekvid
                        WHEN l_kond = 1 AND l_rekvid = 63
                            THEN 999
                        ELSE l_rekvid END)
      AND s.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid)
                       UNION ALL
                       SELECT CASE
                                  WHEN l_kond = 1 AND l_rekvid <> 63
                                      THEN l_rekvid
                                  WHEN l_kond = 1 AND l_rekvid = 63
                                      THEN 999
                                  ELSE l_rekvid END
    )
      AND tp NOT LIKE
          CASE WHEN l_kond = 1 AND l_rekvid = 63 THEN '185101%' ELSE '999999%' END -- буз внутренних Тп кодов
    GROUP BY s.konto, s.rekvid
)
SELECT rekv_id,
       konto,
       coalesce(l.nimetus, ''):: VARCHAR(254) AS nimetus,
       sum(summa)                             AS summa,
       idx
FROM (
         --val(left(ltrim(rtrim(q.konto)), 1)) >= 3 AND val(left(q.konto, 1)) < 9
         SELECT q.rekvid                       AS rekv_id,
                q.konto,
                l.nimetus,
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE val(left(ltrim(rtrim(q.konto)), 1)) >= 3
           AND val(left(q.konto, 1)) < 9
         UNION ALL
         -- val(left(konto, 1)) >= 9 AND val(left(konto, 3)) <= 920
         SELECT q.rekvid                       AS rekv_id,
                q.konto,
                l.nimetus,
                coalesce(kr) + coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE val(left(konto, 1)) >= 9
           AND val(left(konto, 3)) <= 920

         UNION ALL
         -- val(left(konto,3)) > 920 and val(left(konto,2)) < 93
         SELECT q.rekvid                       AS rekv_id,
                q.konto,
                l.nimetus,
                coalesce(db, 0) - coalesce(kr) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE val(left(konto, 3)) > 920
           AND val(left(konto, 2)) < 93
         UNION ALL
         -- val(left(konto,2)) >= 93
         SELECT q.rekvid                       AS rekv_id,
                q.konto,
                l.nimetus,
                coalesce(db, 0) + coalesce(kr) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE val(left(konto, 2)) >= 93
         UNION ALL
         -- 3
         SELECT q.rekvid                            AS rekv_id,
                '3',
                'Tegevustulud',
                sum(coalesce(kr) - coalesce(db, 0)) AS summa,
                3000                                AS idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE left(konto, 1) = '3'
         GROUP BY rekv_id
         UNION ALL
         -- 30
         SELECT q.rekvid                       AS rekv_id,
                '30',
                'Maksud ja sotsiaalkindlustusmaksed',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '30%'
         UNION ALL
         -- 300
         SELECT q.rekvid                       AS rekv_id,
                '300',
                'Tulumaks',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '300%'
         UNION ALL
         -- 3000
         SELECT q.rekvid                       AS rekv_id,
                '3000',
                'Füüsilise isiku tulumaks',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3000%'
         UNION ALL
         -- 3001
         SELECT q.rekvid                       AS rekv_id,
                '3001',
                'Juriidilise isiku tulumaks',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3001%'
         UNION ALL
         -- 302
         SELECT q.rekvid                       AS rekv_id,
                '302',
                'Sotsiaalmaks ja sotsiaalkindlustusmaksed',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '302%'
         UNION ALL
         -- 3020
         SELECT q.rekvid                       AS rekv_id,
                '3020',
                'Sotsiaalmaks',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3020%'
         UNION ALL
         -- 30200
         SELECT q.rekvid                       AS rekv_id,
                '30200',
                'Sotsiaalmaks pensionikindlustuseks',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '30200%'
         UNION ALL
         -- 30201
         SELECT q.rekvid                       AS rekv_id,
                '30201',
                'Sotsiaalmaks ravikindlustuseks',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '30201%'
         UNION ALL
         -- 3025
         SELECT q.rekvid                       AS rekv_id,
                '3025',
                'Töötuskindlustusmaksed',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3025%'
         UNION ALL
         -- 3026
         SELECT q.rekvid                       AS rekv_id,
                '3026',
                'Kogumispension',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3026%'
         UNION ALL
         -- 303
         SELECT q.rekvid                       AS rekv_id,
                '303',
                'Omandimaksud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '303%'
         UNION ALL
         -- 304
         SELECT q.rekvid                       AS rekv_id,
                '304',
                'Maksud kaupadelt ja teenustelt',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '304%'
         UNION ALL
         -- 3042
         SELECT q.rekvid                       AS rekv_id,
                '3042',
                'Aktsiisimaks',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3042%'
         UNION ALL
         -- 30420
         SELECT q.rekvid                       AS rekv_id,
                '30420',
                'Alkoholiaktsiis',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '30420%'
         UNION ALL
         -- 30422
         SELECT q.rekvid                       AS rekv_id,
                '30422',
                'Kütuseaktsiis',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '30422%'
         UNION ALL
         -- 3043
         SELECT q.rekvid                       AS rekv_id,
                '3043',
                'Hasartmängumaks',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3043%'
         UNION ALL
         -- 305
         SELECT q.rekvid                       AS rekv_id,
                '305',
                'Maksud väliskaubanduselt ja tehingutelt',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '305%'
         UNION ALL
         -- 32
         SELECT q.rekvid                       AS rekv_id,
                '32',
                'Kaupade ja teenuste müük',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '32%'
         UNION ALL
         -- 320
         SELECT q.rekvid                       AS rekv_id,
                '320',
                'Riigilõivud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '320%'
         UNION ALL
         -- 322
         SELECT q.rekvid                       AS rekv_id,
                '322',
                'Tulud majandustegevusest',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE left(konto, 3) IN ('322')
         UNION ALL
         -- 3220
         SELECT q.rekvid                       AS rekv_id,
                '3220',
                'Tulud haridusalasest tegevusest',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3220%'
         UNION ALL
         -- 3221
         SELECT q.rekvid                       AS rekv_id,
                '3221',
                'Tulud kultuuri- ja kunstialasest tegevusest',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3221%'
         UNION ALL
         -- 3222
         SELECT q.rekvid                       AS rekv_id,
                '3222',
                'Tulud sprodi- ja puhkealasest tegevusest',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3222%'
         UNION ALL
         -- 3223
         SELECT q.rekvid                       AS rekv_id,
                '3223',
                'Tulud tervishoiust',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3223%'
         UNION ALL
         -- 3224
         SELECT q.rekvid                       AS rekv_id,
                '3224',
                'Tulud sotsiaalabialasest tegevusest',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3224%'
         UNION ALL
         -- 3225
         SELECT q.rekvid                       AS rekv_id,
                '3225',
                'Elamu- ja kommunaaltegevuse tulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3225%'
         UNION ALL
         -- 3227
         SELECT q.rekvid                       AS rekv_id,
                '3227',
                'Tulud korrakaitsest',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3227%'
         UNION ALL
         -- 323
         SELECT q.rekvid                       AS rekv_id,
                '323',
                'Tulud majandustegevusest (järg)',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '323%'
         UNION ALL
         -- 3230
         SELECT q.rekvid                       AS rekv_id,
                '3230',
                'Tulud transpordi- ja sidealasest tegevusest',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3230%'
         UNION ALL
         -- 3232
         SELECT q.rekvid                       AS rekv_id,
                '3232',
                'Tulud muudelt majandusaladelt',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3232%'
         UNION ALL
         -- 3233
         SELECT q.rekvid                       AS rekv_id,
                '3233',
                'Üür ja rent',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3233%'
         UNION ALL
         -- 3237
         SELECT q.rekvid                       AS rekv_id,
                '3237',
                'Õiguste müük',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3237%'
         UNION ALL
         -- 3238
         SELECT q.rekvid                       AS rekv_id,
                '3238',
                'Muu toodete ja teenuste müük',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3238%'
         UNION ALL
         -- 35
         SELECT q.rekvid                       AS rekv_id,
                '35',
                'Saadud toetused',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '35%'
         UNION ALL
         -- 350
         SELECT q.rekvid                       AS rekv_id,
                '350',
                'Saadud sihtfinantseerimine',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '350%'
         UNION ALL
         -- 3500
         SELECT q.rekvid                       AS rekv_id,
                '3500',
                'Saadud sihtfinantseerimine tegevuskuludeks',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3500%'
         UNION ALL
         -- 3502
         SELECT q.rekvid                       AS rekv_id,
                '3502',
                'Saadud sihtfinantseerimine põhivara soetuseks',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3502%'
         UNION ALL
         -- 351
         SELECT q.rekvid                       AS rekv_id,
                '351',
                'Põhivara soetamiseks saadud sihtfinantseerimise amortisatsioon',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '351%'
         UNION ALL
         -- 352
         SELECT q.rekvid                       AS rekv_id,
                '352',
                'Saadud mittesihtotstarbeline finantseerimine',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '352%'
         UNION ALL
         -- 38
         SELECT q.rekvid                       AS rekv_id,
                '38',
                'Muud tulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '38%'
         UNION ALL
         -- 381
         SELECT q.rekvid                       AS rekv_id,
                '381',
                'Kasum/kahjum põhivara ja varude müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '381%'
         UNION ALL
         -- 3810
         SELECT q.rekvid                       AS rekv_id,
                '3810',
                'Kasum/kahjum kinnisvarainvesteeringute müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3810%'
         UNION ALL
         -- 3811
         SELECT q.rekvid                       AS rekv_id,
                '3811',
                'Kasum/kahjum materiaalse põhivara müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3811%'
         UNION ALL
         -- 38110
         SELECT q.rekvid                       AS rekv_id,
                '38110',
                'Kasum/kahjum maa müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '38110%'
         UNION ALL
         -- 38111
         SELECT q.rekvid                       AS rekv_id,
                '38111',
                'Kasum/kahjum hoonete müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '38111%'
         UNION ALL
         -- 38112
         SELECT q.rekvid                       AS rekv_id,
                '38112',
                'Kasum/kahjum rajatiste müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '38112%'
         UNION ALL
         -- 38113
         SELECT q.rekvid                       AS rekv_id,
                '38113',
                'Kasum/kahjum kaitseotstarbelise põhivara müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '38113%'
         UNION ALL
         -- 38115
         SELECT q.rekvid                       AS rekv_id,
                '38115',
                'Kasum/kahjum info- ja kommunikatsioonitehnoloogia seadmete müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '38115%'
         UNION ALL
         -- 38116
         SELECT q.rekvid                       AS rekv_id,
                '38116',
                'Kasum/kahjum muu amortiseeruva materiaalse põhivara müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '38116%'
         UNION ALL
         -- 38117
         SELECT q.rekvid                       AS rekv_id,
                '38117',
                'Kasum/kahjum mitteamortiseeruvate põhivarade müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '38117%'
         UNION ALL
         -- 38118
         SELECT q.rekvid                       AS rekv_id,
                '38118',
                'Kasum/kahjum lõpetamata ehituse müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '38118%'
         UNION ALL
         -- 3813
         SELECT q.rekvid                       AS rekv_id,
                '3813',
                'Kasum/kahjum immateriaalse põhivara müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3813%'
         UNION ALL
         -- 38130
         SELECT q.rekvid                       AS rekv_id,
                '38130',
                'Kasum/kahjum tarkvara müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '38130%'
         UNION ALL
         -- 38132
         SELECT q.rekvid                       AS rekv_id,
                '38132',
                'Kasum/kahjum õiguste ja litsentside müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '38132%'
         UNION ALL
         -- 38136
         SELECT q.rekvid                       AS rekv_id,
                '38136',
                'Kasum/kahjum muu immateriaalse põhivara müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '38136%'
         UNION ALL
         -- 3814
         SELECT q.rekvid                       AS rekv_id,
                '3814',
                'Kasum/kahjum bioloogiliste varade müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '3814%'
         UNION ALL
         -- 3818
         SELECT q.rekvid                       AS rekv_id,
                '3818',
                'Kasum/kahjum varude müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '3818%'
         UNION ALL
         -- 382
         SELECT q.rekvid                       AS rekv_id,
                '382',
                'Muud tulud varadelt',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '382%'
         UNION ALL
         -- 3823
         SELECT q.rekvid                       AS rekv_id,
                '3823',
                'Võlalt arvestatud intressitulu',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3823%'
         UNION ALL
         -- 3825
         SELECT q.rekvid                       AS rekv_id,
                '3825',
                'Tulud loodusressursside kasutamisest',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3825%'
         UNION ALL
         -- 388
         SELECT q.rekvid                       AS rekv_id,
                '388',
                'Muud tulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '388%'
         UNION ALL
         -- 3880
         SELECT q.rekvid                       AS rekv_id,
                '3880',
                'Trahvid',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '3880%'
         UNION ALL
         -- 3882
         SELECT q.rekvid                       AS rekv_id,
                '3882',
                'Saastetasud ja keskkonnale tekitatud kahju hüvitis',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '3882%'
         UNION ALL
         -- 3888
         SELECT q.rekvid                       AS rekv_id,
                '3888',
                'Eespool nimetamata muud tulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '3888%'
         UNION ALL
         -- Saldoandmikust (Sum: Kontod 4*kuni 64* Kreedit) - (Sum: Kontod 4* kuni 64* Deebet)
         SELECT q.rekvid                       AS rekv_id,
                '39999',
                'Tegevuskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                4000
         FROM qrySaldo q
         WHERE val(left(konto, 1)) >= 4
           AND val(left(konto, 2)) <= 64
         UNION ALL
         -- 4
         SELECT q.rekvid                       AS rekv_id,
                '4',
                'ANTUD TOETUSED',
                coalesce(kr) - coalesce(db, 0) AS summa,
                4100
         FROM qrySaldo q
         WHERE left(konto, 1) = '4'
         UNION ALL
         -- 40
         SELECT q.rekvid                       AS rekv_id,
                '40',
                'Subsiidiumid',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '40%'
         UNION ALL
         -- 41
         SELECT q.rekvid                       AS rekv_id,
                '41',
                'Sotsiaaltoetused',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '41%'
         UNION ALL
         -- 410
         SELECT q.rekvid                       AS rekv_id,
                '410',
                'Sotsiaalkindlustustoetused',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '410%'
         UNION ALL
         -- 4100
         SELECT q.rekvid                       AS rekv_id,
                '4100',
                'Pensionikindlustustoetused sotsiaalmaksutuludest',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '4100%'
         UNION ALL
         -- 4102
         SELECT q.rekvid                       AS rekv_id,
                '4102',
                'Pensionikindlustustoetused mitte sotsiaalmaksutuludest',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '4102%'
         UNION ALL
         -- 4105
         SELECT q.rekvid                       AS rekv_id,
                '4105',
                'Ravikindlustustoetused',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '4105%'
         UNION ALL
         -- 4108
         SELECT q.rekvid                       AS rekv_id,
                '4108',
                'Töötuskindlustustoetused',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '4108%'
         UNION ALL
         -- 413
         SELECT q.rekvid                       AS rekv_id,
                '413',
                'Sotsiaalabitoetused ja muud toetused füüsilistele isikutele',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '413%'
         UNION ALL
         -- 4130
         SELECT q.rekvid                       AS rekv_id,
                '4130',
                'Peretoetused',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '4130%'
         UNION ALL
         -- 4132
         SELECT q.rekvid                       AS rekv_id,
                '4132',
                'Toetused töötutele',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '4132%'
         UNION ALL
         -- 4133
         SELECT q.rekvid                       AS rekv_id,
                '4133',
                'Toetused puudega inimestele ja nende hooldajatele',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '4133%'
         UNION ALL
         -- 4134
         SELECT q.rekvid                       AS rekv_id,
                '4134',
                'Õppetoetused',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '4134%'
         UNION ALL
         -- 4137
         SELECT q.rekvid                       AS rekv_id,
                '4137',
                'Erijuhtudel riigi poolt makstav sotsiaalmaks',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '4137%'
         UNION ALL
         -- 4138
         SELECT q.rekvid                       AS rekv_id,
                '4138',
                'Muud sotsiaalabitoetused',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '4138%'
         UNION ALL
         -- 4139
         SELECT q.rekvid                       AS rekv_id,
                '4139',
                'Preemiad ja stipendiumid',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '4139%'
         UNION ALL
         -- 414
         SELECT q.rekvid                       AS rekv_id,
                '414',
                'Sotsiaaltoetused avaliku sektori töövõtjatele',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '414%'
         UNION ALL
         -- 45
         SELECT q.rekvid                       AS rekv_id,
                '45',
                'Muud toetused',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '45%'
         UNION ALL
         -- 450
         SELECT q.rekvid                       AS rekv_id,
                '450',
                'Antud sihtfinantseerimine',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '450%'
         UNION ALL
         -- 4500
         SELECT q.rekvid                       AS rekv_id,
                '4500',
                'Antud sihtfinantseerimine tegevuskuludeks',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '4500%'
         UNION ALL
         -- 4502
         SELECT q.rekvid                       AS rekv_id,
                '4502',
                'Antud sihtfinantseerimine põhivara soetuseks',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '4502%'
         UNION ALL
         -- 452
         SELECT q.rekvid                       AS rekv_id,
                '452',
                'Antud mittesihtotstarbeline finantseerimine',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '452%'
         UNION ALL
         -- 5
         SELECT q.rekvid                       AS rekv_id,
                '5',
                'Tegevuskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                5000
         FROM qrySaldo q
         WHERE konto LIKE '5%'
         UNION ALL
         -- 50
         SELECT q.rekvid                       AS rekv_id,
                '50',
                'Tööjõukulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '50%'
         UNION ALL
         -- 500
         SELECT q.rekvid                       AS rekv_id,
                '500',
                'Töötasu',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '500%'
         UNION ALL
         -- 5000
         SELECT q.rekvid                       AS rekv_id,
                '5000',
                'Valitavate ja ametisse nimetatud ametnikud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '5000%'
         UNION ALL
         -- 5001
         SELECT q.rekvid                       AS rekv_id,
                '5001',
                'Avaliku teenistuse ametnikud (va kaitseväelased, piirivalve-, politseiametnikud)',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '5001%'
         UNION ALL
         -- 50010
         SELECT q.rekvid                       AS rekv_id,
                '50010',
                'Kõrgemad ametnikud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '50010%'
         UNION ALL
         -- 50012
         SELECT q.rekvid                       AS rekv_id,
                '50012',
                'Tippspetsialistide töötasu',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '50012%'
         UNION ALL
         -- 50014
         SELECT q.rekvid                       AS rekv_id,
                '50014',
                'Vanemametnikud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '50014%'
         UNION ALL
         -- 50015
         SELECT q.rekvid                       AS rekv_id,
                '50015',
                'Nooremametnikud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '50015%'
         UNION ALL
         -- 5002
         SELECT q.rekvid                       AS rekv_id,
                '5002',
                'Töötajate töötasu',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '5002%'
         UNION ALL
         -- 50020
         SELECT q.rekvid                       AS rekv_id,
                '50020',
                'Nõukogude ja juhatuste liikmed',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '50020%'
         UNION ALL
         -- 50021
         SELECT q.rekvid                       AS rekv_id,
                '50021',
                'Juhid',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '50021%'
         UNION ALL
         -- 50024
         SELECT q.rekvid                       AS rekv_id,
                '50024',
                'Tippspetsialistid',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '50024%'
         UNION ALL
         -- 50025
         SELECT q.rekvid                       AS rekv_id,
                '50025',
                'Keskastme spetsialistid',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '50025%'
         UNION ALL
         -- 50026
         SELECT q.rekvid                       AS rekv_id,
                '50026',
                'Õpetajad',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '50026%'
         UNION ALL
         -- 500267
         SELECT q.rekvid                       AS rekv_id,
                '50027',
                'Nooremspetsialistide ja assistentide töötasu',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '50027%'
         UNION ALL
         -- 50028
         SELECT q.rekvid                       AS rekv_id,
                '50028',
                'Töölised ja abiteenistujad',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '50028%'
         UNION ALL
         -- 50029
         SELECT q.rekvid                       AS rekv_id,
                '50029',
                'Tugispetsialistide töötasu',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '50029%'
         UNION ALL
         -- 5008
         SELECT q.rekvid                       AS rekv_id,
                '5008',
                'Muud koosseisuvälised töötasud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '5008%'
         UNION ALL
         -- 505
         SELECT q.rekvid                       AS rekv_id,
                '505',
                'Erisoodustused',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '505%'
         UNION ALL
         -- 506
         SELECT q.rekvid                       AS rekv_id,
                '506',
                'Maksud ja sotsiaalkindlustusmaksed',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '506%'
         UNION ALL
         -- 507
         SELECT q.rekvid                       AS rekv_id,
                '507',
                'Tööjõukulude kapitaliseerimine',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '507%'
         UNION ALL
         -- 55
         SELECT q.rekvid                       AS rekv_id,
                '55',
                'Majandamiskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '55%'
         UNION ALL
         -- 5500
         SELECT q.rekvid                       AS rekv_id,
                '5500',
                'Administreerimiskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '5500%'
         UNION ALL
         -- 5503
         SELECT q.rekvid                       AS rekv_id,
                '5503',
                'Lähetuskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '5503%'
         UNION ALL
         -- 55031
         SELECT q.rekvid                       AS rekv_id,
                '55031',
                'Pikaajalised lähetused',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '55031%'
         UNION ALL
         -- 5504
         SELECT q.rekvid                       AS rekv_id,
                '5504',
                'Koolituskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '5504%'
         UNION ALL
         -- 5511
         SELECT q.rekvid                       AS rekv_id,
                '5511',
                'Kinnistute, hoonete ja ruumide majandamiskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '5511%'
         UNION ALL
         -- 5512
         SELECT q.rekvid                       AS rekv_id,
                '5512',
                'Rajatiste majandamiskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '5512%'
         UNION ALL
         -- 5513
         SELECT q.rekvid                       AS rekv_id,
                '5513',
                'Sõidukite majandamiskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '5513%'
         UNION ALL
         -- 5514
         SELECT q.rekvid                       AS rekv_id,
                '5514',
                'Info- ja kommunikatsioonitehnoloogia kulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '5514%'
         UNION ALL
         -- 5515
         SELECT q.rekvid                       AS rekv_id,
                '5515',
                'Inventari majandamiskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '5515%'
         UNION ALL
         -- 5516
         SELECT q.rekvid                       AS rekv_id,
                '5516',
                'Töömasinate ja seadmete majandamiskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '5516%'
         UNION ALL
         -- 5521
         SELECT q.rekvid                       AS rekv_id,
                '5521',
                'Toiduained ja toitlustusteenused',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '5521%'
         UNION ALL
         -- 5522
         SELECT q.rekvid                       AS rekv_id,
                '5522',
                'Meditsiinikulud ja hügieenikulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '5522%'
         UNION ALL
         -- 5523
         SELECT q.rekvid                       AS rekv_id,
                '5523',
                'Teavikute ja kunstiesemete kulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '5523%'
         UNION ALL
         -- 5524
         SELECT q.rekvid                       AS rekv_id,
                '5524',
                'Õppevahendite ja koolituse kulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '5524%'
         UNION ALL
         -- 5525
         SELECT q.rekvid                       AS rekv_id,
                '5525',
                'Kommunikatsiooni-, kultuuri- ja vaba aja sisustamise kulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '5525%'
         UNION ALL
         -- 5526
         SELECT q.rekvid                       AS rekv_id,
                '5526',
                'Sotsiaalteenused',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '5526%'
         UNION ALL
         -- 5529
         SELECT q.rekvid                       AS rekv_id,
                '5529',
                'Tootmiskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '5529%'
         UNION ALL
         -- 5531
         SELECT q.rekvid                       AS rekv_id,
                '5531',
                'Kaitseotstarbeline varustus ja materjalid',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '5531%'
         UNION ALL
         -- 5532
         SELECT q.rekvid                       AS rekv_id,
                '5532',
                'Eri- ja vormiriietus (va kaitseotstarbelised kulud)',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '5532%'
         UNION ALL
         -- 5539
         SELECT q.rekvid                       AS rekv_id,
                '5539',
                'Muu erivarustus ja materjalid',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '5539%'
         UNION ALL
         -- 5540
         SELECT q.rekvid                       AS rekv_id,
                '5540',
                'Mitmesugused majanduskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '5540%'
         UNION ALL
         -- 6
         SELECT q.rekvid                       AS rekv_id,
                '6',
                'Muud kulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                6000
         FROM qrySaldo q
         WHERE left(konto, 1) = '6'
         UNION ALL
         -- 60
         SELECT q.rekvid                       AS rekv_id,
                '60',
                'Muud tegevuskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '60%'
         UNION ALL
         -- 600
         SELECT q.rekvid                       AS rekv_id,
                '600',
                'Riigisaladusega seotud kulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '600%'
         UNION ALL
         -- 601
         SELECT q.rekvid                       AS rekv_id,
                '601',
                'Maksu-, lõivu- ja trahvikulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '601%'
         UNION ALL
         -- 6010
         SELECT q.rekvid                       AS rekv_id,
                '6010',
                'Maksud, lõivud, trahvid',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '6010%'
         UNION ALL
         -- 6012
         SELECT q.rekvid                       AS rekv_id,
                '6012',
                'Ebatõenäoliselt laekuvad maksu-, lõivu- ja trahvinõuded',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '6012%'
         UNION ALL
         -- 6015
         SELECT q.rekvid                       AS rekv_id,
                '6015',
                'Edasiantud maksud, lõivud, trahvid',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '6015%'
         UNION ALL
         -- 605
         SELECT q.rekvid                       AS rekv_id,
                '605',
                'Ebatõenäoliselt laekuvad nõuded',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '605%'
         UNION ALL
         -- 608
         SELECT q.rekvid                       AS rekv_id,
                '608',
                'Muud tegevuskulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
                  LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(q.konto)) = ltrim(rtrim(l.kood))
         WHERE konto LIKE '608%'
         UNION ALL
         -- 61
         SELECT q.rekvid                       AS rekv_id,
                '61',
                'Põhivara amortisatsioon ja ümberhindlus',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '61%'
         UNION ALL
         -- 611
         SELECT q.rekvid                       AS rekv_id,
                '611',
                'Materiaalse põhivara amortisatsioon',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '611%'
         UNION ALL
         -- 6110
         SELECT q.rekvid                       AS rekv_id,
                '6110',
                'Hoonete ja rajatiste amortisatsioon',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '6110%'
         UNION ALL
         -- 6114
         SELECT q.rekvid                       AS rekv_id,
                '6114',
                'Masinate ja seadmete amortisatsioon',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '6114%'
         UNION ALL
         -- 613
         SELECT q.rekvid                       AS rekv_id,
                '613',
                'Immateriaalse põhivara amortisatsioon',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '613%'
         UNION ALL
         -- 614
         SELECT q.rekvid                       AS rekv_id,
                '614',
                'Kasum/kahjum bioloogiliste varade ümberhindamisest',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '614%'
         UNION ALL
         --Saldoandmikust (Sum: Kontod 3*kuni 64* Kreedit) - (Sum: Kontod 3* kuni 64* Deebet)
         SELECT q.rekvid                       AS rekv_id,
                '9999',
                'Aruandeperioodi tegevustulem',
                coalesce(kr) - coalesce(db, 0) AS summa,
                6500                           AS idx
         FROM qrySaldo q
         WHERE val(left(konto, 1)) >= 3
           AND val(left(konto, 2)) <= 64
         UNION ALL
         -- 65
         SELECT q.rekvid                       AS rekv_id,
                '65',
                'Finantstulud ja -kulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '65%'
         UNION ALL
         -- 650
         SELECT q.rekvid                       AS rekv_id,
                '650',
                'Intressikulu',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '650%'
         UNION ALL
         -- 652
         SELECT q.rekvid                       AS rekv_id,
                '652',
                'Tulem osalustelt',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '652%'
         UNION ALL
         -- 655
         SELECT q.rekvid                       AS rekv_id,
                '655',
                'Tulu hoiustelt ja väärtpaberitelt',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '655%'
         UNION ALL
         -- 6550
         SELECT q.rekvid                       AS rekv_id,
                '6550',
                'Intressitulu',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '6550%'
         UNION ALL
         -- 6552
         SELECT q.rekvid                       AS rekv_id,
                '6552',
                'Kasum/kahjum finantsinvesteeringute müügist',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '6552%'
         UNION ALL
         -- 6554
         SELECT q.rekvid                       AS rekv_id,
                '6554',
                'Kasum/kahjum finantsinvesteeringute ümberhindamisest',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '6554%'
         UNION ALL
         -- 658
         SELECT q.rekvid                       AS rekv_id,
                '658',
                'Muud finantstulud ja -kulud',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '658%'
         UNION ALL
         -- 6580
         SELECT q.rekvid                       AS rekv_id,
                '6580',
                'Intressitulu',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '6580%'
         UNION ALL
         -- 6589
         SELECT q.rekvid                       AS rekv_id,
                '6589',
                'Muu finantstulu ja -kulu',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '6589%'
         UNION ALL
         --Saldoandmikust (Sum: Kontod 3*kuni 6* Kreedit) - (Sum: Kontod 3* kuni 6* Deebet)
         SELECT q.rekvid                       AS rekv_id,
                '99999',
                'Aruandeperioodi tulem',
                coalesce(kr) - coalesce(db, 0) AS summa,
                7000                           AS idx
         FROM qrySaldo q
         WHERE val(left(konto, 1)) >= 3
           AND val(left(konto, 1)) <= 6
         UNION ALL
         --Saldoandmikust (Sum: Kontod 3*kuni 7* Kreedit) - (Sum: Kontod 3* kuni 7* Deebet)
         SELECT q.rekvid                       AS rekv_id,
                '9999999',
                'Aruandeperioodi tulem ja siirded kokku',
                coalesce(kr) - coalesce(db, 0) AS summa,
                9000                           AS idx
         FROM qrySaldo q
         WHERE val(left(konto, 1)) >= 3
           AND val(left(konto, 1)) <= 7
         UNION ALL
         -- 7
         SELECT q.rekvid                       AS rekv_id,
                '7',
                'Netofinantseerimine eelarvest',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '7%'
         UNION ALL
         -- 70
         SELECT q.rekvid                       AS rekv_id,
                '70',
                'Saadud siirded',
                coalesce(kr) - coalesce(db, 0) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '70%'
         UNION ALL
         --Saldoandmikust (Sum: Kontod 3*kuni 7* Kreedit) - (Sum: Kontod 3* kuni 7* Deebet)
         SELECT q.rekvid                       AS rekv_id,
                '71',
                'Antud siirded',
                coalesce(kr) - coalesce(db, 0) AS summa,
                7000
         FROM qrySaldo q
         WHERE val(left(ltrim(rtrim(konto)), 1)) >= 3
           AND val(left(ltrim(rtrim(konto)), 1)) <= 7
         UNION ALL
         -- 9
         -- 900
         SELECT q.rekvid                       AS rekv_id,
                '900',
                'Töötajate arv',
                (coalesce(db, 0) - coalesce(kr)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '900%'
         UNION ALL
         -- 9001
         SELECT q.rekvid                       AS rekv_id,
                '9001',
                'Avaliku teenistuse ametnikud',
                abs(coalesce(db) - coalesce(kr, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '9001%'
         UNION ALL
         -- 9002
         SELECT q.rekvid                       AS rekv_id,
                '9002',
                'Töötajad',
                abs(coalesce(kr) - coalesce(db, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '9002%'
         UNION ALL
         -- 91
         SELECT q.rekvid                       AS rekv_id,
                '91',
                'Kohustised ja nõuded',
                abs(coalesce(db) - coalesce(kr, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '91%'
         UNION ALL
         -- 910
         SELECT q.rekvid                       AS rekv_id,
                '910',
                'Võetud pikaajaliste laenukohustiste jaotus järelejäänud tähtaja järgi',
                abs(coalesce(db) - coalesce(kr, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '910%'
         UNION ALL
         -- 911
         SELECT q.rekvid                       AS rekv_id,
                '911',
                'Bilansivälised kohustised',
                abs(coalesce(kr) - coalesce(db, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '911%'
         UNION ALL
         -- 912
         SELECT q.rekvid                       AS rekv_id,
                '912',
                'Bilansivälised kohustised',
                abs(coalesce(kr) - coalesce(db, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '912%'
         UNION ALL
         -- 921
         SELECT q.rekvid                       AS rekv_id,
                '921',
                'Kapitalirendi tingimustel rendile võetud varad',
                (coalesce(db) - coalesce(kr, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '921%'
         UNION ALL
         -- 9211
         SELECT q.rekvid                       AS rekv_id,
                '9211',
                'Hooned ja rajatised',
                (coalesce(db) - coalesce(kr, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '9211%'
         UNION ALL
         -- 9214
         SELECT q.rekvid                       AS rekv_id,
                '9214',
                'Masinad ja seadmed',
                (coalesce(db) - coalesce(kr, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '9214%'
         UNION ALL
         -- 922
         SELECT q.rekvid                       AS rekv_id,
                '922',
                'Kasutusrendile antud varad',
                (coalesce(db) - coalesce(kr, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '922%'
         UNION ALL
         -- 9220
         SELECT q.rekvid                       AS rekv_id,
                '9220',
                'Kinnisvarainvesteeringud',
                (coalesce(db) - coalesce(kr, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '9220%'
         UNION ALL
         -- 9221
         SELECT q.rekvid                       AS rekv_id,
                '9221',
                'Kinnisvarainvesteeringud',
                (coalesce(db) - coalesce(kr, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '9221%'
         UNION ALL
         -- 9222
         SELECT q.rekvid                       AS rekv_id,
                '9222',
                'Hooned ja rajatised',
                (coalesce(db) - coalesce(kr, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '9222%'
         UNION ALL
         -- 9224
         SELECT q.rekvid                       AS rekv_id,
                '9224',
                'Masinad ja seadmed',
                (coalesce(db) - coalesce(kr, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '9224%'
         UNION ALL
         -- 9226
         SELECT q.rekvid                       AS rekv_id,
                '9226',
                'Muu amortiseeruv materiaalne põhivara',
                (coalesce(db) - coalesce(kr, 0)) AS summa,
                idx
         FROM qrySaldo q
         WHERE konto LIKE '9226%'
     ) qry
         LEFT OUTER JOIN (
    SELECT kood, nimetus
    FROM com_kontoplaan
    UNION ALL
    SELECT '39999', 'Tegevuskulud'
    UNION ALL
    SELECT '99999', 'Aruandeperioodi tulem'
    UNION ALL
    SELECT '9999', 'Aruandeperioodi tegevustulem'
    UNION ALL
    SELECT '9999999', 'Aruandeperioodi tulem ja siirded kokku'
    UNION ALL
    SELECT '900', 'Töötajate arv'
) l ON ltrim(rtrim(qry.konto)) = ltrim(rtrim(l.kood))

GROUP BY rekv_id, konto, l.nimetus, idx

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION eelarve.pikk_tulem(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.pikk_tulem(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.pikk_tulem(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.pikk_tulem(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbvaatleja;


SELECT sum(summa),
       konto,
       nimetus,
       idx
FROM eelarve.pikk_tulem('2020-12-31' :: DATE, 63, 1)
GROUP BY konto, nimetus, idx
ORDER BY konto, idx


