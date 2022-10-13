DROP FUNCTION IF EXISTS ou.get_aa(INTEGER, TEXT);

CREATE FUNCTION ou.get_aa(IN rekv_id INTEGER, IN module TEXT, OUT aa_id INTEGER)
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_aa_id   INTEGER = (SELECT id
                         FROM ou.aa
                         WHERE parentid = rekv_id
                           AND aa.kassa = 1
                         ORDER BY default_ DESC
                         LIMIT 1);
    l_aa_tyyp TEXT    = CASE
                            WHEN module IS NULL THEN NULL
                            WHEN module = 'PALK' THEN 'kas_palk'
                            WHEN module = 'TULUD' THEN 'kas_tulud'
                            WHEN module = 'KULUD' THEN 'kas_kulud'
        END ;

BEGIN
    aa_id = l_aa_id;
    IF module IS NOT NULL
    THEN
        -- если задан модуль, то ищем по модулю
        l_aa_id = (SELECT id
                   FROM ou.aa
                   WHERE parentid = rekv_id
                     AND aa.kassa = 1
                     AND (aa.properties ->> l_aa_tyyp)::BOOLEAN
                   ORDER BY default_ DESC
                   LIMIT 1);

        IF l_aa_id IS NOT NULL
        THEN
            aa_id = l_aa_id;
        END IF;
    END IF;
    RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION ou.get_aa(INTEGER, TEXT) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION ou.get_aa(INTEGER, TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.get_aa(INTEGER, TEXT) TO dbpeakasutaja;


/*
SELECT ou.get_aa(63, 'TULUD'::TEXT);

select * from ou.aa where id = 269

*/