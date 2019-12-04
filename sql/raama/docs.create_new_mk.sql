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
    l_selg       TEXT           = params ->> 'selg';
    mk_id        INTEGER;
    v_arv        RECORD;
    json_object  JSONB;
    v_params     RECORD;
    json_mk1     JSONB;
    l_pank_id    INTEGER;
    l_laps_id    INTEGER        = (SELECT parentid
                                   FROM lapsed.liidestamine
                                   WHERE docid = l_arv_id
                                   LIMIT 1);
    l_opt        INTEGER;

BEGIN

    SELECT a.* INTO v_arv
    FROM docs.doc d
             INNER JOIN docs.arv a ON a.parentid = d.id
    WHERE d.id = l_arv_id;

    doc_type_id = CASE WHEN v_arv.liik = 0 THEN 'SMK' ELSE 'VMK' END;

    l_opt = (CASE
                 WHEN v_arv.liik = 0
                     THEN 2 -- если счет доходный, то мк на поступление средств, иначе расзодное поручение
                 ELSE 1 END);

    -- если счет имеет обратное сальдо , то меняем тип на противоположный
    IF v_arv.jaak < 0
    THEN
        l_opt = CASE WHEN l_opt = 1 THEN 2 ELSE 1 END;
        doc_type_id = CASE WHEN v_arv.liik = 0 THEN 'VMK' ELSE 'SMK' END;
        l_summa = coalesce(l_summa, -1 * v_arv.jaak);
    END IF;


    IF l_arv_id IS NULL OR v_arv.id IS NULL OR empty(l_arv_id)
    THEN
        error_message = 'Arve puudub või vale parametrid';
        error_code = 6;
        result = 0;
        RETURN;
    END IF;

    IF v_arv.jaak = 0
    THEN
        result = 0;
        error_code = 0;
        error_message = 'Arve jaak = 0';
        RETURN;
    END IF;

    -- создаем параметры для платежки

    l_pank_id = (SELECT id
                 FROM ou.aa
                 WHERE kassa = 1
                   AND parentid = v_arv.rekvid
                 ORDER BY default_
                 LIMIT
                     1);

    json_mk1 = array_to_json((SELECT array_agg(row_to_json(m1.*))
                              FROM (SELECT 0                                                          AS id,
                                           (SELECT id
                                            FROM libs.nomenklatuur n
                                            WHERE rekvid = v_arv.rekvid
                                              AND dok IN (l_dok, doc_type_id)
                                            ORDER BY id
                                                DESC
                                            LIMIT
                                                1)                                                    AS nomid,
                                           v_arv.asutusid                                             AS asutusid,
                                           CASE WHEN l_summa IS NULL THEN v_arv.jaak ELSE l_summa END AS summa,
                                           coalesce((
                                                        SELECT (e.element ->> 'aa') :: VARCHAR(20) AS aa
                                                        FROM libs.asutus a,
                                                             json_array_elements(CASE
                                                                                     WHEN (a.properties ->> 'asutus_aa') IS NULL
                                                                                         THEN '[]'::JSON
                                                                                     ELSE (a.properties -> 'asutus_aa') :: JSON END) AS e (element)
                                                        WHERE a.id = v_arv.asutusid
                                                        LIMIT
                                                            1
                                                    ), '') :: TEXT                                    AS aa,
                                           a1.kood1,
                                           a1.kood2,
                                           a1.kood3,
                                           a1.kood4,
                                           a1.kood5,
                                           a1.konto,
                                           a1.tp,
                                           a1.tunnus,
                                           a1.proj
                                    FROM docs.arv1 a1
                                    WHERE a1.parentid = v_arv.id
                                    ORDER BY kood5,
                                             kood2
                                        DESC,
                                             kood1
                                        DESC
                                    LIMIT
                                        1
                                   ) AS m1
    ));
    SELECT 0              AS id,
           l_dokprop_id   AS doklausid,
           l_pank_id      AS aaid,
           v_arv.parentid AS arvid,
           l_opt          AS opt,
           l_viitenr      AS viitenr,
           l_number       AS number,
           l_kpv          AS maksepaev,
           l_kpv          AS kpv,
           l_selg         AS selg,
           NULL           AS muud,
           json_mk1       AS "gridData",
           l_laps_id      AS lapsid
           INTO v_params;

    SELECT row_to_json(row) INTO json_object
    FROM (SELECT 0        AS id,
                 v_params AS data) row;

    SELECT docs.sp_salvesta_mk(json_object :: JSON, user_id, v_arv.rekvid) INTO mk_id;

    IF mk_id IS NOT NULL AND mk_id > 0
    THEN
        result = mk_id;
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
SELECT docs.create_new_mk(70, '{"arv_id":1616591}')
select * from docs.arv where rekvid = 63 order by id desc limit 1

select * from docs.doc where id = 1245484

select * from docs.mk where parentid = 1245484

select * from docs.mk1 where parentid = 283417

select * from docs.arvtasu where doc_arv_id = 1245465

select d.*, 0 as valitud from cur_mk d
                where d.rekvId = 63
                and coalesce(docs.usersRigths(d.id, 'select', 2477),true)

select * from libs.library where id = 55
*/