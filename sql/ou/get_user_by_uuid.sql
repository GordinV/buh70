DROP FUNCTION IF EXISTS ou.get_user_by_uuid(TEXT);

CREATE OR REPLACE FUNCTION ou.get_user_by_uuid(l_uuid TEXT)
    RETURNS TABLE (
        userId   INTEGER,
        asutusId INTEGER,
        kasutaja TEXT
    )
AS
$BODY$

SELECT userId,
       asutusId,
       u.kasutaja::text
FROM ou.session_uuid uuid,
     ou.userid u
WHERE uuid = l_uuid
  AND u.id = uuid.userid
ORDER BY timestamp DESC
LIMIT 1;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

/*

SELECT *
FROM ou.get_user_by_uuid('06334410-3fe0-11ec-ba92-651897df85d0')

*/
