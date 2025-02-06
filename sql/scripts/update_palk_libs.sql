/*
drop table if exists tmp_palk_lib;
create table if not EXISTS tmp_palk_lib (vana_konto varchar(20),  uus_konto varchar(20), nimetus varchar(254));

insert into  tmp_palk_lib(vana_konto, uus_konto, nimetus)
SELECT
    t.f[1]::varchar(20) AS vana_konto
        ,t.f[2]::varchar(20) AS uus_konto
        ,t.f[3]::varchar(254) AS nimetus
FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$vana konto;uus konto;;;
500000 13;500001 13;asendamistasu;nõutav;nõutav
500000 14;500001 14;lisatasu öötöö eest;nõutav;nõutav
500000 15;500001 15;lisatasu riigipühadel töötamise eest;nõutav;nõutav
500000 16;500001 16;lisatasu ületunnitöö eest;nõutav;nõutav
500000 17;500001 17;lisatasu valveaja eest;nõutav;nõutav
500000 18;500001 18;muud lisatasud;nõutav;nõutav
500100 13;500101 13;asendamistasu;nõutav;nõutav
500100 14;500101 14;lisatasu öötöö eest;nõutav;nõutav
500100 15;500101 15;lisatasu riigipühadel töötamise eest;nõutav;nõutav
500100 16;500101 16;lisatasu ületunnitöö eest;nõutav;nõutav
500100 17;500101 17;lisatasu valveaja eest;nõutav;nõutav
500100 18;500101 18;muud lisatasud;nõutav;nõutav
500120 13;500121 13;asendamistasu;nõutav;nõutav
500120 14;500121 14;lisatasu öötöö eest;nõutav;nõutav
500120 15;500121 15;lisatasu riigipühadel töötamise eest;nõutav;nõutav
500120 16;500121 16;lisatasu ületunnitöö eest;nõutav;nõutav
500120 17;500121 17;lisatasu valveaja eest;nõutav;nõutav
500120 18;500121 18;muud lisatasud;nõutav;nõutav
500140 13;500141 13;asendamistasu;nõutav;nõutav
500140 14;500141 14;lisatasu öötöö eest;nõutav;nõutav
500140 15;500141 15;lisatasu riigipühadel töötamise eest;nõutav;nõutav
500140 16;500141 16;lisatasu ületunnitöö eest;nõutav;nõutav
500140 17;500141 17;lisatasu valveaja eest;nõutav;nõutav
500140 18;500141 18;muud lisatasud;nõutav;nõutav
500210 13;500211 13;asendamistasu;nõutav;nõutav
500210 14;500211 14;lisatasu öötöö eest;nõutav;nõutav
500210 15;500211 15;lisatasu riigipühadel töötamise eest;nõutav;nõutav
500210 16;500211 16;lisatasu ületunnitöö eest;nõutav;nõutav
500210 17;500211 17;lisatasu valveaja eest;nõutav;nõutav
500210 18;500211 18;muud lisatasud;nõutav;nõutav
500240 13;500241 13;asendamistasu;nõutav;nõutav
500240 14;500241 14;lisatasu öötöö eest;nõutav;nõutav
500240 15;500241 15;lisatasu riigipühadel töötamise eest;nõutav;nõutav
500240 16;500241 16;lisatasu ületunnitöö eest;nõutav;nõutav
500240 17;500241 17;lisatasu valveaja eest;nõutav;nõutav
500240 18;500241 18;muud lisatasud;nõutav;nõutav
500250 13;500251 13;asendamistasu;nõutav;nõutav
500250 14;500251 14;lisatasu öötöö eest;nõutav;nõutav
500250 15;500251 15;lisatasu riigipühadel töötamise eest;nõutav;nõutav
500250 16;500251 16;lisatasu ületunnitöö eest;nõutav;nõutav
500250 17;500251 17;lisatasu valveaja eest;nõutav;nõutav
500250 18;500251 18;muud lisatasud;nõutav;nõutav
500260 13;500261 13;asendamistasu;nõutav;nõutav
500260 14;500261 14;lisatasu öötöö eest;nõutav;nõutav
500260 15;500261 15;lisatasu riigipühadel töötamise eest;nõutav;nõutav
500260 16;500261 16;lisatasu ületunnitöö eest;nõutav;nõutav
500260 17;500261 17;lisatasu valveaja eest;nõutav;nõutav
500260 18;500261 18;muud lisatasud;nõutav;nõutav
500270 13;500271 13; asendamistasu;nõutav;nõutav
500270 14;500271 14;lisatasu öötöö eest;nõutav;nõutav
500270 15;500271 15;lisatasu riigipühadel töötamise eest;nõutav;nõutav
500270 16;500271 16;lisatasu ületunnitöö eest;nõutav;nõutav
500270 17;500271 17;lisatasu valveaja eest;nõutav;nõutav
500270 18;500271 18;muud lisatasud;nõutav;nõutav
500280 13;500281 13;asendamistasu;nõutav;nõutav
500280 14;500281 14;lisatasu öötöö eest;nõutav;nõutav
500280 15;500281 15;lisatasu riigipühadel töötamise eest;nõutav;nõutav
500280 16;500281 16;lisatasu ületunnitöö eest;nõutav;nõutav
500280 17;500281 17;lisatasu valveaja eest;nõutav;nõutav
500280 18;500281 18;muud lisatasud;nõutav;nõutav
500290 13;500291 13;asendamistasu;nõutav;nõutav
500290 14;500291 14;lisatasu öötöö eest;nõutav;nõutav
500290 15;500291 15;lisatasu riigipühadel töötamise eest;nõutav;nõutav
500290 16;500291 16;lisatasu ületunnitöö eest;nõutav;nõutav
500290 17;500291 17;lisatasu valveaja eest;nõutav;nõutav
500290 18;500291 18;muud lisatasud;nõutav;nõutav
$$, '\n') AS l) t;
*/
DROP FUNCTION IF EXISTS palk.update_palk_lib();

