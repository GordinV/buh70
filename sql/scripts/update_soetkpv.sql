DROP FUNCTION IF EXISTS update_soetkpv();

CREATE FUNCTION update_soetkpv()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_docs RECORD;
    l_json JSONB;
BEGIN
    FOR v_docs IN
        SELECT p.id, l.kood, pk.soetkpv, r.nimetus AS asutus, p.kood AS uus_kaart, p.soetkpv AS uus_soetkpv
        FROM remote_pv_kaart pk
                 INNER JOIN remote_library l ON l.id = pk.parentid
                 INNER JOIN ou.rekv r ON r.id = l.rekvid
                 INNER JOIN cur_pohivara p ON p.kood = l.kood AND p.rekvid = l.rekvid
        WHERE (pk.mahakantud IS NULL)
          AND p.soetkpv <> pk.soetkpv
          and p.soetkpv < '2020-12-31'
--          AND p.id = 202474
        LOOP
            l_json = jsonb_build_object('soetkpv', v_docs.soetkpv);
            raise notice 'l_json %', l_json;

            UPDATE libs.library
            SET properties = properties::JSONB || l_json
            WHERE id = v_docs.id;
        END LOOP;

    RETURN 1;
END;

$$;

select update_soetkpv();

DROP FUNCTION IF EXISTS update_soetkpv();

