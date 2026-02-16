DROP FUNCTION IF EXISTS palk.loe_puudumised(INTEGER, JSON);
DROP FUNCTION IF EXISTS palk.loe_puudumised(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION palk.loe_puudumised(IN user_id INTEGER, IN params JSONB, OUT result INTEGER,
                                               OUT error_code INTEGER, OUT error_message TEXT, OUT data JSONB)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_puudumiste_ids JSONB = params -> 'puudumiste_ids'; -- массив индентификаторов договоров
    v_puudumine      RECORD;
    l_params         JSONB;
    l_dok_id         INTEGER; -- ИД сформированной проводки
    v_user           RECORD;
    v_tulemus        RECORD;

BEGIN
    -- проверка пользователя
    SELECT
        kasutaja,
        rekvid
    INTO v_user
    FROM
        ou.userid u
    WHERE
        u.id = user_Id;

    IF v_user.kasutaja IS NULL
    THEN
        error_code = 5;
        error_message = 'Kasutaja ei leitud,  userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        SELECT error_message, error_code INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

        RETURN;
    END IF;

    -- проверка параметров
    IF l_puudumiste_ids IS NULL or jsonb_array_length(l_puudumiste_ids) = 0
    THEN
        error_code = 6;
        error_message = 'Parametrid on vale või puuduvad';
        result = 0;
        SELECT error_message, error_code INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

        RETURN;

    END IF;

    for v_puudumine in (
                           select
                               p.id,
                               p.kpv1,
                               p.kpv2,
                               a.nimetus                                                        as isik,
                               a.regkood                                                        as isikukood,
                               p.puudumiste_liik                                                as pohjus,
                               p.properties ->> 'puudumiste_kood'                               as vs_kood,
                               coalesce((p.properties ->> 'palk_oper_id')::integer, 0)::integer as palk_oper_id,
                               p.properties ->> 'vm_kpv'                                        as vm_kpv

                           from
                               palk.puudumine                p
                                   inner join palk.tooleping t on t.id = p.lepingid
                                   inner join libs.asutus    a on a.id = t.parentid
                           where
                                 p.id in (
                                             select jsonb_array_elements(l_puudumiste_ids)::integer
                                         )
                             and p.status <> 'deleted'
                       )
        loop

            l_params = to_jsonb(row.*)
                       FROM
                           (
                               SELECT
                                   l_dok_id                                AS doc_id,
                                   ltrim(rtrim(v_puudumine.isik)) || ltrim(rtrim(v_puudumine.pohjus::text)) ||
                                   to_char(v_puudumine.kpv1, 'DD.MM.YYYY') || '-' ||
                                   to_char(v_puudumine.kpv2, 'DD.MM.YYYY') AS error_message,
                                   0::INTEGER                              AS error_code,
                                   case
                                       when v_puudumine.vm_kpv is null or empty(v_puudumine.vm_kpv) then null
                                       else v_puudumine.vm_kpv end         as vm_kpv
                           ) row;
            data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

            -- prepaire params
            l_params = jsonb_build_object('puudumise_id', v_puudumine.id);

            if v_puudumine.palk_oper_id is null or v_puudumine.palk_oper_id = 0 or not exists
            (
                select
                    id
                from
                    palk.palk_oper
                where
                    parentid = v_puudumine.palk_oper_id
            ) then
                v_tulemus = palk.gen_puhkuse_oper(user_id, l_params);
            end if;
        end loop;
    result = 1;
    RETURN;
END ;

$BODY$ LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.loe_puudumised(user_id INTEGER, params JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.loe_puudumised(user_id INTEGER, params JSONB) TO dbpeakasutaja;

/*SELECT *
from
    palk.loe_puudumised(2477, '{
      "puudumiste_ids": [
        161918
      ]
    }'::jsonb)
*/
/*

select * from palk.puudumine
where kpv1 = '2025-12-03'
order by id desc limit 10
where id = 161936
*/