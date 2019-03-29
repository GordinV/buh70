DROP FUNCTION IF EXISTS eelarve.sp_kooperi_taotlus(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.sp_kooperi_taotlus(user_id INTEGER,
                                                      doc_id INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  v_taotlus      RECORD;
  v_taotlus1     RECORD;
  l_doc_json     TEXT;
  l_details_json TEXT;
  l_json         TEXT;
  l_doc_id       INTEGER;
BEGIN
  -- paring andmed

  SELECT
    0                                                  AS id,
    user_id :: INTEGER                                 AS userid,
    to_char(created, 'DD.MM.YYYY HH:MM:SS') :: TEXT    AS created,
    to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS') :: TEXT AS lastupdate,
    current_date                                       AS kpv,
    t.rekvid,
    user_id                                            AS koostajaid,
    t.aasta,
    t.kuu,
    t.tunnus,
    0                                                  AS status,
    t.muud
    INTO v_taotlus
  FROM docs.doc d
         INNER JOIN eelarve.taotlus t ON t.parentId = d.id
         INNER JOIN ou.userid u ON u.id = user_id :: INTEGER
  WHERE d.id = doc_id;
  -- salvetsame
  l_doc_json = row_to_json(v_taotlus) :: TEXT;

  FOR v_taotlus1 IN
    SELECT
      0                  AS id,
      user_id :: INTEGER AS userid,
      t1.summa,
      t1.tunnus,
      t1.proj,
      t1.kood1,
      t1.kood2,
      t1.kood3,
      t1.kood4,
      t1.kood5,
      t1.selg,
      t1.muud
    FROM eelarve.taotlus1 AS t1
           INNER JOIN eelarve.taotlus t ON t.id = t1.parentId
    WHERE t.parentid = doc_id
    LOOP
      l_details_json = coalesce(l_details_json, '') :: TEXT || CASE WHEN l_details_json IS NULL THEN '' ELSE ',' END ||
                       row_to_json(v_taotlus1) :: TEXT;
    END LOOP;

  l_json = ('{"data":' || trim(TRAILING FROM l_doc_json, '}')::TEXT || ',"gridData":[' || l_details_json || ']}}');

  l_doc_id = eelarve.sp_salvesta_taotlus(l_json::JSON, user_id, v_taotlus.rekvid);

  RETURN l_doc_id;
END;
$BODY$
  LANGUAGE plpgsql
  VOLATILE
  COST 100;

GRANT EXECUTE ON FUNCTION eelarve.sp_kooperi_taotlus(INTEGER, INTEGER) TO eelkoostaja;

/*

select * from eelarve.taotlus order by id desc limit 10

select eelarve.sp_kooperi_taotlus(70, 1613390)

select * from eelarve.taotlus where parentid = 1613406

*/