DROP FUNCTION IF EXISTS eelarve.lisa1_lisa5_kontrol_pohitegevuse_tulud(TEXT, JSON, JSON);

CREATE OR REPLACE FUNCTION eelarve.lisa1_lisa5_kontrol_pohitegevuse_tulud(IN formula TEXT,
                                                                          IN params JSON,
                                                                          IN data JSON,
                                                                          OUT eelarve NUMERIC,
                                                                          OUT eelarve_taps NUMERIC,
                                                                          OUT eelarve_kassa NUMERIC,
                                                                          OUT eelarve_kassa_taps NUMERIC,
                                                                          OUT saldoandmik NUMERIC,
                                                                          OUT kassa NUMERIC,
                                                                          OUT selg TEXT)
    LANGUAGE plpgsql
AS
$BODY$

DECLARE
    v_params      RECORD;
    v_tulemus     RECORD;
--    tulemus  NUMERIC = 0;
    l_kond        INTEGER = coalesce((params ->> 'kond')::INTEGER, 0);
    l_rekvid      INTEGER = coalesce((params ->> 'rekvid')::INTEGER, 0);
    l_aasta       INTEGER = coalesce((params ->> 'aasta')::INTEGER, year(date()));
    l_kpv1        DATE    = coalesce((params ->> 'kpv1')::DATE, date());
    l_kpv2        DATE    = coalesce((params ->> 'kpv2')::DATE, date());
    l_rekvid_kond INTEGER = CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 999 ELSE l_rekvid END;
