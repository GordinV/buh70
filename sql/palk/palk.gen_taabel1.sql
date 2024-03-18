DROP FUNCTION IF EXISTS gen_taabel1(INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.gen_taabel1(user_id INTEGER, params JSONB);
DROP FUNCTION IF EXISTS palk.gen_taabel1(user_id INTEGER, params JSON);
DROP FUNCTION IF EXISTS palk.gen_taabel1_(user_id INTEGER, params JSON);

CREATE FUNCTION palk.gen_taabel1(IN user_id INTEGER,
                                 IN params JSON,
                                 OUT error_code INTEGER,
                                 OUT result INTEGER,
                                 OUT error_message TEXT,
                                 OUT data JSONB)
    RETURNS RECORD
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_hours            NUMERIC(12, 4) = 0;
    json_object        JSON;
    v_params           RECORD;
    json_record        RECORD;
    l_id               INTEGER;
    l_params           JSON;
    v_user             RECORD;
    l_result           INTEGER        = 0;
    v_tulemus          RECORD;
    l_tahtpaeva_tunnid NUMERIC(12, 4) = 0;
BEGIN

    SELECT kasutaja,
           rekvid
    INTO v_user
    FROM ou.userid u
    WHERE u.id = user_Id;

    IF v_user.kasutaja IS NULL
    THEN
        error_code = 5;
        error_message = 'Kasutaja ei leitud,  userId:' ||
                        coalesce(user_id, 0) :: TEXT;

        SELECT error_message, error_code, 0 AS result INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;
        RETURN;
    END IF;

    IF params IS NULL
    THEN
        error_code = 6;
        error_message = 'Parametrid on vale või puuduvad';
        SELECT error_message, error_code, 0 AS result INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;
        RETURN;
    END IF;

    -- контроль периода для модуля ЗП
    IF NOT (ou.fnc_aasta_palk_kontrol(v_user.rekvid,
                                      make_date((params -> 0 ->> 'aasta')::INTEGER, (params -> 0 ->> 'kuu')::INTEGER,
                                                1)))
    THEN
        RAISE EXCEPTION 'Viga, periodi kontrol. palk kinni';
    END IF;


    -- loop throug params
    FOR json_object IN
        SELECT *
        FROM json_array_elements(params :: JSON)
        LOOP
            SELECT *
            INTO json_record
            FROM json_to_record(
                         json_object) AS x (lepingid INT, kuu INT, aasta INT);

            -- инициализируем
            SELECT NULL::INTEGER           AS doc_id,
                   ltrim(rtrim(p.nimetus)) AS error_message,
                   NULL::INTEGER           AS error_code,
                   0                       AS result
            INTO v_tulemus
            FROM palk.cur_tootajad p
            WHERE p.lepingid = json_record.lepingid;

            -- find available row
            l_id = coalesce((SELECT p.id
                             FROM palk.cur_palk_taabel p
                             WHERE p.lepingid = json_record.lepingid
                               AND p.kuu = json_record.kuu
                               AND p.aasta = json_record.aasta
                             LIMIT 1), 0);


            -- calc tabel
            SELECT row_to_json(row)
            INTO l_params
            FROM (SELECT json_record.lepingid AS lepingid,
                         json_record.kuu      AS kuu,
                         json_record.aasta    AS aasta) row;

            -- проверка на действительность договора
            IF NOT exists(SELECT id
                          FROM palk.tooleping t
                          WHERE t.id = json_record.lepingid
                            AND (t.lopp IS NULL OR
                                 (year(t.lopp) >= json_record.aasta AND month(t.lopp) >= json_record.kuu)))
            THEN
                CONTINUE;
            END IF;

            SELECT t.result, t.tahtpaeva_tunnid
            INTO l_hours, l_tahtpaeva_tunnid
            FROM palk.sp_calc_taabel2(l_params :: JSONB) t; -- -> 145 ?

            IF coalesce(l_hours, 0) > 0
            THEN

                -- save
                SELECT l_id                 AS id,
                       json_record.kuu      AS kuu,
                       json_record.aasta    AS aasta,
                       l_hours              AS too,
                       l_hours              AS kokku,
                       json_record.lepingid AS lepingid,
                       l_tahtpaeva_tunnid   AS tahtpaeva_tunnid
                INTO v_params;

                SELECT row_to_json(row)
                INTO l_params
                FROM (SELECT l_id     AS id,
                             v_params AS data) row;

                l_id = palk.sp_salvesta_palk_taabel(l_params, user_id, v_user.rekvid);
                IF (coalesce(l_id, 0) > 0)
                THEN
                    l_result = l_result + 1;

                    v_tulemus.error_code = 0;
                    v_tulemus.doc_id = l_id;
                    v_tulemus.result = l_result;
                    l_params = to_jsonb(v_tulemus);
                    data = coalesce(data, '[]'::JSONB) || l_params::JSONB;
                END IF;
            ELSE
                --delete
                l_result = l_result + 1;
                IF coalesce(l_id, 0) > 0
                THEN
                    -- delete previous table version
                    PERFORM palk.sp_delete_palk_taabel(user_id, l_id);
                END IF;

/*                v_tulemus.error_code = 0;
                v_tulemus.error_message = v_tulemus.error_message || ',' || ' taabel on tühi';
                l_params = to_jsonb(v_tulemus);
                data = coalesce(data, '[]'::JSONB) || l_params::JSONB;
*/
            END IF;

        END LOOP;

    IF coalesce(l_result, 0) = 0
    THEN
        error_code = 0;
        error_message = 'Lepingud ei leidnud või vale parametrid';
        SELECT error_message, error_code, 0 AS result INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;
    END IF;
    result = coalesce(l_result, 0);
    RETURN;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_message = SQLERRM;
            error_code = 1;
            result = 0;
            v_tulemus.error_message = v_tulemus.error_message || ',' || SQLERRM;
            v_tulemus.error_code = 1;
            l_params = to_jsonb(v_tulemus);
            data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

            RETURN;

END ;
$$;


GRANT EXECUTE ON FUNCTION palk.gen_taabel1(user_id INTEGER, params JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.gen_taabel1(user_id INTEGER, params JSON) TO dbpeakasutaja;


/*
select * from palk.gen_taabel1(1, null::text);
select * from palk.gen_taabel1(1, '[{"lepingid":27261,"kuu":12,"aasta":2021}]'::json);


*/