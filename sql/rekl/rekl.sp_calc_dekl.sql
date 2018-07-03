DROP FUNCTION IF EXISTS rekl.sp_calc_dekl( INTEGER );
DROP FUNCTION IF EXISTS rekl.sp_calc_dekl( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION rekl.sp_calc_dekl(l_luba_doc_id INTEGER, l_user_id INTEGER)
  RETURNS SMALLINT AS
$BODY$

DECLARE

  v_luba        RECORD;

  lnPeriod      INT;
  l_dekl_period INT;
  l_kpv         DATE;
  l_alg_kpv     DATE;
  l_lopp_kpv    DATE;
  l_tahtaeg     DATE;
  l_dokprop_id  INT;
  l_toiming_id  INT;
  l_dekl_number INT;
  l_summa       NUMERIC;
  v_toiming     RECORD;
  json_params   JSON;
BEGIN
  SELECT l.*
  INTO v_luba
  FROM rekl.luba l
    INNER JOIN docs.doc d ON d.id = l.parentid
  WHERE l.parentid = l_luba_doc_id;

  l_dekl_period = 0;
  -- dok liik
  l_dokprop_id = (SELECT d.id
                  FROM libs.library l
                    INNER JOIN libs.dokprop d ON l.id = d.parentid
                  WHERE l.kood = 'DEKL'
                        AND l.library = 'DOK'
                        AND rekvid = v_luba.rekvid
                  ORDER BY id DESC
                  LIMIT 1);

  IF v_luba.staatus IS NULL OR v_luba.staatus = 0
  THEN
    RAISE EXCEPTION 'Luba anulleritud';
    RETURN 0;
  END IF;

  -- kustatme vana dekl

  DELETE FROM rekl.toiming
  WHERE lubaid = v_luba.id AND empty(saadetud) AND staatus = 'active' AND tyyp = 'DEKL';

  l_alg_kpv = date(year(v_luba.algkpv), 1, 1);
  l_lopp_kpv = date(year(v_luba.algkpv), 12, 31);
  --	ldLoppKpv = date(year(v_luba.loppkpv), 12,31);

  IF v_luba.kord = 'PAEV'
  THEN
    lnPeriod = l_lopp_kpv - l_alg_kpv;
    l_dekl_period = 1;
  ELSEIF v_luba.kord = 'NADAL'
    THEN
      lnPeriod = ceil((l_lopp_kpv - l_alg_kpv) / 7);
      l_dekl_period = ceil((v_luba.algkpv - l_alg_kpv) / 7);
  ELSEIF v_luba.kord = 'KUU'
    THEN
      lnPeriod = ceil(month(l_lopp_kpv) - month(l_alg_kpv) + 1);
      l_dekl_period = month(v_luba.algkpv) - month(l_alg_kpv);
  ELSEIF v_luba.kord = 'KVARTAL'
    THEN
      lnPeriod = floor((month(l_lopp_kpv) - month(l_alg_kpv) + 1) / 3);
      l_dekl_period = ceil((v_luba.algkpv - l_alg_kpv) / 90);
  ELSEIF v_luba.kord = 'AASTA'
    THEN
      lnPeriod = 1;
      l_dekl_period = 1;
      IF v_luba.loppkpv > l_lopp_kpv
      THEN
        -- teine aasta
        lnPeriod = year(v_luba.loppkpv) - year(v_luba.algkpv) + 1;
        l_dekl_period = 0;
        l_lopp_kpv = v_luba.loppkpv;
      END IF;

  ELSE
    lnPeriod = floor((month(l_lopp_kpv) - month(l_alg_kpv) + 1) / 3);
    l_dekl_period = ceil((v_luba.algkpv - l_alg_kpv) / 90);
  END IF;
  IF l_lopp_kpv < v_luba.loppkpv
  THEN
    l_lopp_kpv = v_luba.loppkpv;
  END IF;

  --	lnKord = 0;
  LOOP
    IF empty(l_kpv)
    THEN
      -- esimine
      l_kpv = v_luba.algkpv;
    END IF;

    l_tahtaeg = l_kpv;
    IF l_kpv > l_lopp_kpv
    THEN
      RAISE NOTICE 'Exit: %', l_kpv;
      EXIT;
    END IF;
    LOOP
      IF NOT is_workday(l_tahtaeg, v_luba.rekvid)
      THEN
        EXIT;
      END IF;

      l_tahtaeg = l_tahtaeg + 1;
      l_dekl_number = l_dekl_number + 1;

      IF l_dekl_number > 5
      THEN
        EXIT;
      END IF;

    END LOOP;

    l_summa = round(rekl.sp_calc_deklsumma(v_luba.parentid, l_kpv), 2);
    --    lnSumma = sp_calc_deklsumma(v_luba.id, ldKpv);
    IF l_summa IS NULL OR l_summa = 0
    THEN
      EXIT;
    END IF;

    -- parandus
    l_tahtaeg = DATE(YEAR((l_kpv + INTERVAL '1 month') :: DATE), month((l_kpv + INTERVAL '1 month') :: DATE), 10);

    -- parameters

    SELECT
      0               AS id,
      0               AS number,
      v_luba.asutusid,
      v_luba.parentid AS lubaid,
      l_kpv           AS kpv,
      l_summa         AS summa,
      NULL :: TEXT    AS alus,
      NULL :: TEXT    AS ettekirjutus,
      l_tahtaeg       AS tahtaeg,
      l_dokprop_id    AS dokpropid,
      'DEKL'          AS tyyp,
      l_dekl_number   AS number
    INTO v_toiming;

    SELECT row_to_json(row)
    INTO json_params
    FROM (SELECT
            0                      AS id,
            row_to_json(v_toiming) AS data) row;

    l_toiming_id = rekl.sp_salvesta_toiming(json_params, l_user_id, v_luba.rekvid);

    /*
        l_toiming_id = sp_salvesta_toiming(0, v_luba.parentid, v_luba.id, l_kpv, space(1), space(1), l_tahtaeg, l_summa, 1,
                                           'DEKL', space(1), 0, l_dokprop_id, l_dekl_period);
    */

    RAISE NOTICE 'id: %', l_toiming_id;

    l_dekl_period = l_dekl_period + 1;

    IF l_dekl_period >= lnPeriod
    THEN
      RAISE NOTICE 'exit period';
      EXIT;
    END IF;

    CASE WHEN v_luba.kord = 'PAEV'
      THEN
        RAISE NOTICE 'PAEV';
        l_kpv = l_kpv + 1;
      WHEN v_luba.kord = 'NADAL'
      THEN
        RAISE NOTICE 'NADAL';
        l_kpv = l_kpv + 7;
      WHEN v_luba.kord = 'KUU'
      THEN
        RAISE NOTICE 'KUU';
        l_kpv = gomonth(l_kpv, 1);
      WHEN v_luba.kord = 'KVARTAL'
      THEN
        RAISE NOTICE 'KVARTAL';
        IF month(l_kpv) < 4
        THEN
          -- 1 kvartal
          l_kpv = date(year(l_kpv), 04, 01);
        ELSEIF month(l_kpv) > 3 AND month(l_kpv) < 7
          THEN
            -- 2 kvartal
            l_kpv = date(year(l_kpv), 07, 01);
        ELSEIF month(l_kpv) > 6 AND month(l_kpv) < 10
          THEN
            -- 3 kvartal
            l_kpv = date(year(l_kpv), 10, 01);
        ELSE
          -- 4 kvartal
          l_kpv = date(year(l_kpv) + 1, 01, 01);
        END IF;
    END CASE;

    -- toopaevi kontrol
    l_dekl_number = 0;
    LOOP

      IF is_workday(l_kpv, v_luba.rekvid)
      THEN
        EXIT;
      END IF;

      l_kpv = l_kpv + 1;
      l_dekl_number = l_dekl_number + 1;

      IF l_dekl_number > 5
      THEN
        EXIT;
      END IF;
    END LOOP;


    IF v_luba.kord = 'PAEV'
    THEN
      EXIT;
    END IF;

    IF v_luba.kord = 'AASTA'
    THEN
      RAISE NOTICE 'AASTA';
      l_kpv = l_kpv + INTERVAL '12 month';

      IF year(v_luba.loppkpv) = year(l_kpv) AND v_luba.loppkpv < l_kpv
      THEN
        l_kpv = v_luba.loppkpv;
      END IF;

    END IF;
  END LOOP;

  -- delete dekl where kpv > luba.loppkpv
  DELETE FROM rekl.toiming
  WHERE lubaid = v_luba.parentid
        AND kpv > v_luba.loppkpv
        AND staatus = 'active'
        AND tyyp = 'DEKL';
  RETURN 1;

END;

$BODY$
LANGUAGE 'plpgsql' VOLATILE STRICT
COST 100;

GRANT EXECUTE ON FUNCTION rekl.sp_calc_dekl(INTEGER,INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.sp_calc_dekl(INTEGER,INTEGER) TO dbpeakasutaja;




/*
SELECT rekl.sp_calc_dekl(294175,1)
select * from rekl.luba where parentid = 294175

update rekl.luba set staatus = 1 where parentid = 294175
 */