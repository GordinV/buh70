CREATE FUNCTION day(date) RETURNS integer
    LANGUAGE plpgsql
AS
$$
begin
    return  cast(extract(day from $1) as int);
end;
$$;



