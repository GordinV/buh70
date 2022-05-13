DROP FUNCTION IF EXISTS docs.gen_lausend_smk(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.gen_lausend_smk(IN tnid INTEGER,
                                                IN userid INTEGER,
                                                OUT error_code INTEGER,
                                                OUT result INTEGER,
                                                OUT error_message TEXT)
AS
$BODY$
DECLARE
    v_journal      RECORD;
    v_journal1     RECORD;
    v_smk          RECORD;
    v_smk1         RECORD;
    v_arv          RECORD;
    v_dokprop      RECORD;
    v_aa           RECORD;
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
    l_dok          TEXT;
    l_asutus_id    INTEGER;
    l_laps_id      INTEGER;
BEGIN

    RAISE NOTICE 'start gen_lausend %',tnid;
    SELECT d.docs_ids,
           k.*,
           aa.tp,
           aa.konto
    INTO v_smk
    FROM docs.mk k
             INNER JOIN docs.doc d ON d.id = k.parentId
             LEFT OUTER JOIN ou.aa aa ON aa.id = k.aaid
    WHERE d.id = tnId;

    IF v_smk.konto IS NULL
    THEN
        SELECT *
        INTO v_aa
        FROM ou.aa
        WHERE parentid = v_smk.rekvid
          AND default_ = 1
          AND kassa = 1
        ORDER BY id DESC
        LIMIT 1;
        v_smk.konto = v_aa.konto;
        v_smk.tp = v_aa.tp;

    END IF;

    GET DIAGNOSTICS rows_fetched = ROW_COUNT;

    IF rows_fetched = 0
    THEN
        error_code = 4; -- No documents found
        error_message = 'No documents found ' || tnid::TEXT;
        result = 0;
        RAISE NOTICE 'No documents found ';
        RETURN;
    END IF;

    IF v_smk.doklausid = 0
    THEN
        error_code = 1; -- Konteerimine pole vajalik
        error_message = 'Konteerimine pole vajalik ';
        RAISE NOTICE 'v_smk.doklausid = 0a, tnid %',tnid;
        result = 0;
        RETURN;
    END IF;

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = v_smk.rekvId
      AND u.id = userId;

    IF userName IS NULL
    THEN
        error_message = 'User not found';
        error_code = 3;
        RAISE NOTICE 'User not found %', userId;

        RETURN;
    END IF;

    IF v_smk.rekvid > 1
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
    WHERE dokprop.id = v_smk.doklausid
    LIMIT 1;

    IF NOT Found OR v_dokprop.registr = 0
    THEN
        error_code = 1; -- Konteerimine pole vajalik
        result = 0;
        error_message = 'Konteerimine pole vajalik';
        RAISE NOTICE 'pole vaja, rekv_id %',v_smk.rekvId;
        RETURN;
    END IF;

    -- koostame selg rea
    lcSelg = trim(v_dokprop.selg);
    IF (SELECT count(id)
        FROM ou.rekv
        WHERE parentid = 119
           OR id = 119) > 0
    THEN -- Narva LV kultuuriosakond. @todo need flexible solution
        FOR v_selg IN
            SELECT DISTINCT nom.nimetus
            FROM docs.mk1 k1
                     INNER JOIN libs.nomenklatuur nom ON k1.nomid = nom.id
            WHERE k1.parentid = v_smk.id
            LOOP
                lcSelg = lcSelg || ', ' || trim(v_selg.nimetus);
            END LOOP;
    ELSE
        lcSelg = trim(v_dokprop.selg);
    END IF;

    l_dok = 'MK number:' || v_smk.number;
-- ссылка на счет, если есть
    IF (v_smk.arvid IS NOT NULL AND v_smk.arvid > 0)
    THEN
        SELECT number FROM docs.arv a WHERE parentid = v_smk.arvid INTO v_arv;
        IF v_arv.number IS NOT NULL AND NOT empty(v_arv.number)
        THEN
            l_dok = 'Arve nr. ' || v_arv.number;
        END IF;

    END IF;

    FOR v_smk1 IN
        SELECT k1.*,
               'EUR' :: VARCHAR                                                                     AS valuuta,
               1 :: NUMERIC                                                                         AS kuurs,
               CASE WHEN k1.tp IS NULL OR empty(k1.tp) THEN coalesce(a.tp, '800599') ELSE k1.tp END AS tp
        FROM docs.mk1 k1
                 INNER JOIN libs.asutus a ON a.id = k1.asutusid
        WHERE k1.parentid = v_smk.Id
        LOOP
            l_asutus_id = v_smk1.asutusid;
            -- если род. плата, то меняем на ответственного

            l_laps_id = (SELECT parentid FROM lapsed.liidestamine l WHERE docid = v_smk.parentid LIMIT 1);

            -- если есть ребенок, то используем ответственного родителя для контировки
            IF l_laps_id IS NOT NULL
            THEN
                l_asutus_id = (SELECT asutusid
                               FROM lapsed.vanem_arveldus v
                                        INNER JOIN libs.asutus a ON a.id = v.asutusid
                               WHERE v.parentid = l_laps_id
                                 AND v.rekvid = v_smk.rekvid
                               ORDER BY v.arveldus DESC, v.id DESC
                               LIMIT 1);
            END IF;


            -- готовим параментры для шапки проводки
            SELECT coalesce(v_smk1.journalid, 0) AS id,
                   'JOURNAL'                     AS doc_type_id,
                   v_smk.kpv                     AS kpv,
                   lcSelg                        AS selg,
                   v_smk.muud                    AS muud,
                   l_dok                         AS dok,
                   l_asutus_id                   AS asutusid
            INTO v_journal;


            IF NOT empty(v_smk1.kood2)
            THEN
                lcAllikas = v_smk1.kood2;
            END IF;

            -- параметры для табличной части

            SELECT 0                               AS id,
                   coalesce(v_smk1.summa, 0)       AS summa,
                   coalesce(v_smk1.valuuta, 'EUR') AS valuuta,
                   coalesce(v_smk1.kuurs, 1)       AS kuurs,
                   ltrim(rtrim(v_smk.konto))       AS deebet,
                   coalesce(v_smk.tp, '800401')    AS lisa_d,
                   ltrim(rtrim(v_smk1.konto))      AS kreedit,
                   coalesce(v_smk1.tp, '800599')   AS lisa_k,
                   coalesce(v_smk1.tunnus, '')     AS tunnus,
                   coalesce(v_smk1.proj, '')       AS proj,
                   coalesce(v_smk1.kood1, '')      AS kood1,
                   coalesce(v_smk1.kood2, '')      AS kood2,
                   coalesce(v_smk1.kood3, '')      AS kood3,
                   coalesce(v_smk1.kood4, '')      AS kood4,
                   coalesce(v_smk1.kood5, '')      AS kood5
            INTO v_journal1;

            -- готовим параметры
            l_json_details = row_to_json(v_journal1);
            l_json = row_to_json(v_journal);
            l_json = ('{"data":' || trim(TRAILING FROM l_json, '}') :: TEXT || ',"gridData":[' || l_json_details ||
                      ']}}');

            result = docs.sp_salvesta_journal(l_json :: JSON, userId, v_smk.rekvId);

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
                SET docs_ids   = array(SELECT DISTINCT unnest(array_append(v_smk.docs_ids, result))),
                    lastupdate = now(),
                    history    = coalesce(history, '[]') :: JSONB || new_history
                WHERE id = v_smk.parentId;

                -- lausend
                SELECT docs_ids
                INTO a_docs_ids
                FROM docs.doc
                WHERE id = result;

                -- add new id into docs. ref. array
                a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_smk.parentId)));

                UPDATE docs.doc
                SET docs_ids = a_docs_ids
                WHERE id = result;

                -- direct ref to journal
                UPDATE docs.mk1
                SET journalId = result
                WHERE id = v_smk1.id;
            ELSE
                error_code = 2;
                result = 0;
                EXIT;
            END IF;

        END LOOP;
    RAISE NOTICE 'result %',result;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

ALTER FUNCTION docs.gen_lausend_smk( INTEGER, INTEGER )
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.gen_lausend_smk(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.gen_lausend_smk(INTEGER, INTEGER) TO dbpeakasutaja;

/*


SELECT
  error_code,
  result,
  error_message
FROM docs.gen_lausend_smk(2377148,(select id from ou.userid where kasutaja = 'vlad' and rekvid = 63 limit 1));

select * from libs.dokprop

select * from libs.library where library = 'DOK'
-- 7

insert into libs.dokprop (parentid, registr, selg, details, tyyp)
	values (7, 1, 'Sorder', '{"konto":"100000"}'::jsonb, 1 )

update docs.korder1 set doklausid = 4 where tyyp = 1

select * from docs.mk1 where parentid in (select id from docs.mk where parentid = 2377148)

update docs.mk1 set kood1 = '01111', kood5 = '3220'
where id = 1101234
*/