BEGIN
    SELECT coalesce((params ->> 'eelarve')::NUMERIC, 0)::NUMERIC                 AS eelarve,
           coalesce((params ->> 'eelarve_taps')::NUMERIC, 0)::NUMERIC            AS eelarve_taps,
           coalesce((params ->> 'eelarve_kassa')::NUMERIC, 0)::NUMERIC           AS eelarve_kassa,
           coalesce((params ->> 'eelarve_kassa_taps')::NUMERIC, 0)::NUMERIC      AS eelarve_kassa_taps,
           coalesce((params ->> 'saldoandmik')::NUMERIC, 0)::NUMERIC             AS saldoandmik,
           coalesce((params ->> 'kassa')::NUMERIC, 0)::NUMERIC                   AS kassa,
           coalesce((params ->> 'eelarve_3501')::NUMERIC, 0)::NUMERIC            AS eelarve_3501,
           coalesce((params ->> 'eelarve_taps_3501')::NUMERIC, 0)::NUMERIC       AS eelarve_taps_3501,
           coalesce((params ->> 'eelarve_kassa_3501')::NUMERIC, 0)::NUMERIC      AS eelarve_kassa_3501,
           coalesce((params ->> 'eelarve_kassa_taps_3501')::NUMERIC, 0)::NUMERIC AS eelarve_kassa_taps_3501,
           coalesce((params ->> 'kassa_3501')::NUMERIC, 0)::NUMERIC              AS kassa_3501,
           coalesce((params ->> 'saldoandmik_3501')::NUMERIC, 0)::NUMERIC        AS saldoandmik_3501
           INTO v_params;

    CASE
        WHEN formula = 'PÕHITEGEVUSE TULUD KOKKU' AND l_rekvid_kond = 999 THEN
            --   Строка PÕHITEGEVUSE TULUD KOKKU  Tekke täitmine в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
            --   Сумма всех строк с бюджетом 3*Tekke täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  -
            --   строка 3501 Tekke täitmine kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5)  +
            --   строка с бюджетом 381 (только, 3818 не надо брать) Tekke täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) +
            --   строка с бюджетом 3502Tekke täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)+
            --   Jooksva per saldoandmikust  (без элиминирования) конто 3* TP 185101=0

            --  Строка PÕHITEGEVUSE TULUD KOKKU   Kassa täitmine в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                --  Сумма всех строк с бюджетом 3* Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  -
                --  строка 3501 Kassa täitmine в отчете EELARVEARUANNE (Lisa 1, Lisa 5)  +
                --  строка с бюджетом 381 (только, 3818 не надо брать) Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) +
                --  строка с бюджетом 3502 Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  =  0


            -- отчет Tulude eelarve täitmine
            WITH qryTuludTaitmine AS (
                SELECT qry.artikkel,
                       qry.eelarve_kinni            AS eelarve,
                       qry.eelarve_parandatud       AS eelarve_taps,
                       qry.tegelik                  AS saldoandmik,
                       qry.eelarve_kassa_kinni      AS eelarve_kassa,
                       qry.eelarve_kassa_parandatud AS eelarve_kassa_taps,
                       qry.kassa                    AS kassa
                FROM eelarve.tulude_taitmine_allikas_artikkel(l_aasta::INTEGER, l_kpv1::DATE, l_kpv2::DATE,
                                                               l_rekvid, l_kond) qry
                WHERE rekv_id <> 999999
            )
            SELECT sum(qry1.saldoandmik) AS saldoandmik,
                   sum(qry1.kassa)       AS kassa
                   INTO v_tulemus
            FROM (
                     -- Строка PÕHITEGEVUSE TULUD KOKKU
                     SELECT v_params.saldoandmik AS saldoandmik,
                            v_params.kassa       AS kassa
                     UNION ALL
                     -- Сумма всех строк с бюджетом 3*Tekke eelarve kinn в отчете Tulude eelarve täitmine
                     SELECT -1 * q.saldoandmik AS saldoandmik,
                            -1 * q.kassa       AS kassa
                     FROM qryTuludTaitmine q
                     WHERE artikkel LIKE '3%'
                           -- строка 3501 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5)
                     UNION ALL
                     SELECT -1 * v_params.saldoandmik_3501 AS saldoandmik,
                            -1 * v_params.kassa_3501       AS kassa
                     UNION ALL
                     -- строка с бюджетом 381 (только, 3818 не надо брать) Tekke eelarve kinn в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) +
                     SELECT q.saldoandmik AS saldoandmik,
                            q.kassa       AS kassa
                     FROM qryTuludTaitmine q
                     WHERE artikkel LIKE '381%'
                       AND artikkel <> '3818'
                     UNION ALL
                     -- строка с бюджетом 3502 Tekke eelarve kinn в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)
                     SELECT q.saldoandmik AS saldoandmik,
                            q.kassa       AS kassa
                     FROM qryTuludTaitmine q
                     WHERE artikkel = '3502'
                     UNION ALL
                     --  Jooksva per saldoandmikust  (без элиминирования) конто 3* TP 185101
                     SELECT q.kr - q.db AS saldoandmik,
                            0           AS kassa
                     FROM eelarve.saldoandmik q
                     WHERE konto LIKE '3%'
                       AND aasta = year(l_kpv2)
                       AND kuu = month(l_kpv2)
                       AND tp LIKE '185101%'
                       AND q.rekvid IN (SELECT rekv_id
                                        FROM get_asutuse_struktuur(l_rekvid))
                       AND q.rekvid = CASE WHEN l_kond = 1 THEN q.rekvid ELSE l_rekvid END
                 ) qry1;
            eelarve = 0;
            eelarve_taps = 0;
            eelarve_kassa = 0;
            eelarve_kassa_taps = 0;
            saldoandmik = v_tulemus.saldoandmik;
            kassa = v_tulemus.kassa;

        WHEN formula = 'PÕHITEGEVUSE TULUD KOKKU' AND l_rekvid_kond <> 999 THEN
            -- Строка PÕHITEGEVUSE TULUD KOKKU  Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) //('30','32', '35','38')//   -
            -- Сумма всех строк с бюджетом 3*Tekke eelarve kinn в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  -
            -- строка 3501 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5)  +
            -- строка с бюджетом 381 (только, 3818 не надо брать) Tekke eelarve kinn в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) +
            -- строка с бюджетом 3502 Tekke eelarve kinn в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) =  0


