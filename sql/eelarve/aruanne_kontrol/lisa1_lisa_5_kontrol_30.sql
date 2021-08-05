DROP FUNCTION IF EXISTS eelarve.lisa1_lisa5_kontrol_30(TEXT, JSON, JSON);

CREATE OR REPLACE FUNCTION eelarve.lisa1_lisa5_kontrol_30(IN formula TEXT,
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
    l_kond        INTEGER = coalesce((params ->> 'kond')::INTEGER, 0);
    l_rekvid      INTEGER = coalesce((params ->> 'rekvid')::INTEGER, 0);
    l_aasta       INTEGER = coalesce((params ->> 'aasta')::INTEGER, year(date()));
    l_kpv1        DATE    = coalesce((params ->> 'kpv1')::DATE, date());
    l_kpv2        DATE    = coalesce((params ->> 'kpv2')::DATE, date());
    l_rekvid_kond INTEGER = CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 999 ELSE l_rekvid END;
BEGIN
    SELECT coalesce((params ->> 'eelarve')::NUMERIC, 0)::NUMERIC            AS eelarve,
           coalesce((params ->> 'eelarve_taps')::NUMERIC, 0)::NUMERIC       AS eelarve_taps,
           coalesce((params ->> 'eelarve_kassa')::NUMERIC, 0)::NUMERIC      AS eelarve_kassa,
           coalesce((params ->> 'eelarve_kassa_taps')::NUMERIC, 0)::NUMERIC AS eelarve_kassa_taps,
           coalesce((params ->> 'saldoandmik')::NUMERIC, 0)::NUMERIC        AS saldoandmik,
           coalesce((params ->> 'kassa')::NUMERIC, 0)::NUMERIC              AS kassa
           INTO v_params;

    CASE
        WHEN l_rekvid_kond = 999 THEN
-- Строка 30 Tekke täitmine (Lisa 1) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
    -- Сумма всех строк с бюджетом 30* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke täitmine +
    -- Jooksva per saldoandmikust  (без элиминирования) строки 30* TP 185101=0

--            Строка 30 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
    --            Сумма всех строк с бюджетом 30* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine +
    --            Сумма всех строк D710001 K 100100 с бюджетом 30*в Päevaraamat = 0


            SELECT sum(qry1.saldoandmik) AS saldoandmik,
                   sum(qry1.kassa)       AS kassa
                   INTO v_tulemus
            FROM (
                     -- Строка PÕHITEGEVUSE TULUD KOKKU
                     SELECT v_params.saldoandmik AS saldoandmik,
                            v_params.kassa       AS kassa
                     UNION ALL
                     -- Сумма всех строк с бюджетом 3*Tekke eelarve kinn в отчете Tulude eelarve täitmine
                     SELECT qry.tegelik AS saldoandmik,
                            qry.kassa   AS kassa
                     FROM eelarve.tulude_taitmine_allikas_artikkel(l_aasta::INTEGER, l_kpv1::DATE, l_kpv2::DATE,
                                                                   l_rekvid, l_kond) qry
                     WHERE rekv_id <> 999999
                       AND artikkel like '30%'
                     UNION ALL
                     --  Jooksva per saldoandmikust  (без элиминирования) строки 30* TP 185101
                     SELECT q.kr - q.db AS saldoandmik,
                            0           AS kassa
                     FROM eelarve.saldoandmik q
                     WHERE konto LIKE '30%'
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

        WHEN l_rekvid_kond <> 999 THEN
            -- Строка 30 Tekke täitmine (Lisa 1) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
            -- Сумма всех строк с бюджетом 30* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke täitmine +
--  Сумма всех строк D710001 K 100100 с бюджетом 30*в Päevaraamat
            WITH qryJournal AS (
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
                  AND kood5 like '30%'
                GROUP BY deebet, kreedit, kood5
            )

            SELECT
                sum(qry1.eelarve)            AS eelarve,
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
                            v_params.saldoandmik AS saldoandmik,
                            v_params.kassa       AS kassa
                     UNION ALL
-- Сумма всех строк с бюджетом 30* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)
                     SELECT qry.eelarve_kinni as eelarve,
                            qry.eelarve_kassa_parandatud as eelarve_taps,
                            qry.eelarve_kassa_kinni as eelarve_kassa,
                            qry.eelarve_kassa_parandatud as eelarve_kassa_taps,
                            qry.tegelik AS saldoandmik,
                            qry.kassa   AS kassa
                     FROM eelarve.tulude_taitmine_allikas_artikkel(l_aasta::INTEGER, l_kpv1::DATE, l_kpv2::DATE,
                                                                   l_rekvid, l_kond) qry
                     WHERE rekv_id <> 999999
                       AND artikkel  like '30%'
                     UNION ALL
--                     Сумма всех строк D710001 K 100100 с бюджетом 30*в Päevaraamat
                     SELECT 0 AS eelarve,
                            0 AS eelarve_taps,
                            0 AS eelarve_kassa,
                            0 AS eelarve_kassa_taps,
                            0 AS saldoandmik,
                            j.kassa
                     FROM qryJournal j

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
selg = 'test'

    RETURN;
END;
$BODY$
    VOLATILE
    COST 100;

--GRANT EXECUTE ON FUNCTION eelarve.lisa1_lisa5_kontrol(text, json, json) TO eelkoostaja;

SELECT *
FROM eelarve.lisa1_lisa5_kontrol_30('PÕHITEGEVUSE TULUD KOKKU', '    {
  "eelarve": 29639494.00,
  "eelarve_taps": 29639494.00,
  "saldoandmik": 7545012.08,
  "kassa": 7623838.30,
  "eelarve_kassa": 29639494.00,
  "rekvid": 63,
  "kond": 0,
  "kpv1": 20210101,
  "kpv2": 20210331,
  "aasta": 2021
}'::JSON, NULL::JSON)
 where (eelarve <> 0
    AND eelarve_taps <> 0
    AND eelarve_kassa <> 0
    AND eelarve_kassa_taps <> 0
    AND saldoandmik <> 0
    AND kassa <> 0)
or coalesce(selg,'') = 'test';

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
