DROP FUNCTION IF EXISTS docs.create_new_arve(INTEGER, JSONB);
DROP FUNCTION IF EXISTS docs.create_new_arve(INTEGER, JSON);

CREATE OR REPLACE FUNCTION docs.create_new_arve(
  IN  user_id       INTEGER,
  IN  params        JSON,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$
DECLARE
  l_asutus_id     INTEGER = params ->> 'asutus_id';
  l_nom_id        INTEGER = params ->> 'nom_id';
  l_doklausend_id INTEGER = params ->> 'doklausend_id';
  l_kpv           DATE = coalesce((params ->> 'kpv') :: DATE, current_date);
  l_details       JSON = params ->> 'details';
  l_liik          INTEGER = coalesce((params ->> 'liik') :: INTEGER, 0);
  v_arv_details   RECORD;
  json_object     JSONB;
  l_json_arve     JSON;
  json_arvread    JSONB = '[]';
  v_nom    RECORD;

  l_tp     TEXT = (SELECT tp FROM libs.asutus a WHERE id = l_asutus_id);

  l_rekvid INTEGER = (SELECT rekvid FROM ou.userid u WHERE id = user_id);
  l_arv_id INTEGER;
BEGIN

  -- читаем переданные параметры и создаем детали счета
  FOR json_object IN
  SELECT * FROM json_array_elements(l_details)
  LOOP
    SELECT *
        INTO v_arv_details
    FROM json_to_record(
           json_object :: JSON) AS x (kogus NUMERIC(14, 4), hind NUMERIC(14, 4), kbm NUMERIC(14, 4), kbmta NUMERIC(14, 4), summa NUMERIC(14, 4), nomid INTEGER, kood1 TEXT, kood2 TEXT, kood3 TEXT, kood4 TEXT, kood5 TEXT, konto TEXT, tunnus TEXT, tp TEXT, muud TEXT, arve_id INTEGER);

    SELECT *
        INTO v_nom
    FROM com_nomenclature n
    WHERE id = CASE
                 WHEN v_arv_details.nomId IS NOT NULL
                         THEN v_arv_details.nomId
                 ELSE l_nom_id END;

    -- формируем строку
    json_arvread = json_arvread || (SELECT row_to_json(row)
                                    FROM (SELECT v_nom.id AS nomid,
                                                 v_arv_details.arve_id,
                                                 coalesce(v_arv_details.kogus,
                                                          1) AS kogus,
                                                 coalesce(v_arv_details.hind,
                                                          0) AS hind,
                                                 coalesce(v_arv_details.kbm,
                                                          0) AS kbm,
                                                 coalesce(v_arv_details.kbmta,
                                                          coalesce(v_arv_details.kogus, 1) *
                                                          coalesce(v_arv_details.hind,
                                                                   0)) AS kbmta,
                                                 coalesce(v_arv_details.summa,
                                                          coalesce(v_arv_details.kogus, 1) * coalesce(v_arv_details.hind, 0)
                                                            +
                                                          coalesce(v_arv_details.kbm,
                                                                   0)) AS summa,
                                                 coalesce(v_arv_details.kood1,
                                                          v_nom.tegev) AS kood1,
                                                 coalesce(v_arv_details.kood2,
                                                          v_nom.allikas) AS kood2,
                                                 coalesce(v_arv_details.kood3,
                                                          v_nom.rahavoog) AS kood3,
                                                 coalesce(v_arv_details.kood5,
                                                          v_nom.artikkel) AS kood5,
                                                 coalesce(v_arv_details.konto,
                                                          v_nom.konto) AS konto,
                                                 v_arv_details.tunnus,
                                                 v_arv_details.muud,
                                                 l_tp AS tp) row) :: JSONB;

  END LOOP;

  -- создаем параметры
  l_json_arve = (SELECT to_json(row)
                 FROM (SELECT 0               AS id,
                              l_doklausend_id AS doklausid,
                              l_liik          AS liik,
                              l_kpv           AS kpv,
                              l_kpv + 15      AS tahtaeg,
                              l_asutus_id     AS asutusid,
                              json_arvread    AS "gridData") row);

  -- подготавливаем параметры для создания счета
  SELECT row_to_json(row)
      INTO json_object FROM (SELECT 0 AS id, l_json_arve AS data) row;

  SELECT docs.sp_salvesta_arv(json_object :: JSON, user_id, l_rekvid)
      INTO l_arv_id;

  -- проверка

  IF l_arv_id IS NOT NULL AND l_arv_id > 0
  THEN
    PERFORM docs.gen_lausend_arv(l_arv_id, user_id);
    result = l_arv_id;
  ELSE
    result = 0;
    error_message = 'Dokumendi koostamise viga';
    error_code = 1;
  END IF;
  RETURN;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_code = 1;
    error_message = SQLERRM;
    result = 0;
    RETURN;
END;$BODY$
LANGUAGE plpgsql
VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.create_new_arve(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.create_new_arve(INTEGER, JSON) TO dbpeakasutaja;


/*
select docs.create_new_arve(70, '		{"asutus_id":30224,"nom_id":11123,"kpv":"20181130",
		"doklausend_id":1874, "details":[{"arve_id":1438087,"hind":1.90,"kogus":1,"muud":"Kuupäev:2018-11-30, võlg:50.00, päevad:26, intress:0.10, viivis:1.30","number":"20180153364","summa":1.90,"tahtaeg":"20181104","tasud":50,"volg":50}]}'::JSONB)


		{"asutus_id":30224,"nom_id":11123,"kpv":"20181130",
		"doklausend_id":1874, "details":[{"arve_id":1438087,"hind":1.90,"kogus":1,"muud":"Kuupäev:2018-11-30, võlg:50.00, päevad:26, intress:0.10, viivis:1.30","number":"20180153364","summa":1.90,"tahtaeg":"20181104","tasud":50,"volg":50}]}

select * from libs.nomenklatuur
  l_asutus_id     INTEGER = params ->> 'asutus_id';
  l_nom_id        INTEGER = params ->> 'nom_id';
  l_doklausend_id INTEGER = params ->> 'doklausend_id';
  l_kpv           DATE = coalesce((params ->> 'kpv') :: DATE, current_date);
  l_details       JSON = params ->> 'details';
  l_liik          INTEGER = coalesce((params ->> 'liik') :: INTEGER, 0);

*/