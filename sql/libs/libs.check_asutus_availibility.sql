-- libs.check_asutus_availibility
DROP FUNCTION IF EXISTS libs.check_asutus_availibility(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION libs.check_asutus_availibility(IN l_user_id INTEGER, l_log_id INTEGER,
                                                          OUT error_code INTEGER,
                                                          OUT result INTEGER,
                                                          OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_virtual_user_id     integer = l_user_id; -- подменим на виртуального робота
    l_batches             jsonb; -- массив батчей по учреждениям из лога getEarved: [{rekvId, userId, count, arved: [...]}]
    v_regkood             record;
    l_error_list          jsonb   = '[]'::jsonb;
    l_vastutav_isik       text    = 'svetlana.tsaikina';
    l_vastutav_isiku_mail text    = (
                                        select
                                            properties ->> 'email'
                                        from
                                            ou.userid
                                        where
                                              kasutaja = l_vastutav_isik
                                          and properties ->> 'email' is not null
                                        order by (case when rekvid = 63 then 1 else 0 end) desc
                                        limit 1
                                    );

BEGIN
    error_code = 0;
    result = 0;

    if l_user_id is null then
        l_virtual_user_id = (
                                select
                                    id
                                from
                                    ou.userid
                                where
                                      status < 3
                                  and kasutaja ilike '%robot%'
                                order by id desc
                                limit 1
                            );
    end if;

    if l_log_id is null then
        error_code = 1;
        error_message = 'Puudub log_id';
        RETURN;
    end if;

    -- массив батчей (по одному на учреждение) из лога getEarved
    l_batches = (
                    select
                        propertis -> 'arved'
                    from
                        ou.logs
                    where
                          id = l_log_id
                      and propertis ->> 'flow' is not null
                );

    -- проверка размерности массива
    IF l_batches is null or jsonb_typeof(l_batches) <> 'array' or jsonb_array_length(l_batches) = 0
    THEN
        -- нет счетов, выходим
        result = 0;
        error_message = 'Asutused ei ole';
        RETURN;
    END IF;

    -- проходим по ВСЕМ батчам и ВСЕМ счетам, берем уникальные рег.коды контрагентов (asutusid = regkood продавца)
    FOR v_regkood IN
        SELECT DISTINCT
            ALLTRIM(inv.doc -> 'data' ->> 'asutusid') AS regkood
        FROM
            jsonb_array_elements(l_batches) AS batch (b),
            jsonb_array_elements(coalesce(batch.b -> 'arved', '[]'::jsonb)) AS inv (doc)
        WHERE
            coalesce(ALLTRIM(inv.doc -> 'data' ->> 'asutusid'), '') <> ''
        ORDER BY 1
        LOOP
            -- контрагент есть в бд, пропускаем
            if exists
            (
                select
                    a.id
                from
                    libs.asutus a
                where
                      a.regkood = v_regkood.regkood
                  and a.staatus < 3
            ) then
                continue;
            end if;

            l_error_list = l_error_list || jsonb_build_object(
                    'puuduvad_asutused', v_regkood.regkood,
                    'vastutav_isik', l_vastutav_isik,
                    'email', l_vastutav_isiku_mail);
            result = result + 1;
        END LOOP;

    if jsonb_array_length(l_error_list) > 0 then
        error_message = 'Leidnud puuduvad asutused';
    end if;

    -- сохраняем список недостающих контрагентов в логе (поле changes)
    update ou.logs
    set
        changes = l_error_list
    where
        id = l_log_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION libs.check_asutus_availibility(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.check_asutus_availibility(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION libs.check_asutus_availibility(INTEGER, INTEGER) TO arvestaja;

COMMENT ON FUNCTION libs.check_asutus_availibility(INTEGER, INTEGER) IS 'парсит jsonb массив счетов из лога getEarved (по всем учреждениям) и возвращает в ou.logs.changes список рег.кодов контрагентов, отсутствующих в libs.asutus';
