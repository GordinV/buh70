-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION IF EXISTS docs.sp_tasu_arv( INTEGER );
DROP FUNCTION IF EXISTS docs.sp_tasu_arv( INTEGER, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_tasu_arv(
  l_tasu_id INTEGER, l_arv_id INTEGER, l_user_id INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  l_doc_id      INTEGER;
  v_tasu        RECORD;
  v_params      RECORD;
  json_object   JSONB;
  l_tasu_type   INTEGER = 3; -- muud (lausend)
  l_summa       NUMERIC = 0;
  l_doc_tasu_id INTEGER;
BEGIN
  SELECT
    d.*,
    l.kood AS doc_type
  INTO v_tasu
  FROM docs.doc d
    INNER JOIN libs.library l ON l.id = d.doc_type_id
  WHERE d.id = l_tasu_id;

  IF l_tasu_id IS NULL
  THEN
    -- Документ не найден
    RETURN 0;
  END IF;

  l_tasu_type = (CASE
                 WHEN v_tasu.doc_type ILIKE '%MK%'
                   THEN 1
                 WHEN v_tasu.doc_type ILIKE '%ORDER%'
                   THEN 2
                 ELSE 3 END);

  l_summa = (
    SELECT sum(summa) AS summa
    FROM (
           SELECT summa
           FROM docs.mk m
             INNER JOIN docs.mk1 m1 ON m.id = m1.parentid
           WHERE m.parentid = l_tasu_id
           UNION ALL
           SELECT summa
           FROM docs.korder1 k
           WHERE k.parentid = l_tasu_id
           UNION ALL
           SELECT summa
           FROM docs.journal j
             INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
           WHERE j.parentid = l_tasu_id
         ) tasud
  );

  l_doc_tasu_id = (
    SELECT id
    FROM docs.arvtasu
    WHERE rekvid = v_tasu.rekvid AND doc_arv_id = l_arv_id AND doc_tasu_id = l_tasu_id
  );

  SELECT
    coalesce(l_doc_tasu_id, 0) AS id,
    v_tasu.rekvid              AS rekvid,
    l_arv_id                   AS doc_arv_id,
    v_tasu.created :: DATE     AS kpv,
    l_tasu_type                AS pankkassa,
    -- 1 - mk, 2- kassa, 3 - lausend
    l_tasu_id                  AS doc_tasu_id,
    l_summa                    AS summa
  INTO v_params;

  SELECT row_to_json(row)
  INTO json_object
  FROM (SELECT
          0        AS id,
          v_params AS data) row;

  SELECT docs.sp_salvesta_arvtasu(json_object :: JSON, l_user_id, v_tasu.rekvid)
  INTO l_doc_id;

  RETURN l_doc_id;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_tasu_arv(INTEGER, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_tasu_arv(INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;
