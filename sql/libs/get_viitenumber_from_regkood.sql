--DROP FUNCTION IF EXISTS lapsed.get_viitenumber(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION libs.get_viitenumber_from_regkood(IN l_rekv_id INTEGER, IN l_objekt_number text,
                                                             IN l_tyyp text default '', OUT data JSON)
AS
$BODY$
DECLARE
    l_rekv_osa     TEXT    = lpad(l_rekv_id::TEXT, 3, '0');
    l_dok_id       integer ;
    l_dok_id_osa   text;
    l_control      INTEGER;
    l_731          TEXT    = '137137137';
    l_multiple     INTEGER = 0;
    l_summa        INTEGER = 0;
    i              INTEGER = 1;
    l_saja         INTEGER; -- Lähim suurem kümnekordne (4)
    l_viitenumber  TEXT;
    v_dok_record   record;
    l_selg         text;
    l_rekv_nimetus text    = (
                                 select
                                     nimetus
                                 from
                                     ou.rekv
                                 where
                                     id = l_rekv_id
                                 limit 1
                             );
BEGIN


    -- 1. вид документа
    case
        when l_tyyp = '' or l_tyyp = '1' then -- vanemate tasu
        select
            id,
            isikukood,
            nimi
        into v_dok_record
        from
            lapsed.laps l
        where
              l.isikukood = l_objekt_number
          and staatus < 3
        order by id desc
        limit 1;

        l_viitenumber = lapsed.get_viitenumber(l_rekv_id, v_dok_record.id);

        when l_tyyp = '2' then -- get asutus
        select
            a.id,
            a.regkood,
            a.nimetus
        into v_dok_record
        from
            libs.asutus a
        where
              a.regkood = l_objekt_number
          and a.staatus < 3
        order by id desc
        limit 1;

        l_dok_id_osa = lpad(v_dok_record.id::TEXT, 6, '0');
        l_selg = 'Reg.kood:' || ltrim(rtrim(v_dok_record.regkood)) || ', Nimetus:' ||
                 ltrim(rtrim(v_dok_record.nimetus));


        when l_tyyp = '3' then select
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
                                     arv.number = l_objekt_number
                                 and d.status < 3
                                 and d.rekvid = l_rekv_id
                               order by arv.id desc
                               limit 1;

                               l_dok_id_osa = lpad(v_dok_record.id::TEXT, 8, '0');
                               l_selg = 'Arve number:' || ltrim(rtrim(v_dok_record.number)) ||
                                        ', arve kpv:' || v_dok_record.kpv ||
                                        ', asutus: ' || ltrim(rtrim(v_dok_record.asutus)) ||
                                        ', arve jääk:' || ltrim(rtrim(v_dok_record.jaak::text));

        else v_dok_record = null;

        end case;

    if l_viitenumber is null then
        -- структура
        l_viitenumber = l_tyyp || l_rekv_osa || l_dok_id_osa;
        -- должна быть длина 9 знаков, если меняется необходимо пометь 731

        -- перемножаем в цикле
        FOR i IN 1 .. length(l_731)
            LOOP
                l_multiple =
                        substring(l_viitenumber FROM i FOR 1)::INTEGER * substring(l_731 FROM i FOR 1)::INTEGER;
                l_summa = l_summa + l_multiple;
            END LOOP;

        -- arvestame Lähim suurem kümnekordne (4)
        l_saja = l_summa;
        WHILE right(l_saja::TEXT, 1) <> '0'
            LOOP
                l_saja = l_saja + 1;
            END LOOP;
        l_control = l_saja - l_summa;
        l_viitenumber = l_viitenumber || l_control::TEXT;
    end if;
    -- response
    -- ошибка, вернем ответ
    data = jsonb_build_object('error', (l_viitenumber is null),'error_description',(case when l_viitenumber is null then 'Puuduvad andmed' else null end),  'asutus', l_rekv_nimetus, 'viitenumber', l_viitenumber,
                              'selgitus', l_selg)::json;
    return;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION libs.get_viitenumber_from_regkood(INTEGER,text, text) TO public;

SELECT libs.get_viitenumber_from_regkood(66, '066-31426', '3')

