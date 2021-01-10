DROP FUNCTION IF EXISTS fnc_check_libs(JSON, DATE, INTEGER);

CREATE FUNCTION fnc_check_libs(params JSON, l_kpv DATE, l_rekv_id INTEGER)
    RETURNS JSONB
    LANGUAGE plpgsql
AS
$$
DECLARE
    lib_tunnus   TEXT  = params ->> 'tunnus';
    lib_projekt  TEXT  = params ->> 'projekt';
    lib_konto    TEXT  = params ->> 'konto';
    lib_allikas  TEXT  = params ->> 'allikas';
    lib_tegev    TEXT  = params ->> 'tegev';
    lib_artikkel TEXT  = params ->> 'artikkel';
    lib_rahavoog TEXT  = params ->> 'rahavoog';
    lib_osakond  TEXT  = params ->> 'osakond';
    lib_tululiik TEXT  = params ->> 'tululiik';
    lib_nom      TEXT  = params ->> 'nom';
    tulemus      JSONB = '[]'::JSONB;
    v_libs       RECORD;
BEGIN
    FOR v_libs IN
        SELECT id, 'tunnus' AS lib_name, kood
        FROM libs.library l
        WHERE rekvid = l_rekv_id
          AND ltrim(rtrim(kood)) = ltrim(rtrim(lib_tunnus))
          AND l.status <> 3
          AND l.library = 'TUNNUS'
          AND (properties::JSON ->> 'valid')::DATE IS NOT NULL
          AND (properties::JSON ->> 'valid')::DATE <= l_kpv
            UNION
            SELECT id
            , 'projekt' AS lib_name
            , kood AS kood
            FROM libs.library l
            WHERE rekvid = l_rekv_id
          AND ltrim(rtrim(kood)) = ltrim(rtrim(lib_projekt))
          AND l.status <> 3
          AND l.library = 'PROJEKT'
          AND (properties::JSON ->> 'valid')::DATE IS NOT NULL
          AND (properties::JSON ->> 'valid')::DATE <= l_kpv
            UNION
            SELECT id
            , 'konto' AS lib_name
            , kood
            FROM libs.library l
            WHERE ltrim(rtrim(kood)) = ltrim(rtrim(lib_konto))
          AND l.status <> 3
          AND l.library = 'KONTOD'
          AND (properties::JSON ->> 'valid')::DATE IS NOT NULL
          AND (properties::JSON ->> 'valid')::DATE <= l_kpv
            UNION
            SELECT id
            , 'allikas' AS lib_name
            , kood
            FROM libs.library l
            WHERE ltrim(rtrim(kood)) = ltrim(rtrim(lib_allikas))
          AND l.status <> 3
          AND l.library = 'ALLIKAD'
          AND (properties::JSON ->> 'valid')::DATE IS NOT NULL
          AND (properties::JSON ->> 'valid')::DATE <= l_kpv
            UNION
            SELECT DISTINCT id
            , 'tegevus' AS lib_name
            , kood
            FROM libs.library l
            WHERE ltrim(rtrim(kood)) = ltrim(rtrim(lib_tegev))
          AND l.status <> 3
          AND l.library = 'TEGEV'
          AND (properties::JSON ->> 'valid')::DATE IS NOT NULL
          AND (properties::JSON ->> 'valid')::DATE <= l_kpv
            UNION
            SELECT DISTINCT id
            , 'artikkel' AS lib_name
            , kood
            FROM libs.library l
            WHERE ltrim(rtrim(kood)) = ltrim(rtrim(lib_artikkel))
          AND l.status <> 3
          AND l.library = 'TULUDEALLIKAD'
          AND (properties::JSON ->> 'valid')::DATE IS NOT NULL
          AND (properties::JSON ->> 'valid')::DATE <= l_kpv
            UNION
            SELECT DISTINCT id
            , 'rahavoog' AS lib_name
            , kood
            FROM libs.library l
            WHERE ltrim(rtrim(kood)) = ltrim(rtrim(lib_rahavoog))
          AND l.status <> 3
          AND l.library = 'RAHA'
          AND (properties::JSON ->> 'valid')::DATE IS NOT NULL
          AND (properties::JSON ->> 'valid')::DATE <= l_kpv
            UNION
            SELECT id
            , 'nomenklatuur' AS lib_name
            , kood
            FROM libs.nomenklatuur n
            WHERE ltrim(rtrim(kood)) = ltrim(rtrim(lib_nom))
          AND n.status <> 3
          AND (properties::JSON ->> 'valid')::DATE IS NOT NULL
          AND (properties::JSON ->> 'valid')::DATE <= l_kpv
            UNION
            SELECT DISTINCT id
            , 'Osakond' AS lib_name
            , kood
            FROM libs.library n
            WHERE ltrim(rtrim(kood)) = ltrim(rtrim(lib_osakond))
          AND rekvid = l_rekv_id
          AND n.status <> 3
          AND library = 'OSAKOND'
          AND (properties::JSON ->> 'valid')::DATE IS NOT NULL
          AND (properties::JSON ->> 'valid')::DATE <= l_kpv
            UNION ALL
            SELECT id
            , 'tululiik' AS lib_name
            , kood
            FROM libs.library l
            WHERE ltrim(rtrim(kood)) = ltrim(rtrim(lib_tunnus))
          AND l.status <> 3
          AND l.library = 'MAKSUKOOD'
          AND (properties::JSON ->> 'valid')::DATE IS NOT NULL
          AND (properties::JSON ->> 'valid')::DATE <= l_kpv

        LOOP
            tulemus = tulemus || to_jsonb(row)
                      FROM (SELECT v_libs.lib_name || ' kood: ' || ltrim(rtrim(v_libs.kood)) ||
                                   ' ei kehti' AS error_message) row;
        END LOOP;
    tulemus = NULL;
    RETURN tulemus;
END;

$$;

GRANT EXECUTE ON FUNCTION fnc_check_libs(JSON, DATE, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION fnc_check_libs(JSON, DATE, INTEGER) TO dbpeakasutaja;


/*

-- Koolituskulud -> NOM
-- TUNNUS ->>test 3

SELECT DISTINCT id
                      , 'Osakond' AS lib_name
                      , kood,
properties::JSON ->> 'valid',
rekvid, status, library
        FROM libs.library n
        WHERE ltrim(rtrim(kood)) = ltrim(rtrim('test'))
          AND rekvid = 63
          AND n.status <> 3
          AND (properties::JSON ->> 'valid')::DATE IS NOT NULL
          AND (properties::JSON ->> 'valid')::DATE <= l_kpv

*/


SELECT *
FROM jsonb_to_recordset(fnc_check_libs('{
  "osakond": "test",
  "tunnus": "test"
}'::JSON, '2020-11-14'::DATE, 63))
         AS x (error_message TEXT);

SELECT *
FROM jsonb_to_recordset(fnc_check_libs(json_build_object('tunnus', 'test 3', 'kehtivus', TRUE), '2020-11-09'::DATE, 63))
         AS x (error_message TEXT);

SELECT *
FROM jsonb_to_recordset(fnc_check_libs(json_build_object('nom', 'truk', 'kehtivus', TRUE), '2020-11-09'::DATE, 63))
         AS x (error_message TEXT);

SELECT *
FROM jsonb_to_recordset(fnc_check_libs(json_build_object('nom', 'test a', 'kehtivus', TRUE), '2020-11-09'::DATE, 63))
         AS x (error_message TEXT);


