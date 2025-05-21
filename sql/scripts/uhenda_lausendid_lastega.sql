DROP FUNCTION IF EXISTS lapsed.uhenda_lausendid_lastega();

CREATE FUNCTION lapsed.uhenda_lausendid_lastega()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_doc     RECORD;
    v_journal record;
    l_vn      TEXT;
    l_laps_id INTEGER;
    l_count   INTEGER = 0;
BEGIN

    FOR v_doc IN
        SELECT
            l.parentid                                   as laps_id,
            d.rekvid                                     as rekv_id,
            lapsed.get_viitenumber(d.rekvid, l.parentid) as vn,
            d.docs_ids
        from
            docs.doc                           d
                inner join lapsed.liidestamine l on l.docid = d.id
        where
              d.status < 3
          and d.created::date >= '2022-12-31'::date
          and d.docs_ids is not null
        loop
            raise notice 'v_doc %', v_doc.laps_id;

            if exists
            (
                select
                    id
                from
                    docs.journal j
                where
                      parentid in (
                                      select unnest(v_doc.docs_ids)
                                  )
--                  and j.properties ->> 'vn' is null
            ) then
                for v_journal in
                    select
                        parentid
                    from
                        docs.journal j
                    where
                          j.parentid in (
                                            select unnest(v_doc.docs_ids)
                                        )
                      and j.properties ->> 'vn' is null
                    loop
                        update docs.journal
                        set
                            properties = coalesce(properties, '{}'::jsonb) || jsonb_build_object('vn', v_doc.vn)
                        where
                            parentid = v_journal.parentid;

                        insert into lapsed.liidestamine (parentid, docid)
                        values (v_journal.parentid, v_doc.laps_id);

                        l_count = l_count + 1;
                        raise notice 'l_count %', l_count;
                    end loop;
            else
                raise notice 'not exists';
            end if;
        end loop;
    RETURN l_count;

END;
$$;

SELECT lapsed.uhenda_lausendid_lastega();

--DROP FUNCTION IF EXISTS lapsed.uhenda_lausendid_lastega();
