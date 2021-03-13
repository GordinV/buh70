DROP FUNCTION IF EXISTS sp_puudumise_paevad(DATE, INTEGER);

CREATE FUNCTION sp_puudumise_paevad(DATE, INTEGER) RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    tdKpv ALIAS FOR $1;
    tnLepingid ALIAS FOR $2;
    qryTooleping RECORD;
    v_puudumine  RECORD;
    l_paevad     INTEGER = 0;
BEGIN
    -- toopaevad - puhkused

    SELECT t.* INTO qryTooleping
    FROM palk.tooleping t
    WHERE t.id = tnLepingId;

    FOR v_puudumine IN
        SELECT coalesce(kpv1, date(year(tdKpv), month(tdKpv), 1)) AS kpv1, coalesce(kpv2, tdKpv) AS kpv2
        FROM palk.cur_puudumine p
        WHERE lepingId = tnLepingId
          AND ((year(kpv2) = year(tdKpv) AND month(kpv2) = month(tdKpv)) OR
               (month(kpv1) = month(tdKpv) AND year(kpv1) = year(tdKpv)))
          AND (pohjus = 'PUHKUS' AND tyyp IN (1, 2, 3) OR pohjus = 'HAIGUS' AND tyyp = 1)
            ORDER BY kpv1
            , kpv2
        LOOP
            IF v_puudumine.kpv1 < date(year(tdKpv), month(tdKpv), 1)
            THEN
                v_puudumine.kpv1 = date(year(tdKpv), month(tdKpv), 1);
            END IF;
            IF v_puudumine.kpv2 > tdKpv
            THEN
                v_puudumine.kpv2 = tdKpv;
            END IF;
-- paevad
            l_paevad = l_paevad + (v_puudumine.kpv2 - v_puudumine.kpv1) + 1;
        END LOOP;

    RETURN l_paevad;
END;

$$;

GRANT EXECUTE ON FUNCTION sp_puudumise_paevad(DATE, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION sp_puudumise_paevad(DATE, INTEGER) TO dbpeakasutaja;


