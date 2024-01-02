DROP FUNCTION IF EXISTS hooldekodu.sp_salvesta_hootaabel(JSONB, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS hooldekodu.sp_salvesta_hooltaabel(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION hooldekodu.sp_salvesta_hootaabel(data JSONB,
                                                            userid INTEGER,
                                                            user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName           TEXT;
    doc_id             INTEGER = data ->> 'id';
    doc_data           JSON    = data ->> 'data';
    doc_details        JSON    = coalesce(doc_data ->> 'gridData', doc_data ->> 'griddata');

    is_import          BOOLEAN = data ->> 'import';
    json_object        JSONB;
    json_record        RECORD;
    rea_id             INTEGER;
    ids                INTEGER[];
    l_json_props       JSONB ;
    l_eelmise_lepingid INTEGER;

BEGIN

    -- вставка в таблицы документа
    FOR json_object IN
        SELECT *
        FROM json_array_elements(doc_details)
        LOOP
            SELECT *
            INTO json_record
            FROM jsonb_to_record(
                         json_object) AS x (id TEXT, lepingid INTEGER, isikid INTEGER, nomId INTEGER, kpv DATE,
                                            kogus NUMERIC(14, 4), hind NUMERIC(14, 4), soodustus NUMERIC(12, 2),
                                            summa NUMERIC(12, 2), alus_hind NUMERIC(12, 2), umardamine NUMERIC(12, 2),
                                            muud TEXT);

            l_json_props = jsonb_build_object('umardamine', json_record.umardamine);

            IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW'
            THEN

                INSERT INTO hooldekodu.hootaabel (lepingid, isikid, nomId, kpv,
                                                  kogus, hind, soodustus,
                                                  summa, muud, arvid, rekvid, alus_hind, properties)
                VALUES (json_record.lepingid, json_record.isikid, json_record.nomId, json_record.kpv,
                        json_record.kogus, json_record.hind, json_record.soodustus,
                        json_record.summa, json_record.muud, 0, user_rekvid, json_record.alus_hind,
                        l_json_props) RETURNING id
                           INTO rea_id;

                -- add new id into array of ids
                ids = array_append(ids, rea_id);

                doc_id = rea_id;

            ELSE
                SELECT lepingid
                INTO l_eelmise_lepingid
                FROM hooldekodu.hootaabel
                WHERE id = json_record.id :: INTEGER
                LIMIT 1;

                UPDATE hooldekodu.hootaabel
                SET nomid      = json_record.nomid,
                    hind       = coalesce(json_record.hind, 0),
                    lepingid   = coalesce(json_record.lepingid, l_eelmise_lepingid),
                    isikid     = json_record.isikid,
                    kpv        = json_record.kpv,
                    kogus      = json_record.kogus,
                    soodustus  = json_record.soodustus,
                    summa      = json_record.summa,
                    alus_hind  = json_record.alus_hind,
                    muud       = json_record.muud,
                    properties = coalesce(properties, '{}'::JSONB) || l_json_props
                WHERE id = json_record.id :: INTEGER RETURNING id
                    INTO rea_id;

                -- add new id into array of ids
                ids = array_append(ids, rea_id);

            END IF;
        END LOOP;

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

GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hootaabel(JSONB, INTEGER, INTEGER) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hootaabel(JSONB, INTEGER, INTEGER) TO hkametnik;


/*

SELECT hooldekodu.sp_salvesta_hooltaabel('{"id":0,"data":{"muud":"test kontod","isikid":13346,"kpv":"2022-07-01","summa":200,"kogus":1,"nomid":17234}}'
,3196, 64)


select * from libs.nomenklatuur where rekvid = 64 and dok =  'ARV'
*/