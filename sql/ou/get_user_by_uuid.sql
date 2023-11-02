DROP FUNCTION IF EXISTS ou.get_user_by_uuid(TEXT);

CREATE OR REPLACE FUNCTION ou.get_user_by_uuid(l_uuid TEXT)
    RETURNS TABLE (
        userId      INTEGER,
        asutusId    INTEGER,
        kasutaja    TEXT,
        asutus      TEXT,
        taisnimetus TEXT,
        regkood     TEXT,
        user_data   JSONB,
        users       JSONB,
        email       TEXT
    )
AS
$BODY$

SELECT userId,
       asutusId,
       u.kasutaja::TEXT,
       r.nimetus::TEXT                 AS asutus,
       coalesce(r.muud, nimetus)::TEXT AS taisnimetus,
       r.regkood::TEXT,
       uuid.user_data                  AS user_data,
       uuid.users                      AS users,
       r.email
FROM ou.session_uuid uuid,
     ou.userid u,
     ou.rekv r

WHERE uuid = l_uuid
  AND u.id = uuid.userid
  AND u.rekvid = r.id

ORDER BY timestamp DESC
LIMIT 1;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

/*

SELECT *
FROM ou.get_user_by_uuid('4faea4e0-74cc-11ee-b571-bb9ee17ad4b9')

*/
