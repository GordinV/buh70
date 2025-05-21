--DROP FUNCTION IF EXISTS palk.get_isiku_pohipalk(jsonb);

CREATE or replace FUNCTION palk.get_isiku_pohipalk(params jsonb default null)
    RETURNS numeric
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_summa      numeric = 0;
    l_projekt_id integer = (params ->> 'projekt_id')::integer;
    l_seisuga    date    = (params ->> 'seisuga');
    l_leping_id  integer = (params ->> 'leping_id')::integer;
    l_isik_id    integer = (params ->> 'isik_id')::integer;
    l_rekv_id    integer = (params ->> 'rekv_id')::integer;
    l_amet_id    integer = (params ->> 'amet_id')::integer;
    l_klassif    jsonb   = (params -> 'ameti_klassif');
    l_palga_maar integer = (params ->> 'palgamaar')::integer;

BEGIN
    -- lepingid
    l_summa =
            case
                when l_projekt_id is not null and l_leping_id is not null then
                    -- вернем часть суммы по проекту
                    (
                        with
                            params as (
                                          select
                                              l_seisuga::date as seisuga,
                                              l_projekt_id    as projekt_id,
                                              l_leping_id     as leping_id
                            )

                        select
                            case
                                when make_date(year(arv.proj_kuni), month(arv.proj_kuni), 01) =
                                     make_date(year(arv.seisuga), month(arv.seisuga), 01) then
                                    -- последний период, берем только остаток
                                    (arv.summa_kokku - arv.kasutatud_kokku)
                                when (arv.kuu_summa * arv.kokku_periodid - arv.kasutatud_summa) >
                                     (arv.summa_kokku - arv.kasutatud_kokku) then
                                    (arv.summa_kokku - arv.kasutatud_kokku)
                                else
                                    (arv.kuu_summa * arv.kokku_periodid - arv.kasutatud_summa) end summa

                        from
                            (
                                select
                                    kuu_summa,
                                    (pl.summa + pl.korrigeerimine)                   as summa_kokku,
                                    palk.get_projekt_kasutatud_summa(params.leping_id:: integer,
                                                                     params.projekt_id:: INTEGER,
                                                                     (p.properties::JSONB ->> 'proj_kuni')::DATE,
                                                                     'summa':: text) as kasutatud_kokku,
                                    palk.get_projekt_kasutatud_summa(params.leping_id:: integer,
                                                                     params.projekt_id:: INTEGER,
                                                                     params.seisuga:: date,
                                                                     'summa':: text) as kasutatud_summa,
                                    ((params.seisuga - (p.properties::JSONB ->> 'proj_alates')::DATE)::numeric /
                                     30::numeric)::integer                           as kokku_periodid,
                                    (p.properties::JSONB ->> 'proj_kuni')::DATE      as proj_kuni,
                                    params.seisuga                                   as seisuga
                                from
                                    libs.proj_laiendus          pl
                                        inner join libs.library p on p.id = pl.proj_id,
                                                                params
                                where
                                      pl.leping_id = params.leping_id
                                  and (p.properties::JSONB ->> 'proj_kuni')::DATE >=
                                      coalesce(params.seisuga, current_date)
                                  and p.id = params.projekt_id
                            ) arv
                )
                when l_projekt_id is null and l_leping_id is not null then
                    (
                        select
                            t.palk
                        from
                            palk.tooleping t
                        where
                            t.id = l_leping_id
                )
                when l_klassif is not null and l_palga_maar is not null then
                    (
                        select
                            (elem ->> 'summa')::numeric
                        from
                            (
                                with
                                    json_array as (
                                                      select
                                                          a.properties::jsonb -> 'palgaastmed' as elements
                                                      from
                                                          libs.library a
                                                      where
                                                            a.library = 'AMETI_KLASSIF'
                                                        and a.status = 1
                                                        and to_jsonb(a.kood::text) = l_klassif
--                                                        and a.properties::jsonb -> 'palgaastmed' @>
--                                                            ('[]'::jsonb || jsonb_build_object('palgamaar', l_palga_maar::text))
                                    )
                                SELECT
                                    jsonb_array_elements(json_array.elements) as elem
                                FROM
                                    json_array
                            ) qry
                        where
                            (elem ->> 'palgamaar')::integer = l_palga_maar::integer
                )

                when l_isik_id is not null then
                    (
                        select
                            t.palk
                        from
                            palk.tooleping t
                        where
                              t.parentid = l_isik_id
                          and (t.rekvid = l_rekv_id or l_rekv_id is null)
                          and (t.ametid = l_amet_id or l_amet_id is null)
                          and (to_jsonb(l_klassif) ? LEFT(t.properties ->> 'ameti_klassif', 3) OR l_klassif IS NULL)
                        order by coalesce(t.lopp, current_date) desc, t.pohikoht desc, t.palk desc
                        limit 1
                )
                else 0
                end;
    RETURN coalesce(l_summa, 0);
END;

$$;

GRANT EXECUTE ON FUNCTION palk.get_isiku_pohipalk(jsonb) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_isiku_pohipalk(jsonb) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.get_isiku_pohipalk(jsonb) TO dbvaatleja;

select
    palk.get_isiku_pohipalk('{
      "projekt_id": 282919,
      "leping_id": 6,
      "seisuga": "2025-12-31",
      "-isik_id": 25436,
      "-amet_id": 248273,
      "-ameti_klassif": "KJ2-RE-JAH",
      "-palgamaar": 4
    }'::jsonb)

/*
      "ameti_klassif": [
        "HKP",
        "KJ1",
        "KJ2-RE-JAH"
      ],


-- Koolituskulud -> NOM
-- TUNNUS ->>test 3


SELECT *
FROM jsonb_to_recordset(get_palk_lib_kasutus(149605, '2019-12-31'::DATE))
         AS x (error_message TEXT, error_code integer);

select * from libs.library where kood = 'PALK5'

 SELECT DISTINCT
                    'Dok avans nr.:' || ltrim(rtrim(m.number)) || ' (' || ltrim(rtrim(r.nimetus)) || ')' AS dok_nr
                FROM docs.avans1 m
                INNER JOIN docs.avans2 m1 ON m.id = m1.parentid
                INNER JOIN ou.rekv r ON m.rekvid = r.id
                WHERE m.kpv > '2019-12-31'
              AND ltrim(rtrim(m1.kood2)) = '70'

*/

