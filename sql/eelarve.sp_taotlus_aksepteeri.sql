DROP FUNCTION IF EXISTS eelarve.sp_taotlus_aktsepteeri( INTEGER, JSON );

CREATE FUNCTION eelarve.sp_taotlus_aktsepteeri(user_id INTEGER, params JSON, OUT error_code INTEGER, OUT result INTEGER,
                                                                             OUT error_message TEXT)
  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE doc_id      INTEGER = coalesce((params ->> 'doc_id') :: INTEGER, 0);
        ttMuud      TEXT = params ->> 'muud';
        new_history JSON;
        new_eelarve JSON;

        lnTunnus    INTEGER = 0;

        lnId        INTEGER;

        tmpEelProj  RECORD;
        tmpTaotlus  RECORD;
        tmpTaotlus1 RECORD;
        tmpEelarve  RECORD;

        ldKpv       DATE;
        lcSelg      TEXT;
        lnKuurs     NUMERIC;
BEGIN
  IF doc_id IS NULL
  THEN
    error_code = 6;
    error_message = 'Parameter doc_id not exists, docId: ' || coalesce(doc_id, 0) :: TEXT;
    result = 0;
    RETURN;
  END IF;

  SELECT t.*
  INTO tmpTaotlus
  FROM eelarve.taotlus t
  WHERE t.parentid = doc_id
        AND docs.usersRigths(t.parentid, 'EelAktsepterja', user_id);

  IF tmpTaotlus IS NULL
  THEN
    error_code = 6;
    error_message = 'Document not exists or not enough rights , docId: ' || coalesce(doc_id, 0) :: TEXT;
    result = 0;
    RETURN;
  END IF;

  IF tmpTaotlus.status = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'esitatud')
  THEN
    UPDATE eelarve.taotlus
    SET status  = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'aktsepteeritud'),
      aktseptid = user_id,
      timestamp = now()
    WHERE parentid = doc_id;

    -- ajalugu
    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()             AS updated,
            (SELECT kasutaja
             FROM ou.userid
             WHERE id = user_id
             LIMIT 1) :: TEXT AS user,
            'aktsepteeri'     AS status
         ) row;

    -- will check if arvId exists
    UPDATE docs.doc
    SET
      lastupdate = now(),
      history    = coalesce(history, '[]') :: JSONB || new_history :: JSONB
    WHERE id = doc_id;

    result = 1;
  ELSE
    result = 0;
    error_message = 'Vale taotluse staatus';
    RETURN;
  END IF;

  lnKuurs = fnc_currentkuurs(tmpTaotlus.Kpv);

  --* eelarve projektide side
  SELECT
    e.id,
    e.status,
    e.muud
  INTO tmpEelProj
  FROM eelarve.eelproj e
  WHERE e.aasta = tmptaotlus.aasta
        AND e.status > 0
        AND e.rekvid = tmpTaotlus.rekvid
  ORDER BY e.status DESC
  LIMIT 1;

  IF tmpEelProj IS NULL
  THEN
    result = 0;
    error_code = 6;
    error_message = 'Eelarve projekt ei leidnud , docId: ' || coalesce(doc_id, 0) :: TEXT;
    RETURN;
  END IF;

  --* eelarve side
  IF tmpEelProj.status = array_position((enum_range(NULL :: DOK_STATUS)), 'closed')
  THEN
    --		* eelarve mitte projekt

    lnTunnus = 1;
    --		* eelarve juba kinnitatud siis see on parandamine
    FOR tmpTaotlus1 IN
    SELECT t1.*
    FROM eelarve.taotlus1 t1
    WHERE t1.parentid = tmpTaotlus.id AND (t1.eelarveid IS NULL OR empty(t1.eelarveid))
    LOOP

      IF tmpTaotlus.tunnus = 1
      THEN
        lnTunnus = 1;
        ldKpv = tmpTaotlus.kpv;
        lcSelg = tmpTaotlus.muud;
        -- parandamine
        IF NOT empty(ttMuud)
        THEN
          lcSelg = ttMuud;
        END IF;

      ELSE
        lnTunnus = 0;
        ldKpv = NULL;
        lcSelg = tmpEelProj.muud;

      END IF;

      --koostame eelarve

      SELECT
        tmpTaotlus.aasta,
        tmpTaotlus1.summa,
        tmpTaotlus1.tunnus,
        tmpTaotlus1.kood1,
        tmpTaotlus1.kood2,
        tmpTaotlus1.kood3,
        tmpTaotlus1.kood4,
        tmpTaotlus1.kood5,
        (exists(SELECT id
                FROM libs.library l
                WHERE l.library = 'TULUDEALLIKAD'
                      AND kood = tmpTaotlus1.kood5
                      AND l.tun5 =
                          array_position((enum_range(NULL :: ARTIKKEL_TYPE)), 'kulud'))) :: INTEGER AS is_kulud,
        lnTunnus                                                                                    AS is_parandus,
        tmpEelProj.id                                                                               AS variantid,
        ldKpv :: DATE                                                                               AS kpv,
        'EUR'                                                                                       AS valuuta,
        1                                                                                           AS kuurs,
        lcSelg                                                                                      AS muud
      INTO tmpEelarve;

      SELECT row_to_json(row)
      INTO new_eelarve
      FROM (SELECT
              0          AS id,
              tmpEelarve AS data
           ) row;


      lnId = eelarve.sp_salvesta_eelarve(new_eelarve, user_id, tmpTaotlus.rekvId);

      IF lnId > 0
      THEN
        UPDATE eelarve.taotlus1
        SET eelarveId = lnId
        WHERE id = tmpTaotlus1.id;

      ELSE
        result = 0;
        error_code = 1;
        error_message = 'Eelarve salvestamine õnnestu';
        EXIT;
      END IF;

    END LOOP;
  ELSE
    error_message = 'Eelarve projekt ei ole kinnitatud';
  END IF;

  RETURN;

END;
$$;
