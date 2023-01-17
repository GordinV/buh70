DROP FUNCTION IF EXISTS eelarve.sp_salvesta_eelarve(JSON, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS docs.sp_salvesta_eelarve(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.sp_salvesta_eelarve(data JSON,
                                                       userid INTEGER,
                                                       user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    eelarve_id      INTEGER;
    userName        TEXT;
    doc_id          INTEGER        = data ->> 'id';
    doc_data        JSON           = data ->> 'data';
    doc_aasta       INTEGER        = doc_data ->> 'aasta';
    doc_summa       NUMERIC(12, 2) = doc_data ->> 'summa';
    doc_summa_kassa NUMERIC(12, 2) = doc_data ->> 'summa_kassa';
    doc_tunnus      TEXT           = doc_data ->> 'tunnus';
    doc_kood1       TEXT           = doc_data ->> 'kood1';
    doc_kood2       TEXT           = doc_data ->> 'kood2';
    doc_kood3       TEXT           = doc_data ->> 'kood3';
    doc_kood4       TEXT           = doc_data ->> 'kood4';
    doc_kood5       TEXT           = doc_data ->> 'kood5';
    doc_is_kulud    INTEGER        = doc_data ->> 'is_kulud';
    doc_is_parandus INTEGER        = coalesce((doc_data ->> 'is_parandus') :: INTEGER, 0);
    doc_variantid   INTEGER        = doc_data ->> 'variantid';
    doc_kpv         DATE           = doc_data ->> 'kpv';
    doc_muud        TEXT           = doc_data ->> 'muud';
    is_import       BOOLEAN        = data ->> 'import';
BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    RAISE NOTICE 'doc_id %, doc_muud %, doc_aasta %', doc_id, doc_muud, doc_aasta;
    -- вставка или апдейт docs.doc
    IF coalesce(doc_id, 0) > 0 AND NOT exists(SELECT id FROM eelarve.eelarve WHERE id = doc_id AND status < 3)
    THEN
        doc_id = 0;
    END IF;

    IF doc_id IS NULL OR doc_id = 0
    THEN

        IF doc_is_kulud = 0
        THEN
            INSERT INTO eelarve.tulud (rekvid, aasta, summa, summa_kassa, tunnus, kood1, kood2, kood3, kood4, kood5,
                                       kpv, muud, is_kulud, is_parandus, variantid)
            VALUES (user_rekvid, doc_aasta, doc_summa, doc_summa_kassa, doc_tunnus, doc_kood1, doc_kood2, doc_kood3,
                    doc_kood4,
                    doc_kood5,
                    doc_kpv, doc_muud, doc_is_kulud, doc_is_parandus, doc_variantid) RETURNING id
                       INTO eelarve_id;
        ELSE
            INSERT INTO eelarve.kulud (rekvid, aasta, summa, summa_kassa, tunnus, kood1, kood2, kood3, kood4, kood5,
                                       kpv, muud, is_kulud, is_parandus, variantid)
            VALUES (user_rekvid, doc_aasta, doc_summa, doc_summa_kassa, doc_tunnus, doc_kood1, doc_kood2, doc_kood3,
                    doc_kood4,
                    doc_kood5,
                    doc_kpv, doc_muud, doc_is_kulud, doc_is_parandus, doc_variantid) RETURNING id
                       INTO eelarve_id;

        END IF;

    ELSE

        UPDATE eelarve.eelarve
        SET aasta       = doc_aasta,
            summa       = doc_summa,
            summa_kassa = doc_summa_kassa,
            tunnus      = doc_tunnus,
            kood1       = doc_kood1,
            kood2       = doc_kood2,
            kood3       = doc_kood3,
            kood4       = doc_kood4,
            kood5       = doc_kood5,
            is_parandus = doc_is_parandus,
            variantid   = doc_variantId,
            kpv         = doc_kpv,
            muud        = doc_muud
        WHERE id = doc_id RETURNING id
            INTO eelarve_id;
    END IF;
    RAISE NOTICE 'eelarve_id %, doc_is_kulud %',eelarve_id, doc_is_kulud;
    RETURN eelarve_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.sp_salvesta_eelarve(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.sp_salvesta_eelarve(JSON, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.sp_salvesta_eelarve(JSON, INTEGER, INTEGER) TO eelaktsepterja;

/*
select * from pg_roles where rolname ilike 'eel%'

SELECT docs.sp_salvesta_eelarve('{"id":0,"data":{"aasta":2018,"id":0,"is_kulud":0,"kood1":"test","kood2":"__test9088","kood3":"","kood4":null,"kood5":"123","kpv":null,"kuu":null,"muud":"test","rekvid":1,"summa":100,"userid":1}}', 1, 1);
*/
