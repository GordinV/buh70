DROP FUNCTION IF EXISTS palk.get_projekt_jaotamine(INTEGER, numeric);

CREATE FUNCTION palk.get_projekt_jaotamine(l_proj_id INTEGER, l_summa numeric)
    RETURNS TABLE
            (
                leping_Id INTEGER,
                proj_id   INTEGER,
                isik      varchar(254),
                amet      varchar(254),
                summa     NUMERIC(14, 2),
                sm        numeric(14, 2),
                selgitus  text
            )
AS
$$
DECLARE
    v_isik             RECORD;
    l_proj_osad        integer;
    v_proj             record;
    v_config           record;
    l_ped_palk_alus    numeric = 1820; -- базовая ЗП
    l_isiku_pohipalk   numeric = l_ped_palk_alus; -- основная ЗП работника
    l_ped_kooli_osa    numeric = 50; -- процент от суммы для школы
    l_ped_lasteaed_osa numeric = 30; -- процент от суммы для садика
    l_dir_osa          numeric = 100; -- процент от суммы для директора
    l_all_juht_osa     numeric = 85; -- процент от суммы для завуча
    l_summa_kokku      numeric = 0;
    l_isiku_summa      numeric = 0;
    l_isiku_sm         numeric = 0;
    l_isiku_osad       numeric = 0; -- кол-во частей для человека, которые попали под проект
    l_selgitus         text; -- пояснения к расчету
    l_arv_summa        numeric = 0;
    l_dir_summa        numeric;
    l_dir_sm           numeric;
    l_alL_juhid_summa  numeric = 0;
    l_alL_juhid_sm     numeric = 0;
    l_puhas_summa      numeric = 0;
    l_sm_summa         numeric = 0;
    l_dir_arvutus      numeric = 0;
    l_params           jsonb;
