DROP FUNCTION IF EXISTS libs.sp_salvesta_nomenclature(DATA JSON, userid INTEGER, user_rekvid INTEGER);

CREATE OR REPLACE FUNCTION libs.sp_salvesta_nomenclature(data JSON, userid INTEGER, user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    nom_id                INTEGER;
    userName              TEXT;
    doc_id                INTEGER = data ->> 'id';
    is_import             BOOLEAN = data ->> 'import';
    doc_data              JSON    = data ->> 'data';
    doc_kood              TEXT    = doc_data ->> 'kood';
    doc_nimetus           TEXT    = doc_data ->> 'nimetus';
    doc_luno              TEXT    = doc_data ->> 'luno'; -- краткое название для столбцов в табеле
    doc_dok               TEXT    = doc_data ->> 'dok';
    doc_uhik              TEXT    = doc_data ->> 'uhik';
    doc_hind              NUMERIC = coalesce((doc_data ->> 'hind') :: NUMERIC, 0);
    doc_ulehind           NUMERIC = coalesce((doc_data ->> 'ulehind') :: NUMERIC, 0);
    doc_kogus             NUMERIC = coalesce((doc_data ->> 'kogus') :: NUMERIC, 0);
    doc_formula           TEXT    = doc_data ->> 'formula';
    doc_muud              TEXT    = doc_data ->> 'muud';
    doc_vat               TEXT    = (doc_data ->> 'vat');
    doc_konto             TEXT    = doc_data ->> 'konto';
    doc_projekt           TEXT    = doc_data ->> 'projekt';
    doc_tunnus            TEXT    = doc_data ->> 'tunnus';
    doc_uritus            TEXT    = doc_data ->> 'uritus';
    doc_tegev             TEXT    = doc_data ->> 'tegev';
    doc_allikas           TEXT    = doc_data ->> 'allikas';
    doc_rahavoog          TEXT    = doc_data ->> 'rahavoog';
    doc_artikkel          TEXT    = doc_data ->> 'artikkel';
    doc_kalor             NUMERIC = doc_data ->> 'kalor';
    doc_sahharid          NUMERIC = doc_data ->> 'sahharid';
    doc_rasv              TEXT    = doc_data ->> 'rasv';
    doc_vailkaine         NUMERIC = doc_data ->> 'vailkaine';
    doc_grupp             TEXT    = doc_data ->> 'grupp';
    doc_oppe_tyyp         TEXT    = doc_data ->> 'oppe_tyyp';
    doc_luhi_nimi         TEXT    = doc_data ->> 'luhi_nimi';
    doc_algoritm          TEXT    = doc_data ->> 'algoritm';
    doc_tyyp              TEXT    = CASE
                                        WHEN doc_data ->> 'tyyp' = '0' THEN NULL::TEXT
                                        ELSE doc_data ->> 'tyyp' END; -- тип услуги, нул - простая, soodustus - льгота
    doc_INF3              BOOLEAN = doc_data ->> 'kas_inf3';
    doc_kas_umberarvestus BOOLEAN = doc_data ->> 'kas_umberarvestus';
    doc_valid             DATE    = CASE
                                        WHEN empty(doc_data ->> 'valid') THEN NULL::DATE
                                        ELSE (doc_data ->> 'valid')::DATE END;
    json_object           JSONB;
    new_history           JSONB;
    new_rights            JSONB;
    l_error               TEXT;

BEGIN

    -- check null as text
    IF (coalesce(doc_tegev, '') = 'null')
    THEN
        doc_tegev = NULL;
    END IF;

    IF (coalesce(doc_artikkel, '') = 'null')
    THEN
        doc_artikkel = NULL;
    END IF;

    IF (coalesce(doc_tunnus, '') = 'null')
    THEN
        doc_tunnus = NULL;
    END IF;

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    -- контроль классификаторов
    json_object = to_jsonb(row)
                  FROM (SELECT doc_tunnus    AS tunnus,
                               doc_konto     AS konto,
                               doc_projekt   AS projekt,
                               doc_tegev     AS tegev,
                               doc_allikas   AS allikas,
                               doc_rahavoog  AS rahavoog,
                               doc_artikkel  AS artikkel,
                               doc_uritus    AS uritus,
                               doc_grupp     AS grupp,
                               doc_oppe_tyyp AS oppe_tyyp
                       ) row;

    json_object = fnc_check_libs(json_object::JSON, CASE WHEN doc_valid IS NULL THEN current_date ELSE doc_valid END,
                                 user_rekvid);

    IF (jsonb_array_length(json_object) > 0)
    THEN
        l_error = array_to_string(array_agg(value ->> 'error_message'), ',')
                  FROM (
                           SELECT *
                           FROM jsonb_array_elements(json_object)
                       ) qry;

        RAISE EXCEPTION '%',l_error;
    END IF;

    IF doc_INF3 IS NULL AND doc_id IS NOT NULL AND doc_id > 0
    THEN
        -- оставляем параметр без изменения
        doc_INF3 = (SELECT coalesce((n.properties ->> 'kas_inf3')::BOOLEAN, FALSE)
                    FROM libs.nomenklatuur n
                    WHERE id = doc_id);

    END IF;


    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT doc_vat                        AS vat,
                 doc_luno                       AS luno,
                 coalesce(doc_konto, 'null')    AS konto,
                 doc_projekt                    AS projekt,
                 coalesce(doc_tunnus, 'null')   AS tunnus,
                 coalesce(doc_tegev, 'null')    AS tegev,
                 coalesce(doc_allikas, 'null')  AS allikas,
                 coalesce(doc_rahavoog, 'null') AS rahavoog,
                 coalesce(doc_artikkel, 'null') AS artikkel,
                 coalesce(doc_uritus, 'null')   AS uritus,
                 doc_kalor                      AS kalor,
                 doc_valid                      AS valid,
                 doc_sahharid                   AS sahharid,
                 doc_rasv                       AS rasv,
                 doc_vailkaine                  AS vailkaine,
                 doc_grupp                      AS grupp,
                 doc_INF3                       AS kas_inf3,
                 doc_kas_umberarvestus          AS kas_umberarvestus,
                 doc_oppe_tyyp                  AS oppe_tyyp,
                 doc_tyyp                       AS tyyp,
                 doc_algoritm                   AS algoritm,
                 doc_luhi_nimi                  AS luhi_nimi
         ) row;

    -- контроль над классфикаторами, если задан кор.счет из группы 32
    IF doc_konto IS NOT NULL AND left(doc_konto, 2) = '32'
    THEN
        IF empty(coalesce(doc_tunnus, '')) AND user_rekvid IN (
            SELECT id FROM ou.rekv WHERE id = 119 OR parentid = 119 OR id = 64 OR parentid = 64
        )
        THEN
            -- только для соц. департамента и отдела культуры
            l_error = coalesce(l_error, '') || ' tunnus, ';
        END IF;
        IF empty(coalesce(doc_tegev, ''))
        THEN
            l_error = coalesce(l_error, '') || ' tegevusala, ';
        END IF;
        IF empty(coalesce(doc_artikkel, ''))
        THEN
            l_error = coalesce(l_error, '') || ' artikkel, ';
        END IF;
        IF empty(coalesce(doc_allikas, ''))
        THEN
            l_error = coalesce(l_error, '') || ' allikas ';
        END IF;

        IF len(coalesce(l_error, '')) > 1
        THEN
            RAISE EXCEPTION 'Viga, puuduvad vajalikud andmed: %', l_error;
        END IF;

    END IF;

    IF doc_id IS NULL OR doc_id = 0
    THEN

        -- проверка на уникальность кода
        IF exists(SELECT id
                  FROM libs.nomenklatuur
                  WHERE rekvid = user_rekvid
                    AND ltrim(rtrim(kood)) = ltrim(rtrim(doc_kood))
                    AND status < 3)
        THEN
            -- такой код уже есть, возвращаем ошибку
            RAISE EXCEPTION 'Viga, kood juba kasutusel: %', doc_dok;
        END IF;

        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;
        SELECT row_to_json(row)
        INTO new_rights
        FROM (SELECT ARRAY [userId] AS "select",
                     ARRAY [userId] AS "update",
                     ARRAY [userId] AS "delete") row;

        -- uus kiri
        INSERT INTO libs.nomenklatuur (rekvid, dok, kood, nimetus, uhik, hind, muud, ulehind, kogus, formula,
                                       properties)
        VALUES (user_rekvid, doc_dok, doc_kood, doc_nimetus, doc_uhik, doc_hind, doc_muud, doc_ulehind, doc_kogus,
                doc_formula,
                json_object) RETURNING id
                   INTO nom_id;


    ELSE
        -- проверка на уникальность кода
        IF exists(SELECT id
                  FROM libs.nomenklatuur
                  WHERE rekvid = user_rekvid
                    AND kood = doc_kood
                    AND id <> doc_id
                    AND status < 3)
        THEN
            -- такой код уже есть, возвращаем ошибку
            RAISE EXCEPTION 'Viga, kood juba kasutusel: %', doc_dok;
        END IF;

        -- muuda

        UPDATE libs.nomenklatuur
        SET rekvid     = CASE WHEN is_import IS NOT NULL THEN user_rekvid ELSE rekvid END,
            dok        = doc_dok,
            kood       = doc_kood,
            nimetus    = doc_nimetus,
            uhik       = doc_uhik,
            hind       = doc_hind,
            muud       = doc_muud,
            ulehind    = doc_ulehind,
            kogus      = doc_kogus,
            formula    = doc_formula,
            properties = json_object
        WHERE id = doc_id RETURNING id
            INTO nom_id;

        -- проставим значение inf3 по карточкам
        IF exists(SELECT 1
                  FROM pg_class
                  WHERE relname = 'lapse_kaart')
        THEN
            UPDATE lapsed.lapse_kaart
            SET properties = properties::JSONB || jsonb_build_object('kas_inf3', doc_INF3)
            WHERE nom_id = doc_id;
        END IF;


    END IF;

    RETURN coalesce(nom_id, 0);
/*EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;
*/

END ;
$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_nomenclature(DATA JSON, userid INTEGER, user_rekvid INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_nomenclature(DATA JSON, userid INTEGER,
    user_rekvid INTEGER) TO dbpeakasutaja;

/*
select libs.sp_salvesta_nomenclature(
'{"id":0,"data":{"allikas":"ALLIKAS","artikkel":"ART","doc_type_id":"VARA","dok":"LADU","formula":null,"gruppid":401,"hind":0,"id":0,"kalor":null,"kogus":1,"konto":"KONTO","kood":"__test3367","kuurs":1,"muud":null,"nimetus":"vfp test vara","projekt":null,"rasv":null,"rekvid":1,"sahharid":null,"status":0,"tegev":"TEGEV","tunnus":null,"uhik":null,"ulehind":0,"userid":1,"vailkaine":null,"valid":null,"valuuta":"EUR","vat":"20"}}',1,1)

*/
