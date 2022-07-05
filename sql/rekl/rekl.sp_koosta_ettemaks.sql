DROP FUNCTION IF EXISTS rekl.sp_koosta_ettemaks(INTEGER, JSON);

CREATE FUNCTION rekl.sp_koosta_ettemaks(IN  user_id    INTEGER, IN params JSON, OUT result INTEGER,
                                        OUT error_code INTEGER, OUT error_message TEXT)

  RETURNS RECORD

LANGUAGE plpgsql
AS $$
DECLARE
  lausend_id  INTEGER = params ->> 'id';
  l_liik      INTEGER = coalesce((params ->> 'liik') :: INTEGER, 1);
  l_id        INTEGER = 0;
  v_journal   RECORD;
  v_ettemaks  RECORD;
  json_params JSON;
  is_import   BOOLEAN = coalesce((params ->> 'import') :: BOOLEAN, FALSE);
BEGIN

  IF l_liik = 1
  THEN
    -- journal
    FOR v_journal IN
    SELECT j.parentid AS id, j1.id AS journal1Id, j.rekvid, j.kpv, j.asutusid, j.selg, j1.summa, jid.number
    FROM docs.journal j
           JOIN docs.journal1 j1 ON j.id = j1.parentid
           JOIN docs.journalid jid ON j.id = jid.journalid
    WHERE j.parentid = lausend_id
    LOOP
      -- kontrollime kas ettemaks juba koostatud
      SELECT coalesce(e.id, 0)
          INTO l_id FROM rekl.ettemaksud e
        WHERE journalid = v_journal.journal1Id;

      SELECT coalesce(l_id,0)             AS id,
             v_journal.number       AS number,
             v_journal.asutusId,
             v_journal.id           AS dokid,
             v_journal.kpv          AS kpv,
             v_journal.summa        AS summa,
             v_journal.selg :: TEXT AS selg,
             v_journal.journal1Id   AS journalid, -- ссылка на строку проводки
             v_journal.rekvid,
             is_import              AS import
          INTO v_ettemaks;

      SELECT row_to_json(row)
          INTO json_params FROM (SELECT coalesce(l_id,0) AS id, row_to_json(v_ettemaks) AS data) row;

      result = rekl.sp_salvesta_ettemaksud(json_params, user_id, v_journal.rekvid);

    END LOOP;
    RETURN;
  END IF;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_code = 1;
    error_message = SQLERRM;
    result = 0;
    RETURN;

END;
$$;


GRANT EXECUTE ON FUNCTION rekl.sp_koosta_ettemaks(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.sp_koosta_ettemaks(INTEGER, JSON) TO dbpeakasutaja;

/*
select * from rekl.sp_koosta_ettemaks(1, '{"id":294361,"import":true}')

 select * from cur_journal order by id desc limit 10
 */