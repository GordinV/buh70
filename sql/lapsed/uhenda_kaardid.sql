-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.uhenda_kaardid(TEXT, TEXT);

CREATE OR REPLACE FUNCTION lapsed.uhenda_kaardid(l_oige_ik TEXT, l_vale_ik TEXT)
    RETURNS BOOLEAN AS

$BODY$

DECLARE
    return_date    DATE;
    l_oige_laps_id INTEGER;
    l_vale_laps_id INTEGER;
    v_vanem        RECORD;
BEGIN
    SELECT id
    INTO l_oige_laps_id
    FROM lapsed.laps
    WHERE isikukood = l_oige_ik
      AND staatus < 3
    LIMIT 1;

    SELECT id
    INTO l_vale_laps_id
    FROM lapsed.laps
    WHERE isikukood = l_vale_ik
      AND staatus < 3
    LIMIT 1;

    RAISE NOTICE 'l_oige_laps_id %, l_vale_laps_id %',l_oige_laps_id, l_vale_laps_id;

    IF (l_vale_laps_id IS NULL)
    THEN
        RAISE EXCEPTION 'Vale vale IK, laps ei leidnud %', l_vale_laps_id;
    END IF;

    IF (l_oige_laps_id IS NULL)
    THEN
        RAISE NOTICE 'Ainult kaardi parandus';
        -- такой только один, просто меняем IK в карточке
        UPDATE lapsed.laps SET isikukood = l_oige_ik WHERE id = l_vale_laps_id;
        RETURN TRUE;
    END IF;

    -- карточка
    UPDATE lapsed.lapse_kaart SET parentid = l_oige_laps_id WHERE parentid = l_vale_laps_id AND staatus < 3;
    -- табеля
    UPDATE lapsed.lapse_taabel SET parentid = l_oige_laps_id WHERE parentid = l_vale_laps_id AND staatus < 3;

    UPDATE lapsed.day_taabel1 SET laps_id = l_oige_laps_id WHERE laps_id = l_vale_laps_id;

    -- документы
    UPDATE lapsed.liidestamine SET parentid = l_oige_laps_id WHERE parentid = l_vale_laps_id;

    -- vana VN
    update lapsed.viitenr set isikukood = l_oige_ik where isikukood = l_vale_ik;

    -- родители
    FOR v_vanem IN
        SELECT *
        FROM lapsed.vanem_arveldus va
        WHERE va.parentid = l_vale_laps_id
        LOOP
            RAISE NOTICE 'v_vanem arv kontrol v_vanem.parentid %, v_vanem.asutusid %, v_vanem.rekvid %', v_vanem.parentid, v_vanem.asutusid, v_vanem.rekvid;
            IF NOT exists(SELECT id
                          FROM lapsed.vanem_arveldus va
                          WHERE va.parentid = l_oige_laps_id
                            AND asutusid = v_vanem.asutusid
                            AND va.rekvid = v_vanem.rekvid)
            THEN
                RAISE NOTICE 'Update';
                -- нет связи, апдейт
                UPDATE lapsed.vanem_arveldus SET parentid = l_oige_laps_id WHERE id = v_vanem.id;
            ELSE
                RAISE NOTICE 'Delete';

                DELETE FROM lapsed.vanem_arveldus WHERE id = v_vanem.id;
            END IF;
        END LOOP;

    FOR v_vanem IN
        SELECT *
        FROM lapsed.vanemad v
        WHERE v.parentid = l_vale_laps_id
        LOOP
            RAISE NOTICE 'v_vanem arv kontrol v_vanem.parentid %, v_vanem.asutusid %, ', v_vanem.parentid, v_vanem.asutusid;
            IF NOT exists(SELECT id
                          FROM lapsed.vanemad v
                          WHERE v.parentid = l_oige_laps_id
                            AND asutusid = v_vanem.asutusid)
            THEN
                RAISE NOTICE 'Update';
                -- нет связи, апдейт
                UPDATE lapsed.vanemad SET parentid = l_oige_laps_id WHERE id = v_vanem.id;
            ELSE
                RAISE NOTICE 'Delete';
                DELETE FROM lapsed.vanemad WHERE id = v_vanem.id;
            END IF;
        END LOOP;

    -- viitenr
    UPDATE lapsed.viitenr SET isikukood = l_oige_ik WHERE ltrim(rtrim(isikukood)) = ltrim(rtrim(l_vale_ik));

    -- удаляем карточку
    UPDATE lapsed.laps SET staatus = 3 WHERE id = l_vale_laps_id;

    RETURN TRUE;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN FALSE;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

/*
select lapsed.uhenda_kaardid('61910080073', ' 6191008007')

select * from lapsed.lapse_kaart where parentid = 10329

*/