-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS test(JSONB);
DROP FUNCTION IF EXISTS lapsed.convert_day_taabel(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.convert_day_taabel(params JSONB, user_id INTEGER, user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    json_object     JSONB;
    data            JSONB   = params ->> 'data';
    doc_id          INTEGER = data ->> 'id';
    doc_kpv         DATE    = data ->> 'kpv';
    doc_grupp_id    INTEGER = data ->> 'grupp_id';
    doc_muud        TEXT    = data ->> 'muud';
    doc_details     JSONB   = coalesce(data ->> 'gridData', data ->> 'griddata');
    json_row        RECORD;
    json_taabel_row JSONB;
    taabel1_id      INTEGER;
    l_nom_id        INTEGER;
    json_grid       JSONB   = '[]'::JSONB;
    json_doc        JSON;
BEGIN
    -- 1 . цикл по параметрам
    FOR json_object IN
        SELECT *
        FROM json_array_elements(doc_details::JSON)
        LOOP
            FOR json_row IN
                SELECT *
                FROM jsonb_each(json_object)
                WHERE regexp_match(key::TEXT, '[0-9]') IS NOT NULL
                LOOP

                    -- 2. разбор цифровыйх полей
                    l_nom_id = json_row.key::INTEGER;
                    taabel1_id = (SELECT t1.id
                                  FROM lapsed.day_taabel t
                                           INNER JOIN lapsed.day_taabel1 t1 ON t.id = t1.parent_id
                                  WHERE t.id = doc_id
                                    AND t1.laps_id = (json_object ->> 'lapsid')::INTEGER
                                    AND t.grupp_id = doc_grupp_id
                                    AND t1.nom_id = l_nom_id
                                  LIMIT 1
                    );

                    SELECT row_to_json(row) INTO json_taabel_row
                    FROM (SELECT taabel1_id                                                                         AS id,
                                 l_nom_id::INTEGER                                                                  AS nom_id,
                                 (json_object ->> 'lapsid')::INTEGER                                                AS laps_id,
                                 CASE WHEN (json_row.value::TEXT)::BOOLEAN = TRUE THEN 1 ELSE 0 END::NUMERIC(14, 4) AS kogus,
                                 CASE
                                     WHEN (json_object ->> 'osalemine'::TEXT)::BOOLEAN = TRUE THEN 1
                                     ELSE 0 END::INTEGER                                                            AS osalemine,
                                 json_object ->> 'muud'                                                             AS muud
                         ) row;
                    json_grid = json_grid || json_taabel_row;
                END LOOP;

--
        END LOOP;
-- сохранение
    json_doc = (SELECT to_json(row)
                FROM (SELECT coalesce(doc_id, 0) AS id,
                             doc_kpv             AS kpv,
                             doc_grupp_id        AS grupp_id,
                             doc_muud            AS muud,
                             json_grid           AS "gridData") row);

    SELECT row_to_json(row) INTO json_doc
    FROM (SELECT doc_id   AS id,
                 json_doc AS data) row;

    SELECT lapsed.sp_salvesta_day_taabel(json_doc :: JSONB, user_id, user_rekvid) INTO doc_id;

    RETURN doc_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.convert_day_taabel(JSONB, INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.convert_day_taabel(JSONB, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.convert_day_taabel(JSONB, INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT lapsed.convert_day_taabel('{
  "data": {
    "docTypeId": "PAEVA_TAABEL",
    "module": "lapsed",
    "userId": 70,
    "uuid": "b4038dc0-6b57-11ea-b44c-ffff5eab1248",
    "docId": 3,
    "context": null,
    "id": 3,
    "userid": "70",
    "kpv": "2020-03-01",
    "muud": "test ",
    "grupp_id": 214107,
    "yksus": "grupp 2",
    "row": [
      {
        "id": 3,
        "userid": "70",
        "kpv": "2020-03-01",
        "muud": "test ",
        "grupp_id": 214107,
        "yksus": "grupp 2"
      }
    ],
    "details": [
      {
        "userid": "70",
        "id": "1",
        "parent_id": 3,
        "lapsid": 38,
        "isikukood": "49308233762",
        "nimi": "Angelina",
        "grupp_id": 214107,
        "rekvid": 63,
        "noms": [
          {
            "nom_id": 2738,
            "teenus": "inventaar",
            "kogus": 1,
            "id": 1
          }
        ]
      }
    ],
    "gridConfig": [
      {
        "id": "id",
        "name": "id",
        "width": "0px",
        "show": false,
        "type": "text",
        "readOnly": true
      },
      {
        "id": "isikukood",
        "name": "Isikukood",
        "width": "100px",
        "show": true,
        "type": "text",
        "readOnly": true
      },
      {
        "id": "nimi",
        "name": "Nimi",
        "width": "300px",
        "show": true,
        "type": "text",
        "readOnly": true
      },
      {
        "id": "2738",
        "name": "inventaar",
        "width": "auto",
        "type": "boolean"
      }
    ],
    "gridData": [
      {
        "2738": true,
        "userid": "70",
        "id": "1",
        "parent_id": 3,
        "lapsid": 38,
        "isikukood": "49308233762",
        "nimi": "Angelina",
        "grupp_id": 214107,
        "rekvid": 63,
        "noms": [
          {
            "nom_id": 2738,
            "teenus": "inventaar",
            "kogus": 1,
            "id": 1
          }
        ]
      }
    ],
    "bpm": [],
    "requiredFields": [
      {
        "name": "grupp_id",
        "type": "I"
      },
      {
        "name": "kpv",
        "type": "D"
      }
    ]
  }
}'::JSONB, 70, 63);
*/