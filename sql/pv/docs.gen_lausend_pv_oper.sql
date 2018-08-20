DROP FUNCTION IF EXISTS docs.gen_lausend_pv_oper( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION docs.gen_lausend_pv_oper(
  IN  tnid          INTEGER,
  IN  userid        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
AS
$BODY$
DECLARE
  v_journal      RECORD;
  v_journal1     RECORD;
  v_pv_oper      RECORD;
  v_dokprop      RECORD;
  lcAllikas      VARCHAR(20);
  lcSelg         TEXT;
  l_json         TEXT;
  l_json_details TEXT;
  new_history    JSONB;
  userName       TEXT;
  a_docs_ids     INTEGER [];
  rows_fetched   INTEGER = 0;
  a_dokvaluuta   TEXT [] = enum_range(NULL :: DOK_VALUUTA);
  a_pv_opers     TEXT [] = enum_range(NULL :: PV_OPERATSIOONID);
BEGIN

  SELECT
    d.docs_ids,
    d.rekvid,
    po.*,
    a.tp,
    l.kood,
    coalesce((l.properties :: JSONB ->> 'parhind') :: NUMERIC(12, 2), 0) :: NUMERIC(12, 2)  AS parhind,
    coalesce((l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 2), 0) :: NUMERIC(12, 2) AS algkulum,
    coalesce((l.properties :: JSONB ->> 'konto'),
             (grupp.properties :: JSONB ->> 'konto')) :: TEXT                               AS korrkonto,
    (l.properties :: JSONB ->> 'jaak') :: NUMERIC(12, 2)                                    AS jaak,
    aa.tp                                                                                   AS asutus_tp,
    (grupp.properties :: JSONB ->> 'kulum_konto') :: TEXT                                   AS kulum_konto,
    coalesce(v.valuuta, 'EUR')                                                              AS valuuta,
    coalesce(v.kuurs, 1)                                                                    AS kuurs
  INTO v_pv_oper
  FROM docs.pv_oper po
    INNER JOIN docs.doc d ON d.id = po.parentId
    INNER JOIN libs.library l ON l.id = po.pv_kaart_id
    INNER JOIN libs.library grupp ON grupp.id = (l.properties :: JSONB ->> 'gruppid') :: INTEGER
    LEFT OUTER JOIN ou.aa aa ON aa.parentid = d.rekvid AND aa.arve = 'TP'
    LEFT OUTER JOIN libs.asutus a ON a.id = po.asutusid
    LEFT OUTER JOIN docs.dokvaluuta1 v ON (v.dokid = po.id AND v.dokliik = array_position(a_dokvaluuta, 'pv_oper'))
  WHERE d.id = tnId;

  GET DIAGNOSTICS rows_fetched = ROW_COUNT;

  IF rows_fetched = 0
  THEN
    error_code = 4; -- No documents found
    error_message = 'No documents found';
    result = 0;
    RETURN;
  END IF;

  IF v_pv_oper.doklausid = 0
  THEN
    error_code = 1; -- Konteerimine pole vajalik
    error_message = 'Konteerimine pole vajalik';
    result = 0;
    RETURN;
  END IF;

  SELECT kasutaja
  INTO userName
  FROM userid u
  WHERE u.rekvid = v_pv_oper.rekvId AND u.id = userId;

  IF userName IS NULL
  THEN
    error_message = 'User not found';
    error_code = 3;
    RETURN;
  END IF;

  IF v_pv_oper.rekvid > 1
  THEN
    lcAllikas = 'LE-P'; -- narva LV @todo should create more flexible variant
  END IF;

  SELECT
    library.kood,
    dokprop.*,
    details.*
  INTO v_dokprop
  FROM libs.dokprop dokprop
    INNER JOIN libs.library library ON library.id = dokprop.parentid
    ,
        jsonb_to_record(dokprop.details) AS details(konto TEXT)
  WHERE dokprop.id = v_pv_oper.doklausid
  LIMIT 1;

  IF NOT Found OR v_dokprop.registr = 0
  THEN
    error_code = 1; -- Konteerimine pole vajalik
    result = 0;
    error_message = 'Konteerimine pole vajalik';
    RETURN;
  END IF;

  -- koostame selg rea
  lcSelg = trim(v_dokprop.selg);

  SELECT
    coalesce(v_pv_oper.journalid, 0) AS id,
    'JOURNAL'                        AS doc_type_id,
    v_pv_oper.kpv                    AS kpv,
    lcSelg                           AS selg,
    v_pv_oper.muud                   AS muud,
    'Inv.number ' || coalesce(v_pv_oper.kood, '')
                                     AS dok,
    v_pv_oper.asutusid               AS asutusid
  INTO v_journal;


  IF NOT empty(v_pv_oper.kood2)
  THEN
    lcAllikas = v_pv_oper.kood2;
  END IF;

  CASE
    WHEN v_pv_oper.liik = array_position(a_pv_opers, 'paigutus')
    THEN
      SELECT
        0                                  AS id,
        coalesce(v_pv_oper.summa, 0)       AS summa,
        coalesce(v_pv_oper.valuuta, 'EUR') AS valuuta,
        coalesce(v_pv_oper.kuurs, 1)       AS kuurs,
        v_pv_oper.korrkonto                AS deebet,
        coalesce(v_pv_oper.tp, '800599')   AS lisa_d,
        v_pv_oper.konto                    AS kreedit,
        coalesce(v_pv_oper.tp, '800401')   AS lisa_k,
        coalesce(v_pv_oper.tunnus, '')     AS tunnus,
        coalesce(v_pv_oper.proj, '')       AS proj,
        coalesce(v_pv_oper.kood1, '')      AS kood1,
        coalesce(v_pv_oper.kood2, '')      AS kood2,
        coalesce(v_pv_oper.kood3, '')      AS kood3,
        coalesce(v_pv_oper.kood4, '')      AS kood4,
        coalesce(v_pv_oper.kood5, '')      AS kood5
      INTO v_journal1;

    WHEN v_pv_oper.liik = array_position(a_pv_opers, 'kulum')
    THEN
      SELECT
        0                                  AS id,
        coalesce(v_pv_oper.summa, 0)       AS summa,
        coalesce(v_pv_oper.valuuta, 'EUR') AS valuuta,
        coalesce(v_pv_oper.kuurs, 1)       AS kuurs,
        v_pv_oper.konto                    AS deebet,
        ''                                 AS lisa_d,
        v_pv_oper.kulum_konto              AS kreedit,
        ''                                 AS lisa_k,
        coalesce(v_pv_oper.tunnus, '')     AS tunnus,
        coalesce(v_pv_oper.proj, '')       AS proj,
        coalesce(v_pv_oper.kood1, '')      AS kood1,
        coalesce(v_pv_oper.kood2, '')      AS kood2,
        coalesce(v_pv_oper.kood3, '')      AS kood3,
        coalesce(v_pv_oper.kood4, '')      AS kood4,
        coalesce(v_pv_oper.kood5, '')      AS kood5
      INTO v_journal1;

    WHEN v_pv_oper.liik = array_position(a_pv_opers, 'parandus')
    THEN
      SELECT
        0                                  AS id,
        coalesce(v_pv_oper.summa, 0)       AS summa,
        coalesce(v_pv_oper.valuuta, 'EUR') AS valuuta,
        coalesce(v_pv_oper.kuurs, 1)       AS kuurs,
        v_pv_oper.korrkonto                AS deebet,
        coalesce(v_pv_oper.tp, '800599')   AS lisa_d,
        v_pv_oper.konto                    AS kreedit,
        coalesce(v_pv_oper.tp, '800599')   AS lisa_k,
        coalesce(v_pv_oper.tunnus, '')     AS tunnus,
        coalesce(v_pv_oper.proj, '')       AS proj,
        coalesce(v_pv_oper.kood1, '')      AS kood1,
        coalesce(v_pv_oper.kood2, '')      AS kood2,
        coalesce(v_pv_oper.kood3, '')      AS kood3,
        coalesce(v_pv_oper.kood4, '')      AS kood4,
        coalesce(v_pv_oper.kood5, '')      AS kood5
      INTO v_journal1;
    WHEN v_pv_oper.liik = array_position(a_pv_opers, 'mahakandmine')
    THEN
      SELECT
        0                                  AS id,
        coalesce(v_pv_oper.summa, 0)       AS summa,
        coalesce(v_pv_oper.valuuta, 'EUR') AS valuuta,
        coalesce(v_pv_oper.kuurs, 1)       AS kuurs,
        v_pv_oper.konto                    AS deebet,
        coalesce(v_pv_oper.tp, '800599')   AS lisa_d,
        v_pv_oper.korrkonto                AS kreedit,
        coalesce(v_pv_oper.tp, '800599')   AS lisa_k,
        coalesce(v_pv_oper.tunnus, '')     AS tunnus,
        coalesce(v_pv_oper.proj, '')       AS proj,
        coalesce(v_pv_oper.kood1, '')      AS kood1,
        coalesce(v_pv_oper.kood2, '')      AS kood2,
        coalesce(v_pv_oper.kood3, '')      AS kood3,
        coalesce(v_pv_oper.kood4, '')      AS kood4,
        coalesce(v_pv_oper.kood5, '')      AS kood5
      INTO v_journal1;
    WHEN v_pv_oper.liik = array_position(a_pv_opers, 'umberhindamine')
    THEN
      error_code = 1; -- Konteerimine pole vajalik
      error_message = 'Umberhindamine konteerimine ei ole realiseeritud';
      result = 0;
      RETURN;
  END CASE;

  l_json_details = row_to_json(v_journal1);
  l_json = row_to_json(v_journal);
  l_json = ('{"data":' || trim(TRAILING FROM l_json, '}') :: TEXT || ',"gridData":[' || l_json_details || ']}}');

  raise notice 'l_json %', l_json;

  result = docs.sp_salvesta_journal(l_json :: JSON, userId, v_pv_oper.rekvId);

  /* salvestan lausend */

  IF result IS NOT NULL AND result > 0
  THEN
    /*
    ajalugu
    */

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS updated,
            userName AS user) row;

    -- will add docs into doc's pull

    UPDATE docs.doc
    SET docs_ids = array(SELECT DISTINCT unnest(array_append(v_pv_oper.docs_ids, result))),
      lastupdate = now(),
      history    = coalesce(history, '[]') :: JSONB || new_history
    WHERE id = v_pv_oper.parentId;

    -- lausend
    SELECT docs_ids
    INTO a_docs_ids
    FROM docs.doc
    WHERE id = result;

    -- add new id into docs. ref. array
    a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_pv_oper.parentId)));

    UPDATE docs.doc
    SET docs_ids = a_docs_ids
    WHERE id = result;

    -- direct ref to journal
    UPDATE docs.pv_oper
    SET
      journalId = result
    WHERE parentid = v_pv_oper.parentid;
  ELSE
    error_code = 2;
    result = 0;
  END IF;
  RETURN;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

ALTER FUNCTION docs.gen_lausend_pv_oper( INTEGER, INTEGER )
OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.gen_lausend_pv_oper(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.gen_lausend_pv_oper(INTEGER, INTEGER) TO dbpeakasutaja;

/*
select error_code, result, error_message from docs.gen_lausend_pv_oper(1245, 1)

select * from libs.dokprop order by id desc
*/
