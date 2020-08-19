DROP FUNCTION IF EXISTS docs.gen_lausend_vmk(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.gen_lausend_vmk(IN tnid INTEGER,
                                                IN userid INTEGER,
                                                OUT error_code INTEGER,
                                                OUT result INTEGER,
                                                OUT error_message TEXT)
AS
$BODY$
DECLARE
    v_journal    RECORD;

    v_journal1   RECORD;
    v_vmk        RECORD;
    v_vmk1       RECORD;
    v_dokprop    RECORD;
    lcAllikas    VARCHAR(20);
    lcSelg       TEXT;
    v_selg       RECORD;
    l_json       TEXT;
    new_history  JSONB;
    userName     TEXT;
    a_docs_ids   INTEGER[];
    rows_fetched INTEGER = 0;
    json_mk1     JSONB;
    l_jaak       NUMERIC = 0;

BEGIN

    SELECT d.docs_ids,
           k.*,
           aa.tp,
           aa.konto
           INTO v_vmk
    FROM docs.mk k
             INNER JOIN docs.doc d ON d.id = k.parentId
             LEFT OUTER JOIN ou.aa aa ON aa.id = k.aaid
    WHERE d.id = tnId;

    GET DIAGNOSTICS rows_fetched = ROW_COUNT;

    IF rows_fetched = 0
    THEN
        error_code = 4; -- No documents found
        error_message = 'No documents found';
        result = 0;
        RETURN;
    END IF;

    IF v_vmk.doklausid = 0
    THEN
        error_code = 1; -- Konteerimine pole vajalik
        error_message = 'Konteerimine pole vajalik';
        result = 0;
        RETURN;
    END IF;

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = v_vmk.rekvId
      AND u.id = userId;

    IF userName IS NULL
    THEN
        error_message = 'User not found';
        error_code = 3;
        RETURN;
    END IF;

    IF v_vmk.rekvid > 1
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
    WHERE dokprop.id = v_vmk.doklausid
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
            FROM docs.mk1 k1
                     INNER JOIN libs.nomenklatuur nom ON k1.nomid = nom.id
            WHERE k1.parentid = v_vmk.id
            LOOP
                lcSelg = lcSelg || ', ' || trim(v_selg.nimetus);
            END LOOP;
    ELSE
        lcSelg = trim(v_dokprop.selg);
    END IF;


    FOR v_vmk1 IN
        SELECT k1.*,
               coalesce(dokvaluuta1.valuuta, 'EUR') :: VARCHAR AS valuuta,
               coalesce(dokvaluuta1.kuurs, 1) :: NUMERIC       AS kuurs,
               a.tp
        FROM docs.mk1 k1
                 LEFT OUTER JOIN docs.dokvaluuta1 dokvaluuta1 ON (k1.id = dokvaluuta1.dokid AND dokvaluuta1.dokliik = 4)
                 INNER JOIN libs.asutus a ON a.id = k1.asutusid
        WHERE k1.parentid = v_vmk.Id
        LOOP
            l_jaak = v_vmk1.summa;
            SELECT coalesce(v_vmk.journalid, 0) AS id,
                   'JOURNAL'                    AS doc_type_id,
                   v_vmk.kpv                    AS kpv,
                   lcSelg                       AS selg,
                   v_vmk.muud                   AS muud,
                   'MK nr. ' || v_vmk.number    AS dok,
                   v_vmk1.asutusid              AS asutusid
                   INTO v_journal;

            -- avans
            IF v_vmk.dokid IS NOT NULL AND exists(SELECT id FROM docs.avans1 WHERE parentid = v_vmk.dokid)
            THEN
                v_journal.dok = (SELECT number FROM docs.avans1 WHERE parentid = v_vmk.dokid LIMIT 1);
            END IF;

            IF NOT empty(v_vmk1.kood2)
            THEN
                lcAllikas = v_vmk1.kood2;
            END IF;

            IF (v_vmk.arvid IS NULL OR v_vmk.arvid = 0)
            THEN
                SELECT 0                               AS id,
                       coalesce(v_vmk1.summa, 0)       AS summa,
                       coalesce(v_vmk1.valuuta, 'EUR') AS valuuta,
                       coalesce(v_vmk1.kuurs, 1)       AS kuurs,
                       v_vmk1.konto                    AS deebet,
                       coalesce(v_vmk1.tp, '800599')   AS lisa_d,
                       v_vmk.konto                     AS kreedit,
                       coalesce(v_vmk.tp, '800401')    AS lisa_k,
                       coalesce(v_vmk1.tunnus, '')     AS tunnus,
                       coalesce(v_vmk1.proj, '')       AS proj,
                       coalesce(v_vmk1.kood1, '')      AS kood1,
                       coalesce(v_vmk1.kood2, '')      AS kood2,
                       coalesce(v_vmk1.kood3, '')      AS kood3,
                       coalesce(v_vmk1.kood4, '')      AS kood4,
                       coalesce(v_vmk1.kood5, '')      AS kood5
                       INTO v_journal1;

                json_mk1 = coalesce(json_mk1, '[]'::JSONB) || to_jsonb(v_journal1);

            ELSE
                FOR v_journal1 IN
                    SELECT 0                                                         AS id,
                           CASE WHEN l_jaak < a1.summa THEN l_jaak ELSE a1.summa END AS summa,
                           coalesce(v_vmk1.valuuta, 'EUR')                           AS valuuta,
                           coalesce(v_vmk1.kuurs, 1)                                 AS kuurs,
                           v_vmk1.konto                                              AS deebet,
                           coalesce(v_vmk1.tp, '800599')                             AS lisa_d,
                           v_vmk.konto                                               AS kreedit,
                           coalesce(v_vmk.tp, '800401')                              AS lisa_k,
                           coalesce(a1.tunnus, '')                                   AS tunnus,
                           coalesce(a1.proj, '')                                     AS proj,
                           coalesce(a1.kood1, '')                                    AS kood1,
                           coalesce(a1.kood2, '')                                    AS kood2,
                           coalesce(a1.kood3, '')                                    AS kood3,
                           coalesce(a1.kood4, '')                                    AS kood4,
                           coalesce(a1.kood5, '')                                    AS kood5
                    FROM docs.arv1 a1
                             INNER JOIN docs.arv a ON a.id = a1.parentid
                    WHERE a.parentid = v_vmk.arvid
                    ORDER BY a1.id
                    LOOP
                        l_jaak = l_jaak - v_journal1.summa;
                        json_mk1 = coalesce(json_mk1, '[]'::JSONB) || to_jsonb(v_journal1);
                        IF l_jaak <= 0
                        THEN
                            EXIT;
                        END IF;
                    END LOOP;
                IF l_jaak > 0
                THEN
                    SELECT 0                               AS id,
                           l_jaak                          AS summa,
                           coalesce(v_vmk1.valuuta, 'EUR') AS valuuta,
                           coalesce(v_vmk1.kuurs, 1)       AS kuurs,
                           v_vmk1.konto                    AS deebet,
                           coalesce(v_vmk1.tp, '800599')   AS lisa_d,
                           v_vmk.konto                     AS kreedit,
                           coalesce(v_vmk.tp, '800401')    AS lisa_k,
                           coalesce(v_vmk1.tunnus, '')     AS tunnus,
                           coalesce(v_vmk1.proj, '')       AS proj,
                           coalesce(v_vmk1.kood1, '')      AS kood1,
                           coalesce(v_vmk1.kood2, '')      AS kood2,
                           coalesce(v_vmk1.kood3, '')      AS kood3,
                           coalesce(v_vmk1.kood4, '')      AS kood4,
                           coalesce(v_vmk1.kood5, '')      AS kood5
                           INTO v_journal1;

                    json_mk1 = coalesce(json_mk1, '[]'::JSONB) || to_jsonb(v_journal1);

                END IF;

            END IF;

            IF json_mk1 IS NOT NULL
            THEN

                SELECT v_journal.id,
                       v_journal.doc_type_id,
                       v_journal.kpv,
                       v_journal.selg,
                       v_journal.muud,
                       v_journal.dok,
                       v_journal.asutusid,
                       json_mk1 AS "gridData"
                       INTO v_journal;

                SELECT row_to_json(row) INTO l_json
                FROM (SELECT 0         AS id,
                             v_journal AS data) row;

                result = docs.sp_salvesta_journal(l_json :: JSON, userId, v_vmk.rekvId);
            ELSE
                RAISE NOTICE 'null';
            END IF;

            /* salvestan lausend */

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
                SET docs_ids   = array(SELECT DISTINCT unnest(array_append(v_vmk.docs_ids, result))),
                    lastupdate = now(),
                    history    = coalesce(history, '[]') :: JSONB || new_history
                WHERE id = v_vmk.parentId;

                -- lausend
                SELECT docs_ids INTO a_docs_ids
                FROM docs.doc
                WHERE id = result;

                -- add new id into docs. ref. array
                a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_vmk.parentId)));

                UPDATE docs.doc
                SET docs_ids = a_docs_ids
                WHERE id = result;

                -- direct ref to journal
                UPDATE docs.mk1
                SET journalId = result
                WHERE id = v_vmk1.id;
            ELSE
                error_code = 2;
                result = 0;
                EXIT;
            END IF;

        END LOOP; -- v_journal
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

ALTER FUNCTION docs.gen_lausend_vmk( INTEGER, INTEGER )
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.gen_lausend_vmk(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.gen_lausend_vmk(INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT error_code,
       result,
       error_message
FROM docs.gen_lausend_vmk(1616833, 70);





select * from libs.dokprop

select * from libs.library where library = 'DOK'
-- 7

insert into libs.dokprop (parentid, registr, selg, details, tyyp)
	values (7, 1, 'Sorder', '{"konto":"100000"}'::jsonb, 1 )

update docs.korder1 set doklausid = 4 where tyyp = 1
*/
