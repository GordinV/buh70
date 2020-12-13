DROP FUNCTION IF EXISTS get_jsonb_array(TEXT);

CREATE FUNCTION get_jsonb_array(l_json TEXT)
    RETURNS JSONB
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_jsonb JSONB = l_json::JSONB; -- tulemus, paevad
BEGIN

    RETURN l_jsonb;
END;
$$;

GRANT EXECUTE ON FUNCTION get_jsonb_array(TEXT) TO public;



