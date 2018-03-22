DROP FUNCTION IF EXISTS eelarve.sp_eelproj_kinnitamine( INTEGER, JSON );

CREATE FUNCTION eelarve.sp_eelproj_kinnitamine(
      user_id       INTEGER,
      params        JSON,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD

LANGUAGE plpgsql
AS $$
DECLARE
  eelproj_id   INTEGER = coalesce((params ->> 'eelproj_id') :: INTEGER, 0); -- eelproj
  taotlus_id   INTEGER = coalesce((params ->> 'taotlus_id') :: INTEGER, 0); -- taotlus
  v_taotlus    RECORD;
  v_eelproj    RECORD;
  eelarve_json JSON;
  v_eelarve    RECORD;
  eelarve_id   INTEGER; -- eelarve ride id
  new_history  JSONB = row_to_json(row)  FROM ( SELECT
  now() AS updated,
  ( SELECT kasutaja
  FROM ou.userid
  WHERE id = user_id
  LIMIT 1) :: TEXT AS USER,
  'kinnitamine' AS status
  ) ROW;
BEGIN
  -- find eelprojekt if eelproj_id is null
  IF ((eelproj_id IS NULL or eelproj_id = 0) AND taotlus_id IS NOT NULL)
  THEN
    SELECT eelprojid
    INTO eelproj_id
    FROM docs.doc d
      INNER JOIN eelarve.taotlus t ON t.parentid = d.id
      INNER JOIN eelarve.taotlus1 t1 ON t1.parentid = t.id
    WHERE d.id = taotlus_id
    LIMIT 1;
  END IF;

  raise notice 'eelproj_id %',eelproj_id;

  IF eelproj_id IS NULL
  THEN
    -- error
    error_code = 6;
    error_message = 'Eelarve projekt ei leidnud';
    result = 0;
    RETURN;
  END IF;

  SELECT e.*
  INTO v_eelproj
  FROM eelarve.eelproj e
  WHERE e.id = eelproj_id;

  IF v_eelproj.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'closed')
  THEN
    result = 1;
    error_code = 0;
    error_message = 'Eelarve pole kinnitatud';
    RETURN;
  END IF;

  FOR v_taotlus IN
  SELECT
    t.rekvid,
    t.aasta,
    t.kuu,
    t1.summa,
    t1.muud,
    t1.kood1,
    t1.kood2,
    t1.kood3,
    t1.kood4,
    t1.kood5,
    T.kpv,
    t1.tunnus,
    t.id     AS taotlusId,
    t1.id    AS taotlus1id,
    t1.eelprojid,
    t.tunnus AS tun
  FROM docs.doc d
    INNER JOIN eelarve.taotlus t ON t.parentid = d.id
    INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
  WHERE t1.eelprojid = eelproj_id
        AND (d.id = taotlus_id OR taotlus_id IS NULL) -- kui meil on taotlus_id parameter siis, kasutame
        AND t.status = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'aktsepteeritud')
        AND empty(t1.eelarveid)

  LOOP
    -- Kontrollime aasta
    IF (SELECT fnc_aasta_kontrol(v_taotlus.rekvid, v_taotlus.kpv)) = 0
    THEN
      error_code = 1;
      error_message = 'Period on kinnitatud';
      result = 0;
      RETURN;

    END IF;

    -- Salvestame eelarve

    SELECT
      v_taotlus.aasta,
      v_taotlus.summa,
      v_taotlus.tunnus,
      v_taotlus.kood1,
      v_taotlus.kood2,
      v_taotlus.kood3,
      v_taotlus.kood4,
      v_taotlus.kood5,
      (exists(SELECT id
              FROM libs.library l
              WHERE l.library = 'TULUDEALLIKAD'
                    AND kood = v_Taotlus.kood5
                    AND l.tun5 =
                        array_position((enum_range(NULL :: ARTIKKEL_TYPE)), 'kulud'))) :: INTEGER AS is_kulud,
      v_taotlus.tun                                                                               AS is_parandus,
      eelproj_id                                                                                  AS variantid,
      (CASE WHEN NOT empty(v_taotlus.tun)
        THEN v_taotlus.kpv
       ELSE NULL END) :: DATE                                                                     AS kpv,
      'EUR'                                                                                       AS valuuta,
      1                                                                                           AS kuurs,
      v_taotlus.muud                                                                              AS muud,
      eelproj_id                                                                                  AS variantid
    INTO v_eelarve;

    SELECT row_to_json(ROW)
    INTO eelarve_json
    FROM (SELECT
            0 :: INTEGER AS id,
            v_eelarve    AS data) ROW;

    raise notice 'salvestan eelarve eelarve_json %', eelarve_json;
    eelarve_id = eelarve.sp_salvesta_eelarve(eelarve_json, user_id, v_taotlus.rekvid);
    raise notice 'salvestan eelarve eelarve_id %', eelarve_id;


    IF empty(eelarve_id)
    THEN
      -- error
      result = 0;
      error_code = 0;
      error_message = 'Eelarve rida salvestamine ebaõnnestus';
      RETURN;
    END IF;

    UPDATE eelarve.taotlus1
    SET eelarveId = eelarve_id
    WHERE id = v_taotlus.taotlus1id;

    result = 1;
    new_history = new_history::jsonb || row_to_json(row)::jsonb  FROM ( SELECT eelarve_id AS eelarveId) ROW;

  END LOOP;

  raise notice 'result %, error_code %, error_message %',result, error_code, error_message;
  RETURN;

END;
$$;


GRANT EXECUTE ON FUNCTION eelarve.sp_eelproj_kinnitamine(INTEGER, JSON) TO eelaktsepterja;
