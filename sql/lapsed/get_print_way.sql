DROP FUNCTION IF EXISTS lapsed.get_print_way(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.get_print_way(l_asutus_id INTEGER, l_rekv_id INTEGER, l_laps_id INTEGER)
    RETURNS TEXT AS
$BODY$

DECLARE
    l_print TEXT = '';
BEGIN

    l_print = (SELECT array_to_string(get_unique_value_from_array(
                                              array_agg(
                                                      CASE
                                                          WHEN NOT coalesce(va.arveldus::BOOLEAN, FALSE) THEN ''
                                                          ELSE (
                                                                              CASE
                                                                                  WHEN (v.properties ->> 'kas_email')::BOOLEAN
                                                                                      THEN 'email;'
                                                                                  ELSE '' END ||
                                                                              CASE
                                                                                  WHEN (v.properties ->> 'kas_paberil')::BOOLEAN
                                                                                      THEN 'paber;'
                                                                                  ELSE '' END ||
                                                                              CASE
                                                                                  WHEN (va.properties ->> 'kas_earve')::BOOLEAN AND
                                                                                       empty(va.properties ->> 'pank')
                                                                                      THEN 'e-arve;'
                                                                                  ELSE '' END ||
                                                                              CASE
                                                                                  WHEN (va.properties ->> 'kas_earve')::BOOLEAN AND
                                                                                       NOT empty(va.properties ->> 'pank') AND
                                                                                       (va.properties ->> 'pank') = 'SEB'
                                                                                      THEN 'SEB;'
                                                                                  ELSE '' END ||
                                                                              CASE
                                                                                  WHEN (va.properties ->> 'kas_earve')::BOOLEAN AND
                                                                                       NOT empty(va.properties ->> 'pank') AND
                                                                                       (va.properties ->> 'pank') = 'SWED'
                                                                                      THEN 'SWED;'
                                                                                  ELSE '' END) END)
                                          ), '')::TEXT
                          AS printimine
               FROM lapsed.vanemad v
                        INNER JOIN libs.asutus a ON a.id = v.asutusid
                        LEFT OUTER JOIN lapsed.vanem_arveldus va ON va.parentid = v.parentid
                   AND va.asutusid = v.asutusid
                   AND va.rekvid = l_rekv_id
                   AND a.id = l_asutus_id
                   AND va.parentid = l_laps_id
               WHERE v.staatus <> 3);

    return l_print;

END;

$BODY$
    LANGUAGE plpgsql
    IMMUTABLE
    COST 100;



GRANT EXECUTE ON FUNCTION lapsed.get_print_way(INTEGER,INTEGER,INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_print_way(INTEGER,INTEGER,INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.get_print_way(INTEGER,INTEGER,INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_print_way(INTEGER,INTEGER,INTEGER) TO arvestaja;

select lapsed.get_print_way(2874,71,14563)
