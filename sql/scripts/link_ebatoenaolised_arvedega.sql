DROP FUNCTION IF EXISTS lapsed.link_ebatoenaolised();
DROP FUNCTION IF EXISTS lapsed.link_ebatoenaolised(integer);

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
                       inner join  lapsed.liidestamine l on l.docid = d.id

                       where
                           maksja_isikukood = '60102203741'
--                          vahe = 0
--                        qry.doc_id in (4589619)

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
                                   and kpv < '2024-10-31'
                                   AND deebet in ('605030','888888')
                                   AND kreedit like '103009%'
                                   and dok = 'Arve nr.' || v_arved.number::text
                                   and id not in (
                                                     select unnest(v_arved.docs_ids)
                                                 )
                                 and asutusid in (select id from libs.asutus where regkood = v_arved.maksja_isikukood)
                             )

                LOOP

                    raise notice 'found %',  v_arved.number;


                    UPDATE docs.doc
                    SET docs_ids   = docs_ids || v_journal.new_docs
                    WHERE id = v_arved.doc_id;

                END LOOP;

            -- дорасчет
            perform docs.ebatoenaolised(l_rekv_id, '2024-10-06'::date, v_arved.doc_id);


        end loop;

    RAISE NOTICE 'l_kokku %', l_kokku;
    RETURN l_count;

END ;

$$;

SELECT lapsed.link_ebatoenaolised(id)
from ou.rekv
where parentid = 119
  and id = 99
and id not in (66,67);

DROP FUNCTION IF EXISTS lapsed.link_ebatoenaolised();
DROP FUNCTION IF EXISTS lapsed.link_ebatoenaolised(integer);

