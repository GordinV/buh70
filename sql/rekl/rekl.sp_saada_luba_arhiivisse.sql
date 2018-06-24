DROP FUNCTION IF EXISTS rekl.sp_saada_luba_arhiivisse( INTEGER, JSON );

CREATE FUNCTION rekl.sp_saada_luba_arhiivisse(IN  user_id    INTEGER, IN params JSON, OUT result INTEGER,
                                              OUT error_code INTEGER, OUT error_message TEXT)

  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  tnRekvId ALIAS FOR $1;
  v_luba   RECORD;
  lnresult INT;
  lnDeklId INT;
BEGIN

  lnresult = 0;
  FOR v_luba IN
  SELECT luba.id
  FROM luba
  WHERE luba.rekvId = tnRekvId
        AND luba.staatus > 0
        AND luba.loppkpv < date()
        AND id IN (SELECT DISTINCT lubaid
                   FROM toiming
                   WHERE tyyp = 'PIKENDAMA'
                         AND tahtaeg < date() AND staatus > 0)
  LOOP
    RAISE NOTICE 'v_luba.id %', v_luba.id;
    lnDeklId = sp_luba_annuleri(v_luba.id);
    IF ifnull(lnDeklId, 0) > 0
    THEN
      lnresult = lnresult + 1;
    END IF;
  END LOOP;

  RETURN lnresult;

END;
$$;

GRANT EXECUTE ON FUNCTION rekl.sp_saada_luba_arhiivisse(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.sp_saada_luba_arhiivisse(INTEGER, JSON) TO dbpeakasutaja;
