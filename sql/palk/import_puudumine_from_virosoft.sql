DROP FUNCTION IF EXISTS palk.sp_import_puudumine_from_virosoft(INTEGER, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION palk.sp_import_puudumine_from_virosoft(IN user_id integer, IN rekv_id integer,
                                                                  IN import_data JSONB,
                                                                  OUT result INTEGER,
                                                                  out error_code integer,
                                                                  OUT error_message TEXT,
                                                                  OUT data JSONB)
    RETURNS RECORD AS
$BODY$

DECLARE
    userName                    record;
    doc_data                    JSON    = import_data ->> 'file';
    doc_file_id                 TEXT    = import_data ->> 'fileId';
    json_object                 jsonb;
    jsonb_params                jsonb;
    l_isik_id                   integer;
    l_Leping_id                 integer;
    v_leping                    record;
    l_alg_kpv                   date;
    l_lopp_kpv                  date;
    l_puudumine_id              integer;
    l_puudumine_pohjus          text;
    l_puudumie_kood             text;
    l_puudumine_liik            text;
    l_paevad                    integer;
    l_arvestatud_paevad         integer;
    l_VM_kpv                    date; -- дата выплаты
    l_koormus                   integer = 8;
    count                       integer = 0;
    SHORT_DATE_FORMAT           TEXT    = 'DD.MM.YY';
    LONG_DATE_FORMAT            TEXT    = 'DD.MM.YYYY';
    v_puudumine                 record;
    v_eelmise_version_puudumine record; -- для проверки на соответствие новой записи со старой
    l_eelmise_json_params       jsonb;
    l_error_message             text;
    L_puudumise_tyyp            TEXT;
    L_eelmise_puudumine_id      INTEGER;
    l_puudumine_nimetus         text; -- наименование кода. для отличия разных видов учебных отпусков
    kas_PH                      boolean = false; -- если код PH найден, то не осуществляем контроль

BEGIN
    data = '[]'::jsonb;
    -- init

    -- check user
    SELECT
        id,
        kasutaja,
        rekvid
    INTO userName
    FROM
        ou.userid u
    WHERE
          u.id = user_id
      and u.rekvid = rekv_id;

    rekv_id = userName.rekvid;

    IF userName.id IS NULL
    THEN
        error_message = 'User not found ';
        error_code = 6;
        result = 0;
        data = data || jsonb_build_object('error_code', error_code, 'error_message', error_message, 'result', result);
        RETURN;
    END IF;


    FOR json_object IN
        SELECT *
        FROM
            json_array_elements(doc_data)
--        where not empty(json_object ->> 'regkood')
        LOOP
            -- init vars
            kas_PH = false;
            l_VM_kpv = null;

            --s var inits
            if empty(coalesce(json_object ->> 'ik', '')) then
                -- пуста строка
                continue ;
            end if;

            if not empty(coalesce(json_object ->> 'regkood', '')) then
                -- указан рег. код
                rekv_id = (
                              select
                                  id
                              from
                                  ou.rekv
                              where
                                  regkood = json_object ->> 'regkood'
                              limit 1
                          );
                user_id = (
                              select id from ou.userid u where u.rekvid = rekv_id and u.kasutaja = userName limit 1
                          );

                if rekv_id is null or user_id is null then
                    error_message = 'User not found: ' || json_object ->> 'regkood';
                    error_code = 6;
                    result = 0;
                    data = data ||
                           jsonb_build_object('error_code', error_code, 'error_message', error_message, 'result',
                                              result);
                    RETURN;
                end if;
            end if;

            -- работник
            l_isik_id = (
                            select
                                id
                            from
                                palk.com_tootajad t
                            where
                                  ltrim(rtrim(t.isikukood))::text = json_object ->> 'ik'
                              and t.rekvid = rekv_id
                            order by id desc
                            limit 1
                        );
            -- lepingud

            for v_leping in
                select
                    t.lepingId as id
                from
                    palk.com_tootajad           t
                        inner join libs.library l on l.id = t.ametid
                where
                      t.id = l_isik_id
--                                and ltrim(rtrim(upper(t.amet))) = ltrim(rtrim(upper(json_object ->> 'amet')))
                  and upper(ltrim(rtrim(l.nimetus))) = upper(ltrim(rtrim(json_object ->> 'amet')))
                  and (t.lopp is null
                    or t.lopp >= get_date_from_string((json_object ->> 'lopp_kpv'), (case
                                                                                        when len(ltrim(rtrim(json_object ->> 'lopp_kpv'))) = 10
                                                                                            then LONG_DATE_FORMAT
                                                                                        else SHORT_DATE_FORMAT END))
                          )
                loop

                    select
                        get_date_from_string((json_object ->> 'alg_kpv'), (case
                                                                               when len(ltrim(rtrim(json_object ->> 'alg_kpv'))) = 10
                                                                                   then LONG_DATE_FORMAT
                                                                               else SHORT_DATE_FORMAT END))::date  as alg_kpv,
                        get_date_from_string((json_object ->> 'lopp_kpv'), (case
                                                                                when len(ltrim(rtrim(json_object ->> 'lopp_kpv'))) = 10
                                                                                    then LONG_DATE_FORMAT
                                                                                else SHORT_DATE_FORMAT END))::date as lopp_kpv,
                        json_object ->> 'PuhkuseLiik'                                                              as puhkus_liik,
                        json_object ->> 'PuudumiseKood'                                                            as puudumise_kood,
                        coalesce((json_object ->> 'paevad')::integer, 0)::integer                                  as paevad
                    into l_alg_kpv, l_lopp_kpv, l_puudumine_liik, l_puudumie_kood, l_paevad;

                    -- проверим на дату выплаты (вносится руками перед импортом)
                    if len(coalesce(json_object ->> 'VM', '')::text) >= 8 then
                        l_VM_kpv = get_date_from_string((json_object ->> 'VM'), (case
                                                                                     when len(ltrim(rtrim(json_object ->> 'VM'))) >= 10
                                                                                         then LONG_DATE_FORMAT
                                                                                     else SHORT_DATE_FORMAT END))::date;
                    end if;

                    if l_isik_id is null or v_Leping.id is null then
                        error_message = 'Vead failis';
                        error_code = 6;
                        result = 0;

                        data = data || jsonb_build_object('error_code', error_code, 'error_message',
                                                          ('Isik:' || (json_object ->> 'isik') || ', Amet:' ||
                                                           (json_object ->> 'amet') ||
                                                           '-> Puudub isik või vale IK või vale ameti kood'),
                                                          'result', result, 'Isik', json_object ->> 'isik', 'amet',
                                                          json_object ->> 'amet');
                        continue;
                    end if;

                    if l_alg_kpv is null or l_lopp_kpv is null then
                        error_message = 'Vead failis';
                        error_code = 6;
                        result = 0;
                        data = data ||
                               jsonb_build_object('error_code', error_code, 'error_message', 'Puudub või vale period',
                                                  'result', result, 'Isik', json_object ->> 'isik', 'amet',
                                                  (json_object ->> 'amet'));
                        continue;
                    end if;

                    -- ПЕРВИЧНАЯ ИЛИ ПОСЛЕДУЮЩЕЕ
                    L_puudumise_tyyp = json_object ->> 'haiguslehe_tyyp';
                    l_puudumine_nimetus = coalesce(json_object ->> 'puudumise_liik', '');

                    -- сохраняем
                    l_puudumine_id = coalesce((
                                                  select
                                                      id
                                                  from
                                                      palk.puudumine p
                                                  where
                                                        p.lepingid = v_Leping.id
                                                    and p.kpv1 = l_alg_kpv
                                                    and p.kpv2 = l_lopp_kpv
                                                    and p.status = 'active'
                                                  limit 1
                                              ), 0);

                    -- проверми на код PH
                    if coalesce(l_puudumine_id, 0) = 0 and l_puudumie_kood in ('H') and exists
                    (
                        with
                            puudumised as (
                                              select
                                                  p.id,
                                                  case
                                                      when p.properties ->> 'puudumiste_kood' is null
                                                          then array_to_string(tyyp.vs_kooded, ',')
                                                      else p.properties ->> 'puudumiste_kood'
                                                      end::varchar(10) as puudumiste_kood
                                              from
                                                  palk.puudumine                          p
                                                      INNER JOIN palk.com_puudumiste_tyyp tyyp
                                                                 ON tyyp.liik = p.puudumiste_liik AND p.tyyp = tyyp.id
                                              where
                                                    p.lepingid = v_Leping.id
                                                and (p.kpv1 = l_alg_kpv or p.kpv2 = l_lopp_kpv)
                                                and p.status = 'active'
                            )
                        select
                            id
                        from
                            puudumised p
                        where
                            p.puudumiste_kood like '%PH%'
                        limit 1

                    ) then
                        -- это извещение о больничном, которое надо поправить на больничный. Разрещаем перезапись
                        l_puudumine_id = (
                                             with
                                                 puudumised as (
                                                                   select
                                                                       p.id,
                                                                       case
                                                                           when p.properties ->> 'puudumiste_kood' is null
                                                                               then array_to_string(tyyp.vs_kooded, ',')
                                                                           else p.properties ->> 'puudumiste_kood'
                                                                           end::varchar(10) as puudumiste_kood
                                                                   from
                                                                       palk.puudumine                          p
                                                                           INNER JOIN palk.com_puudumiste_tyyp tyyp
                                                                                      ON tyyp.liik = p.puudumiste_liik AND p.tyyp = tyyp.id
                                                                   where
                                                                         p.lepingid = v_Leping.id
                                                                     and (p.kpv1 = l_alg_kpv or p.kpv2 = l_lopp_kpv)
                                                                     and p.status = 'active'
                                                 )
                                             select
                                                 p.id
                                             from
                                                 puudumised p
                                             where
                                                 p.puudumiste_kood like '%PH%'
                                             limit 1
                                         );
                        -- пропустим контроль, если на эти даты приходится извещение о больничном
                        kas_PH = true;
                    end if;

                    -- проверка на наличие отсутствия в периоде
                    if not kas_PH and exists
                    (
                        select
                            id
                        from
                            palk.puudumine p
                        where
                              lepingid = v_Leping.id
                          and (l_alg_kpv::date, l_lopp_kpv::date) OVERLAPS (p.kpv1::date, p.kpv2::date)
                          and coalesce(l_puudumine_id, 0) <> p.id
                          and p.status <> 'deleted'

                    ) then
                        error_message = 'Vead failis';
                        error_code = 6;
                        result = 0;
                        l_error_message =
                                'Isik:' || coalesce(json_object ->> 'isik', '') || ', amet:' ||
                                (json_object ->> 'amet') ||
                                ',selles ajavahemikus töötaja juba puudub';
                        data = data || jsonb_build_object('error_code', error_code,
                                                          'error_message', l_error_message,
                                                          'result', result, 'Isik', json_object ->> 'isik', 'amet',
                                                          (json_object ->> 'amet'));
                        continue;

                    end if;


                    select
                        liik,
                        id
                    into v_puudumine
                    from
                        palk.com_puudumiste_tyyp pt
                    where
                        vs_kooded @> array [l_puudumie_kood];

                    -- проверим на тип учебного отпуска
                    if l_puudumie_kood = 'ÕP' then
                        v_puudumine.id = case
                                             when l_puudumine_nimetus ilike '%keskmise%'
                                                 then 5 -- Õppepuhkus (keskmine)
                                             when l_puudumine_nimetus ilike '%alammäär%'
                                                 then 50 -- Õppepuhkus (alammäär)
                                             else 51 -- Õppepuhkus (tasutamata)
                            end;
                    end if;


                    -- расчетные дни
                    l_arvestatud_paevad = case
                                              when (json_object ->> 'arvestatud_paevad')::text = '' then null::text
                                              else (json_object ->> 'arvestatud_paevad')::text end::integer;
                    --(json_object ->> 'arvestatud_paevad')::integer;

                    -- календарные дни
                    l_paevad = (json_object ->> 'paevad')::integer;

                    if v_puudumine.liik is null then
                        raise exception 'Viga: vale puudumise kood %',l_puudumie_kood;
                    end if;

                    jsonb_params =
                            jsonb_build_object('id', l_puudumine_id,
                                               'kpv1', l_alg_kpv,
                                               'kpv2', l_lopp_kpv,
                                               'lepingid', v_Leping.id,
                                               'puudumiste_liik', v_puudumine.liik,
                                               'tyyp', v_puudumine.id,
                                               'paevad', l_paevad,
                                               'arvestatud_paevad', l_arvestatud_paevad,
                                               'parentid', l_isik_id,
                                               'summa', 0.0000::numeric,
                                               'puudumiste_kood', l_puudumie_kood,
                                               'puudumise_tyyp', L_puudumise_tyyp,
                                               'vm_kpv', l_VM_kpv,
                                               'muud', 'Import (Virosoft),' || 'puudumise kood:' || l_puudumie_kood ||
                                                       ', puudumise liik:' || l_puudumine_nimetus
                            );


                    if coalesce(l_paevad, 0) = 0 then

                        -- koormus (tunnid)
                        l_koormus = (
                                        select
                                            toopaev
                                        from
                                            palk.tooleping t
                                        where
                                            id = v_Leping.id
                                        limit 1
                                    );

                        jsonb_params = jsonb_build_object('alg_kpv', l_alg_kpv, 'lopp_kpv', l_lopp_kpv,
                                                          'lepingid', v_Leping.id, 'toograf', 1,
                                                          'kuu', month(l_lopp_kpv), 'aasta', year(l_lopp_kpv));
                        l_paevad = (
                                       select
                                           t.result
                                       from
                                           palk.get_taabel2(jsonb_params::JSONB) t
                                   ) / coalesce(l_koormus, 8);

                    end if;

                    -- проверяем на идентичность данных
                    if coalesce(l_puudumine_id, 0) > 0 then
                        select
                            id,
                            kpv1,
                            kpv2,
                            lepingid,
                            puudumiste_liik,
                            tyyp,
                            paevad,
                            (p.properties ->> 'arvestatud_paevad')::integer as arvestatud_paevad,
                            summa,
                            l_isik_id                                       as parentid,
                            p.properties ->> 'puudumiste_kood'              as puudumiste_kood,
                            (p.properties ->> 'puudumise_tyyp')             as puudumise_tyyp,
                            p.muud                                          as muud
                        into v_eelmise_version_puudumine
                        from
                            palk.puudumine p
                        where
                            id = l_puudumine_id;

                        l_eelmise_json_params = to_jsonb(v_eelmise_version_puudumine);

                        if l_eelmise_json_params = jsonb_params then
                            -- записи идентичны, не нужно сохранять
                            error_message = 'OK';
                            error_code = 0;
                            result = 0;
                            l_error_message =
                                    'Isik:' || coalesce(json_object ->> 'isik', '') || ', amet:' ||
                                    (json_object ->> 'amet') ||
                                    ',Parandused ei ole.';
                            data = data || jsonb_build_object('error_code', error_code,
                                                              'error_message', l_error_message,
                                                              'result', result, 'Isik', json_object ->> 'isik', 'amet',
                                                              (json_object ->> 'amet'));
                            continue;
                        end if;

                    end if;


                    jsonb_params = jsonb_build_object('id', l_puudumine_id, 'data', jsonb_params);

                    l_puudumine_id = palk.sp_salvesta_puudumine(jsonb_params::json, user_id, rekv_id);

-- результат
                    error_message = '';
                    error_code = 0;
                    result = l_puudumine_id;
                    data = data ||
                           jsonb_build_object('error_code', error_code,
                                              'error_message',
                                              ('Isik:' || (json_object ->> 'isik') || ', Amet:' ||
                                               (json_object ->> 'amet') ||
                                               ',Puudumine importeeritud'),
                                              'result', result,
                                              'Isik', (json_object ->> 'isik'),
                                              'amet', (json_object ->> 'amet'));

                end loop; -- v_leping
            count = count + 1;
        END LOOP; -- import tabel

    IF count > 0
    THEN
        -- успешно, сохраняем ид файла
        INSERT INTO ou.paringud (user_id, sql, params, tulemused, changes)
        VALUES
            (user_id, 'docs.sp_import_puudumine_from_virosoft', import_data, jsonb_build_object('result', count),
             jsonb_build_object('fileId', doc_file_id));

    END IF;

    result = count;
    RETURN;


END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.sp_import_puudumine_from_virosoft (INTEGER, INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_import_puudumine_from_virosoft (INTEGER, INTEGER, JSONB) TO dbpeakasutaja;


/*
SELECT *
FROM
    jsonb_to_recordset((
                           SELECT
                               p.data
                           from
                               palk.sp_import_puudumine_from_virosoft(4711::integer, 3::integer, '	{
	"userId":"c420624c886383a25465ed84699362271647709f",
	"fileId":"61571",
	"file":[{"Registrikood":"75024411","ik":"49311173728","isik":"Sokolova Lina ","amet":"abiõpetaja alushariduse alal",
"Maksta koos palgaga":"0","PuudumiseKood":"LPA","puudumise_liik":"AÜ lapse lisapuhkus","alg_kpv":"30.01.2026","lopp_kpv":"30.01.2026","paevad":"1","Tunnid":"","haiguslehe_tyyp":"","arvestatud_paevad":"1"}]
	}'::JSONB) p
                       )
    )
        AS x (error_message TEXT, error_code INTEGER, result INTEGER)


*/