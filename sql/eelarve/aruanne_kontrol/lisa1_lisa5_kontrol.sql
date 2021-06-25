DROP FUNCTION IF EXISTS eelarve.lisa1_lisa5_kontrol(TEXT, JSON, JSON);

CREATE OR REPLACE FUNCTION eelarve.lisa1_lisa5_kontrol(IN formula TEXT,
                                                       IN params JSON,
                                                       IN data JSON,
                                                       OUT eelarve NUMERIC,
                                                       OUT eelarve_taps NUMERIC,
                                                       OUT selg TEXT)
    LANGUAGE plpgsql
AS
$BODY$

DECLARE
    v_params  RECORD;
    v_tulemus RECORD;
--    tulemus  NUMERIC = 0;
    l_kond    INTEGER = coalesce((params ->> 'kond')::INTEGER, 0);
    l_rekvid  INTEGER = coalesce((params ->> 'rekvid')::INTEGER, 0);
    l_aasta   INTEGER = coalesce((params ->> 'aasta')::INTEGER, year(date()));
    l_kpv1    DATE    = coalesce((params ->> 'kpv1')::DATE, date());
    l_kpv2    DATE    = coalesce((params ->> 'kpv2')::DATE, date());
BEGIN
    CASE
        WHEN formula = 'PÕHITEGEVUSE TULUD KOKKU' AND l_rekvid <> 999 THEN
            -- Строка PÕHITEGEVUSE TULUD KOKKU  Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) //('30','32', '35','38')//   -
            -- Сумма всех строк с бюджетом 3*Tekke eelarve kinn в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  -
            -- строка 3501 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5)  +
            -- строка с бюджетом 381 (только, 3818 не надо брать) Tekke eelarve kinn в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) +
            -- строка с бюджетом 3502 Tekke eelarve kinn в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) =  0

            SELECT coalesce((params ->> 'eelarve')::NUMERIC, 0)::NUMERIC           AS eelarve,
                   coalesce((params ->> 'eelarve_taps')::NUMERIC, 0)::NUMERIC      AS eelarve_taps,
                   coalesce((params ->> 'eelarve_3501')::NUMERIC, 0)::NUMERIC      AS eelarve_3501,
                   coalesce((params ->> 'eelarve_taps_3501')::NUMERIC, 0)::NUMERIC AS eelarve_taps_3501
                   INTO v_params;

            -- отчет Tulude eelarve täitmine
            WITH qryTuludTaitmine AS (
                SELECT qry.artikkel, qry.eelarve_kinni AS eelarve, qry.eelarve_parandatud AS eelarve_taps
                FROM eelarve.tulude_taitmine_allikas_artikkel_(l_aasta::INTEGER, l_kpv1::DATE, l_kpv2::DATE,
                                                               l_rekvid, l_kond) qry
                WHERE rekv_id <> 999999
            )
            SELECT sum(qry1.eelarve)      AS eelarve,
                   sum(qry1.eelarve_taps) AS eelarve_taps
                   INTO v_tulemus
            FROM (
                     -- Строка PÕHITEGEVUSE TULUD KOKKU
                     SELECT v_params.eelarve      AS eelarve,
                            v_params.eelarve_taps AS eelarve_taps
                     UNION ALL
                     -- Сумма всех строк с бюджетом 3*Tekke eelarve kinn в отчете Tulude eelarve täitmine
                     SELECT -1 * q.eelarve      AS eelarve,
                            -1 * q.eelarve_taps AS eelarve_taps
                     FROM qryTuludTaitmine q
                     WHERE artikkel LIKE '3%'
                         -- строка 3501 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5)
                         UNION ALL
                         SELECT -1 * v_params.eelarve_3501 AS eelarve
                         ,
                             -1 * v_params.eelarve_taps_3501 AS eelarve_taps
                         UNION ALL
                         -- строка с бюджетом 381 (только, 3818 не надо брать) Tekke eelarve kinn в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) +
                         SELECT q.eelarve AS eelarve
                         ,
                         q.eelarve_taps AS eelarve_taps
                         FROM qryTuludTaitmine q
                         WHERE artikkel LIKE '381%' AND artikkel <> '3818'
                         UNION ALL
                         -- строка с бюджетом 3502 Tekke eelarve kinn в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)
                         SELECT q.eelarve AS eelarve
                         ,
                         q.eelarve_taps AS eelarve_taps
                         FROM qryTuludTaitmine q
                         WHERE artikkel = '3502'
                 ) qry1;
            eelarve = v_tulemus.eelarve;
            eelarve_taps = v_tulemus.eelarve_taps;
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
FROM eelarve.lisa1_lisa5_kontrol('PÕHITEGEVUSE TULUD KOKKU', '	{
  "eelarve":82343738.00,
  "eelarve_taps":83255187.00,
  "eelarve_3501":39509129.00,
  "eelarve_taps_3501":39509616.00,
  "rekvid":119,
  "kond": 1,
  "kpv1": 20210625,
  "kpv2": 20210625,
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