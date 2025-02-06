DROP FUNCTION IF EXISTS palk.sp_import_taabel_from_virosoft(INTEGER, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION palk.sp_import_taabel_from_virosoft(IN user_id integer, IN rekv_id integer,
                                                               IN import_data JSONB,
                                                               OUT result INTEGER,
                                                               out error_code integer,
                                                               OUT error_message TEXT,
                                                               OUT data JSONB)
    RETURNS RECORD AS
$BODY$

DECLARE
    userName        TEXT;
    doc_data        JSON    = import_data ->> 'file';
    doc_file_id     TEXT    = import_data ->> 'fileId';
    json_object     jsonb;
    jsonb_params    jsonb;
    l_isik_id       integer;
    l_Leping_id     integer;
    l_lopp_kpv      date;
    l_kuu           integer;
    l_aasta         integer;
    l_kokku_tunnid  numeric;
    l_paev          numeric;
    l_ohtu          numeric;
    l_too           numeric;
    l_oo            numeric;
    l_tahtpaev      numeric;
    l_puhapaev      numeric;
    l_uleajatunnd   numeric;
    l_taabel_id     integer;
    l_toograafik_id integer;
    count           integer = 0;
    l_ind_norm      numeric;
BEGIN
    data = '[]'::jsonb;
    -- init

    -- check user
    SELECT
        kasutaja
    INTO userName
    FROM
        ou.userid u
    WHERE
          u.id = user_id
      and u.rekvid = rekv_id;

    IF userName IS NULL
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
        LOOP
            --s var inits
            l_kuu = null;
            l_aasta = null;

            if empty(coalesce(json_object ->> 'ik', '')) then
                -- пуста строка
                continue ;
            end if;

            if not empty(coalesce(json_object ->> 'regkood', '')) then
                -- указан рег. код
                rekv_id = (
                              select id
                              from ou.rekv
                              where regkood = json_object ->> 'regkood'
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
                                  t.isikukood = json_object ->> 'ik'
                              and t.rekvid = rekv_id
                            order by id desc
                            limit 1
                        );
            -- период
            select
                month(get_date_from_string(left(coalesce(json_object ->> 'period', ''), 10), 'DD.MM.YYYY')),
                year(get_date_from_string(left(coalesce(json_object ->> 'period', ''), 10), 'DD.MM.YYYY'))
            into l_kuu, l_aasta;

            -- leping

            l_Leping_id = (
                              select
                                  t.lepingId
                              from
                                  palk.com_tootajad           t
                                      inner join libs.library l on l.id = t.ametid
                              where
                                    t.id = l_isik_id
--                                and t.amet = json_object ->> 'amet'
                                and upper(ltrim(rtrim(l.nimetus))) = upper(ltrim(rtrim(json_object ->> 'amet')))
                              order by t.lepingid desc
                              limit 1
                          );

            select
                coalesce((json_object ->> 'KokkuTunnid')::numeric, 0)::numeric            as kokku_tunnid,
                coalesce((json_object ->> 'TootundideSum')::numeric, 0)::numeric          as paeva_tunnid,
                coalesce((json_object ->> 'SumOhtutunnid')::numeric, 0)::numeric          as ohtu_tunnid,
                coalesce((json_object ->> 'SumOotunnid')::numeric, 0)::numeric            as oo_tunnid,
                coalesce((json_object ->> 'SumTooPuhapaevalTunnid')::numeric, 0)::numeric as puhapaevad_tunnid,
                coalesce((json_object ->> 'SumRiigipuhadTunnid')::numeric, 0)::numeric    as tahtpaev_tunnid,
                coalesce((json_object ->> 'SumUletunnid1')::numeric, 0)::numeric          as uleajatunnd_tunnid,
                coalesce((json_object ->> 'IndNorm')::numeric, 0)::numeric                as ind_norm
            into l_kokku_tunnid, l_paev, l_ohtu, l_oo, l_puhapaev, l_tahtpaev, l_uleajatunnd, l_ind_norm;

            if l_isik_id is null or l_Leping_id is null then
                error_message = 'Vead failis';
                error_code = 6;
                result = 0;
                data = data || jsonb_build_object('error_code', error_code, 'error_message',
                                                  ('IK:' || (json_object ->> 'ik') || ', Amet:' ||
                                                   (json_object ->> 'amet') ||
                                                   '-> Puudub isik või vale IK või vale ameti kood'),
                                                  'result', result, 'IK', json_object ->> 'ik', 'amet',
                                                  json_object ->> 'amet', 'kuu', l_kuu, 'aasta', l_aasta);
                continue;
            end if;

            if l_kuu is null or l_aasta is null then
                error_message = 'Vead failis';
                error_code = 6;
                result = 0;
                data = data || jsonb_build_object('error_code', error_code, 'error_message', 'Puudub või vale period',
                                                  'result', result, 'IK', json_object ->> 'ik', 'amet',
                                                  (json_object ->> 'amet'), 'kuu', l_kuu, 'aasta', l_aasta);
                continue;
            end if;

            -- ind. norm.
            if l_ind_norm > 0 then
                -- tooaja graafik

                -- otsin
                l_toograafik_id = (
                                      select
                                          id
                                      from
                                          palk.toograf t
                                      where
                                            t.lepingid = l_Leping_id
                                        and t.aasta = l_aasta
                                        and t.kuu = l_kuu
                                        and t.status = 'active'
                                      limit 1
                                  );

                jsonb_params =
                        jsonb_build_object('id', l_toograafik_id,
                                           'kuu', l_kuu,
                                           'aasta', l_aasta,
                                           'tund', l_ind_norm,
                                           'lepingid', l_Leping_id,
                                           'muud', 'Import (Virosoft)');

                jsonb_params = jsonb_build_object('id', l_toograafik_id, 'data', jsonb_params);

                l_toograafik_id = palk.sp_salvesta_toograafik(jsonb_params::json, user_id, rekv_id);

                if l_toograafik_id is null or empty(l_toograafik_id) then
                    error_message = 'Vead failis';
                    error_code = 6;
                    result = 0;
                    data = data || jsonb_build_object('error_code', error_code, 'error_message',
                                                      ('IK:' || (json_object ->> 'ik') || ', Amet:' ||
                                                       (json_object ->> 'amet') ||
                                                       '-> Tööaja graafiku salvestamine ebaõnnestus'),
                                                      'result', result, 'IK', json_object ->> 'ik', 'amet',
                                                      json_object ->> 'amet', 'kuu', l_kuu, 'aasta', l_aasta);
                    continue;

                end if;

            end if;

            -- сохраняем
            l_taabel_id = coalesce((
                                       select
                                           id
                                       from
                                           palk.palk_taabel1 pt
                                       where
                                             pt.lepingid = l_Leping_id
                                         and pt.kuu = l_kuu
                                         and pt.aasta = l_aasta
                                         and pt.status = 'active'
                                       limit 1
                                   ), 0);

            jsonb_params =
                    jsonb_build_object('id', l_taabel_id,
                                       'kuu', l_kuu,
                                       'aasta', l_aasta,
                                       'lepingid', l_Leping_id,
                                       'ohtu', l_ohtu,
                                       'oo', l_oo,
                                       'tahtpaev', l_tahtpaev,
                                       'puhapaev', l_puhapaev,
                                       'uleajatoo', l_uleajatunnd,
                                       'kokku', l_kokku_tunnid,
                                       'paev', (l_paev),
                                       'muud', 'Import (Virosoft)');

            jsonb_params = jsonb_build_object('id', l_taabel_id, 'data', jsonb_params);

            l_taabel_id = palk.sp_salvesta_palk_taabel(jsonb_params::json, user_id, rekv_id);


-- результат
            error_message = '';
            error_code = 0;
            result = l_taabel_id;
            data = data ||
                   jsonb_build_object('error_code', error_code,
                                      'error_message',
                                      ('IK:' || (json_object ->> 'ik') || ', Amet:' || (json_object ->> 'amet') ||
                                       ',Taabel importeeritud'),
                                      'result', result,
                                      'IK', (json_object ->> 'ik'),
                                      'amet', (json_object ->> 'amet'), 'kuu', l_kuu, 'aasta', l_aasta);

            count = count + 1;
        END LOOP;

    IF count > 0
    THEN
        -- успешно, сохраняем ид файла
        INSERT INTO ou.paringud (user_id, sql, params, tulemused, changes)
        VALUES
            (user_id, 'docs.sp_import_taabel_from_virosoft', import_data, jsonb_build_object('result', count),
             jsonb_build_object('fileId', doc_file_id));

    END IF;

    result = count;
    RETURN;


END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.sp_import_taabel_from_virosoft (INTEGER, INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_import_taabel_from_virosoft (INTEGER, INTEGER, JSONB) TO dbpeakasutaja;


/*
SELECT *
                  FROM jsonb_to_recordset(
                               (
                                   SELECT qry.data
                                   FROM (
                                            SELECT *
from
    palk.sp_import_taabel_from_virosoft(11578, 63, '{"file":[{"regkood":"75008485","asutus":"Narva Linnakantselei","yksus":"Kõrgemad ametnikud","period":"01.10.2025  -  31.10.2025","isik":
"Kaljuste Üllar","ik":"36111132734","amet":"linnasekretär","Tookoormus":"1.0","IndNorm":40,"SumPaevad":5,"TootundideSum":40,"SumTTSTunnid":0,"KokkuTunnid":40,"SumOhtutunnid":0,"SumOotunnid":0,"SumTooPuhapaevalTunnid":0,"SumRiigipuhadTunnid":0,"SumUletunnid1":0}],"fileId":"1"}'::JSONB)

                                        ) qry
                               )
                           ) AS x (error_message TEXT, error_code INTEGER, result INTEGER)

*/


