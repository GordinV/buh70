DROP FUNCTION IF EXISTS libs.sp_delete_library(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION libs.sp_delete_library(IN userid INTEGER,
                                                  IN doc_id INTEGER,
                                                  OUT error_code INTEGER,
                                                  OUT result INTEGER,
                                                  OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc          RECORD;
    userName       TEXT;
    is_peakasutaja BOOLEAN = FALSE;

BEGIN

    SELECT
        l.*,
        u.ametnik AS user_name,
        u.rekvid  AS kasutaja_rekvid
    INTO v_doc
    FROM
        libs.library                  l
            LEFT OUTER JOIN ou.userid u ON u.id = userid
    WHERE
        l.id = doc_id;

    IF v_doc IS NULL
    THEN
        error_code = 6;
        error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    IF NOT exists
    (
        SELECT
            id
        FROM
            ou.userid u
        WHERE
              id = userid
          AND (u.rekvid = v_doc.kasutaja_rekvid OR v_doc.kasutaja_rekvid IS NULL OR v_doc.kasutaja_rekvid = 0)
    )
    THEN

        error_code = 5;
        error_message = 'Kasutaja ei leitud, rekvId: ' || coalesce(v_doc.rekvid, 0) :: TEXT || ', userId:' ||
                        coalesce(userid, 0) :: TEXT;
        result = 0;
--        RETURN;

    END IF;

    -- проверим на использование кода в справочниках
    IF (v_doc.library = 'KOOLITUSE_TYYP' AND exists
    (
        SELECT
            id
        FROM
            libs.library l
        WHERE
              l.library = 'LAPSE_GRUPP'
          AND status <> 3
          AND coalesce((l.properties::JSONB ->> 'tyyp')::INTEGER, 0)::INTEGER =
              v_doc.id
    ))
        OR (v_doc.library = 'KOOLITUSE_LIIK' AND exists
        (
            SELECT
                id
            FROM
                libs.nomenklatuur n
            WHERE
                  status <> 3
              AND n.properties::JSONB ->> 'oppe_tyyp' = v_doc.kood
        ))
        OR (v_doc.library = 'ASUTUSE_LIIK' AND exists
        (
            SELECT
                id
            FROM
                ou.rekv r
            WHERE
                  r.properties ->> 'liik' IS NOT NULL
              AND r.properties ->> 'liik' = v_doc.kood::TEXT
        ))
    THEN
        error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
        error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
        result = 0;

        RAISE EXCEPTION 'Есть связанные доку менты. удалять нельзя';
        RETURN;

    END IF;


    IF v_doc.library IN ('TUNNUS', 'OBJEKT', 'PROJ', 'URITUS')
    THEN
        -- контроль за правами. Ограничен (В.Б)
        SELECT
            kasutaja,
            (u.roles ->> 'is_peakasutaja')::BOOLEAN AS is_peakasutaja

        INTO userName, is_peakasutaja
        FROM
            ou.userid u
        WHERE
              u.rekvid = v_doc.rekvid
          AND u.id = userId;

        IF (userName IS NULL OR NOT is_peakasutaja)
        THEN
            RAISE EXCEPTION 'Viga, Puuduvad õigused või kasutaja ei leidnud %', user;
--            RETURN ;
        END IF;

    END IF;

    UPDATE libs.library
    SET
        status = 3
    WHERE
        id = doc_id;

    -- proj laiendus
    if v_doc.library = 'PROJ' then
        delete from libs.proj_laiendus where proj_id = doc_id;
    end if;


    result = 1;
    RETURN;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_delete_library(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_delete_library(INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT *
FROM libs.sp_delete_library(2477, 121358)

select * from libs.library where kood = 'Kood'

*/