DROP FUNCTION IF EXISTS docs.gen_lausend_vorder(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.gen_lausend_vorder(IN tnid INTEGER,
                                                   IN userid INTEGER,
                                                   OUT error_code INTEGER,
                                                   OUT result INTEGER,
                                                   OUT error_message TEXT)
AS
$BODY$
DECLARE
    lcDbKonto      VARCHAR(20);
    lcKrKonto      VARCHAR(20);
    lcDbTp         VARCHAR(20);
    lcKrTp         VARCHAR(20);
    lcKood5        VARCHAR(20);
    v_journal      RECORD;
    v_vorder       RECORD;
    v_dokprop      RECORD;
    v_vorder1      RECORD;
    lcAllikas      VARCHAR(20);
    lcSelg         TEXT;
    v_selg         RECORD;
    l_json         TEXT;
    l_json_details TEXT;
    l_json_row     TEXT;
    l_row_count    INTEGER = 0;
    new_history    JSONB;
    userName       TEXT;
    a_docs_ids     INTEGER[];
    rows_fetched   INTEGER = 0;

BEGIN

    SELECT d.docs_ids,
           k.*,
           asutus.tp AS asutus_tp
    INTO v_vorder
    FROM docs.korder1 k
             INNER JOIN docs.doc d ON d.id = k.parentId
             LEFT OUTER JOIN libs.asutus asutus ON asutus.id = k.asutusid
    WHERE d.id = tnId;

    GET DIAGNOSTICS rows_fetched = ROW_COUNT;

    IF rows_fetched = 0
    THEN
        RAISE NOTICE 'rows_fetched = 0, v_vorder %, tnId %', v_vorder.id, tnId;
        error_code = 4; -- No documents found
        error_message = 'No documents found';
        result = 0;
        RETURN;
    END IF;

    IF v_vorder.doklausid = 0
    THEN
        RAISE NOTICE 'v_vorder.doklausid = 0';
        error_code = 1; -- Konteerimine pole vajalik
        error_message = 'Konteerimine pole vajalik';
        result = 0;
        RETURN;
    END IF;

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = v_vorder.rekvId
      AND u.id = userId;

    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', userId;
        error_message = 'User not found';
        error_code = 3;
        RETURN;
    END IF;

    IF v_vorder.rekvid > 1
    THEN
        lcAllikas = 'LE-P'; -- narva LV @todo should create more flexible variant
    END IF;

    SELECT library.kood,
           dokprop.*,
           details.*
    INTO v_dokprop
    FROM libs.dokprop dokprop
             INNER JOIN libs.library library ON library.id = dokprop.parentid
            ,
         jsonb_to_record(dokprop.details) AS details(konto TEXT, kbmkonto TEXT)
    WHERE dokprop.id = v_vorder.doklausid
    LIMIT 1;

    IF NOT Found OR v_dokprop.registr = 0
    THEN
        RAISE NOTICE 'v_dokprop.registr = 0';
        error_code = 1; -- Konteerimine pole vajalik
        result = 0;
        error_message = 'Konteerimine pole vajalik';
        RETURN;
    END IF;

    lcDbKonto = '100000';
    -- koostame selg rea
    lcSelg = trim(v_dokprop.selg) || ' ' || trim(v_vorder.alus);
    IF (SELECT count(id)
        FROM ou.rekv
        WHERE parentid = 119
           OR id = 119) > 0
    THEN -- Narva LV kultuuriosakond. @todo need flexible solution
        FOR v_selg IN
            SELECT DISTINCT nom.nimetus
            FROM docs.korder2 k1
                     INNER JOIN libs.nomenklatuur nom ON k1.nomid = nom.id
            WHERE k1.parentid = v_vorder.id
            LOOP
                lcSelg = lcSelg || ', ' || trim(v_selg.nimetus);
            END LOOP;
    ELSE
        lcSelg = trim(v_dokprop.selg);
    END IF;

    v_vorder.asutus_tp = coalesce(v_vorder.asutus_tp, '800599');
    lcKrTp = coalesce(v_vorder.asutus_tp, '800599');

    SELECT coalesce(v_vorder.journalid, 0) AS id,
           'JOURNAL'                       AS doc_type_id,
           v_vorder.kpv                    AS kpv,
           lcSelg                          AS selg,
           v_vorder.muud                   AS muud,
           v_vorder.Asutusid               AS asutusid,
           'Arve nr. ' || v_vorder.number  AS dok
    INTO v_journal;

    l_json = row_to_json(v_journal);

    --		l_json_details = '[]';
    FOR v_vorder1 IN
        SELECT k1.*,
               coalesce(dokvaluuta1.valuuta, 'EUR') :: VARCHAR AS valuuta,
               coalesce(dokvaluuta1.kuurs, 1) :: NUMERIC       AS kuurs
        FROM docs.korder2 k1
                 LEFT OUTER JOIN docs.dokvaluuta1 dokvaluuta1
                                 ON (k1.id = dokvaluuta1.dokid AND dokvaluuta1.dokliik = 10)
        WHERE k1.parentid = v_vorder.Id
        LOOP
            IF NOT empty(v_vorder1.tp)
            THEN
                v_vorder.asutus_tp := v_vorder1.tp;
            END IF;

            IF NOT empty(v_vorder1.kood2)
            THEN
                lcAllikas = v_vorder1.kood2;
            END IF;

            lcKood5 = v_vorder1.kood5;

            /* sisse kassa order*/
            lcDbKonto = coalesce(v_vorder1.konto, 'puudub');
            lcKrKonto = v_dokprop.konto;

            SELECT 0                                      AS id,
                   coalesce(v_vorder1.summa, 0)           AS summa,
                   coalesce(v_vorder1.valuuta, 'EUR')     AS valuuta,
                   coalesce(v_vorder1.kuurs, 1)           AS kuurs,
                   lcDbKonto                              AS deebet,
                   coalesce(v_vorder.asutus_tp, '800599') AS lisa_d,
                   lcKrKonto                              AS kreedit,
                   ''                                     AS lisa_k,
                   coalesce(v_vorder1.tunnus, '')         AS tunnus,
                   coalesce(v_vorder1.proj, '')           AS proj,
                   coalesce(v_vorder1.kood1, '')          AS kood1,
                   coalesce(v_vorder1.kood2, '')          AS kood2,
                   coalesce(v_vorder1.kood3, '')          AS kood3,
                   coalesce(v_vorder1.kood4, '')          AS kood4,
                   coalesce(v_vorder1.kood5, '')          AS kood5
            INTO v_journal;

            l_json_row = row_to_json(v_journal);

            IF l_row_count > 0
            THEN
                l_json_details = l_json_details || ',' || l_json_row;
            ELSE
                l_json_details = l_json_row;
            END IF;

            l_row_count = l_row_count + 1;

        END LOOP;
    IF l_json_details IS NULL
    THEN
        l_json_details = '';
    END IF;

    l_json = ('{"data":' || trim(TRAILING FROM l_json, '}') :: TEXT || ',"gridData":[' || l_json_details || ']}}');

    /* salvestan lausend */

    result = docs.sp_salvesta_journal(l_json :: JSON, userId, v_vorder.rekvId);

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
        SET docs_ids   = array(SELECT DISTINCT unnest(array_append(v_vorder.docs_ids, result))),
            lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || new_history
        WHERE id = v_vorder.parentId;

        -- lausend
        SELECT docs_ids
        INTO a_docs_ids
        FROM docs.doc
        WHERE id = result;

        -- add new id into docs. ref. array
        a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_vorder.parentId)));

        UPDATE docs.doc
        SET docs_ids = a_docs_ids
        WHERE id = result;

        -- direct ref to journal
        UPDATE docs.korder1
        SET journalId = result
        WHERE id = v_vorder.id;

        error_code = 0;
    ELSE
        error_code = 2;
    END IF;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

ALTER FUNCTION docs.gen_lausend_vorder( INTEGER, INTEGER )
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.gen_lausend_vorder(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.gen_lausend_vorder(INTEGER, INTEGER) TO dbpeakasutaja;

--select error_code, result, error_message from docs.gen_lausend_vorder(99999,998);
