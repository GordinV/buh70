DROP FUNCTION IF EXISTS ou.get_user_data(l_kasutaja TEXT, l_rekvid INTEGER, l_module TEXT);

CREATE OR REPLACE FUNCTION ou.get_user_data(l_kasutaja TEXT, l_rekvid INTEGER, l_module TEXT)
    RETURNS TABLE (
        id             INTEGER,
        rekvid         INTEGER,
        kasutaja       TEXT,
        ametnik        TEXT,
        parool         TEXT,
        kasutaja_      INTEGER,
        peakasutaja_   INTEGER,
        admin          INTEGER,
        muud           TEXT,
        last_login     TIMESTAMP,
        asutus         TEXT,
        allowed_access TEXT[],
        allowed_libs   TEXT[]
    ) AS
$BODY$

SELECT u.id,
       u.rekvid,
       u.kasutaja::TEXT,
       u.ametnik::TEXT,
       u.parool::TEXT,
       u.kasutaja_,
       u.peakasutaja_,
       u.admin,
       u.muud,
       u.last_login,
       r.nimetus::TEXT              AS asutus,
       rs.a::TEXT[]                 AS allowed_access,
       allowed_modules.libs::TEXT[] AS allowed_libs

FROM ou.userid u
         JOIN ou.rekv r ON r.id = u.rekvid AND u.kasutaja::TEXT = l_kasutaja
         JOIN (
    SELECT array_agg('{"id":'::TEXT || r.id::TEXT || ',"nimetus":"'::TEXT || r.nimetus || '"}') AS a
    FROM (
             SELECT r.id, r.nimetus
             FROM ou.rekv r
                      JOIN ou.userid u_1 ON u_1.rekvid = r.id
             WHERE u_1.kasutaja::TEXT = l_kasutaja
         ) r) rs ON rs.a IS NOT NULL
         JOIN (
    SELECT array_agg('{"id":'::TEXT || lib.id::TEXT || ',"nimetus":"'::TEXT || lib.nimetus || '"}')
               AS libs
    FROM (
             SELECT id,
                    kood::TEXT,
                    nimetus::TEXT,
                    library::TEXT                          AS lib,
                    (properties::JSONB -> 'module')::JSONB AS module
             FROM libs.library l
             WHERE l.library = 'DOK'
               AND status <> 3
               AND ((properties::JSONB -> 'module') @> l_module::JSONB OR l_module IS NULL)
         ) lib
) allowed_modules ON allowed_modules.libs IS NOT NULL
WHERE (r.id = l_rekvid OR l_rekvid IS NULL)
ORDER BY u.last_login desc
LIMIT 1;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

/*

SELECT *
FROM ou.get_user_data('temp', null, null)

*/