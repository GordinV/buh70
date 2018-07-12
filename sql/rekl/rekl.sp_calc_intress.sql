DROP FUNCTION IF EXISTS rekl.sp_calc_intress( INTEGER, JSON );

CREATE FUNCTION rekl.sp_calc_intress(IN  user_id    INTEGER, IN params JSON, OUT result INTEGER,
                                     OUT error_code INTEGER, OUT error_message TEXT, OUT data JSONB)

  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE

  l_lubaid          INTEGER = params ->> 'id';
  l_kpv             DATE = params ->> 'kpv';
  v_dekl            RECORD;
  v_luba            RECORD;
  v_tasu            RECORD;
  v_toiming         RECORD;
  l_markused        TEXT = '';
  l_intress         NUMERIC(12, 4);
  l_tasu            INT;
  l_summa           NUMERIC(12, 2) = 0;

  l_rea_summa       NUMERIC(12, 2);
  l_laek_kpv        DATE;
  l_laekumine_summa NUMERIC(18, 4) = 0;

  l_dokProp         INTEGER = (SELECT d.id
                               FROM libs.dokprop d INNER JOIN libs.library l
                                   ON l.id = d.parentid AND upper(l.kood) = upper('REKL intress')
                                      AND l.rekvid IN (SELECT rekvid
                                                       FROM docs.doc
                                                       WHERE id = l_lubaid));
  l_jaak            NUMERIC(12, 2);

  l_paev_kokku      INT;
  l_dekl_number     VARCHAR(20);
  l_period          VARCHAR(40);
  l_luba_period     VARCHAR(40);

  l_intress_Id      INTEGER;

  l_viivised        JSONB = '[]' :: JSONB; -- {intresid:xxx,data:[{}]} структура
  l_tasu_index      INTEGER = 0;
  l_paev_array      INTEGER [];
  l_summa_array     NUMERIC [];
  l_summa_kokku     NUMERIC = 0;
  json_params       JSON;

