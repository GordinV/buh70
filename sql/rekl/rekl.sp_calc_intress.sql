DROP FUNCTION IF EXISTS rekl.sp_calc_intress( INTEGER, JSON );

CREATE FUNCTION rekl.sp_calc_intress(IN  user_id    INTEGER, IN params JSON, OUT result INTEGER,
                                     OUT error_code INTEGER, OUT error_message TEXT)

  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE

  l_id              INTEGER = params ->> 'id';
  l_kpv             DATE = params ->> 'kpv';
  v_dekl            RECORD;
  v_luba            RECORD;
  v_tasu            RECORD;
  l_markused        TEXT = '';
  l_paev            INT;
  lnAlgSaldo        NUMERIC(12, 4);
  l_intress         NUMERIC(12, 4);
  l_paev1           INT;
  l_paev2           INT;
  l_paev3           INT;
  l_paev4           INT;
  l_paev5           INT;
  l_tasu            INT;
  l_summa0          NUMERIC(12, 2);
  l_summa1          NUMERIC(12, 2);
  l_summa2          NUMERIC(12, 2);
  l_summa3          NUMERIC(12, 2);
  l_summa4          NUMERIC(12, 2);
  l_summa5          NUMERIC(12, 2);
  l_summa           NUMERIC(12, 2) = 0;

  l_rea_summa       NUMERIC(12, 2);
  l_laek_kpv        DATE;
  l_laekumine_summa NUMERIC(18, 4) = 0;

  l_dokProp         INTEGER = (SELECT d.id
                               FROM libs.dokprop d INNER JOIN libs.library l
                                   ON l.id = d.parentid AND upper(l.kood) = upper('REKL intress')
                                      AND l.rekvid IN (SELECT rekvid
                                                       FROM docs.doc
                                                       WHERE id = l_id));
  l_jaak            NUMERIC(12, 2);
  lnEurKuurs        NUMERIC(12, 4) = 1;
  lcValuuta         VARCHAR(20) = 'EUR';
  l_paev_kokku      INT;
  l_dekl_number     VARCHAR(20);
  l_period          VARCHAR(40);
  l_luba_period     VARCHAR(40);

  l_intress_Id      INTEGER;
  l_kpv             DATE;

  l_viivised        JSONB;

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


  l_luba_period = ltrim(rtrim(str(day(v_luba.algkpv)))) + '.' + ltrim(rtrim(str(month(v_luba.algkpv)))) + '.' +
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
    t.*,
    t.lisa ->> 'intress' AS viivised
  FROM rekl.toiming t
  WHERE t.lubaid = l_id
        AND t.tyyp IN ('DEKL', 'ALGSALDO', 'PARANDUS')
        AND t.staatus <> 'deleted'
        AND NOT empty(t.saadetud)
        AND (t.tahtaeg + 1) < l_kpv
  LOOP
    l_jaak = rekl.fnc_dekl_jaak(v_dekl.id);

    SELECT
      0,
      0,
      0,
      0,
      0,
      0
    INTO l_paev, l_summa0, l_summa1, l_summa2, l_summa3, l_summa4, l_summa5;

    l_markused = l_markused + ' dekl.nr.:' + ltrim(rtrim(str(v_dekl.number))) :: VARCHAR;

    -- arvestame viimane paev, default = tahtpaev
    -- v_dekl.viivised - jsonb array
    IF v_dekl.viivised IS NOT NULL
    THEN
      l_intress_Id = (SELECT value ->> 'intressid'
                      FROM LATERAL jsonb_array_elements(v_dekl.viivised :: JSONB)
                      ORDER BY value ->> 'intressid' DESC
                      LIMIT 1
      );
    END IF;

    /*
    SELECT intressId
    INTO l_intress_Id
    FROM viiviseinfo v
      INNER JOIN toiming t ON t.id = v.intressId
    WHERE dokid = v_dekl.id
          AND t.staatus > 0
    ORDER BY t.kpv DESC
    LIMIT 1;
*/

    IF l_intress_Id IS NOT NULL
    THEN
      -- parandame v_dekl.tahtaeg
      l_kpv = (SELECT kpv
               FROM rekl.toiming t
               WHERE t.parentid = l_intress_Id
                     AND staatus <> 'deleted');
      IF l_kpv IS NOT NULL
      THEN
        v_dekl.tahtaeg = l_kpv;
      END IF;
      RAISE NOTICE 'leitud vana intress l_intress_Id %,l_kpv % ', l_intress_Id, l_kpv;
    END IF;

    -- arvestame paevi arv

    IF v_dekl.staatus = 'active'
    THEN
      -- puudub tasumise info
      l_paev = l_kpv - v_dekl.tahtaeg;

      l_summa1 = l_intress * v_dekl.summa * l_paev;
      l_markused = l_markused || ' tahtaeg ' || v_dekl.tahtaeg :: TEXT || ' paevad:' ||
                   l_paev :: TEXT || 'Volg:' || round(v_dekl.summa, 2) :: TEXT || ' Intress:' ||
                   round(l_summa1, 2) :: TEXT;

      -- insert new intress data into viivised array
      v_dekl.viivised = v_dekl.viivised :: JSONB || (SELECT to_jsonb(row)
                                                     FROM (SELECT
                                                             l_dekl_number +
                                                             ltrim(rtrim(str(v_dekl.number))) AS deklnumber,
                                                             l_period                         AS period,
                                                             l_luba_period                    AS lubaperiod,
                                                             v_dekl.parentid                  AS dokid,
                                                             1                                AS dokliik,
                                                             v_dekl.tahtaeg                   AS doktahtaeg,
                                                             v_dekl.summa                     AS doksumma,
                                                             round(v_dekl.summa, 2)           AS dokvolg,
                                                             l_paev                           AS dokpaevad,
                                                             l_intress                        AS intressimaar,
                                                             l_summa1                         AS muudsumma,
                                                             NULL :: DATE                     AS laekkpv,
                                                             0                                AS laeksumma) row);

      --      v_dekl.viivised = v_dekl.viivised

      -- salvestame arvestuse info
      /*
            INSERT INTO viiviseinfo (deklnumber, period, lubaperiod, rekvid, asutusId, intressId, dokid,
                                     dokliik, doktahtaeg, doksumma, dokvolg,
                                     dokpaevad, intressimaar, muudsumma, laekkpv, laeksumma) VALUES
              (l_dekl_number + ltrim(rtrim(str(v_dekl.number))), l_period, lcLubaPeriod,
                                                                 v_luba.rekvid, v_luba.parentid, 0,
                                                                 v_dekl.id, 1, v_dekl.tahtaeg, v_dekl.summa,
                                                                 round(v_dekl.summa, 2),
               l_paev, l_intress, round(l_summa1 / lnEurKuurs, 2), NULL, 0);
      */
    ELSE
      l_tasu = 0;
      l_jaak = v_dekl.summa;
      l_markused = l_markused + ' tahtaeg ' + v_dekl.tahtaeg :: VARCHAR(10);
      RAISE NOTICE 'tahtaeg  %', v_dekl.tahtaeg;

      FOR v_tasu IN
      SELECT
        d.id,
        d.tasuid,
        d.summa,
        d.tasukpv
      FROM rekl.dekltasu d
      WHERE d.deklId = v_dekl.parentid
      ORDER BY d.tasukpv
      LOOP

        RAISE NOTICE 'tasu.id =  %', v_tasu.id;
        RAISE NOTICE 'tasu valuuta =  %', v_tasu.kuurs;
        l_tasu = l_tasu + 1;
        -- paevad
        IF l_tasu = 1
        THEN
          l_paev1 = v_tasu.tasukpv - v_dekl.tahtaeg;
          IF l_paev1 > 0
          THEN
            l_summa1 = l_jaak * l_intress * l_paev1;
            l_jaak = l_jaak - v_tasu.summa * v_tasu.kuurs;
            l_markused =
            l_markused + ' tasu kpv ' + v_tasu.tasukpv :: VARCHAR(10) + ' paevad:' + l_paev1 :: VARCHAR + 'Volg: ' +
            round(l_jaak / lnEurKuurs, 2) :: VARCHAR + ' Intress:' + round(l_summa1 / lnEurKuurs, 2) :: VARCHAR;
          END IF;
          l_laek_kpv = v_tasu.tasukpv;
          l_laekumine_summa = v_tasu.summa;
          RAISE NOTICE 'lnpaev1 =  %', l_paev1;
          RAISE NOTICE 'lnJaak1 =  %', l_jaak;

          -- salvestame arvestuse info
          INSERT INTO viiviseinfo (deklnumber, period, lubaperiod, rekvid, asutusId, intressId, dokid, dokliik, doktahtaeg, doksumma, dokvolg,
                                   dokpaevad, intressimaar, muudsumma, laekkpv, laeksumma) VALUES
            (l_dekl_number + ltrim(rtrim(str(v_dekl.number))), l_period, l_luba_period, v_luba.rekvid, v_luba.parentid,
                                                               0,
                                                               v_dekl.id, 1, v_dekl.tahtaeg, v_dekl.summa,
                                                               round(l_jaak / lnEurKuurs, 2),
             l_paev1, l_intress, round(l_summa1 / lnEurKuurs, 2), l_laek_kpv, l_laekumine_summa);


        ELSEIF l_tasu = 2
          THEN
            l_paev2 = v_tasu.tasukpv - v_dekl.tahtaeg;
            IF l_paev2 > 0
            THEN
              l_summa2 = (l_jaak - v_tasu.summa * v_tasu.kuurs) * l_intress * l_paev2;
              l_jaak = l_jaak - v_tasu.summa * v_tasu.kuurs;
              l_markused =
              l_markused + ' tasu kpv ' + v_tasu.tasukpv :: VARCHAR(10) + ' paevad:' + l_paev2 :: VARCHAR + 'Volg: ' +
              round(l_jaak / lnEurKuurs, 2) :: VARCHAR + ' Intress:' + round(l_summa2 / lnEurKuurs, 2) :: VARCHAR;

              l_laek_kpv = v_tasu.tasukpv;
              l_laekumine_summa = v_tasu.summa;

              RAISE NOTICE 'lnpaev2 =  %', l_paev2;
              RAISE NOTICE 'lnSumma2 =  %', l_summa2;
              RAISE NOTICE 'lnJaak1 =  %', l_jaak;

              -- salvestame arvestuse info
              INSERT INTO viiviseinfo (DeklNumber, Period, LubaPeriod, rekvid, asutusId, intressId, dokid, dokliik, doktahtaeg, doksumma, dokvolg,
                                       dokpaevad, intressimaar, muudsumma, laekkpv, laeksumma) VALUES
                (l_dekl_number + ltrim(rtrim(str(v_dekl.number))), l_period, l_luba_period, v_luba.rekvid,
                                                                   v_luba.parentid, 0, v_dekl.id, 1, v_dekl.tahtaeg,
                                                                   v_dekl.summa, round(l_jaak / lnEurKuurs, 2),
                 l_paev2, l_intress, round(l_summa2 / lnEurKuurs, 2), l_laek_kpv, l_laekumine_summa);

            END IF;
        ELSEIF l_tasu = 3
          THEN
            l_paev3 = v_tasu.tasukpv - v_dekl.tahtaeg;
            IF l_paev3 > 0
            THEN
              l_summa3 = (l_jaak - v_tasu.summa * v_tasu.kuurs) * l_intress * l_paev3;
              l_jaak = l_jaak - v_tasu.summa * v_tasu.kuurs;
              l_markused =
              l_markused + ' tasu kpv ' + v_tasu.tasukpv :: VARCHAR(10) + ' paevad:' + l_paev3 :: VARCHAR + 'Volg: ' +
              round(l_jaak / lnEurKuurs, 2) :: VARCHAR + ' Intress:' + round(l_summa3 / lnEurKuurs, 2) :: VARCHAR;

              l_laek_kpv = v_tasu.tasukpv;
              l_laekumine_summa = v_tasu.summa;
              -- salvestame arvestuse info
              INSERT INTO viiviseinfo (deklnumber, period, LubaPeriod, rekvid, asutusId, intressId, dokid, dokliik, doktahtaeg, doksumma, dokvolg,
                                       dokpaevad, intressimaar, muudsumma, laekkpv, laeksumma) VALUES
                (l_dekl_number + ltrim(rtrim(str(v_dekl.number))), l_period, l_luba_period, v_luba.rekvid,
                                                                   v_luba.parentid, 0, v_dekl.id, 1, v_dekl.tahtaeg,
                                                                   v_dekl.summa, round(l_jaak / lnEurKuurs, 2),
                 l_paev3, l_intress, round(l_summa3 / lnEurKuurs, 2), l_laek_kpv, l_laekumine_summa);


            END IF;
        ELSEIF l_tasu = 4
          THEN
            l_paev4 = v_tasu.tasukpv - v_dekl.tahtaeg;
            IF l_paev4 > 0
            THEN
              l_summa4 = (l_jaak - v_tasu.summa * v_tasu.kuurs) * l_intress * l_paev4;
              l_jaak = l_jaak - v_tasu.summa * v_tasu.kuurs;
              l_markused =
              l_markused + ' tasu kpv ' + v_tasu.tasukpv :: VARCHAR(10) + ' paevad:' + l_paev4 :: VARCHAR + 'Volg: ' +
              round(l_jaak / lnEurKuurs, 2) :: VARCHAR + ' Intress:' + round(l_summa4 / lnEurKuurs, 2) :: VARCHAR;

              l_laek_kpv = v_tasu.tasukpv;
              l_laekumine_summa = v_tasu.summa;

              -- salvestame arvestuse info
              INSERT INTO viiviseinfo (deklnumber, period, LubaPeriod, rekvid, asutusId, intressId, dokid, dokliik, doktahtaeg, doksumma, dokvolg,
                                       dokpaevad, intressimaar, muudsumma, laekkpv, laeksumma) VALUES
                (l_dekl_number + ltrim(rtrim(str(v_dekl.number))), l_period, l_luba_period, v_luba.rekvid,
                                                                   v_luba.parentid, 0, v_dekl.id, 1, v_dekl.tahtaeg,
                                                                   v_dekl.summa, round(l_jaak / lnEurKuurs, 2),
                 l_paev4, l_intress, round(l_summa4 / lnEurKuurs, 2), l_laek_kpv, l_laekumine_summa);

            END IF;
        ELSE
          l_paev5 = v_tasu.tasukpv - v_dekl.tahtaeg;
          IF l_paev5 > 0
          THEN
            l_summa5 = (l_jaak - v_tasu.summa * v_tasu.kuurs) * l_intress * l_paev5;
            l_jaak = l_jaak - v_tasu.summa * v_tasu.kuurs;
            l_markused =
            l_markused + ' tasu kpv ' + v_tasu.tasukpv :: VARCHAR(10) + ' paevad:' + l_paev5 :: VARCHAR + 'Volg: ' +
            round(l_jaak / lnEurKuurs, 2) :: VARCHAR + ' Intress:' + round(l_summa5 / lnEurKuurs, 2) :: VARCHAR;

            l_laek_kpv = v_tasu.tasukpv;
            l_laekumine_summa = v_tasu.summa;

            -- salvestame arvestuse info
            INSERT INTO viiviseinfo (deklnumber, period, LubaPeriod, rekvid, asutusId, intressId, dokid, dokliik, doktahtaeg, doksumma, dokvolg,
                                     dokpaevad, intressimaar, muudsumma, laekkpv, laeksumma) VALUES
              (l_dekl_number + ltrim(rtrim(str(v_dekl.number))), l_period, l_luba_period, v_luba.rekvid,
                                                                 v_luba.parentid,
                                                                 0, v_dekl.id, 1, v_dekl.tahtaeg, v_dekl.summa,
                                                                 round(l_jaak / lnEurKuurs, 2),
               l_paev5, l_intress, round(l_summa5 / lnEurKuurs, 2), l_laek_kpv, l_laekumine_summa);

          END IF;
        END IF;
        IF l_jaak <= 0
        THEN
          RAISE NOTICE 'jaak = 0';
          --					exit;

        END IF;

      END LOOP;

    END IF;
    IF (l_summa1 + l_summa2 + l_summa3 + l_summa4 + l_summa5) > 0
    THEN
      -- intress suurem kui 0
      l_rea_summa = (l_summa1 + l_summa2 + l_summa3 + l_summa4 + l_summa5);
      l_summa = l_summa + (l_summa1 + l_summa2 + l_summa3 + l_summa4 + l_summa5);
    END IF;
    -- salvestame viivise info
    --dokliik = 1 (dekl)
    l_paev_kokku = l_paev;
    IF l_paev1 > 0
    THEN
      l_paev_kokku = l_paev1;
    END IF;
    IF l_paev1 > 0
    THEN
      l_paev_kokku = l_paev1;
    END IF;
    IF l_paev2 > 0
    THEN
      l_paev_kokku = l_paev2;
    END IF;
    IF l_paev3 > 0
    THEN
      l_paev_kokku = l_paev3;
    END IF;
    IF l_paev4 > 0
    THEN
      l_paev_kokku = l_paev4;
    END IF;
    IF l_paev5 > 0
    THEN
      l_paev_kokku = l_paev5;
    END IF;

    l_rea_summa = 0;
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
