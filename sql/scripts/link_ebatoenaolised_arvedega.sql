DROP FUNCTION IF EXISTS lapsed.link_ebatoenaolised();

CREATE FUNCTION lapsed.link_ebatoenaolised(rekv_id integer)
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_journal      RECORD;
    l_count        INTEGER = 0;
    l_kokku        INTEGER = 0;
    l_user_id      INTEGER;
    l_json         JSONB;
    l_json_details JSONB   = '[]'::JSONB;
    v_params       RECORD;
    l_journal_id   INTEGER;
    v_arved        record;
    l_rekv_id      integer = rekv_id;
BEGIN

    -- делаем отчет, берем отрицательные значения и ищем по ним проводки
    for v_arved in (
                       select
                           d.docs_ids,
                           qry.*
                       from
                           (
                               select
                                   (qry.noude_50 + qry.noude_100) - qry.ArvestatudPaevaraamatus as vahe,
                                   *
                               from
                                   lapsed.ebatoenaolised(l_rekv_id, '2024-09-30') qry
                           )                       qry
                               inner join docs.doc d on d.id = qry.doc_id

                       where
                           vahe < 0
--                       and qry.doc_id = 4539722

                   )
        loop
            -- ищем проводки, которые не связаны со счетом
            FOR v_journal IN (
                                 SELECT
                                     array_agg(id) as new_docs
                                 FROM
                                     cur_journal
                                 WHERE
                                       rekvid = l_rekv_id
                                   and kpv < '2024-09-30'
                                   AND deebet = '605030'
                                   AND kreedit like '103009%'
                                   and (selg like 'Ebatõenäolised nõuded%' or selg like 'Ebatoenaolised nouded%')
                                   and dok = 'Arve nr.' || v_arved.number::text
                                   and id not in (
                                                     select unnest(v_arved.docs_ids)
                                                 )
                             )

                LOOP


                    UPDATE docs.doc
                    SET docs_ids   = docs_ids || v_journal.new_docs
                    WHERE id = v_arved.doc_id;

                END LOOP;

        end loop;

    RAISE NOTICE 'l_kokku %', l_kokku;
    RETURN l_count;

END ;

$$;

SELECT lapsed.link_ebatoenaolised(id)
from ou.rekv
where parentid = 119
and id not in (66,67);

DROP FUNCTION IF EXISTS lapsed.link_ebatoenaolised();

