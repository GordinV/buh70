DROP FUNCTION IF EXISTS docs.gen_lausend_smk(INTEGER, INTEGER);
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
    l_json         JSONB;
    l_json_details JSONB   = '[]';
    l_json_row     JSONB;
    l_row_count    INTEGER = 0;
    new_history    JSONB;
    userName       TEXT;
    a_docs_ids     INTEGER[];
    rows_fetched   INTEGER = 0;
    l_dok          TEXT;
    l_asutus_id    INTEGER;
    l_laps_id      INTEGER;
    v_nom          RECORD;
    l_parallel_doc INTEGER;
    l_uur_summa    NUMERIC = 0;
    l_tasu_summa   NUMERIC = 0;
    l_uur_json     JSONB;
    l_muud_docs    NUMERIC = 0;
    l_arv_id       INTEGER;
BEGIN

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
               CASE WHEN k1.tp IS NULL OR empty(k1.tp) THEN coalesce(a.tp, '800599') ELSE k1.tp END AS tp,
               coalesce(n.properties ->> 'tunnus', '')                                              AS n_tunnus,
               coalesce(n.properties ->> 'tegev', '')                                               AS n_tegev,
               coalesce(n.properties ->> 'konto', '')                                               AS n_konto,
               coalesce(n.properties ->> 'artikkel', '')                                            AS n_artikkel,
               coalesce(n.properties ->> 'allikas', '')                                             AS n_allikas
        FROM docs.mk1 k1
                 INNER JOIN libs.asutus a ON a.id = k1.asutusid
                 INNER JOIN libs.nomenklatuur n ON n.id = k1.nomid
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
                               ORDER BY coalesce(v.arveldus, FALSE) DESC
                                       , v.id DESC
                               LIMIT 1);

                IF l_asutus_id IS NULL
                THEN
                    l_asutus_id = v_smk1.asutusid;
                END IF;


            END IF;

            IF l_laps_id IS NOT NULL
            THEN
                v_smk1.konto = '10300029';
                v_smk1.tp = '800699';
                v_smk1.tp = coalesce((SELECT tp FROM libs.asutus WHERE id = l_asutus_id), '800699');
                IF v_smk1.tp = '800698'
                THEN
                    -- Kalle, FIE меняекм на частные лица
                    v_smk1.tp = '800699';
                END IF;

                IF v_smk1.kood1 = 'null'
                THEN
                    v_smk1.kood1 = NULL;
                END IF;
                v_smk1.kood1 = coalesce(v_smk1.kood1, '09110');
                IF v_smk1.kood2 = 'null'
                THEN
                    v_smk1.kood2 = NULL;
                END IF;

                v_smk1.kood2 = coalesce(v_smk1.kood2, '80');
                IF v_smk1.kood5 = 'null'
                THEN
                    v_smk1.kood5 = NULL;
                END IF;

                v_smk1.kood5 = coalesce(v_smk1.kood5, '3220');
                IF v_smk1.tunnus = 'null'
                THEN
                    v_smk1.tunnus = NULL;
                END IF;

                v_smk1.tunnus =
                        coalesce(v_smk1.tunnus, (SELECT regexp_replace(nimetus, '[[:alpha:]]', '', 'g')
                                                 FROM ou.rekv
                                                 WHERE id = v_smk.rekvid
                                                 LIMIT 1));

