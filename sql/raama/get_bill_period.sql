DROP FUNCTION IF EXISTS docs.get_arve_period(INTEGER);

CREATE OR REPLACE FUNCTION docs.get_arve_period(l_arve_id INTEGER)
    RETURNS date AS
$BODY$


DECLARE
    l_kpv   date = current_date;
BEGIN
    -- получить дату счета
    l_kpv = (SELECT a.kpv FROM docs.arv a WHERE a.parentid = l_arve_id);

    -- вычислить период услуги
    l_kpv = make_date(year(l_kpv), month(l_kpv),1);

    RETURN l_kpv;

END;


$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.get_arve_period(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.get_arve_period(INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.get_arve_period(INTEGER) TO dbvaatleja;

/*
SELECT docs.get_avans_jaak(parentid)
FROM docs.avans1

*/