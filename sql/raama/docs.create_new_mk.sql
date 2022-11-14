DROP FUNCTION IF EXISTS docs.create_new_mk(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.create_new_mk(IN user_id INTEGER,
                                              IN params JSONB,
                                              OUT error_code INTEGER,
                                              OUT result INTEGER,
                                              OUT doc_type_id TEXT,
                                              OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_arv_id     INTEGER        = params ->> 'arv_id';
    l_dok        TEXT           = coalesce((params ->> 'dok') :: TEXT, 'MK');
    l_summa      NUMERIC(12, 2) = params ->> 'summa';
    l_dokprop_id INTEGER        = params ->> 'dokprop_id';
    l_viitenr    TEXT           = params ->> 'viitenumber';
    l_number     TEXT           = params ->> 'number';
    l_kpv        DATE           = params ->> 'kpv';
    l_maksepaev  DATE           = params ->> 'maksepaev';
    l_selg       TEXT           = params ->> 'selg';
    l_asutus_id  INTEGER        = params ->> 'maksja_id';
    l_aa         TEXT           = params ->> 'maksja_arve';
    l_asutus_aa  TEXT           = params ->> 'aa';
    mk_id        INTEGER;
    v_arv        RECORD;
    v_mk1        RECORD;
    json_object  JSONB;
    v_params     RECORD;
    json_mk1     JSONB;
    l_pank_id    INTEGER;
    l_laps_id    INTEGER        = CASE
                                      WHEN l_arv_id IS NOT NULL THEN (SELECT parentid
                                                                      FROM lapsed.liidestamine
                                                                      WHERE docid = l_arv_id
                                                                      LIMIT 1)
                                      ELSE left(right(l_viitenr::TEXT, 7), 6)::INTEGER END;
    l_opt        INTEGER;
    l_rekvId     INTEGER        = (SELECT rekvid
                                   FROM ou.userid
                                   WHERE id = user_id);
    l_nom_id     INTEGER;
BEGIN

    IF (l_dokprop_id) IS NULL
    THEN
        l_dokprop_id = (SELECT id
                        FROM public.com_dokprop l
                        WHERE (l.rekvId = l_rekvId OR l.rekvid IS NULL)
                          AND kood = l_dok
                        ORDER BY id DESC
                        LIMIT 1
        );
    END IF;

    SELECT dp.details ->> 'konto'                                         AS konto,
           a.*,
           coalesce((a.properties ->> 'viitenr')::TEXT, '')::VARCHAR(120) AS viitenr
    INTO v_arv
    FROM docs.doc d
             INNER JOIN docs.arv a ON a.parentid = d.id
             LEFT OUTER JOIN libs.dokprop dp ON dp.id = a.doklausid
    WHERE d.id = l_arv_id;

    doc_type_id = CASE WHEN v_arv.liik = 0 OR v_arv.id IS NULL THEN 'SMK' ELSE 'VMK' END;

    -- maksepaev
    IF l_maksepaev IS NULL
    THEN
        IF l_arv_id IS NOT NULL AND doc_type_id = 'VMK'
        THEN
            l_maksepaev = v_arv.tahtaeg;
        ELSE
            l_maksepaev = l_kpv;
        END IF;
    END IF;

    -- viitenr
    IF l_viitenr IS NULL AND v_arv.viitenr IS NOT NULL AND NOT public.empty(v_arv.viitenr)
    THEN
        l_viitenr = v_arv.viitenr;
    END IF;

    -- добавим пояснение
    IF l_selg IS NULL AND l_arv_id IS NOT NULL
    THEN
        l_selg = 'Arve nr.' || ltrim(rtrim(v_arv.number))::TEXT;
    END IF;

    l_opt = (CASE
                 WHEN v_arv.liik = 0 OR v_arv.id IS NULL
                     THEN 2 -- если счет доходный, то мк на поступление средств, иначе расзодное поручение
                 ELSE 1 END);

    IF l_summa IS NULL
    THEN
        l_summa = v_arv.jaak;
        IF v_arv.jaak IS NULL OR v_arv.jaak = 0
        THEN
            l_summa = v_arv.summa - (SELECT sum(summa) FROM docs.arvtasu WHERE doc_arv_id = l_arv_id AND status <> 3);
        END IF;
    END IF;

    -- если счет имеет обратное сальдо , то меняем тип на противоположный
    IF v_arv.id IS NOT NULL AND v_arv.jaak < 0
    THEN
        l_opt = CASE WHEN l_opt = 1 THEN 2 ELSE 1 END;
        l_summa = coalesce(l_summa, -1 * v_arv.jaak);
    END IF;

    IF coalesce(l_summa, 0) <= 0
    THEN
        -- платеж равен нулю
        error_message = 'Makse summa <= 0';
        RETURN;
    END IF;

    IF (l_asutus_id IS NULL AND v_arv.id IS NULL)
    THEN
        -- платильщик не идентифицирован
        error_message = 'Maksja puudub';
        RETURN;

    END IF;

    IF l_asutus_id IS NULL
    THEN
        l_asutus_id = v_arv.asutusid;
    END IF;

    -- создаем параметры для платежки

    -- ищем расчетный счет учреждения
    IF l_asutus_aa IS NOT NULL
    THEN
        l_pank_id = (SELECT id
                     FROM ou.aa aa
                     WHERE kassa = 1
                       AND parentid = l_rekvId
                       AND aa.arve::TEXT = l_asutus_aa::TEXT
                     ORDER BY default_ DESC
                     LIMIT 1);

    END IF;

    l_pank_id = CASE
                    WHEN l_pank_id IS NULL THEN ou.get_aa(l_rekvId,
                                                          CASE WHEN doc_type_id = 'SMK' THEN 'TULUD' ELSE 'KULUD'::TEXT END)
                    ELSE l_pank_id END;

    l_nom_id = (SELECT id
                FROM libs.nomenklatuur n
                WHERE rekvid = l_rekvId
                  AND dok IN (l_dok, doc_type_id)
                ORDER BY id DESC
                LIMIT 1);

    l_aa = CASE
               WHEN l_aa IS NULL THEN (COALESCE((
                                                    SELECT (e.element ->> 'aa') :: VARCHAR(20) AS aa
                                                    FROM libs.asutus a,
                                                         json_array_elements(CASE
                                                                                 WHEN (a.properties ->> 'asutus_aa') IS NULL
                                                                                     THEN '[]'::JSON
                                                                                 ELSE (a.properties -> 'asutus_aa') :: JSON END) AS e (ELEMENT)
                                                    WHERE a.id = l_asutus_id
                                                    LIMIT 1
                                                ), ''))
               ELSE l_aa END;

    IF v_arv.id IS NOT NULL
    THEN
        -- если есть счет, то собираем строку с классфикаторами оттуда
        SELECT 0                                                          AS id,
               l_nom_id                                                   AS nomid,
               l_asutus_id                                                AS asutusid,
               CASE WHEN l_summa IS NULL THEN v_arv.jaak ELSE l_summa END AS summa,
               l_aa :: TEXT                                               AS aa,
               a1.kood1,
               a1.kood2,
               a1.kood3,
               a1.kood4,
               a1.kood5,
               coalesce(v_arv.konto, a1.konto)                            AS konto,
               a1.tp,
               a1.tunnus,
               a1.proj
        FROM docs.arv1 a1
        WHERE a1.
                  parentid = v_arv.id
        ORDER BY kood5
                , kood2 DESC
                , kood1 DESC
        LIMIT 1
        INTO v_mk1;

    ELSE
        SELECT 0           AS id,
               l_nom_id    AS nomid,
               l_asutus_id AS asutusid,
               l_summa     AS summa,
               l_aa        AS aa,
               '103000'    AS konto
        INTO v_mk1;
    END IF;


    json_mk1 = array_to_json((SELECT array_agg(row_to_json(v_mk1))));

    SELECT 0              AS id,
           l_dokprop_id   AS doklausid,
           l_pank_id      AS aa_id,
           v_arv.parentid AS arvid,
           l_opt          AS opt,
           l_viitenr      AS viitenr,
           l_number       AS number,
           l_kpv          AS kpv,
           l_maksepaev    AS maksepaev,
           l_selg         AS selg,
           NULL           AS muud,
           json_mk1       AS "gridData",
           l_laps_id      AS lapsid
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT 0        AS id,
                 v_params AS data) row;

    SELECT docs.sp_salvesta_mk(json_object :: JSON, user_id, l_rekvId) INTO mk_id;

    IF mk_id IS NOT NULL AND mk_id > 0 AND doc_type_id = 'VMK'
    THEN
        result = mk_id;
        -- register
        PERFORM docs.gen_lausend_vmk(mk_id, user_id);
    ELSIF mk_id IS NOT NULL AND mk_id > 0 AND doc_type_id = 'SMK'
    THEN
        result = mk_id;
        -- register
        PERFORM docs.gen_lausend_smk(mk_id, user_id);

    ELSE
        result = 0;
        error_message = 'Dokumendi koostamise viga';
        error_code = 1;
    END IF;
    RETURN;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
            RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.create_new_mk(INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.create_new_mk(INTEGER, JSONB) TO dbpeakasutaja;


/*
SELECT docs.create_new_mk(70, '{"arv_id":1902365}')
select * from docs.arv where rekvid = 63
and number = 'SN1079106'
order by id desc limit 1

select * from docs.doc where id = 1245484

select * from docs.mk where parentid = 1245484

select * from docs.mk1 where parentid = 283417

select * from docs.arvtasu where doc_arv_id = 1245465

select d.*, 0 as valitud from cur_mk d
                where d.rekvId = 63
                and coalesce(docs.usersRigths(d.id, 'select', 2477),true)

select * from libs.library where id = 55

    select * from docs.mk where parentid = 1616855
*/