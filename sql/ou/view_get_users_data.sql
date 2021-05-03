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
       r.nimetus                                                          AS asutus,
       CASE WHEN r.muud IS NOT NULL THEN r.muud ELSE r.nimetus END ::TEXT AS asutus_tais,
       rs.a                                                               AS allowed_access,
       libs.libs                                                          AS allowed_libs_old,
       allowed_modules.libs                                               AS allowed_libs,
       r.parentid,
       parent_r.nimetus::TEXT                                             AS parent_asutus,
       u.roles
FROM ou.userid u
         JOIN ou.rekv r ON r.id = u.rekvid AND r.status <> 3 and r.parentid < 999
         LEFT OUTER JOIN ou.rekv parent_r ON parent_r.id = r.parentid
         JOIN (SELECT u_1.kasutaja,
                      array_agg(((('{"id":'::TEXT || u_1.rekvid::TEXT) || ',"nimetus":"'::TEXT) ||
                                 ltrim(rtrim(rekv.nimetus::TEXT))) || '"}'::TEXT) AS a
               FROM ou.rekv rekv
                        JOIN ou.userid u_1 ON u_1.rekvid = rekv.id AND rekv.status <> 3
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
) allowed_modules ON allowed_modules.libs IS NOT NULL
WHERE u.status <> 3
;

ALTER TABLE ou.view_get_users_data
    OWNER TO postgres;

ALTER TABLE ou.view_get_users_data
    OWNER TO postgres;

GRANT ALL ON TABLE ou.view_get_users_data TO dbadmin;
GRANT SELECT ON TABLE ou.view_get_users_data TO dbpeakasutaja;
GRANT SELECT ON TABLE ou.view_get_users_data TO dbkasutaja;
GRANT SELECT ON TABLE ou.view_get_users_data TO dbvaatleja;


/*
select * from ou.view_get_users_data v
                 where (v.rekvid = 3 or 15 is null)
                 and upper(ltrim(rtrim(v.kasutaja))) = upper('vlad')
                 order by v.last_login desc limit 1
*/
