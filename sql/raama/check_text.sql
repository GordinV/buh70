DROP FUNCTION IF EXISTS check_text(TEXT);

CREATE FUNCTION check_text(l_var TEXT)
    RETURNS BOOLEAN
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_sumbol_1 TEXT = ';'; --  "  /   enter
    l_sumbol_2 TEXT = '"'; --  "  /   enter
    l_sumbol_3 TEXT = '/'; --  "  /   enter
    l_sumbol_4 TEXT = ''''; --  "  /   enter
    l_sumbol_5 TEXT = chr(10);

BEGIN
    IF l_var ~ l_sumbol_1 OR l_var ~ l_sumbol_2 OR l_var ~ l_sumbol_3 OR l_var ~ l_sumbol_4 OR l_var ~ l_sumbol_5
    THEN
        RAISE EXCEPTION 'Viga, on sisestatud keelatud sümbolid';
    END IF;
    RETURN TRUE;
END
$$;


--SELECT check_text('12''');