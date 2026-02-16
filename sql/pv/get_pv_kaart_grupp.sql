DROP FUNCTION IF EXISTS libs.get_pv_kaart_grupp(l_pv_kaart_id INTEGER, l_kpv DATE);

CREATE OR REPLACE FUNCTION libs.get_pv_kaart_grupp(l_pv_kaart_id INTEGER, l_kpv DATE DEFAULT current_date)
    RETURNS integer
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_pk record;

begin

    with
        params as (
                      select
                          l_kpv::date   as kpv,
                          l_pv_kaart_id as pv_kaart_id
                  ),
        kas_exists as (
                      select
                          coalesce((
                                       select
                                           po.kood3 as rv
                                       from
                                           docs.pv_oper po
                                       where
                                             po.pv_kaart_id = p.pv_kaart_id
                                         and po.kood3 in ('13', '14')
                                         and po.kpv > p.kpv
                                         and po.liik = 6 -- переквалификация
                                       order by po.kpv
                                       limit 1
                                   )::text, '01') as jargmine_rv

                      from
                          params p
                  ),
        pv_kaart as (

                      SELECT
                          l.id,
                          case
                              when kas_exists.jargmine_rv = '13'
                                  and l.properties::jsonb ->> 'prev_gruppid' is not null
                                  then l.properties::jsonb ->> 'prev_gruppid'
                              else l.properties::jsonb ->> 'gruppid'
                              end::integer as pv_grupp_id,
                          kas_exists.jargmine_rv
                      FROM
                          libs.library l
                              JOIN params p ON l.id = p.pv_kaart_id
                              CROSS JOIN kas_exists
                  )

    SELECT
        pk.pv_grupp_id, jargmine_rv
    into v_pk
    from
        pv_kaart pk;

    raise notice 'jargmine_rv %', v_pk.jargmine_rv;

    RETURN v_pk.pv_grupp_id;
END ;

$$;

GRANT EXECUTE ON FUNCTION libs.get_pv_kaart_grupp( INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION libs.get_pv_kaart_grupp( INTEGER, DATE) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION libs.get_pv_kaart_grupp( INTEGER, DATE) TO dbkasutaja;

select libs.get_pv_kaart_grupp(250127, '2025-10-31');


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