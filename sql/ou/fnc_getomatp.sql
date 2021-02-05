DROP FUNCTION IF EXISTS fnc_getomatp(INTEGER, INTEGER);

CREATE FUNCTION fnc_getomatp(l_rekvid INTEGER, l_aasta INTEGER)
    RETURNS CHARACTER
    LANGUAGE plpgsql
AS
$_$
DECLARE
    lcOmaTp CHARACTER(20);
BEGIN
    lcOmaTp = '185101';

    SELECT TP INTO lcOmaTp FROM ou.Aa WHERE Aa.parentid = l_rekvid AND Aa.kassa = 2 ORDER BY ID DESC LIMIT 1;

    lcOmaTp = coalesce(lcOmaTp, '');
    RETURN lcOmaTp;
END;

$_$;


