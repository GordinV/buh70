DROP FUNCTION IF EXISTS eelarve.sp_salvesta_aastakassakulud ( JSON, INTEGER, INTEGER );

CREATE FUNCTION eelarve.sp_salvesta_aastakassakulud(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER

LANGUAGE plpgsql
AS $$
DECLARE
  l_id         INTEGER = DATA ->> 'id';
  doc_data     JSON = data ->> 'data';
  doc_summa    NUMERIC = doc_data ->> 'summa';
  doc_valuuta  TEXT = coalesce((doc_data ->> 'valuuta'), 'EUR');
  doc_kuurs    NUMERIC = coalesce((doc_data ->> 'kuurs') :: NUMERIC, 1);
  doc_tegev    TEXT = doc_data ->> 'tegev';
  doc_allikas  TEXT = doc_data ->> 'allikas';
  doc_artikkel TEXT = doc_data ->> 'artikkel';
  doc_kpv      DATE = doc_data ->> 'kpv';
  doc_aasta    INTEGER = coalesce((doc_data ->> 'aasta') :: INTEGER, date_part('year', doc_kpv));
  doc_kuu      INTEGER = coalesce((doc_data ->> 'kuu') :: INTEGER, date_part('month', doc_kpv));
  doc_rekvid   INTEGER = doc_data ->> 'rekvid';

  l_oma_tp     CHARACTER VARYING;

BEGIN


  IF (l_id IS NULL)
  THEN
    l_id = doc_data ->> 'id';
  END IF;

  l_oma_tp = fnc_getomatp(doc_rekvid, doc_aasta);

  IF l_id = 0
  THEN
    -- uus kiri
    INSERT INTO eelarve.aasta_kassa_kulud (summa, valuuta, kuurs, tegev, allikas, art, kpv, aasta, kuu, rekvid, omatp, tyyp)
    VALUES
      (doc_summa, doc_valuuta, doc_kuurs, doc_tegev, doc_allikas, doc_artikkel, doc_kpv, doc_aasta, doc_kuu, doc_rekvid,
                  l_oma_tp, 1)
    RETURNING id
      INTO l_id;

    INSERT INTO eelarve.eeltaitmine (rekvid, aasta, kuu, kood1, kood2, kood4, kood5, proj, objekt, summa)
    VALUES (doc_rekvid, doc_aasta, doc_kuu, doc_tegev, doc_allikas, doc_artikkel, doc_artikkel, '', '', doc_summa);

  ELSE
    -- muuda
    UPDATE eelarve.aasta_kassa_kulud
    SET
      summa   = doc_summa,
      valuuta = doc_valuuta,
      kuurs   = doc_kuurs,
      tegev   = doc_tegev,
      allikas = doc_allikas,
      art     = doc_artikkel,
      kpv     = doc_kpv,
      aasta   = doc_aasta,
      kuu     = doc_kuu,
      rekvid  = doc_rekvid,
      omatp   = l_oma_tp
    WHERE id = l_id;

  END IF;

  RETURN l_id;
END;
$$;

GRANT EXECUTE ON FUNCTION eelarve.sp_salvesta_aastakassakulud(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.sp_salvesta_aastakassakulud(JSON, INTEGER, INTEGER) TO dbpeakasutaja;
