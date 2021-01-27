DROP FUNCTION IF EXISTS import_palk_kaart(INTEGER);


DROP FOREIGN TABLE IF EXISTS remote_palk_kaart;

/*
CREATE FOREIGN TABLE remote_palk_kaart (
  id        INTEGER                    NOT NULL,
  parentid  INTEGER                   NOT NULL,
  lepingid  INTEGER        DEFAULT 0  NOT NULL,
  libid     INTEGER        DEFAULT 0  NOT NULL,
  summa     NUMERIC(12, 4) DEFAULT 0  NOT NULL,
  percent_  SMALLINT       DEFAULT 1  NOT NULL,
  tulumaks  SMALLINT       DEFAULT 1  NOT NULL,
  tulumaar  SMALLINT       DEFAULT 26 NOT NULL,
  status    SMALLINT       DEFAULT 1  NOT NULL,
  muud      TEXT,
  alimentid INTEGER        DEFAULT 0  NOT NULL,
  tunnusid  BIGINT         DEFAULT 0  NOT NULL,
  vanaid    INTEGER,
  minsots   INTEGER
  )  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'palk_kaart');
*/

CREATE OR REPLACE FUNCTION import_palk_kaart(in_old_id INTEGER)
    RETURNS INTEGER AS
$BODY$
DECLARE
    pk_id       INTEGER;
    log_id      INTEGER;
    v_pk        RECORD;
    json_object JSONB;
    hist_object JSONB;
    v_params    RECORD;
    l_count     INTEGER = 0;
    l_asutus_id INTEGER;
    l_lib_id    INTEGER;
    l_tunnus    TEXT;
    l_user_id   INTEGER;
BEGIN
    -- выборка из "старого меню"

    FOR v_pk IN
        SELECT pk.*,
               t.rekvid,
               il.new_id AS new_leping_id
        FROM palk_kaart pk
                 INNER JOIN tooleping t ON t.id = pk.lepingid
                 INNER JOIN rekv ON rekv.id = t.rekvid AND rekv.parentid < 999
                 INNER JOIN import_log il ON il.old_id = t.id AND il.lib_name = 'TOOLEPING'
            WHERE (pk.id = in_old_id OR in_old_id IS NULL)
                 AND exists(SELECT 1
                            FROM library WHERE id = pk.libid)
                 AND exists(SELECT 1
                            FROM asutus WHERE id = pk.parentid)
                 AND t.rekvid NOT IN (3, 63, 131)
                 AND (t.lopp IS NULL OR t.lopp > '2020-12-31')
            LIMIT ALL
        LOOP

            -- поиск и проверка на ранее сделанный импорт
            SELECT new_id,
                   id
                   INTO pk_id, log_id
            FROM import_log
                WHERE old_id = v_pk.id
                     AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'PALK_KAART';

            RAISE NOTICE 'check for lib.. v_pk.id -> %, found -> % log_id -> %', v_pk.id, pk_id, log_id;

            l_asutus_id = (SELECT new_id
                           FROM import_log
                               WHERE lib_name = 'ASUTUS'
                                    AND old_id = v_pk.parentid);

            l_lib_id = (SELECT new_id
                        FROM import_log
                            WHERE lib_name = 'PALK'
                                 AND old_id = v_pk.libid);

            l_tunnus = (SELECT kood
                        FROM library
                            WHERE id = v_pk.tunnusid);

            IF l_asutus_id IS NULL OR l_lib_id IS NULL
            THEN
                RAISE EXCEPTION 'data not found v_pk.parentid %, l_asutus_id %, v_pk.libid %, l_lib_id %', v_pk.parentid, l_asutus_id, v_pk.libid, l_lib_id;
            END IF;
            -- преобразование и получение параметров
            l_user_id = (SELECT id
                         FROM ou.userid WHERE rekvid = v_pk.rekvid AND kasutaja = 'vlad' LIMIT 1);

            IF pk_id IS NOT NULL AND NOT exists(SELECT id
                                                FROM palk.palk_kaart WHERE id = pk_id)
            THEN
                pk_id = NULL;
            END IF;

            -- сохранение
            SELECT coalesce(pk_id, 0)                          AS id,
                   l_asutus_id                                 AS parentid,
                   l_lib_id                                    AS libid,
                   v_pk.new_leping_id                          AS lepingid,
                   v_pk.summa,
                   v_pk.percent_,
                   v_pk.tulumaks,
                   v_pk.tulumaar,
                   v_pk.alimentid,
                   l_tunnus                                    AS tunnus,
                   v_pk.minsots,
                   v_pk.muud                                   AS muud,
                   CASE WHEN v_pk.status = 0 THEN 2 ELSE 1 END AS status
                   INTO v_params;

            SELECT row_to_json(row) INTO json_object
            FROM (SELECT coalesce(pk_id, 0) AS id,
                         TRUE               AS import,
                         v_params           AS data) row;

            SELECT palk.sp_salvesta_palk_kaart(json_object :: JSON, l_user_id, v_pk.rekvid) INTO pk_id;
            RAISE NOTICE 'pk_id %, l_count %', pk_id, l_count;

            -- salvestame log info
            SELECT row_to_json(row) INTO hist_object
            FROM (SELECT now() AS timestamp) row;

            IF log_id IS NULL
            THEN
                INSERT INTO import_log (new_id, old_id, lib_name, params, history)
                VALUES (pk_id, v_pk.id, 'PALK_KAART', json_object :: JSON, hist_object :: JSON) RETURNING id
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
SELECT import_palk_kaart(id)
from palk_kaart where lepingid in (
select id from tooleping where parentid in (select id from asutus where regkood in
('48411083719'))
and rekvid = 79
and lopp is null
)

select * from rekv where nimetus ilike '%23601%'

SELECT import_palk_kaart(id)
from palk_kaart where lepingid in (select id from tooleping where parentid in (
select id from asutus where regkood in ('46704273740','44702143710','48506013716','46104073710','46009192711','46310083729','37801213718','36804303721',
'46204283721','48404082243','37208077014','48006173716')
)
and lopp is null)

select import_palk_kaart(id) from palk_kaart where lepingid in (select id from tooleping where rekvid = 106 and lopp is null)


SELECT import_palk_kaart(id) from palk_kaart
where
lepingid in
(
select id from tooleping where rekvid in (select id from rekv where (parentid < 999 and id not in (3, 63, 131, 106) and parentid = 119) or id = 119  )
and lopp is null
)

(select old_id from import_log where lib_name = 'TOOLEPING')


SELECT import_palk_kaart(id) from (
select id from remote_palk_kaart
where
lepingid in (select old_id from import_log where lib_name = 'TOOLEPING')
except
select old_id from import_log where lib_name = 'PALK_KAART'
) qry

delete from palk.palk_kaart where id in
(select id from palk.palk_kaart where lepingid in (select id from palk.tooleping where rekvid not in (3, 63, 131))
except
select new_id from import_log where lib_name = 'PALK_KAART'
)

select * from palk_kaart where id < 10

select * from tooleping where id = 3
*/