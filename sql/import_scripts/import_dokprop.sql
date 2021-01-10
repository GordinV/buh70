DROP FUNCTION IF EXISTS import_dokprop();
DROP FUNCTION IF EXISTS import_dokprop(INTEGER);
DROP FUNCTION IF EXISTS import_dokprop(INTEGER, TEXT);

DROP FOREIGN TABLE IF EXISTS remote_dokprop;
/*
CREATE FOREIGN TABLE remote_dokprop (
  id        INTEGER                         NOT NULL,
  parentid  INTEGER                        NOT NULL,
  proc_     VARCHAR(120) DEFAULT space(1)  NOT NULL,
  registr   SMALLINT     DEFAULT 1         NOT NULL,
  vaatalaus SMALLINT     DEFAULT 0         NOT NULL,
  selg      TEXT         DEFAULT space(1)  NOT NULL,
  muud      TEXT,
  asutusid  INTEGER      DEFAULT 0         NOT NULL,
  konto     VARCHAR(20)  DEFAULT space(20) NOT NULL,
  kood1     VARCHAR(20)  DEFAULT space(20) NOT NULL,
  kood2     VARCHAR(20)  DEFAULT space(20) NOT NULL,
  kood3     VARCHAR(20)  DEFAULT space(20) NOT NULL,
  kood4     VARCHAR(20)  DEFAULT space(20) NOT NULL,
  kood5     VARCHAR(20)  DEFAULT space(20) NOT NULL,
  kbmkonto  VARCHAR(20)  DEFAULT space(20) NOT NULL,
  tyyp      INTEGER      DEFAULT 1         NOT NULL  )
  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'dokprop');

 */
CREATE OR REPLACE FUNCTION import_dokprop(in_old_id INTEGER)
    RETURNS INTEGER AS
$BODY$
DECLARE
    lib_id      INTEGER;
    log_id      INTEGER;
    v_lib       RECORD;
    json_object JSONB;
    hist_object JSONB;
    v_params    RECORD;
    l_count     INTEGER = 0;
    l_asutus_id INTEGER;
    l_lib_id    INTEGER;
    l_dok_tyyp  TEXT;
    l_user_id INTEGER = (select id from ou.userid where rekvid = 132 and kasutaja = 'vlad' limit 1);
BEGIN
    -- выборка из "старого меню"

    FOR v_lib IN
        SELECT d.*,
               l.kood AS dok,
               l.rekvid
        FROM dokprop d
                 INNER JOIN library l ON l.id = d.parentid
        WHERE (d.id = in_old_id OR in_old_id IS NULL)
          AND l.kood IN
