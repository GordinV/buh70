DROP FUNCTION IF EXISTS ou.fnc_aasta_kontrol(INTEGER, DATE);

CREATE OR REPLACE FUNCTION ou.fnc_aasta_kontrol(l_rekvid INTEGER, l_kpv DATE)
    RETURNS BOOLEAN AS
$BODY$

BEGIN
    IF NOT exists(
            SELECT a.id FROM ou.aasta a WHERE a.kuu = date_part('month',l_kpv) AND a.aasta = date_part('year',l_kpv) AND a.rekvid = l_rekvid)
    THEN
        INSERT INTO ou.aasta (rekvid, "aasta", kuu, kinni)
        VALUES (l_rekvid, year(l_kpv), month(l_kpv), 0);
    END IF;

    IF exists(
            SELECT a.id
            FROM ou.aasta a
            WHERE a.kuu = date_part('month',l_kpv)
              AND a.aasta = date_part('year',l_kpv)
              AND a.rekvid = l_rekvid
              AND a.kinni = 1)
    THEN
        RAISE NOTICE 'exists';

        --    RAISE EXCEPTION 'Ei tohi selles periodis töötada';
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;

END
$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION ou.fnc_aasta_kontrol(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.fnc_aasta_kontrol(INTEGER, DATE) TO dbpeakasutaja;


/*
 select * from ou.aasta
 */