DROP FUNCTION IF EXISTS libs.get_pv_kaart_konto(l_pv_kaart_id INTEGER, l_kpv DATE);
DROP FUNCTION IF EXISTS libs.get_pv_kaart_konto(l_pv_kaart_id INTEGER, l_kpv DATE, text);

CREATE OR REPLACE FUNCTION libs.get_pv_kaart_konto(l_pv_kaart_id INTEGER, l_kpv DATE DEFAULT current_date,
                                                    l_konto text default null)
    RETURNS text
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_konto text;
BEGIN

    SELECT
        case
            when po14.kpv is not null and po14.kpv = p.kpv then po14.konto
            when po13.kpv is not null and po13.kpv = p.kpv then po13.konto
            when po19.kpv is not null and po19.kpv = p.kpv then po19.konto

            -- 00 -> 14 возврат из инвестиций в ОС в периоде
            when po14.kpv is not null
                and po14.kpv > p.kpv
                and po19.kpv is null
                and po13.kpv is null then '154000'

            when po19.kpv is not null and po19.kpv > p.kpv
                and (po13.kpv is null or po13.kpv > p.kpv)
                and (po14.kpv is null or po14.kpv > p.kpv)
                then po19.konto

            -- постановка на 19
            when po19.kpv is not null
                and po19.kpv > p.kpv
                and po14.kpv is not null
                and po14.kpv < p.kpv -- был перевод в ОС
                and po14.kpv > po19.kpv
                and (po13.kpv is null or po13.kpv > po14.kpv) then po19.konto

            -- переквалификация с 19 -> 14 ->13 поток
            when po19.kpv is not null
                and po19.kpv < p.kpv
                and po14.kpv is not null
                and po14.kpv < p.kpv
                and po14.kpv > po19.kpv
                and po13.kpv is not null
                and po13.kpv < p.kpv -- запрос после инвестиций
                and po13.kpv > po14.kpv -- был перевод из ОС в инвестиции
                then po13.konto

            -- переквалификация с 19 на 14 поток
            when po19.kpv is not null
                and po19.kpv < p.kpv
                and po14.kpv is not null
                and po14.kpv < p.kpv -- был перевод в ОС
                and po14.kpv > po19.kpv
                and (po13.kpv is null or po13.kpv > p.kpv) then po14.konto

            when po19.kpv is not null
                and po19.kpv < p.kpv
                and po14.kpv is not null
                and po14.kpv > po19.kpv
                and po14.kpv > p.kpv -- до перевода в ОС (154000)
                then po19.konto

            -- 14->13
            when po14.kpv is not null
                and po13.kpv is not null
                and po19.konto is null
                and po13.kpv > po14.kpv -- последняя операция в инвестиции, т.е. 154000
                and po13.kpv < p.kpv
                then po13.konto
            -- 00 13 --> 14
            when po14.kpv is not null
                and po13.kpv is not null
                and po13.kpv < po14.kpv
                and po14.kpv > p.kpv
                and po13.kpv < p.kpv -- investeering
                then po13.konto
            -- 14
            when po14.kpv is not null
                and po13.kpv is not null
                and p.kpv > po14.kpv and
                 p.kpv < po13.kpv
                then po14.konto

            -- 00 -> 13
            when po14.kpv is null
                and po19.kpv is null
                and po13.kpv is not null
                and po13.kpv > p.kpv
                and po13.eelmine_konto is not null then
                po13.eelmine_konto

            -- 00 (13)
            when po13.kpv is not null
                and po13.kpv < p.kpv
                and po14.kpv is not null
                and po14.konto is not null
                and po14.kpv > p.kpv
                then po13.konto

            -- vanad
            when po13.kpv is not null and po13.kpv > p.kpv then po13.korr_konto
            when po14.kpv is not null and po14.konto is not null and po14.kpv > p.kpv
                then po14.konto
            when po14.kpv is not null and po14.konto is null then '154000'
            when po13.kpv is not null and po14.kpv is not null
                and po13.kpv < po14.kpv
                and po13.kpv > p.kpv
                then po13.konto
            when po13.kpv is not null and po14.kpv is not null
                and po13.kpv > po14.kpv
                and po13.kpv < p.kpv
                and po13.konto <> po14.konto
                then po14.konto
            when po13.konto = po14.konto
                and po13.kpv > po14.kpv
                and po13.kpv < p.kpv then
                '154000'
            when po13.konto = po14.konto
                and po13.kpv > po14.kpv
                and po13.kpv > p.kpv then
                po13.konto
            else
                coalesce(
                    (
                        select o.konto
                        from docs.pv_oper o
                        where o.pv_kaart_id = l.id
                          and o.liik = 6
                          and o.kpv <= p.kpv
                        order by id desc
                        limit 1
                    ),
                    (
                        select o.properties ->> 'konto'
                        from docs.pv_oper o
                        where o.pv_kaart_id = l.id
                          and o.liik = 6
                          and o.kpv > p.kpv
                          and o.properties ->> 'konto' is not null
                        order by o.kpv asc
                        limit 1
                    ),
                    l.properties::JSONB ->> 'konto'
                )
            end
    INTO v_konto
    FROM
        libs.library l
        CROSS JOIN (SELECT l_kpv as kpv) p
        LEFT JOIN LATERAL (
            select
                po.properties ->> 'konto'      as eelmine_konto,
                '154000'                       as konto,
                po.properties ->> 'korr_konto' as korr_konto,
                po.kpv
            from
                docs.pv_oper po
            where
                  po.pv_kaart_id = l.id
              and po.liik = 6
              and po.kood3 = '13'
            order by kpv desc
            limit 1
        ) po13 ON true
        LEFT JOIN LATERAL (
            select
                coalesce(case
                             when po.journalid is not null and exists
                             (
                                 select
                                     1
                                 from
                                     docs.journal                 j
                                         inner join docs.journal1 j1 on j.id = j1.parentid
                                 where
                                     j.parentid = po.journalid
                             ) then
                                 (
                                     select
                                         j1.deebet
                                     from
                                         docs.journal                 j
                                             inner join docs.journal1 j1 on j.id = j1.parentid
                                     where
                                           j.parentid = po.journalid
                                       and kreedit = '154000'
                                     limit 1
                             )

                             when po.kpv = p.kpv
                                 then po.properties ->> 'korr_konto'
                             else po.properties ->> 'konto' end, case
                                                                     when po.kpv = p.kpv
                                                                         then po.properties ->> 'korr_konto'
                                                                     when po.kpv <= p.kpv
                                                                         then po.konto
                                                                     else '154000' end) as konto,
                po.konto                                                                as korr_konto,
                po.kpv
            from
                docs.pv_oper po
            where
                  po.pv_kaart_id = l.id
              and po.liik = 6
              and po.kood3 = '14'
            order by kpv desc
            limit 1
        ) po14 ON true
        LEFT JOIN LATERAL (
            select
                case
                    when po.journalid is not null and exists
                    (
                        select
                            1
                        from
                            docs.journal                 j
                                inner join docs.journal1 j1 on j.id = j1.parentid
                        where
                              j.parentid = po.journalid
                          and j1.kood3 = '19'
                    ) then
                        (
                            select
                                j1.deebet
                            from
                                docs.journal                 j
                                    inner join docs.journal1 j1 on j.id = j1.parentid
                            where
                                  j.parentid = po.journalid
                              and j1.kood3 = '19'
                            limit 1
                    )
                    else
                        '154000' end as konto,
                null                 as korr_konto,
                po.kpv
            from
                docs.pv_oper po
            where
                  po.pv_kaart_id = l.id
              and po.liik = 1
              and po.kood3 = '19'
            order by kpv desc
            limit 1
        ) po19 ON true
    WHERE
        l.id = l_pv_kaart_id
        AND (
            l_konto IS NULL OR
            EXISTS (
                SELECT 1 FROM docs.pv_oper po
                WHERE po.pv_kaart_id = l.id
                  AND po.kood3 IN ('13', '14')
                  AND po.kpv >= p.kpv
            )
        );

    RETURN coalesce(v_konto, l_konto, '');
END ;

$$;

GRANT EXECUTE ON FUNCTION libs.get_pv_kaart_konto( INTEGER, DATE, text) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION libs.get_pv_kaart_konto( INTEGER, DATE, text) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION libs.get_pv_kaart_konto( INTEGER, DATE, text) TO dbkasutaja;

select libs.get_pv_kaart_konto(287321, '2025-06-27');


/*SELECT
    kood,
    libs.get_pv_kaart_konto(id, '2025-01-01'::date)
from
    libs.library
where
      kood in ('01784-08PH','02328-01KM','02328-02KK', 'IMM156200-1','IMM156600-4','01784-02PH')
  and library = 'POHIVARA'
  and rekvid in (130,28)
*/

/*
83 ms, fetching: 76 ms
select *
from
    libs.library
where
      kood = '00171-02KK'
  and library = 'POHIVARA'
  and rekvid = 130

select * from libs.get_pv_kaart_jaak(273574, '2024-01-01'::date)
select * from docs.pv_oper where pv_kaart_id = 208148 and kood3 = '14'
*/