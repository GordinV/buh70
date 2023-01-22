/*
drop table if exists tmp_arved;
create table if not EXISTS tmp_arved (number text, tunnus text, asutus text);

insert into  tmp_arved (number, tunnus, asutus)
SELECT
    t.f[1] AS number
        ,t.f[2]::text AS tunnus
        ,t.f[3]::text AS asutus
FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$4862;0810202 Narva Spordikeskus
8063;0820201 Kultuurimaja Rugodiv
8063;0820201 Kultuurimaja Rugodiv
5;0820201 Kultuurimaja Rugodiv
4849;0810202 Narva Spordikeskus
4849;0810202 Narva Spordikeskus
72;0810203 Narva Paemurru Spordikool
72;0810203 Narva Paemurru Spordikool
79;0810203 Narva Paemurru Spordikool
4859;0810202 Narva Spordikeskus
4859;0810202 Narva Spordikeskus
4859;0810202 Narva Spordikeskus
4859;0810202 Narva Spordikeskus
4859;0810202 Narva Spordikeskus
76;0810203 Narva Paemurru Spordikool
77;0810203 Narva Paemurru Spordikool
77;0810203 Narva Paemurru Spordikool
81;0810203 Narva Paemurru Spordikool
81;0810203 Narva Paemurru Spordikool
4855;0810202 Narva Spordikeskus
4861;0810202 Narva Spordikeskus
4861;0810202 Narva Spordikeskus
4861;0810202 Narva Spordikeskus
4861;0810202 Narva Spordikeskus
4866;0810202 Narva Spordikeskus
4851;0810202 Narva Spordikeskus
4851;0810202 Narva Spordikeskus
4851;0810202 Narva Spordikeskus
4853;0810202 Narva Spordikeskus
4853;0810202 Narva Spordikeskus
4853;0810202 Narva Spordikeskus
4856;0810202 Narva Spordikeskus
4856;0810202 Narva Spordikeskus
4856;0810202 Narva Spordikeskus
4857;0810202 Narva Spordikeskus
4857;0810202 Narva Spordikeskus
4857;0810202 Narva Spordikeskus
78;0810203 Narva Paemurru Spordikool
80;0810203 Narva Paemurru Spordikool
4847;0810202 Narva Spordikeskus
4848;0810202 Narva Spordikeskus
4848;0810202 Narva Spordikeskus
4854;0810202 Narva Spordikeskus
4854;0810202 Narva Spordikeskus
4850;0810202 Narva Spordikeskus
4850;0810202 Narva Spordikeskus
4865;0810202 Narva Spordikeskus
75;0810203 Narva Paemurru Spordikool
9061;0820201 Kultuurimaja Rugodiv
4852;0810202 Narva Spordikeskus
4852;0810202 Narva Spordikeskus
4852;0810202 Narva Spordikeskus
4867;0810202 Narva Spordikeskus
4873;0810202 Narva Spordikeskus
4873;0810202 Narva Spordikeskus
4873;0810202 Narva Spordikeskus
4873;0810202 Narva Spordikeskus
4873;0810202 Narva Spordikeskus
4873;0810202 Narva Spordikeskus
74;0810203 Narva Paemurru Spordikool
74;0810203 Narva Paemurru Spordikool
74;0810203 Narva Paemurru Spordikool
74;0810203 Narva Paemurru Spordikool
25309;0921214 Narva Keeltelutseum
4860;0810202 Narva Spordikeskus
4860;0810202 Narva Spordikeskus
4864;0810202 Narva Spordikeskus
4864;0810202 Narva Spordikeskus
12935;0951004 Narva Muusikakool
12935;0951004 Narva Muusikakool
73;0810203 Narva Paemurru Spordikool
73;0810203 Narva Paemurru Spordikool
6;0820201 Kultuurimaja Rugodiv
6;0820201 Kultuurimaja Rugodiv
9;0820201 Kultuurimaja Rugodiv
7;0820201 Kultuurimaja Rugodiv
7;0820201 Kultuurimaja Rugodiv
88;0810203 Narva Paemurru Spordikool
8;0820201 Kultuurimaja Rugodiv
8;0820201 Kultuurimaja Rugodiv
87;0810203 Narva Paemurru Spordikool
76;0810202 Narva Spordikeskus
58;0820201 Kultuurimaja Rugodiv
58;0820201 Kultuurimaja Rugodiv
79;0810202 Narva Spordikeskus
59;0820201 Kultuurimaja Rugodiv
59;0820201 Kultuurimaja Rugodiv
77;0810202 Narva Spordikeskus
78;0810202 Narva Spordikeskus
80;0810202 Narva Spordikeskus
60;0820201 Kultuurimaja Rugodiv
60;0820201 Kultuurimaja Rugodiv
469;0820201 Kultuurimaja Rugodiv
469;0820201 Kultuurimaja Rugodiv
468;0820201 Kultuurimaja Rugodiv
468;0820201 Kultuurimaja Rugodiv
93;0810202 Narva Spordikeskus
93;0810202 Narva Spordikeskus
93;0810202 Narva Spordikeskus
$$, '\n') AS l) t;
*/
DROP FUNCTION IF EXISTS paranda_lausend_arv();

CREATE FUNCTION paranda_lausend_arv()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_arv    RECORD;
    l_rekvid INTEGER;
    l_tunnus TEXT;
    tmp_arv  RECORD;
BEGIN
    FOR v_arv IN
        SELECT *
        FROM tmp_arved
        WHERE tunnus IS NOT NULL
        LOOP

            l_tunnus = left(v_arv.tunnus, 7);
            RAISE NOTICE 'l_tunnus %', l_tunnus;

            l_rekvid = (SELECT id
                        FROM ou.rekv
                        WHERE nimetus::TEXT LIKE left(replace(v_arv.tunnus, E'\r', ''), 7) || '%'
                          AND (parentid = 119 OR id = 119)
                        LIMIT 1);

            RAISE NOTICE 'l_rekvid %, v_arv.tunnus %, l_tunnus %', l_rekvid, v_arv.tunnus, l_tunnus;

            SELECT parentid, userid
            INTO tmp_arv
            FROM docs.arv
            WHERE journalid IN (SELECT id
                                FROM cur_journal
                                WHERE number::TEXT = v_arv.number::TEXT
                                  AND kpv >= '2022-12-10'
                                  AND rekvid = l_rekvid
            )
              AND rekvid = l_rekvid;

            RAISE NOTICE 'arv_id %, user_id %', tmp_arv.parentid, tmp_arv.userid;

            PERFORM docs.gen_lausend_arv(tmp_arv.parentid, tmp_arv.userid);

        END LOOP;

    RETURN 0;

END;
$$;

SELECT paranda_lausend_arv();

--DROP FUNCTION IF EXISTS paranda_lausend_arv();


