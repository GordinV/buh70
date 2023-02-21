DROP FUNCTION IF EXISTS docs.gen_lausend_avans(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.gen_lausend_avans(IN tnid INTEGER,
                                                  IN userid INTEGER,
                                                  OUT error_code INTEGER,
                                                  OUT result INTEGER,
                                                  OUT error_message TEXT)
AS
$BODY$
DECLARE
    v_journal         RECORD;
    v_journal1        RECORD;
    v_avans1          RECORD;
    v_avans2          RECORD;
    v_dokprop         RECORD;
    lcAllikas         VARCHAR(20);
    lcSelg            TEXT;
    v_selg            RECORD;
    l_json            TEXT    = '';
    l_json_row        TEXT    = '';
    l_json_details    TEXT    = '';
    new_history       JSONB;
    userName          TEXT;
    a_docs_ids        INTEGER[];
    rows_fetched      INTEGER = 0;
    DOC_STATUS_ACTIVE INTEGER = 1;
    l_tp_db           VARCHAR(20);
    l_tp_kr           VARCHAR(20);

BEGIN

    SELECT d.docs_ids,
           k.*
    INTO v_avans1
    FROM docs.avans1 k
             INNER JOIN docs.doc d ON d.id = k.parentId
    WHERE d.id = tnId;

    GET DIAGNOSTICS rows_fetched = ROW_COUNT;

    IF rows_fetched = 0
    THEN
        error_code = 4; -- No documents found
        error_message = 'No documents found';
        result = 0;
        RETURN;
    END IF;

    IF v_avans1.dokpropid = 0
    THEN
        error_code = 1; -- Konteerimine pole vajalik
        error_message = 'Konteerimine pole vajalik';
        result = 0;
        RETURN;
    END IF;

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = v_avans1.rekvId
      AND u.id = userId;

    IF userName IS NULL
    THEN
        error_message = 'User not found';
        error_code = 3;
        RETURN;
    END IF;

    IF v_avans1.rekvid > 1
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
         jsonb_to_record(dokprop.details) AS details(konto TEXT)
    WHERE dokprop.id = v_avans1.dokpropid
    LIMIT 1;

    IF NOT Found OR v_dokprop.registr = 0
    THEN
        error_code = 1; -- Konteerimine pole vajalik
        result = 0;
        error_message = 'Konteerimine pole vajalik';
        RETURN;
    END IF;

    -- koostame selg rea
    lcSelg = trim(v_dokprop.selg);
    IF (SELECT count(id)
        FROM rekv
        WHERE parentid = 119
           OR id = 119) > 0
    THEN -- Narva LV kultuuriosakond. @todo need flexible solution
        FOR v_selg IN
            SELECT DISTINCT nom.nimetus
            FROM docs.avans2 k1
                     INNER JOIN libs.nomenklatuur nom ON k1.nomid = nom.id
            WHERE k1.parentid = v_avans1.id
            LOOP
                lcSelg = lcSelg || ', ' || trim(v_selg.nimetus);
            END LOOP;
    ELSE
        lcSelg = trim(v_dokprop.selg);
    END IF;

    SELECT coalesce(v_avans1.journalid, 0) AS id,
           'JOURNAL'                       AS doc_type_id,
           v_avans1.kpv                    AS kpv,
           lcSelg                          AS selg,
           v_avans1.muud                   AS muud,
           v_avans1.number                 AS dok,
           v_avans1.asutusid               AS asutusid
    INTO v_journal;

    FOR v_avans2 IN
        SELECT k1.*,
               coalesce(dokvaluuta1.valuuta, 'EUR') :: VARCHAR AS valuuta,
               coalesce(dokvaluuta1.kuurs, 1) :: NUMERIC       AS kuurs,
               a.tp,
               a.properties -> 'asutus_aa' -> 0 ->> 'aa'       AS aa

        FROM docs.avans2 k1
                 INNER JOIN docs.avans1 a1 ON a1.id = k1.parentid
                 LEFT OUTER JOIN docs.dokvaluuta1 dokvaluuta1 ON (k1.id = dokvaluuta1.dokid AND dokvaluuta1.dokliik = 4)
                 INNER JOIN libs.asutus a ON a.id = a1.asutusid
        WHERE a1.id = v_avans1.Id
        LOOP
            IF NOT empty(v_avans2.kood2)
            THEN
                lcAllikas = v_avans2.kood2;
            END IF;
            l_tp_db = v_avans2.tp;
            l_tp_kr = v_avans2.tp;

            IF v_avans2.konto = '550012'
            THEN
                -- только банк можно
                l_tp_db = '800401';
                CASE WHEN substr(v_avans2.aa, 5, 2) = '22' THEN
                    -- swed
                    l_tp_db = '800402';
                    WHEN substr(v_avans2.aa, 5, 2) = '10' THEN
                        l_tp_db = '800401';
                    WHEN substr(v_avans2.aa, 5, 2) IN ('96', '17') THEN
                        -- Luminor Bank AS
                        l_tp_db = '800404';

                    ELSE
                        l_tp_db = '800498';
                    END CASE;
            END IF;

            SELECT 0                                 AS id,
                   coalesce(v_avans2.summa, 0)       AS summa,
                   coalesce(v_avans2.valuuta, 'EUR') AS valuuta,
                   coalesce(v_avans2.kuurs, 1)       AS kuurs,
                   v_avans2.konto                    AS deebet,
                   coalesce(l_tp_db, '800599')       AS lisa_d,
                   v_dokprop.konto                   AS kreedit,
                   coalesce(l_tp_kr, '800599')       AS lisa_k,
                   coalesce(v_avans2.tunnus, '')     AS tunnus,
                   coalesce(v_avans2.proj, '')       AS proj,
                   coalesce(v_avans2.kood1, '')      AS kood1,
                   coalesce(v_avans2.kood2, '')      AS kood2,
                   coalesce(v_avans2.kood3, '')      AS kood3,
                   coalesce(v_avans2.kood4, '')      AS kood4,
                   coalesce(v_avans2.kood5, '')      AS kood5
            INTO v_journal1;

            l_json_row = row_to_json(v_journal1);
            l_json_details = l_json_details || CASE
                                                   WHEN len(l_json_details) > 0
                                                       THEN ','
                                                   ELSE '' END || l_json_row;
        END LOOP;

    l_json = row_to_json(v_journal);
    l_json = ('{"data":' || trim(TRAILING FROM l_json, '}') :: TEXT || ',"gridData":[' ||
              l_json_details || ']}}');

    result = docs.sp_salvesta_journal(l_json :: JSON, userId, v_avans1.rekvId);

    /* salvestan lausend */

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
        SET docs_ids   = array(SELECT DISTINCT unnest(array_append(v_avans1.docs_ids, result))),
            lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || new_history,
            status     = CASE
                             WHEN status IS NULL OR empty(status)
                                 THEN DOC_STATUS_ACTIVE
                             ELSE status END
        WHERE id = v_avans1.parentId;

        -- lausend
        UPDATE docs.doc
        SET docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_avans1.parentId)))
        WHERE id = result;

        -- direct ref to journal
        UPDATE docs.avans1
        SET journalId = result
        WHERE id = v_avans1.id;
    ELSE
        error_code = 2;
        result = 0;
    END IF;

    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

ALTER FUNCTION docs.gen_lausend_avans( INTEGER, INTEGER )
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.gen_lausend_avans(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.gen_lausend_avans(INTEGER, INTEGER) TO dbpeakasutaja;

/*


SELECT
  error_code,
  result,
  error_message
FROM docs.gen_lausend_avans(1268,1);

*/