BEGIN

    -- projekti info

    select
        (p.properties::jsonb ->> 'proj_alates')::date as proj_alates,
        (p.properties::jsonb ->> 'proj_kuni')::date   as proj_kuni,
        p.kood                                        as projekt,
        p.rekvid                                      as rekv_id

    into v_proj
    from
        libs.library p
    where
        id = l_proj_id;

    l_proj_osad = round((v_proj.proj_kuni::date - v_proj.proj_alates::date) / 30, 0);

    -- init
    select
        pc.properties -> 'projekt'                                                                 as proj_config,
        coalesce((pc.properties -> 'projekt' ->> 'ped_palk_alus')::numeric, l_ped_palk_alus)       as ped_palk_alus,
        coalesce((pc.properties -> 'projekt' ->> 'ped_kooli_osa')::numeric, l_ped_kooli_osa)       as ped_kooli_osa,
        coalesce((pc.properties -> 'projekt' ->> 'ped_lasteaed_osa')::numeric, l_ped_lasteaed_osa) as ped_lasteaed_osa,
        coalesce((pc.properties -> 'projekt' ->> 'dir_osa')::numeric, l_dir_osa)                   as dir_osa,
        coalesce((pc.properties -> 'projekt' ->> 'all_juht_osa')::numeric, l_all_juht_osa)         as all_juht_osa,
        pc.sm,
        pc.tka
    into v_config
    from
        palk.palk_config pc
    where
        pc.rekvid = v_proj.rekv_id;

    -- õppetajad

    for v_isik in
        select
            t.id                                     as leping_id,
            t.koormus                                as koormus,
            t.algab                                  as algab,
            coalesce(t.lopp, v_proj.proj_kuni)::date as lopp,
            a.id                                     as isiki_id,
            a.regkood                                as isikukood,
            a.nimetus                                as isik,
            l.kood                                   as amet,
            exists
            (
                select
                    pk.id
                from
                    palk.palk_kaart             pk
                        inner join libs.library l on l.id = pk.libid
                where
                      pk.lepingid = t.id
                  and pk.status <> 3
                  and l.properties::jsonb ->> 'allikas' = '60'
                  and left(l.properties::jsonb ->> 'konto', 5) in ('50026', '50029')
                  and coalesce(l.properties::JSONB ->> 'tegev', '') in ('09212','09213') -- kool
                  and l.properties::JSONB ->> 'proj' is not null
                  and len(ltrim(rtrim(l.properties::JSONB ->> 'proj'))) > 1
--                  and ltrim(rtrim(l.properties::JSONB ->> 'proj')) = ltrim(rtrim(v_proj.projekt))


            )                                        as kas_kooli_oppetaja
        from
            palk.tooleping                   t
                inner join      libs.asutus  a on a.id = t.parentid
                left outer join libs.library l on l.id = t.ametid
        where
              t.rekvid = v_proj.rekv_id
          and t.koormus > 1
          and coalesce(t.lopp, current_date) >= current_date
          and exists
              (
                  select
                      pk.id
                  from
                      palk.palk_kaart             pk
                          inner join libs.library l on l.id = pk.libid
                  where
                        pk.lepingid = t.id
                    and pk.status <> 3
                    and l.properties::jsonb ->> 'allikas' = '60'
                    and left(l.properties::jsonb ->> 'konto', 5) in ('50026', '50029')
                    and l.properties::JSONB ->> 'proj' is not null
                    and len(ltrim(rtrim(l.properties::JSONB ->> 'proj'))) > 1
                  --                   and ltrim(rtrim(l.properties::JSONB ->> 'proj')) = ltrim(rtrim(v_proj.projekt))
              )
        loop
            l_selgitus = '';
            -- ищем ЗП работника
            l_params = jsonb_build_object('rekv_id', v_proj.rekv_id, 'leping_id', null, 'isik_id', v_isik.isiki_id,
                                          'amet_id', null, 'ameti_klassif', array ['HKG', 'HKP','LBV','LMV']::text[]);
            --            l_isiku_pohipalk = palk.get_isiku_pohipalk(l_params::jsonb);

            -- J. Igolkina 07.04.2025
            l_isiku_pohipalk = v_config.ped_palk_alus;

            l_isiku_osad = l_proj_osad;
            --расчет частей проектов для преподователя, если его договор начат раньше или позже проекта
            if v_isik.algab > v_proj.proj_alates or v_isik.lopp < v_proj.proj_kuni then
                l_isiku_osad =
                        round((case when v_isik.lopp < v_proj.proj_kuni then v_isik.lopp else v_proj.proj_kuni end -
                               case
                                   when v_isik.algab > v_proj.proj_alates then v_isik.algab
                                   else v_proj.proj_alates end)::numeric / 30, 0);
            end if;

            -- summa
            l_isiku_summa = (l_isiku_pohipalk * (case
                                                    when v_isik.kas_kooli_oppetaja
                                                        then v_config.ped_kooli_osa
                                                    else v_config.ped_lasteaed_osa end /
                                                100) *
                            0.01 * v_isik.koormus) * l_isiku_osad;

            l_isiku_sm = l_isiku_summa * coalesce((v_config.sm + v_config.tka), (v_config.sm + v_config.tka)) / 100;

            l_summa_kokku = l_summa_kokku + l_isiku_summa + l_isiku_sm;

            l_selgitus = l_isiku_pohipalk::text || '(1820 konstanta ) *' || l_isiku_osad::text || '(Projekti osad) * ' ||
                         v_isik.koormus || '(Koormus %) * ' || case
                                                                   when v_isik.kas_kooli_oppetaja
                                                                       then v_config.ped_kooli_osa
                                                                   else v_config.ped_lasteaed_osa end::text ||
                         '(Õppetaja osa %)';
            return
                query select
                          v_isik.leping_id::integer      as leping_Id,
                          l_proj_id::integer             as proj_id,
                          v_isik.isik ::varchar(254)     as isik,
                          v_isik.amet::varchar(254)      as amet,
                          l_isiku_summa ::numeric(14, 2) as summa,
                          l_isiku_sm ::numeric(14, 2)    as sm,
                          l_selgitus::text               as selgitus;

        end loop;

    -- juhid

    -- eelarve
    l_arv_summa = l_summa - l_summa_kokku; -- jaak
    for v_isik in
        with
            isikud as (
                          select
                              t.id      as leping_id,
                              t.koormus,
                              a.regkood as isikukood,
                              a.nimetus as isik,
                              l.kood    as amet,
                              exists
                              (
                                  select
                                      id
                                  from
                                      palk.tooleping tl
                                  where
                                        t.rekvid = v_proj.rekv_id
                                    and tl.parentid = t.parentid
                                    and coalesce(t.lopp, current_date) >= current_date
                                    and left(coalesce((tl.properties ->> 'ameti_klassif')::varchar(20), ''), 3) in
                                        ('KJ2', 'LJ2')
                              )         AS kas_direktor,
                              exists
                              (
                                  select
                                      id
                                  from
                                      palk.tooleping tl
                                  where
                                        tl.rekvid = v_proj.rekv_id
                                    and tl.parentid = t.parentid
                                    and coalesce(t.lopp, current_date) >= current_date
                                    and left(coalesce((tl.properties ->> 'ameti_klassif')::varchar(20), ''), 3) in
                                        ('KJ1', 'LJ1')
                              )         AS kas_asendaja

                          from
                              palk.tooleping                   t
                                  inner join      libs.asutus  a on a.id = t.parentid
                                  left outer join libs.library l on l.id = t.ametid
                          where
                                t.rekvid = v_proj.rekv_id
                            and coalesce(t.lopp, current_date) >= current_date
                            and exists
                                (
                                    select
                                        pk.id
                                    from
                                        palk.palk_kaart             pk
                                            inner join libs.library l on l.id = pk.libid
                                    where
                                          pk.lepingid = t.id
                                      and pk.status <> 3
                                      and l.properties::jsonb ->> 'allikas' = '60'
                                      and left(l.properties::jsonb ->> 'konto', 5) in ('50021')
                                      and l.properties::JSONB ->> 'proj' is not null
                                      and len(l.properties::JSONB ->> 'proj') > 1
                                      and exists
                                          (
                                              select
                                                  id
                                              from
                                                  palk.tooleping tl
                                              where
                                                    tl.rekvid = v_proj.rekv_id
                                                and tl.parentid = t.parentid
                                                and coalesce(t.lopp, current_date) >= current_date
                                                and left(coalesce((tl.properties ->> 'ameti_klassif')::varchar(20), ''),
                                                         3) in
                                                    ('KJ1', 'KJ2', 'LJ2', 'LJ1')
                                          )
                                )
            )
        select
            (
                select
                    count(*)
                from
                    isikud
                where
                    kas_direktor
            )                as direktor_kokku,
            count(*) over () as juhid_kokku,

            *
        from
            isikud
        loop
            -- summad
            if l_dir_summa is null and v_isik.direktor_kokku > 0 then

                -- доли руководителей
                l_dir_arvutus = ((v_config.dir_osa) * v_isik.direktor_kokku +
                                 (v_config.all_juht_osa) * (v_isik.juhid_kokku - v_isik.direktor_kokku));

                -- доля директора
                l_dir_summa = round(l_arv_summa / l_dir_arvutus *
                                    v_config.dir_osa,
                                    2);

                -- в том числе соц. налог
                l_dir_sm = round(l_dir_summa - l_dir_summa / (1 + (v_config.sm + v_config.tka) * 0.01), 2);

                -- сумма без соцналога
                l_dir_summa = l_dir_summa - l_dir_sm;

                -- всего на замов вкл соц.налог
                if (v_isik.juhid_kokku - v_isik.direktor_kokku) > 0 then
                    -- бюджет замов
                    l_alL_juhid_summa =
                            ((l_arv_summa - (l_dir_summa + l_dir_sm)) / (v_isik.juhid_kokku - v_isik.direktor_kokku));

                    -- соц налог на каждого
                    l_alL_juhid_sm = l_alL_juhid_summa - l_alL_juhid_summa / (1 + (v_config.sm + v_config.tka) * 0.01);

                    -- чистая сумма для замов
                    l_alL_juhid_summa = l_alL_juhid_summa - l_alL_juhid_sm;

                    l_alL_juhid_sm = l_alL_juhid_summa - l_alL_juhid_summa / (1 + (v_config.sm + v_config.tka) * 0.01);
                else
                    l_alL_juhid_summa = 0;
                    l_alL_juhid_sm = 0;
                end if;

                -- расчет каждому из директоров
                l_dir_summa = l_dir_summa / v_isik.direktor_kokku;
            end if;


            if v_isik.kas_direktor then
                l_puhas_summa = l_dir_summa;
                l_sm_summa = l_dir_summa * (v_config.sm + v_config.tka) * 0.01;
            else
                l_puhas_summa = l_alL_juhid_summa;
                l_sm_summa = l_alL_juhid_summa * (v_config.sm + v_config.tka) * 0.01;

            end if;

            l_selgitus = l_dir_summa::text || '(Direktori osa), ' || l_alL_juhid_summa::text || '(All juhid kokku)' ||
                         l_puhas_summa::text || '(Isiku summa)';

            return
                query select
                          v_isik.leping_id::integer      as leping_Id,
                          l_proj_id::integer             as proj_id,
                          v_isik.isik ::varchar(254)     as isik,
                          v_isik.amet::varchar(254)      as amet,
                          l_puhas_summa ::numeric(14, 2) as summa,
                          l_sm_summa ::numeric(14, 2)    as sm,
                          l_selgitus::text               as selgitus;

        end loop;


END;
$$
    LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION palk.get_projekt_jaotamine(INTEGER, numeric ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_projekt_jaotamine(INTEGER, numeric ) TO dbpeakasutaja;

/*
select
    sum(summa) over () as summa_kokku,
    sum(sm) over () as sm_kokku,
    *
from
    palk.get_projekt_jaotamine(282919, 100000)
*/
/*
select * from palk.get_projekt_jaotamine
select * from ou.rekv where nimetus ilike '%paikene%'
-- 89
select * from libs.library where kood  = '24093' and rekvid = 113
kood = '25001'
and rekvid = 89
 */