--            ('ARV', 'AVANS','AVANSS', 'DEKL', 'KULUM', 'PALK', 'MAHAKANDMINE', 'PAIGUTUS', 'UMBERHINDAMINE', 'VORDER', 'SORDER', 'PARANDUS', 'MK')
              ('ARV', 'KULUM', 'PALK', 'MAHAKANDMINE', 'PAIGUTUS', 'UMBERHINDAMINE', 'PARANDUS')
          AND rekvid = 64
            LIMIT ALL
        LOOP

            -- поиск и проверка на ранее сделанный импорт
            /*
        SELECT new_id,
               id
               INTO lib_id, log_id
        FROM import_log
        WHERE old_id = v_lib.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'DOKPROP';

*/
            lib_id = NULL;
            log_id = NULL;

            RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_lib.id, lib_id, log_id;

            -- преобразование и получение параметров
            /*
              doc_kood1     TEXT = doc_data ->> 'kood1';
              doc_kood2     TEXT = doc_data ->> 'kood2';
              doc_kood3     TEXT = doc_data ->> 'kood3';
              doc_kood5     TEXT = doc_data ->> 'kood5';
              doc_proc_     TEXT = doc_data ->> 'proc_';
              doc_type      INTEGER = doc_data ->> 'type';
              doc_parentid  INTEGER = doc_data ->> 'parentid';

             */
            l_asutus_id = (SELECT new_id
                           FROM import_log
                           WHERE old_id = v_lib.asutusid
                             AND lib_name = 'ASUTUS');
            IF NOT empty(v_lib.asutusid) AND l_asutus_id IS NULL
            THEN
                RAISE EXCEPTION 'asutus not found v_lib.asutusid %, l_asutus_id %', v_lib.asutusid, l_asutus_id;
            END IF;

            l_dok_tyyp = ltrim(rtrim(v_lib.dok));
            CASE ltrim(rtrim(v_lib.dok))
                WHEN 'MK'
                    THEN
                        l_dok_tyyp = 'VMK';
                WHEN 'AVANSS'
                    THEN
                        l_dok_tyyp = 'AVANS';

                WHEN 'PALK'
                    THEN
                        l_dok_tyyp = 'PALK_OPER';

                ELSE
                    l_dok_tyyp = ltrim(rtrim(v_lib.dok));
                END CASE;

            l_lib_id = (SELECT ID
                        FROM libs.library
                        WHERE ltrim(rtrim(kood)) = l_dok_tyyp
                          AND library = 'DOK');

            IF l_lib_id IS NULL
            THEN
                RAISE NOTICE 'dok. type not found v_lib.dok %, l_lib_id %', v_lib.dok, l_lib_id;
            END IF;

            -- сохранение
            SELECT coalesce(lib_id, 0) AS id,
                   v_lib.dok           AS dok,
                   v_lib.selg          AS selg,
                   v_lib.registr       AS registr,
                   v_lib.vaatalaus     AS vaatalaus,
                   v_lib.konto         AS konto,
                   v_lib.kbmkonto      AS kbmkonto,
                   l_asutus_id         AS asutusid,
                   v_lib.kood1         AS kood1,
                   v_lib.kood2         AS kood2,
                   v_lib.kood3         AS kood3,
                   v_lib.kood4         AS kood4,
                   v_lib.kood5         AS kood5,
                   v_lib.proc_         AS propc_,
                   v_lib.tyyp          AS type,
--                   v_lib.rekvid        AS rekvid,
                   132                 AS rekvid,
                   l_lib_id            AS parentid,
                   v_lib.muud          AS muud
                   INTO v_params;

            SELECT row_to_json(row) INTO json_object
            FROM (SELECT coalesce(lib_id, 0) AS id,
                         TRUE                AS import,
                         v_params            AS data) row;

            SELECT libs.sp_salvesta_dokprop(json_object :: JSON, l_user_id, 132) INTO lib_id;
            RAISE NOTICE 'import dokprop lib_id %, l_count %', lib_id, l_count;

            IF empty(lib_id)
            THEN
                RAISE EXCEPTION 'Dokprop not saved json_object %', json_object;
            END IF;

            -- salvestame log info
            SELECT row_to_json(row) INTO hist_object
            FROM (SELECT now() AS timestamp) row;

/*
            IF log_id IS NULL OR empty(log_id)
            THEN
                INSERT INTO import_log (new_id, old_id, lib_name, params, history)
                VALUES (lib_id, v_lib.id, 'DOKPROP', json_object :: JSON, hist_object :: JSON) RETURNING id
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

 */
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
SELECT import_dokprop(rd.id)
from dokprop rd
inner join library l on rd.parentid= l.id
where l.rekvid= 64

select * from dokprop
limit 10
where library = 'DOK' and rekvid = 64

select d.*
from libs.dokprop d
left outer join libs.library l on d.parentid = l.id
where d.rekvid = 64


select * from libs.library where id = 53
*/

select selg, count(*) as count, max(id) as id, parentid
from libs.dokprop
where rekvid = 64
group by selg, parentid
having count(*) > 1
ORDER BY selg  DESC limit 100

delete from libs.dokprop where id in (495)
and rekvid = 64

select * from libs.library where id = 26