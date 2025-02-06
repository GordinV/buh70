DROP FUNCTION IF EXISTS restore_journal(INTEGER);

CREATE FUNCTION restore_journal(IN doc_id INTEGER)
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_doc                 record;
    v_journal             RECORD;
    jsonb_journal         jsonb;
    jsonb_journal1        jsonb;
    l_json                jsonb;
    v_journal1            RECORD;
    l_rekvid              INTEGER;
    l_tunnus              TEXT;
    tmp_arv               RECORD;
    result                integer;
    user_id               integer;
    l_period              integer;
    l_kpv                 date;
    l_period_manipulation boolean = false;
    l_hootehing_id        integer;
    l_hooisik             integer;
BEGIN
    -- check if exists
    select *
    into v_doc
    from
        docs.doc
    where
          id = doc_id
      and status = 3;

    if v_doc is null then
        raise exception 'Viga, dokument puudub';
    end if;

    user_id = (
                  select id from ou.userid where rekvid = v_doc.rekvid and kasutaja = 'vlad' limit 1
              );

    --select from history
    jsonb_journal = v_doc.history -> (jsonb_array_length(v_doc.history) - 1) -> 'journal';

    if jsonb_journal ->> 'kpv' is null then
        raise exception 'Viga, andmed puuduvad';
    end if;
    l_kpv = (jsonb_journal ->> 'kpv')::date;

    jsonb_journal1 = v_doc.history -> (jsonb_array_length(v_doc.history) - 1) -> 'journal1' -> 0;

    l_json = jsonb_journal || jsonb_build_object('gridData', jsonb_journal1);

    l_json = jsonb_build_object('id', doc_id, 'taastamine', 1, 'data', l_json);

    l_period = (
                   select
                       kinni
                   from
                       ou.aasta
                   where
                         rekvid = v_doc.rekvid
                     and kuu = month(l_kpv)
                     and aasta = year(l_kpv)
                   limit 1
               );

    if l_period = 1 then

        update ou.aasta
        set
            kinni = 0
        where
              rekvid = v_doc.rekvid
          and kuu = month(l_kpv)
          and aasta = year(l_kpv);

        l_period_manipulation = true;
    end if;
    result = docs.sp_salvesta_journal(l_json :: JSON, user_id, v_doc.rekvid);

    if (l_period_manipulation) then
        update docs.doc set lastupdate = created where id = doc_id;

        if exists
        (
            select id from hooldekodu.hootehingud where journalid = doc_id and status = 3
        ) then

            if not exists
            (
                select id from hooldekodu.hootehingud where journalid = doc_id and status = 1
            ) then
                l_hootehing_id = (
                                     select
                                         id
                                     from
                                         hooldekodu.hootehingud
                                     where
                                           journalid = doc_id
                                       and status = 3
                                     order by id desc
                                     limit 1
                                 );
                update hooldekodu.hootehingud set status = 1 where id = l_hootehing_id;
                l_hooisik = (
                                select
                                    isikid
                                from
                                    hooldekodu.hootehingud
                                where
                                    id = l_hootehing_id
                            );

                select hooldekodu.sp_calc_hoojaak(l_hooisik);


            end if;

        end if;


        update ou.aasta
        set
            kinni = l_period
        where
              rekvid = v_doc.rekvid
          and kuu = month(l_kpv)
          and aasta = year(l_kpv);
    end if;
    raise notice 'result %',result;
    return result;

END;
$$;

/*
SELECT restore_journal(5713207);
*/


