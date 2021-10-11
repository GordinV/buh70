DROP FUNCTION IF EXISTS docs.ebatoenaolised_mahakandmine(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION docs.ebatoenaolised_mahakandmine(IN l_user_id INTEGER,
                                                            IN l_id INTEGER,
                                                            IN l_kpv DATE DEFAULT current_date,
                                                            OUT error_code INTEGER,
                                                            OUT result INTEGER, OUT error_message TEXT)
AS
$BODY$
DECLARE
    l_kr_konto     VARCHAR(20);
    v_arv          RECORD;
    v_dokprop      RECORD;
    v_arv1         RECORD;
    l_json         TEXT;
    l_json_details JSONB   = '[]';
    l_row_count    INTEGER = 0;
    new_history    JSONB;
    userName       TEXT;
    a_docs_ids     INTEGER[];
    rows_fetched   INTEGER = 0;
    v_journal      RECORD;

BEGIN

    -- select dok data
    SELECT d.docs_ids,
           a.*,
           asutus.tp AS asutus_tp
    INTO v_arv
    FROM docs.arv a
             INNER JOIN docs.doc d ON d.id = a.parentId
             INNER JOIN libs.asutus asutus ON asutus.id = a.asutusid
    WHERE d.id = l_id;

    GET DIAGNOSTICS rows_fetched = ROW_COUNT;

    IF v_arv IS NULL
    THEN
        error_code = 4; -- No documents found
        error_message = 'No documents found';
        result = 0;
        RETURN;
    END IF;

    IF coalesce((v_arv.properties ->> 'ebatoenaolised_2_id')::INTEGER, 0) = 0 OR v_arv.jaak <= 0
    THEN
        error_code = 1; -- Konteerimine pole vajalik
        error_message = 'Mahakandmine pole vajalik';
        result = 0;
        RETURN;
    END IF;

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = v_arv.rekvId
      AND u.id = l_user_id;
    IF userName IS NULL
    THEN
        error_message = 'User not found';
        error_code = 3;
        RETURN;
    END IF;

    SELECT library.kood,
           dokprop.*,
           details.*
    INTO v_dokprop
    FROM libs.dokprop dokprop
             INNER JOIN libs.library library ON library.id = dokprop.parentid,
         jsonb_to_record(dokprop.details) AS details(konto TEXT, kbmkonto TEXT)
    WHERE dokprop.id = v_arv.doklausid
    LIMIT 1;

    -- lausend

    SELECT 0,
           'JOURNAL'                            AS doc_type_id,
           l_kpv as kpv,
           'Ebatõenäoliste nõuete mahakandmine' AS selg,
           v_arv.Asutusid,
           v_arv.number::TEXT                   AS dok
    INTO v_journal;

    l_json = row_to_json(v_journal);

--    l_json_details = '';
    l_kr_konto = coalesce(v_dokprop.konto, '103000');
    SELECT * INTO v_arv1 FROM docs.arv1 WHERE parentid = v_arv.id ORDER BY summa DESC LIMIT 1;

    SELECT 0                               AS id,
           v_arv.jaak                      AS summa,
           '103009'                        AS deebet,
           l_kr_konto                      AS kreedit,
           '800699'                        AS lisa_d,
           '800699'                        AS lisa_k,
           coalesce(v_arv1.tunnus, '')     AS tunnus,
           coalesce(v_arv1.kood1, '09110') AS kood1,
           coalesce(v_arv1.kood2, '80')    AS kood2,
           coalesce(v_arv1.kood3, '')      AS kood3,
           coalesce(v_arv1.kood5, '3220')  AS kood5
    INTO v_journal;

    l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_journal);


    l_row_count = l_row_count + 1;

    l_json = ('{"id": ' || coalesce(v_arv.journalid, 0)::TEXT || ',"data":' ||
              trim(TRAILING FROM l_json, '}') :: TEXT || ',"gridData":' || l_json_details::TEXT || '}}');
    --    RAISE NOTICE 'l_json 2 %', l_json :: JSON;

    /* salvestan lausend */

    IF l_row_count > 0
    THEN
        result = docs.sp_salvesta_journal(l_json :: JSON, l_user_id, v_arv.rekvId);
    ELSE
        error_message = 'Puudub kehtiv read';
        result = 0;
    END IF;

    IF result IS NOT NULL AND result > 0
    THEN
        /*
        ajalugu
        */

        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user) row;

        -- will add docs into doc's pull
        -- arve

        UPDATE docs.doc
        SET docs_ids   = array(SELECT DISTINCT unnest(array_append(v_arv.docs_ids, result))),
            lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || new_history
        WHERE id = v_arv.parentId;

        -- lausend
        SELECT docs_ids
        INTO a_docs_ids
        FROM docs.doc
        WHERE id = result;

        -- add new id into docs. ref. array
        a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_arv.parentId)));

        UPDATE docs.doc
        SET docs_ids = a_docs_ids
        WHERE id = result;

        -- direct ref to journal
        UPDATE docs.arv
        SET journalId = result
        WHERE id = v_arv.id;


        error_code = 0;
    ELSE
        error_code = 2;
    END IF;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.ebatoenaolised_mahakandmine(INTEGER, INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.ebatoenaolised_mahakandmine(INTEGER, INTEGER, DATE) TO dbpeakasutaja;

/*

SELECT error_code, result, error_message from docs.ebatoenaolised_mahakandmine(65, 2328427)


select * from docs.arvtasu where doc_arv_id  = 2347607

select docs.sp_delete_journal(65,2328428)

select * from cur_journal where id = 2347607
*/
