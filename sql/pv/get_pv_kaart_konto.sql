DROP FUNCTION IF EXISTS libs.get_pv_kaart_konto(l_pv_kaart_id INTEGER, l_kpv DATE);
DROP FUNCTION IF EXISTS libs.get_pv_kaart_konto(l_pv_kaart_id INTEGER, l_kpv DATE, text);

CREATE OR REPLACE FUNCTION libs.get_pv_kaart_konto(l_pv_kaart_id INTEGER, l_kpv DATE DEFAULT current_date, l_konto text default null)
    RETURNS text
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_pk record;

begin

    WITH
        kas_exists as (
            select
                case
                    when l_konto is null then true
                    when l_konto is not null and exists (select id
                                                            from
                                                             docs.pv_oper po
                                                             where po.pv_kaart_id = l_pv_kaart_id
                                                             and po.kood3 in ('13','14')
                                                             and po.kpv >= l_kpv) then true -- не надо искать, берем из карточки
                    else false -- используем переданное конто
                end as kas_olemas
                      ),
        pv_kaart AS (
                        SELECT
                            l.id,
                            case
                                when po13.kpv is not null and po13.kpv > l_kpv then po13.konto
                                when po14.kpv is not null and po14.konto is not null and po14.kpv > l_kpv then po14.konto
                                when po14.kpv is not null and po14.konto is null then '154000'
                                when po13.kpv is not null and po14.kpv is not null
                                         and po13.kpv < po14.kpv
                                    and po13.kpv > l_kpv
                                    then po13.konto
                                when po13.kpv is not null and po14.kpv is not null
                                    and po13.kpv > po14.kpv
                                    and po13.kpv < l_kpv
                                    then po14.konto

                                else l.properties::JSONB ->> 'konto'
                                end  as konto,
                            po13.kpv as kpv_13,
                            po14.kpv as kpv_14,
                            po13.konto as po13_konto,
                            po14.konto as po14_konto
                        FROM
                            kas_exists,
                            libs.library          l
                                left outer join (
                                                    select
                                                        po.pv_kaart_id,
                                                        po.properties ->> 'konto' as konto,
                                                        po.kpv
                                                    from
                                                        docs.pv_oper po
                                                    where
                                                          po.pv_kaart_id = l_pv_kaart_id
                                                      and po.liik = 6
                                                      and po.kood3 = '13'
                                                    order by kpv desc
                                                    limit 1
                                                ) po13 on po13.pv_kaart_id = l.id
                                left outer join (
                                                    select
                                                        po.pv_kaart_id,
                                                        coalesce(po.properties ->> 'konto',case when po.kpv <= l_kpv then po.konto   else '154000' end) as konto,
                                                        po.kpv
                                                    from
                                                        docs.pv_oper po
                                                    where
                                                          po.pv_kaart_id = l_pv_kaart_id
                                                      and po.liik = 6
                                                      and po.kood3 = '14'
                                                    order by kpv desc
                                                    limit 1
                                                ) po14 on po14.pv_kaart_id = l.id
                        WHERE kas_exists.kas_olemas
                            and l.id = l_pv_kaart_id
        )
    SELECT *
    into v_pk
    from
        pv_kaart pk;

    RETURN coalesce(v_pk.konto, coalesce(l_konto,''));
END ;

$$;

GRANT EXECUTE ON FUNCTION libs.get_pv_kaart_konto( INTEGER, DATE, text) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION libs.get_pv_kaart_konto( INTEGER, DATE, text) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION libs.get_pv_kaart_konto( INTEGER, DATE, text) TO dbkasutaja;


SELECT
    libs.get_pv_kaart_konto(id, '2024-09-01'::date)
from
    libs.library
where
      kood = '00536-01KM'
  and library = 'POHIVARA'
  and rekvid = 130


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