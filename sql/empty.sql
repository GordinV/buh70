-- Function: empty(character varying)

-- DROP FUNCTION empty(character varying);

CREATE OR REPLACE FUNCTION empty(CHARACTER VARYING)
    RETURNS BOOLEAN AS
$BODY$

BEGIN

    IF $1 IS NULL OR len(ltrim(rtrim($1))) < 1
    THEN

        RETURN TRUE;

    ELSE

        RETURN FALSE;

    END IF;

END;

$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION empty(CHARACTER VARYING) TO PUBLIC;

CREATE OR REPLACE FUNCTION empty(TEXT)
    RETURNS BOOLEAN AS
$BODY$

BEGIN

    IF $1 IS NULL OR len(ltrim(rtrim($1))) < 1
    THEN

        RETURN TRUE;

    ELSE

        RETURN FALSE;

    END IF;

END;

$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION empty(TEXT) TO PUBLIC;



CREATE OR REPLACE FUNCTION empty(numeric)
    RETURNS boolean AS
$BODY$

begin

    if $1 is null or $1 = 0 then

        return true;

    else

        return false;

    end if;

end;

$BODY$
    LANGUAGE 'plpgsql' VOLATILE
                       COST 100;
GRANT EXECUTE ON FUNCTION empty(numeric) TO public;
GRANT EXECUTE ON FUNCTION empty(numeric) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION empty(numeric) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION empty(numeric) TO dbadmin;
GRANT EXECUTE ON FUNCTION empty(numeric) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION empty(numeric) TO dbvanemtasu;

-- Function: empty(date)

-- DROP FUNCTION empty(date);

CREATE OR REPLACE FUNCTION empty(date)
    RETURNS boolean AS
$BODY$

begin

    if $1 is null or year($1) <  year (now()::date)-100 then

        return true;

    else

        return false;

    end if;

end;

$BODY$
    LANGUAGE 'plpgsql' VOLATILE
                       COST 100;
ALTER FUNCTION empty(date) OWNER TO vlad;
GRANT EXECUTE ON FUNCTION empty(date) TO vlad;
GRANT EXECUTE ON FUNCTION empty(date) TO public;
GRANT EXECUTE ON FUNCTION empty(date) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION empty(date) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION empty(date) TO dbadmin;
GRANT EXECUTE ON FUNCTION empty(date) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION empty(date) TO taabel;
GRANT EXECUTE ON FUNCTION empty(date) TO dbvanemtasu;
