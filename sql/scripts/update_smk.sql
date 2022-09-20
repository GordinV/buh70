DROP FUNCTION IF EXISTS lapsed.update_smk();

CREATE FUNCTION lapsed.update_smk()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_smk     RECORD;
    l_count   INTEGER = 0;
    l_rekv_id INTEGER;
    l_kokku   INTEGER = 0;
    l_vn      TEXT;
    l_ik      TEXT;
    l_laps_id INTEGER;
BEGIN

    FOR v_smk IN
        SELECT aa.arve, vv.aa, mk.id
        FROM docs.mk mk
                 INNER JOIN lapsed.pank_vv vv ON mk.parentid = vv.doc_id
                 INNER JOIN ou.aa aa ON aa.id = mk.aaid
        WHERE vv.aa IS NOT NULL
          AND aa.arve <> vv.aa
          and mk.kpv >= '2022-01-01'
            ORDER BY mk.id DESC
            LIMIT 100
        LOOP


        END LOOP;
    RETURN l_count;

END;
$$;

SELECT lapsed.update_smk();

DROP FUNCTION IF EXISTS lapsed.update_smk();
