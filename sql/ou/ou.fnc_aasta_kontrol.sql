CREATE OR REPLACE FUNCTION ou.fnc_aasta_kontrol(l_rekvid INTEGER, l_kpv DATE DEFAULT current_date) RETURNS BOOLEAN
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_aasta INTEGER = year(coalesce(l_kpv, current_date));
    l_kuu   INTEGER = month(coalesce(l_kpv, current_date));
BEGIN
    IF NOT exists(
            SELECT a.id
            FROM ou.aasta a
            WHERE a.kuu = date_part('month', l_kpv)
              AND a.aasta = date_part('year', l_kpv)
              AND a.rekvid = l_rekvid)
    THEN
        INSERT INTO ou.aasta (rekvid, "aasta", kuu, kinni)
        VALUES (l_rekvid, l_aasta, l_kuu, 0);
    END IF;

    IF exists(
            SELECT a.id
            FROM ou.aasta a
            WHERE a.kuu = date_part('month', l_kpv)
              AND a.aasta = date_part('year', l_kpv)
              AND a.rekvid = l_rekvid
              AND a.kinni = 1)
    THEN
        --    RAISE EXCEPTION 'Ei tohi selles periodis töötada';
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;

END
$$;

ALTER FUNCTION ou.fnc_aasta_kontrol(INTEGER, DATE) OWNER TO vlad;

GRANT EXECUTE ON FUNCTION ou.fnc_aasta_kontrol(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION ou.fnc_aasta_kontrol(INTEGER, INTEGER) TO dbkasutaja;
