DROP FUNCTION IF EXISTS palk.palk_kaart_from_tmpl( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION palk.palk_kaart_from_tmpl(
  IN  isik_id       INTEGER,
  IN  user_id       INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
AS
$BODY$
DECLARE
  v_leping RECORD;
  v_tmpl   RECORD;
  l_json   JSONB;
  l_id     INTEGER;
BEGIN
  result = 0;
  error_code = 0;
  error_message= '';

  IF isik_id IS NULL OR isik_id = 0
  THEN
    error_code = 6;
    error_message = 'Isiku parameter on vale';
    RETURN;
  END IF;
  -- select kehtiv lepingud
  FOR v_leping IN
  SELECT
    t.id,
    t.osakondid,
    t.ametid,
    t.algab,
    t.lopp,
    t.rekvid
  FROM palk.tooleping t
  WHERE t.parentid = isik_id
        AND t.rekvid IN (SELECT u.rekvid
                         FROM ou.userid u
                         WHERE id = user_id)
        AND t.status = array_position((enum_range(NULL :: DOK_STATUS)), 'active') -- ainult kehtiv lepingud
  LOOP
    -- select muster
    FOR v_tmpl IN
    SELECT
      0            AS id,
      isik_id      AS parentid,
      p.libid,
      v_leping.id  AS lepingid,
      p.summa      AS summa,
      p.percent_,
      p.tulumaks,
      p.tulumaar,
      p.tunnus,
      0 :: INTEGER AS alimentid,
      p.muud
    FROM palk.palk_tmpl p
    WHERE p.parentid = v_leping.ametid
          AND p.status = 'active'
          AND libid NOT IN (SELECT libid
                            FROM palk.palk_kaart pk
                            WHERE lepingid = v_leping.id and status <> array_position((enum_range(NULL :: DOK_status)), 'deleted'))
    LOOP
      -- salvestan palk_kaart
      SELECT row_to_json(row)
      INTO l_json
      FROM (SELECT
              0 :: INTEGER AS id,
              v_tmpl       AS data) row;

      l_id = palk.sp_salvesta_palk_kaart(l_json :: JSON, user_id, v_leping.rekvid);
      IF l_id > 0
      THEN
        result = result + 1;
      ELSE
        error_code = 1;
        error_message = 'Palk kaart import ebaõnnestus';
      END IF;
    END LOOP;
  END LOOP;

  IF result = 0
  THEN
    error_code = 0;
    error_message = 'Puudub lepingud või kõim koodid juba importeeritud';
  END IF;
  RETURN;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_message = SQLERRM;
    error_code = 1;
    result = 0;
    RETURN;

END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION palk.palk_kaart_from_tmpl(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.palk_kaart_from_tmpl(INTEGER, INTEGER) TO dbpeakasutaja;

/*
select error_code, result, error_message from palk.palk_kaart_from_tmpl(56, 1)
*/
