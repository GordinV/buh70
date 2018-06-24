DROP FUNCTION IF EXISTS rekl.sp_recalc_rekl_jaak( IN user_id INTEGER, IN params JSON );

CREATE FUNCTION rekl.sp_recalc_rekl_jaak(IN  user_id    INTEGER, IN params JSON, OUT result INTEGER,
                                         OUT error_code INTEGER, OUT error_message TEXT)
  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  l_id       INTEGER = params ->> 'id';
  l_tasud    NUMERIC = 0;
  lnAlgsaldo NUMERIC = 0;
  lnKr1      NUMERIC = 0;
  lnKr2      NUMERIC = 0;
  lnDb       NUMERIC = 0;
  lnIntress  NUMERIC = 0;
  lnVolg     NUMERIC = 0;
  l_jaak     NUMERIC = 0;
  v_luba     RECORD;
  v_user     RECORD;
BEGIN
  SELECT
    kasutaja,
    rekvid
  INTO v_user
  FROM ou.userid u
  WHERE u.id = user_Id;

  IF v_user.kasutaja IS NULL
  THEN
    error_code = 5;
    error_message = 'Kasutaja ei leitud,  userId:' ||
                    coalesce(user_id, 0) :: TEXT;
    result = 0;
    RETURN;
  END IF;


  SELECT
    id,
    jaak,
    volg,
    intress,
    staatus
  INTO v_luba
  FROM rekl.luba
  WHERE luba.parentid = l_id;

  IF v_luba.id is null
  THEN
    error_code = 5;
    error_message = 'Dokument ei leidnud ' || l_id :: TEXT;
    result = 0;
    RETURN;
  END IF;
  result = 1;
  IF v_luba.staatus = 1
  THEN
    -- algsaldo

    SELECT
      sum(summa)
        FILTER (WHERE tyyp = 'ALGSALDO')                                                           AS algsaldo,
      sum(summa)
        FILTER (WHERE (tyyp IN ('DEKL', 'PARANDUS') AND NOT empty(saadetud)) AND tahtaeg > date()) AS kr1,
      sum(summa)
        FILTER (WHERE ((tyyp IN ('DEKL') AND NOT empty(saadetud)) OR tyyp IN ('PARANDUS', 'INTRESS')) AND
                      tahtaeg <= date())                                                           AS kr2,
      sum(summa)
        FILTER (WHERE tyyp = 'INTRESS')                                                            AS intress,
      sum(summa)
        FILTER (WHERE tyyp = 'TASU')                                                               AS intress
    INTO lnAlgsaldo, lnKr1, lnKr2, lnIntress, lnDb
    FROM rekl.toiming
    WHERE lubaId = v_luba.id
          AND staatus <> 'deleted';

    -- tasud summa
    SELECT sum(summa)
    INTO l_tasud
    FROM rekl.dekltasu
    WHERE deklId IN (
      SELECT t.id
      FROM rekl.toiming t
      WHERE tyyp = 'INTRESS' AND staatus <> 'deleted' AND lubaId = v_luba.id
    );

    lnIntress = lnIntress - coalesce(l_tasud, 0);

    l_jaak = (lnAlgsaldo + lnKr1 + lnKr2) - lnDb;

    -- volg = lnKr2 - lnDb
    lnVolg = (lnAlgsaldo + lnKr2) - lnDb;

    IF lnVolg < 0
    THEN
      lnVolg = 0;
    END IF;

    l_jaak = round(l_jaak, 2);
    lnVolg = round(lnVolg, 2);
    lnIntress = round(lnIntress, 2);

    IF coalesce(v_luba.Jaak, 0) <> l_jaak OR coalesce(v_luba.volg, 0) <> lnVolg OR
       coalesce(v_luba.intress, 0) <> lnIntress
    THEN
      UPDATE rekl.luba
      SET jaak  = l_tasud,
        volg    = lnVolg,
        intress = lnIntress
      WHERE id = v_luba.id;
      result = 1;
    END IF;
  END IF;

  IF v_luba.staatus = 0
  THEN
    error_message = 'Luba anuleeritud, nullime saldo:';

    UPDATE rekl.luba
    SET jaak  = 0,
      volg    = 0,
      intress = 0
    WHERE id = v_luba.id;
    result = 1;
  END IF;

  RETURN;
END;
$$;

GRANT EXECUTE ON FUNCTION rekl.sp_recalc_rekl_jaak(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.sp_recalc_rekl_jaak(INTEGER, JSON) TO dbpeakasutaja;
