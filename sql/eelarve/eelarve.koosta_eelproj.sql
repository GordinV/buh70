DROP FUNCTION IF EXISTS eelarve.koosta_eelproj(INTEGER, JSON);

CREATE FUNCTION eelarve.koosta_eelproj(tnAmetnikId INTEGER, params JSON,
                                       OUT error_code INTEGER,
                                       OUT result INTEGER,
                                       OUT error_message TEXT)
    RETURNS RECORD
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_id       INTEGER = params ->> 'eelproj_id';
    l_rekv_id  INTEGER = params ->> 'rekvid';
    l_aasta    INTEGER = params ->> 'aasta';
    l_kuu      INTEGER = params ->> 'kuu';
    l_muud     TEXT    = params ->> 'muud';
    l_json     JSON;
    l_proj_row RECORD;
BEGIN

    -- ищем проект бюджета

    SELECT id INTO l_id
    FROM eelarve.eelproj e
    WHERE status <> 3
      AND rekvid = l_rekv_id
      AND aasta = l_aasta
      AND (l_kuu IS NULL OR l_kuu = 0 OR kuu = l_kuu)
    LIMIT 1;

    SELECT coalesce(l_id, 0)  AS id,
           l_rekv_id          AS rekvid,
           l_aasta            AS aasta,
           coalesce(l_kuu, 0) AS kuu,
           0                  AS kinnitaja,
           l_muud :: TEXT     AS muud

           INTO l_proj_row;

    SELECT row_to_json(row) INTO l_json
    FROM (SELECT coalesce(l_id, 0) AS id,
                 l_proj_row        AS data
         ) row;

    l_id = eelarve.sp_salvesta_eelproj(l_json, tnAmetnikId, l_rekv_id);

    IF coalesce(l_id, 0) > 0
    THEN
        -- успешно сохранено
        result = l_id;
    ELSE
        error_code = 1;
        error_message = 'status != 1';
        result = 0;
    END IF;

    RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION eelarve.koosta_eelproj( INTEGER, JSON ) TO eelaktsepterja;

/*
select eelarve.koosta_eelproj( 70, '{"rekvid":83,"aasta":2021,"muud":"Narva Linnavolikogu 25.02.2021 määrus nr 4  Narva linna 2021. aasta eelarve kinnitamine"}'::json )

from eelarve.eelproj where id = 3
select error_code, result, error_message from eelarve.sp_eelproj_allkiri(3, 1);

*/