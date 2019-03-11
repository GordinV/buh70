DROP FUNCTION IF EXISTS rekl.sp_luba_annuleri(INTEGER, JSON);

CREATE FUNCTION rekl.sp_luba_annuleri(IN user_id INTEGER, IN params JSON, OUT result INTEGER,
                                      OUT error_code INTEGER, OUT error_message TEXT)
  RETURNS RECORD
  LANGUAGE plpgsql
AS
$$
DECLARE
  l_id        INTEGER = params ->> 'id';
  v_luba      RECORD;
  v_toiming   RECORD;
  lnDokProp   INT;
  json_params JSON;
BEGIN
  result = 0;
  lnDokProp = 0;
  SELECT
    l.*,
    d.rekvid
    INTO v_luba
  FROM rekl.luba l
         INNER JOIN docs.doc d ON d.id = l.parentid
  WHERE parentid = l_id;

  SELECT
    0                AS id,
    0                AS number,
    v_luba.asutusid,
    v_luba.parentid  AS lubaid,
    date()           AS kpv,
    0                AS summa,
    NULL :: TEXT     AS alus,
    NULL :: TEXT     AS ettekirjutus,
    date()           AS tahtaeg,
    'ANNULLEERIMINE' AS tyyp
    INTO v_toiming;

  SELECT row_to_json(row)
         INTO json_params
  FROM (SELECT
          0                      AS id,
          row_to_json(v_toiming) AS data) row;

  result = rekl.sp_salvesta_toiming(json_params, user_id, v_luba.rekvid);

  IF NOT empty(user_id)
  THEN
    SELECT row_to_json(row)
           INTO json_params
    FROM (SELECT
            l_id AS id,
            0    AS staatus) row;
    SELECT
      qry.result,
      qry.error_code,
      qry.error_message
      INTO result, error_code, error_message
    FROM rekl.sp_muuda_lubastaatus(user_id, json_params) qry;
  END IF;

  -- удалить не активные декларации
  FOR v_toiming IN
    SELECT parentid
    FROM rekl.toiming
    WHERE lubaid = l_id
      AND (empty(saadetud) OR saadetud IS NULL)
      AND staatus IS NULL
      AND tyyp = 'DEKL'
    LOOP
      PERFORM rekl.sp_delete_toiming(user_id, v_toiming.parentid);
    END LOOP;
  RETURN;
END;
$$;

GRANT EXECUTE ON FUNCTION rekl.sp_luba_annuleri(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.sp_luba_annuleri(INTEGER, JSON) TO dbpeakasutaja;