-- Строка PÕHITEGEVUSE TULUD KOKKU   Kassa täitmine в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                -- Сумма всех строк с бюджетом 3* Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  -
                -- строка 3501 Kassa täitmine в отчете EELARVEARUANNE (Lisa 1, Lisa 5)  +
                -- строка с бюджетом 381 (только, 3818 не надо брать) Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) +
                -- строка с бюджетом 3502 Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  +
                -- Сумма всех строк D710001 K 100100 с бюджетом 3*в Päevaraamat- Сумма всех строк D710001 K 100100 с бюджетом 381*в Päevaraamat Сумма всех строк -
                -- D710001 K 100100 с бюджетом 3501*в Päevaraamat Сумма всех строк D710001 K 100100 с бюджетом 3502*в Päevaraamat =  0

            -- отчет Tulude eelarve täitmine
            WITH qryTuludTaitmine AS (
                SELECT qry.artikkel,
                       qry.eelarve_kinni            AS eelarve,
                       qry.eelarve_parandatud       AS eelarve_taps,
                       qry.tegelik                  AS saldoandmik,
                       qry.eelarve_kassa_kinni      AS eelarve_kassa,
                       qry.eelarve_kassa_parandatud AS eelarve_kassa_taps,
                       qry.kassa                    AS kassa
                FROM eelarve.tulude_taitmine_allikas_artikkel(l_aasta::INTEGER, l_kpv1::DATE, l_kpv2::DATE,
                                                               l_rekvid, l_kond) qry
                WHERE rekv_id <> 999999
            ),
                 qryJournal AS (
                     SELECT j.deebet,
                            j.kreedit,
                            sum(j.summa) AS kassa,
                            j.kood5      AS artikkel
                     FROM cur_journal j
                     WHERE kpv >= l_kpv1
                       AND kpv <= l_kpv2
                       AND j.rekvid IN (SELECT rekv_id
                                        FROM get_asutuse_struktuur(l_rekvid))
                       AND j.rekvid = CASE WHEN l_kond = 1 THEN j.rekvid ELSE l_rekvid END
                       AND left(deebet, 6) IN ('710001')
                       AND left(kreedit, 6) IN ('100100')
                     GROUP BY deebet, kreedit, kood5
                 )
            SELECT sum(qry1.eelarve)            AS eelarve,
                   sum(qry1.eelarve_taps)       AS eelarve_taps,
                   sum(qry1.eelarve_kassa)      AS eelarve_kassa,
                   sum(qry1.eelarve_kassa_taps) AS eelarve_kassa_taps,
                   sum(qry1.saldoandmik)        AS saldoandmik,
                   sum(qry1.kassa)              AS kassa
                   INTO v_tulemus
            FROM (
                     -- Строка PÕHITEGEVUSE TULUD KOKKU
                     SELECT v_params.eelarve            AS eelarve,
                            v_params.eelarve_taps       AS eelarve_taps,
                            v_params.eelarve_kassa      AS eelarve_kassa,
                            v_params.eelarve_kassa_taps AS eelarve_kassa_taps,
                            v_params.saldoandmik        AS saldoandmik,
                            v_params.kassa              AS kassa
                     UNION ALL
                     -- kassa Сумма всех строк D710001 K 100100 с бюджетом 3*в Päevaraamat
                     SELECT 0 AS eelarve,
                            0 AS eelarve_taps,
                            0 AS eelarve_kassa,
                            0 AS eelarve_kassa_taps,
                            0 AS saldoandmik,
                            j.kassa
                     FROM qryJournal j
                     WHERE artikkel LIKE '3%'
                     UNION ALL
                     -- - Сумма всех строк D710001 K 100100 с бюджетом 381*в Päevaraamat Сумма всех строк
                     SELECT 0 AS eelarve,
                            0 AS eelarve_taps,
                            0 AS eelarve_kassa,
                            0 AS eelarve_kassa_taps,
                            0 AS saldoandmik,
                            -1 * j.kassa
                     FROM qryJournal j
                     WHERE artikkel LIKE '381%'
                     UNION ALL
-- - D710001 K 100100 с бюджетом 3501*в Päevaraamat Сумма всех строк D710001 K 100100 с бюджетом 3502*в Päevaraamat
                     SELECT 0 AS eelarve,
                            0 AS eelarve_taps,
                            0 AS eelarve_kassa,
                            0 AS eelarve_kassa_taps,
                            0 AS saldoandmik,
                            -1 * j.kassa
                     FROM qryJournal j
                     WHERE left(artikkel, 4) IN ('3501', '3502')
                     UNION ALL

                     -- Сумма всех строк с бюджетом 3*Tekke eelarve kinn в отчете Tulude eelarve täitmine
                     SELECT -1 * q.eelarve            AS eelarve,
                            -1 * q.eelarve_taps       AS eelarve_taps,
                            -1 * q.eelarve_kassa      AS eelarve_kassa,
                            -1 * q.eelarve_kassa_taps AS eelarve_kassa_taps,
                            -1 * q.saldoandmik        AS saldoandmik,
                            -1 * q.kassa              AS kassa
                     FROM qryTuludTaitmine q
                     WHERE artikkel LIKE '3%'
                           -- строка 3501 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5)
                     UNION ALL
                     SELECT -1 * v_params.eelarve_3501            AS eelarve,
                            -1 * v_params.eelarve_taps_3501       AS eelarve_taps,
                            -1 * v_params.eelarve_kassa_3501      AS eelarve_kassa,
                            -1 * v_params.eelarve_kassa_taps_3501 AS eelarve_kassa_taps,
                            -1 * v_params.saldoandmik_3501        AS saldoandmik,
                            -1 * v_params.kassa_3501              AS kassa
                     UNION ALL
                     -- строка с бюджетом 381 (только, 3818 не надо брать) Tekke eelarve kinn в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) +
                     SELECT q.eelarve            AS eelarve,
                            q.eelarve_taps       AS eelarve_taps,
                            q.eelarve_kassa      AS eelarve_kassa,
                            q.eelarve_kassa_taps AS eelarve_kassa_taps,
                            q.saldoandmik        AS saldoandmik,
                            q.kassa              AS kassa
                     FROM qryTuludTaitmine q
                     WHERE artikkel LIKE '381%'
                       AND artikkel <> '3818'
                     UNION ALL
                     -- строка с бюджетом 3502 Tekke eelarve kinn в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)
                     SELECT q.eelarve            AS eelarve,
                            q.eelarve_taps       AS eelarve_taps,
                            q.eelarve_kassa      AS eelarve_kassa,
                            q.eelarve_kassa_taps AS eelarve_kassa_taps,
                            q.saldoandmik        AS saldoandmik,
                            q.kassa              AS kassa
                     FROM qryTuludTaitmine q
                     WHERE artikkel = '3502'
                 ) qry1;
            eelarve = v_tulemus.eelarve;
            eelarve_taps = v_tulemus.eelarve_taps;
            eelarve_kassa = v_tulemus.eelarve_kassa;
            eelarve_kassa_taps = v_tulemus.eelarve_kassa_taps;
            saldoandmik = v_tulemus.saldoandmik;
            kassa = v_tulemus.kassa;
        ELSE
            eelarve = 0;
        END CASE;


    RETURN;
