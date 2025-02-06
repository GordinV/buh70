DROP FUNCTION IF EXISTS hooldekodu.sp_delete_hootehing(INTEGER, INTEGER, BOOLEAN);

CREATE OR REPLACE FUNCTION hooldekodu.sp_delete_hootehing(IN userid INTEGER,
                                                          IN doc_id INTEGER,
                                                          IN kas_journal BOOLEAN DEFAULT FALSE,
                                                          OUT error_code INTEGER,
                                                          OUT result INTEGER,
                                                          OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc   RECORD;
    l_mk_id INTEGER;
BEGIN
    SELECT
        l.*,
        u.ametnik AS user_name,
        u.rekvid  AS kasutaja_rekvid
    INTO v_doc
    FROM
        hooldekodu.hootehingud        l
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

    if not ou.fnc_aasta_kontrol(v_doc.rekvid, v_doc.kpv) then
        raise exception 'Viga, period on kinni';
    end if;


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
        RETURN;

    END IF;


    UPDATE hooldekodu.hootehingud
    SET
        status = 3
    WHERE
        id = doc_id;

    -- удаляем связанные документы
    IF v_doc.allikas = 'TASKURAHA' AND v_doc.summa < 0
    THEN
        SELECT
            mk.parentid
        INTO l_mk_id
        FROM
            docs.mk1               mk1
                INNER JOIN docs.mk mk ON mk.id = mk1.parentid
        WHERE
            mk1.journalid = v_doc.journalid
        LIMIT 1;

        IF l_mk_id IS NOT NULL
        THEN
            PERFORM docs.sp_delete_mk(userid, l_mk_id);
        ELSE
            SELECT
                k1.parentid
            INTO l_mk_id
            FROM
                docs.korder1 k1
            WHERE
                k1.journalid = v_doc.journalid
            LIMIT 1;

            PERFORM docs.sp_delete_korder(userid, l_mk_id);


        END IF;


    END IF;

-- удаляем связанную проводку
    IF NOT coalesce(kas_journal, FALSE)
    THEN
        PERFORM docs.sp_delete_journal(userid, v_doc.journalid);
    END IF;

    PERFORM hooldekodu.sp_calc_hoojaak(v_doc.isikid);

    result = 1;
    RETURN;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION hooldekodu.sp_delete_hootehing(INTEGER, INTEGER,BOOLEAN) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_delete_hootehing(INTEGER, INTEGER,BOOLEAN) TO hkametnik;

/*
SELECT *
FROM libs.sp_delete_library(2477, 121358)

select * from libs.library where kood = 'Kood'

*/