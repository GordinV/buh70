DROP FUNCTION IF EXISTS import_tooleping(INTEGER);
/*

DROP FOREIGN TABLE IF EXISTS remote_tooleping;

CREATE FOREIGN TABLE remote_tooleping (
  id          SERIAL                                    NOT NULL,
  parentid    INTEGER                                   NOT NULL,
  osakondid   INTEGER       DEFAULT 0                   NOT NULL,
  ametid      INTEGER       DEFAULT 0                   NOT NULL,
  algab       DATE          DEFAULT ('now'::TEXT)::DATE NOT NULL,
  lopp        DATE,
  palk        NUMERIC(12,4) DEFAULT 0                   NOT NULL,
  palgamaar   SMALLINT      DEFAULT 0                   NOT NULL,
  pohikoht    SMALLINT      DEFAULT 1                   NOT NULL,
  ametnik     SMALLINT      DEFAULT 0                   NOT NULL,
  tasuliik    SMALLINT      DEFAULT 1                   NOT NULL,
  pank        SMALLINT      DEFAULT 0                   NOT NULL,
  aa          VARCHAR(16)   DEFAULT space(1)            NOT NULL,
  muud        TEXT,
  rekvid      INTEGER       DEFAULT 0                   NOT NULL,
  resident    INTEGER       DEFAULT 1                   NOT NULL,
  riik        VARCHAR(3)    DEFAULT space(1)            NOT NULL,
  toend       DATE,
  vanaid      INTEGER,
  vanakoormus NUMERIC(12,4),
  koormus     NUMERIC(12,4),
  vanatoopaev INTEGER,
  toopaev     NUMERIC(12,4) DEFAULT 0                   NOT NULL)
  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'tooleping');


 */
CREATE OR REPLACE FUNCTION import_tooleping(in_old_id INTEGER)
    RETURNS INTEGER AS
$BODY$
DECLARE
    leping_id    INTEGER;
    log_id       INTEGER;
    v_leping     RECORD;
    json_object  JSONB;
    hist_object  JSONB;
    v_params     RECORD;
    l_count      INTEGER = 0;
    l_osakond_id INTEGER;
    l_amet_id    INTEGER;
    l_asutus_id  INTEGER;
    l_user_id    INTEGER;
BEGIN
    -- выборка из "старого меню"

    FOR v_leping IN
        SELECT t.*
        FROM tooleping t
                 INNER JOIN rekv rekv ON rekv.id = t.rekvid AND rekv.parentid < 999 AND rekvid NOT IN (15)
        WHERE (t.id = in_old_id OR in_old_id IS NULL)
          AND NOT empty(t.ametid)
          AND t.osakondid IN (SELECT id FROM remote_library WHERE library = 'OSAKOND')
          AND t.ametid IN (SELECT id FROM remote_library WHERE library = 'AMET')
          AND rekv.id IN (SELECT id FROM rekv WHERE parentid < 999 AND id NOT IN (3, 63, 131))
