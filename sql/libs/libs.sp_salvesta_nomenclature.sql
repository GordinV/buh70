DROP FUNCTION IF EXISTS libs.sp_salvesta_nomenclature(DATA JSON, userid INTEGER, user_rekvid INTEGER);

CREATE OR REPLACE FUNCTION libs.sp_salvesta_nomenclature(data JSON, userid INTEGER, user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    nom_id        INTEGER;
    userName      TEXT;
    doc_id        INTEGER = data ->> 'id';
    is_import     BOOLEAN = data ->> 'import';
    doc_data      JSON    = data ->> 'data';
    doc_kood      TEXT    = doc_data ->> 'kood';
    doc_nimetus   TEXT    = doc_data ->> 'nimetus';
    doc_luno      TEXT    = doc_data ->> 'luno'; -- краткое название для столбцов в табеле
    doc_dok       TEXT    = doc_data ->> 'dok';
    doc_uhik      TEXT    = doc_data ->> 'uhik';
    doc_hind      NUMERIC = coalesce((doc_data ->> 'hind') :: NUMERIC, 0);
    doc_ulehind   NUMERIC = coalesce((doc_data ->> 'ulehind') :: NUMERIC, 0);
    doc_kogus     NUMERIC = coalesce((doc_data ->> 'kogus') :: NUMERIC, 0);
    doc_formula   TEXT    = doc_data ->> 'formula';
    doc_muud      TEXT    = doc_data ->> 'muud';
    doc_vat       TEXT    = (doc_data ->> 'vat');
    doc_konto     TEXT    = doc_data ->> 'konto';
    doc_projekt   TEXT    = doc_data ->> 'projekt';
    doc_tunnus    TEXT    = doc_data ->> 'tunnus';
    doc_tegev     TEXT    = doc_data ->> 'tegev';
    doc_allikas   TEXT    = doc_data ->> 'allikas';
    doc_rahavoog  TEXT    = doc_data ->> 'rahavoog';
    doc_artikkel  TEXT    = doc_data ->> 'artikkel';
    doc_kalor     NUMERIC = doc_data ->> 'kalor';
    doc_sahharid  NUMERIC = doc_data ->> 'sahharid';
    doc_rasv      TEXT    = doc_data ->> 'rasv';
    doc_vailkaine NUMERIC = doc_data ->> 'vailkaine';
    doc_grupp     TEXT    = doc_data ->> 'grupp';
    doc_oppe_tyyp TEXT    = doc_data ->> 'oppe_tyyp';
    doc_luhi_nimi TEXT    = doc_data ->> 'luhi_nimi';
    doc_INF3      BOOLEAN = coalesce((doc_data ->> 'kas_inf3')::BOOLEAN, FALSE);
    doc_valid     DATE    = CASE WHEN empty(doc_data ->> 'valid') THEN NULL::DATE ELSE (doc_data ->> 'valid')::DATE END;
    json_object   JSONB;
    new_history   JSONB;
    new_rights    JSONB;

BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;


    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    SELECT row_to_json(row) INTO json_object
    FROM (SELECT doc_vat                        AS vat,
                 doc_luno                       AS luno,
                 coalesce(doc_konto, 'null')    AS konto,
                 doc_projekt                    AS projekt,
                 coalesce(doc_tunnus, 'null')   AS tunnus,
                 coalesce(doc_tegev, 'null')    AS tegev,
                 coalesce(doc_allikas, 'null')  AS allikas,
                 coalesce(doc_rahavoog, 'null') AS rahavoog,
                 coalesce(doc_artikkel, 'null') AS artikkel,
                 doc_kalor                      AS kalor,
                 doc_valid                      AS valid,
                 doc_sahharid                   AS sahharid,
                 doc_rasv                       AS rasv,
                 doc_vailkaine                  AS vailkaine,
                 doc_grupp                      AS grupp,
                 doc_INF3                       AS kas_inf3,
                 doc_oppe_tyyp                  AS oppe_tyyp
         ) row;

    IF doc_id IS NULL OR doc_id = 0
    THEN

        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;
        SELECT row_to_json(row) INTO new_rights
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
        -- muuda

        RAISE NOTICE 'doc_nimetus %', doc_nimetus;

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
    END IF;

    RETURN nom_id;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;

END;
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
