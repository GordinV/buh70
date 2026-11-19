DROP FUNCTION IF EXISTS libs.set_asutuse_kehtivus(INTEGER, INTEGER, DATE);

CREATE FUNCTION libs.set_asutuse_kehtivus(
    l_asutusid    INTEGER,
    l_user_id     INTEGER,
    l_kehtise_aeg DATE DEFAULT current_date
)
    RETURNS JSONB
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_result    JSONB := '[]'::jsonb;
    v_user_name TEXT;
    v_asutus    RECORD;
    v_old_date  DATE;
    v_history   JSONB;
BEGIN
    -- 1. Проверка прав (роль is_asutuste_korraldaja)
    SELECT u.kasutaja
    INTO v_user_name
    FROM ou.userid u
    WHERE u.id = l_user_id
      AND coalesce((u.roles ->> 'is_asutuste_korraldaja')::BOOLEAN, FALSE);

    IF v_user_name IS NULL THEN
        RAISE EXCEPTION 'Viga: pole õigused';
    END IF;

    -- 2. Чтение карточки контрагента
    SELECT
        a.id,
        ltrim(rtrim(a.regkood))                                   AS regkood,
        ltrim(rtrim(a.nimetus))                                   AS nimetus,
        ltrim(rtrim(coalesce(a.properties ->> 'kehtivus', '')))   AS kehtivus_raw
    INTO v_asutus
    FROM libs.asutus a
    WHERE a.staatus < 3
      AND a.id = l_asutusid;

    IF v_asutus.id IS NOT NULL THEN
        IF v_asutus.kehtivus_raw ~ '^\d{4}-\d{2}-\d{2}' THEN
            v_old_date := substring(v_asutus.kehtivus_raw FROM 1 FOR 10)::DATE;
        ELSE
            v_old_date := NULL;
        END IF;

        -- Ставим kehtivus, если дата отсутствует или текущая дата позже l_kehtise_aeg
        IF v_old_date IS NULL OR v_old_date > l_kehtise_aeg THEN
            v_history := jsonb_build_array(
                jsonb_build_object(
                    'updated', now(),
                    'user', v_user_name,
                    'action', 'set_asutuse_kehtivus',
                    'old_kehtivus', CASE WHEN v_asutus.kehtivus_raw = '' THEN NULL ELSE v_asutus.kehtivus_raw END,
                    'kehtivus', l_kehtise_aeg::TEXT
                )
            );

            UPDATE libs.asutus
            SET
                properties = coalesce(properties, '{}'::jsonb) || jsonb_build_object('kehtivus', l_kehtise_aeg::TEXT),
                ajalugu    = coalesce(ajalugu, '[]'::jsonb) || v_history
            WHERE id = l_asutusid;

            l_result := jsonb_build_array(
                jsonb_build_object(
                    'asutus_id', v_asutus.id,
                    'regkood', v_asutus.regkood,
                    'nimetus', v_asutus.nimetus,
                    'old_kehtivus', CASE WHEN v_asutus.kehtivus_raw = '' THEN NULL ELSE v_asutus.kehtivus_raw END,
                    'kehtivus', l_kehtise_aeg::TEXT,
                    'staatus', 'suletatud'
                )
            );
        END IF;
    END IF;

    RETURN l_result;
END;
$$;

GRANT EXECUTE ON FUNCTION libs.set_asutuse_kehtivus(INTEGER, INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.set_asutuse_kehtivus(INTEGER, INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION libs.set_asutuse_kehtivus(INTEGER, INTEGER, DATE) TO dbadmin;
