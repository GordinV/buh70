DROP FUNCTION IF EXISTS get_objekt_kasutus(INTEGER, DATE);

CREATE FUNCTION get_objekt_kasutus(l_lib_id INTEGER, l_kpv DATE)
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
            SELECT 'Lib. Nomenklatuur kood:' || ltrim(rtrim(n.kood)) || ' (' || ltrim(rtrim(r.nimetus)) || ')' AS dok_nr
            FROM libs.nomenklatuur n
                     INNER JOIN ou.rekv r ON n.rekvid = r.id
            WHERE ((n.properties ->> 'valid')::DATE IS NULL OR (n.properties ->> 'valid')::DATE > l_kpv)
              AND n.properties ->> 'objekt' IS NOT NULL
              AND ltrim(rtrim(n.properties ->> 'objekt')) = l_lib_kood
            UNION
            -- docs
            SELECT DISTINCT
                    'Dok lausend nr.:' || ltrim(rtrim(m.number::text)) || ' (' || ltrim(rtrim(r.nimetus)) || ')' AS dok_nr
            FROM cur_journal m
                     INNER JOIN ou.rekv r ON m.rekvid = r.id
            WHERE m.kpv > l_kpv
              AND ltrim(rtrim(m.objekt)) = l_lib_kood
            LOOP
                tulemus = tulemus || to_jsonb(row)
                          FROM (SELECT 'Projekt kood ' || ltrim(rtrim(l_lib_kood)) || ' kasutusel, ' ||
                                       ltrim(rtrim(v_docs.dok_nr)) AS error_message,
                                       1                           AS error_code) row;
            END LOOP;

    END IF;
    RETURN tulemus;
END;

$$;

GRANT EXECUTE ON FUNCTION get_objekt_kasutus(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION get_objekt_kasutus(INTEGER, DATE) TO dbpeakasutaja;


/*

-- Koolituskulud -> NOM
-- TUNNUS ->>test 3


SELECT *
FROM jsonb_to_recordset(get_objekt_kasutus(214945, '2019-12-31'::DATE))
         AS x (error_message TEXT, error_code integer);

select * from libs.library where nimetus = 'test obj   '

 SELECT DISTINCT
                    'Dok avans nr.:' || ltrim(rtrim(m.number)) || ' (' || ltrim(rtrim(r.nimetus)) || ')' AS dok_nr
                FROM docs.avans1 m
                INNER JOIN docs.avans2 m1 ON m.id = m1.parentid
                INNER JOIN ou.rekv r ON m.rekvid = r.id
                WHERE m.kpv > '2019-12-31'
              AND ltrim(rtrim(m1.kood2)) = '70'

*/

