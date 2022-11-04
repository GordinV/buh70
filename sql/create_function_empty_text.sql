--drop function if EXISTS public.empty(CHARACTER VARYING);
CREATE OR REPLACE FUNCTION empty(CHARACTER VARYING) RETURNS BOOLEAN
    LANGUAGE plpgsql
AS
$$
BEGIN
    IF $1 IS NULL OR char_length(ltrim(rtrim($1))) < 1
    THEN

        RETURN TRUE;

    ELSE

        RETURN FALSE;

    END IF;

END;

$$;

ALTER FUNCTION empty(VARCHAR) OWNER TO vlad;

