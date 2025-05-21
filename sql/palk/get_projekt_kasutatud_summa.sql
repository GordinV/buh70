DROP FUNCTION IF EXISTS palk.get_projekt_kasutatud_summa(INTEGER, INTEGER, DATE);
DROP FUNCTION IF EXISTS palk.get_projekt_kasutatud_summa(INTEGER, INTEGER, DATE, TEXT);
DROP FUNCTION IF EXISTS palk.get_projekt_kasutatud_summa_(INTEGER, INTEGER, DATE, TEXT);

CREATE FUNCTION palk.get_projekt_kasutatud_summa(l_leping_id integer, l_projekt_id INTEGER,
                                                  l_kpv date default current_date, l_liik text default 'summa')
    RETURNS NUMERIC
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_summa NUMERIC(12, 2) = 0;
    v_proj  record;
BEGIN
    select
        kood,
        rekvid
    into v_proj
    from
        libs.library
    where
        id = l_projekt_id;

    if l_liik = 'summa' then
        SELECT
            sum(po.summa) as summa
        into l_summa
        from
            palk.palk_oper po
        where
              lepingid = l_leping_id
          and kpv <= l_kpv
              -- только начисления
          and po.libid in (
                              select
                                  pl.id
                              from
                                  libs.library pl
                              where
                                    pl.rekvid = v_proj.rekvid
                                and (pl.properties::jsonb ->> 'liik')::integer = 1
                          )
              -- включая округления
          and po.kood2 = '60'
          and po.proj = v_proj.kood;
    else
        SELECT
            sum(po.summa) as summa
        into l_summa
        from
            palk.palk_oper po
        where
              lepingid = l_leping_id
          and kpv <= l_kpv
              -- только начисления
          and po.libid in (
                              select
                                  pl.id
                              from
                                  libs.library pl
                              where
                                    pl.rekvid = v_proj.rekvid
                                and ((pl.properties::jsonb ->> 'liik')::integer = 5
                                  or (pl.properties::jsonb ->> 'liik')::integer = 7 and
                                     (pl.properties::jsonb ->> 'asutusest')::boolean)
                          )
              -- включая округления
          and po.kood2 = '60'
          and po.proj = v_proj.kood;

    end if;

    RETURN coalesce(l_summa, 0);

END
$$;


GRANT EXECUTE ON FUNCTION palk.get_projekt_kasutatud_summa(INTEGER,INTEGER, DATE, TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_projekt_kasutatud_summa(INTEGER, INTEGER,DATE, TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.get_projekt_kasutatud_summa(INTEGER, INTEGER,DATE, TEXT) TO dbvaatleja;


/*
SELECT palk.get_projekt_kasutatud_summa_(38972, 284445,DATE(2025,03,31), 'summa'),
palk.get_projekt_kasutatud_summa(38972, 284445,DATE(2025,03,31), 'summa'),
palk.get_projekt_kasutatud_summa_(38972, 284445,DATE(2025,03,31), 'sm'),
palk.get_projekt_kasutatud_summa(38972, 284445,DATE(2025,03,31), 'sm')
*/