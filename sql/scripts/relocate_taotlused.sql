/*
drop table if exists tmp_lib;
create table if not EXISTS tmp_lib (id integer, asutus text);

insert into  tmp_lib(id, asutus)
SELECT
    t.f[1]::integer AS id
    ,t.f[2]::text AS asutus
FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$6807000;0860001 Kultuuriosakond
6807086;0860001 Kultuuriosakond
6807003;0911027 Narva Lasteaed Pongerjas
6807003;0911027 Narva Lasteaed Pongerjas
6807003;0911027 Narva Lasteaed Pongerjas
6807003;0911027 Narva Lasteaed Pongerjas
6807089;0911027 Narva Lasteaed Pongerjas
6807089;0911027 Narva Lasteaed Pongerjas
6807089;0911027 Narva Lasteaed Pongerjas
6807089;0911027 Narva Lasteaed Pongerjas
6807089;0911027 Narva Lasteaed Pongerjas
6807089;0911027 Narva Lasteaed Pongerjas
6806988;0911032 Narva Lasteaed Sademeke
6806988;0911032 Narva Lasteaed Sademeke
6807074;0911032 Narva Lasteaed Sademeke
6807074;0911032 Narva Lasteaed Sademeke
6807074;0911032 Narva Lasteaed Sademeke
6807074;0911032 Narva Lasteaed Sademeke
6807074;0911032 Narva Lasteaed Sademeke
6807008;0860001 Kultuuriosakond
6807008;0860001 Kultuuriosakond
6807008;0921201 Narva Kesklinna Kool
6806990;0860001 Kultuuriosakond
6806990;0860001 Kultuuriosakond
6806990;0860001 Kultuuriosakond
6806990;0860001 Kultuuriosakond
6807076;0860001 Kultuuriosakond
6807076;0860001 Kultuuriosakond
6807076;0860001 Kultuuriosakond$$, '\n') AS l) t;
*/
DROP FUNCTION IF EXISTS relocate_taotlused;

CREATE FUNCTION relocate_taotlused()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_taotlus record;
    v_doc     record;
    l_count   INTEGER = 0;
    l_json    jsonb   = '[]';
    l_user_id integer;
    l_rekv_id integer;
    l_doc_id  integer;
BEGIN
    for v_taotlus in
        select id, left(replace(asutus,'/r/n',''),10) as asutus from tmp_lib where id is not null
        loop
            raise notice 'v_taotlus.id %',v_taotlus.id;
            select
                t.*,
                (
                    select kasutaja
                    from ou.userid
                    where id = t.koostajaid
                ) as kasutaja
            into v_doc
            from
                eelarve.taotlus t
            where
                parentid = v_taotlus.id;

            l_rekv_id = (
                            select id from ou.rekv where nimetus ilike ltrim(rtrim(v_taotlus.asutus)) || '%' limit 1
                        );
            l_user_id = (
                            select id from ou.userid where rekvid = l_rekv_id and kasutaja = v_doc.kasutaja limit 1
                        );

            raise notice 'l_rekv_id %, l_user_id %, v_doc.kasutaja %, asutus %',l_rekv_id, l_user_id, v_doc.kasutaja, ltrim(rtrim(v_taotlus.asutus)) || '%';

            if l_rekv_id is null or l_user_id is null then
                raise exception 'Puudub kasutaja voi asutus l_rekv_id %, l_user_id %', l_rekv_id, l_user_id;
            end if;


--            update docs.doc set rekvid = l_rekv_id where id = v_taotlus.id;
            update eelarve.taotlus
            set
                rekvid = l_rekv_id
            where
                parentid = v_taotlus.id;

/*            update eelarve.taotlus
            set
                koostajaid = l_user_id,
                rekvid = l_rekv_id,
                number     = (
                                 SELECT
                                     docs.sp_get_number(l_rekv_id::INTEGER, 'TAOTLUS'::TEXT,
                                                        year(v_doc.kpv)::INTEGER, NULL)
                )
            where
                parentid = v_taotlus.id;
*/

        end loop;
    raise notice 'kokku l_count %', l_count;

    RETURN l_count;

END;
$$;

SELECT relocate_taotlused();

DROP FUNCTION IF EXISTS relocate_taotlused;
--DROP TABLE IF EXISTS tmp_viitenr;
/*
 select trim(replace(vn,E'\n',''),'"'), vn, ik, asutus from tmp_viitenr_kustuta

SELECT id FROM ou.rekv WHERE left(nimetus, 10) = left(trim('"0911027 Narva Lasteaed Pongerjas T"','"'), 10) LIMIT 1

          FROM lapsed.viitenr
            WHERE isikukood = v_vn.ik
              AND rekv_id = l_rekv_id
              AND viitenumber = trim(replace(v_vn.vn,E'\n',''),'"');

select * from tmp_viitenr_kustuta
 where vn = '9366554'

 */
