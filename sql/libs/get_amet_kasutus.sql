DROP FUNCTION IF EXISTS get_amet_kasutus(INTEGER, DATE);

CREATE FUNCTION get_amet_kasutus(l_lib_id INTEGER, l_kpv DATE)
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
            SELECT 'Lib. tööleping, isik:' || ltrim(rtrim(a.regkood)) || ' (' || ltrim(rtrim(a.nimetus)) ||
                   ')' AS dok_nr
            FROM palk.tooleping t
                     INNER JOIN libs.asutus a ON t.parentid = a.id
            WHERE t.ametid = l_lib_id
              AND (t.algab >= l_kpv
                OR t.lopp IS NULL
                OR t.lopp >= l_kpv)
              AND t.status <> 3

            LOOP
                tulemus = tulemus || to_jsonb(row)
                          FROM (SELECT 'Amet kood ' || ltrim(rtrim(l_lib_kood)) || ' kasutusel, ' ||
                                       ltrim(rtrim(v_docs.dok_nr)) AS error_message,
                                       1                           AS error_code) row;
            END LOOP;

    END IF;
    RETURN tulemus;
END;

$$;

GRANT EXECUTE ON FUNCTION get_amet_kasutus(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION get_amet_kasutus(INTEGER, DATE) TO dbpeakasutaja;


/*

-- Koolituskulud -> NOM
-- TUNNUS ->>test 3


SELECT *
FROM jsonb_to_recordset(get_tegevus_kasutus(121490, '2019-12-31'::DATE))
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

