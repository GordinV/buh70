DROP FUNCTION IF EXISTS ou.sp_salvesta_userid( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION ou.sp_salvesta_userid(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  new_user_id  INTEGER;
  userName     TEXT;
  doc_id       INTEGER = data ->> 'id';
  doc_data     JSON = data ->> 'data';
  doc_kasutaja TEXT = doc_data ->> 'kasutaja';
  doc_ametnik  TEXT = doc_data ->> 'ametnik';
  doc_muud     TEXT = doc_data ->> 'muud';
  new_history  JSON;
  props_json   JSONB = (SELECT to_jsonb(row)
                        FROM (SELECT (doc_data ->> 'email') :: TEXT AS email) row);

  roles_json   JSONB = (SELECT to_jsonb(row)
                        FROM (SELECT
                                coalesce((doc_data ->> 'is_kasutaja') :: BOOLEAN, FALSE)     AS is_kasutaja,
                                coalesce((doc_data ->> 'is_peakasutaja') :: BOOLEAN, FALSE)  AS is_peakasutaja,
                                coalesce((doc_data ->> 'is_admin') :: BOOLEAN, FALSE)        AS is_admin,
                                coalesce((doc_data ->> 'is_eel_koostaja') :: BOOLEAN, FALSE) AS is_eel_koostaja,
                                coalesce((doc_data ->> 'is_eel_allkirjastaja') :: BOOLEAN,
                                         FALSE)                                              AS is_eel_allkirjastaja,
                                coalesce((doc_data ->> 'is_eel_esitaja') :: BOOLEAN, FALSE)  AS is_eel_esitaja,
                                coalesce((doc_data ->> 'is_eel_aktsepterja') :: BOOLEAN,
                                         FALSE)                                              AS is_eel_aktsepterja,
                                coalesce((doc_data ->> 'is_asutuste_korraldaja') :: BOOLEAN,
                                         FALSE)                                              AS is_asutuste_korraldaja,
                                coalesce((doc_data ->> 'is_rekl_administraator') :: BOOLEAN,
                                         FALSE)                                              AS is_rekl_administraator,
                                coalesce((doc_data ->> 'is_rekl_maksuhaldur') :: BOOLEAN,
                                         FALSE)                                              AS is_rekl_maksuhaldur
                             ) row);

  is_import    BOOLEAN = data ->> 'import';
BEGIN

  SELECT kasutaja
  INTO userName
  FROM ou.userid u
  WHERE u.id = userId AND NOT empty(admin);

  IF is_import IS NULL AND userName IS NULL
  THEN
    RAISE EXCEPTION 'kasutaja ei leidnud või puudub õigused %', user;
  END IF;

  IF (doc_id IS NULL)
  THEN
    doc_id = doc_data ->> 'id';
  END IF;

  -- вставка или апдейт docs.doc
  IF doc_id IS NULL OR doc_id = 0
  THEN

    -- проверка наличия учетной записи
    IF is_import IS NULL AND NOT exists(
        SELECT 1
        FROM pg_roles
        WHERE rolname = doc_kasutaja)
    THEN

      IF exists(SELECT id
                FROM ou.cur_userid
                WHERE id = userid AND coalesce(is_admin :: BOOLEAN, FALSE))
      THEN
        RAISE NOTICE 'new account';
        execute 'CREATE ROLE ' || quote_ident(doc_kasutaja) || ' NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION ';
        IF roles_json ->> 'is_kasutaja'
        THEN
          execute 'GRANT dbkasutaja TO ' || doc_kasutaja;
        END IF;

      ELSE

        RAISE EXCEPTION 'System role for user is not esists, kasutaja %, import %', doc_kasutaja, is_import;
      END IF;
    END IF;

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS created,
            userName AS user) row;

    INSERT INTO ou.userid (rekvid, kasutaja, ametnik, muud, roles, properties, ajalugu, status)
    VALUES
      (user_rekvid, doc_kasutaja, doc_ametnik, doc_muud, roles_json,
       props_json,
       new_history, array_position((enum_range(NULL :: DOK_STATUS)), 'active'))
    RETURNING id
      INTO new_user_id;
  ELSE

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS updated,
            userName AS user,
            u.*
          FROM ou.userid u
          WHERE u.id = doc_id) row;


    UPDATE ou.userid
    SET
      ametnik      = doc_ametnik,
      roles        = roles_json,
      muud         = doc_muud,
      properties   = props_json,
      ajalugu      = new_history
    WHERE id = doc_id
    RETURNING id
      INTO new_user_id;
  END IF;
  RETURN new_user_id;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION ou.sp_salvesta_userid(JSON, INTEGER, INTEGER) TO dbadmin;
GRANT EXECUTE ON FUNCTION ou.sp_salvesta_userid(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.sp_salvesta_userid(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT ou.sp_salvesta_userid('{"id":0,"data":{"rekvid":1, "kasutaja":"temp_2","ametnik":"test1","is_kasutaja":true}}', 1, 1);

select * from ou.userid where id = 5693

update ou.userid set roles = '{"is_admin":true}' where id = 1

SELECT *
        FROM pg_roles
        WHERE rolname = 'test_2'
*/
