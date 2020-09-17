DROP FUNCTION IF EXISTS import_to_new_asutus_palk();

CREATE OR REPLACE FUNCTION import_to_new_asutus_palk()
    RETURNS INTEGER AS
$BODY$
DECLARE
    lib_id      INTEGER;
    v_lib       RECORD;
    json_object JSONB;
    v_params    RECORD;
    l_count     INTEGER = 0;
    l_user_id   INTEGER = (SELECT id
                           FROM ou.userid
                           WHERE rekvid = 132
                             AND kasutaja = 'vlad'
                           LIMIT 1);

BEGIN
    -- выборка из "старого меню"

    FOR v_lib IN
        SELECT l.*,
               p.liik,
               p.tund,
               p.maks,
               p.round,
               p.sots,
               p.elatis,
               p.tululiik,
               p.asutusest,
               p.palgafond,
               p.konto AS korrkonto,
               k.tunnusid,
               k.konto,
               k.kood1 AS tegev,
               k.kood2 AS allikas,
               k.kood3 AS rahavoog,
               k.kood5 AS artikkel,
               k.kood4 AS uritus,
               t.kood  AS tunnus,
               k.proj
        FROM library l
                 INNER JOIN palk_lib p ON p.parentid = l.id
                 LEFT OUTER JOIN klassiflib k ON k.libid = l.id
                 LEFT OUTER JOIN library t ON t.id = k.tunnusid
                 INNER JOIN rekv ON l.rekvid = rekv.id AND rekv.parentid < 999
        WHERE l.library = 'PALK'
          AND l.rekvid = 64
        LIMIT ALL
        LOOP

            SELECT id INTO lib_id
            FROM libs.library
            WHERE rekvid = 132
              AND library.library = 'PALK'
              AND status <> 3
              AND kood = v_lib.kood;

            -- преобразование и получение параметров

            -- сохранение
            SELECT coalesce(lib_id, 0) AS id,
                   v_lib.kood          AS kood,
                   v_lib.nimetus       AS nimetus,
                   v_lib.tun1          AS tun1,
                   v_lib.tun2          AS tun2,
                   v_lib.tun3          AS tun3,
                   v_lib.tun4          AS tun4,
                   v_lib.tun5          AS tun5,
                   v_lib.liik          AS liik,
                   v_lib.tululiik      AS tululiik,
                   v_lib.tund          AS tund,
                   v_lib.maks          AS maks,
                   v_lib.asutusest     AS asutusest,
                   v_lib.palgafond     AS palgafond,
                   v_lib.sots          AS sots,
                   v_lib.elatis        AS elatis,
                   v_lib.round         AS round,
                   v_lib.konto         AS konto,
                   v_lib.korrkonto     AS korrkonto,
                   NULL                AS tunnusid,
                   v_lib.uritus        AS uritus,
                   v_lib.proj          AS proj,
                   v_lib.tegev         AS tegev,
                   v_lib.allikas       AS allikas,
                   v_lib.artikkel      AS artikkel,
                   v_lib.muud          AS muud
                   INTO v_params;

            SELECT row_to_json(row) INTO json_object
            FROM (SELECT coalesce(lib_id, 0) AS id,
                         TRUE                AS import,
                         v_params            AS data) row;

            SELECT libs.sp_salvesta_palk_lib(json_object :: JSON, l_user_id, 132) INTO lib_id;
            RAISE NOTICE 'lib_id %, l_count %', lib_id, l_count;
            IF empty(lib_id)
            THEN
                RAISE EXCEPTION 'saving not success';
            END IF;

            l_count = l_count + 1;
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
select import_to_new_asutus_palk()
*/