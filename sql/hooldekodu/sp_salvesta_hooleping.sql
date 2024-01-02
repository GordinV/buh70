DROP FUNCTION IF EXISTS hooldekodu.sp_salvesta_hooleping(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION hooldekodu.sp_salvesta_hooleping(data JSONB,
                                                            userid INTEGER,
                                                            user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName             TEXT;
    doc_data             JSON        = data ->> 'data';
    doc_id               INTEGER     = doc_data ->> 'id';
    doc_isikid           INTEGER     = doc_data ->> 'isikid';
    doc_hooldekoduid     INTEGER     = doc_data ->> 'hooldekoduid';
    doc_omavalitsusId    INTEGER     = doc_data ->> 'omavalitsusid';
    doc_sugulane_id      INTEGER     = doc_data ->> 'sugulane_id';
    doc_algkpv           DATE        = doc_data ->> 'algkpv';
    doc_loppkpv          DATE        = doc_data ->> 'loppkpv';
    doc_number           TEXT        = doc_data ->> 'number';
    doc_muud             TEXT        = doc_data ->> 'muud';
    doc_summa            NUMERIC     = doc_data ->> 'summa';
    doc_osa              NUMERIC     = doc_data ->> 'osa';
    doc_sugulane_osa     NUMERIC     = doc_data ->> 'sugulane_osa';
    doc_tasku_raha       NUMERIC     = doc_data ->> 'tasku_raha';
    doc_BruttoSisseTulek NUMERIC     = doc_data ->> 'bruttosissetulek';
    doc_netoSisseTulek   NUMERIC     = doc_data ->> 'netosissetulek';
    doc_hoolduskulud     NUMERIC     = doc_data ->> 'hoolduskulud';
    doc_algoritm         INTEGER     = coalesce((doc_data ->> 'algoritm')::INTEGER, 0);
    doc_makse_viis       INTEGER     = coalesce((doc_data ->> 'makse_viis')::INTEGER, 0);
    doc_rahasaaja_id     INTEGER     = doc_data ->> 'rahasaaja_id';
    doc_aa               VARCHAR(20) = doc_data ->> 'aa';
    doc_tunnus           VARCHAR(20) = doc_data ->> 'tunnus';
    is_import            BOOLEAN     = coalesce((doc_data ->> 'import')::BOOLEAN, FALSE);
    doc_details          JSON        = coalesce(doc_data ->> 'gridData', doc_data ->> 'griddata');
    json_object          JSON;
    json_record          RECORD;
    rea_json             JSONB;
    json_ajalugu         JSONB;
    rea_id               INTEGER;
    ids                  INTEGER[];
    l_omavalitsus        TEXT;
    l_properties         JSONB ;

BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    IF doc_omavalitsusId IS NOT NULL
    THEN
        l_omavalitsus =
                (SELECT nimetus FROM libs.asutus WHERE id = doc_omavalitsusId AND staatus < 3 ORDER BY id DESC LIMIT 1);

    END IF;

    l_properties = jsonb_build_object('algoritm', doc_algoritm);

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN
        -- логгирование
        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS created,
                                    userName AS user) row;

        INSERT INTO hooldekodu.hooleping(rekvid, isikid, hooldekoduid, number, omavalitsusId, algkpv, loppkpv, muud,
                                         summa, osa, omavalitsus, sugulane_id, sugulane_osa, tasku_raha, makse_viis,
                                         bruttosissetulek, properties, rahasaaja_id, aa, tunnus, netosissetulek,
                                         hoolduskulud)
        VALUES (user_rekvid, doc_isikid, doc_hooldekoduid, doc_number, doc_omavalitsusId, doc_algkpv, doc_loppkpv,
                doc_muud, doc_summa, doc_osa, l_omavalitsus, doc_sugulane_id, doc_sugulane_osa, doc_tasku_raha,
                doc_makse_viis, doc_bruttosissetulek, l_properties, doc_rahasaaja_id, doc_aa, doc_tunnus,
                doc_netoSisseTulek, doc_hoolduskulud) RETURNING id
                   INTO doc_id;

    ELSE

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS updated,
                                    userName AS user
                            ) row;

        UPDATE hooldekodu.hooleping
        SET hooldekoduid     = doc_hooldekoduid,
            number           = doc_number,
            omavalitsusId    = doc_omavalitsusId,
            sugulane_id      = doc_sugulane_id,
            sugulane_osa     = doc_sugulane_osa,
            omavalitsus      = l_omavalitsus,
            algkpv           = doc_algkpv,
            loppkpv          = doc_loppkpv,
            summa            = doc_summa,
            osa              = doc_osa,
            tasku_raha       = doc_tasku_raha,
            makse_viis       = doc_makse_viis,
            rahasaaja_id     = doc_rahasaaja_id,
            aa               = CASE WHEN coalesce(doc_aa, '') = 'null' THEN NULL ELSE doc_aa END,
            tunnus           = CASE WHEN coalesce(doc_tunnus, '') = 'null' THEN NULL ELSE doc_tunnus END,
            bruttosissetulek = doc_bruttosissetulek,
            netosissetulek   = doc_netosissetulek,
            hoolduskulud     = doc_hoolduskulud,
            properties       = coalesce(properties, '{}'::JSONB) || l_properties,
            muud             = doc_muud,
            ajalugu          = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu
        WHERE id = doc_id RETURNING id
            INTO doc_id;

    END IF;

    -- вставка в таблицы документа
    FOR json_object IN
        SELECT *
        FROM json_array_elements(doc_details)
        LOOP
            SELECT *
            INTO json_record
            FROM json_to_record(
                         json_object) AS x (id TEXT, nomId INTEGER, kogus NUMERIC(14, 4), hind NUMERIC(14, 4),
                                            allikas TEXT, tuluosa NUMERIC, kehtivus TEXT, muud TEXT);


            IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW'
            THEN
                INSERT INTO hooldekodu.hooteenused (lepingid, nomid, hind, allikas, tuluosa, kehtivus, muud)
                VALUES (doc_id, json_record.nomid,
                        coalesce(json_record.hind, 0),
                        coalesce(json_record.allikas, ''),
                        coalesce(json_record.tuluosa, 0),
                        (CASE
                             WHEN json_record.kehtivus IS NULL OR
                                  empty(ltrim(rtrim(json_record.kehtivus))) THEN NULL
                             ELSE json_record.kehtivus END)::DATE,
                        json_record.muud) RETURNING id
                           INTO rea_id;

                -- add new id into array of ids
                ids = array_append(ids, rea_id);

            ELSE

                UPDATE hooldekodu.hooteenused
                SET nomid    = json_record.nomid,
                    hind     = coalesce(json_record.hind, 0),
                    allikas  = coalesce(json_record.allikas, ''),
                    tuluosa  = coalesce(json_record.tuluosa, 0),
                    kehtivus = (CASE
                                    WHEN json_record.kehtivus IS NULL OR
                                         empty(ltrim(rtrim(json_record.kehtivus))) THEN NULL
                                    ELSE json_record.kehtivus END)::DATE,
                    muud     = json_record.muud
                WHERE id = json_record.id :: INTEGER RETURNING id
                    INTO rea_id;

                -- add new id into array of ids
                ids = array_append(ids, rea_id);

            END IF;

        END LOOP;

    DELETE
    FROM hooldekodu.hooteenused
    WHERE lepingid = doc_id
      AND id NOT IN (SELECT unnest(ids));

    RETURN doc_id;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;


END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hooleping(JSONB, INTEGER, INTEGER) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hooleping(JSONB, INTEGER, INTEGER) TO hkametnik;


/*

select hooldekodu.sp_salvesta_hooleping('{"data":{"id":0,"isikid":13346,"hooldekoduid":30311,"omavalitsus":"Narva LV","number":"001","algkpv":"2022-01-01","loppkpv":"2022-12-31","muud":"test","summa":100, "osa":85}}'::jsonb, 957::integer, 64::integer) as id

select * from ou.userid where rekvid = 64 and kasutaja = 'temp'

select * from libs.asutus where nimetus ilike '%hooldekodu%'
*/