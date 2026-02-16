DROP FUNCTION IF EXISTS palk.sp_salvesta_puudumine(DATA JSON, userid INTEGER, user_rekvid INTEGER);

CREATE FUNCTION palk.sp_salvesta_puudumine(data JSON, userid INTEGER, user_rekvid INTEGER)
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    puudumine_id             INTEGER;
    userName                 TEXT;
    doc_id                   INTEGER           = data ->> 'id';
    doc_data                 JSON              = data ->> 'data';
    doc_kpv1                 DATE              = doc_data ->> 'kpv1';
    doc_kpv2                 DATE              = doc_data ->> 'kpv2';
    doc_paevad               INTEGER           = doc_data ->> 'paevad';
    doc_arvestatud_paevad    integer           = case
                                                     when (doc_data ->> 'arvestatud_paevad')::text = '' then null::text
                                                     else (doc_data ->> 'arvestatud_paevad')::text end::integer; -- расчетные дни
    doc_puudumiste_liik      PUUDUMISTE_LIIGID = (doc_data ->> 'puudumiste_liik') :: TEXT;
    doc_tyyp                 INTEGER           = doc_data ->> 'tyyp';
    doc_lepingid             INTEGER           = doc_data ->> 'lepingid';
    doc_libid                INTEGER           = doc_data ->> 'libid';
    doc_summa                NUMERIC(14, 4)    = doc_data ->> 'summa';
    doc_muud                 TEXT              = doc_data ->> 'muud';
    doc_kas_arvesta_parandus integer           = doc_data ->> 'kas_arvesta_parandus';
    doc_puudumiste_kood      text              = doc_data ->> 'puudumiste_kood'; -- код из вирософт
    doc_puudumise_tyyp       text              = doc_data ->> 'puudumise_tyyp'; -- E, J тип больничного (первичный или повторный)
    doc_eelmise_puudumine_id integer           = doc_data ->> 'eelmise_puudumine_id'; -- ссылка на предыдущий документ
    doc_allikas_e            text              = doc_data ->> 'allikas_e'; -- источник (основной) для расчета
    doc_allikas_j            text              = doc_data ->> 'allikas_j'; -- источник (основной) для расчета
    doc_arvestatud_paevad_j  integer           = doc_data ->> 'arvestatud_paevad_j'; -- кол-во дней больничного со второго источника
    doc_VM_kpv               date              = doc_data ->> 'vm_kpv';
    new_history              JSONB;
    v_puudumine              RECORD;
    is_import                BOOLEAN           = data ->> 'import';
    doc_details              JSONB             = doc_data ->> 'gridData';
    json_data                JSONB;
    v_pk                     record;
    v_palk_oper              record;
    l_puhkuse_summa          numeric(14, 4)    = 0;
    l_puhkuse_paevad         numeric           = 0;
    l_toopaevad              integer           = 0;
    l_katkestuse_summa       numeric(14, 4)    = 0;
    i                        integer           = 0;
    l_palk_oper_lib_id       integer;
    l_function               text;
    l_params                 json;
    tulemus                  record;
    l_tulemus_json           json;
    l_dok_id                 integer;
    l_save_params            jsonb;
    l_libs_ids               integer[];
    l_leping_ids             integer[];
    l_isik_ids               integer[];
    kas_alus                 boolean           = false;
