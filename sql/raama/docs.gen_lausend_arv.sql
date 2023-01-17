DROP FUNCTION IF EXISTS docs.gen_lausend_arv(INTEGER);

DROP FUNCTION IF EXISTS docs.gen_lausend_arv(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS docs.gen_lausend_arv_(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.gen_lausend_arv(IN tnId INTEGER, IN userId INTEGER, OUT error_code INTEGER,
                                                OUT result INTEGER, OUT error_message TEXT)
AS
$BODY$
DECLARE
    lcDbKonto      VARCHAR(20);
    lcKrKonto      VARCHAR(20);
    lcDbTp         VARCHAR(20);
    lcKrTp         VARCHAR(20);
    lcKood5        VARCHAR(20);
    v_arv          RECORD;
    v_dokprop      RECORD;
    v_arv1         RECORD;
    lcAllikas      VARCHAR(20);
    lcSelg         TEXT;
    v_selg         RECORD;
    l_json         TEXT;
    l_json_details JSONB          = '[]';
    l_row_count    INTEGER        = 0;
    new_history    JSONB;
    userName       TEXT;
    a_docs_ids     INTEGER[];
    rows_fetched   INTEGER        = 0;
    v_journal      RECORD;
    l_allika_summa NUMERIC(12, 2) = 0;
    kas_alg_saldo  BOOLEAN        = FALSE;
BEGIN

    -- select dok data
    SELECT d.docs_ids,
           a.*,
           CASE WHEN empty(coalesce(asutus.tp, '')) THEN '800599' ELSE asutus.tp END AS asutus_tp,
           a.properties ->> 'tyyp'                                                   AS tyyp,
           coalesce((a.properties ->> 'ettemaksu_period')::INTEGER, 0)               AS kas_tulu_arve
    INTO v_arv
    FROM docs.arv a
             INNER JOIN docs.doc d ON d.id = a.parentId
             INNER JOIN libs.asutus asutus ON asutus.id = a.asutusid
    WHERE d.id = tnId;

    GET DIAGNOSTICS rows_fetched = ROW_COUNT;

    IF v_arv IS NULL
    THEN
        RAISE NOTICE 'rows_fetched = 0';
        error_code = 4; -- No documents found
        error_message = 'No documents found';
        result = 0;
        RETURN;
    END IF;

    IF v_arv.doklausid = 0
    THEN
        RAISE NOTICE 'v_arv.doklausid = 0';
        error_code = 1; -- Konteerimine pole vajalik
        error_message = 'Konteerimine pole vajalik';
        result = 0;
        RETURN;
    END IF;

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = v_arv.rekvId
      AND u.id = userId;
    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', userId;
        error_message = 'User not found';
        error_code = 3;
        RETURN;
    END IF;

    -- проверка на нач. сальдо род. платы
    IF v_arv.muud = 'Oppetasu algsaldo 2023'
    THEN
        kas_alg_saldo = TRUE;
    END IF;


    IF result IS NULL
    THEN

        IF v_arv.rekvid > 1
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
        WHERE dokprop.id = v_arv.doklausid
        LIMIT 1;

--        v_dokprop.kbmkonto = CASE WHEN v_dokprop.kbmkonto IS NULL OR v_dokprop.kbmkonto = '' THEN v_dokprop.konto END;

        IF NOT Found OR v_dokprop.registr = 0
        THEN

            error_code = 1; -- Konteerimine pole vajalik
            result = 0;
            error_message = 'Konteerimine pole vajalik';

        END IF;
    END IF;

    IF result IS NULL
    THEN
        lcDbKonto = '103000';
        lcDbTp = CASE
                     WHEN left(lcDbKonto, 6) IN ('601000', '103701', '203010', '203000') THEN '014001'
                     ELSE coalesce(v_arv.asutus_tp, '800599') END;

        lcDbTp = '800699';
        -- koostame selg rea
        lcSelg = trim(v_dokprop.selg);
        IF (SELECT count(id)
            FROM ou.rekv
            WHERE parentid = 119
               OR id = 119) > 0
        THEN -- Narva LV kultuuriosakond. @todo need flexible solution
            FOR v_selg IN
                SELECT DISTINCT nom.nimetus
                FROM docs.arv1 arv1
                         INNER JOIN libs.nomenklatuur nom ON arv1.nomid = nom.id
                WHERE arv1.parentid = v_arv.id
                  AND arv1.summa <> 0
                LOOP
                    lcSelg = lcSelg || ', ' || trim(v_selg.nimetus);
                END LOOP;

            IF kas_alg_saldo
            THEN
                lcSelg = 'Oppetasu algsaldo 2023';
            END IF;
        ELSE
            lcSelg = trim(v_dokprop.selg);
        END IF;

        v_arv.asutus_tp = coalesce(v_arv.asutus_tp, '800599');
        lcKrTp = coalesce(v_arv.asutus_tp, '800599');

        -- majandusamet
        -- подмена символов 16.01.2023 В. Бешекерскас
        IF (v_arv.rekvid = 130 OR v_arv.rekvid = 29) AND NOT empty(v_arv.lisa)
        THEN
            lcSelg = lcSelg || ', ' || ltrim(rtrim(regexp_replace(v_arv.lisa, '[/"]', '.','g')));
        END IF;

        SELECT v_arv.journalid,
               'JOURNAL'                         AS doc_type_id,
               v_arv.kpv,
               lcSelg                            AS selg,
               v_arv.muud,
               v_arv.Asutusid,
               'Arve nr. ' || v_arv.number::TEXT AS dok
        INTO v_journal;

        l_json = row_to_json(v_journal);

--    l_json_details = '';
        IF v_arv.tyyp IS NOT NULL AND v_arv.tyyp = 'HOOLDEKODU_ISIKU_OSA' AND v_arv.liik = 0
        THEN
            FOR v_arv1 IN
                SELECT arv1.tp,
                       arv1.kood1,
                       arv1.proj,
                       arv1.kood2,
                       arv1.kood3,
                       arv1.kood4,
                       arv1.kood5,
                       arv1.tunnus,
                       arv1.konto,
                       sum(arv1.summa)                                                 AS summa,
                       sum(arv1.kbmta)                                                 AS kbmta,
                       sum(coalesce((arv1.properties ->> 'allikas_85')::NUMERIC, 0))   AS allikas_85,
                       sum(coalesce((arv1.properties ->> 'allikas_vara')::NUMERIC, 0)) AS allikas_vara,
                       sum(coalesce((arv1.properties ->> 'allikas_muud')::NUMERIC, 0)) AS allikas_muud,
                       sum(coalesce((arv1.properties ->> 'umardamine')::NUMERIC, 0))   AS umardamine,
                       'EUR' :: VARCHAR                                                AS valuuta,
                       1 :: NUMERIC                                                    AS kuurs
                FROM docs.arv1 arv1
                WHERE arv1.summa <> 0
                  AND arv1.parentid = v_arv.id
                GROUP BY arv1.tp
                        ,
                         arv1.kood1
                        ,
                         arv1.kood2
                        ,
                         arv1.kood3
                        ,
                         arv1.kood4
                        ,
                         arv1.kood5
                        ,
                         arv1.tunnus
                        ,
                         arv1.proj
                        ,
                         arv1.konto
                LOOP

                    IF NOT empty(v_arv1.tp)
                    THEN
                        v_arv.asutus_tp := v_arv1.tp;
                    END IF;

                    IF NOT empty(v_arv1.kood2)
                    THEN
                        lcAllikas = v_arv1.kood2;
                    END IF;

                    lcKood5 = v_arv1.kood5;
                    lcDbKonto = '10300002';
                    lcKrKonto = v_arv1.konto;
                    v_arv1.kood5 = '3224';
                    v_arv1.kood2 = '80';
                    v_arv1.kood1 = '10200';

                    SELECT 0                               AS id,
                           v_arv1.summa                    AS summa,
                           coalesce(v_arv1.valuuta, 'EUR') AS valuuta,
                           coalesce(v_arv1.kuurs, 1)       AS kuurs,
                           lcDbKonto                       AS deebet,
                           lcKrKonto                       AS kreedit,
                           '800699'                        AS lisa_d,
                           '800699'                        AS lisa_k,
                           coalesce(v_arv1.tunnus, '')     AS tunnus,
                           coalesce(v_arv1.proj, '')       AS proj,
                           coalesce(v_arv1.kood1, '')      AS kood1,
                           coalesce(v_arv1.kood2, '')      AS kood2,
                           coalesce(v_arv1.kood3, '')      AS kood3,
                           coalesce(v_arv1.kood4, '')      AS kood4,
                           coalesce(v_arv1.kood5, '')      AS kood5
                    INTO v_journal;

                    l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_journal);

                    -- доп. строка для модуля дома попечения
                    IF v_arv1.allikas_85::NUMERIC <> 0 AND
                       v_arv1.umardamine = 0
                    THEN
                        -- если деньги по источнику 85
                        l_allika_summa = v_arv1.allikas_85;

                        SELECT 0                               AS id,
                               l_allika_summa                  AS summa,
                               coalesce(v_arv1.valuuta, 'EUR') AS valuuta,
                               coalesce(v_arv1.kuurs, 1)       AS kuurs,
                               '20363001'                      AS deebet,
                               '10300002'                      AS kreedit,
                               '800699'                        AS lisa_d,
                               '800699'                        AS lisa_k,
                               coalesce(v_arv1.tunnus, '')     AS tunnus,
                               coalesce(v_arv1.proj, '')       AS proj,
                               coalesce(v_arv1.kood1, '')      AS kood1,
                               coalesce(v_arv1.kood2, '')      AS kood2,
                               coalesce(v_arv1.kood3, '')      AS kood3,
                               coalesce(v_arv1.kood4, '')      AS kood4,
                               coalesce(v_arv1.kood5, '')      AS kood5
                        INTO v_journal;
                        l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_journal);

                    END IF;
                    IF v_arv1.allikas_vara <> 0 AND
                       v_arv1.umardamine = 0
                    THEN
                        -- если деньги по источнику vara
                        l_allika_summa = v_arv1.allikas_vara;

                        SELECT 0                               AS id,
                               l_allika_summa                  AS summa,
                               coalesce(v_arv1.valuuta, 'EUR') AS valuuta,
                               coalesce(v_arv1.kuurs, 1)       AS kuurs,
                               '20363004'                      AS deebet,
                               '10300002'                      AS kreedit,
                               '800699'                        AS lisa_d,
                               '800699'                        AS lisa_k,
                               coalesce(v_arv1.tunnus, '')     AS tunnus,
                               coalesce(v_arv1.proj, '')       AS proj,
                               coalesce(v_arv1.kood1, '')      AS kood1,
                               coalesce(v_arv1.kood2, '')      AS kood2,
                               coalesce(v_arv1.kood3, '')      AS kood3,
                               coalesce(v_arv1.kood4, '')      AS kood4,
                               coalesce(v_arv1.kood5, '')      AS kood5
                        INTO v_journal;
                        l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_journal);

                    END IF;
                    IF v_arv1.allikas_vara <> 0 AND
                       v_arv1.umardamine::NUMERIC = 0
                    THEN
                        -- если деньги по источнику muud
                        l_allika_summa = v_arv1.allikas_muud;

                        SELECT 0                               AS id,
                               l_allika_summa                  AS summa,
                               coalesce(v_arv1.valuuta, 'EUR') AS valuuta,
                               coalesce(v_arv1.kuurs, 1)       AS kuurs,
                               '20363005'                      AS deebet,
                               '10300002'                      AS kreedit,
                               '800699'                        AS lisa_d,
                               '800699'                        AS lisa_k,
                               coalesce(v_arv1.tunnus, '')     AS tunnus,
                               coalesce(v_arv1.proj, '')       AS proj,
                               coalesce(v_arv1.kood1, '')      AS kood1,
                               coalesce(v_arv1.kood2, '')      AS kood2,
                               coalesce(v_arv1.kood3, '')      AS kood3,
                               coalesce(v_arv1.kood4, '')      AS kood4,
                               coalesce(v_arv1.kood5, '')      AS kood5
                        INTO v_journal;
                        l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_journal);

                    END IF;
                    l_row_count = l_row_count + 1;

                END LOOP;
        ELSE
            -- прочие счета
            FOR v_arv1 IN
                SELECT arv1.*,
                       'EUR' :: VARCHAR AS valuuta,
                       1 :: NUMERIC     AS kuurs
                FROM docs.arv1 arv1
                WHERE arv1.summa <> 0
                  AND arv1.parentid = v_arv.id
                LOOP

                    IF NOT empty(v_arv1.tp)
                    THEN
                        v_arv.asutus_tp := v_arv1.tp;
                    END IF;

                    IF NOT empty(v_arv1.kood2)
                    THEN
                        lcAllikas = v_arv1.kood2;
                    END IF;

                    lcKood5 = v_arv1.kood5;

                    IF v_arv.liik = 0
                    THEN
                        -- ettemaksu arve

                        IF (v_arv.tyyp IS NOT NULL AND v_arv.tyyp = 'ETTEMAKS')
                        THEN
                            -- 103000	203900
                            lcDbKonto = '103000';
                            lcKrKonto = '203900';
