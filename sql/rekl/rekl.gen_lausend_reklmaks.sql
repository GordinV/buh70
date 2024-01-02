DROP FUNCTION IF EXISTS palk.gen_lausend_reklmaks(INTEGER, JSON);
DROP FUNCTION IF EXISTS rekl.gen_lausend_reklmaks(INTEGER, JSON);

CREATE OR REPLACE FUNCTION rekl.gen_lausend_reklmaks(IN user_id INTEGER, IN params JSON, OUT result INTEGER,
                                                     OUT error_code INTEGER, OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_dekl_id   INTEGER = params ->> 'id';
    l_db_konto  TEXT    = '102060';
    l_kr_konto  TEXT    = '304400';
    l_db_tp     TEXT    = '800699';
    l_kr_tp     TEXT    = '800699';
    v_toiming   RECORD;
    v_user      RECORD;
    v_journal   RECORD;
    v_journal1  RECORD;
    l_json      JSON;
    new_history JSONB;
    a_docs_ids  INTEGER[];
BEGIN

    SELECT kasutaja,
           rekvid
    INTO v_user
    FROM ou.userid u
    WHERE u.id = user_Id;

    IF v_user.kasutaja IS NULL
    THEN
        error_code = 5;
        error_message = 'Kasutaja ei leitud,  userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        RETURN;
    END IF;

    IF l_dekl_id IS NULL
    THEN
        error_code = 6;
        error_message = 'Parametrid on vale või puuduvad';
        result = 0;
        RETURN;

    END IF;

    SELECT t.*,
           a.tp,
           d.selg,
           l.rekvid,
           l.docs_ids
    INTO v_toiming
    FROM rekl.toiming t
             INNER JOIN libs.asutus a ON a.id = t.asutusid
             INNER JOIN docs.doc l ON l.id = t.parentid
             LEFT OUTER JOIN libs.dokprop d ON d.id = t.dokpropid

    WHERE t.parentid = l_dekl_id;

    IF v_toiming.dokpropid IS NULL OR v_toiming.dokpropid = 0 OR v_toiming.summa = 0
    THEN
        error_message = 'Konteerimine pole vajalik, dok tyyp ei ole defineeritud voi summa = 0 ';
        result = 1;
        RETURN;
    END IF;

    l_db_tp = v_toiming.tp;
    l_kr_tp = v_toiming.tp;

    -- готовим параметры
    SELECT v_toiming.journalid                          AS id,
           'JOURNAL'                                    AS doc_type_id,
           v_toiming.saadetud                           AS kpv,
           coalesce(v_toiming.selg, 'Reklaam')          AS selg,
           'AUTOMATSELT LAUSEND (GEN_LAUSEND_REKLMAKS)' AS muud,
           v_toiming.asutusid                           AS asutusid
    INTO v_journal;

    SELECT 0                            AS id,
           coalesce(v_toiming.summa, 0) AS summa,
           l_db_konto                   AS deebet,
           l_db_tp                      AS lisa_d,
           l_kr_konto                   AS kreedit,
           l_kr_tp                      AS lisa_k,
           '01112'                      AS kood1,
           '80'                         AS kood2, -- Valentina 29.06.2022
           '3044'                       AS kood5
    INTO v_journal1;

    l_json = ('{"data":' || trim(TRAILING FROM (row_to_json(v_journal)) :: TEXT, '}') :: TEXT || ',"gridData":[' ||
              (row_to_json(v_journal1)) || ']}}');

    /* salvestan lausend */
    result = docs.sp_salvesta_journal(l_json :: JSON, user_id, v_toiming.rekvId);

    IF result IS NOT NULL AND result > 0
    THEN
        /*
        ajalugu
        */

        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()           AS updated,
                     v_user.kasutaja AS user) row;

        -- will add docs into doc's pull
        -- arve

        UPDATE docs.doc
        SET docs_ids   = array(SELECT DISTINCT unnest(array_append(v_toiming.docs_ids, result))),
            lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || new_history
        WHERE id = v_toiming.parentId;

        -- lausend
        SELECT docs_ids
        INTO a_docs_ids
        FROM docs.doc
        WHERE id = result;

        -- add new id into docs. ref. array
        a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_toiming.parentId)));

        UPDATE docs.doc
        SET docs_ids = a_docs_ids
        WHERE id = result;

        -- сохраним ссылку на
        UPDATE rekl.toiming
        SET journalId = result
        WHERE parentid = l_dekl_id;
    END IF;
    RETURN;
END;

$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION rekl.gen_lausend_reklmaks(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.gen_lausend_reklmaks(INTEGER, JSON) TO dbpeakasutaja;

/*
SELECT rekl.gen_lausend_reklmaks(1, '{"id": 294174}' :: JSON)

select * from rekl.toiming where dokpropid is not null order by id desc limit 100


select * from libs.asutus where id = 32121
*/