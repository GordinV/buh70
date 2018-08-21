DROP FUNCTION IF EXISTS palk.gen_palk_dok( INTEGER, JSON );
--tnlepingid integer, tnlibid integer, tndoklausid integer, tdkpv date, tnavans integer, tnminpalk integer
CREATE OR REPLACE FUNCTION palk.gen_palk_dok(IN  user_id    INTEGER, IN params JSON, OUT result INTEGER,
                                             OUT error_code INTEGER, OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$
DECLARE
  v_lib         RECORD;

  l_kpv         DATE = coalesce((params ->> 'kpv') :: DATE, current_date);
  l_isik_ids    JSON = params -> 'isik_ids'; -- массив индентификаторов работников
  l_lib_ids     JSON = params -> 'lib_ids'; -- массив индентификаторов операций
  l_osakond_ids JSON = params ->> 'osakond_ids'; -- массив отделов

  v_po          RECORD;
  v_mk          RECORD;
  v_mk1         RECORD;
  ids           INTEGER [];
  l_grid_params JSONB = '[]';
  l_dok_id      INTEGER; -- ИД сформированной проводки
  v_palk_kaart  RECORD; -- соберем все данные операции в строку
  v_user        RECORD;
  l_params      JSONB;
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

  IF l_isik_ids IS NULL OR json_array_length(l_isik_ids) = 0
  THEN
    error_code = 6;
    error_message = 'Parametrid on vale või puuduvad';
    result = 0;
    RETURN;

  END IF;

  -- выбираем операции для подготовки расчет
  FOR v_po IN
  SELECT
    d.id,
    po.lepingid,
    po.libid,
    d.rekvid,
    t.parentid                                                                    AS isikid,
    po.summa,
    po.tunnus,
    po.proj,
    po.konto,
    po.kood1,
    po.kood2,
    po.kood3,
    po.kood4,
    po.kood5,
    po.journalid,
    l.properties :: JSON ->> 'konto'                                              AS korr_konto,
    (a.properties -> 'asutus_aa') -> 0 ->> 'aa'                                   AS asutus_aa,
    -- isiku pank arve
    a.regkood                                                                     AS isikukood,
    a.nimetus                                                                     AS nimi,
    a.aadress,
    a.tp,
    (SELECT aa.kassa = 1
     FROM ou.aa aa
     WHERE aa.parentid = d.rekvid AND konto = (l.properties :: JSON ->> 'konto')) AS is_kassa
  FROM palk.palk_oper po
    INNER JOIN docs.doc d ON d.id = po.parentid
    INNER JOIN palk.tooleping t ON t.id = po.lepingid
    INNER JOIN libs.asutus a ON a.id = t.parentid
    INNER JOIN libs.library l ON l.id = po.libid AND (l.properties :: JSONB ->> 'liik') :: INTEGER = 6 -- только выплаты
  WHERE t.parentid IN (SELECT value :: INTEGER
                       FROM json_array_elements_text(l_isik_ids))
        AND po.kpv = l_kpv -- только за определенную дату
        AND po.rekvid = v_user.rekvid -- только свое учреждение
        AND l.id IN (SELECT value :: INTEGER
                     FROM json_array_elements_text(l_lib_ids)) -- только указанные операции
        AND t.osakondid IN (SELECT value :: INTEGER
                            FROM json_array_elements_text(l_osakond_ids)) -- только указанные отделы
        AND NOT exists(SELECT d.id
                       FROM docs.doc d
                         INNER JOIN libs.library l ON l.id = d.doc_type_id

                       WHERE d.id IN (SELECT *
                                      FROM unnest(d.docs_ids))
                             AND l.kood NOT IN
                                 ('VMK', 'VORDER')) -- только те выплаты, на которые не созданы платежные документы

  LOOP
    SELECT *
    INTO v_palk_kaart
    FROM palk.palk_kaart pk
    WHERE pk.lepingid = v_po.lepingid AND pk.libid = v_po.libid AND pk.status < 3;

    -- создаем документ
    IF NOT v_po.is_kassa
    THEN
      -- MK
      SELECT
        'VMK'                                                AS doc_type_id,
        docs.get_new_number('VMK', v_po.rekvid, year(l_kpv)) AS number,
        0 :: INTEGER                                         AS id,
        l_kpv                                                AS kpv,
        'PALK'                                               AS muud,
        'Palk'                                               AS selg,
        v_po.summa                                           AS summa
      INTO v_mk;

      --MK1
      SELECT
        v_po.isikid AS asutusid,
        (SELECT id
         FROM libs.nomenklatuur n
         WHERE dok = 'MK'
               AND n.rekvid = v_po.rekvid
               AND n.status < 3
         ORDER BY id DESC
         LIMIT 1)   AS nomid,
        v_po.aa     AS aa,
        v_po.tunnus,
        v_po.proj,
        v_po.konto,
        v_po.kood1,
        v_po.kood2,
        v_po.kood3,
        v_po.kood4,
        v_po.kood5,
        v_po.tp,
        v_po.summa  AS summa
      INTO v_mk1;

      l_grid_params = l_grid_params || to_jsonb(v_mk1);

      SELECT json_object_agg('data', qry.data || qry."gridData")
      INTO l_params
      FROM (SELECT
              to_jsonb(v_mk)                                AS data,
              jsonb_object_agg('gridData', l_grid_params) AS "gridData") qry;

      /*
    l_params = (
      '{"data":' || trim(TRAILING FROM l_params :: TEXT, '}') :: TEXT || ',"gridData":' || l_grid_params :: TEXT ||
      '}}');
*/
      -- save results
      l_dok_id = docs.sp_salvesta_mk(
          l_params :: JSON,
          user_id,
          v_po.rekvid);
    ELSE
      -- VORDER
      SELECT
        2                                                       AS tyyp,
        docs.get_new_number('VORDER', v_po.rekvid, year(l_kpv)) AS number,
        0 :: INTEGER                                            AS id,
        l_kpv                                                   AS kpv,
        v_po.isikid                                             AS asutusid,
        v_po.nimi,
        v_po.aadress,
        'PALK'                                                  AS muud,
        'Palk'                                                  AS alus,
        v_po.summa                                              AS summa
      INTO v_mk;

      --MK1
      SELECT
        v_po.isikid AS asutusid,
        (SELECT id
         FROM libs.nomenklatuur n
         WHERE dok = 'VORDER'
               AND n.rekvid = v_po.rekvid
               AND n.status < 3
         ORDER BY id DESC
         LIMIT 1)   AS nomid,
        v_po.tunnus,
        v_po.proj,
        v_po.konto,
        v_po.kood1,
        v_po.kood2,
        v_po.kood3,
        v_po.kood4,
        v_po.kood5,
        v_po.tp,
        v_po.summa  AS summa
      INTO v_mk1;

      l_grid_params = l_grid_params || to_jsonb(v_mk1);

      SELECT json_object_agg('data', qry.data || qry."gridData")
      INTO l_params
      FROM (SELECT
              to_jsonb(v_mk)                                AS data,
              jsonb_object_agg('gridData', l_grid_params) AS "gridData") qry;

      -- save results
      l_dok_id = docs.sp_salvesta_korder(
          l_params :: JSON,
          user_id,
          v_po.rekvid);

    END IF;

    IF l_dok_id IS NOT NULL AND l_dok_id > 0
    THEN
      -- добавим ссылку на PO

      SELECT docs_ids
      INTO ids
      FROM docs.doc
      WHERE id = l_dok_id;

      ids = array_append(ids, v_po.id);

      IF v_po.journalid IS NOT NULL AND v_po.journalid > 0
      THEN
        ids = array_append(ids, v_po.journalid);
      END IF;

      UPDATE docs.doc
      SET docs_ids = ids
      WHERE id = l_dok_id;

      -- добавим ссылку на VMK / Vorder
      UPDATE docs.doc
      SET docs_ids = array_append(docs_ids, l_dok_id)
      WHERE id = v_po.id;

      result = coalesce(result, 0) + 1;
    END IF;

  END LOOP; -- po loop
  RETURN;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_code = 1;
    error_message = SQLERRM;
    result = 0;
    RETURN;
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION palk.gen_palk_dok(user_id INTEGER, params JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.gen_palk_dok(user_id INTEGER, params JSON) TO dbpeakasutaja;

/*
select palk.gen_palk_dok(1, '{"kpv":"2018-06-30","isik_ids":[56],"osakond_ids":[374],"lib_ids":[531]}')
*/