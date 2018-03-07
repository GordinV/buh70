DROP FUNCTION IF EXISTS libs.sp_salvesta_pv_kaart( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION libs.sp_salvesta_pv_kaart(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  lib_id         INTEGER;
  userName       TEXT;
  doc_id         INTEGER = data ->> 'id';
  doc_data       JSON = data ->> 'data';
  doc_kood       TEXT = doc_data ->> 'kood';
  doc_nimetus    TEXT = doc_data ->> 'nimetus';
  doc_library    TEXT = 'POHIVARA';
  doc_gruppid    INTEGER = doc_data ->> 'gruppid';
  doc_konto      TEXT = doc_data ->> 'konto';
  doc_soetkpv    DATE = (CASE WHEN empty((doc_data ->> 'soetkpv') :: TEXT)
    THEN NULL
                         ELSE (doc_data ->> 'soetkpv') END) :: DATE;
  doc_kulum      NUMERIC(12, 4) = doc_data ->> 'kulum';
  doc_algkulum   NUMERIC(12, 2) = doc_data ->> 'algkulum';
  doc_soetmaks   NUMERIC(12, 2) = doc_data ->> 'soetmaks';
  doc_selg       TEXT = doc_data ->> 'selg';
  doc_vastisikid INTEGER = doc_data ->> 'vastisikid';
  doc_rentnik    TEXT = doc_data ->> 'rentnik';
  doc_liik       TEXT = doc_data ->> 'liik';
  doc_muud       TEXT = doc_data ->> 'muud';
  doc_valuuta    TEXT = coalesce((doc_data ->> 'valuuta') :: TEXT, 'EUR');
  doc_kuurs      NUMERIC(12, 4) = coalesce((doc_data ->> 'kuurs') :: NUMERIC, 1);
  json_object    JSONB;
  a_dokvaluuta   TEXT [] = enum_range(NULL :: DOK_VALUUTA);

BEGIN

  IF (doc_id IS NULL)
  THEN
    doc_id = doc_data ->> 'id';
  END IF;

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
  FROM (SELECT
          doc_gruppid                    AS gruppid,
          doc_konto                      AS konto,
          doc_soetkpv                    AS soetkpv,
          doc_kulum                      AS kulum,
          doc_algkulum                   AS algkulum,
          doc_soetmaks                   AS soetmaks,
          doc_selg                       AS selg,
          doc_vastisikid                 AS vastisikid,
          doc_rentnik                    AS rentnik,
          coalesce(doc_liik, 'põhivara') AS liik) row;

  -- вставка или апдейт docs.doc
  IF doc_id IS NULL OR doc_id = 0
  THEN

    INSERT INTO libs.library (rekvid, kood, nimetus, library, muud, properties, status)
    VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library, doc_muud,
            json_object, 1)
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
  END IF;


  IF NOT exists(SELECT id
                FROM docs.dokvaluuta1
                WHERE dokid = lib_id AND dokliik = array_position(a_dokvaluuta, 'pv_kaart'))
  THEN
    -- if record does
    INSERT INTO docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs)
    VALUES (lib_id, array_position(a_dokvaluuta, 'pv_kaart'), doc_valuuta, doc_kuurs);

  END IF;


  RETURN lib_id;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_pv_kaart(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_pv_kaart(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*
select libs.sp_salvesta_pv_kaart(
'{"id":0,"data":{"algkulum":0,"doc_type_id":"POHIVARA","gruppid":393,"id":0,"jaak":0,"konto":null,"kood":"RCT_90878","kulum":20,"kuurs":1,"library":"POHIVARA","liik":"p?µhivara","mahakantud":null,"muud":null,"nimetus":"real card test PV_KAART","parhind":0,"rekvid":1,"rentnik":null,"selg":null,"soetkpv":"20180301","soetmaks":1000,"status":0,"userid":1,"valuuta":"EUR","vastisikid":null}}'
,1, 1)
*/