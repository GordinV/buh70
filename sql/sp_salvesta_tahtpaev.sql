DROP FUNCTION IF EXISTS libs.sp_salvesta_tahtpaev( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION libs.sp_salvesta_tahtpaev(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  lib_id      INTEGER;
  userName    TEXT;
  doc_id      INTEGER = data ->> 'id';
  doc_data    JSON = data ->> 'data';
  doc_kood    TEXT = doc_data ->> 'kood';
  doc_nimetus TEXT = doc_data ->> 'nimetus';
  doc_library TEXT = 'TAHTPAEV';
  doc_paev integer = doc_data ->> 'paev';
  doc_kuu integer = doc_data ->> 'kuu';
  doc_aasta integer = doc_data ->> 'aasta';
  doc_luhipaev integer = doc_data ->> 'luhipaev';
  doc_muud text = doc_data ->> 'muud';
  json_object JSONB;
BEGIN

  IF (doc_id IS NULL)
  THEN
    doc_id = doc_data ->> 'id';
  END IF;

  if (doc_paev is not null and doc_paev < 1 or doc_paev > 31) then
    RAISE NOTICE 'Vale kuupäev %', doc_paev;
    RETURN 0;
  end if;

  if (doc_kuu is not null and doc_kuu < 1 or doc_kuu > 12) then
    RAISE NOTICE 'Vale kuu %', doc_kuu;
    RETURN 0;
  end if;

  if (doc_aasta is not null and doc_aasta < 2018 or doc_kuu > year(date()) + 2) then
      RAISE NOTICE 'Vale aasta %', doc_aasta;
  RETURN 0;
end if;

SELECT kasutaja
INTO userName
FROM userid u
WHERE u.rekvid = user_rekvid AND u.id = userId;
IF userName IS NULL
THEN
  RAISE NOTICE 'User not found %', user;
  RETURN 0;
END IF;

SELECT row_to_json(row)
INTO json_object
FROM (SELECT doc_luhipaev as luhipaev, doc_paev as paev, doc_kuu as kuu, doc_aasta as aasta) row;

-- вставка или апдейт docs.doc
IF doc_id IS NULL OR doc_id = 0
THEN

  INSERT INTO libs.library (rekvid, kood, nimetus, library,  muud, properties)
  VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library, doc_muud, json_object)
  RETURNING id
    INTO lib_id;


ELSE

  UPDATE libs.library
  SET
    kood       = doc_kood,
    nimetus    = doc_nimetus,
    library    = doc_library,
    properties = json_object,
    muud       = doc_muud
  WHERE id = doc_id
  RETURNING id
    INTO lib_id;


  -- uuenda pv_kaart konto

  --	UPDATE docs.pv_kaart SET konto = doc_konto WHERE gruppid = lib_id;

END IF;

RETURN lib_id;

EXCEPTION WHEN OTHERS
THEN
RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
RETURN 0;


END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_tahtpaev(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_tahtpaev(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT libs.sp_salvesta_pv_grupp('{"id":0,"data":{"doc_type_id":"PVGRUPP","id":0,"konto":"5001","kood":"__test3367","kulum_konto":"1901","library":"PVGRUPP","muud":null,"nimetus":"vfp test PVGRUPP","rekvid":1,"status":0,"tun1":null,"tun2":null,"userid":1}}'
,1, 1)

*/