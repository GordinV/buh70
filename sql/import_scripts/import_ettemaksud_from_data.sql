DROP FUNCTION IF EXISTS import_ettemaksud_from_data(INTEGER);

CREATE OR REPLACE FUNCTION import_ettemaksud_from_data(IN data JSONB, IN l_kpv DATE)
    RETURNS INTEGER AS
$BODY$
DECLARE
    ettemaks_id      INTEGER;
    v_ettemaksud     RECORD;
    json_object      JSONB;
    v_params         RECORD;
    l_count          INTEGER = 0;
    l_asutus_id      INTEGER;
    l_rekv_id        INTEGER = 28;
    l_user_id        INTEGER = (SELECT id
                                FROM ou.userid
                                WHERE rekvid = l_rekv_id
                                  AND kasutaja = 'vlad'
                                LIMIT 1);
    l_ettemaks_summa NUMERIC;
BEGIN
    -- выборка из "старого меню"

    FOR v_ettemaksud IN
        SELECT *
        FROM jsonb_to_recordset(data::JSONB)
                 AS x(konto TEXT, regkood TEXT, summa TEXT)
        LOOP
            -- ищем контр агента
            l_asutus_id = (SELECT id
                           FROM libs.asutus a
                           WHERE regkood::TEXT = v_ettemaksud.regkood::TEXT
                             AND a.staatus <> 3
                             AND a.id IN (SELECT asutusid FROM rekl.luba l WHERE l.staatus <> 3)
            );

            RAISE NOTICE 'Asutus %, v_ettemaksud.regkood %', l_asutus_id, v_ettemaksud.regkood;
            IF l_asutus_id IS NOT NULL
            THEN
                -- преобразование и получение параметров
                l_ettemaks_summa = regexp_replace(v_ettemaksud.summa, '[,]', '.')::NUMERIC;

                -- ищем ранние версии
                ettemaks_id = (SELECT id
                               FROM rekl.ettemaksud e
                               WHERE asutusid = l_asutus_id
                                 AND kpv = l_kpv
                                 AND selg = 'Alg. saldo'
                               LIMIT 1);

-- сохранение
                SELECT coalesce(ettemaks_id, 0) AS id,
                       l_asutus_id              AS asutusid,
                       l_kpv                    AS kpv,
                       -1 * l_ettemaks_summa    AS summa,
                       'Alg. saldo'             AS selg,
                       0                        AS number,
                       l_rekv_id                AS rekvid,
                       'DEEBET'                 AS doktyyp,
                       'active'                 AS staatus
                       INTO v_params;


                SELECT row_to_json(row) INTO json_object
                FROM (SELECT coalesce(ettemaks_id, 0) AS id,
                             TRUE                     AS import,
                             v_params                 AS data) row;

                RAISE NOTICE 'salvestan %', json_object;
                SELECT rekl.sp_salvesta_ettemaksud(json_object :: JSON, l_user_id, l_rekv_id) INTO ettemaks_id;
                RAISE NOTICE 'tulemus %', ettemaks_id;

                IF (ettemaks_id > 0)
                THEN
                    l_count = l_count + 1;
                END IF;

                RAISE NOTICE 'leping_id %, l_count %', ettemaks_id, l_count;
            END IF;


        END LOOP;


    RETURN l_count;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


