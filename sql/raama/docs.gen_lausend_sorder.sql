DROP FUNCTION IF EXISTS docs.gen_lausend_sorder(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.gen_lausend_sorder(IN tnid INTEGER,
                                                   IN userid INTEGER,
                                                   OUT error_code INTEGER,
                                                   OUT result INTEGER,
                                                   OUT error_message TEXT)
AS
$BODY$
DECLARE
    lcDbKonto         VARCHAR(20);
    lcKrKonto         VARCHAR(20);
    lcDbTp            VARCHAR(20);
    lcKrTp            VARCHAR(20);
    lcKood5           VARCHAR(20);
    v_journal         RECORD;
    v_sorder          RECORD;
    v_dokprop         RECORD;
    v_dokprop_details RECORD;
    v_sorder1         RECORD;
    lcAllikas         VARCHAR(20);
    lcSelg            TEXT;
    v_selg            RECORD;
    l_json            TEXT;
    l_json_details    TEXT;
    l_json_row        TEXT;
    l_row_count       INTEGER = 0;
    new_history       JSONB;
    userName          TEXT;
    a_docs_ids        INTEGER[];
    rows_fetched      INTEGER = 0;
    l_arve_number     TEXT    = '';
BEGIN

    SELECT d.docs_ids,
           k.*,
           asutus.tp AS asutus_tp
           INTO v_sorder
    FROM docs.korder1 k
             INNER JOIN docs.doc d ON d.id = k.parentId
             LEFT OUTER JOIN libs.asutus asutus ON asutus.id = k.asutusid
    WHERE d.id = tnId;

    IF v_sorder.parentid IS NULL
    THEN
        error_code = 4; -- No documents found
        error_message = 'No documents found';
        result = 0;
        RETURN;
    END IF;

    IF v_sorder.doklausid = 0
    THEN
        error_code = 1; -- Konteerimine pole vajalik
        error_message = 'Konteerimine pole vajalik';
        result = 0;
        RETURN;
    END IF;

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = v_sorder.rekvId
      AND u.id = userId;

    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', userId;
        error_message = 'User not found';
        error_code = 3;
        RETURN;
    END IF;

    IF v_sorder.rekvid > 1
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
         jsonb_to_record(dokprop.details) AS details (konto TEXT, kbmkonto TEXT)
    WHERE dokprop.id = v_sorder.doklausid
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
    lcSelg = trim(v_dokprop.selg) || ' ' || trim(v_sorder.alus);
    IF (SELECT count(id)
        FROM ou.rekv
        WHERE parentid = 119
           OR id = 119) > 0
    THEN -- Narva LV kultuuriosakond. @todo need flexible solution
        FOR v_selg IN
            SELECT DISTINCT nom.nimetus
            FROM docs.korder2 k1
                     INNER JOIN libs.nomenklatuur nom ON k1.nomid = nom.id
            WHERE k1.parentid = v_sorder.id
            LOOP
                lcSelg = lcSelg || ', ' || trim(v_selg.nimetus);
            END LOOP;
    ELSE
        lcSelg = trim(v_dokprop.selg);
    END IF;

    v_sorder.asutus_tp = coalesce(v_sorder.asutus_tp, '800599');
    lcKrTp = coalesce(v_sorder.asutus_tp, '800599');

    IF v_sorder.arvid IS NOT NULL
    THEN
        l_arve_number = 'Arve Nr. ' ||
                        ltrim(rtrim(coalesce((SELECT number FROM docs.arv WHERE parentid = v_sorder.arvid LIMIT 1),
                                             '')));
    END IF;

    SELECT coalesce(v_sorder.journalid, 0) AS id,
           'JOURNAL'                       AS doc_type_id,
           v_sorder.kpv                    AS kpv,
           lcSelg                          AS selg,
           v_sorder.muud                   AS muud,
           v_sorder.Asutusid               AS asutusid,
           l_arve_number                   AS dok
           INTO v_journal;

    l_json = row_to_json(v_journal);

    --		l_json_details = '[]';
    FOR v_sorder1 IN
        SELECT sum(k1.summa)                                                       AS summa,
               'EUR' :: VARCHAR                                                    AS valuuta,
               1 :: NUMERIC                                                        AS kuurs,
               coalesce(k1.tunnus, '')                                             AS tunnus,
               coalesce(k1.proj, '')                                               AS proj,
               coalesce(k1.kood1, '')                                              AS kood1,
               coalesce(k1.kood2, '')                                              AS kood2,
               coalesce(CASE WHEN k1.kood3 = 'null' THEN '' ELSE k1.kood3 END, '') AS kood3,
               coalesce(k1.kood4, '')                                              AS kood4,
               coalesce(k1.kood5, '')                                              AS kood5,
               k1.tp,
               coalesce(k1.konto, '')                                              AS konto

        FROM docs.korder2 k1
        WHERE k1.parentid = v_sorder.Id
        GROUP BY coalesce(k1.tunnus, ''),
                 coalesce(k1.proj, ''),
                 coalesce(k1.kood1, ''),
                 coalesce(k1.kood2, ''),
                 coalesce(CASE WHEN k1.kood3 = 'null' THEN '' ELSE k1.kood3 END, ''),
                 coalesce(k1.kood4, ''),
                 coalesce(k1.kood5, ''),
                 k1.tp,
                 coalesce(k1.konto, '')

        LOOP
            IF NOT empty(v_sorder1.tp)
            THEN
                v_sorder.asutus_tp := v_sorder1.tp;
            END IF;

            IF NOT empty(v_sorder1.kood2)
            THEN
                lcAllikas = v_sorder1.kood2;
            END IF;

            lcKood5 = v_sorder1.kood5;

            /* sisse kassa order*/
            lcDbKonto = v_dokprop.konto;
            lcKrKonto = coalesce(v_sorder1.konto, 'puudub');

            SELECT 0                                      AS id,
                   coalesce(v_sorder1.summa, 0)           AS summa,
                   coalesce(v_sorder1.valuuta, 'EUR')     AS valuuta,
                   coalesce(v_sorder1.kuurs, 1)           AS kuurs,
                   lcDbKonto                              AS deebet,
                   coalesce(v_sorder.asutus_tp, '800599') AS lisa_d,
                   lcKrKonto                              AS kreedit,
                   coalesce(v_sorder.asutus_tp, '800599') AS lisa_k,
                   coalesce(v_sorder1.tunnus, '')         AS tunnus,
                   coalesce(v_sorder1.proj, '')           AS proj,
                   coalesce(v_sorder1.kood1, '')          AS kood1,
                   coalesce(v_sorder1.kood2, '')          AS kood2,
                   coalesce(v_sorder1.kood3, '')          AS kood3,
                   coalesce(v_sorder1.kood4, '')          AS kood4,
                   coalesce(v_sorder1.kood5, '')          AS kood5
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

    result = docs.sp_salvesta_journal(l_json :: JSON, userId, v_sorder.rekvId);

    IF result IS NOT NULL AND result > 0
    THEN
        /*
        ajalugu
        */

        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user) row;

        -- will add docs into doc's pull
        -- arve

        UPDATE docs.doc
        SET docs_ids   = array(SELECT DISTINCT unnest(array_append(v_sorder.docs_ids, result))),
            lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || new_history
        WHERE id = v_sorder.parentId;

        -- lausend
        SELECT docs_ids INTO a_docs_ids
        FROM docs.doc
        WHERE id = result;

        -- add new id into docs. ref. array
        a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_sorder.parentId)));

        UPDATE docs.doc
        SET docs_ids = a_docs_ids
        WHERE id = result;

        -- direct ref to journal
        UPDATE docs.korder1
        SET journalId = result
        WHERE id = v_sorder.id;

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

ALTER FUNCTION docs.gen_lausend_sorder( INTEGER, INTEGER )
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.gen_lausend_sorder(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.gen_lausend_sorder(INTEGER, INTEGER) TO dbpeakasutaja;

SELECT error_code, result, error_message
FROM docs.gen_lausend_sorder(99999, 998);

/*


select * from libs.dokprop

select * from libs.library where library = 'DOK'
-- 7

insert into libs.dokprop (parentid, registr, selg, details, tyyp)
	values (7, 1, 'Sorder', '{"konto":"100000"}'::jsonb, 1 )

update docs.korder1 set doklausid = 4 where tyyp = 1
*/
