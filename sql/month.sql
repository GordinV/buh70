CREATE FUNCTION month() RETURNS integer
    LANGUAGE plpgsql
AS
$$
begin
    return  cast(extract(month from date()) as int4);
end;
$$;

CREATE FUNCTION month(date) RETURNS integer
    LANGUAGE plpgsql
AS
$$
begin
    return  cast(extract(month from $1) as int8);
end;
$$;


CREATE OR REPLACE FUNCTION "month"(date)
    RETURNS integer AS
$BODY$
begin
    return  cast(extract(month from $1) as int8);
end;
$BODY$
    LANGUAGE 'plpgsql' VOLATILE
                       COST 100;
ALTER FUNCTION "month"(date) OWNER TO vlad;
GRANT EXECUTE ON FUNCTION "month"(date) TO vlad;
GRANT EXECUTE ON FUNCTION "month"(date) TO public;
GRANT EXECUTE ON FUNCTION "month"(date) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION "month"(date) TO taabel;
GRANT EXECUTE ON FUNCTION "month"(date) TO dbvanemtasu;

