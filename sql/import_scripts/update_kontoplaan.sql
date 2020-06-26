/*
drop SERVER if exists dbtest_narva_ee CASCADE ;
CREATE SERVER dbtest_narva_ee FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'dbarch.narva.ee', dbname 'narvalv', port '5436');

CREATE USER MAPPING FOR vlad
    SERVER dbtest_narva_ee
    OPTIONS (user 'vlad', password 'Vlad490710');


CREATE FOREIGN TABLE remote2_library (
    id         SERIAL,
    rekvid     INTEGER                                                      NOT NULL,
    kood       CHAR(20)  DEFAULT public.space(1)                            NOT NULL,
    nimetus    CHAR(254) DEFAULT public.space(1)                            NOT NULL,
    library    CHAR(20)  DEFAULT public.space(1)                            NOT NULL,
    muud       TEXT,
    tun1       INTEGER   DEFAULT 0,
    tun2       INTEGER   DEFAULT 0,
    tun3       INTEGER   DEFAULT 0,
    tun4       INTEGER   DEFAULT 0,
    tun5       INTEGER   DEFAULT 0,
    vanaid     INTEGER,
    properties TEXT,
    timestamp  TIMESTAMP DEFAULT ('now'::TEXT)::TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    status     INTEGER   DEFAULT 1                                          NOT NULL
    )
    SERVER dbtest_narva_ee
    OPTIONS (SCHEMA_NAME 'libs', TABLE_NAME 'library');
*/


CREATE OR REPLACE FUNCTION update_kontoplaan()
    RETURNS INTEGER AS
$BODY$
DECLARE
    v_lib    RECORD;
    v_konto  RECORD;
    l_change BOOL;
    l_count  INTEGER = 0;
BEGIN
    -- читаем план
    FOR v_lib IN
        SELECT *
        FROM remote2_library
        WHERE library = 'KONTOD'
--          AND status = 1
        LOOP
            -- проверка на статус
            IF v_lib.status = 3
            THEN
                raise notice 'delete v_lib.konto %', v_lib.kood;
                UPDATE libs.library SET status = v_lib.status WHERE library.library = 'KONTOD' AND kood = v_lib.kood;
            ELSE
                -- правим содержимое счета
                SELECT * INTO v_konto
                FROM libs.library
                WHERE library.library = 'KONTOD' AND kood = v_lib.kood AND status = 1;
                IF (v_konto IS NOT NULL AND upper(v_lib.properties::TEXT) <> upper(coalesce(v_konto.properties::TEXT, '')))
                    OR v_lib.tun1 <> v_konto.tun1
                    OR v_lib.tun2 <> v_konto.tun2
                    OR v_lib.tun3 <> v_konto.tun3
                    OR v_lib.tun4 <> v_konto.tun4
                    OR v_lib.tun5 <> v_konto.tun5
                THEN
                UPDATE libs.library
                SET properties = v_lib.properties,
                    tun1       = v_lib.tun1,
                    tun2       = v_lib.tun2,
                    tun3       = v_lib.tun3,
                    tun4       = v_lib.tun4,
                    tun5       = v_lib.tun5
                WHERE id = v_konto.id;

                    l_change = TRUE;
                    l_count = l_count + 1;
                    RAISE NOTICE 'konto -> %, v_konto-> %, l_change-> %', v_lib, v_konto, l_change;

                ELSE
                    l_change = FALSE;
                END IF;

            END IF;


        END LOOP;
    RETURN l_count;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


SELECT update_kontoplaan()