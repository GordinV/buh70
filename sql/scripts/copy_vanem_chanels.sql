DROP FUNCTION IF EXISTS lapsed.copy_vanem_chanels();

CREATE FUNCTION lapsed.copy_vanem_chanels()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_va     RECORD;
    v_vastav RECORD;
BEGIN
    FOR v_va IN
        SELECT va.*
        FROM lapsed.vanem_arveldus va
        WHERE va.rekvid = 94
        and parentid in (select parentid from lapsed.lapse_kaart where rekvid = 84 and staatus < 3)
        LOOP
            -- ищем ответственного в 84
            SELECT va.*
            INTO v_vastav
            FROM lapsed.vanem_arveldus va
            WHERE rekvid = 84
              AND asutusid = v_va.asutusid
              AND parentid = v_va.parentid;
            IF v_vastav IS NULL
            THEN
                RAISE NOTICE 'Puudub, insert v_va.asutusid  %, v_va.parentid %', v_va.asutusid, v_va.parentid;
/*                INSERT INTO lapsed.vanem_arveldus (parentid, asutusid, rekvid, arveldus, properties, kas_email,
                                                   kas_paberil)
                VALUES (v_va.parentid, v_va.asutusid, 84, v_va.arveldus, v_va.properties, v_va.kas_email,
                        v_va.kas_paberil);
*/            ELSE
                IF NOT v_vastav.arveldus and not exists (select id from lapsed.vanem_arveldus where parentid = v_va.parentid and arveldus and rekvid = 84)
                THEN
                    RAISE NOTICE 'update v_vastav.arveldus %,  v_va.asutusid  %, v_va.parentid %', v_vastav.arveldus,v_va.asutusid, v_va.parentid;
                END IF;
            END IF;

        END LOOP;
    RETURN 1;

END;
$$;

SELECT lapsed.copy_vanem_chanels();

DROP FUNCTION IF EXISTS lapsed.copy_vanem_chanels();

/*
 select trim(replace(vn,E'\n',''),'"'), vn, ik, asutus from tmp_viitenr_kustuta

SELECT id FROM ou.rekv WHERE left(nimetus, 10) = left(trim('"0911027 Narva Lasteaed Pongerjas T"','"'), 10) LIMIT 1

          FROM lapsed.viitenr
            WHERE isikukood = v_vn.ik
              AND rekv_id = l_rekv_id
              AND viitenumber = trim(replace(v_vn.vn,E'\n',''),'"');

select * from tmp_viitenr_kustuta
 where vn = '9366554'

 */
