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
    userName           record;
    doc_data           JSON    = import_data ->> 'file';
    doc_file_id        TEXT    = import_data ->> 'fileId';
    json_object        jsonb;
    jsonb_params       jsonb;
    l_isik_id          integer;
    l_Leping_id        integer;
    l_alg_kpv          date;
    l_lopp_kpv         date;
    l_puudumine_id     integer;
    l_puudumine_pohjus text;
    l_puudumie_kood    text;
    l_puudumine_liik   text;
    l_paevad           integer;
    l_koormus          integer = 8;
    count              integer = 0;
    SHORT_DATE_FORMAT  TEXT    = 'DD.MM.YY';
    LONG_DATE_FORMAT   TEXT    = 'DD.MM.YYYY';
    v_puudumine        record;
BEGIN
    data = '[]'::jsonb;
    -- init

    -- check user
    SELECT id, kasutaja, rekvid
    INTO userName
    FROM ou.userid u
    WHERE u.id = user_id
      and u.rekvid = rekv_id;

    raise notice 'start %', userName;

    rekv_id = userName.rekvid;

    IF userName.id  IS NULL
    THEN
        error_message = 'User not found ';
        error_code = 6;
        result = 0;
        data = data || jsonb_build_object('error_code', error_code, 'error_message', error_message, 'result', result);
        RETURN;
    END IF;

/*    -- Контроль уникальности файла
    IF doc_file_id IS NULL OR empty(doc_file_id) OR
       exists
       (
           SELECT id
           FROM ou.paringud
           WHERE changes ->> 'fileId' = doc_file_id
       )
    THEN
        RAISE EXCEPTION 'Viga, vale fileId või fail juba impoteeritud % ',doc_file_id;
    END IF;
*/
    FOR json_object IN
        SELECT *
        FROM
            json_array_elements(doc_data)
        LOOP
            --s var inits
            if empty(coalesce(json_object ->> 'ik', '')) then
                -- пуста строка
                continue ;
            end if;

            if not empty(coalesce(json_object ->> 'regkood', '')) then
                -- указан рег. код
                rekv_id = (select id
                           from ou.rekv
                           where regkood = json_object ->> 'regkood'
                           limit 1);
                user_id = (select id from ou.userid u where u.rekvid = rekv_id and u.kasutaja = userName limit 1);

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

