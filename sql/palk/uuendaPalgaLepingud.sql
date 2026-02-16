DROP FUNCTION IF EXISTS palk.uuendaPalgaLepingud(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION palk.uuendaPalgaLepingud(l_user_id integer, l_ameti_klassif_id INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    v_tl      RECORD;
    v_pm      record;
    l_result  integer = 0;
    l_ajalugu jsonb;
    l_user    text    = (
                            select
                                kasutaja
                            from
                                ou.userid
                            where
                                id = l_user_id
                        );
    l_rekv_id integer = (
                            select
                                rekvid
                            from
                                ou.userid
                            where
                                id = l_user_id
                        );
BEGIN

    if not exists
    (
        select
            id
        from
            ou.userid
        where
              id = l_user_id
          AND roles ->> 'is_admin' IS NOT NULL
          AND (roles ->> 'is_admin')::BOOLEAN
    ) then
        raise exception 'Viga: Puuduvad õigused';
    end if;
    for v_pm in
        SELECT
            l.kood,
            (jsonb_array_elements(properties::jsonb -> 'palgaastmed') ->> 'summa')::numeric(12, 2) AS summa,
            (jsonb_array_elements(properties::jsonb -> 'palgaastmed') ->>
             'palgamaar')::integer                                                                 AS palgamaar
        FROM
            libs.library l
        WHERE
            l.id = l_ameti_klassif_id
        LOOP
            for v_tl in
                select
                    t.id,
                    t.palk
                from
                    palk.tooleping t
                where
                      t.palgamaar = v_pm.palgamaar
                  and (t.lopp is null or t.lopp > current_date)
                  and t.tasuliik = 1 -- kuupalk
                  and t.properties::jsonb ->> 'ameti_klassif' is not null
                  and t.properties ->> 'ameti_klassif' = v_pm.kood
                  and t.palk <> v_pm.summa
                  and t.rekvid = l_rekv_id -- только учреждение пользователя, В.Б. 17.09.2025
                LOOP
                    l_ajalugu = jsonb_build_object('user', l_user, 'updated', now(), 'eelmine', v_tl.palk);

                    update palk.tooleping
                    set
                        palk    = v_pm.summa,
                        ajalugu = coalesce(ajalugu, '[]') || l_ajalugu
                    where
                        id = v_tl.id;
                    l_result = l_result + 1;
                END LOOP;
        end loop;
    RETURN 1;

END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE
                          COST 100;

GRANT EXECUTE ON FUNCTION palk.uuendaPalgaLepingud(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.uuendaPalgaLepingud(INTEGER, INTEGER) TO dbpeakasutaja;
--GRANT EXECUTE ON FUNCTION palk.uuendaPalgaLepingud(INTEGER, INTEGER) TO taabel;


