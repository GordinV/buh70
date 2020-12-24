DROP FUNCTION IF EXISTS docs.insert_into_dynamic_table(text) CASCADE ;

CREATE OR REPLACE FUNCTION docs.insert_into_dynamic_table(table_name text)
    RETURNS SETOF RECORD AS
$BODY$

DECLARE
    l_string text;
BEGIN
/*
    EXECUTE format('INSERT INTO %s SELECT $1.*'
        , table_name || 'shadow')
        USING new;
*/
--    raise notice 'new %', new;
    return query select 1 as id;
--    RETURN new.id;
END;
$BODY$
    LANGUAGE 'plpgsql' VOLATILE
    COST 100;

--GRANT EXECUTE ON FUNCTION palk.calc_mvt(NUMERIC, NUMERIC) TO dbkasutaja;
--GRANT EXECUTE ON FUNCTION palk.calc_mvt(NUMERIC, NUMERIC) TO dbpeakasutaja;
/*

*/