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
    l_dok        TEXT;
    v_arv        RECORD;
    l_asutuse_tp TEXT    = '800599';
    l_laps_id    INTEGER;
    l_asutus_id  INTEGER;
BEGIN

    SELECT d.docs_ids,
           k.*,
           aa.tp,
           aa.konto,
           (k.properties ->> 'kasusaaja_id')::INTEGER AS kasusaaja_id
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

    SELECT kasutaja
    INTO userName
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


    l_laps_id = (SELECT parentid FROM lapsed.liidestamine l WHERE docid = v_vmk.parentid LIMIT 1);

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
            WHERE k1.parentid = v_vmk.id
            LOOP
                lcSelg = lcSelg || ', ' || trim(v_selg.nimetus);
            END LOOP;
    ELSE
        lcSelg = trim(v_dokprop.selg);
    END IF;


    -- koostame dok rea
    l_dok = 'MK nr. ' || v_vmk.number;
    IF (v_vmk.arvid IS NOT NULL AND v_vmk.arvid > 0)
    THEN
        SELECT number FROM docs.arv a WHERE parentid = v_vmk.arvid INTO v_arv;
        IF v_arv.number IS NOT NULL AND NOT empty(v_arv.number)
        THEN
            l_dok = 'Arve nr. ' || v_arv.number;
        END IF;

    END IF;

    FOR v_vmk1 IN
        SELECT k1.*,
               'EUR' :: VARCHAR                                                                     AS valuuta,
               1 :: NUMERIC                                                                         AS kuurs,
               CASE WHEN k1.tp IS NULL OR empty(k1.tp) THEN coalesce(a.tp, '800599') ELSE k1.tp END AS a_tp
        FROM docs.mk1 k1
                 INNER JOIN libs.asutus a ON a.id = k1.asutusid
        WHERE k1.parentid = v_vmk.Id
        LOOP
            -- инициализируем детали проводки
            json_mk1 = '[]'::JSONB;
            l_jaak = v_vmk1.summa;

            l_asutus_id = v_vmk1.asutusid;

            IF (v_vmk.kasusaaja_id IS NOT NULL AND NOT empty(v_vmk.kasusaaja_id))
            THEN
                -- hooldekodu
                l_asutus_id = v_vmk.kasusaaja_id;
            END IF;
            -- если есть ребенок, то используем ответственного родителя для контировки

            IF l_laps_id IS NOT NULL
            THEN

                l_asutus_id = (SELECT asutusid
                               FROM lapsed.vanem_arveldus v
                                        INNER JOIN libs.asutus a ON a.id = v.asutusid
                               WHERE v.parentid = l_laps_id
                                 AND v.rekvid = v_vmk.rekvid
                               ORDER BY coalesce(v.arveldus, FALSE) DESC
                                       , v.id DESC
                               LIMIT 1);

                IF l_asutus_id IS NULL
                THEN
                    l_asutus_id = v_vmk1.asutusid;
                END IF;


                v_vmk1.konto = '10300029';

/*                В проводках по поступлению денег в Selgitus-е хорошо бы поставить так:
                    - при tegevusala 09110 поставить Lasteaiatasu
                    - при tegevusala 08102 и 09510, 09500 поставить Huvikoolitasu
                    - при tegevusala 08202 (это в Ругодиве) поставить Huviringitasu
*/
                lcSelg = CASE
                             WHEN v_vmk1.kood1 = '09110' THEN 'Lasteaiatasu'
                             WHEN v_vmk1.kood1 = '08102' THEN 'Huvikoolitasu'
                             WHEN v_vmk1.kood1 = '09510' THEN 'Huvikoolitasu'
                             WHEN v_vmk1.kood1 = '09500' THEN 'Huvikoolitasu'
                             WHEN v_vmk1.kood1 = '08202' THEN 'Huviringitasu'
                             ELSE lcSelg END;

            END IF;


            SELECT coalesce(v_vmk1.journalid, 0)        AS id,
                   'JOURNAL'                            AS doc_type_id,
                   coalesce(v_vmk.maksepaev, v_vmk.kpv) AS kpv,
                   lcSelg                               AS selg,
                   v_vmk.muud                           AS muud,
                   l_dok                                AS dok,
                   l_asutus_id                          AS asutusid
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
                       'EUR'                           AS valuuta,
                       1                               AS kuurs,
                       ltrim(rtrim(v_vmk1.konto))      AS deebet,
                       coalesce(v_vmk1.a_tp, '800599') AS lisa_d,
                       ltrim(rtrim(v_vmk.konto))       AS kreedit,
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
                           'EUR'                                                     AS valuuta,
                           1                                                         AS kuurs,
                           ltrim(rtrim(v_vmk1.konto))                                AS deebet,
                           coalesce(v_vmk1.a_tp, '800599')                           AS lisa_d,
                           ltrim(rtrim(v_vmk.konto))                                 AS kreedit,
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
                           'EUR'                           AS valuuta,
                           1                               AS kuurs,
                           v_vmk1.konto                    AS deebet,
                           coalesce(v_vmk1.a_tp, '800599') AS lisa_d,
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

                SELECT row_to_json(row)
                INTO l_json
                FROM (SELECT coalesce(v_journal.id, 0) AS id,
                             v_journal                 AS data) row;

                result = docs.sp_salvesta_journal(l_json :: JSON, userId, v_vmk.rekvId);
                l_json = NULL;
                json_mk1 = '[]'::JSONB;
            ELSE
                RAISE NOTICE 'null';
            END IF;

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
                SET docs_ids   = array(SELECT DISTINCT unnest(array_append(v_vmk.docs_ids, result))),
                    lastupdate = now(),
                    history    = coalesce(history, '[]') :: JSONB || new_history
                WHERE id = v_vmk.parentId;

                -- lausend
                SELECT docs_ids
                INTO a_docs_ids
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
FROM docs.gen_lausend_vmk(5274000, 5162);

select * from docs.mk where rekvid = 132 and number = '9658'

select * from ou.userid where rekvid = 132 and kasutaja = 'valentina.besekerskas'
*/
