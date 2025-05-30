﻿DROP FUNCTION IF EXISTS docs.gen_lausend_arv(INTEGER);

DROP FUNCTION IF EXISTS docs.gen_lausend_arv(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS docs.gen_lausend_arv(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.gen_lausend_arv(IN tnId INTEGER, IN user_Id INTEGER, OUT error_code INTEGER,
                                                OUT result INTEGER, OUT error_message TEXT)
AS
$BODY$
DECLARE
    lcDbKonto              VARCHAR(20);
    lcKrKonto              VARCHAR(20);
    lcDbTp                 VARCHAR(20);
    lcKrTp                 VARCHAR(20);
    lcKood5                VARCHAR(20);
    v_arv                  RECORD;
    v_dokprop              RECORD;
    v_arv1                 RECORD;
    lcAllikas              VARCHAR(20);
    lcSelg                 TEXT;
    v_selg                 RECORD;
    l_json                 TEXT;
    l_json_details         JSONB          = '[]';
    l_json_tasu            TEXT;
    l_json_asendus_details JSONB          = '[]';
    l_json_asendus_header  JSONB          = '{}';
    l_json_asendus         JSONB= '[]'::JSONB;
    l_json_details_tasu    JSONB          = '[]';
    l_row_count            INTEGER        = 0;
    new_history            JSONB;
    userName               TEXT;
    a_docs_ids             INTEGER[];
    rows_fetched           INTEGER        = 0;
    v_journal              RECORD;
    l_allika_summa         NUMERIC(12, 2) = 0;
    kas_alg_saldo          BOOLEAN        = FALSE;
    l_asutus_id            INTEGER;
    l_parrallel_id         INTEGER; -- ид параллельной проводки
    v_asendus_taabel       RECORD;
    l_asendus_user_id      INTEGER;
    l_vn                   text ; -- lapse VN
BEGIN

    -- select dok data
    SELECT
        d.docs_ids,
        a.*,
        CASE WHEN empty(coalesce(asutus.tp, '')) THEN '800599' ELSE asutus.tp END AS asutus_tp,
        a.properties ->> 'tyyp'                                                   AS tyyp,
        coalesce((a.properties ->> 'ettemaksu_period')::INTEGER, 0)               AS kas_tulu_arve,
        l.parentid                                                                AS laps_id,
        (a.properties ->> 'asendus_id')::INTEGER                                  AS asendus_id,
        coalesce((a.properties ->> 'umardamine')::numeric, 0)::numeric            as umardamine
    INTO v_arv
    FROM
        docs.arv                                a
            INNER JOIN      docs.doc            d ON d.id = a.parentId
            INNER JOIN      libs.asutus         asutus ON asutus.id = a.asutusid
            LEFT OUTER JOIN lapsed.liidestamine l ON l.docid = d.id
    WHERE
        d.id = tnId;

    GET DIAGNOSTICS rows_fetched = ROW_COUNT;

    IF v_arv IS NULL
    THEN
        error_code = 4; -- No documents found
        error_message = 'No documents found';
        result = 0;
        RETURN;
    END IF;

    IF v_arv.doklausid = 0
    THEN
        error_code = 1; -- Konteerimine pole vajalik
        error_message = 'Konteerimine pole vajalik';
        result = 0;
        RETURN;
    END IF;

    SELECT
        kasutaja
    INTO userName
    FROM
        ou.userid u
    WHERE
          u.rekvid = v_arv.rekvId
      AND u.id = user_Id;
    IF userName IS NULL
    THEN
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

        SELECT
            library.kood,
            dokprop.*,
            details.*
        INTO v_dokprop
        FROM
            libs.dokprop                        dokprop
                INNER JOIN libs.library         library ON library.id = dokprop.parentid
                ,
            jsonb_to_record(dokprop.details) AS details(konto TEXT, kbmkonto TEXT)
        WHERE
            dokprop.id = v_arv.doklausid
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
                     WHEN coalesce(v_arv.laps_id, 0) > 0 THEN
                         coalesce(v_arv.asutus_tp, '800699')
                     ELSE coalesce(v_arv.asutus_tp, '800599') END;


        -- koostame selg rea
        lcSelg = trim(v_dokprop.selg);
        IF (
               SELECT
                   count(id)
               FROM
                   ou.rekv
               WHERE
                    parentid = 119
                 OR id = 119
           ) > 0
        THEN -- Narva LV kultuuriosakond. @todo need flexible solution
            FOR v_selg IN
                SELECT DISTINCT
                    nom.nimetus
                FROM
                    docs.arv1                        arv1
                        INNER JOIN libs.nomenklatuur nom ON arv1.nomid = nom.id
                WHERE
                      arv1.parentid = v_arv.id
                  AND arv1.summa <> 0
                LOOP
                    lcSelg = lcSelg || ', ' || trim(v_selg.nimetus);
                END LOOP;

            IF kas_alg_saldo
            THEN
                lcSelg = 'Oppetasu algsaldo 2023';
                v_arv.kpv = '2023-01-01'::DATE;
            END IF;
        ELSE
            lcSelg = trim(v_dokprop.selg);
        END IF;

        v_arv.asutus_tp = coalesce(v_arv.asutus_tp, '800599');
        --lcKrTp = coalesce(v_arv.asutus_tp, '800599');

        lcKrTp = CASE
                     WHEN left(lcDbKonto, 6) IN ('601000', '103701', '203010', '203000') THEN '014001'
                     WHEN coalesce(v_arv.laps_id, 0) > 0 THEN
                         coalesce(v_arv.asutus_tp, '800699')
                     ELSE coalesce(v_arv.asutus_tp, '800599') END;

        -- род. плата
        IF v_arv.laps_id IS NOT NULL
        THEN
            -- поличим VN для ребенка
            l_vn = lapsed.get_viitenumber(v_arv.rekvid, v_arv.laps_id);

            -- удалим если есть замещающие проводки
            IF v_arv.asendus_id IS NOT NULL
            THEN
                PERFORM docs.sp_delete_journal(qry.userid, qry.id)
                FROM
                    (
                        SELECT
                            j.parentid AS id,
                            (
                                SELECT
                                    id
                                FROM
                                    ou.userid u
                                WHERE
                                      u.rekvid = j.rekvid
                                  AND kasutaja IN (
                                                      SELECT
                                                          kasutaja
                                                      FROM
                                                          ou.userid
                                                      WHERE
                                                          id = user_Id
                                                  )
                                  AND status < 3
                                LIMIT 1
                            )          AS userid
                        FROM
                            docs.journal j
                        WHERE
                              j.properties IS NOT NULL
                          AND (j.properties ->> 'asendus_id')::INTEGER IN (
                                                                              SELECT
                                                                                  (properties ->> 'asendus_id')::INTEGER
                                                                              FROM
                                                                                  docs.arv1 a1
                                                                              WHERE
                                                                                    a1.properties ->> 'asendus_id' IS NOT NULL
                                                                                AND a1.parentid = v_arv.id
                                                                          )
                    ) qry;

            END IF;

            -- новый балансовый субсчет для проводок по учебной плате вместо счета 103000 kalle 11.02.2023
            lcDbKonto = '10300029';

            -- меняем на ответственного ( Kalle 18/01/2023
            if v_arv.summa >= 0 then
                -- кредитовые счета не трогаем А.Варгунин 21.10.2024
                l_asutus_id = (
                                  SELECT
                                      asutusid
                                  FROM
                                      lapsed.vanem_arveldus      v
                                          INNER JOIN libs.asutus a ON a.id = v.asutusid
                                  WHERE
                                        v.parentid = v_arv.laps_id
                                    AND v.rekvid = v_arv.rekvid
                                  ORDER BY
                                      coalesce(v.arveldus, FALSE) DESC
                                    , v.id DESC
                                  LIMIT 1
                              );
            end if;

            IF l_asutus_id IS NULL
            THEN
                l_asutus_id = v_arv.asutusid;
            END IF;
            v_arv.asutusid = l_asutus_id;

            v_arv.asutus_tp = (
                                  SELECT
                                      tp
                                  FROM
                                      libs.asutus
                                  WHERE
                                      id = l_asutus_id
                              );
            IF v_arv.asutus_tp = '800698'
            THEN
                -- Kalle, FIE меняекм на частные лица
                v_arv.asutus_tp = '800699';
            END IF;

            lcKrTp = coalesce(v_arv.asutus_tp, '800699');
            lcDbTp = coalesce(v_arv.asutus_tp, '800699');


        END IF;

        -- majandusamet
        -- подмена символов 16.01.2023 В. Бешекерскас
        IF (v_arv.rekvid = 130 OR v_arv.rekvid = 29) AND NOT empty(v_arv.lisa)
        THEN
            lcSelg = lcSelg || ', ' || ltrim(rtrim(regexp_replace(v_arv.lisa, '[/"]', '.', 'g')));
        END IF;
        lcSelg = regexp_replace(lcSelg, '[/"]', '.', 'g');


        SELECT
            v_arv.journalid,
            'JOURNAL'                         AS doc_type_id,
            v_arv.kpv,
            lcSelg                            AS selg,
            v_arv.muud,
            v_arv.Asutusid,
            'Arve nr. ' || v_arv.number::TEXT AS dok,
            l_vn                              as vn
        INTO v_journal;

        l_json = row_to_json(v_journal);

        IF v_arv.tyyp IS NOT NULL AND v_arv.tyyp = 'HOOLDEKODU_ISIKU_OSA' AND v_arv.liik = 0
        THEN
            FOR v_arv1 IN
                SELECT
                    arv1.tp,
                    arv1.kood1,
                    arv1.proj,
                    arv1.kood2,
                    arv1.kood3,
                    arv1.kood4,
                    arv1.kood5,
                    arv1.tunnus,
                    arv1.objekt,
                    arv1.konto,
                    sum(arv1.summa)                                                      AS summa,
                    sum(arv1.kbmta)                                                      AS kbmta,
                    sum(coalesce((arv1.properties ->> 'allikas_85')::NUMERIC, 0))        AS allikas_85,
                    sum(coalesce((arv1.properties ->> 'allikas_vara')::NUMERIC, 0))      AS allikas_vara,
                    sum(coalesce((arv1.properties ->> 'allikas_muud')::NUMERIC, 0))      AS allikas_muud,
                    sum(coalesce((arv1.properties ->> 'allikas_taskuraha')::NUMERIC, 0)) AS allikas_taskuraha,
                    sum(coalesce((arv1.properties ->> 'umardamine')::NUMERIC, 0))        AS umardamine,
                    'EUR' :: VARCHAR                                                     AS valuuta,
                    1 :: NUMERIC                                                         AS kuurs
                FROM
                    docs.arv1 arv1
                WHERE
                      arv1.summa <> 0
                  AND arv1.parentid = v_arv.id
                GROUP BY
                    arv1.tp,
                    arv1.kood1,
                    arv1.kood2,
                    arv1.kood3,
                    arv1.kood4,
                    arv1.kood5,
                    arv1.tunnus,
                    arv1.objekt,
                    arv1.proj,
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

                    SELECT
                        0                               AS id,
                        v_arv1.summa                    AS summa,
                        coalesce(v_arv1.valuuta, 'EUR') AS valuuta,
                        coalesce(v_arv1.kuurs, 1)       AS kuurs,
                        lcDbKonto                       AS deebet,
                        lcKrKonto                       AS kreedit,
                        '800699'                        AS lisa_d,
                        '800699'                        AS lisa_k,
                        coalesce(v_arv1.tunnus, '')     AS tunnus,
                        coalesce(v_arv1.proj, '')       AS proj,
                        v_arv1.objekt                   AS objekt,
                        coalesce(v_arv1.kood1, '')      AS kood1,
                        coalesce(v_arv1.kood2, '')      AS kood2,
                        coalesce(v_arv1.kood3, '')      AS kood3,
                        coalesce(v_arv1.kood4, '')      AS kood4,
                        coalesce(v_arv1.kood5, '')      AS kood5
                    INTO v_journal;

                    IF coalesce(v_arv1.allikas_taskuraha, 0) = 0
                    THEN
                        -- исключим из проводки сумму карманных денег
                        l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_journal);
                    END IF;

                    -- доп. строка для модуля дома попечения, оплата
                    IF coalesce(v_arv1.allikas_85, 0)::NUMERIC <> 0
                    THEN
                        -- если деньги по источнику 85
                        l_allika_summa = v_arv1.allikas_85;

                        SELECT
                            0                               AS id,
                            l_allika_summa                  AS summa,
                            coalesce(v_arv1.valuuta, 'EUR') AS valuuta,
                            coalesce(v_arv1.kuurs, 1)       AS kuurs,
                            '20363001'                      AS deebet,
                            '10300002'                      AS kreedit,
                            '800699'                        AS lisa_d,
                            '800699'                        AS lisa_k,
                            coalesce(v_arv1.tunnus, '')     AS tunnus,
                            v_arv1.objekt                   AS objekt,
                            coalesce(v_arv1.proj, '')       AS proj,
                            coalesce(v_arv1.kood1, '')      AS kood1,
                            coalesce(v_arv1.kood2, '')      AS kood2,
                            coalesce(v_arv1.kood3, '')      AS kood3,
                            coalesce(v_arv1.kood4, '')      AS kood4,
                            coalesce(v_arv1.kood5, '')      AS kood5
                        INTO v_journal;
                        l_json_details_tasu = coalesce(l_json_details_tasu, '{}'::JSONB) || to_jsonb(v_journal);

                    END IF;
                    IF coalesce(v_arv1.allikas_vara, 0) <> 0
                    THEN
                        -- если деньги по источнику vara
                        l_allika_summa = v_arv1.allikas_vara;
                        -- первая часть
                        SELECT
                            0                               AS id,
                            l_allika_summa                  AS summa,
                            coalesce(v_arv1.valuuta, 'EUR') AS valuuta,
                            coalesce(v_arv1.kuurs, 1)       AS kuurs,
                            '20363004'                      AS deebet,
                            '999999'                        AS kreedit,
                            '800699'                        AS lisa_d,
                            '800699'                        AS lisa_k,
                            coalesce(v_arv1.tunnus, '')     AS tunnus,
                            v_arv1.objekt                   AS objekt,
                            coalesce(v_arv1.proj, '')       AS proj,
                            coalesce(v_arv1.kood1, '')      AS kood1,
                            coalesce(v_arv1.kood2, '')      AS kood2,
                            coalesce(v_arv1.kood3, '')      AS kood3,
                            coalesce(v_arv1.kood4, '')      AS kood4,
                            '2586'                          AS kood5
                        INTO v_journal;
                        l_json_details_tasu = coalesce(l_json_details_tasu, '{}'::JSONB) || to_jsonb(v_journal);

                        -- вторая часть
                        SELECT
                            0                               AS id,
                            l_allika_summa                  AS summa,
                            coalesce(v_arv1.valuuta, 'EUR') AS valuuta,
                            coalesce(v_arv1.kuurs, 1)       AS kuurs,
                            '999999'                        AS deebet,
                            '10300002'                      AS kreedit,
                            '800699'                        AS lisa_d,
                            '800699'                        AS lisa_k,
                            coalesce(v_arv1.tunnus, '')     AS tunnus,
                            v_arv1.objekt                   AS objekt,
                            coalesce(v_arv1.proj, '')       AS proj,
                            coalesce(v_arv1.kood1, '')      AS kood1,
                            coalesce(v_arv1.kood2, '')      AS kood2,
                            coalesce(v_arv1.kood3, '')      AS kood3,
                            coalesce(v_arv1.kood4, '')      AS kood4,
                            '3224'                          AS kood5
                        INTO v_journal;
                        l_json_details_tasu = coalesce(l_json_details_tasu, '{}'::JSONB) || to_jsonb(v_journal);


                    END IF;
                    IF coalesce(v_arv1.allikas_muud, 0) <> 0
                    THEN
                        -- если деньги по источнику muud
                        l_allika_summa = v_arv1.allikas_muud;
                        -- первая часть

                        SELECT
                            0                               AS id,
                            l_allika_summa                  AS summa,
                            coalesce(v_arv1.valuuta, 'EUR') AS valuuta,
                            coalesce(v_arv1.kuurs, 1)       AS kuurs,
                            '20363005'                      AS deebet,
                            '999999'                        AS kreedit,
                            '800699'                        AS lisa_d,
                            '800699'                        AS lisa_k,
                            coalesce(v_arv1.tunnus, '')     AS tunnus,
                            coalesce(v_arv1.proj, '')       AS proj,
                            v_arv1.objekt                   AS objekt,
                            coalesce(v_arv1.kood1, '')      AS kood1,
                            coalesce(v_arv1.kood2, '')      AS kood2,
                            coalesce(v_arv1.kood3, '')      AS kood3,
                            coalesce(v_arv1.kood4, '')      AS kood4,
                            2586                            AS kood5
                        INTO v_journal;
                        l_json_details_tasu = coalesce(l_json_details_tasu, '{}'::JSONB) || to_jsonb(v_journal);

                        -- вторая часть
                        SELECT
                            0                               AS id,
                            l_allika_summa                  AS summa,
                            coalesce(v_arv1.valuuta, 'EUR') AS valuuta,
                            coalesce(v_arv1.kuurs, 1)       AS kuurs,
                            '999999'                        AS deebet,
                            '10300002'                      AS kreedit,
                            '800699'                        AS lisa_d,
                            '800699'                        AS lisa_k,
                            coalesce(v_arv1.tunnus, '')     AS tunnus,
                            v_arv1.objekt                   AS objekt,
                            coalesce(v_arv1.proj, '')       AS proj,
                            coalesce(v_arv1.kood1, '')      AS kood1,
                            coalesce(v_arv1.kood2, '')      AS kood2,
                            coalesce(v_arv1.kood3, '')      AS kood3,
                            coalesce(v_arv1.kood4, '')      AS kood4,
                            '3224'                          AS kood5
                        INTO v_journal;
                        l_json_details_tasu = coalesce(l_json_details_tasu, '{}'::JSONB) || to_jsonb(v_journal);


                    END IF;
                    IF coalesce(v_arv1.allikas_taskuraha, 0) <> 0
                    THEN
                        -- если деньги по источнику taskuraha (kov)
                        l_allika_summa = v_arv1.allikas_taskuraha;
                        -- доп. строка

                        SELECT
                            0                               AS id,
                            l_allika_summa                  AS summa,
                            coalesce(v_arv1.valuuta, 'EUR') AS valuuta,
                            coalesce(v_arv1.kuurs, 1)       AS kuurs,
                            '20356001'                      AS deebet,
                            '10300002'                      AS kreedit,
                            '800699'                        AS lisa_d,
                            '800699'                        AS lisa_k,
                            v_arv1.tunnus                   AS tunnus,
                            v_arv1.objekt                   AS objekt,
                            coalesce(v_arv1.proj, '')       AS proj,
                            coalesce(v_arv1.kood1, '')      AS kood1,
                            coalesce(v_arv1.kood2, '')      AS kood2,
                            coalesce(v_arv1.kood3, '')      AS kood3,
                            coalesce(v_arv1.kood4, '')      AS kood4,
                            coalesce(v_arv1.kood5, '')      AS kood5
                        INTO v_journal;
                        l_json_details_tasu = coalesce(l_json_details_tasu, '{}'::JSONB) || to_jsonb(v_journal);

                    END IF;

                    l_row_count = l_row_count + 1;

                END LOOP;
        ELSE
            -- прочие счета
            FOR v_arv1 IN
                SELECT
                    arv1.*,
                    'EUR' :: VARCHAR                            AS valuuta,
                    1 :: NUMERIC                                AS kuurs,
                    (arv1.properties ->> 'asendus_id')::INTEGER AS asendus_id
                FROM
                    docs.arv1 arv1
                WHERE
                      arv1.summa <> 0
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
                        ELSIF (v_arv.tyyp IS NOT NULL AND
                               v_arv.tyyp IN ('HOOLDEKODU_SUGULUANE_OSA', 'HOOLDEKODU_SUGULUANE'))
                        THEN

                            lcDbKonto = '10300019';
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

                        SELECT
                            0                               AS id,
                            CASE
                                WHEN v_arv1.kbmta = 0 AND v_arv1.hind <> 0
                                    THEN v_arv1.hind * v_arv1.kogus
                                WHEN v_arv1.kbmta = 0 AND v_arv1.hind = 0
                                    THEN v_arv1.summa - v_arv1.kbm
                                WHEN v_arv1.kbm = 0 AND v_arv1.kbmta <> v_arv1.summa THEN
                                    -- коррекция округления в род. плате
                                    v_arv1.summa
                                ELSE v_arv1.kbmta END       AS summa,
                            coalesce(v_arv1.valuuta, 'EUR') AS valuuta,
                            coalesce(v_arv1.kuurs, 1)       AS kuurs,
                            lcDbKonto                       AS deebet,
                            lcKrKonto                       AS kreedit,
                            coalesce(lcDbTp, '800599')      AS lisa_d,
                            coalesce(lcKrTp, '800599')      AS lisa_k,
                            coalesce(v_arv1.tunnus, '')     AS tunnus,
                            v_arv1.objekt                   AS objekt,
                            coalesce(v_arv1.proj, '')       AS proj,
                            coalesce(v_arv1.kood1, '')      AS kood1,
                            coalesce(v_arv1.kood2, '')      AS kood2,
                            coalesce(v_arv1.kood3, '')      AS kood3,
                            coalesce(v_arv1.kood4, '')      AS kood4,
                            coalesce(v_arv1.kood5, '')      AS kood5
                        INTO v_journal;

                        -- нужно убрать TP код при 888888. Kalle
                        if v_journal.deebet = '888888' then
                            v_journal.lisa_d = '';
                        END IF;
                        if v_journal.kreedit = '888888' then
                            v_journal.lisa_k = '';
                        END IF;

                        l_json_details = coalesce(l_json_details, '[]'::JSONB) || to_jsonb(v_journal);


                        -- Доп. проводка для род.платы, если услуга была оказана в другом учреждении
                        IF v_arv1.properties ->> 'asendus_id' IS NOT NULL AND exists
                        (
                            SELECT
                                id
                            FROM
                                lapsed.asendus_taabel
                            WHERE
                                id = (v_arv1.properties ->> 'asendus_id')::INTEGER
                        )
                        THEN

                            -- табель (признак)
                            SELECT
                                l.kood AS tunnus,
                                at.rekvid
                            INTO v_asendus_taabel
                            FROM
                                lapsed.asendus_taabel            at
                                    INNER JOIN      ou.rekv      r ON r.id = at.rekvid
                                    LEFT OUTER JOIN libs.library l
                                                    ON l.rekvid = r.id AND l.kood = left(r.nimetus, 7) AND
                                                       l.library = 'TUNNUS' AND l.status < 3
                            WHERE
                                at.id = (v_arv1.properties ->> 'asendus_id')::INTEGER
                            ORDER BY l.id DESC
                            LIMIT 1;

                            -- Перевод дохода в другое учреждение
                            SELECT
                                0                                AS id,
                                -1 * (CASE
                                          WHEN v_arv1.kbmta = 0 AND v_arv1.hind <> 0
                                              THEN v_arv1.hind * v_arv1.kogus
                                          WHEN v_arv1.kbmta = 0 AND v_arv1.hind = 0
                                              THEN v_arv1.summa - v_arv1.kbm
                                          WHEN v_arv1.kbm = 0 AND v_arv1.kbmta <> v_arv1.summa THEN
                                              -- коррекция округления в род. плате
                                              v_arv1.summa
                                          ELSE v_arv1.kbmta END) AS summa,
                                coalesce(v_arv1.valuuta, 'EUR')  AS valuuta,
                                coalesce(v_arv1.kuurs, 1)        AS kuurs,
                                '20363005'                       AS deebet,
                                lcKrKonto                        AS kreedit,
                                coalesce(lcDbTp, '800699')       AS lisa_d,
                                coalesce(lcKrTp, '800699')       AS lisa_k,
                                coalesce(v_arv1.tunnus, '')      AS tunnus,
                                v_arv1.objekt                    AS objekt,
                                coalesce(v_arv1.proj, '')        AS proj,
                                coalesce(v_arv1.kood1, '')       AS kood1,
                                coalesce(v_arv1.kood2, '')       AS kood2,
                                coalesce(v_arv1.kood3, '')       AS kood3,
                                coalesce(v_arv1.kood4, '')       AS kood4,
                                coalesce(v_arv1.kood5, '')       AS kood5,
                                v_arv1.asendus_id,
                                v_asendus_taabel.tunnus          AS asendus_tunnus,
                                v_asendus_taabel.rekvid          AS asendus_rekvid
                            INTO v_journal;

                            l_json_details = coalesce(l_json_details, '[]'::JSONB) || to_jsonb(v_journal);
                            -- запомним эту часть проводки


                            l_json_asendus_header = l_json;
                            v_journal.tunnus = v_asendus_taabel.tunnus;
                            IF (v_arv1.tunnus = '3008')
                            THEN
                                -- если украинцы, то оставляем признак уцкраинцев
                                v_journal.tunnus = v_arv1.tunnus;
                            END IF;

                            -- поправим знак
                            v_journal.summa = -1 * v_journal.summa;

                            l_json_asendus_details =
                                    coalesce(l_json_asendus_details, '[]')::JSONB || to_jsonb(v_journal)::JSONB;

                            -- сохраним параметры для проводки
                            l_json_asendus = l_json_asendus ||
                                             jsonb_build_object('header', l_json_asendus_header, 'details',
                                                                l_json_asendus_details);

                        END IF;

                        IF v_arv1.kbm <> 0
                        THEN

                            IF left(trim(v_arv1.konto), 6) = '103701'
                            THEN
                                v_arv.asutus_tp = '014001';
                            END IF;

                            lcDbKonto = coalesce(v_dokprop.konto, '601000');

                            SELECT
                                0                                                AS id,
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
                                v_arv1.objekt                                    AS objekt,
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
                        SELECT
                            0                                   AS id,
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
                            v_arv1.objekt                       AS objekt,
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

                            SELECT
                                0                                      AS id,
                                coalesce(v_arv1.kbm, 0)                AS summa,
                                coalesce(v_arv1.valuuta, 'EUR')        AS valuuta,
                                coalesce(v_arv1.kuurs, 1)              AS kuurs,
                                coalesce(v_dokprop.kbmkonto, '601000') AS deebet,
                                '014001'                               AS lisa_d,
                                coalesce(v_dokprop.konto, '203010')    AS kreedit,
                                coalesce(lcKrTp, '014001')             AS lisa_k,
                                coalesce(v_arv1.tunnus, '')            AS tunnus,
                                v_arv1.objekt                          AS objekt,
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

        -- округление (с 2025)
        if v_arv.kpv >= '2025-01-01'::date and coalesce((
                                                            select
                                                                c.properties ->> 'round_arve' as round_arve
                                                            from
                                                                ou.config c
                                                            where
                                                                c.rekvid = v_arv.rekvid
                                                            limit 1
                                                        )::integer, 0)::integer > 0 and v_arv.umardamine <> 0 then
            -- формируем строку на сумму округления
            SELECT
                0                                                                  AS id,
                v_arv.umardamine                                                   AS summa,
                coalesce(v_arv1.valuuta, 'EUR')                                    AS valuuta,
                coalesce(v_arv1.kuurs, 1)                                          AS kuurs,
                case when empty(lcDbKonto) then v_dokprop.konto else lcDbKonto end AS deebet,
                '608090'                                                           AS kreedit,
                v_arv1.tp                                                          AS lisa_d,
                v_arv1.tp                                                          AS lisa_k,
                coalesce(v_arv1.tunnus, '')                                        AS tunnus,
                v_arv1.objekt                                                      AS objekt,
                coalesce(v_arv1.proj, '')                                          AS proj,
                coalesce(v_arv1.kood1, '')                                         AS kood1,
                'LE-P'                                                             AS kood2,
                coalesce(v_arv1.kood3, '')                                         AS kood3,
                coalesce(v_arv1.kood4, '')                                         AS kood4,
                '608'                                                              AS kood5,
                'Ümardamine'                                                       as muud
            INTO v_journal;
            l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_journal);

        end if;

        l_json = ('{"id": ' || coalesce(v_arv.journalid, 0)::TEXT || ',"data":' ||
                  trim(TRAILING FROM l_json, '}') :: TEXT || ',"gridData":' || l_json_details::TEXT ||
                  '}}');

        /* salvestan lausend */

        IF l_row_count > 0
        THEN
            result = docs.sp_salvesta_journal(l_json :: JSON, user_Id, v_arv.rekvId);
        ELSE
            error_message = 'Puudub kehtiv read';
            result = 0;
        END IF;

        IF result IS NOT NULL AND result > 0
        THEN
            -- род. плата, если есть импорт услуг из другого учреждения
            -- Доп. проводка для род.платы, если услуга была оказана в другом учреждении

            IF jsonb_array_length(l_json_asendus_details::JSONB) > 0 AND exists
            (
                SELECT
                    id
                FROM
                    lapsed.asendus_taabel
                WHERE
                    id IN
                    (
                        SELECT
                            (arv1.properties ->> 'asendus_id')::INTEGER AS asendus_id
                        FROM
                            docs.arv1 arv1
                        WHERE
                              arv1.summa <> 0
                          AND arv1.parentid = v_arv.id
                    )
            )
            THEN
                FOR i IN 1..jsonb_array_length(l_json_asendus_details::JSONB)
                    LOOP

                        lcSelg = 'Tulud üleviimine: ' ||
                                 ((l_json_asendus_details::JSONB -> (i - 1))::JSONB ->> 'asendus_tunnus');

                        SELECT
                            0                                                                             AS id,
                            'JOURNAL'                                                                     AS doc_type_id,
                            v_arv.kpv                                                                     AS kpv,
                            lcSelg                                                                        AS selg,
                            v_arv.muud                                                                    AS muud,
                            'Arve nr. ' || v_arv.number::TEXT                                             AS dok,
                            l_asutus_id                                                                   AS asutusid,
                            ((l_json_asendus_details::JSONB -> (i - 1))::JSONB ->> 'asendus_id')::INTEGER AS asendus_id,
                            l_vn                                                                          as vn,
                            '[]'::JSONB || (l_json_asendus_details::JSONB -> (i - 1))::JSONB              AS gridData
                        INTO v_journal;
                        -- создаем параметры
                        l_json = jsonb_build_object('id', 0, 'data', to_jsonb(v_journal));

                        -- пользователь другого учреждения
                        -- подготавливаем параметры для создания проводки
                        l_asendus_user_id = (
                                                SELECT
                                                    id
                                                FROM
                                                    ou.userid u
                                                WHERE
                                                      u.rekvid =
                                                      ((l_json_asendus_details::JSONB -> (i - 1))::JSONB ->> 'asendus_rekvid')::INTEGER
                                                  AND u.kasutaja IN (
                                                                        SELECT
                                                                            kasutaja
                                                                        FROM
                                                                            ou.userid
                                                                        WHERE
                                                                            id = user_Id
                                                                    )
                                                  AND status < 3
                                                LIMIT 1
                                            );


                        l_parrallel_id =
                                docs.sp_salvesta_journal(l_json :: JSON, l_asendus_user_id,
                                                         ((l_json_asendus_details::JSONB -> (i - 1))::JSONB ->> 'asendus_rekvid')::INTEGER);
                    END LOOP;


            END IF;

            -- оплата счета холдекоду
            IF (jsonb_array_length(l_json_details_tasu)) > 0 AND v_arv.tyyp = 'HOOLDEKODU_ISIKU_OSA' AND v_arv.liik = 0
            THEN
                IF exists
                (
                    SELECT
                        id
                    FROM
                        hooldekodu.hooleping
                    WHERE
                          isikid = v_arv.Asutusid
                      AND coalesce((properties ->> 'algoritm')::INTEGER, 0) = 1
                )
                THEN
                    -- меняем дату на дату поступления денег на последнее поступление (31.07.2023)

                    v_arv.kpv = (
                                    SELECT
                                        kpv
                                    FROM
                                        cur_journal
                                    WHERE
                                          asutusid = v_arv.Asutusid
--                          AND kpv >= v_arv.kpv
                                      AND deebet LIKE '100100%'
                                      AND kreedit LIKE '203630%'
                                    ORDER BY kpv DESC
                                    LIMIT 1
                                );
                END IF;

                SELECT
                    0,
                    'JOURNAL'          AS doc_type_id,
                    v_arv.kpv,
                    lcSelg             AS selg,
                    v_arv.muud,
                    v_arv.Asutusid,
                    v_arv.number::TEXT AS dok,
                    l_vn               as vn
                INTO v_journal;

                l_json_tasu = row_to_json(v_journal);


                l_json_tasu = ('{"id": 0,"data":' ||
                               trim(TRAILING FROM l_json_tasu, '}') :: TEXT || ',"gridData":' ||
                               l_json_details_tasu::TEXT ||
                               '}}');

                /* salvestan lausend */
                l_parrallel_id = docs.sp_salvesta_journal(l_json_tasu :: JSON, user_Id, v_arv.rekvId);

                IF coalesce(l_parrallel_id, 0) > 0
                THEN
                    -- оплата
                    PERFORM docs.sp_tasu_arv(
                            l_parrallel_id, v_arv.parentid, user_Id);
                END IF;

            END IF;


            /*
            ajalugu
            */

            SELECT
                row_to_json(row)
            INTO new_history
            FROM
                (
                    SELECT
                        now()    AS updated,
                        userName AS user
                ) row;

            -- will add docs into doc's pull
            -- arve


            UPDATE docs.doc
            SET
                docs_ids   = array(SELECT DISTINCT unnest(array_append(v_arv.docs_ids, result))),
                lastupdate = now(),
                history    = coalesce(history, '[]') :: JSONB || new_history
            WHERE
                id = v_arv.parentId;

            -- lausend
            SELECT
                docs_ids
            INTO a_docs_ids
            FROM
                docs.doc
            WHERE
                id = result;

            -- add new id into docs. ref. array
            a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_arv.parentId)));

            UPDATE docs.doc
            SET
                docs_ids = a_docs_ids
            WHERE
                id = result;

            -- direct ref to journal
            UPDATE docs.arv
            SET
                journalId = result
            WHERE
                id = v_arv.id;


            error_code = 0;
        ELSE
            error_code = 2;
        END IF;
    END IF;


END;
$BODY$ LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.gen_lausend_arv(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.gen_lausend_arv(INTEGER, INTEGER) TO dbpeakasutaja;

/*

SELECT  docs.gen_lausend_arv(6089799, 5407)

*/

