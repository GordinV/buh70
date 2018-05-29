DROP FUNCTION IF EXISTS docs.sp_salvesta_palk_lib( JSON, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS libs.sp_salvesta_palk_lib( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION libs.sp_salvesta_palk_lib(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  lib_id      INTEGER;
  userName    TEXT;
  doc_id      INTEGER = data ->> 'id';
  is_import boolean = data->>'import';
  doc_data    JSON = data ->> 'data';
  doc_kood    TEXT = doc_data ->> 'kood';
  doc_nimetus TEXT = doc_data ->> 'nimetus';
  doc_library TEXT = 'PALK';
  doc_tun1    INTEGER = doc_data ->> 'tun1';
  doc_tun2    INTEGER = doc_data ->> 'tun2';
  doc_tun3    INTEGER = doc_data ->> 'tun3';
  doc_tun4    INTEGER = doc_data ->> 'tun4';
  doc_tun5    INTEGER = doc_data ->> 'tun5';
  doc_liik INTEGER = doc_data ->> 'liik';
  doc_tululiik varchar(20) = doc_data ->> 'tululiik';
  doc_tund INTEGER = doc_data ->> 'tund';
  doc_maks Integer = doc_data ->> 'maks';
  doc_asutusest Integer = doc_data ->> 'asutusest';
  doc_palgafond Integer = doc_data ->> 'palgafond';
  doc_sots Integer = doc_data ->> 'sots';
  doc_elatis Integer = doc_data ->> 'elatis';
  doc_round Numeric(12,4) = doc_data ->> 'round';
  doc_konto varchar(20) = doc_data ->> 'konto';
  doc_korrkonto varchar(20) = doc_data ->> 'korrkonto';
  doc_tunnusid Integer = doc_data ->> 'tunnusid';
  doc_muud    TEXT = doc_data ->> 'muud';
  doc_uuritus varchar(20) = doc_data ->> 'uuritus';
  doc_proj varchar(20) = doc_data ->> 'proj';
  doc_tegev varchar(20) = doc_data ->> 'tegev';
  doc_allikas varchar(20) = doc_data ->> 'allikas';
  doc_artikkel varchar(20) = doc_data ->> 'artikkel';
  json_object JSONB;
BEGIN

  IF (doc_id IS NULL)
  THEN
    doc_id = doc_data ->> 'id';
  END IF;


  SELECT kasutaja
  INTO userName
  FROM userid u
  WHERE u.rekvid = user_rekvid AND u.id = userId;
  IF is_import is null and userName IS NULL
  THEN
    RAISE NOTICE 'User not found %', user;
    RETURN 0;
  END IF;

  SELECT row_to_json(row)
  INTO json_object
  FROM (SELECT doc_liik as liik,  doc_tund as tund, doc_maks as maks, doc_asutusest as asutusest,
      doc_palgafond as palgafond, doc_sots as sots, doc_round as round,doc_konto as konto, doc_elatis as elatis,
       doc_korrkonto as korrkonto, doc_tunnusid as tunnusid, doc_uuritus as uuritus, doc_proj as proj,
       doc_tegev as tegev, doc_allikas as allikas, doc_artikkel as artikkel, doc_tululiik as tululiik) row;

  -- вставка или апдейт docs.doc
  IF doc_id IS NULL OR doc_id = 0
  THEN

    INSERT INTO libs.library (rekvid, kood, nimetus, library, tun1, tun2, tun3, tun4, tun5, muud, properties)
    VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library, doc_tun1, doc_tun2, doc_tun3, doc_tun4, doc_tun5,
        doc_muud, json_object)
    RETURNING id
      INTO lib_id;


  ELSE

    UPDATE libs.library
    SET
      kood       = doc_kood,
      nimetus    = doc_nimetus,
      library    = doc_library,
      properties = json_object,
      tun1       = doc_tun1,
      tun2       = doc_tun2,
      tun3       = doc_tun3,
      tun4       = doc_tun4,
      tun5       = doc_tun5,
      muud       = doc_muud
    WHERE id = doc_id
    RETURNING id
      INTO lib_id;

  END IF;

  RETURN lib_id;

  EXCEPTION WHEN OTHERS
  THEN
     RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
     RETURN 0;


END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_palk_lib(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_palk_lib(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT libs.sp_salvesta_konto('{"id":38,"data":{"doc_type_id":"KONTOD","id":38,"konto_tyyp":null,"kood":"620","library":"KONTOD","muud":"test kontod","nimetus":"Sotsiaalmaks töötasult","rekvid":1,"tun1":1,"tun2":1,"tun3":0,"tun4":0,"tyyp":1,"userid":1,"valid":"20181231"}}'
,1, 1)
*/