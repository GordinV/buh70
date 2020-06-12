DROP FUNCTION IF EXISTS fix_text(TEXT);

CREATE FUNCTION fix_text(l_str TEXT)
    RETURNS TEXT
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_txt TEXT; -- tulemus, paevad
BEGIN
    l_txt = TRIM(to_jsonb(l_str)::TEXT, '"');
    RETURN l_txt;
END;
$$;

GRANT EXECUTE ON FUNCTION fix_text(TEXT) TO public;



SELECT fix_text('ÄÄÄÄÄÄÄ':: TEXT)


