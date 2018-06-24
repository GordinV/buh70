DROP FUNCTION IF EXISTS rekl.sp_calc_intress( INTEGER, JSON );

CREATE FUNCTION rekl.sp_calc_intress(IN  user_id    INTEGER, IN params JSON, OUT result INTEGER,
                                     OUT error_code INTEGER, OUT error_message TEXT)

  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE

  l_id         INTEGER = params ->> 'id';
  l_kpv        DATE = params ->> 'kpv';
  v_dekl       RECORD;
  v_luba       RECORD;
  v_tasu       RECORD;
  l_markused   TEXT = '';
  lnpaev       INT;
  lnAlgSaldo   NUMERIC(12, 4);
  l_intress    NUMERIC(12, 4);
  lnpaev1      INT;
  lnpaev2      INT;
  lnpaev3      INT;
  lnpaev4      INT;
  lnpaev5      INT;
  lntasu       INT;
  lnSumma0     NUMERIC(12, 2);
  lnSumma1     NUMERIC(12, 2);
  lnSumma2     NUMERIC(12, 2);
  lnSumma3     NUMERIC(12, 2);
  lnSumma4     NUMERIC(12, 2);
  lnSumma5     NUMERIC(12, 2);
  l_summa      NUMERIC(12, 2) = 0;

  lnreaSumma   NUMERIC(12, 2);
  ldLaekKpv    DATE;
  l_laekumine_summa  NUMERIC(18, 4) = 0;

  l_dokProp    INTEGER = (SELECT d.id
                          FROM libs.dokprop d INNER JOIN libs.library l
                              ON l.id = d.parentid AND upper(l.kood) = upper('REKL intress')
                                 AND l.rekvid IN (SELECT rekvid
                                                  FROM docs.doc
                                                  WHERE id = l_id));
  lnJaak       NUMERIC(12, 2);
  lnEurKuurs   NUMERIC(12, 4) = 1;
  lcValuuta    VARCHAR(20) = 'EUR';
  lnpaevKokku  INT;
  l_dekl_number VARCHAR(20);
  l_period     VARCHAR(40);
  lcLubaPeriod VARCHAR(40);

  l_intress_Id INTEGER;
  l_kpv        DATE;

