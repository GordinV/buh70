-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.koosta_arve_ettemaksuarve_alusel(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.koosta_arve_ettemaksuarve_alusel(IN user_id INTEGER,
                                                                   IN l_ettemaksu_arve_id INTEGER,
                                                                   OUT error_code INTEGER,
                                                                   OUT result INTEGER,
                                                                   OUT doc_type_id TEXT,
                                                                   OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_doklausend_id INTEGER;
    v_arv           RECORD;
    v_arvread       RECORD;
    l_arve_id       INTEGER;
    l_number        TEXT;
    l_kpv           DATE;
    json_object     JSONB;
    l_json_arve     JSON;
    json_arvread    JSONB = '[]';
    l_db_konto      TEXT  = '203900';
BEGIN

    -- will return docTypeid of new doc
    doc_type_id = 'ARV';
    -- грузим счет на предоплату
    SELECT a.*,
           (a.properties ->> 'ettemaksu_period')::INTEGER AS ettemaksu_period,
           l.parentid                                     AS lapsid
           INTO v_arv
    FROM docs.doc d
             INNER JOIN docs.arv a ON d.id = a.parentid
             INNER JOIN lapsed.liidestamine l ON l.docid = d.id
    WHERE d.id = l_ettemaksu_arve_id;

    IF v_arv IS NULL
    THEN
        error_message = 'Ettemaksuarve ei leidnud';
        error_code = 1;
        result = 0;
        RETURN;
    END IF;

    -- ищем ид конфигурации контировки

    l_doklausend_id = (SELECT dp.id
                       FROM libs.dokprop dp
                                INNER JOIN libs.library l ON l.id = dp.parentid
                       WHERE dp.rekvid = v_arv.rekvid
                         AND (dp.details ->> 'konto')::TEXT = l_db_konto::TEXT
                         AND l.kood = 'ARV'
                       ORDER BY dp.id DESC
                       LIMIT 1
    );


    -- идем в цикле по периодам
    FOR i IN 1..v_arv.ettemaksu_period
        LOOP
            -- ищем уже имеющийся счет
            SELECT parentid, number INTO l_arve_id, l_number
            FROM docs.arv a
            WHERE (a.properties::JSONB ->> 'ettemaksu_arve_id') ::INTEGER = v_arv.id
              AND (a.properties ->> 'ettemaksu_period')::INTEGER = i;


            -- выбираем услуги
            FOR v_arvread IN
                SELECT a1.*,
                       a1.hind                                                                         AS calc_hind,
                       1                                                                               AS calc_kogus,
                       a1.hind *
                       (coalesce((n.properties ->> 'vat')::NUMERIC, 0)::NUMERIC / 100)                 AS calc_kbm,
                       a1.hind * 1                                                                     AS calc_kbmta,
                       a1.hind * 1 + (a1.hind *
                                      (coalesce((n.properties ->> 'vat')::NUMERIC, 0)::NUMERIC / 100)) AS calc_summa,
                       n.properties ->> 'konto'                                                        AS korr_konto,
                       coalesce((a1.properties ->> 'soodustus')::NUMERIC, 0)::NUMERIC                  AS soodustus
                FROM docs.arv1 a1
                         INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                WHERE a1.parentid = v_arv.id
                LOOP
                    -- создаем параметры строки
                    -- формируем строку
                    json_arvread = json_arvread || (SELECT row_to_json(row)
                                                    FROM (SELECT v_arvread.nomid                      AS nomid,
                                                                 v_arvread.calc_kogus                 AS kogus,
                                                                 v_arvread.calc_hind                  AS hind,
                                                                 v_arvread.calc_kbmta                 AS kbmta,
                                                                 v_arvread.calc_kbm                   AS kbm,
                                                                 v_arvread.calc_summa                 AS summa,
                                                                 v_arvread.kood1                      AS kood1,
                                                                 v_arvread.kood2                      AS kood2,
                                                                 v_arvread.kood3                      AS kood3,
                                                                 v_arvread.kood5                      AS kood5,
                                                                 v_arvread.korr_konto                 AS konto,
                                                                 v_arvread.tunnus,
                                                                 v_arvread.proj                       AS projekt,
                                                                 v_arvread.properties ->> 'yksus'     AS yksus,
                                                                 v_arvread.properties ->> 'all_yksus' AS all_yksus,
                                                                 v_arvread.muud                       AS muud,
                                                                 v_arvread.soodustus                  AS soodustus,
                                                                 v_arvread.tp                         AS tp) row) :: JSONB;


                END LOOP;

            -- создаем параметры
            l_kpv = (date(year(v_arv.kpv), month(v_arv.kpv), 1) +
                     make_interval(months => i))::DATE - 1;

            l_json_arve = (SELECT to_json(row)
                           FROM (SELECT coalesce(l_arve_id, 0)                                       AS id,
                                        l_number                                                     AS number,
                                        l_doklausend_id                                              AS doklausid,
                                        v_arv.liik                                                   AS liik,
                                        l_kpv                                                        AS kpv,
                                        v_arv.asutusid                                               AS asutusid,
                                        v_arv.lapsid                                                 AS lapsid,
                                        v_arv.properties ->> 'aa'                                    AS aa,
                                        (v_arv.properties ->> 'print')::JSONB                        AS print,
                                        i                                                            AS ettemaksu_period,
                                        l_ettemaksu_arve_id                                          AS ettemaksu_arve_id,
                                        'Ettemaksuarve number ' || v_arv.number::TEXT || ' alusel, ' ||
                                        to_char(l_kpv, 'MM.YYYY') || ' (' || i::TEXT || ') kuu eest' AS muud,

                                        json_arvread                                                 AS "gridData") row);

            -- подготавливаем параметры для создания счета
            SELECT row_to_json(row) INTO json_object
            FROM (SELECT coalesce(l_arve_id, 0) AS id, l_json_arve AS data) row;

            SELECT docs.sp_salvesta_arv(json_object :: JSON, user_id, v_arv.rekvid) INTO l_arve_id;
            IF l_arve_id IS NOT NULL AND l_arve_id > 0
            THEN
                -- контируем
                PERFORM docs.gen_lausend_arv(l_arve_id, user_id);

                result = coalesce(result, 0) + 1;
            END IF;

            -- обнулим масив строк
            json_arvread = '[]'::JSONB;
        END LOOP;
    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
            RETURN;
END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.koosta_arve_ettemaksuarve_alusel(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.koosta_arve_ettemaksuarve_alusel(INTEGER, INTEGER) TO dbpeakasutaja;
REVOKE EXECUTE ON FUNCTION lapsed.koosta_arve_ettemaksuarve_alusel(INTEGER, INTEGER) FROM arvestaja;


/*
select lapsed.koosta_arve_ettemaksuarve_alusel(70, 1616643)
 */

