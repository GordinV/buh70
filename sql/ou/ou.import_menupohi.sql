DROP FUNCTION IF EXISTS ou.import_menupohi( );

CREATE OR REPLACE FUNCTION ou.import_menupoh()
  RETURNS INTEGER AS
$BODY$
DECLARE
  menu_id     INTEGER;
  userName    TEXT;
  v_menu      RECORD;
  json_object JSONB;
  l_name      TEXT;
  l_vene      TEXT;
  l_eesti     TEXT;
  l_string    TEXT;
  l_key       TEXT;
  l_id        INTEGER;
  v_params    RECORD;
BEGIN
  -- выборка из "старого меню"
  FOR v_menu IN
  SELECT
    pad,
    bar,
    idx,
    level_                    AS level,
    proc_                     AS proc,
    omandus,
    array_to_json(md.modules) AS modules,
    array_to_json(mi.groups)  AS groups,
    array_to_json(mi.users)   AS users
  FROM menupohi_ m
    INNER JOIN (SELECT
                  parentid,
                  array_agg(modul) AS modules
                FROM menumodul
                GROUP BY parentid) AS md ON md.parentid = m.id
    INNER JOIN (SELECT
                  parentid,
                  array_agg(gruppid) AS groups,
                  array_agg(userid)  AS users
                FROM menuisik
                WHERE empty(ei :: INTEGER)
                GROUP BY parentid) AS mi ON mi.parentid = m.id
--  LIMIT 10
  LOOP
    -- преобразование и получение параметров

    l_name = v_menu.pad;
    l_string = substring(v_menu.omandus FROM position('RUS' IN v_menu.omandus) FOR position(CHR(13) IN v_menu.omandus));
    l_vene = substring(l_string FROM 13 FOR len(l_string));
    RAISE NOTICE 'l_string % l_vene %', l_string, l_vene;

    l_string = substring(v_menu.omandus FROM position('EST' IN v_menu.omandus) FOR len(v_menu.omandus));
    IF position(chr(13) IN l_string) > 0
    THEN
      l_string = substring(v_menu.omandus FROM position('EST' IN v_menu.omandus) FOR position(CHR(13) IN l_string));
    END IF;
    l_eesti = substring(l_string FROM 13 FOR len(l_string));

    RAISE NOTICE 'l_string % l_eesti %', l_string, l_eesti;

    IF position('KeyShortCut' IN v_menu.omandus) > 0
    THEN
      l_string = substring(v_menu.omandus FROM position('KeyShortCut' IN v_menu.omandus) FOR len(v_menu.omandus));
      IF position(chr(13) IN l_string) > 0
      THEN
        l_string = substring(v_menu.omandus FROM position('KeyShortCut' IN v_menu.omandus) FOR
                             position(CHR(13) IN l_string));
      END IF;
      l_key = substring(l_string FROM 13 FOR len(l_string));

    ELSE
      l_key = NULL;
    END IF;
    RAISE NOTICE 'l_string % l_key %', l_string, l_key;
    -- поиск в новом меню
    SELECT id
    INTO l_id
    FROM ou.menupohi m
    WHERE m.pad = v_menu.pad
          AND m.bar = v_menu.bar
          AND (m.properties ->> 'level') :: TEXT = v_menu.level :: TEXT;

    -- сохранение
    SELECT
      coalesce(l_id, 0)         AS id,
      ltrim(rtrim(v_menu.pad))  AS pad,
      ltrim(rtrim(v_menu.bar))  AS bar,
      v_menu.idx                AS idx,
      ltrim(rtrim(v_menu.pad))  AS name,
      l_vene                    AS vene,
      l_eesti                   AS eesti,
      ltrim(rtrim(v_menu.proc)) AS proc,
      v_menu.groups             AS groups,
      v_menu.users              AS users,
      v_menu.modules            AS modules,
      v_menu.level              AS level
    INTO v_params;


    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(l_id, 0) AS id,
            v_params          AS data) row;

    SELECT ou.sp_salvesta_menupohi(json_object :: JSON, 1, 1)
    INTO menu_id;
    RAISE NOTICE 'menu_id %', menu_id;

  END LOOP;
  RETURN 0;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

SELECT ou.import_menupoh()

/*

SELECT ou.sp_salvesta_menupohi('{"id":4,"data":{"pad":"test","bar":"","idx":1,"name":"Test", "vene": "Тест", "eesti": "Testid", "level": 1, "users": ["vlad"], "groups": ["KASUTAJA", "PEAKASUTAJA"], "modules": ["EELARVE"]}}'
,1, 1)

select * from ou.menupohi
*/