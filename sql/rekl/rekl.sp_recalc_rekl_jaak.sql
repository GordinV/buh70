DROP FUNCTION IF EXISTS rekl.sp_recalc_rekl_jaak(IN user_id INTEGER, IN params JSON);

CREATE FUNCTION rekl.sp_recalc_rekl_jaak(IN user_id INTEGER, IN params JSON, OUT result INTEGER,
                                         OUT error_code INTEGER, OUT error_message TEXT)
    RETURNS RECORD
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_luba_id INTEGER = params ->> 'id';
    l_intress NUMERIC = 0;
    l_volg    NUMERIC = 0;
    l_jaak    NUMERIC = 0;
    v_luba    RECORD;
BEGIN

    SELECT id,
           jaak,
           volg,
           intress,
           staatus
    INTO v_luba
    FROM rekl.luba
    WHERE luba.parentid = l_luba_id;

    IF v_luba.id IS NULL
    THEN
        error_code = 5;
        error_message = 'Dokument ei leidnud ' || l_luba_id :: TEXT;
        result = 0;
        RETURN;
    END IF;

    result = 1;
    IF v_luba.staatus = 1
    THEN
        -- algsaldo

        SELECT coalesce(sum(jaak) FILTER (WHERE tyyp IN ('DEKL', 'PARANDUS', 'ALGSALDO') AND coalesce(jaak, 0) >= 0 AND
                                                tahtaeg < current_date), 0)                   AS volg,
               coalesce(sum(jaak) FILTER (WHERE tyyp IN ('DEKL', 'PARANDUS', 'ALGSALDO')), 0) AS jaak,
               coalesce(sum(jaak) FILTER (WHERE tyyp = 'INTRESS'), 0)                         AS intress
        INTO l_volg, l_jaak, l_intress
        FROM (SELECT COALESCE(rekl.fnc_dekl_jaak(D.ID), 0) AS jaak, t.tyyp, t.tahtaeg
              FROM rekl.toiming t
                       INNER JOIN docs.doc d ON d.id = t.parentid
              WHERE t.lubaId = l_luba_id
                AND d.status <> 3
                AND staatus <> 'deleted') qry;

        UPDATE rekl.luba
        SET jaak    = l_jaak,
            volg    = l_volg,
            intress = l_intress
        WHERE parentid = l_luba_id;

    ELSE
        error_message = 'Luba anuleeritud, nullime saldo:';

        UPDATE rekl.luba
        SET jaak    = 0,
            volg    = 0,
            intress = 0
        WHERE parentid = l_luba_id;
    END IF;
    result = 1;

    RETURN;
END;
$$;

GRANT EXECUTE ON FUNCTION rekl.sp_recalc_rekl_jaak(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.sp_recalc_rekl_jaak(INTEGER, JSON) TO dbpeakasutaja;

/*

select *

select rekl.sp_recalc_rekl_jaak(4862, '{"id":4644387}'::JSON)

2275773
2288031
2284825
2457994

 */