raise notice 'rekv_id %, ik %, json % ',rekv_id, json_object ->> 'ik', json_object;
            -- работник
            l_isik_id = (select id
                         from palk.com_tootajad t
                         where ltrim(rtrim(t.isikukood))::text = json_object ->> 'ik'
                           and t.rekvid = rekv_id
                         order by id desc
                         limit 1);
            -- leping

            l_Leping_id = (select t.lepingId
                           from palk.com_tootajad t
                                    inner join libs.library l on l.id = t.ametid
                           where t.id = l_isik_id
--                                and ltrim(rtrim(upper(t.amet))) = ltrim(rtrim(upper(json_object ->> 'amet')))
                             and upper(ltrim(rtrim(l.nimetus))) = upper(ltrim(rtrim(json_object ->> 'amet')))

                           order by t.lepingid desc
                           limit 1);

            raise notice 'l_isik_id %, l_Leping_id %, amet %', l_isik_id, l_Leping_id , upper(ltrim(rtrim(json_object ->> 'amet')));


            select get_date_from_string((json_object ->> 'alg_kpv'), (case
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

            if l_isik_id is null or l_Leping_id is null then
                error_message = 'Vead failis';
                error_code = 6;
                result = 0;
                data = data || jsonb_build_object('error_code', error_code, 'error_message',
                                                  ('IK:' || (json_object ->> 'ik') || ', Amet:' ||
                                                   (json_object ->> 'amet') ||
                                                   '-> Puudub isik või vale IK või vale ameti kood'),
                                                  'result', result, 'IK', json_object ->> 'ik', 'amet',
                                                  json_object ->> 'amet');
                continue;
            end if;

            if l_alg_kpv is null or l_lopp_kpv is null then
                error_message = 'Vead failis';
                error_code = 6;
                result = 0;
                data = data || jsonb_build_object('error_code', error_code, 'error_message', 'Puudub või vale period',
                                                  'result', result, 'IK', json_object ->> 'ik', 'amet',
                                                  (json_object ->> 'amet'));
                continue;
            end if;

            -- сохраняем
            l_puudumine_id = coalesce((select id
                                       from palk.puudumine p
                                       where p.lepingid = l_Leping_id
                                         and p.kpv1 = l_alg_kpv
                                         and p.kpv2 = l_lopp_kpv
                                         and p.status = 'active'
                                       limit 1), 0);

            select liik, id
            into v_puudumine
            from palk.com_puudumiste_tyyp pt
            where vs_kooded @> array [l_puudumie_kood];


            if coalesce(l_paevad, 0) = 0 then

                -- koormus (tunnid)
                l_koormus = (select toopaev
                             from palk.tooleping t
                             where id = l_Leping_id
                             limit 1);

                jsonb_params = jsonb_build_object('alg_kpv', l_alg_kpv, 'lopp_kpv', l_lopp_kpv,
                                                  'lepingid', l_Leping_id, 'toograf', 1,
                                                  'kuu', month(l_lopp_kpv), 'aasta', year(l_lopp_kpv));
                l_paevad = (select t.result
                            from palk.get_taabel2(jsonb_params::JSONB) t) / coalesce(l_koormus, 8);

            end if;

            jsonb_params =
                    jsonb_build_object('id', l_puudumine_id,
                                       'kpv1', l_alg_kpv,
                                       'kpv2', l_lopp_kpv,
                                       'lepingid', l_Leping_id,
                                       'puudumiste_liik', v_puudumine.liik,
                                       'tyyp', v_puudumine.id,
                                       'paevad', l_paevad,
                                       'parentid', l_isik_id,
                                       'summa', 0,
                                       'muud', 'Import (Virosoft)');

            jsonb_params = jsonb_build_object('id', l_puudumine_id, 'data', jsonb_params);

            l_puudumine_id = palk.sp_salvesta_puudumine(jsonb_params::json, user_id, rekv_id);
            raise notice 'l_puudumine_id %',l_puudumine_id;

-- результат
            error_message = '';
            error_code = 0;
            result = l_puudumine_id;
            data = data ||
                   jsonb_build_object('error_code', error_code,
                                      'error_message',
                                      ('IK:' || (json_object ->> 'ik') || ', Amet:' || (json_object ->> 'amet') ||
                                       ',Puudumine importeeritud'),
                                      'result', result,
                                      'IK', (json_object ->> 'ik'),
                                      'amet', (json_object ->> 'amet'));

            count = count + 1;
        END LOOP;

    IF count > 0
    THEN
        -- успешно, сохраняем ид файла
        INSERT INTO ou.paringud (user_id, sql, params, tulemused, changes)
        VALUES (user_id, 'docs.sp_import_puudumine_from_virosoft', import_data, jsonb_build_object('result', count),
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
                               palk.sp_import_puudumine_from_virosoft(4711::integer, 3::integer, '{
"userId":"e81dd1f82d5d97419f16c20916ed822456b7a6a9",
"fileId":"02.06.2025",
"file":
[{"isik":"BeÅ¡ekerskas Valentina",
		"ik":"46002203715",
		"amet":"osakonna juhataja",
		"kas_puhkus": "ei",
		"PuhkuseLiik":"TÃ¶Ã¶tasu sÃ¤ilimise",
		"alg_kpv":"06.04.0020",
		"lopp_kpv":"06.04.0020",
		"PuudumiseKood":"V",
		"HaigusleheTyyp":"",
		"paevad":1,
		"tunnid":0
}
,
{"isik":"BeÅ¡ekerskas Valentina",
		"ik":"46002203715",
		"amet":"osakonna juhataja",
		"kas_puhkus": "ei",
		"PuhkuseLiik":"PÃµhipuhkus",
		"alg_kpv":"18.06.2020",
		"lopp_kpv":"26.06.2020",
		"PuudumiseKood":"P",
		"HaigusleheTyyp":"",
		"paevad":7,
		"tunnid":0
}
,
{"isik":"Zaitseva Lilia",
		"ik":"48312153717",
		"amet":"vanemspetsialist",
		"kas_puhkus": "ei",
		"PuhkuseLiik":"TÃ¶Ã¶lepingujÃ¤rgse",
		"alg_kpv":"13.06.2020",
		"lopp_kpv":"13.06.2020",
		"PuudumiseKood":"VK",
		"HaigusleheTyyp":"",
		"paevad":1,
		"tunnid":0
}
,
{"isik":"Zaitseva Lilia",
		"ik":"48312153717",
		"amet":"vanemspetsialist",
		"kas_puhkus": "ei",
		"PuhkuseLiik":"PÃµhipuhkus",
		"alg_kpv":"19.06.2020",
		"lopp_kpv":"30.06.2020",
		"PuudumiseKood":"P",
		"HaigusleheTyyp":"",
		"paevad":10,
		"tunnid":0
}
]}'::JSONB) p
                       )
    )
        AS x (error_message TEXT, error_code INTEGER, result INTEGER)


*/