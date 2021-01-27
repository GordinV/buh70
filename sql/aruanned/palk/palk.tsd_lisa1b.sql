DROP FUNCTION IF EXISTS palk.tsd_lisa_1b(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION palk.tsd_lisa_1b(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE (
        c_1300      VARCHAR(20),
        c_1310      VARCHAR(254),
        c_1320      VARCHAR(20),
        c_1330      NUMERIC(14, 2),
        c_1340      INTEGER,
        c_1350      INTEGER,
        c_1360      VARCHAR(10),
        pohjus_selg TEXT,
        c_1370      NUMERIC(14, 2),
        c_1380      NUMERIC(14, 2),
        c_1390      NUMERIC(14, 2),
        c_1400      NUMERIC(14, 2),
        c_1410      NUMERIC(14, 2),
        c_1420      NUMERIC(14, 2),
        c_1430      NUMERIC(14, 2),
        c_1440      NUMERIC(14, 2),
        c_1450      NUMERIC(14, 2),
        c_1460      VARCHAR(10),
        c_1470      NUMERIC(14, 2),
        c_1480      NUMERIC(14, 2),
        c_1500      NUMERIC(14, 2),
        c_1510      NUMERIC(14, 2),
        c_1520      NUMERIC(14, 2),
        c_1530      NUMERIC(14, 2),
        c_1540      NUMERIC(14, 2),
        c_1550      NUMERIC(14, 2)

    ) AS
$BODY$
SELECT *,
       -- Koodil 1500 summeeritakse koodil 1370 näidatud tagastatud või tasaarvestatud sotsiaalmaksuga maksustatud väljamaksed
       sum(c_1370) OVER () AS c_1500,
-- Koodil 1510 summeeritakse koodil 1410 näidatud tagastatud või tasaarvestatud väljamakselt arvutatud sotsiaalmaks, mis kantakse vormi TSD koodile 115
       sum(c_1410) OVER () AS c_1510,
-- Koodil 1520 summeeritakse koodil 1420 näidatud tagastatud või tasaarvestatud väljamakselt
-- kinnipeetud kohustuslik kogumispensioni makse, mis kantakse vormi TSD koodile 117.
       sum(c_1420) OVER () AS c_1520,
       -- Koodil 1530 summeeritakse koodil 1440 näidatud tagastatud või tasaarvestatud väljamakselt kinnipeetud töötuskindlustusmakse, mis kantakse vormi TSD koodile 116
       sum(c_1440) OVER () AS c_1530,
--Koodil 1540 summeeritakse koodil 1450 näidatud tagastatud või tasaarvestatud väljamakselt arvutatud tööandja töötuskindlustusmakse, mis kantakse vormi TSD koodile 116.
       sum(c_1450) OVER () AS c_1540,
-- Koodil 1550 summeeritakse koodil 1480 tagastatud või tasaarvestatud väljamakselt kinnipeetud tulumaks, mis kantakse vormi TSD koodile 110
       sum(c_1480) OVER () AS c_1550

FROM (
         SELECT isikukood::VARCHAR(20)                                                                     AS c_1300,
                isik::VARCHAR(254)                                                                         AS c_1310,
                tululiik                                                                                   AS c_1320,
                sum(abs(summa))                                                                            AS c_1330,
                year(period)                                                                               AS c_1340,
                month(period)                                                                              AS c_1350,
                pohjus                                                                                     AS c_1360,
                pohjus_selg                                                                                AS pohjus_selg,
                sum(qry.c_1370)                                                                            AS c_1370,
                sum(qry.c_1380)                                                                            AS c_1380, -- Koodil 1380 näidatakse väljamakse tegemise kuul Ia osas koodidel 1070 või 1080 näidatud mahaarvamised või nende osa, mis vastab maksustamisperioodil tagastatud või tasaarvestatud väljamaksele
                sum(qry.c_1390)                                                                            AS c_1390, -- Koodil 1390 näidatakse koodidel 1340 ja 1350 näidatud maksustamisperioodil (väljamakse tegemise kuu) Ia osas koodil 1090 näidatud sotsiaalmaksuga maksustatud väljamakse suurendus või selle osa, mis vastab maksustamisperioodil tagastatud või tasaarvestatud väljamaksele
                -- 38. Koodil 1400 näidatakse tagastatud sotsiaalmaksuga maksustatud väljamakse vähendus.
                -- Kood 1400 täidetakse juhul, kui koodidel 1340 ja 1350 näidatud maksustamisperioodil (väljamakse tegemise kuu)
                -- säilib tööandjal sotsiaalmaksu miinimumkohustus, mistõttu tal ei ole tagastatavalt väljamakselt arvutatud sotsiaalmaksu või selle osa tagasisaamise õigust.
                sum(qry.c_1400)                                                                            AS c_1400,
-- 39. Koodil 1410 näidatakse tagastatud väljamakselt arvutatud sotsiaalmaksu summa järgmise valemi
-- alusel: Kood 1410 = (kood 1370 – kood 1380 + kood 1390 – kood 1400) x sotsiaalmaksu määr.
                sum(abs(qry.sotsmaks))                                                                     AS c_1410,
-- 40. Koodil 1420 näidatakse koodil 1370 näidatud tagastatud või tasaarvestatud väljamakselt kinnipeetud
-- kogumispensioni makse.
                sum(abs(qry.pensmaks))                                                                     AS c_1420,
-- 41. Koodil 1430 näidatakse töötuskindlustusmaksega maksustatavad väljamaksed, mis vastavad koodil 1330 deklareeritud tagastatud või tasaarvestatud väljamakse summale koodil 1320 näidatud väljamakse liikidele 10, 11, 14, 17, 18, 19, 25, 26, 52.
                sum(ABS(qry.summa) * qry.tka_arv)                                                          AS c_1430,
-- 42. Koodil 1440 näidatakse tagastatud töötuskindlustusmaksega maksustatavalt väljamakselt kinnipeetud kindlustatu töötuskindlustusmakse järgmise valemiga:
                sum(abs(qry.tootumaks))                                                                    AS c_1440,
-- Koodil 1450 näidatakse tagastatud töötuskindlustusmaksega maksustatavalt väljamakselt arvutatud tööandja töötuskindlustusmakse järgmise valemi alusel:
                sum(abs(qry.tka))                                                                          AS c_1450,
-- Koodidel 1460 ja 1470 näidatakse tulumaksu kinnipidamisel maha arvatud maksuvaba tulu liik ja
-- summa
                CASE WHEN abs(qry.tulubaas) > 0 OR qry.kas_taotlus_mvt THEN '610' ELSE '' END::VARCHAR(10) AS c_1460,
                sum(abs(qry.tulubaas))                                                                     AS c_1470,
                sum(abs(qry.tulumaks))                                                                     AS c_1480
         FROM (
                  SELECT a.regkood                                                                AS isikukood,
                         a.nimetus                                                                AS isik,
                         po.summa                                                                 AS summa,
                         po.pohjus,
                         po.properties ->> 'pohjus_selg'                                          AS pohjus_selg,
                         po.period,
                         pl.tululiik,
                         a.id,
                         t.rekvId,
                         coalesce(l.tun2, 0)                                                      AS sm_arv,
                         coalesce(l.tun4, 0)                                                      AS tka_arv,
                         t.id                                                                     AS lepingid,
                         po.tulubaas,
                         po.tulumaks,
                         exists(SELECT mvt.id
                                FROM palk.taotlus_mvt mvt
                                         INNER JOIN palk.tooleping t ON t.id = mvt.lepingid
                                WHERE year(mvt.lopp_kpv) >= year(l_kpv2)
--                                  AND mvt.summa > 0
                                  AND t.parentid IN (SELECT id FROM libs.asutus WHERE id = a.id)) AS kas_taotlus_mvt,
                         abs(po.summa * coalesce(l.tun2, 0))                                      AS c_1370,
                         CASE WHEN po.summa > 0 THEN abs(po.Summa) ELSE 0 END::NUMERIC            AS c_1380, -- Koodil 1380 näidatakse väljamakse tegemise kuul Ia osas koodidel 1070 või 1080 näidatud mahaarvamised või nende osa, mis vastab maksustamisperioodil tagastatud või tasaarvestatud väljamaksele
                         CASE WHEN po.summa > 0 THEN ABS(po.Summa) ELSE 0 END::NUMERIC            AS c_1390, -- Koodil 1390 näidatakse koodidel 1340 ja 1350 näidatud maksustamisperioodil (väljamakse tegemise kuu) Ia osas koodil 1090 näidatud sotsiaalmaksuga maksustatud väljamakse suurendus või selle osa, mis vastab maksustamisperioodil tagastatud või tasaarvestatud väljamaksele
                         -- 38. Koodil 1400 näidatakse tagastatud sotsiaalmaksuga maksustatud väljamakse vähendus.
                         -- Kood 1400 täidetakse juhul, kui koodidel 1340 ja 1350 näidatud maksustamisperioodil (väljamakse tegemise kuu)
                         -- säilib tööandjal sotsiaalmaksu miinimumkohustus, mistõttu tal ei ole tagastatavalt väljamakselt arvutatud sotsiaalmaksu või selle osa tagasisaamise õigust.
                         coalesce((SELECT sum(po.sotsmaks)
                                   FROM palk.palk_oper po
                                            INNER JOIN libs.library pl ON pl.id = po.libId
                                   WHERE YEAR(kpv) = year(period)
                                     AND MONTH(kpv) = month(period)
                                     AND po.lepingid = lepingid
                                     AND pl.properties::JSONB ->> 'liik' = '5'), 0)::NUMERIC      AS c_1400,
                         po.sotsmaks,
                         po.pensmaks,
                         po.tka,
                         po.tootumaks,
                         COALESCE(t.lopp, '2099-12-31' :: DATE)                                   AS lopp

--             36. Koodil 1370 näidatakse tagastatud või tasaarvestatud sotsiaalmaksuga maksustatavad tegelikud väljamaksed, mis vastavad koodil 1330 deklareeritud väljamakse summale koodil 1320 näidatud väljamakse liikidele 10, 11, 13, 14, 15, 17, 18, 19, 21, 22, 25, 26, 28, 29, 30, 33, 34, 41, 42, 43.
                  FROM palk.tooleping t
                           INNER JOIN libs.asutus a ON a.id = t.parentid
                           INNER JOIN palk.palk_oper po ON po.lepingid = t.id
                           INNER JOIN palk.com_palk_lib pl ON pl.id = po.libId
                           LEFT OUTER JOIN libs.LIBRARY l ON l.kood = pl.tululiik AND l.library = 'MAKSUKOOD'
                           LEFT OUTER JOIN palk.palk_kaart pk ON pk.lepingId = t.id AND pk.libid = po.libid
                           INNER JOIN ou.rekv ON rekv.id = po.rekvid
                  WHERE po.kpv >= l_kpv1
                    AND po.kpv <= l_kpv2
                    AND period IS NOT NULL
                    AND pl.liik = 1
                    AND t.resident = 1
                    AND rekv.id = (CASE
                                       WHEN l_kond IS NOT NULL
                                           THEN l_rekvid
                                       ELSE rekv.id END)
                    AND rekv.Id IN (SELECT rekv_id
                                    FROM get_asutuse_struktuur(l_rekvid))
              ) qry
         GROUP BY isikukood, isik, tululiik, year(period), month(period), pohjus, pohjus_selg,
                  (CASE WHEN abs(qry.tulubaas) > 0 OR qry.kas_taotlus_mvt THEN '610' ELSE '' END::VARCHAR(10))
     ) prel
ORDER BY c_1310, c_1320
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.tsd_lisa_1b( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.tsd_lisa_1b( DATE, DATE, INTEGER, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.tsd_lisa_1b( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;


SELECT *
FROM (
         SELECT *
         FROM palk.tsd_lisa_1b('2021-01-01', '2021-01-31', 106, 0 :: INTEGER)
     ) qry
WHERE c_1300 = '46111203717'

/*

select * from ou.rekv where regkood = '75008611  '

select * from palk.palk_oper where
    lepingid in (select id from palk.tooleping where parentid in (select id from libs.asutus where regkood = '47304043719'))

*/