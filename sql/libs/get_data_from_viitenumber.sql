--DROP FUNCTION IF EXISTS lapsed.get_viitenumber(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION libs.get_data_from_viitenumber(IN l_viitenumber text,
                                                          OUT data JSON)
AS
$BODY$
DECLARE
    l_tyyp            text    = (
                                    select left(ltrim(rtrim(l_viitenumber)), 1)
    );
    l_dok_id          integer ;
    v_dok_record      record;
    l_selg            text;
    l_rekv_id         integer;
    l_rekv_nimetus    text;
    l_viitenumber_len integer;
    l_algotithm       text;
BEGIN
    -- 1. вид документа
    case
        when l_tyyp = '' or l_tyyp = '1' then -- vanemate tasu
        -- читаем первые 3 знака
            l_rekv_id = (
                            select
                                id
                            from
                                ou.rekv
                            where
                                id = (left(l_viitenumber, 3)::integer)
                        );
            l_dok_id = lapsed.get_laps_from_viitenumber(l_viitenumber);

            select
                nimi
            into v_dok_record
            from
                lapsed.laps l
            where
                  l.id = l_dok_id
              and staatus < 3
            order by id desc
            limit 1;

            l_algotithm = 'Vanemate tasu';

        when l_tyyp = '2' then -- get asutus
        l_viitenumber_len = len(ltrim(rtrim(l_viitenumber))) - 1 - 3 - 1;
        l_rekv_id = (
                        select
                            id
                        from
                            ou.rekv
                        where
                            id = (substr(l_viitenumber, 2, 3)::integer)
                    );

        l_dok_id = (substr(l_viitenumber, 5, l_viitenumber_len));
        l_algotithm = 'Asutused';

        select
            a.id,
            a.regkood,
            a.nimetus
        into v_dok_record
        from
            libs.asutus a
        where
              a.id = l_dok_id
          and a.staatus < 3
        order by id desc
        limit 1;

        if v_dok_record.id is null then
            -- not found
            l_dok_id = null;
        end if;

        l_selg = 'Reg.kood:' || ltrim(rtrim(v_dok_record.regkood)) || ', Nimetus:' ||
                 ltrim(rtrim(v_dok_record.nimetus));


        when l_tyyp = '3' then l_viitenumber_len = len(ltrim(rtrim(l_viitenumber))) - 1 - 3 - 1;
                               l_algotithm = 'Arve number';
                               l_dok_id = (substr(l_viitenumber, 5, l_viitenumber_len));
                               l_rekv_id = (
                                               select
                                                   id
                                               from
                                                   ou.rekv
                                               where
                                                   id = (substr(l_viitenumber, 2, 3)::integer)
                                           );


                               raise notice 'l_tyyp %, l_dok_id %, l_viitenumber_len %, l_viitenumber %',l_tyyp, l_dok_id, l_viitenumber_len, l_viitenumber;

                               select
                                   d.id,
                                   ltrim(rtrim(arv.number))       as number,
                                   to_char(arv.kpv, 'DD.MM.YYYY') as kpv,
                                   arv.summa,
                                   arv.jaak,
                                   arv.tasud,
                                   a.regkood,
                                   a.nimetus                      as asutus
                               into v_dok_record

                               from
                                   docs.doc                        d
                                       inner join      docs.arv    arv on arv.parentid = d.id
                                       left outer join libs.asutus a on arv.asutusid = a.id
                               where
                                     d.id = l_dok_id
                                 and d.status < 3
                                 and d.rekvid = l_rekv_id
                               order by arv.id desc
                               limit 1;

                               if v_dok_record.id is null then
                                   -- not found
                                   l_dok_id = null;
                               end if;


                               l_selg = 'Arve number:' || ltrim(rtrim(v_dok_record.number)) ||
                                        ', arve kpv:' || v_dok_record.kpv ||
                                        ', asutus: ' || ltrim(rtrim(v_dok_record.asutus)) ||
                                        ', arve jääk:' || ltrim(rtrim(v_dok_record.jaak::text));

        else v_dok_record = null;

        end case;

    l_rekv_nimetus = (
                         select nimetus
                         from ou.rekv
                         where id = l_rekv_id
                     );

    raise notice 'final l_dok_id %',l_dok_id;

    -- response
    -- ошибка, вернем ответ
    data = jsonb_build_object('error', (l_dok_id is null), 'error_description',
                              (case when l_dok_id is null then 'Puuduvad andmed' else null end), 'asutus',
                              l_rekv_nimetus,
                              'selgitus', l_selg)::json;
    return;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION libs.get_data_from_viitenumber(text) TO public;

SELECT libs.get_data_from_viitenumber('3066087775166')

