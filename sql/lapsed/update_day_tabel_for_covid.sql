DROP FUNCTION IF EXISTS lapsed.update_day_tabel_for_covid();

CREATE FUNCTION lapsed.update_day_tabel_for_covid()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_dt RECORD;
BEGIN

    FOR v_dt IN
        WITH day_taabel AS (
            SELECT DISTINCT dt.id, dt1.id AS dt1_id, dt1.osalemine, dt1.covid, dt.kpv, dt1.laps_id
            FROM lapsed.day_taabel dt
                     INNER JOIN lapsed.day_taabel1 dt1 ON dt.id = dt1.parent_id
            WHERE month(dt.kpv) IN (1, 2, 3)
              AND year(dt.kpv) = 2022
              AND dt.staatus < 3
              AND dt1.osalemine = 0
              AND rekv_id IN (SELECT id FROM ou.rekv WHERE nimetus ILIKE '%Kaoke%')
--              AND dt.id = 41856
        )

        SELECT *
        FROM day_taabel
        LOOP
            UPDATE lapsed.day_taabel1 SET covid = 1 WHERE id = v_dt.dt1_id;
        END LOOP;
    RETURN 1;
END;
$$;

SELECT lapsed.update_day_tabel_for_covid();

DROP FUNCTION IF EXISTS lapsed.update_day_tabel_for_covid();