BEGIN
  SELECT *
  INTO v_luba
  FROM rekl.luba
  WHERE parentid = l_id;

  l_dekl_number = ltrim(rtrim(v_luba.number)) + '-';
  l_period = ltrim(rtrim(str(day(v_luba.algkpv)))) + '.' + ltrim(rtrim(str(month(v_luba.algkpv)))) + '.' +
             ltrim(rtrim(str(year(v_luba.algkpv)))) + '-' +
             ltrim(rtrim(str(day(l_kpv)))) + '.' + ltrim(rtrim(str(month(l_kpv)))) + '.' +
             ltrim(rtrim(str(year(l_kpv))));


  lcLubaPeriod = ltrim(rtrim(str(day(v_luba.algkpv)))) + '.' + ltrim(rtrim(str(month(v_luba.algkpv)))) + '.' +
                 ltrim(rtrim(str(year(v_luba.algkpv)))) + '-' +
                 ltrim(rtrim(str(day(v_luba.loppKpv)))) + '.' + ltrim(rtrim(str(month(v_luba.loppKpv)))) + '.' +
                 ltrim(rtrim(str(year(v_luba.loppKpv))));

  -- otsime intressi maar
  SELECT n.hind
  INTO l_intress
  FROM libs.nomenklatuur n
  WHERE n.dok = 'REKL'
        AND n.kood ILIKE 'INTRESS%'
        AND n.rekvid = v_luba.rekvid
  ORDER BY upper(kood) DESC
  LIMIT 1;

  l_intress = coalesce(l_intress * 0.01, 0.0006);
  l_markused = 'Luba. number: ' || ltrim(rtrim(v_luba.number)) || ' intress:' || l_intress :: TEXT || chr(13);

  -- koostame deklaratsioonide nimekiri, kus on staatus < 3, tahtaeg < tdKpv and tyyp = 'DEKL'
  FOR v_dekl IN
  SELECT
    t.*
  FROM rekl.toiming t
  WHERE t.lubaid = l_id
        AND t.tyyp IN ('DEKL', 'ALGSALDO', 'PARANDUS')
        AND t.staatus <= 3
        AND NOT empty(toiming.saadetud)
        AND (t.tahtaeg + 1) < l_kpv
  LOOP
    lnJaak = fncDeklJaak(v_dekl.id);
    RAISE NOTICE 'v_dekl.id %, lnJaak %', v_dekl.id, lnJaak;
    lnpaev = 0;
    lnSumma0 = 0;
    lnSumma1 = 0;
    lnSumma2 = 0;
    lnSumma3 = 0;
    lnSumma4 = 0;
    lnSumma5 = 0;
    l_markused = l_markused + ' dekl.nr.:' + ltrim(rtrim(str(v_dekl.number))) :: VARCHAR;

    RAISE NOTICE 'arvestame viimane paev, default = tahtpaev ';
    -- arvestame viimane paev, default = tahtpaev
    SELECT intressId
    INTO l_intress_Id
    FROM viiviseinfo v
      INNER JOIN toiming t ON t.id = v.intressId
    WHERE dokid = v_dekl.id
          AND t.staatus > 0
    ORDER BY t.kpv DESC
    LIMIT 1;

    IF l_intress_Id IS NOT NULL
    THEN
      -- parandame v_dekl.tahtaeg
      l_kpv = (SELECT kpv
               FROM toiming
               WHERE id = l_intress_Id AND staatus > 0);
      IF l_kpv IS NOT NULL
      THEN
        v_dekl.tahtaeg = l_kpv;
      END IF;
      RAISE NOTICE 'leitud vana intress l_intress_Id %,l_kpv % ', l_intress_Id, l_kpv;
    END IF;

    -- arvestame paevi arv
    --		lcValuuta = v_dekl.valuuta;
    IF v_dekl.staatus = 1
    THEN
      RAISE NOTICE 'staatus = 1, puudub tasumise info ';
      -- puudub tasumise info
      lnPaev = l_kpv - v_dekl.tahtaeg;
      RAISE NOTICE ' lnPaev %', lnPaev;
      /*
            -- parandame paevade arv

            select dokpaevad into lnPaevKokku from viiviseinfo where dokliik = 1 and dokid = v_dekl.id;
            lnPaevKokku = ifnull(lnPaevKokku,0);
            if lnPaevKokku > 0 then
              lnPaev = lnPaev - lnPaevKokku;
            end if;
            if lnPaev < 0 then
              lnPaev = 0;
            end if;
            raise notice 'lnPaevKokku %, lnPaev %', lnPaevKokku, lnPaev;
      */

      lnSumma1 = l_intress * v_dekl.summa * v_dekl.kuurs * lnPaev;
      l_markused = l_markused + ' tahtaeg ' + v_dekl.tahtaeg :: VARCHAR(10) + ' paevad:' + lnPaev :: VARCHAR + 'Volg:' +
                   round(v_dekl.summa * v_dekl.kuurs / lnEurKuurs, 2) :: VARCHAR + ' Intress:' +
                   round(lnSumma1 / lnEurKuurs, 2) :: VARCHAR;
      RAISE NOTICE 'lnSumma1 %', lnSumma1;
      RAISE NOTICE 'v_dekl.summa %', v_dekl.summa;
      RAISE NOTICE 'lnIntress %', l_intress;
      RAISE NOTICE 'lnPaev %', lnPaev;
      RAISE NOTICE 'Kuurs %', v_dekl.kuurs;

      -- salvestame arvestuse info
      INSERT INTO viiviseinfo (deklnumber, period, lubaperiod, rekvid, asutusId, intressId, dokid, dokliik, doktahtaeg, doksumma, dokvolg,
                               dokpaevad, intressimaar, muudsumma, laekkpv, laeksumma) VALUES
        (l_dekl_number + ltrim(rtrim(str(v_dekl.number))), l_period, lcLubaPeriod, v_luba.rekvid, v_luba.parentid, 0,
                                                          v_dekl.id, 1, v_dekl.tahtaeg, v_dekl.summa,
                                                          round(v_dekl.summa * v_dekl.kuurs / lnEurKuurs, 2),
         lnPaev, l_intress, round(lnSumma1 / lnEurKuurs, 2), NULL, 0);

    ELSE
      RAISE NOTICE 'staatus =  %', v_dekl.staatus;
      lntasu = 0;
      lnJaak = v_dekl.summa * v_dekl.kuurs;
      l_markused = l_markused + ' tahtaeg ' + v_dekl.tahtaeg :: VARCHAR(10);
      RAISE NOTICE 'tahtaeg  %', v_dekl.tahtaeg;

      FOR v_tasu IN
      SELECT
        dekltasu.id,
        dekltasu.tasuid,
        dekltasu.summa,
        dekltasu.tasukpv,
        ifnull(dokvaluuta1.kuurs, 1) :: NUMERIC AS kuurs
      FROM dekltasu
        LEFT OUTER JOIN dokvaluuta1 ON (dekltasu.id = dokvaluuta1.dokid AND dokvaluuta1.dokliik = 7)
      WHERE dekltasu.deklId = v_dekl.id
      ORDER BY dekltasu.tasukpv
      LOOP

        RAISE NOTICE 'tasu.id =  %', v_tasu.id;
        RAISE NOTICE 'tasu valuuta =  %', v_tasu.kuurs;
        lntasu = lntasu + 1;
        -- paevad
        IF lntasu = 1
        THEN
          lnpaev1 = v_tasu.tasukpv - v_dekl.tahtaeg;
          IF lnpaev1 > 0
          THEN
            lnSumma1 = lnJaak * l_intress * lnPaev1;
            lnJaak = lnJaak - v_tasu.summa * v_tasu.kuurs;
            l_markused =
            l_markused + ' tasu kpv ' + v_tasu.tasukpv :: VARCHAR(10) + ' paevad:' + lnPaev1 :: VARCHAR + 'Volg: ' +
            round(lnJaak / lnEurKuurs, 2) :: VARCHAR + ' Intress:' + round(lnSumma1 / lnEurKuurs, 2) :: VARCHAR;
          END IF;
          ldLaekKpv = v_tasu.tasukpv;
          l_laekumine_summa = v_tasu.summa;
          RAISE NOTICE 'lnpaev1 =  %', lnpaev1;
          RAISE NOTICE 'lnJaak1 =  %', lnJaak;

          -- salvestame arvestuse info
          INSERT INTO viiviseinfo (deklnumber, period, lubaperiod, rekvid, asutusId, intressId, dokid, dokliik, doktahtaeg, doksumma, dokvolg,
                                   dokpaevad, intressimaar, muudsumma, laekkpv, laeksumma) VALUES
            (l_dekl_number + ltrim(rtrim(str(v_dekl.number))), l_period, lcLubaPeriod, v_luba.rekvid, v_luba.parentid, 0,
                                                              v_dekl.id, 1, v_dekl.tahtaeg, v_dekl.summa,
                                                              round(lnJaak / lnEurKuurs, 2),
             lnPaev1, l_intress, round(lnSumma1 / lnEurKuurs, 2), ldLaekKpv, l_laekumine_summa);


        ELSEIF lntasu = 2
          THEN
            lnpaev2 = v_tasu.tasukpv - v_dekl.tahtaeg;
            IF lnpaev2 > 0
            THEN
              lnSumma2 = (lnJaak - v_tasu.summa * v_tasu.kuurs) * l_intress * lnPaev2;
              lnJaak = lnJaak - v_tasu.summa * v_tasu.kuurs;
              l_markused =
              l_markused + ' tasu kpv ' + v_tasu.tasukpv :: VARCHAR(10) + ' paevad:' + lnPaev2 :: VARCHAR + 'Volg: ' +
              round(lnJaak / lnEurKuurs, 2) :: VARCHAR + ' Intress:' + round(lnSumma2 / lnEurKuurs, 2) :: VARCHAR;

              ldLaekKpv = v_tasu.tasukpv;
              l_laekumine_summa = v_tasu.summa;

              RAISE NOTICE 'lnpaev2 =  %', lnpaev2;
              RAISE NOTICE 'lnSumma2 =  %', lnSumma2;
              RAISE NOTICE 'lnJaak1 =  %', lnJaak;

              -- salvestame arvestuse info
              INSERT INTO viiviseinfo (DeklNumber, Period, LubaPeriod, rekvid, asutusId, intressId, dokid, dokliik, doktahtaeg, doksumma, dokvolg,
                                       dokpaevad, intressimaar, muudsumma, laekkpv, laeksumma) VALUES
                (l_dekl_number + ltrim(rtrim(str(v_dekl.number))), l_period, lcLubaPeriod, v_luba.rekvid,
                                                                  v_luba.parentid, 0, v_dekl.id, 1, v_dekl.tahtaeg,
                                                                  v_dekl.summa, round(lnJaak / lnEurKuurs, 2),
                 lnPaev2, l_intress, round(lnSumma2 / lnEurKuurs, 2), ldLaekKpv, l_laekumine_summa);

            END IF;
        ELSEIF lntasu = 3
          THEN
            lnpaev3 = v_tasu.tasukpv - v_dekl.tahtaeg;
            IF lnpaev3 > 0
            THEN
              lnSumma3 = (lnJaak - v_tasu.summa * v_tasu.kuurs) * l_intress * lnPaev3;
              lnJaak = lnJaak - v_tasu.summa * v_tasu.kuurs;
              l_markused =
              l_markused + ' tasu kpv ' + v_tasu.tasukpv :: VARCHAR(10) + ' paevad:' + lnPaev3 :: VARCHAR + 'Volg: ' +
              round(lnJaak / lnEurKuurs, 2) :: VARCHAR + ' Intress:' + round(lnSumma3 / lnEurKuurs, 2) :: VARCHAR;

              ldLaekKpv = v_tasu.tasukpv;
              l_laekumine_summa = v_tasu.summa;
              -- salvestame arvestuse info
              INSERT INTO viiviseinfo (deklnumber, period, LubaPeriod, rekvid, asutusId, intressId, dokid, dokliik, doktahtaeg, doksumma, dokvolg,
                                       dokpaevad, intressimaar, muudsumma, laekkpv, laeksumma) VALUES
                (l_dekl_number + ltrim(rtrim(str(v_dekl.number))), l_period, lcLubaPeriod, v_luba.rekvid,
                                                                  v_luba.parentid, 0, v_dekl.id, 1, v_dekl.tahtaeg,
                                                                  v_dekl.summa, round(lnJaak / lnEurKuurs, 2),
                 lnPaev3, l_intress, round(lnSumma3 / lnEurKuurs, 2), ldLaekKpv, l_laekumine_summa);


            END IF;
        ELSEIF lntasu = 4
          THEN
            lnpaev4 = v_tasu.tasukpv - v_dekl.tahtaeg;
            IF lnpaev4 > 0
            THEN
              lnSumma4 = (lnJaak - v_tasu.summa * v_tasu.kuurs) * l_intress * lnPaev4;
              lnJaak = lnJaak - v_tasu.summa * v_tasu.kuurs;
              l_markused =
              l_markused + ' tasu kpv ' + v_tasu.tasukpv :: VARCHAR(10) + ' paevad:' + lnPaev4 :: VARCHAR + 'Volg: ' +
              round(lnJaak / lnEurKuurs, 2) :: VARCHAR + ' Intress:' + round(lnSumma4 / lnEurKuurs, 2) :: VARCHAR;

              ldLaekKpv = v_tasu.tasukpv;
              l_laekumine_summa = v_tasu.summa;

              -- salvestame arvestuse info
              INSERT INTO viiviseinfo (deklnumber, period, LubaPeriod, rekvid, asutusId, intressId, dokid, dokliik, doktahtaeg, doksumma, dokvolg,
                                       dokpaevad, intressimaar, muudsumma, laekkpv, laeksumma) VALUES
                (l_dekl_number + ltrim(rtrim(str(v_dekl.number))), l_period, lcLubaPeriod, v_luba.rekvid,
                                                                  v_luba.parentid, 0, v_dekl.id, 1, v_dekl.tahtaeg,
                                                                  v_dekl.summa, round(lnJaak / lnEurKuurs, 2),
                 lnPaev4, l_intress, round(lnSumma4 / lnEurKuurs, 2), ldLaekKpv, l_laekumine_summa);

            END IF;
        ELSE
          lnpaev5 = v_tasu.tasukpv - v_dekl.tahtaeg;
          IF lnpaev5 > 0
          THEN
            lnSumma5 = (lnJaak - v_tasu.summa * v_tasu.kuurs) * l_intress * lnPaev5;
            lnJaak = lnJaak - v_tasu.summa * v_tasu.kuurs;
            l_markused =
            l_markused + ' tasu kpv ' + v_tasu.tasukpv :: VARCHAR(10) + ' paevad:' + lnPaev5 :: VARCHAR + 'Volg: ' +
            round(lnJaak / lnEurKuurs, 2) :: VARCHAR + ' Intress:' + round(lnSumma5 / lnEurKuurs, 2) :: VARCHAR;

            ldLaekKpv = v_tasu.tasukpv;
            l_laekumine_summa = v_tasu.summa;

            -- salvestame arvestuse info
            INSERT INTO viiviseinfo (deklnumber, period, LubaPeriod, rekvid, asutusId, intressId, dokid, dokliik, doktahtaeg, doksumma, dokvolg,
                                     dokpaevad, intressimaar, muudsumma, laekkpv, laeksumma) VALUES
              (l_dekl_number + ltrim(rtrim(str(v_dekl.number))), l_period, lcLubaPeriod, v_luba.rekvid, v_luba.parentid,
                                                                0, v_dekl.id, 1, v_dekl.tahtaeg, v_dekl.summa,
                                                                round(lnJaak / lnEurKuurs, 2),
               lnPaev5, l_intress, round(lnSumma5 / lnEurKuurs, 2), ldLaekKpv, l_laekumine_summa);

          END IF;
        END IF;
        IF lnjaak <= 0
        THEN
          RAISE NOTICE 'jaak = 0';
          --					exit;

        END IF;

      END LOOP;

    END IF;
    IF (lnSumma1 + lnSumma2 + lnSumma3 + lnSumma4 + lnSumma5) > 0
    THEN
      -- intress suurem kui 0
      lnreaSumma = (lnSumma1 + lnSumma2 + lnSumma3 + lnSumma4 + lnSumma5);
      l_summa = l_summa + (lnSumma1 + lnSumma2 + lnSumma3 + lnSumma4 + lnSumma5);
    END IF;
    -- salvestame viivise info
    --dokliik = 1 (dekl)
    lnpaevKokku = lnPaev;
    IF lnPaev1 > 0
    THEN
      lnpaevKokku = lnPaev1;
    END IF;
    IF lnPaev1 > 0
    THEN
      lnpaevKokku = lnPaev1;
    END IF;
    IF lnPaev2 > 0
    THEN
      lnpaevKokku = lnPaev2;
    END IF;
    IF lnPaev3 > 0
    THEN
      lnpaevKokku = lnPaev3;
    END IF;
    IF lnPaev4 > 0
    THEN
      lnpaevKokku = lnPaev4;
    END IF;
    IF lnPaev5 > 0
    THEN
      lnpaevKokku = lnPaev5;
    END IF;

    lnreaSumma = 0;
    l_markused = ltrim(rtrim(l_markused)) + '
	';
  END LOOP;

  IF l_summa > 0 AND v_luba.parentid > 0
  THEN
    RAISE NOTICE 'lnEurKuurs %', lnEurKuurs;
    l_summa = round(l_summa / lnEurKuurs, 2);
    result = sp_salvesta_toiming(0, v_luba.parentid, v_luba.id, l_kpv, '', '', l_kpv, l_summa, 0, 'INTRESS',
                                   l_markused, 0, l_dokProp, 0, lcValuuta, lnEURKuurs);
    -- salvestame intressi doki infot
    UPDATE viiviseinfo
    SET intressId = result
    WHERE intressId = 0 AND asutusid = v_luba.parentid
          AND dokliik = 1 AND dokid IN (SELECT id
                                        FROM toiming
                                        WHERE lubaid = v_luba.id);
  END IF;

  RETURN result;


END;
$$;
