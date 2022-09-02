CREATE FUNCTION year() RETURNS integer
    LANGUAGE plpgsql
AS
$$
begin
    return  year(current_date);
end;
$$;


CREATE FUNCTION year(date) RETURNS integer
    LANGUAGE plpgsql
AS
$$
begin
    return  cast(extract(year from $1) as int);
end;
$$;


CREATE OR REPLACE FUNCTION "year"(date)
    RETURNS integer AS
$BODY$
begin
    return  cast(extract(year from $1) as int);
end;
$BODY$
    LANGUAGE 'plpgsql' VOLATILE
                       COST 100;
ALTER FUNCTION "year"(date) OWNER TO vlad;
GRANT EXECUTE ON FUNCTION "year"(date) TO vlad;
GRANT EXECUTE ON FUNCTION "year"(date) TO public;
GRANT EXECUTE ON FUNCTION "year"(date) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION "year"(date) TO taabel;
GRANT EXECUTE ON FUNCTION "year"(date) TO dbvanemtasu;