END;
$BODY$
    VOLATILE
    COST 100;

--GRANT EXECUTE ON FUNCTION eelarve.lisa1_lisa5_kontrol(text, json, json) TO eelkoostaja;

SELECT *
FROM eelarve.lisa1_lisa5_kontrol_pohitegevuse_tulud('PÕHITEGEVUSE TULUD KOKKU', '	{
  "eelarve":67143464.00,
  "eelarve_taps":68108774.00,
  "saldoandmik":19104831.40,
  "kassa":19179590.56,
  "eelarve_kassa":67143464.00,
  "eelarve_kassa_taps":68181627.00,
  "eelarve_3501":0.00,
  "eelarve_taps_3501":0.00,
  "saldoandmik_3501":0.00,
  "eelarve_kassa_3501":0.00,
  "eelarve_kassa_taps_3501":0.00,
  "kassa_3501":1635.00,
  "rekvid":63,
  "kond": 1,
  "kpv1": 20210627,
  "kpv2": 20210627,
  "aasta":2021
}'::JSON, NULL::JSON);

/*
        SELECT *
         FROM eelarve.eelarve_andmik_lisa_1_5(DATE(2021,03, 31),119, 1) qry
         where artikkel like '32%'

sELECT *
                       FROM tmp_andmik
                       WHERE --(
                       ltrim(rtrim(artikkel))::text like '35'
                       ('3000', '3030', '3044', '3045', '3047')
*/