BEGIN

    SELECT
        kasutaja
    INTO userName
    FROM
        ou.userid u
    WHERE
          u.rekvid = user_rekvid
      AND u.id = userId;
    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE exception 'Viga: User not found %', user;
    END IF;

    json_data =
            jsonb_build_object(
                    'arvestatud_paevad', doc_arvestatud_paevad,
                    'arvestatud_paevad_j', doc_arvestatud_paevad_j,
                    'pk', doc_details,
                    'kas_arvesta_parandus', doc_kas_arvesta_parandus,
                    'puudumiste_kood', doc_puudumiste_kood,
                    'puudumise_tyyp', doc_puudumise_tyyp,
                    'eelmise_puudumine_id', doc_eelmise_puudumine_id,
                    'allikas_e', doc_allikas_e,
                    'allikas_j', doc_allikas_j,
                    'arvestatud_paevad_j', doc_arvestatud_paevad_j,
                    'vm_kpv', doc_VM_kpv
            );

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    -- проверка на наличие отсутствия в периоде
    if exists
    (
        select
            id
        from
            palk.puudumine p
        where
              lepingid = doc_lepingid
          and (doc_kpv1::date, doc_kpv2::date) OVERLAPS (p.kpv1::date, p.kpv2::date)
          and coalesce(doc_id, 0) <> p.id
          and p.status <> 'deleted'
    ) then
        raise exception 'Viga: Selles ajavahemikus töötaja juba puudub';

    end if;

    -- вставка или апдейт docs.doc

    IF doc_id IS NULL OR doc_id = 0
    THEN
        SELECT
            row_to_json(row)
        INTO new_history
        FROM
            (
                SELECT
                    now()    AS created,
                    userName AS user
            ) row;

        INSERT INTO
            palk.puudumine (lepingid, libid, summa, kpv1, kpv2, paevad, puudumiste_liik, tyyp, status, ajalugu, muud,
                            properties)
        VALUES
            (doc_lepingid, doc_libid, doc_summa, doc_kpv1, doc_kpv2, doc_paevad,
             doc_puudumiste_liik :: PUUDUMISTE_LIIGID,
             doc_tyyp, 'active',
             new_history, doc_muud, json_data)
        RETURNING id
            INTO puudumine_id;


    ELSE
        SELECT
            p.id,
            p.kpv1,
            p.kpv2,
            p.paevad,
            p.summa,
            p.muud,
            p.puudumiste_liik,
            p.tyyp,
            p.lepingid,
            (p.properties ->> 'palk_oper_id')::integer                    as palk_oper_id,
            t.parentid                                                    as isik_id,
            p.properties ->> 'algorithm'                                  as algorithm,
            ((p.properties ->> 'data')::jsonb -> 0 ->> 'paevad')::integer as arv_puhkuse_paevad,
            ((p.properties ->> 'data')::jsonb -> 0 ->> 'summa')::numeric  as arv_puhkuse_summa

        INTO v_puudumine
        FROM
            palk.puudumine                p
                inner join palk.tooleping t on t.id = p.lepingid
        WHERE
            p.id = doc_id;

        if v_puudumine.palk_oper_id is not null then
            kas_alus = true;
--            raise exception 'Viga, alus operatsioonpuudub';
        end if;

        if kas_alus then
            -- создаем расчет

            select *,
                   po.doklausid as dokpropid
            into v_palk_oper
            from
                palk.palk_oper po
            where
                parentid = v_puudumine.palk_oper_id;
        end if;

        -- check for puudumine katkestus

        if jsonb_array_length(doc_details::jsonb) > 0 then
            -- базовая операция отпускные
            for v_pk in
                select *
                from
                    jsonb_to_recordset((doc_details)
                    ) as x(kpv1 date, kpv2 date, paevad integer, toopaevad integer, summa numeric, alus text,
                           palk_oper_id integer,
                           deleted text)
                where
                    paevad > 0
                loop
                    -- дорасчет календарных дней
                    if v_pk.toopaevad is null or v_pk.toopaevad = 0 then
                        l_toopaevad = palk.get_work_days(jsonb_build_object('kuu', extract(month from v_pk.kpv1),
                                                                            'aasta', extract(year from v_pk.kpv1),
                                                                            'paev', extract(day from v_pk.kpv1),
                                                                            'lopp',
                                                                            extract(day from v_pk.kpv2)) :: JSON);

                        doc_details = jsonb_set(doc_details, array [i::text,'toopaevad'], to_jsonb(l_toopaevad));

                    end if;

                    if kas_alus and coalesce(v_pk.palk_oper_id, 0) = 0 and doc_kas_arvesta_parandus = 1 then
                        select
                            po.summa,
                            v_puudumine.paevad,
                            po.summa / v_puudumine.paevad * v_pk.paevad,
                            po.libid
                        into l_puhkuse_summa, l_puhkuse_paevad , l_katkestuse_summa, l_palk_oper_lib_id
                        from
                            palk.palk_oper po
                        where
                            po.parentid = v_puudumine.palk_oper_id::integer;

