DROP FUNCTION IF EXISTS import_rekl_alg(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION import_rekl_alg(IN data JSONB)
    RETURNS INTEGER AS
$BODY$

DECLARE
    json_object JSON;
    v_dekl      RECORD;
    l_luba_id   INTEGER;
    json_luba1  JSONB;
    v_luba      RECORD;
    v_params    RECORD;
    l_asutus_id INTEGER;
    toiming_id  INTEGER;
    l_user_id   INTEGER = (SELECT id
                           FROM ou.userid
                           WHERE rekvid = 28
                             AND kasutaja = 'vlad' LIMIT 1);
BEGIN

    FOR v_dekl IN
        WITH qryJsons AS (
            SELECT *
            FROM jsonb_to_recordset(data::JSONB)
                     AS x(konto TEXT, regkood TEXT, summa NUMERIC)
        )
        SELECT *
        FROM qryJsons
        WHERE regkood = '10092807'
        LOOP
            RAISE NOTICE 'row %', v_dekl;

            SELECT id,
                   asutusid
                   INTO l_luba_id, l_asutus_id
            FROM rekl.luba l
            WHERE asutusid IN (SELECT id FROM libs.asutus WHERE regkood = v_dekl.regkood)
              AND year(l.loppkpv) = 2021
              AND l.staatus = 1
                LIMIT 1;

            IF l_luba_id IS NULL
            THEN
                -- not found, create luba
                -- берем разрешение за 2020 год и копируем его

                -- find luba 2020
                SELECT * INTO v_luba
                FROM rekl.luba l
                WHERE asutusid IN (SELECT id FROM libs.asutus WHERE regkood = v_dekl.regkood)
                  AND year(l.loppkpv) = 2020
                  AND l.staatus = 1
                    LIMIT 1;

                -- преобразование и получение параметров
                json_luba1 = array_to_json((SELECT array_agg(row_to_json(l1.*))
                                            FROM (SELECT 0 AS id,
                                                         nomid,
                                                         summa,
                                                         kogus,
                                                         maksumaar,
                                                         soodus_tyyp,
                                                         soodus,
                                                         staatus,
                                                         muud
                                                  FROM rekl.luba1 l1
                                                  WHERE l1.parentid = v_luba.id) AS l1));

                -- сохранение
                SELECT 0            AS id,
                       v_luba.asutusid,
                       '2021-01-01' AS algkpv,
                       '2021-12-31' AS loppkpv,
                       v_luba.summa,
                       v_luba.jaak,
                       v_luba.volg,
                       v_luba.alus,
                       v_luba.kord,
                       v_luba.number,
                       v_luba.muud,
                       v_luba.staatus,
                       json_luba1   AS "gridData"
                       INTO v_params;

                SELECT row_to_json(row) INTO json_object
                FROM (SELECT 0 AS id, TRUE AS import, v_params AS data) row;

                SELECT rekl.sp_salvesta_luba(json_object :: JSON, l_user_id, v_luba.rekvid) INTO l_luba_id;
                RAISE NOTICE 'luba_id %', l_luba_id;

                IF empty(l_luba_id)
                THEN
                    RAISE EXCEPTION 'Luba salvestamine ebaõnnestus';
                END IF;
                l_asutus_id = v_luba.asutusid;
            END IF;

            -- сохраняем нач. сальдо

            IF NOT exists(
                    SELECT id
                    FROM rekl.toiming
                    WHERE asutusid = l_asutus_id
                      AND lubaid = l_luba_id
                      AND tyyp = 'ALGSALDO'

                )
            THEN

-- сохранение
                SELECT 0            AS id,
                       l_asutus_id  AS asutusid,
                       l_luba_id    AS lubaid,
                       0            AS number,
                       '2020-12-31' AS kpv,
                       v_dekl.summa,
                       '2020-12-31' AS tahtaeg,
                       'ALGSALDO'   AS tyyp,
                       'Alg.saldo'  AS muud,
                       'active'     AS staatus,
                       0            AS dokpropid
                       INTO v_params;


                SELECT row_to_json(row) INTO json_object
                FROM (SELECT 0        AS id,
                             TRUE     AS import,
                             v_params AS data) row;

                SELECT rekl.sp_salvesta_toiming(json_object :: JSON, l_user_id, 28) INTO toiming_id;
                RAISE NOTICE 'leping_id %', toiming_id;
            END IF;

        END LOOP;
    RETURN 1;
END;

$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

/*

select import_rekl_alg('[{"konto": "102060", "regkood":"10054238","summa":19.20}		, {"konto": "102060", "regkood":"14706369","summa":345.60}		, {"konto": "102060", "regkood":"11958746","summa":2541.12}		, {"konto": "102060", "regkood":"10015238","summa":80.60}		, {"konto": "102060", "regkood":"10971513","summa":105.60}		, {"konto": "102060", "regkood":"10569681","summa":1990.40}		, {"konto": "102060", "regkood":"10227532","summa":500.00}		, {"konto": "102060", "regkood":"11292572","summa":10.00}		, {"konto": "102060", "regkood":"10180925","summa":376.20}		, {"konto": "102060", "regkood":"10717472","summa":328.53}		, {"konto": "102060", "regkood":"10072621","summa":3.00}		, {"konto": "102060", "regkood":"10388850","summa":268.80}		, {"konto": "102060", "regkood":"10017013","summa":230.40}		, {"konto": "102060", "regkood":"11135542","summa":460.95}		, {"konto": "102060", "regkood":"10312806","summa":163.20}		, {"konto": "102060", "regkood":"10669454","summa":9.60}		, {"konto": "102060", "regkood":"11663703","summa":48.00}		, {"konto": "102060", "regkood":"14197510","summa":57.60}		, {"konto": "102060", "regkood":"10348263","summa":100.06}		, {"konto": "102060", "regkood":"12702865","summa":6.40}		, {"konto": "102060", "regkood":"10170660","summa":144.00}		, {"konto": "102060", "regkood":"10579320","summa":6.40}		, {"konto": "102060", "regkood":"10167439","summa":60.80}		, {"konto": "102060", "regkood":"10895280","summa":10.00}		, {"konto": "102060", "regkood":"10092807","summa":28.80}		, {"konto": "102060", "regkood":"10765896","summa":232.80}		, {"konto": "102060", "regkood":"11273563","summa":144.00}		, {"konto": "102060", "regkood":"80145868","summa":1.60}		, {"konto": "102060", "regkood":"12059903","summa":48.00}		, {"konto": "102060", "regkood":"10773542","summa":32.00}		, {"konto": "102060", "regkood":"11435907","summa":12.60}		, {"konto": "102060", "regkood":"10167511","summa":109.20}		, {"konto": "102060", "regkood":"10136870","summa":247.60}		, {"konto": "102060", "regkood":"14437516","summa":268.80}		, {"konto": "102060", "regkood":"12470550","summa":144.00}		, {"konto": "102060", "regkood":"11269030","summa":206.40}		, {"konto": "102060", "regkood":"10693470","summa":115.20}		, {"konto": "102060", "regkood":"11923498","summa":411.84}		, {"konto": "102060", "regkood":"11281775","summa":38.40}		, {"konto": "102060", "regkood":"10108827","summa":19.20}		, {"konto": "102060", "regkood":"10131080","summa":86.40}		, {"konto": "102060", "regkood":"11229728","summa":36.96}		, {"konto": "102060", "regkood":"12961779","summa":38.40}		, {"konto": "102060", "regkood":"12252155","summa":76.80}		, {"konto": "102060", "regkood":"10182901","summa":64.00}		, {"konto": "102060", "regkood":"10190065","summa":185.40}		, {"konto": "102060", "regkood":"12648723","summa":226.56}		, {"konto": "102060", "regkood":"10406134","summa":5.00}		, {"konto": "102060", "regkood":"10199349","summa":51.20}		, {"konto": "102060", "regkood":"12622907","summa":6.40}		, {"konto": "102060", "regkood":"10263574","summa":1113.60}		, {"konto": "102060", "regkood":"10093480","summa":4.80}		, {"konto": "102060", "regkood":"14865548","summa":41.40}		, {"konto": "102060", "regkood":"10379733","summa":192.00}		, {"konto": "102060", "regkood":"10896486","summa":19.20}		, {"konto": "102060", "regkood":"10677712","summa":76.80}		, {"konto": "102060", "regkood":"10924857","summa":124.80}		, {"konto": "102060", "regkood":"11759933","summa":6.40}		, {"konto": "102060", "regkood":"10060701","summa":28.80}		, {"konto": "102060", "regkood":"10234957","summa":144.00}		, {"konto": "102060", "regkood":"14008620","summa":76.80}		, {"konto": "102060", "regkood":"10330885","summa":2.40}		, {"konto": "102060", "regkood":"12352537","summa":24.00}		, {"konto": "102060", "regkood":"10485381","summa":16.00}		, {"konto": "102060", "regkood":"11689463","summa":3.00}		, {"konto": "102060", "regkood":"10020239","summa":33.60}		, {"konto": "102060", "regkood":"14508819","summa":10.00}		, {"konto": "102060", "regkood":"11958752","summa":9.60}		, {"konto": "102060", "regkood":"12273418","summa":201.60}		, {"konto": "102060", "regkood":"12905657","summa":6.40}]'::jsonb)



 */