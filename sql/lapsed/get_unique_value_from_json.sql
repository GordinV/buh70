DROP FUNCTION IF EXISTS get_unique_value_from_json(JSONB, TEXT);
DROP FUNCTION IF EXISTS get_unique_value_from_json(JSONB);

CREATE OR REPLACE FUNCTION get_unique_value_from_json(jsonb_row JSONB)
    RETURNS TABLE (
        value TEXT
    ) AS
$BODY$
SELECT DISTINCT value
FROM (
         SELECT trim(both '"' from value::TEXT) AS value
         FROM json_array_elements(jsonb_row::JSON)
     ) qry

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION get_unique_value_from_json(JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION get_unique_value_from_json(JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION get_unique_value_from_json(JSONB) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION get_unique_value_from_json(JSONB) TO dbvaatleja;

/*

SELECT get_unique_value_from_json(
(select json_agg(properties->>'yksus')
from lapsed.lapse_kaart
where parentid = 46)::jsonb)

*/