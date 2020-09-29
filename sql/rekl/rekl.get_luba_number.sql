DROP FUNCTION IF EXISTS rekl.get_luba_number(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION rekl.get_luba_number(l_asutus_id INTEGER, l_rekv_id INTEGER DEFAULT 28)
    RETURNS VARCHAR(20)
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_eelmine_kuu INTEGER = (SELECT date_part('month', (current_date - INTERVAL '1 month')));
    l_aasta       INTEGER = date_part('year', current_date);
    l_number      VARCHAR(20);
    l_vana_number TEXT;
BEGIN
    -- Number: [eelmine kuu]/[ käesolev aasta]-luba nr[vaikimisi sama number, mis oli eelnevalt]
    l_vana_number = (SELECT number
                     FROM rekl.luba l
                     WHERE asutusid = l_asutus_id
                       AND l.rekvid = l_rekv_id

                     ORDER BY id DESC
                     LIMIT 1
    );

    IF l_vana_number IS NOT NULL
    THEN
--        l_vana_number = ltrim(rtrim(substring(l_vana_number FROM position('-' IN l_vana_number) + 1)));
        l_vana_number = left(l_vana_number, position('/' IN l_vana_number) - 1);
    ELSE
        l_vana_number = '0001';
    END IF;
raise notice 'l_vana_number %', l_vana_number;
--    l_number =lpad(l_eelmine_kuu::TEXT, 2,'0') || '/' || l_aasta::TEXT || '-' || coalesce(l_vana_number, '0001');
        -- Антон, новый формат
    l_number = coalesce(l_vana_number, '0001') || '/' || l_aasta::TEXT  ||  '-' || lpad(l_eelmine_kuu::TEXT, 2,'0')::TEXT  ;
    RETURN l_number;
END;
$$;

GRANT EXECUTE ON FUNCTION rekl.get_luba_number(INTEGER, INTEGER) TO dbkasutaja;


/*
SELECT rekl.get_luba_number(26748, 28)



*/