--          AND (t.lopp IS NULL OR t.lopp > '2020-12-31'::DATE)
            LIMIT ALL
        LOOP

            -- поиск и проверка на ранее сделанный импорт
            SELECT new_id,
                   id
                   INTO leping_id, log_id
            FROM import_log
            WHERE old_id = v_leping.id
              AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'TOOLEPING';

            RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_leping.id, leping_id, log_id;

            l_osakond_id = (SELECT new_id
                            FROM import_log
                            WHERE old_id = v_leping.osakondid
                              AND lib_name = 'OSAKOND');
            l_amet_id = (SELECT new_id
                         FROM import_log
                         WHERE old_id = v_leping.ametid
                           AND lib_name = 'AMET');

            l_asutus_id = (SELECT new_id
                           FROM import_log
                           WHERE old_id = v_leping.parentid
                             AND lib_name = 'ASUTUS');

            IF l_osakond_id IS NULL OR l_amet_id IS NULL OR l_asutus_id IS NULL or empty(l_amet_id)
            THEN
                RAISE EXCEPTION 'amet or osakond not found v_leping.osakondid %,l_osakond_id %, v_leping.ametid %, l_amet_id %, v_leping.parentid %,  l_asutus_id %', v_leping.osakondid, l_osakond_id, v_leping.ametid, l_amet_id, v_leping.parentid, l_asutus_id;
            END IF;
            -- преобразование и получение параметров

            -- ищем договора

            IF leping_id IS NOT NULL AND NOT exists(SELECT id FROM palk.tooleping WHERE id = leping_id)
            THEN
                DELETE from import_log
                WHERE id = log_id;

                leping_id = NULL;
                log_id = null;
                raise notice 'log info not found, cleaned %', log_id;
            END IF;

            l_user_id = (SELECT id FROM ou.userid WHERE kasutaja = 'vlad' AND rekvid = v_leping.rekvid LIMIT 1);
            -- сохранение
            SELECT coalesce(leping_id, 0) AS id,
                   l_asutus_id            AS parentid,
                   l_osakond_id           AS osakondid,
                   l_amet_id              AS ametid,
                   v_leping.algab,
                   v_leping.lopp,
                   v_leping.palk,
                   v_leping.palgamaar,
                   v_leping.resident,
                   v_leping.riik,
                   v_leping.toend,
                   v_leping.koormus,
                   v_leping.toopaev,
                   v_leping.ametnik,
                   v_leping.tasuliik,
                   v_leping.muud          AS muud
                   INTO v_params;

            SELECT row_to_json(row) INTO json_object
            FROM (SELECT coalesce(leping_id, 0) AS id,
                         TRUE                   AS import,
                         v_params               AS data) row;

            IF v_leping.lopp IS NOT NULL AND v_leping.lopp <= '2020-12-31'
            THEN
                -- уволен, не актуально
                IF leping_id IS NOT NULL
                THEN
                    UPDATE palk.tooleping SET lopp = v_leping.lopp WHERE id = leping_id;
                    RAISE NOTICE 'loppetatud %, v_leping.lopp %', leping_id, v_leping.lopp;
                END IF;
            ELSE

                SELECT palk.sp_salvesta_tooleping(json_object :: JSON, l_user_id, v_leping.rekvid) INTO leping_id;
                RAISE NOTICE 'leping_id %, l_count %', leping_id, l_count;


                -- salvestame log info
                SELECT row_to_json(row) INTO hist_object
                FROM (SELECT now() AS timestamp) row;

                IF log_id IS NULL and leping_id > 0
                THEN
                    INSERT INTO import_log (new_id, old_id, lib_name, params, history)
                    VALUES (leping_id, v_leping.id, 'TOOLEPING', json_object :: JSON, hist_object :: JSON) RETURNING id
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
delete from palk.tooleping where rekvid in (select id from ou.rekv where parentid = 119 or id = 119) and lopp is not null

delete from palk.tooleping where parentid in (select id from libs.asutus where regkood = '46410152219')


SELECT import_tooleping(id) from tooleping
where rekvid in (select id from rekv where id = 64)
and lopp is null
and rekvid <>  106

select * from asutus where regkood = '46410152219'

select import_tooleping(id)  from tooleping where parentid = 16782  and lopp is null

select * from ou.rekv where nimetus ilike '%kesklin%'

--and (tooleping.lopp is null or tooleping.lopp > '2020-12-31')
--and id = 146020

select * from palk.tooleping where id = 8

select * from tooleping where rekvid = 63 and lopp is null or year(lopp) >= 2017

SELECT import_tooleping(id) from tooleping where
lopp is null or year(lopp) >= 2017
INSERT INTO library (id, rekvid, kood, nimetus, library, muud, tun1, tun2, tun3, tun4, tun5, vanaid) VALUES (287565, 112, '0922013             ', 'Narva Soldino G𭮡asium 0922013                                                                                                                                                                                                                              ', 'OSAKOND             ', NULL, 0, 0, 0, 0, 0, NULL);

SELECT import_tooleping(id) from (
select id from remote_tooleping where parentid <> 0 and rekvid in (select id from rekv where id = 119 or parentid = 119)
except
select old_id from import_log where lib_name = 'TOOLEPING'
) qry


select * from remote_tooleping where id = 144767

select * from library where id = 717841

select * from import_log where old_id = 717841

delete from import_log where new_id = 0 and lib_name = 'AMET'

*/

--INSERT INTO library (id, rekvid, kood, nimetus, library, muud, tun1, tun2, tun3, tun4, tun5, vanaid) VALUES (611504, 112, 'pedagoog-P          ', 'pedagoog-P                                                                                                                                                                                                                                                    ', 'AMET                ', '', 0, 0, 0, 0, 0, NULL);
