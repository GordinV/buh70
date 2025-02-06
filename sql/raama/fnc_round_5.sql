DROP FUNCTION IF EXISTS fnc_round_5(NUMERIC);

CREATE FUNCTION fnc_round_5(IN l_summa numeric,
                            OUT l_round_summa numeric(14, 2))
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_mod   numeric = round(mod(l_summa, 1), 2);
    l_diff  numeric = 0;
    l_scale integer = scale(l_mod);
    l_num integer = 0;
    l_multiply integer = 5;
BEGIN

    if l_scale <= 1 then
        -- десятки. ничего не округляем
        l_diff = 0;
    else
        l_num = right(l_mod::text,1)::integer;
        l_multiply = case
            when l_num in (1, 2, 6, 7) then -1
            else 1  end;
        l_diff = (case
            when l_num in (1, 2) then l_num
            when l_num in (3,4, 6, 7) then abs(5 - l_num)
            when l_num in (8,9) then abs(10 - l_num)
            end)  * 0.01 * l_multiply;
     end if;

    l_round_summa = coalesce(l_summa,0) + coalesce(l_diff,0);
    RETURN;
END;
$$;

GRANT EXECUTE ON FUNCTION fnc_round_5(NUMERIC) TO dbvaatleja;

select fnc_round_5(17.17), fnc_round_5(10.17), fnc_round_5(10.32), fnc_round_5(10.36),
       fnc_round_5(10.38), fnc_round_5(10.39), fnc_round_5(10.08);
