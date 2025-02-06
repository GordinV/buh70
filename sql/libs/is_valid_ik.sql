DROP FUNCTION IF EXISTS libs.is_valid_ik(text);

CREATE FUNCTION libs.is_valid_ik(ik text)
    RETURNS BOOLEAN
    LANGUAGE SQL
AS
$$
select
    case
        when  palk.get_sunnipaev(ik:: TEXT) = current_date  then false
        when len(ik) <> 11 then false
        when left(ik, 1) not in ('3', '4', '5', '6') then false
        else true
        end;

$$;

GRANT EXECUTE ON FUNCTION libs.is_valid_ik(text) TO arvestaja;
GRANT EXECUTE ON FUNCTION libs.is_valid_ik(text) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION libs.is_valid_ik(text) TO dbkasutaja;

select libs.is_valid_ik('37303023721')
union all
select libs.is_valid_ik('87303023721')
union all
select libs.is_valid_ik('30000000010')
union all
select libs.is_valid_ik('00000000010')
union all
select libs.is_valid_ik('48707053722')
union all
select libs.is_valid_ik('61309190283')

;