/*
SELECT import_ettemaksud_from_data('[{"konto":"102060","rekood":"10054238","summa":"19,2"},{"konto":"102060","rekood":"14706369","summa":"345,6"},{"konto":"102060","rekood":"11958746","summa":"10069,28"},{"konto":"102060","rekood":"10015238","summa":"78"},{"konto":"102060","rekood":"10971513","summa":"105,6"},{"konto":"102060","rekood":"10569681","summa":"1209,6"},{"konto":"102060","rekood":"10227532","summa":"500"},{"konto":"102060","rekood":"11292572","summa":"10"},{"konto":"102060","rekood":"10180925","summa":"368,4"},{"konto":"102060","rekood":"10717472","summa":"358,4"},{"konto":"102060","rekood":"10072621","summa":"3"},{"konto":"102060","rekood":"10388850","summa":"268,8"},{"konto":"102060","rekood":"10017013","summa":"230,4"},{"konto":"102060","rekood":"11135542","summa":"556,95"},{"konto":"102060","rekood":"10312806","summa":"163,2"},{"konto":"102060","rekood":"10669454","summa":"9,6"},{"konto":"102060","rekood":"11663703","summa":"48"},{"konto":"102060","rekood":"14197510","summa":"57,6"},{"konto":"102060","rekood":"12702865","summa":"6,4"},{"konto":"102060","rekood":"10170660","summa":"700,8"},{"konto":"102060","rekood":"10579320","summa":"6,4"},{"konto":"102060","rekood":"10167439","summa":"60,8"},{"konto":"102060","rekood":"10895280","summa":"10"},{"konto":"102060","rekood":"10196524","summa":"115,2"},{"konto":"102060","rekood":"10765896","summa":"232,8"},{"konto":"102060","rekood":"11273563","summa":"556,8"},{"konto":"102060","rekood":"80145868","summa":"1,6"},{"konto":"102060","rekood":"12059903","summa":"48"},{"konto":"102060","rekood":"10773542","summa":"32"},{"konto":"102060","rekood":"11435907","summa":"12,6"},{"konto":"102060","rekood":"10136870","summa":"242,4"},{"konto":"102060","rekood":"14437516","summa":"268,8"},{"konto":"102060","rekood":"12470550","summa":"144"},{"konto":"102060","rekood":"11269030","summa":"206,4"},{"konto":"102060","rekood":"11923498","summa":"1364,8"},{"konto":"102060","rekood":"11281775","summa":"38,4"},{"konto":"102060","rekood":"10108827","summa":"19,2"},{"konto":"102060","rekood":"10131080","summa":"86,4"},{"konto":"102060","rekood":"12961779","summa":"38,4"},{"konto":"102060","rekood":"12252155","summa":"76,8"},{"konto":"102060","rekood":"14754949","summa":"4,27"},{"konto":"102060","rekood":"10190065","summa":"185,4"},{"konto":"102060","rekood":"12648723","summa":"170,19"},{"konto":"102060","rekood":"10406134","summa":"5"},{"konto":"102060","rekood":"10199349","summa":"51,2"},{"konto":"102060","rekood":"12622907","summa":"6,4"},{"konto":"102060","rekood":"10263574","summa":"1113,6"},{"konto":"102060","rekood":"90011481","summa":"38,4"},{"konto":"102060","rekood":"10093480","summa":"4,8"},{"konto":"102060","rekood":"14865548","summa":"41,4"},{"konto":"102060","rekood":"10379733","summa":"192"},{"konto":"102060","rekood":"10896486","summa":"19,2"},{"konto":"102060","rekood":"10677712","summa":"76,8"},{"konto":"102060","rekood":"10924857","summa":"124,8"},{"konto":"102060","rekood":"11759933","summa":"6,4"},{"konto":"102060","rekood":"10060701","summa":"28,8"},{"konto":"102060","rekood":"10234957","summa":"144"},{"konto":"102060","rekood":"14008620","summa":"76,8"},{"konto":"102060","rekood":"10330885","summa":"2,4"},{"konto":"102060","rekood":"12352537","summa":"24"},{"konto":"102060","rekood":"10485381","summa":"16"},{"konto":"102060","rekood":"11689463","summa":"3"},{"konto":"102060","rekood":"10020239","summa":"33,6"},{"konto":"102060","rekood":"14508819","summa":"10"},{"konto":"102060","rekood":"11958752","summa":"9,6"},{"konto":"102060","rekood":"12273418","summa":"2281,07"},{"konto":"102060","rekood":"12905657","summa":"12,8"}]'::jsonb,'2020-09-30'::date)



*/
