DROP FUNCTION IF EXISTS get_tululiik_kasutus(INTEGER, DATE);

CREATE FUNCTION get_tululiik_kasutus(l_lib_id INTEGER, l_kpv DATE)
    RETURNS JSONB
    LANGUAGE plpgsql
AS
$$
DECLARE
    tulemus    JSONB = '[]'::JSONB;
    v_docs     RECORD;
    l_lib_kood TEXT  = (SELECT ltrim(rtrim(kood))
                        FROM libs.library
                        WHERE id = l_lib_id);
BEGIN

    IF l_lib_id IS NOT NULL
    THEN
        FOR v_docs IN
            -- libs
            SELECT 'Lib. palk lib kood:' || ltrim(rtrim(n.kood)) || ' (' || ltrim(rtrim(r.nimetus)) || ')' AS dok_nr
            FROM libs.library n
                     INNER JOIN ou.rekv r ON n.rekvid = r.id
            WHERE ((n.properties::JSON ->> 'valid')::DATE IS NULL OR (n.properties::JSON ->> 'valid')::DATE > l_kpv)
              AND n.properties::JSON ->> 'tululiik' IS NOT NULL
              AND ltrim(rtrim(n.properties::JSON ->> 'tululiik')) = l_lib_kood

            LOOP
                tulemus = tulemus || to_jsonb(row)
                          FROM (SELECT 'Tululiik kood ' || ltrim(rtrim(l_lib_kood)) || ' kasutusel, ' ||
                                       ltrim(rtrim(v_docs.dok_nr)) AS error_message,
                                       1                           AS error_code) row;
            END LOOP;

    END IF;
    RETURN tulemus;
END;

$$;

GRANT EXECUTE ON FUNCTION get_tululiik_kasutus(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION get_tululiik_kasutus(INTEGER, DATE) TO dbpeakasutaja;


/*

-- Koolituskulud -> NOM
-- TUNNUS ->>test 3


SELECT *
FROM jsonb_to_recordset(get_tululiik_kasutus(76509, '2019-12-31'::DATE))
         AS x (error_message TEXT, error_code integer);

select * from libs.library where kood = '01400'

 SELECT DISTINCT
                    'Dok avans nr.:' || ltrim(rtrim(m.number)) || ' (' || ltrim(rtrim(r.nimetus)) || ')' AS dok_nr
                FROM docs.avans1 m
                INNER JOIN docs.avans2 m1 ON m.id = m1.parentid
                INNER JOIN ou.rekv r ON m.rekvid = r.id
                WHERE m.kpv > '2019-12-31'
              AND ltrim(rtrim(m1.kood1)) = '01400'

*/