/*                В проводках по поступлению денег в Selgitus-е хорошо бы поставить так:
                    - при tegevusala 09110 поставить Lasteaiatasu
                    - при tegevusala 08102 и 09510, 09500 поставить Huvikoolitasu
                    - при tegevusala 08202 (это в Ругодиве) поставить Huviringitasu
*/
                lcSelg = CASE
                             WHEN v_smk1.kood1 = '09110' THEN 'Lasteaiatasu'
                             WHEN v_smk1.kood1 = '08102' THEN 'Huvikoolitasu'
                             WHEN v_smk1.kood1 = '09510' THEN 'Huvikoolitasu'
                             WHEN v_smk1.kood1 = '09500' THEN 'Huvikoolitasu'
                             WHEN v_smk1.kood1 = '08202' THEN 'Huviringitasu'
                             ELSE lcSelg END;

                IF v_smk.selg = 'Oppetasu algsaldo 2023'
                THEN
                    -- alg saldo
                    lcSelg = 'Oppetasu algsaldo 2023';
                    v_smk.konto = '888888';
                    v_smk1.konto = '10300029';
                    v_smk1.tp = '800699';
                    v_smk.tp = '800699';
                    v_smk.kpv = '2023-01-01'::DATE;
                END IF;

                -- Muusikakool, üür

                IF v_smk.rekvid = 71 AND
                   exists(SELECT a.id
                          FROM docs.arv a
                                   INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
                                   INNER JOIN docs.arvtasu at
                                              ON at.doc_arv_id = a.parentid AND at.doc_tasu_id = v_smk.parentid AND
                                                 at.status < 3
                          WHERE a.parentid IN (SELECT unnest(v_smk.docs_ids))
                            AND a1.konto = '323330'
                       )
                THEN
                    -- есть в оплате счета сумма аренды
                    -- дополним пояснение
                    lcSelg = lcSelg + ', muusikariistade uur';

                    -- считаем сумму аренды инструмента

                    -- ид счета, с арендой, последний
                    l_arv_id = (SELECT a.parentid
                                FROM docs.arv a
                                         INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
                                WHERE a.parentid IN
                                      (SELECT at.doc_arv_id
                                       FROM docs.arvtasu at
                                       WHERE at.doc_tasu_id = v_smk.parentid
                                         AND at.status < 3)
                                  AND a1.konto IN ('323330')
                                ORDER BY a.kpv DESC
                                LIMIT 1);

                    -- сумма аренды в счете
                    SELECT sum(a1.summa)
                    INTO l_uur_summa
                    FROM docs.arv1 a1
                             INNER JOIN docs.arv a ON a.id = a1.parentid
                    WHERE a.parentid = l_arv_id
                      AND a1.konto IN ('323330');

                    -- сумма оплаты счета
                    l_tasu_summa = (SELECT at.summa)
                                   FROM docs.arvtasu at
                                   WHERE at.doc_arv_id = l_arv_id
                                     AND at.doc_tasu_id = v_smk.parentid
                                     AND at.status < 3;

                    IF l_tasu_summa < l_uur_summa
                    THEN
                        -- сумма оплаты в счете меньше стоимости аренды, уменьшим ее до суммы оплаты
                        l_uur_summa = l_tasu_summa;
                    END IF;

                    -- ищем прочие платежи , связанные с оплатой этого счета
                    IF l_arv_id IS NOT NULL AND l_uur_summa IS NOT NULL AND l_uur_summa > 0
                    THEN

                        -- формируем строку
                        l_uur_json = jsonb_build_object('id', 0,
                                                        'summa', COALESCE(l_uur_summa, 0),
                                                        'deebet', ltrim(rtrim(v_smk.konto)),
                                                        'lisa_d', COALESCE(v_smk.tp, '800401'),
                                                        'kreedit', '10300029',
                                                        'lisa_k', COALESCE(v_smk1.tp, '800699'),
                                                        'tunnus', COALESCE(v_smk1.tunnus, v_smk1.n_tunnus),
                                                        'proj', COALESCE(v_smk1.proj, ''),
                                                        'kood1', COALESCE(v_smk1.kood1, v_smk1.n_tegev),
                                                        'kood2', COALESCE(v_smk1.kood2, v_smk1.n_allikas),
                                                        'kood5', '3233'
                            );

                        -- уменьшаем сумму строки платежа на сумму аренды
                        v_smk1.summa = v_smk1.summa - l_uur_summa;

                    END IF;

                END IF;

            END IF;


            IF NOT empty(v_smk1.kood2)
            THEN
                lcAllikas = v_smk1.kood2;
            END IF;

            -- параметры для табличной части

            SELECT 0                                         AS id,
                   coalesce(v_smk1.summa, 0)                 AS summa,
                   coalesce(v_smk1.valuuta, 'EUR')           AS valuuta,
                   coalesce(v_smk1.kuurs, 1)                 AS kuurs,
                   ltrim(rtrim(v_smk.konto))                 AS deebet,
                   coalesce(v_smk.tp, '800401')              AS lisa_d,
                   ltrim(rtrim(v_smk1.konto))                AS kreedit,
                   coalesce(v_smk1.tp, '800599')             AS lisa_k,
                   coalesce(v_smk1.tunnus, v_smk1.n_tunnus)  AS tunnus,
                   coalesce(v_smk1.proj, '')                 AS proj,
                   coalesce(v_smk1.kood1, v_smk1.n_tegev)    AS kood1,
                   coalesce(v_smk1.kood2, v_smk1.n_allikas)  AS kood2,
                   ''                                        AS kood3,
                   ''                                        AS kood4,
                   coalesce(v_smk1.kood5, v_smk1.n_artikkel) AS kood5
            INTO v_journal1;

            -- готовим параметры
            l_json_details = l_json_details || to_jsonb(v_journal1);

            -- сумма аренды, должны быть меньше или равной сумме платежа
            IF (coalesce(l_uur_summa, 0) > 0)
            THEN
                -- есть корректирующая проводку строка аренды
                l_json_details = coalesce(l_json_details, '[]'::JSONB)::JSONB || l_uur_json;
            END IF;

            SELECT coalesce(v_smk1.journalid, 0) AS id,
                   'JOURNAL'                     AS doc_type_id,
                   v_smk.kpv                     AS kpv,
                   lcSelg                        AS selg,
                   v_smk.muud                    AS muud,
                   l_dok                         AS dok,
                   l_asutus_id                   AS asutusid,
                   l_json_details                AS gridData
            INTO v_journal;
            -- создаем параметры
            l_json = jsonb_build_object('id', coalesce(v_smk1.journalid, 0), 'data', to_jsonb(v_journal));

            -- подготавливаем параметры для создания проводки

            result = 0;
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

            -- параллельная проводка для нач. сальдо
            IF v_smk.selg = 'Oppetasu algsaldo 2023' AND result IS NOT NULL AND result > 0
            THEN
                v_journal.asutusid = (SELECT id FROM libs.asutus WHERE regkood = '88888888880' AND staatus < 3 LIMIT 1);
                v_journal.id = 0;
                v_journal1.deebet = '203900';
                v_journal1.kreedit = '888888';
                l_json_details = to_jsonb(v_journal1);


                SELECT 0                                                                                  AS id,
                       'JOURNAL'                                                                          AS doc_type_id,
                       v_smk.kpv                                                                          AS kpv,
                       lcSelg                                                                             AS selg,
                       v_smk.muud                                                                         AS muud,
                       l_dok                                                                              AS dok,
                       (SELECT id FROM libs.asutus WHERE regkood = '88888888880' AND staatus < 3 LIMIT 1) AS asutusid,
                       l_json_details                                                                     AS gridData
                INTO v_journal;

                -- создаем параметры
                l_json = jsonb_build_object('id', 0, 'data', to_jsonb(v_journal));

                l_parallel_doc = docs.sp_salvesta_journal(l_json :: JSON, userId, v_smk.rekvId);

                IF l_parallel_doc IS NOT NULL AND l_parallel_doc > 0
                THEN

                    -- lausend
                    SELECT docs_ids
                    INTO a_docs_ids
                    FROM docs.doc
                    WHERE id = l_parallel_doc;

                    -- add new id into docs. ref. array
                    a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_smk.parentId)));

                    UPDATE docs.doc
                    SET docs_ids = a_docs_ids
                    WHERE id = l_parallel_doc;
                END IF;


            END IF;


        END LOOP;
    RAISE NOTICE 'result %',result;
    RETURN;
END ;
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
docs.gen_lausend_smk(4631051,5396)


*/


