DROP FUNCTION IF EXISTS get_unique_value_from_array(TEXT[]);

CREATE OR REPLACE FUNCTION get_unique_value_from_array(l_array TEXT[])
    RETURNS TEXT[]
AS
$BODY$
SELECT array_agg(value)
FROM (
         SELECT DISTINCT value
         FROM (
                  SELECT unnest(l_array) AS value
              ) qry) qry

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION get_unique_value_from_array(TEXT[]) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION get_unique_value_from_array(TEXT[]) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION get_unique_value_from_array(TEXT[]) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION get_unique_value_from_array(TEXT[]) TO dbvaatleja;

/*

SELECT get_unique_value_from_array(array['1','1','1','2','2']:: TEXT[])

*/