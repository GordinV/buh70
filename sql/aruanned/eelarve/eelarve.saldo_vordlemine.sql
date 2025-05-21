DROP FUNCTION IF EXISTS eelarve.saldo_vordlemine( DATE, INTEGER );
DROP FUNCTION IF EXISTS eelarve.saldo_vordlemine_( DATE, INTEGER );

CREATE OR REPLACE FUNCTION eelarve.saldo_vordlemine(l_kpv DATE, l_rekvid INTEGER)
  RETURNS TABLE(
    tp          VARCHAR(20),
    summa_12    NUMERIC(14, 2),
    summa_21    NUMERIC(14, 2),
    summa_346   NUMERIC(14, 2),
    summa_463   NUMERIC(14, 2),
    summa_7     NUMERIC(14, 2),
    summa_kokku NUMERIC(14, 2)
  ) AS
$BODY$
DECLARE
  v_omatp RECORD;
  v_tp    RECORD;
BEGIN

  DROP TABLE IF EXISTS temp_saldoandmik_table;
  CREATE TEMPORARY TABLE temp_saldoandmik_table (
    oma_tp  VARCHAR(20),
    tp      VARCHAR(20),
    summa01 NUMERIC(14, 2),
    summa02 NUMERIC(14, 2),
    summa03 NUMERIC(14, 2),
    summa04 NUMERIC(14, 2),
    summa05 NUMERIC(14, 2),
    summa06 NUMERIC(14, 2),
    summa07 NUMERIC(14, 2),
    summa08 NUMERIC(14, 2),
    summa09 NUMERIC(14, 2),
    summa10 NUMERIC(14, 2),
    summa11 NUMERIC(14, 2),
    summa12 NUMERIC(14, 2)
  );

  FOR v_omatp IN
  SELECT DISTINCT ltrim(rtrim(omatp)) AS oma_tp
  FROM eelarve.saldoandmik
  WHERE aasta = year(l_kpv) AND kuu = month(l_kpv)
        AND left(omatp, 4) = '1851'
  LOOP
    FOR v_tp IN
    SELECT DISTINCT ltrim(rtrim(s.tp)) AS tp
    FROM eelarve.saldoandmik s
    WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
          AND rtrim(s.tp) <> rtrim(s.omatp) AND
          left(s.tp, 4) = left(v_omatp.oma_tp, 4)
    LOOP
      RAISE NOTICE 'v_omatp.oma_tp %,  v_tp.tp %', v_omatp.oma_tp, v_tp.tp;

      -- (esitaja saldoandmik sum (kõik kontod algusega 1, mille TP kood on võrreldava kood (deebet miinus kreedit)))
      INSERT INTO temp_saldoandmik_table (oma_Tp, tp, summa01, summa02, summa03, summa04, summa05, summa06, summa07, summa08, summa09, summa10, summa11, summa12)
        SELECT
          v_omatp.oma_tp,
          v_tp.tp,
          -- (esitaja saldoandmik sum (kõik kontod algusega 1, mille TP kood on võrreldava kood (deebet miinus kreedit)))

          sum(db - kr)
            FILTER (WHERE ltrim(rtrim(s.omatp)) = ltrim(rtrim(v_omatp.oma_tp))
                          AND ltrim(rtrim(s.tp)) = ltrim(rtrim(v_tp.tp))
                          AND s.konto LIKE '1%'
            ) AS summa01,
          -- (võrreldava saldoandmik (kõik kontod algusega 2, mille TP kood on aruande koostaja kood (kreedit miinus deebet)))

          sum(kr - db)
            FILTER (WHERE ltrim(rtrim(s.omatp)) = ltrim(rtrim(v_tp.tp))
                          AND ltrim(rtrim(s.tp)) = ltrim(rtrim(v_omatp.oma_tp))
                          AND s.konto LIKE '2%'
            ) AS summa02,
          -- (võrreldava saldoandmik (kõik kontod algusega 1, mille TP kood on aruande koostaja kood (deebet miinus kreedit)))
          sum(db - kr)
            FILTER (WHERE ltrim(rtrim(s.omatp)) = ltrim(rtrim(v_tp.tp))
                          AND ltrim(rtrim(s.tp)) = ltrim(rtrim(v_omatp.oma_tp))
                          AND s.konto LIKE '1%'

            ) AS summa03,
          -- (esitaja saldoandmik sum (kõik kontod algusega 2, mille TP kood on võrreldava kood (kreedit miinus deebet)))
          sum(kr - db)
            FILTER (WHERE ltrim(rtrim(s.omatp)) = ltrim(rtrim(v_omatp.oma_tp))
                          AND ltrim(rtrim(s.tp)) = ltrim(rtrim(v_tp.tp))
                          AND s.konto LIKE '2%'
            ) AS summa04,
          -- (võrreldava saldoandmik (kõik kontod algusega 4 kuni 6, mille esitaja kood on TP kood on aruande koostaja kood (deebet miinus kreedit,
          --	välja arvatud kontod 601000 ja 601001, mida ei võeta üldse arvesse olenemata TP koodist)))
          sum(db - kr)
            FILTER (WHERE ltrim(rtrim(s.omatp)) = ltrim(rtrim(v_tp.tp))
                          AND ltrim(rtrim(s.tp)) = ltrim(rtrim(v_omatp.oma_tp))
                          AND left(s.konto, 1) IN ('4', '5', '6')
                          AND ltrim(rtrim(s.konto)) NOT IN ('601000', '601001')
            ) AS summa05,
          --(esitaja saldoandmik sum (kõik kontod algusega 3, mille TP kood on võrreldava kood (kreedit miinus deebet)))
          sum(kr - db)
            FILTER (WHERE ltrim(rtrim(s.omatp)) = ltrim(rtrim(v_omatp.oma_tp))
                          AND ltrim(rtrim(s.tp)) = ltrim(rtrim(v_tp.tp))
                          AND s.konto LIKE '3%'
            ) AS summa06,
          --(esitaja saldoandmik sum (kõik kontod algusega 4-6, mille TP kood on võrreldava kood (deebet miinus kreedit),
          --välja arvatud kontod 601000 ja 601001, mida ei võeta üldse arvesse, olenemata TP koodist))
          sum(db - kr)
            FILTER (WHERE ltrim(rtrim(s.omatp)) = ltrim(rtrim(v_omatp.oma_tp))
                          AND ltrim(rtrim(s.tp)) = ltrim(rtrim(v_tp.tp))
                          AND left(ltrim(rtrim(s.konto)), 1) IN ('4', '5', '6')
                          AND ltrim(rtrim(s.konto)) NOT IN ('601000', '601001')
            ) AS summa07,
          --(võrreldava saldoandmik (kõik kontod algusega 3, mille mille TP kood on aruande koostaja kood (kreedit miinus deebet)))
          sum(kr - db)
            FILTER (WHERE ltrim(rtrim(s.omatp)) = ltrim(rtrim(v_tp.tp))
                          AND ltrim(rtrim(s.tp)) = ltrim(rtrim(v_omatp.oma_tp))
                          AND left(ltrim(rtrim(s.konto)), 1) IN ('3')
            ) AS summa08,
          --(esitaja saldoandmik sum (kõik kontod algusega 7, mille TP kood on võrreldava kood (deebet miinus kreedit)))
          sum(db - kr)
            FILTER (WHERE ltrim(rtrim(s.omatp)) = ltrim(rtrim(v_omatp.oma_tp))
                          AND ltrim(rtrim(s.tp)) = ltrim(rtrim(v_tp.tp))
                          AND left(ltrim(rtrim(s.konto)), 1) IN ('7')
            ) AS summa09,
          --(võrreldava saldoandmik (kõik kontod algusega 7, mille TP kood on aruande koostaja kood (kreedit miinus deebet)))
          sum(kr - db)
            FILTER (WHERE ltrim(rtrim(s.omatp)) = ltrim(rtrim(v_tp.tp))
                          AND ltrim(rtrim(s.tp)) = ltrim(rtrim(v_omatp.oma_tp))
                          AND left(ltrim(rtrim(s.konto)), 1) IN ('7')
            ) AS summa10,
          --(esitaja saldoandmik sum (kõik kontod algusega 1 kuni 7, mille TP kood on võrreldava kood (deebet miinus kreedit)
          -- välja arvatud kontod 601000 ja 601001, mida ei võeta üldse arvesse olenemata TP koodist))
          sum(db - kr)
            FILTER (WHERE ltrim(rtrim(s.omatp)) = ltrim(rtrim(v_omatp.oma_tp))
                          AND ltrim(rtrim(s.tp)) = ltrim(rtrim(v_tp.tp))
                          AND left(ltrim(rtrim(s.konto)), 1) IN ('1', '2', '3', '4', '5', '6', '7')
                          AND ltrim(rtrim(s.konto)) NOT IN ('601000', '601001')
            ) AS summa11,
          --(võrreldava saldoandmik (kõik kontod algusega 1-7, mille TP kood on aruande koostaja kood (kreedit miinus deebet)
          --välja arvatud kontod 601000 ja 601001, mida ei võeta üldse arvesse olenemata TP koodist))
          sum(kr - db)
            FILTER (WHERE ltrim(rtrim(s.omatp)) = ltrim(rtrim(v_tp.tp))
                          AND ltrim(rtrim(s.tp)) = ltrim(rtrim(v_omatp.oma_tp))
                          AND left(ltrim(rtrim(s.konto)), 1) IN ('1', '2', '3', '4', '5', '6', '7')
                          AND ltrim(rtrim(s.konto)) NOT IN ('601000', '601001')
            ) AS summa12

        FROM eelarve.saldoandmik s
        WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
              AND rekvid < 999;


    END LOOP;

  END LOOP;

  RAISE NOTICE 'final ';
  RETURN QUERY SELECT
                 t.tp,
                 sum(coalesce(summa01, 0) - coalesce(summa02, 0)) AS summa_12,
                 -- 01
                 sum(coalesce(summa03, 0) - coalesce(summa04, 0)) AS summa_21,
                 -- 02
                 sum(coalesce(summa05, 0) - coalesce(summa06, 0)) AS summa_346,
                 --03
                 sum(coalesce(summa07, 0) - coalesce(summa08, 0)) AS summa_463,
                 --04
                 sum(coalesce(summa09, 0) - coalesce(summa10, 0)) AS summa_7,
                 -- 05
                 sum(coalesce(summa11, 0) - coalesce(summa12, 0)) AS summa_kokku -- 06
               FROM temp_saldoandmik_table t
               GROUP BY t.tp;
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION eelarve.saldo_vordlemine(DATE, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.saldo_vordlemine(DATE, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.saldo_vordlemine(DATE, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.saldo_vordlemine(DATE, INTEGER) TO dbvaatleja;

SELECT *
FROM eelarve.saldo_vordlemine('2025-03-31', 63)

/*
select * from temp_saldoandmik_table

*/