DROP FUNCTION IF EXISTS import_to_new_asutus_dokprop_arved();

DROP FOREIGN TABLE IF EXISTS remote_palk_asutus;
/*
CREATE FOREIGN TABLE remote_palk_asutus (
    id INTEGER NOT NULL,
    rekvid INTEGER NOT NULL,
    osakondid INTEGER DEFAULT 0 NOT NULL,
    ametid INTEGER DEFAULT 0 NOT NULL,
    kogus NUMERIC(18, 2) DEFAULT 0 NOT NULL,
    vaba NUMERIC(18, 2) DEFAULT 0 NOT NULL,
    palgamaar INTEGER DEFAULT 0 NOT NULL,
    muud TEXT,
    tunnusid BIGINT DEFAULT 0 NOT NULL,
    vanaid INTEGER
    ) SERVER db_narva_ee
    OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'palk_asutus');

*/
CREATE OR REPLACE FUNCTION import_to_new_asutus_dokprop_arved()
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
    l_osakondid INTEGER;
    l_tunnusid  INTEGER;
    l_user_id   INTEGER = (SELECT id
                           FROM ou.userid
                           WHERE rekvid = 132
                             AND kasutaja = 'vlad'
                               LIMIT 1);

    l_dok_id integer = (select id from libs.library where library = 'DOK' and kood = 'ARV');
    v_dokprop RECORD;
BEGIN
    for v_dokprop in
        select * from db.public.dokprop
    RAISE NOTICE 'Import ->ok';

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
SELECT import_to_new_asutus_amet()

select * from libs.library where id = 728093
*/