CREATE FUNCTION palk.update_palk_lib()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_pl      RECORD;
    l_count   INTEGER = 0;
    v_nimetus RECORD;
    l_nimetus varchar(254);
BEGIN
    for v_pl in
        select
            REPLACE(vana_konto, ' ', '') as vk,
            REPLACE(uus_konto, ' ', '')  as uk,
            ltrim(rtrim(nimetus))        as nimetus
        from
            tmp_palk_lib
        where
              vana_konto not like 'vana%'
          and uus_konto is not null
        loop
            raise notice 'v_pl.vk %, v_pl.uk %', v_pl.vk, v_pl.uk;
            -- otsime konto
            if exists
            (
                select
                    id
                from
                    libs.library
                where
                      library = 'PALK'
                  AND STATUS < 3
                  and (ltrim(rtrim(properties::jsonb ->> 'konto')) = v_pl.vk
                    or ltrim(rtrim(properties::jsonb ->> 'konto')) = v_pl.uk)
            ) then
                -- update

                -- прежнее название
                for v_nimetus in
                    select
                        id,
                        nimetus
                    from
                        libs.library
                    where
                          library = 'PALK'
                      AND STATUS < 3
                      and (ltrim(rtrim(properties::jsonb ->> 'konto')) = v_pl.vk
                        or ltrim(rtrim(properties::jsonb ->> 'konto')) = v_pl.uk)
                    loop
                        -- otsime origonaal nimetus
                        select
                            changes ->> 'nimetus' as orig_nimetus
                        into l_nimetus
                        from
                            ou.logs
                        where
                              doc_id = v_nimetus.id
                          and changes ->> 'nimetus' is not null
                          and propertis ->> 'table' = 'library'
                          and propertis ->> 'updated'::text like '2025-01-02%'
                        order by id asc
                        limit 1;

                        if l_nimetus is not null and ltrim(rtrim(l_nimetus)) <> ltrim(rtrim(v_nimetus.nimetus)) then
                            update libs.library
                            set
                                nimetus = l_nimetus
                            where
                                id = v_nimetus.id;
                        end if;

                    end loop;

                l_count = l_count + 1;

            end if;

        end loop;

    RETURN l_count;

END;
$$;

SELECT palk.update_palk_lib();

DROP FUNCTION IF EXISTS palk.update_palk_lib();