/*                        ELSIF (v_arv.tyyp IS NOT NULL AND v_arv.tyyp = 'HOOLDEKODU_ISIKU_OSA')
                        THEN
                            lcDbKonto = '10300002';
                            lcKrKonto = v_arv1.konto;
                            v_arv1.kood5 = '3224';
                            v_arv1.kood2 = '80';
                            v_arv1.kood1 = '10200';
*/
                        ELSIF (v_arv.tyyp IS NOT NULL AND v_arv.tyyp = 'HOOLDEKODU_SUGULUANE_OSA')
                        THEN
                            lcDbKonto = '10300020';
                            lcKrKonto = v_arv1.konto;
                            v_arv1.kood5 = '3224';
                            v_arv1.kood2 = '80';
                            v_arv1.kood1 = '10200';
                        ELSIF NOT empty(v_arv.kas_tulu_arve)
                        THEN
                            -- 203900	32ХХХХ
                            lcDbKonto = '203900';
                            lcKrKonto = v_arv1.konto;
                        ELSE
                            lcDbKonto = coalesce(v_dokprop.konto, '103000');
                            lcKrKonto = v_arv1.konto;
                        END IF;

                        SELECT 0                                   AS id,
                               CASE
                                   WHEN v_arv1.kbmta = 0 AND v_arv1.hind <> 0
                                       THEN v_arv1.hind * v_arv1.kogus
                                   WHEN v_arv1.kbmta = 0 AND v_arv1.hind = 0
                                       THEN v_arv1.summa - v_arv1.kbm
                                   WHEN v_arv1.kbm = 0 AND v_arv1.kbmta <> v_arv1.summa THEN
                                       -- коррекция округления в род. плате
                                       v_arv1.summa
                                   ELSE v_arv1.kbmta END           AS summa,
                               coalesce(v_arv1.valuuta, 'EUR')     AS valuuta,
                               coalesce(v_arv1.kuurs, 1)           AS kuurs,
                               lcDbKonto                           AS deebet,
                               lcKrKonto                           AS kreedit,
                               coalesce(lcDbTp, '800599')          AS lisa_d,
                               coalesce(v_arv.asutus_tp, '800599') AS lisa_k,
                               coalesce(v_arv1.tunnus, '')         AS tunnus,
                               coalesce(v_arv1.proj, '')           AS proj,
                               coalesce(v_arv1.kood1, '')          AS kood1,
                               coalesce(v_arv1.kood2, '')          AS kood2,
                               coalesce(v_arv1.kood3, '')          AS kood3,
                               coalesce(v_arv1.kood4, '')          AS kood4,
                               coalesce(v_arv1.kood5, '')          AS kood5
                        INTO v_journal;

                        l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_journal);

                        IF v_arv1.kbm <> 0
                        THEN

                            IF left(trim(v_arv1.konto), 6) = '103701'
                            THEN
                                v_arv.asutus_tp = '014001';
                            END IF;

                            lcDbKonto = coalesce(v_dokprop.konto, '601000');

                            SELECT 0                                                AS id,
                                   coalesce(v_arv1.kbm, 0)                          AS summa,
                                   coalesce(v_arv1.valuuta, 'EUR')                  AS valuuta,
                                   coalesce(v_arv1.kuurs, 1)                        AS kuurs,
                                   coalesce(v_dokprop.konto, '601000')              AS deebet,
                                   CASE
                                       WHEN lcDbKonto = '601000' THEN '014001'
                                       ELSE coalesce(v_arv.asutus_tp, '800599') END AS lisa_d,
                                   coalesce(v_dokprop.kbmkonto, '203010')           AS kreedit,
                                   '014001'                                         AS lisa_k,
                                   coalesce(v_arv1.tunnus, '')                      AS tunnus,
                                   coalesce(v_arv1.proj, '')                        AS proj,
                                   coalesce(v_arv1.kood1, '')                       AS kood1,
                                   coalesce(v_arv1.kood2, '')                       AS kood2,
                                   coalesce(v_arv1.kood3, '')                       AS kood3,
                                   coalesce(v_arv1.kood4, '')                       AS kood4,
                                   coalesce(v_arv1.kood5, '')                       AS kood5
                            INTO v_journal;

                            l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_journal);


                        END IF;

                    ELSE
                        -- kreedit (kulud) arve

                        IF v_arv1.konto = '601000' OR v_arv1.konto = '203000' OR
                           left(ltrim(rtrim(v_arv1.konto)), 6) = '103701'
                        THEN
                            v_arv.asutus_tp := '014001';
                        END IF;
                        SELECT 0                                   AS id,
                               CASE
                                   WHEN v_arv1.kbmta = 0 AND v_arv1.hind <> 0
                                       THEN v_arv1.hind * v_arv1.kogus
                                   WHEN v_arv1.kbmta = 0 AND v_arv1.hind = 0
                                       THEN v_arv1.summa - v_arv1.kbm
                                   ELSE v_arv1.kbmta END           AS summa,
                               coalesce(v_arv1.valuuta, 'EUR')     AS valuuta,
                               coalesce(v_arv1.kuurs, 1)           AS kuurs,
                               coalesce(v_arv1.konto, '103000')    AS deebet,
                               coalesce(v_arv.asutus_tp, '014001') AS lisa_d,
                               coalesce(v_dokprop.konto, '203010') AS kreedit,
                               coalesce(lcKrTp, '014001')          AS lisa_k,
                               coalesce(v_arv1.tunnus, '')         AS tunnus,
                               coalesce(v_arv1.proj, '')           AS proj,
                               coalesce(v_arv1.kood1, '')          AS kood1,
                               coalesce(v_arv1.kood2, '')          AS kood2,
                               coalesce(v_arv1.kood3, '')          AS kood3,
                               coalesce(v_arv1.kood4, '')          AS kood4,
                               coalesce(v_arv1.kood5, '')          AS kood5
                        INTO v_journal;

                        l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_journal);

                        IF v_arv1.kbm <> 0
                        THEN

                            IF left(trim(v_arv1.konto), 6) = '103701'
                            THEN
                                v_arv.asutus_tp = '014001';
                            END IF;

                            SELECT 0                                      AS id,
                                   coalesce(v_arv1.kbm, 0)                AS summa,
                                   coalesce(v_arv1.valuuta, 'EUR')        AS valuuta,
                                   coalesce(v_arv1.kuurs, 1)              AS kuurs,
                                   coalesce(v_dokprop.kbmkonto, '601000') AS deebet,
                                   '014001'                               AS lisa_d,
                                   coalesce(v_dokprop.konto, '203010')    AS kreedit,
                                   coalesce(lcKrTp, '014001')             AS lisa_k,
                                   coalesce(v_arv1.tunnus, '')            AS tunnus,
                                   coalesce(v_arv1.proj, '')              AS proj,
                                   coalesce(v_arv1.kood1, '')             AS kood1,
                                   coalesce(v_arv1.kood2, '')             AS kood2,
                                   coalesce(v_arv1.kood3, '')             AS kood3,
                                   coalesce(v_arv1.kood4, '')             AS kood4,
                                   coalesce(v_arv1.kood5, '')             AS kood5
                            INTO v_journal;

                            l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_journal);

                        END IF;
                    END IF;

                    l_row_count = l_row_count + 1;
                END LOOP;
        END IF;

        l_json = ('{"id": ' || coalesce(v_arv.journalid, 0)::TEXT || ',"data":' ||
                  trim(TRAILING FROM l_json, '}') :: TEXT || ',"gridData":' || l_json_details::TEXT ||
                  '}}');

        /* salvestan lausend */

        IF l_row_count > 0
        THEN
            RAISE NOTICE 'l_json %',l_json;
            result = docs.sp_salvesta_journal(l_json :: JSON, userId, v_arv.rekvId);
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
    END IF;


END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.gen_lausend_arv(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.gen_lausend_arv(INTEGER, INTEGER) TO dbpeakasutaja;

/*


SELECT error_code, result, error_message from docs.gen_lausend_arv(2486725, 5175)

select parentid, * from docs.arv where number = 'HKOP264'

select array(select distinct unnest(array[1,1,2]))


select id, docs_ids from docs.doc where id = 75

select * from docs.arv where parentid = 81

select * from docs.arv where parentid = 75


update docs.arv set doklausid = 1

select * from libs.library where library = 'DOK'

select * from docs.arv

*/
