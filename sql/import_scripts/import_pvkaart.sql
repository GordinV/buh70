DROP FUNCTION IF EXISTS import_pvkaart(INTEGER);

CREATE OR REPLACE FUNCTION import_pvkaart(in_old_id INTEGER)
    RETURNS INTEGER AS
$BODY$
DECLARE
    pv_id          INTEGER;
    log_id         INTEGER;
    v_pv           RECORD;
    json_object    JSONB;
    hist_object    JSONB;
    v_params       RECORD;
    l_count        INTEGER = 0;
    l_vast_isik_id INTEGER;
    l_grupp_id     INTEGER;
    l_user_id      INTEGER;
BEGIN
    -- выборка из "старого меню"

    FOR v_pv IN
        SELECT p.*,
               l.nimetus AS fixed_nimi
        FROM curpohivara p
                 INNER JOIN library l ON l.id = p.id
                 INNER JOIN rekv ON rekv.id = p.rekvid AND rekv.parentid < 999
        WHERE (p.id = in_old_id OR in_old_id IS NULL)
          AND rekv.id NOT IN (3, 63, 131)
          AND (p.mahakantud IS NULL OR p.mahakantud >= '2020-12-31')
            LIMIT ALL
        LOOP

            -- поиск и проверка на ранее сделанный импорт
            SELECT new_id,
                   id
                   INTO pv_id, log_id
            FROM import_log
            WHERE old_id = v_pv.id
              AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'POHIVARA';

            -- поиск pv_konto


            RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_pv.id, pv_id, log_id;

            -- преобразование и получение параметров
            l_grupp_id = (SELECT new_id
                          FROM import_log
                          WHERE old_id = v_pv.gruppid
                            AND lib_name = 'PVGRUPP');

            IF l_grupp_id IS NULL
            THEN
                RAISE EXCEPTION 'PV grupp not found v_pv.gruppid %, l_grupp_id %', v_pv.gruppid, l_grupp_id;
            END IF;

            l_vast_isik_id = (SELECT new_id
                              FROM import_log
                              WHERE old_id = v_pv.vastisikid
                                AND lib_name = 'ASUTUS');

            l_user_id = (SELECT id FROM ou.userid WHERE rekvid = v_pv.rekvid AND kasutaja = 'vlad' LIMIT 1);
            -- сохранение
            SELECT coalesce(pv_id, 0) AS id,
                   v_pv.kood,
                   v_pv.fixed_nimi    AS nimetus,
                   l_grupp_id         AS gruppid,
                   v_pv.konto,
                   v_pv.soetkpv,
                   v_pv.kulum,
                   v_pv.algkulum,
                   v_pv.soetmaks,
                   v_pv.selgitus      AS selg,
                   l_vast_isik_id     AS vastisikid,
                   v_pv.rentnik,
                   v_pv.liik
                   INTO v_params;

            SELECT row_to_json(row) INTO json_object
            FROM (SELECT coalesce(pv_id, 0) AS id,
                         TRUE               AS import,
                         v_params           AS data) row;

            SELECT libs.sp_salvesta_pv_kaart(json_object :: JSON, l_user_id, v_pv.rekvid) INTO pv_id;
            RAISE NOTICE 'pv_id %, l_count %', pv_id, l_count;

            IF v_pv.mahakantud IS NOT NULL AND NOT empty(v_pv.mahakantud) OR
               exists(SELECT id FROM pv_oper WHERE parentid = v_pv.id AND liik = 4)
            THEN
                IF v_pv.mahakantud IS NULL OR empty(v_pv.mahakantud)
                THEN
                    v_pv.mahakantud = (SELECT kpv FROM pv_oper WHERE parentid = v_pv.id AND liik = 4 LIMIT 1);
                END IF;
                -- списание

                UPDATE libs.library
                SET status     = 2,
                    properties = properties :: JSONB || (SELECT row_to_json(row)
                                                         FROM (SELECT v_pv.mahakantud :: DATE AS mahakantud) row) :: JSONB
                WHERE id = pv_id;

            END IF;

            -- salvestame log info
            SELECT row_to_json(row) INTO hist_object
            FROM (SELECT now() AS timestamp) row;

            IF log_id IS NULL
            THEN
                INSERT INTO import_log (new_id, old_id, lib_name, params, history)
                VALUES (pv_id, v_pv.id, 'POHIVARA', json_object :: JSON, hist_object :: JSON) RETURNING id
                    INTO log_id;

            ELSE
                UPDATE import_log
                SET params  = json_object :: JSON,
                    history = (history :: JSONB || hist_object :: JSONB) :: JSON
                WHERE id = log_id;
            END IF;

            IF empty(log_id)
            THEN
                RAISE EXCEPTION 'log save failed';
            END IF;
            l_count = l_count + 1;
        END LOOP;

    -- control
    /*
    IF (SELECT count(id)
        FROM libs.library
        WHERE LIBRARY = 'POHIVARA')
       >= l_count
    THEN
      RAISE NOTICE 'Import ->ok';
    ELSE
      RAISE EXCEPTION 'Import failed, new_count < old_count %', l_count;
    END IF;
  */

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

select import_pvkaart(id) from curPohivara where kood in ('MUU-80', 'MUU-81', 'MUU-82')
and rekvid = 28
and mahakantud is null

select * from cur_pohivara where rekvid = 28 and kood = 'MUU-80'

SELECT import_pvkaart(733119)
SELECT import_pvkaart(id)
from curPohivara
where
(mahakantud is null or year(mahakantud) > 2020)
and rekvid not in (3, 63, 131)

*/

UPDATE libs.library set status = 1 where id in (
    SELECT new_id
    FROM import_log
    WHERE old_id IN (
        SELECT id
        FROM curPohivara
        WHERE kood IN ('MUU-80', 'MUU-81', 'MUU-82')
          AND rekvid = 28
          AND mahakantud IS NULL
    )
      AND lib_name = 'POHIVARA'
)

select * from libs.library where id = 203303