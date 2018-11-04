DROP FUNCTION IF EXISTS palk.sp_calc_puhkuse_paevad( INTEGER, JSON );

CREATE FUNCTION palk.sp_calc_puhkuse_paevad(IN  user_id       INTEGER,
                                            IN  params        JSON,
                                            OUT error_code    INTEGER,
                                            OUT result        INTEGER,
                                            OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$
DECLARE
  leping_id          INTEGER = params ->> 'lepingid';
  v_leping           RECORD;
  l_kpv              DATE = params ->> 'kpv';
  l_puhkus           TEXT = 'PUHKUS';
  l_puhkuse_tyyp     INTEGER = coalesce((params ->> 'tyyp') :: INTEGER, 1);
  l_aasta            INTEGER;
  l_params           JSON;
  l_puhkus_kasutatud INTEGER = 0;
  l_puhkuse_paevad   INTEGER = 28; -- tavaline puhkus
  is_ametnik         BOOLEAN = FALSE;
BEGIN
  error_code = 0; --default

  SELECT *
  INTO v_leping
  FROM palk.tooleping
  WHERE id = leping_id;

  IF v_leping.id IS NULL
  THEN
    error_code = 6;
    error_message = 'Vale parameter';
    RETURN;
  END IF;

  IF l_puhkuse_tyyp = 3
  THEN
    -- lapse puhkus
    l_puhkuse_paevad = 3;
  ELSE

    -- kui töötab väisem 365 p.
    IF l_puhkuse_tyyp = 1 AND (v_leping.algab + INTERVAL '1 year') < current_date
    THEN
      l_puhkuse_paevad = ceil(l_puhkuse_paevad / 12 * _diffmonth(v_leping.algab, current_date));
      -- calc sunnipaev
      -- get isikukood

      SELECT row_to_json(row)
      INTO l_params
      FROM (SELECT regkood AS isikukood
            FROM libs.asutus
            WHERE id IN (SELECT parentid
                         FROM palk.tooleping t
                         WHERE id = leping_id)) row;


      SELECT qry.result
      INTO l_aasta
      FROM palk.fnc_get_sunnipaev(1, l_params) qry;

      -- is aasta < 18
      IF l_aasta < 18 OR exists((SELECT 1
                                 FROM palk.tooleping t
                                 WHERE id = leping_id AND NOT empty(t.ametnik :: INTEGER)))
      -- is ametnik ?

      THEN
        -- must be 35 days
        l_puhkuse_paevad = 35;
      END IF;

    END IF;

    -- paevad kasutatud
    SELECT sum(paevad) AS paevad
    INTO l_puhkus_kasutatud
    FROM palk.cur_puudumine
    WHERE lepingid = leping_id
          AND kpv1 >= date(year(date()), 1, 1)
          AND kpv2 <= l_kpv
          AND pohjus = l_puhkus
          AND tyyp = l_puhkuse_tyyp;


  END IF;

  result = l_puhkuse_paevad - coalesce(l_puhkus_kasutatud, 0);
  RETURN;

END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION palk.sp_calc_puhkuse_paevad(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_calc_puhkuse_paevad(INTEGER, JSON) TO dbpeakasutaja;


COMMENT ON FUNCTION palk.sp_calc_puhkuse_paevad(INTEGER, JSON) IS 'расчет дней к отпуску';


/*
SELECT * from palk.sp_calc_puhkuse_paevad(1, '{"lepingid":4}')

select * from palk.tooleping
*/