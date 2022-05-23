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