-- Сделала отзыв на 6 и 7 сентября - это 2 выходных дня. На них отпускные не начислялись, соответственно и снимать не надо ничего. VB 16.09.2025
                        if coalesce(v_puudumine.algorithm, 'Null') = 'Palk' then

                            -- берем дни из расчета (без учета выходных
                            l_toopaevad = (
                                              select
                                                  p.too_paevad
                                              from
                                                  palk.arvuta_puudumise_paevad(jsonb_build_object('alg_kpv', v_pk.kpv1, 'lopp_kpv', v_pk.kpv2)) p
                                          );
                            l_katkestuse_summa =
                                    v_puudumine.arv_puhkuse_summa / v_puudumine.arv_puhkuse_paevad * l_toopaevad;
                        end if;


                        doc_details = jsonb_set(doc_details, array [i::text,'summa'], to_jsonb(l_katkestuse_summa));

                        -- создаем операцию
                        -- расчет
                        if doc_puudumiste_liik in ('PUHKUS') and doc_kas_arvesta_parandus = 1 and
                           l_katkestuse_summa > 0 then
                            -- Готовим параметры для расчета
                            SELECT
                                row_to_json(row)
                            INTO l_params
                            FROM
                                (
                                    SELECT
                                        v_pk.kpv1               AS kpv,
                                        user_rekvid             AS rekvid,
                                        doc_lepingid            AS lepingid,
                                        l_palk_oper_lib_id      AS libid,
                                        -1 * l_katkestuse_summa as alus_summa
                                ) row;

                            -- определяем расчетную процедуру
                            l_function = 'palk.sp_calc_arv';

                            -- вызов процедура расчета

                            EXECUTE 'select * from ' || l_function || '($1, $2)'
                                INTO STRICT tulemus
                                USING userid, l_params;

                            l_tulemus_json = row_to_json(tulemus);

                            IF tulemus.summa IS NOT NULL AND tulemus.summa <> 0
                            THEN

                                SELECT
                                    0 :: INTEGER                                                  AS id,
                                    v_pk.kpv1                                                     AS kpv,
                                    v_pk.kpv1                                                     as maksekpv,
                                    doc_lepingid                                                  AS lepingid,
                                    l_palk_oper_lib_id                                            AS libid,
                                    tulemus.summa                                                 AS summa,
                                    v_palk_oper.dokpropid                                         AS dokpropid,
                                    v_palk_oper.kood1                                             AS kood1,
                                    v_palk_oper.kood2                                             AS kood2,
                                    v_palk_oper.kood5                                             AS kood5,
                                    null                                                          AS kood4,
                                    v_palk_oper.konto                                             AS konto,
                                    v_palk_oper.tunnus                                            AS tunnus,
                                    null                                                          AS korrkonto,
                                    v_palk_oper.proj                                              AS proj,
                                    v_palk_oper.tp :: TEXT                                        AS tp,
                                    coalesce((l_tulemus_json ->> 'tm') :: NUMERIC, 0) :: NUMERIC  AS tulumaks,
                                    coalesce((l_tulemus_json ->> 'sm') :: NUMERIC, 0) :: NUMERIC  AS sotsmaks,
                                    coalesce((l_tulemus_json ->> 'tki') :: NUMERIC, 0) :: NUMERIC AS tootumaks,
                                    coalesce((l_tulemus_json ->> 'tka') :: NUMERIC, 0) :: NUMERIC AS tka,
                                    coalesce((l_tulemus_json ->> 'pm') :: NUMERIC, 0) :: NUMERIC  AS pensmaks,
                                    coalesce((l_tulemus_json ->> 'mvt') :: NUMERIC, 0) :: NUMERIC AS tulubaas,
                                    v_palk_oper.tululiik                                          AS tululiik,
                                    l_tulemus_json ->> 'selg' :: TEXT                             AS muud,
                                    TRUE                                                          AS kas_lausend,
                                    FALSE                                                         AS kas_kas_arvesta_saldo,
                                    v_puudumine.id                                                as puudumise_id,
                                    false                                                         as kas_ettemaks,
                                    null                                                          as ettemaksu_periood
                                INTO v_palk_oper;

                                l_save_params = row_to_json(v_palk_oper)::JSONB;

                                -- save results
                                l_dok_id =
                                        palk.sp_salvesta_palk_oper(
                                                json_build_object('data', l_save_params, 'kas_lausend', true) :: JSON,
                                                userid,
                                                user_rekvid);

                                doc_details =
                                        jsonb_set(doc_details, array [i::text,'palk_oper_id'], to_jsonb(l_dok_id));

                                -- расчет налогов
                                select
                                    array_agg(pk.libid)
                                into l_libs_ids
                                from
                                    palk.palk_kaart             pk
                                        inner join libs.library l on l.id = pk.libid
                                where
                                      pk.lepingid = doc_lepingid
                                  and pk.status = 1
                                  and (l.properties::jsonb ->> 'liik')::integer in (2, 3, 4, 5, 7, 8);

                                -- готовим параметры
--                            l_leping_ids = array_append(l_leping_ids, doc_lepingid);

                                SELECT
                                    row_to_json(row)
                                INTO l_params
                                FROM
                                    (
                                        SELECT
                                            array_append(l_leping_ids, doc_lepingid)      AS leping_ids,
                                            l_libs_ids                                    AS lib_ids,
                                            array_append(l_isik_ids, v_puudumine.isik_id) as isik_ids,
                                            array []::integer[]                           as osakond_ids,
                                            v_pk.kpv1                                     AS kpv,
                                            v_pk.kpv1::date                               as maksekpv,
                                            v_palk_oper.dokpropid                         AS dokprop,
                                            FALSE                                         AS is_delete_prev_oper,
                                            false                                         as kas_arvesta_minsots
                                    ) row;


                                PERFORM palk.gen_palkoper(userid, l_params:: JSON);


                            end if;
                        end if;
                    else
                        if v_pk.deleted = '1' then
                            select result into l_dok_id from palk.sp_delete_palk_oper(userid, v_pk.palk_oper_id);
                            if coalesce(l_dok_id, 0) = 1 then
                                doc_details =
                                        jsonb_set(doc_details, array [i::text,'palk_oper_id'], to_jsonb(null));
                            end if;

                        end if;
                    end if;

                    i = i + 1;
                end loop;
        end if;

        SELECT
            row_to_json(row)
        INTO new_history
        FROM
            (
                SELECT
                    now()       AS updated,
                    userName    AS user,
                    v_puudumine AS puudumine
            ) row;

        UPDATE palk.puudumine
        SET
            libid           = doc_libid,
            summa           = doc_summa,
            ajalugu         = '[]'::jsonb || coalesce(ajalugu, '[]'::jsonb) || new_history,
            kpv1            = doc_kpv1,
            kpv2            = doc_kpv2,
            paevad          = doc_paevad,
            puudumiste_liik = doc_puudumiste_liik :: PUUDUMISTE_LIIGID,
            tyyp            = doc_tyyp,
            muud            = doc_muud,
            properties      = coalesce(properties, '{}'::jsonb) || json_data
        WHERE
            id = doc_id
        RETURNING id
            INTO puudumine_id;

    END IF;
    RETURN puudumine_id;
END;
$$;

/*
SELECT palk.sp_salvesta_puudumine(
    '{"id":157910,"data":{"algorithm":"Arveldus","allikas":"LE-P","amet":"Varustaja","artikkel":"5002","arvestatud_paevad":14,"arv_paevad_perioodis":102,"avg_paeva_summa":22.650000,"doc_type_id":"PUUDUMINE","id":157910,"kas_arvesta_parandus":1,"kpv1":"20250915","kpv2":"20250928","lepingid":30766,"libid":0,"muud":null,"paevad":14,"palk_oper_id":0,"params_kpv1":"20250201","params_kpv2":"20250731","parentid":11019,"pt_nimetus":"Korraline puhkus","puudumiste_liik":"PUHKUS","selg":"Kalendri paevad periodis:181 pidupaavad:7 puudumised:21.04.2025 - 25.04.2025, paevad:5,23.05.2025 - 31.05.2025, paevad:9,01.06.2025 - 30.06.2025, paevad:27,01.07.2025 - 31.07.2025, paevad:31, Arveldused kokku:2309.93 kasutatud koodid: PPALK-KESK-09110","status":"active","summa":60,"tegev":"09110","tunnus":"0911032","tyyp":1,"userid":4824,"vs_kooded":"{P}","gridData":[{"alus":"test","deleted":"0","kpv1":"20250918","kpv2":"20250922","paevad":5,"palk_oper_id":0,"summa":0,"toopaevad":3,"userid":4824}]}}',
    4824, 96)
*/