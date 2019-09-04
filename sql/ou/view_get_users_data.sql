DROP VIEW IF EXISTS public.view_get_users_data;
DROP VIEW IF EXISTS ou.view_get_users_data;

CREATE OR REPLACE VIEW ou.view_get_users_data AS
SELECT u.id,
       u.rekvid,
       u.kasutaja,
       u.ametnik,
       u.parool,
       u.kasutaja_,
       u.peakasutaja_,
       u.admin,
       u.muud,
       u.last_login,
       r.nimetus            AS asutus,
       rs.a                 AS allowed_access,
       libs.libs            AS allowed_libs_old,
       allowed_modules.libs AS allowed_libs

FROM ou.userid u
         JOIN ou.rekv r ON r.id = u.rekvid
         JOIN (SELECT u_1.kasutaja,
                      array_agg(((('{"id":'::TEXT || u_1.rekvid::TEXT) || ',"nimetus":"'::TEXT) ||
                                 ltrim(rtrim(rekv.nimetus::TEXT))) || '"}'::TEXT) AS a
               FROM ou.rekv
                        JOIN ou.userid u_1 ON u_1.rekvid = rekv.id
               GROUP BY u_1.kasutaja) rs ON rs.kasutaja = u.kasutaja
         JOIN (SELECT array_agg(((((('{"id":'::TEXT || l.id::TEXT) || ',"nimetus":"'::TEXT) ||
                                   ltrim(rtrim(l.nimetus::TEXT))) || '","lib":"'::TEXT) ||
                                 ltrim(rtrim(l.library::TEXT))) || '"}'::TEXT) AS libs
               FROM libs.library l
               WHERE l.library = 'DOK'::BPCHAR
--          GROUP BY l.rekvid
) libs ON libs.libs IS NOT NULL
         JOIN (
    SELECT json_agg(lib.*) AS libs
    FROM (
             SELECT id,
                    kood::TEXT,
                    nimetus::TEXT,
                    library::TEXT                          AS lib,
                    (properties::JSONB -> 'module')::JSONB AS module
             FROM libs.library l
             WHERE l.library = 'DOK'
               AND status <> 3
         ) lib
) allowed_modules ON allowed_modules.libs IS NOT NULL;

ALTER TABLE ou.view_get_users_data
    OWNER TO postgres;

ALTER TABLE ou.view_get_users_data
    OWNER TO postgres;

GRANT ALL ON TABLE ou.view_get_users_data TO dbadmin;
GRANT SELECT ON TABLE ou.view_get_users_data TO dbpeakasutaja;
GRANT SELECT ON TABLE ou.view_get_users_data TO dbkasutaja;


/*
select * from ou.view_get_users_data v
                 where (v.rekvid = 2 or 2 is null) 
                 and upper(ltrim(rtrim(v.kasutaja))) = upper('vlad') 
                 order by v.last_login desc limit 1
*/
                 