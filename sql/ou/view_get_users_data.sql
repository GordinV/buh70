DROP VIEW if exists public.view_get_users_data;


CREATE OR REPLACE VIEW public.view_get_users_data AS 
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
    r.nimetus AS asutus,
    rs.a AS allowed_access,
    libs.libs AS allowed_libs
   FROM ou.userid u
     JOIN ou.rekv r ON r.id = u.rekvid
     JOIN ( SELECT u_1.kasutaja,
            array_agg(((('{"id":'::text || u_1.rekvid::text) || ',"nimetus":"'::text) || ltrim(rtrim(rekv.nimetus::text))) || '"}'::text) AS a
           FROM ou.rekv
             JOIN ou.userid u_1 ON u_1.rekvid = rekv.id
          GROUP BY u_1.kasutaja) rs ON rs.kasutaja = u.kasutaja
     JOIN ( SELECT
            array_agg(((((('{"id":'::text || l.id::text) || ',"nimetus":"'::text) || ltrim(rtrim(l.nimetus::text))) || '","lib":"'::text) || ltrim(rtrim(l.library::text))) || '"}'::text) AS libs
           FROM libs.library l
          WHERE l.library = 'DOK'::bpchar
--          GROUP BY l.rekvid
         ) libs ON  libs is not null;

ALTER TABLE public.view_get_users_data
  OWNER TO postgres;



select * from view_get_users_data v 
                 where (v.rekvid = 2 or 2 is null) 
                 and upper(ltrim(rtrim(v.kasutaja))) = upper('vlad') 
                 order by v.last_login desc limit 1

                 