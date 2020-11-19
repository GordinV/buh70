DROP FUNCTION IF EXISTS get_koolituse_tyyp_kasutus(INTEGER, DATE);

CREATE FUNCTION get_koolituse_tyyp_kasutus(l_lib_id INTEGER, l_kpv DATE)
    RETURNS JSONB
    LANGUAGE plpgsql
AS
$$
DECLARE
    tulemus    JSONB   = '[]'::JSONB;
    v_docs     RECORD;
    l_lib_kood TEXT    = (SELECT ltrim(rtrim(kood))
                          FROM libs.library
                          WHERE id = l_lib_id);
    l_rekv_id  INTEGER = (SELECT rekvid
                          FROM libs.library
                          WHERE id = l_lib_id);
BEGIN

    IF l_lib_id IS NOT NULL
    THEN
        FOR v_docs IN
            -- libs
            SELECT 'Lib. Laste grupp kood:' || ltrim(rtrim(l.kood)) || ',' || ltrim(rtrim(l.nimetus)) AS dok_nr
            FROM libs.library l
            WHERE ((l.properties::JSON ->> 'valid')::DATE IS NULL OR (l.properties::JSON ->> 'valid')::DATE > l_kpv)
              AND l.properties::JSON ->> 'tyyp' IS NOT NULL
              AND (l.properties::JSON ->> 'tyyp')::INTEGER = l_lib_id
              AND l.rekvid = l_rekv_id
              AND l.status <> 3
            LOOP
                tulemus = tulemus || to_jsonb(row)
                          FROM (SELECT 'Koolituse tüüp kood ' || ltrim(rtrim(l_lib_kood)) || ' kasutusel, ' ||
                                       ltrim(rtrim(v_docs.dok_nr)) AS error_message,
                                       1                           AS error_code) row;
            END LOOP;

    END IF;
    RETURN tulemus;
END;

$$;

GRANT EXECUTE ON FUNCTION get_koolituse_tyyp_kasutus(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION get_koolituse_tyyp_kasutus(INTEGER, DATE) TO dbpeakasutaja;


/*

-- Koolituskulud -> NOM
-- TUNNUS ->>test 3


SELECT *
FROM jsonb_to_recordset(get_koolituse_tyyp_kasutus(237190, '2019-12-31'::DATE))
         AS x (error_message TEXT, error_code integer);

            SELECT 'Lib. Laste grupp kood:' || ltrim(rtrim(l.kood)) || ',' || ltrim(rtrim(l.nimetus)) AS dok_nr
            FROM libs.library l
            WHERE ((l.properties::JSON ->> 'valid')::DATE IS NULL OR (l.properties::JSON ->> 'valid')::DATE > '2019-12-31')
              AND l.properties::JSON ->> 'tyyp' IS NOT NULL
              AND ltrim(rtrim(l.properties::JSON ->> 'tyyp')) = 'test'
              AND l.status <> 3
*/

