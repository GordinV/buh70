DROP FUNCTION IF EXISTS get_tunnus_kasutus(INTEGER, DATE);

CREATE FUNCTION get_tunnus_kasutus(l_lib_id INTEGER, l_kpv DATE)
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
            SELECT 'Lib. Nomenklatuur kood:' || ltrim(rtrim(n.kood)) || ' (' || ltrim(rtrim(r.nimetus)) || ')' AS dok_nr
            FROM libs.nomenklatuur n
                     INNER JOIN ou.rekv r ON n.rekvid = r.id
            WHERE ((n.properties ->> 'valid')::DATE IS NULL OR (n.properties ->> 'valid')::DATE > l_kpv)
              AND n.properties ->> 'tunnus' IS NOT NULL
              AND n.rekvid = l_rekv_id
              AND ltrim(rtrim(n.properties ->> 'tunnus')) = l_lib_kood
            UNION
            SELECT 'Lib. amet kood:' || ltrim(rtrim(n.kood)) AS dok_nr
            FROM libs.library n
            WHERE n.library = 'AMET'
              AND n.rekvid = l_rekv_id
              AND ((n.properties::JSON ->> 'valid')::DATE IS NULL OR (n.properties::JSON ->> 'valid')::DATE > l_kpv)
              AND (n.properties::JSON ->> 'tunnusid' IS NOT NULL AND
                   (n.properties::JSON ->> 'tunnusid')::INTEGER = l_lib_id)
            UNION
            SELECT 'Lib. palk kood:' || ltrim(rtrim(n.kood)) AS dok_nr
            FROM libs.library n
            WHERE n.library = 'PALK'
              AND n.rekvid = l_rekv_id
              AND ((n.properties::JSON ->> 'valid')::DATE IS NULL OR (n.properties::JSON ->> 'valid')::DATE > l_kpv)
              AND (n.properties::JSON ->> 'tunnusid' IS NOT NULL AND
                   (n.properties::JSON ->> 'tunnusid')::INTEGER = l_lib_id)
            UNION
            -- docs
            SELECT DISTINCT 'Dok. MK nr.:' || ltrim(rtrim(m.number)) || ' (' || ltrim(rtrim(r.nimetus)) || ')' AS dok_nr
            FROM docs.mk m
                     INNER JOIN docs.mk1 m1 ON m.id = m1.parentid
                     INNER JOIN ou.rekv r ON m.rekvid = r.id
            WHERE m.kpv > l_kpv
              AND m.rekvid = l_rekv_id
              AND ltrim(rtrim(m1.tunnus)) = l_lib_kood
            UNION
            SELECT DISTINCT 'Dok. kassa order nr.:' || ltrim(rtrim(m.number)) || ' (' || ltrim(rtrim(r.nimetus)) ||
                            ')' AS dok_nr
            FROM docs.korder1 m
                     INNER JOIN docs.korder2 m1 ON m.id = m1.parentid
                     INNER JOIN ou.rekv r ON m.rekvid = r.id
            WHERE m.kpv > l_kpv
              AND m.rekvid = l_rekv_id
              AND ltrim(rtrim(m1.tunnus)) = l_lib_kood
            UNION
            SELECT DISTINCT
                        'Dok avans nr.:' || ltrim(rtrim(m.number)) || ' (' || ltrim(rtrim(r.nimetus)) || ')' AS dok_nr
            FROM docs.avans1 m
                     INNER JOIN docs.avans2 m1 ON m.id = m1.parentid
                     INNER JOIN ou.rekv r ON m.rekvid = r.id
            WHERE m.kpv > l_kpv
              AND m.rekvid = l_rekv_id
              AND ltrim(rtrim(m1.tunnus)) = l_lib_kood
            UNION
            SELECT DISTINCT 'Dok PV operatsioon inv.nr.:' || ltrim(rtrim(p.kood)) || ' (' || ltrim(rtrim(r.nimetus)) ||
                            ')' AS dok_nr
            FROM docs.pv_oper o
                     INNER JOIN cur_pohivara p ON o.parentid = p.id
                     INNER JOIN ou.rekv r ON p.rekvid = r.id
            WHERE o.kpv > l_kpv
              AND ltrim(rtrim(o.tunnus)) = l_lib_kood
            UNION ALL
            SELECT DISTINCT 'Dok lausend nr.:' || ltrim(rtrim(m.number::TEXT)) || ' (' || ltrim(rtrim(r.nimetus)) ||
                            ')' AS dok_nr
            FROM cur_journal m
                     INNER JOIN ou.rekv r ON m.rekvid = r.id
            WHERE m.kpv > l_kpv
              AND m.rekvid = l_rekv_id
              AND ltrim(rtrim(m.tunnus)) = l_lib_kood

            LOOP
                tulemus = tulemus || to_jsonb(row)
                          FROM (SELECT 'Tunnuse kood ' || ltrim(rtrim(l_lib_kood)) || ' kasutusel, ' ||
                                       ltrim(rtrim(v_docs.dok_nr)) AS error_message,
                                       1                           AS error_code) row;
            END LOOP;

    END IF;
    RETURN tulemus;
END;

$$;

GRANT EXECUTE ON FUNCTION get_tunnus_kasutus(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION get_tunnus_kasutus(INTEGER, DATE) TO dbpeakasutaja;


/*

-- Koolituskulud -> NOM
-- TUNNUS ->>test 3


SELECT *
FROM jsonb_to_recordset(get_tunnus_kasutus(214939, '2019-12-31'::DATE))
         AS x (error_message TEXT, error_code integer);


select * from libs.library where rekvid = 63 and library = 'TUNNUS' and kood = 'test'

select * from libs.library where rekvid = 63 and library = 'AMET'
 SELECT DISTINCT
                    'Dok avans nr.:' || ltrim(rtrim(m.number)) || ' (' || ltrim(rtrim(r.nimetus)) || ')' AS dok_nr
                FROM docs.avans1 m
                INNER JOIN docs.avans2 m1 ON m.id = m1.parentid
                INNER JOIN ou.rekv r ON m.rekvid = r.id
                WHERE m.kpv > '2019-12-31'
              AND ltrim(rtrim(m1.kood2)) = '70'

*/

