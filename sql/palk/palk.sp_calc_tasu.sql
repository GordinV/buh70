DROP FUNCTION IF EXISTS palk.sp_calc_tasu( INTEGER, INTEGER, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS palk.sp_calc_tasu(params JSONB );
DROP FUNCTION IF EXISTS palk.sp_calc_tasu(user_id INTEGER, params JSON );

CREATE FUNCTION palk.sp_calc_tasu(user_id       INTEGER, params JSON,
  OUT                             summa         NUMERIC,
  OUT                             selg          TEXT,
  OUT                             error_code    INTEGER,
  OUT                             result        INTEGER,
  OUT                             error_message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  l_lepingid   INTEGER = params ->> 'lepingid';
  l_libId      INTEGER = params ->> 'libid';
  l_kpv        DATE = coalesce((params ->> 'kpv') :: DATE, current_date);
  is_percent   BOOLEAN = coalesce((params ->> 'is_percent') :: BOOLEAN,
                                  TRUE); -- kas pk summa percentis (100%)
  l_alus_summa NUMERIC(12, 4) = params ->> 'alus_summa'; -- tasu summa , milliest arvestame VM
  l_pk_summa   NUMERIC = coalesce((params ->> 'summa') :: NUMERIC, 100);
  l_round      NUMERIC = 0.01;
BEGIN

  IF l_alus_summa IS NULL
  THEN
    -- parameter puudub, võttame summad andmebaasist

    SELECT
      pk.percent_,
      pk.summa,
      l.round
    INTO is_percent, l_pk_summa, l_round
    FROM palk.palk_kaart pk
      INNER JOIN palk.com_palk_lib l ON pk.libid = l.id
    WHERE pk.lepingid = l_lepingid
          AND pk.libId = l_libId;

    IF is_percent
    THEN
      -- otsime jaak
      SELECT sum(pj.jaak)
      INTO l_alus_summa
      FROM palk.Palk_jaak pj
      WHERE pj.lepingId = l_lepingid
            AND pj.kuu = MONTH(l_kpv)
            AND pj.aasta = YEAR(l_kpv);
    END IF;
  END IF;

  IF is_percent
  THEN
    summa = f_round(l_pk_summa * 0.01 * l_alus_summa, l_round);
    selg = l_pk_summa :: TEXT || ' * 0.01 * ' || l_alus_summa :: TEXT;
  ELSE
    summa = f_round(l_pk_summa, l_round);
    selg = l_pk_summa :: TEXT;
  END IF;
  summa = coalesce(summa, 0);
  result = 1;
  RETURN;
END;
$$;

/*
select * from palk.sp_calc_tasu(1, '{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSON)
select * from  palk.sp_calc_tasu(1, '{"alus_summa":100}'::JSON)
select * from palk.sp_calc_tasu(1, '{"alus_summa":0,"summa":100,"is_percent":false}'::JSON)
*/