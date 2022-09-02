
CREATE OR REPLACE FUNCTION val(character varying)
    RETURNS integer AS
$BODY$
begin
    return  ltrim($1)::int;
end;
$BODY$
    LANGUAGE 'plpgsql' VOLATILE
                       COST 100;
ALTER FUNCTION val(character varying) OWNER TO vlad;
GRANT EXECUTE ON FUNCTION val(character varying) TO vlad;
GRANT EXECUTE ON FUNCTION val(character varying) TO public;
GRANT EXECUTE ON FUNCTION val(character varying) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION val(character varying) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION val(character varying) TO dbadmin;
GRANT EXECUTE ON FUNCTION val(character varying) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION val(character varying) TO taabel;
GRANT EXECUTE ON FUNCTION val(character varying) TO dbvanemtasu;
