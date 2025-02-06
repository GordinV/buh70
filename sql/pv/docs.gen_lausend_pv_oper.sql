DROP FUNCTION IF EXISTS docs.gen_lausend_pv_oper(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.gen_lausend_pv_oper(IN tnid INTEGER,
                                                    IN user_id INTEGER,
                                                    OUT error_code INTEGER,
                                                    OUT result INTEGER,
                                                    OUT error_message TEXT)
AS
$BODY$
DECLARE
    v_journal      RECORD;
    v_journal1     RECORD;
    v_pv_oper      RECORD;
    v_dokprop      RECORD;
    lcAllikas      VARCHAR(20);
    lcSelg         TEXT;
    l_json         TEXT;
    l_json_details TEXT;
    new_history    JSONB;
    userName       TEXT;
    a_docs_ids     INTEGER[];
    a_pv_opers     TEXT[] = enum_range(NULL :: PV_OPERATSIOONID);
BEGIN

    SELECT
        d.docs_ids,
        d.rekvid,
        po.*,
        po.properties ->> 'korr_konto'                                                          AS po_korr_konto,
        po.properties ->> 'konto'                                                               AS po_konto,
        po.properties ->> 'kulum_konto'                                                         AS po_kulum_konto,
        a.tp,
        l.kood,
        coalesce((l.properties :: JSONB ->> 'parhind') :: NUMERIC(12, 2), 0) :: NUMERIC(12, 2)  AS parhind,
        coalesce((l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 2), 0) :: NUMERIC(12, 2) AS algkulum,
        coalesce((l.properties :: JSONB ->> 'konto'),
                 (grupp.properties :: JSONB ->> 'konto')) :: TEXT                               AS korrkonto,
        (l.properties :: JSONB ->> 'korr_konto')::TEXT                                          AS korr_konto,    -- ainult kui umberklassifitseerimine
        (l.properties :: JSONB ->> 'prev_konto')::TEXT                                          AS prev_konto,    -- ainult kui umberklassifitseerimine
        (l.properties :: JSONB ->> 'prev_pruppid')::INTEGER                                     AS prev_grupp_id, -- ainult kui umberklassifitseerimine
        (l.properties :: JSONB ->> 'konto')::TEXT                                               AS pv_kaart_konto,
        (l.properties :: JSONB ->> 'jaak') :: NUMERIC(12, 2)                                    AS jaak,
        aa.tp                                                                                   AS asutus_tp,
        (grupp.properties :: JSONB ->> 'kulum_konto') :: TEXT                                   AS kulum_konto,
        jaak.kulum                                                                              AS kulum_kokku
    INTO v_pv_oper
    FROM
        docs.pv_oper                                     po
            INNER JOIN      docs.doc                     d ON d.id = po.parentId
            INNER JOIN      libs.library                 l ON l.id = po.pv_kaart_id
            INNER JOIN      libs.library                 grupp
                            ON grupp.id = (l.properties :: JSONB ->> 'gruppid') :: INTEGER
            LEFT OUTER JOIN ou.aa                        aa ON aa.parentid = d.rekvid AND aa.arve = 'TP'
            LEFT OUTER JOIN libs.asutus                  a ON a.id = po.asutusid
            INNER JOIN      libs.get_pv_kaart_jaak(l.id) jaak ON jaak.id = l.id

    WHERE
        d.id = tnId;

    -- если карточка в инвестициях, то конто износа 154010
    IF v_pv_oper.pv_kaart_konto = '154000' AND v_pv_oper.konto <> '154000'
    THEN
        v_pv_oper.kulum_konto = '154010';
        IF empty(v_pv_oper.kood3)
        THEN
            v_pv_oper.kood3 = '11';
        END IF;

    END IF;


    --  Можно еще убрать код партнёра у группы 154? Veronika Nikitina, 31.01.24
    IF v_pv_oper.id IS NULL
    THEN
        error_code = 4; -- No documents found
        error_message = 'No documents found';
        result = 0;
        RETURN;
    END IF;

    IF v_pv_oper.doklausid = 0
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
          u.rekvid = v_pv_oper.rekvId
      AND u.id = user_id;

    IF userName IS NULL
    THEN
        error_message = 'User not found';
        error_code = 3;
        RETURN;
    END IF;

    IF v_pv_oper.rekvid > 1
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
        jsonb_to_record(dokprop.details) AS details(konto TEXT)
    WHERE
        dokprop.id = v_pv_oper.doklausid
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

    SELECT
        coalesce(v_pv_oper.journalid, 0) AS id,
        'JOURNAL'                        AS doc_type_id,
        v_pv_oper.kpv                    AS kpv,
        lcSelg                           AS selg,
        v_pv_oper.muud                   AS muud,
        'Inv.number ' || coalesce(v_pv_oper.kood, '')
                                         AS dok,
        v_pv_oper.asutusid               AS asutusid
    INTO v_journal;


    IF NOT empty(v_pv_oper.kood2)
    THEN
        lcAllikas = v_pv_oper.kood2;
    END IF;

    CASE
        WHEN v_pv_oper.liik = 1 -- array_position(a_pv_opers, 'paigutus')
            THEN SELECT
                     0                                AS id,
                     coalesce(v_pv_oper.summa, 0)     AS summa,
                     v_pv_oper.korrkonto              AS deebet,
                     coalesce(v_pv_oper.tp, '800599') AS lisa_d,
                     v_pv_oper.konto                  AS kreedit,
                     coalesce(v_pv_oper.tp, '800401') AS lisa_k,
                     coalesce(v_pv_oper.tunnus, '')   AS tunnus,
                     coalesce(v_pv_oper.proj, '')     AS proj,
                     coalesce(v_pv_oper.kood1, '')    AS kood1,
                     coalesce(v_pv_oper.kood2, '')    AS kood2,
                     coalesce(v_pv_oper.kood3, '')    AS kood3,
                     coalesce(v_pv_oper.kood4, '')    AS kood4,
                     coalesce(v_pv_oper.kood5, '')    AS kood5
                 INTO v_journal1;

                 IF v_journal1.kood3 not in ('01', '19')
                 THEN
                     v_journal1.lisa_d = '';
--                    v_journal1.lisa_k = '';
                 END IF;

                 l_json_details = row_to_json(v_journal1);

            -- RV16
                 if coalesce(v_pv_oper.kood3, '') in ('16', '29') and coalesce(v_pv_oper.algkulum, 0) > 0 then
                     -- добавим в проводку строку с износом
                     SELECT
                         0                                AS id,
                         coalesce(v_pv_oper.algkulum, 0)  AS summa,
                         v_pv_oper.konto                  as deebet,
                         coalesce(v_pv_oper.tp, '800599') AS lisa_d,
                         v_pv_oper.kulum_konto            AS kreedit,
                         ''                               AS lisa_k,
                         coalesce(v_pv_oper.tunnus, '')   AS tunnus,
                         coalesce(v_pv_oper.proj, '')     AS proj,
                         coalesce(v_pv_oper.kood1, '')    AS kood1,
                         coalesce(v_pv_oper.kood2, '')    AS kood2,
                         coalesce(v_pv_oper.kood3, '')    AS kood3,
                         coalesce(v_pv_oper.kood4, '')    AS kood4,
                         coalesce(v_pv_oper.kood5, '')    AS kood5
                     INTO v_journal1;

                     l_json_details = l_json_details::text || ',' || row_to_json(v_journal1)::text;

                 end if;

        WHEN v_pv_oper.liik = 2
            THEN
                SELECT
                     0                              AS id,
                     coalesce(v_pv_oper.summa, 0)   AS summa,
                     v_pv_oper.konto                AS deebet,
                     ''                             AS lisa_d,
                     v_pv_oper.kulum_konto          AS kreedit,
                     ''                             AS lisa_k,
                     coalesce(v_pv_oper.tunnus, '') AS tunnus,
                     coalesce(v_pv_oper.proj, '')   AS proj,
                     coalesce(v_pv_oper.kood1, '')  AS kood1,
                     coalesce(v_pv_oper.kood2, '')  AS kood2,
                     coalesce(v_pv_oper.kood3, '')  AS kood3,
                     coalesce(v_pv_oper.kood4, '')  AS kood4,
                     coalesce(v_pv_oper.kood5, '')  AS kood5
                 INTO v_journal1;
                -- частичное списание
                IF v_journal1.kood3 in ('12')
                THEN
                    -- В блоке parenduseKulum ja allahindlus запись D 155610 (кулум ОИ) К 888888   RV 12
                    v_journal1.kreedit  = '888888';
                    v_journal1.deebet = v_pv_oper.kulum_konto;
                    v_journal1.summa = -1 * v_journal1.summa;
                END IF;


                 l_json_details = row_to_json(v_journal1);

        WHEN v_pv_oper.liik = 3 -- array_position(a_pv_opers, 'parandus')
            THEN SELECT
                     0                                AS id,
                     coalesce(v_pv_oper.summa, 0)     AS summa,
                     v_pv_oper.korrkonto              AS deebet,
                     coalesce(v_pv_oper.tp, '800599') AS lisa_d,
                     v_pv_oper.konto                  AS kreedit,
                     coalesce(v_pv_oper.tp, '800599') AS lisa_k,
                     coalesce(v_pv_oper.tunnus, '')   AS tunnus,
                     coalesce(v_pv_oper.proj, '')     AS proj,
                     coalesce(v_pv_oper.kood1, '')    AS kood1,
                     coalesce(v_pv_oper.kood2, '')    AS kood2,
                     coalesce(v_pv_oper.kood3, '')    AS kood3,
                     coalesce(v_pv_oper.kood4, '')    AS kood4,
                     coalesce(v_pv_oper.kood5, '')    AS kood5
                 INTO v_journal1;

                 IF v_journal1.kood3 in ('23')
                 THEN
                     -- V. Nikitina В разделе парендусед. Увеличение стоимости основного имущества. Проводки с RV 23 должны быть без кода партнера.
                     v_journal1.lisa_d = '';
                     v_journal1.lisa_k = '';
                 END IF;

            -- частичное списание
                 IF v_journal1.kood3 in ('12')
                 THEN
                     -- В блоке parendused сделала запись. Проводка Д888888 К ОИ в данном случае 155600 RV 12.
                     v_journal1.deebet = '888888';
                     v_journal1.kreedit = v_pv_oper.korrkonto;
                     v_journal1.summa = -1 * v_journal1.summa;
                     v_journal1.kood5 = '155';
                 END IF;

                 l_json_details = row_to_json(v_journal1);


        WHEN v_pv_oper.liik = 4 -- array_position(a_pv_opers, 'mahakandmine')
            THEN SELECT
                     0                                AS id,
                     coalesce(v_pv_oper.summa, 0)     AS summa,
                     v_pv_oper.konto                  AS deebet,
                     coalesce(v_pv_oper.tp, '800599') AS lisa_d,
                     v_pv_oper.korrkonto              AS kreedit,
                     ''                               AS lisa_k,
                     coalesce(v_pv_oper.tunnus, '')   AS tunnus,
                     coalesce(v_pv_oper.proj, '')     AS proj,
                     coalesce(v_pv_oper.kood1, '')    AS kood1,
                     coalesce(v_pv_oper.kood2, '')    AS kood2,
                     coalesce(v_pv_oper.kood3, '')    AS kood3,
                     coalesce(v_pv_oper.kood4, '')    AS kood4,
                     coalesce(v_pv_oper.kood5, '')    AS kood5
                 INTO v_journal1;
                 l_json_details = row_to_json(v_journal1);

                 IF ltrim(rtrim(coalesce(v_pv_oper.kood3, ''))) in ('02', '24') and
                    coalesce(v_pv_oper.kulum_kokku, 0) > 0
                 THEN
                     -- продажа
                     -- D154010 K381010 TP kood TA04900 RV02
                     SELECT
                         0                                  AS id,
                         coalesce(v_pv_oper.kulum_kokku, 0) AS summa,
                         v_pv_oper.kulum_konto              AS deebet,
                         ''                                 AS lisa_d,
                         v_pv_oper.konto                    AS kreedit,
                         coalesce(v_pv_oper.tp, '800599')   AS lisa_k,
                         coalesce(v_pv_oper.tunnus, '')     AS tunnus,
                         coalesce(v_pv_oper.proj, '')       AS proj,
                         coalesce(v_pv_oper.kood1, '')      AS kood1,
                         coalesce(v_pv_oper.kood2, '')      AS kood2,
                         coalesce(v_pv_oper.kood3, '')      AS kood3,
                         coalesce(v_pv_oper.kood4, '')      AS kood4,
                         coalesce(v_pv_oper.kood5, '')      AS kood5
                     INTO v_journal1;
                     l_json_details = l_json_details || ',' || row_to_json(v_journal1);

                 END IF;

                 IF ltrim(rtrim(coalesce(v_pv_oper.kood3, ''))) = '15'
                 THEN
                     -- передача
                     --Запись следующая:
                     --    D710010 TP18510130               K155109                       RV15
                     --    D155119                                  K710010 TP18510130   RV15    Veronika Nikitina, 21.02.2024

                     v_journal1.deebet = '710010';
                     v_journal1.lisa_d = v_pv_oper.tp;
                     v_journal1.kreedit = v_pv_oper.korrkonto;
                     v_journal1.lisa_k = '';
                     l_json_details = row_to_json(v_journal1);

                     -- 2 строка

                     SELECT
                         0                                  AS id,
                         coalesce(v_pv_oper.kulum_kokku, 0) AS summa,
                         v_pv_oper.kulum_konto              AS deebet,
                         ''                                 AS lisa_d,
                         '710010'                           AS kreedit,
                         coalesce(v_pv_oper.tp, '800599')   AS lisa_k,
                         coalesce(v_pv_oper.tunnus, '')     AS tunnus,
                         coalesce(v_pv_oper.proj, '')       AS proj,
                         coalesce(v_pv_oper.kood1, '')      AS kood1,
                         coalesce(v_pv_oper.kood2, '')      AS kood2,
                         coalesce(v_pv_oper.kood3, '')      AS kood3,
                         coalesce(v_pv_oper.kood4, '')      AS kood4,
                         coalesce(v_pv_oper.kood5, '')      AS kood5
                     INTO v_journal1;
                     l_json_details = l_json_details || ',' || row_to_json(v_journal1);

                 END IF;


        WHEN v_pv_oper.liik = 5 -- array_position(a_pv_opers, 'umberhindamine')
            THEN error_code = 1; -- Konteerimine pole vajalik
                 error_message = 'Umberhindamine konteerimine ei ole realiseeritud';
                 result = 0;
                 RETURN;
        WHEN v_pv_oper.liik = 6
            THEN -- umberklassifitseerimine
            -- PV->investeeringud
                IF v_pv_oper.konto = '154000'
                THEN
                    SELECT
                        0                              AS id,
                        coalesce(v_pv_oper.summa, 0)   AS summa,
                        '154000'                       AS deebet,
                        v_pv_oper.po_konto             AS kreedit,
                        ''                             AS lisa_d,
                        ''                             AS lisa_k,
                        coalesce(v_pv_oper.tunnus, '') AS tunnus,
                        coalesce(v_pv_oper.proj, '')   AS proj,
                        coalesce(v_pv_oper.kood1, '')  AS kood1,
                        coalesce(v_pv_oper.kood2, '')  AS kood2,
                        coalesce(v_pv_oper.kood3, '')  AS kood3,
                        coalesce(v_pv_oper.kood4, '')  AS kood4,
                        coalesce(v_pv_oper.kood5, '')  AS kood5
                    INTO v_journal1;
                    l_json_details = row_to_json(v_journal1);

                    IF v_pv_oper.po_kulum_konto IS NOT NULL AND v_pv_oper.korr_konto <> '155000' AND
                       coalesce(v_pv_oper.kulum_kokku, 0) > 0 AND NOT empty(v_pv_oper.kulum_konto)
                    THEN
                        -- maa,
                        -- kulum
                        SELECT
                            0                                  AS id,
                            coalesce(v_pv_oper.kulum_kokku, 0) AS summa,
                            v_pv_oper.po_kulum_konto           AS deebet,
                            '154010'                           AS kreedit,
                            coalesce(v_pv_oper.tunnus, '')     AS tunnus,
                            ''                                 AS lisa_d,
                            ''                                 AS lisa_k,
                            coalesce(v_pv_oper.proj, '')       AS proj,
                            coalesce(v_pv_oper.kood1, '')      AS kood1,
                            coalesce(v_pv_oper.kood2, '')      AS kood2,
                            coalesce(v_pv_oper.kood3, '')      AS kood3,
                            coalesce(v_pv_oper.kood4, '')      AS kood4,
                            coalesce(v_pv_oper.kood5, '')      AS kood5
                        INTO v_journal1;
                        l_json_details = l_json_details::TEXT || ',' || row_to_json(v_journal1)::TEXT;

                    END IF;

                ELSE
                    -- investeeringud -> PV
                    SELECT
                        0                              AS id,
                        coalesce(v_pv_oper.summa, 0)   AS summa,
                        v_pv_oper.konto                AS deebet,
                        '154000'                       AS kreedit,
                        ''                             AS lisa_d,
                        ''                             AS lisa_k,
                        coalesce(v_pv_oper.tunnus, '') AS tunnus,
                        coalesce(v_pv_oper.proj, '')   AS proj,
                        coalesce(v_pv_oper.kood1, '')  AS kood1,
                        coalesce(v_pv_oper.kood2, '')  AS kood2,
                        coalesce(v_pv_oper.kood3, '')  AS kood3,
                        coalesce(v_pv_oper.kood4, '')  AS kood4,
                        coalesce(v_pv_oper.kood5, '')  AS kood5
                    INTO v_journal1;
                    l_json_details = row_to_json(v_journal1);

                    IF v_pv_oper.kulum_konto IS NOT NULL AND v_pv_oper.korr_konto <> '155000' AND
                       coalesce(v_pv_oper.kulum_kokku, 0) > 0 AND NOT empty(v_pv_oper.kulum_konto)
                    THEN
                        -- kulum
                        SELECT
                            0                                  AS id,
                            coalesce(v_pv_oper.kulum_kokku, 0) AS summa,
                            v_pv_oper.po_kulum_konto           AS kreedit,
                            '154010'                           AS deebet,
                            ''                                 AS lisa_d,
                            ''                                 AS lisa_k,
                            coalesce(v_pv_oper.tunnus, '')     AS tunnus,
                            coalesce(v_pv_oper.proj, '')       AS proj,
                            coalesce(v_pv_oper.kood1, '')      AS kood1,
                            coalesce(v_pv_oper.kood2, '')      AS kood2,
                            coalesce(v_pv_oper.kood3, '')      AS kood3,
                            coalesce(v_pv_oper.kood4, '')      AS kood4,
                            coalesce(v_pv_oper.kood5, '')      AS kood5
                        INTO v_journal1;
                        l_json_details = l_json_details::TEXT || ',' || row_to_json(v_journal1)::TEXT;

                    END IF;

                END IF;
        END CASE;


    l_json = row_to_json(v_journal);
    l_json =
            ('{"data":' || trim(TRAILING FROM l_json, '}') :: TEXT || ',"gridData":[' || l_json_details::TEXT || ']}}');

    result = docs.sp_salvesta_journal(l_json :: JSON, user_id, v_pv_oper.rekvId);

    /* salvestan lausend */

    IF result IS NOT NULL AND result > 0
    THEN
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

        UPDATE docs.doc
        SET
            docs_ids   = array(SELECT DISTINCT unnest(array_append(v_pv_oper.docs_ids, result))),
            lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || new_history
        WHERE
            id = v_pv_oper.parentId;

        -- lausend
        SELECT
            docs_ids
        INTO a_docs_ids
        FROM
            docs.doc
        WHERE
            id = result;

        -- add new id into docs. ref. array
        a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_pv_oper.parentId)));

        UPDATE docs.doc
        SET
            docs_ids = a_docs_ids
        WHERE
            id = result;

        -- direct ref to journal
        UPDATE docs.pv_oper
        SET
            journalId = result
        WHERE
            parentid = v_pv_oper.parentid;
    ELSE
        error_code = 2;
        result = 0;
    END IF;
    RETURN;
END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

ALTER FUNCTION docs.gen_lausend_pv_oper( INTEGER, INTEGER )
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.gen_lausend_pv_oper(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.gen_lausend_pv_oper(INTEGER, INTEGER) TO dbpeakasutaja;

/*
select error_code, result, error_message from docs.gen_lausend_pv_oper_(5883561, 956)



*/
