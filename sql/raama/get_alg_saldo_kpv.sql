DROP FUNCTION IF EXISTS docs.get_alg_saldo_kpv(DATE, DATE, DATE, DATE);

CREATE FUNCTION docs.get_alg_saldo_kpv(l_alg_saldo_kpv DATE, l_doc_kpv DATE, l_kpv1 DATE, l_kpv2 DATE)
    RETURNS DATE
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_kpv DATE = l_doc_kpv;
BEGIN
    -- нач сальдо
    IF (l_kpv1 > l_doc_kpv)
    THEN
        l_kpv = l_doc_kpv;
    ELSIF
        l_kpv1 = l_doc_kpv
    THEN
-- дата проводки совпадает с датой нач. периода запроса. напр 01.01
        l_kpv = coalesce(l_alg_saldo_kpv, l_doc_kpv);
    ELSIF
        l_kpv1 < l_doc_kpv AND l_kpv2 >= coalesce(l_alg_saldo_kpv, l_doc_kpv)
    THEN
        -- конец периода на дату сальдо (напр. 31.12)
        l_kpv = l_doc_kpv;
    ELSE
        l_kpv = l_doc_kpv;
    END IF;
    RETURN l_kpv;
END;
$$;

GRANT EXECUTE ON FUNCTION docs.get_alg_saldo_kpv(DATE, DATE, DATE, DATE) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.get_alg_saldo_kpv(DATE, DATE, DATE, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.get_alg_saldo_kpv(DATE, DATE, DATE, DATE) TO dbpeakasutaja;


/*
select docs.get_alg_saldo_kpv('2019-12-31'::DATE, '2020-01-01'::DATE, '2020-01-01'::DATE, '2020-01-31'::DATE)
select docs.get_alg_saldo_kpv(NULL::DATE, '2019-01-01'::DATE, '2020-01-01'::DATE, '2020-01-31'::DATE)
select docs.get_alg_saldo_kpv('2019-12-31'::DATE, '2020-01-01'::DATE, '2020-01-05'::DATE, '2020-01-31'::DATE)
select docs.get_alg_saldo_kpv('2019-12-31'::DATE, '2020-01-01'::DATE, '2019-12-31'::DATE, '2020-01-31'::DATE)
select docs.get_alg_saldo_kpv('2019-12-31'::DATE, '2020-01-01'::DATE, '2019-01-01'::DATE, '2019-12-31'::DATE)

 */