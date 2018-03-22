DROP FUNCTION IF EXISTS ou.sp_salvesta_userid( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION ou.sp_salvesta_userid(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  new_user_id      INTEGER;
  userName         TEXT;
  doc_id           INTEGER = data ->> 'id';
  doc_data         JSON = data ->> 'data';
  doc_kasutaja     TEXT = doc_data ->> 'kasutaja';
  doc_ametnik      TEXT = doc_data ->> 'ametnik';
  doc_kasutaja_    INTEGER = doc_data ->> 'kasutaja_';
  doc_peakasutaja_ INTEGER = doc_data ->> 'peakasutaja_';
  doc_admin        INTEGER = doc_data ->> 'admin';
  doc_muud         TEXT = doc_data ->> 'muud';
  new_history      JSON;
  roles_json       JSON = (SELECT row_to_json(row)
                           FROM (SELECT
                                   doc_kasutaja_    AS kasutaja,
                                   doc_peakasutaja_ AS peakasutaja,
                                   doc_admin        AS admin) row);

BEGIN

  SELECT kasutaja
  INTO userName
  FROM ou.userid u
  WHERE u.id = userId AND NOT empty(admin);

  IF userName IS NULL
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
    IF NOT exists(
        SELECT 1
        FROM pg_roles
        WHERE rolname = doc_kasutaja)
    THEN
      RAISE EXCEPTION 'System role for user is not esists, kasutaja %', doc_kasutaja;
      --  CREATE ROLE (doc_kasutaja);

    END IF;


    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS created,
            userName AS user) row;

    INSERT INTO ou.userid (rekvid, kasutaja, ametnik, kasutaja_, peakasutaja_, admin, muud, roles, ajalugu, status)
    VALUES
      (user_rekvid, doc_kasutaja, doc_ametnik, doc_kasutaja_, doc_peakasutaja_, doc_admin, doc_muud, roles_json,
       new_history,
       array_position((enum_range(NULL :: DOK_STATUS)), 'active'))
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
      kasutaja_    = doc_kasutaja_,
      peakasutaja_ = doc_peakasutaja_,
      admin        = doc_admin,
      muud         = doc_muud,
      roles        = roles_json,
      muud         = doc_muud,
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
SELECT ou.sp_salvesta_rekv('{"id":0,"data":{"aadress":null,"doc_type_id":"REKV","email":null,"faks":null,"haldus":null,"id":0,"juht":null,"kbmkood":null,"muud":null,"nimetus":"vfp rekv test","parentid":0,"raama":null,"regkood":"__test8514","tel":null,"userid":1}}', 1, 1);

*/
