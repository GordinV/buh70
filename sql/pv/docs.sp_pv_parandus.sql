DROP FUNCTION IF EXISTS docs.sp_pv_oper_parandus(INTEGER);
DROP FUNCTION IF EXISTS docs.sp_pv_oper_parandus(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_pv_oper_parandus(
    tnId INTEGER, pv_oper_id integer default null, user_id integer default null)
    RETURNS NUMERIC(14, 2) AS
$BODY$

DECLARE
    v_pv_kaart        RECORD;
    v_pv_oper         RECORD;
    json_object       JSONB;
    v_soetmaks        RECORD;
    umberHindamiseKpv DATE;
    a_pv_opers        TEXT[] = enum_range(NULL :: PV_OPERATSIOONID);
    l_jaak            numeric;
    l_kulum_maha_id   integer;
    v_kulum           record;
BEGIN

    -- load the card
    SELECT
        coalesce((l.properties :: JSONB ->> 'soetkpv') :: DATE, now() :: DATE)                 AS soetkpv,
        coalesce((l.properties :: JSONB ->> 'parhind') :: NUMERIC(12, 2), 0) :: NUMERIC(12, 2) AS parhind,
        coalesce((l.properties :: JSONB ->> 'jaak') :: NUMERIC(12, 2), 0) :: NUMERIC(12, 2)    AS jaak,
        1                                                                                      AS kuurs,
        l.rekvid,
        l.properties
    INTO v_pv_kaart
    FROM
        libs.library l
    WHERE
        l.id = tnId;

    -- calculate PV cost
    l_jaak = docs.sp_recalc_pv_jaak(tnId::INTEGER);

    if pv_oper_id is not null then

        -- load operation
        select
            summa,
            kpv,
            kood3 as rv,
            liik,
            d.docs_ids,
            d.rekvid,
            d.id,
            po.kood1 as tegev,
            po.kood2 as allikas,
            po.proj,
            po.tunnus
        into v_pv_oper
        from
            docs.pv_oper            po
                inner join docs.doc d on d.id = po.parentid
        where
            po.parentid = pv_oper_id;


        if v_pv_oper.liik = 3 and v_pv_oper.rv = '12' then

            -- частичное списание
            -- ищем износ для этой операции
            l_kulum_maha_id = (
                                  select
                                      po.parentid
                                  from
                                      docs.pv_oper po
                                  where
                                        po.pv_kaart_id = tnId
                                    and po.liik = 2
                                    and po.kood3 = '12'
                                    and po.kpv = v_pv_oper.kpv
                                  limit 1
                              );


            if l_kulum_maha_id is null then
                -- операции нет, создаем
                -- Берем последний износ для этой карточки
                SELECT
                    po.id,
                    po.nomid,
                    po.konto,
                    po.doklausid,
                    po.kood1 as tegev,
                    kood2    as allikas,
                    kood5    as artikkel,
                    proj,
                    tunnus

                into v_kulum
                FROM
                    docs.pv_oper po
                WHERE
                      pv_kaart_id = tnId :: INTEGER
                  AND kpv < v_pv_oper.kpv
                  AND po.liik = 2
                ORDER BY kpv DESC
                LIMIT 1;

                SELECT
                    row_to_json(row)
                INTO json_object
                FROM
                    (
                        SELECT
                            coalesce(l_kulum_maha_id, 0) AS id,
                            v_pv_oper.kpv                AS kpv,
                            v_kulum.nomid                AS nomid,
                            2                            AS liik,
                            v_kulum.doklausid            AS doklausid,
                            v_pv_oper.summa              AS summa,
                            '888888'                     AS konto,
                            v_pv_oper.proj                 AS proj,
                            v_pv_oper.tegev                AS kood1,
                            v_pv_oper.allikas              AS kood2,
                            '12'                         AS kood3,
                            '155'                        AS kood5,
                            v_pv_oper.tunnus               AS tunnus,
                            'AUTOMATSELT ARVESTUS'       AS muud,
                            tnId :: INTEGER              AS pv_kaart_id
                    ) row;

                SELECT
                    row_to_json(row)
                INTO json_object
                FROM
                    (
                        SELECT
                            coalesce(l_kulum_maha_id, 0) AS id,
                            json_object                  AS data
                    ) row;

                l_kulum_maha_id = docs.sp_salvesta_pv_oper(json_object::json, user_id, v_pv_oper.rekvid);

                if coalesce(l_kulum_maha_id, 0) = 0 then
                    raise exception 'Viga, RV12 kulumi arvestus ebaõnnestus';
                end if;

                -- контируем операцию
                perform docs.gen_lausend_pv_oper(l_kulum_maha_id,user_id);

            end if;
            if not l_kulum_maha_id = ANY (v_pv_oper.docs_ids) then
                -- связываем kulum с операций
                update docs.doc set docs_ids = array_append(docs_ids, l_kulum_maha_id) where id = v_pv_oper.id;
                update docs.doc set docs_ids = array_append(docs_ids, v_pv_oper.id) where id = l_kulum_maha_id;
            end if;

        end if;

    end if;


    RETURN v_pv_kaart.parhind;

END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_pv_oper_parandus(INTEGER, INTEGER,INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_pv_oper_parandus(INTEGER, INTEGER,INTEGER) TO dbpeakasutaja;

/*
SELECT docs.sp_pv_oper_parandus(447);

*/