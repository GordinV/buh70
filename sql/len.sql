
CREATE OR REPLACE FUNCTION len(character varying)
    RETURNS integer AS
$BODY$
begin
    return char_length($1);
end;
$BODY$
    LANGUAGE 'plpgsql' VOLATILE
                       COST 100;
GRANT EXECUTE ON FUNCTION len(character varying) TO public;
GRANT EXECUTE ON FUNCTION len(character varying) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION len(character varying) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION len(character varying) TO dbadmin;
GRANT EXECUTE ON FUNCTION len(character varying) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION len(character varying) TO dbvanemtasu;
