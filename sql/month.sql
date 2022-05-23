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



