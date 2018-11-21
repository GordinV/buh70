DROP FUNCTION IF EXISTS rekl.sp_koosta_rekl_uhendus(IN user_id INTEGER, IN params JSON);

CREATE FUNCTION rekl.sp_koosta_rekl_uhendus(IN  user_id    INTEGER, IN params JSON, OUT result INTEGER,
                                            OUT error_code INTEGER, OUT error_message TEXT)
  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  l_dekl_id  INTEGER = params ->> 'dekl_id';
  l_tasu_id  INTEGER = params ->> 'tasu_id';

  l_kasutaja TEXT = (SELECT kasutaja FROM ou.userid WHERE id = user_id);
  l_ajalugu  JSONB = (SELECT row_to_json(row) FROM (SELECT l_kasutaja AS user, now() AS updated) row) :: JSONB;
BEGIN
  -- сохранить ссылку в docs.doc

  UPDATE docs.doc
  SET docs_ids   = array_append(docs_ids, l_tasu_id),
      history    = history || l_ajalugu,
      lastupdate = now()
  WHERE id = l_dekl_id;

  -- отметить оплату

  UPDATE rekl.toiming SET staatus = 'closed' WHERE parentid = l_tasu_id;

  -- установить связь с декларацией и сделать отметку в истории

  UPDATE docs.doc
  SET docs_ids   = array_append(docs_ids, l_dekl_id),
      history    = history || l_ajalugu,
      status     = 2, -- закрыта для редактирования
      lastupdate = now()
  WHERE id = l_tasu_id;

  -- вызвать расчет сальдо декларации
  IF rekl.fnc_dekl_jaak(l_dekl_id) <= 0
  THEN
    -- декларация оплачена, ставим статус closed
    UPDATE rekl.toiming SET staatus = 'closed' WHERE parentid = l_dekl_id;
    UPDATE docs.doc SET status = 2 WHERE id = l_dekl_id;
  END IF;

  result = 1;

  RETURN;
END;
$$;

GRANT EXECUTE ON FUNCTION rekl.sp_koosta_rekl_uhendus(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.sp_koosta_rekl_uhendus(INTEGER, JSON) TO dbpeakasutaja;

