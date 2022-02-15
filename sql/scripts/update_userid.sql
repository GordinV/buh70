DROP FUNCTION IF EXISTS update_users();

CREATE FUNCTION update_users()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_users RECORD;
    l_count integer = 0;
BEGIN
    FOR v_users IN
        SELECT max(id) AS id, kasutaja, rekvid
        FROM ou.userid u
        WHERE status <> 3
          AND kasutaja || '-' || rekvid::TEXT IN (
            SELECT kasutaja || '-' || rekvid::TEXT
            FROM ou.userid
            WHERE status <> 3
            GROUP BY kasutaja, rekvid
            HAVING count(*) > 1
        )
--        and kasutaja = 'jelena.tsekanina'
        GROUP BY rekvid, kasutaja
        ORDER BY rekvid, kasutaja
        LOOP
            UPDATE ou.userid SET status = 3 WHERE id = v_users.id;
            l_count = l_count + 1;
        END LOOP;
    return l_count;
END;

$$;

SELECT update_users();

DROP FUNCTION IF EXISTS update_users();