BEGIN
  SELECT *
  INTO v_luba
  FROM rekl.luba
  WHERE parentid = l_lubaid;

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
    t.lisa ->> 'intress'  AS viivised,
    t.lisa ->> 'dekltasu' AS tasud,
    u.kasutaja            AS userName
  FROM rekl.toiming t,
    ou.userid u
  WHERE t.lubaid = l_lubaid
        AND t.tyyp IN ('DEKL', 'ALGSALDO', 'PARANDUS')
        AND t.staatus <> 'deleted'
        AND NOT empty(t.saadetud)
        AND (t.tahtaeg + 1) < l_kpv
        AND u.id = user_id
  LOOP
    l_jaak = rekl.fnc_dekl_jaak(v_dekl.parentid);
    l_summa_kokku = 0;

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
    RAISE NOTICE 'arvestame paevi arv %', v_dekl;
    IF v_dekl.staatus = 'active'
    THEN
      -- puudub tasumise info
      l_paev_array [1] = l_kpv - v_dekl.tahtaeg;

      l_summa_array [1] = l_intress * v_dekl.summa * l_paev_array [1];
      l_markused = l_markused || ' tahtaeg ' || v_dekl.tahtaeg :: TEXT || ' paevad:' ||
                   l_paev_array [1] :: TEXT || 'Volg:' || round(v_dekl.summa, 2) :: TEXT || ' Intress:' ||
                   l_summa_array [1] :: TEXT || chr(13);

      -- salvestame arvestuse info
      -- insert new intress data into viivised array
      l_viivised = l_viivised :: JSONB || (SELECT to_jsonb(row)
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
                                                   l_paev_array [1]                 AS dokpaevad,
                                                   l_intress                        AS intressimaar,
                                                   l_summa_array [1]                AS muudsumma,
                                                   NULL :: DATE                     AS laekkpv,
                                                   0                                AS laeksumma) row);
      l_summa_kokku = l_summa_array [1];
    ELSE
      l_tasu = 0;
      l_tasu_index = 0;
      l_jaak = v_dekl.summa;
      l_markused = l_markused + ' tahtaeg ' + v_dekl.tahtaeg :: VARCHAR(10);

      FOR v_tasu IN
      SELECT
        qry.tasuid  AS id,
        qry.tasukpv AS kpv,
        qry.summa
      FROM (SELECT *
            FROM jsonb_to_recordset(v_dekl.tasud :: JSONB) AS x (tasuid INTEGER, summa NUMERIC,  tasukpv DATE )) qry
      ORDER BY 1
      LOOP
        l_tasu_index = l_tasu_index + 1;
        -- paevad
        l_paev_array [l_tasu_index] = v_tasu.kpv - v_dekl.tahtaeg;
        IF l_paev_array [l_tasu_index] > 0
        THEN
          l_summa_array [l_tasu_index] = l_jaak * l_intress * l_paev_array [l_tasu_index];
          l_jaak = l_jaak - v_tasu.summa;
          l_markused =
          l_markused || ' tasu kpv ' || v_tasu.kpv :: VARCHAR(10) || ' paevad:' ||
          l_paev_array [l_tasu_index] :: VARCHAR || 'Volg: ' ||
          l_jaak :: VARCHAR || ' Intress:' || l_summa_array [l_tasu_index] :: VARCHAR || chr(13);
        END IF;
        l_laek_kpv = v_tasu.kpv;
        l_laekumine_summa = v_tasu.summa;

        -- salvestame arvestuse info

        l_viivised = l_viivised :: JSONB || (SELECT to_jsonb(row)
                                             FROM (SELECT
                                                     l_dekl_number ||
                                                     ltrim(rtrim(str(v_dekl.number))) AS deklnumber,
                                                     l_period                         AS period,
                                                     l_luba_period                    AS lubaperiod,
                                                     v_dekl.parentid                  AS dokid,
                                                     1                                AS dokliik,
                                                     v_dekl.tahtaeg                   AS doktahtaeg,
                                                     v_dekl.summa                     AS doksumma,
                                                     round(l_jaak, 2)                 AS dokvolg,
                                                     l_paev_array [l_tasu_index]      AS dokpaevad,
                                                     l_intress                        AS intressimaar,
                                                     l_summa_array [l_tasu_index]     AS muudsumma,
                                                     l_laek_kpv :: DATE               AS laekkpv,
                                                     l_laekumine_summa                AS laeksumma) row);

        IF l_jaak <= 0
        THEN
          RAISE NOTICE 'jaak = 0';
          --					exit;

        END IF;
        l_summa_kokku = l_summa_kokku + l_summa_array [l_tasu_index];
        l_paev_kokku = l_paev_array [l_tasu_index];
      END LOOP;

    END IF;
    IF l_summa_kokku > 0
    THEN
      -- intress suurem kui 0
      l_rea_summa = l_summa_kokku;
      l_summa = l_summa + l_summa_kokku;
    END IF;
    -- salvestame viivise info

    l_rea_summa = 0;
    l_markused = ltrim(rtrim(l_markused)) || chr(13);
  END LOOP;

  RAISE NOTICE 'arvestus: %', l_summa;
  IF l_summa > 0 AND v_luba.parentid > 0
  THEN

    SELECT
      0                  AS id,
      0                  AS number,
      v_luba.asutusid,
      v_luba.parentid    AS lubaid,
      l_kpv              AS kpv,
      l_summa            AS summa,
      NULL :: TEXT       AS alus,
      NULL :: TEXT       AS ettekirjutus,
      l_kpv              AS tahtaeg,
      l_dokProp          AS dokpropid,
      l_markused :: TEXT AS muud,
      'INTRESS'          AS tyyp
    INTO v_toiming;

    SELECT row_to_json(row)
    INTO json_params
    FROM (SELECT
            0                      AS id,
            row_to_json(v_toiming) AS data) row;

    result = rekl.sp_salvesta_toiming(json_params, user_id, v_luba.rekvid);

    -- salvestame intressi doki infot
    SELECT row_to_json(row)
    INTO json_params
    FROM (SELECT
            result     AS intressid,
            l_viivised AS data) row;

    v_dekl.viivised = coalesce(v_dekl.viivised, '{}') :: JSONB || json_params :: JSONB;

    UPDATE rekl.toiming
    SET lisa = coalesce(lisa :: JSONB, '{}' :: JSONB) :: JSONB || v_dekl.viivised :: JSONB
    WHERE id = v_dekl.id;

    -- связи
    -- 1. intress
    UPDATE docs.doc
    SET
      docs_ids   = array_append(docs_ids, v_dekl.parentid),
      lastupdate = now(),
      history    = coalesce(history, '[]') :: JSONB || row_to_json(row) :: JSONB
    FROM (SELECT
            now()           AS updated,
            v_dekl.userName AS user) row
    WHERE id = result;

    -- 2. dekl

    UPDATE docs.doc
    SET
      docs_ids   = array_append(docs_ids, result),
      lastupdate = now(),
      history    = coalesce(history, '[]') :: JSONB || row_to_json(row) :: JSONB
    FROM (SELECT
            now()           AS updated,
            v_dekl.userName AS user) row
    WHERE id = v_dekl.parentid;

    data = row_to_json(row) :: JSONB
    FROM ( SELECT
    result AS id,
    l_summa AS summa) ROW;

  ELSE
    result = 0;
  END IF;
  RETURN;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_code = 1;
    error_message = SQLERRM;
    result = 0;
    RETURN;

END;
$$;

/*
SELECT *
FROM rekl.sp_calc_intress(1, '{
  "id": 294112,
  "kpv": "20180712"
}')

select * from rekl.toiming where saadetud is not null
select * from rekl.toiming where parentid in (294174, 294318, 294321)
*/