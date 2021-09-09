-- libs.palk_lib_synhronization
DROP FUNCTION IF EXISTS libs.palk_lib_synhronization(INTEGER);
DROP FUNCTION IF EXISTS libs.palk_lib_synhronization(INTEGER, INTEGER);

CREATE FUNCTION libs.palk_lib_synhronization(l_lib_id INTEGER, l_user_id INTEGER)
  RETURNS BOOLEAN
  LANGUAGE plpgsql
AS
$$
DECLARE
  v_all_asutus RECORD;
  l_all_lib_id INTEGER;
  v_lib        RECORD;
  v_params     RECORD;
  json_object  JSON;
BEGIN

  SELECT l.id                               AS lib_id,
         l.kood,
         l.nimetus,
         l.library,
         l.properties::JSON ->> 'liik'      AS liik,
         l.properties::JSON ->> 'tund'      AS tund,
         l.properties::JSON ->> 'maks'      AS maks,
         l.properties::JSON ->> 'asutusest' AS asutusest,
         l.properties::JSON ->> 'palgafond' AS palgafond,
         l.properties::JSON ->> 'sots'      AS sots,
         l.properties::JSON ->> 'round'     AS round,
         l.properties::JSON ->> 'konto'     AS konto,
         l.properties::JSON ->> 'elatis'    AS elatis,
         l.properties::JSON ->> 'korrkonto' AS korrkonto,
         l.properties::JSON ->> 'tunnusid'  AS tunnusid,
         l.properties::JSON ->> 'uuritus'   AS uuritus,
         l.properties::JSON ->> 'proj'      AS proj,
         l.properties::JSON ->> 'tegev'     AS tegev,
         l.properties::JSON ->> 'allikas'   AS allikas,
         l.properties::JSON ->> 'artikkel'  AS artikkel,
         l.properties::JSON ->> 'tululiik'  AS tululiik,
         l.tun5
         INTO v_lib
  FROM libs.library l
  WHERE id = l_lib_id;

  FOR v_all_asutus IN
    SELECT *
    FROM libs.all_asutused
    WHERE parentid IN (SELECT rekvid FROM libs.library WHERE id = l_lib_id)
    LOOP
      -- ищем по коду
      l_all_lib_id = (SELECT id
                      FROM libs.library l
                      WHERE rekvid = v_all_asutus.childid
                        AND l.kood = v_lib.kood
                        AND l.library = v_lib.library);

      SELECT coalesce(l_all_lib_id, 0)::INTEGER AS id,
             v_lib.kood,
             v_lib.nimetus,
             v_lib.library,
             v_lib.liik,
             v_lib.tund,
             v_lib.maks,
             v_lib.asutusest,
             v_lib.palgafond,
             v_lib.sots,
             v_lib.round,
             v_lib.konto,
             v_lib.elatis,
             v_lib.korrkonto,
             v_lib.tunnusid,
             v_lib.uuritus,
             v_lib.proj,
             v_lib.tegev,
             v_lib.allikas,
             v_lib.artikkel,
             v_lib.tululiik,
             v_lib.tun5
             INTO v_params;

      -- готовим параметры
      SELECT row_to_json(row)
             INTO json_object
      FROM (SELECT
              coalesce(l_all_lib_id, 0) AS id,
              TRUE                      AS import,
              v_params                  AS data) row;
      -- сохранение


      SELECT libs.sp_salvesta_palk_lib(json_object :: JSON, l_user_id, v_all_asutus.childid)
             INTO l_all_lib_id;

    END LOOP;

  RETURN TRUE;
END;
$$;

COMMENT ON FUNCTION libs.palk_lib_synhronization(INTEGER, INTEGER) IS 'Синхронизация справочника согласно структуре';


GRANT EXECUTE ON FUNCTION libs.palk_lib_synhronization(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.palk_lib_synhronization(INTEGER, INTEGER) TO dbpeakasutaja;



/*

SELECT libs.palk_lib_synhronization(id, 1)
FROM libs.library
WHERE library = 'PALK'
  AND rekvid = 1
LIMIT 10



update libs.all_asutused set parentid = 1

select * from libs.library where library = 'PALK' and rekvid = 1 limit 10


 */