DROP FUNCTION IF EXISTS docs.arvesta_tulemused(INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS docs.arvesta_tulemused(INTEGER, JSON);

CREATE OR REPLACE FUNCTION docs.arvesta_tulemused(IN l_user_id INTEGER,
                                                  IN params JSON,
                                                  OUT error_code INTEGER,
                                                  OUT result INTEGER, OUT error_message TEXT)
AS
$BODY$
DECLARE
    l_aasta               INTEGER = params ->> 'aasta';
    l_rekv_id             INTEGER = (SELECT rekvid
                                     FROM ou.userid u
                                     WHERE id = l_user_id);

    v_journal             RECORD;
    v_json                RECORD;
    l_journal_id          INTEGER;
    l_json_details        JSONB   = '[]'::JSONB;
    l_json                JSONB;
    l_rows                INTEGER = 0;
    v_user                RECORD;
    v_rekv                RECORD;
    l_asutuse_kasutaja_id INTEGER = l_user_id;


BEGIN
    SELECT *,
           (roles ->> 'is_peakasutaja')::BOOLEAN AS is_peakasutaja
           INTO v_user
    FROM ou.userid
    WHERE id = l_user_id;


    IF v_user IS NULL OR NOT v_user.is_peakasutaja
    THEN
        error_code = 5;
        error_message = 'Kasutaja ei leitud või puudub õigused, aasta.id: ' || coalesce(l_aasta, 0) :: TEXT ||
                        ', userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        RAISE NOTICE 'error %', error_message;
        RETURN;

    END IF;

    FOR v_rekv IN
        SELECT rekv_id
        FROM get_asutuse_struktuur(l_rekv_id)
        LOOP
            -- ищем пользователя
            SELECT id INTO l_asutuse_kasutaja_id
            FROM ou.userid
            WHERE rekvid = v_rekv.rekv_id
              AND kasutaja = v_user.kasutaja
            LIMIT 1;

            -- проверим есть ли у пользователя права в этом учреждении
            IF l_asutuse_kasutaja_id IS NOT NULL
            THEN
                -- обнуляем переменные
                l_json_details = '[]'::JSONB;
                l_json = NULL;
                -- доходы
                FOR v_journal IN
                    SELECT *
                    FROM (
                             SELECT sum(summa) AS summa, konto
                             FROM (
                                      SELECT sum(-1 * summa) AS summa, deebet AS konto
                                      FROM docs.doc d
                                               INNER JOIN docs.journal j ON j.parentid = d.id
                                               INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                                               INNER JOIN libs.library l ON l.library = 'KONTOD'
                                          AND l.tun5 = 4 -- K
                                          AND left(l.kood, 1) IN ('3', '6')
                                          AND l.kood::TEXT = j1.deebet::TEXT
                                      WHERE j.rekvid = v_rekv.rekv_id
                                        AND j.kpv <= make_date(l_aasta, 12, 31)
                                        AND d.status <> 3
                                      GROUP BY deebet
                                      UNION ALL
                                      SELECT sum(summa) AS summa
                                           , kreedit    AS konto
                                      FROM docs.doc d
                                               INNER JOIN docs.journal j ON j.parentid = d.id
                                               INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                                               INNER JOIN libs.library l ON l.library = 'KONTOD'
                                          AND l.tun5 = 4 -- K
                                          AND left(l.kood, 1) IN ('3', '6')
                                          AND l.kood::TEXT = j1.kreedit::TEXT
                                      WHERE j.rekvid = v_rekv.rekv_id
                                        AND j.kpv <= make_date(l_aasta, 12, 31)
                                        AND d.status <> 3
                                      GROUP BY kreedit
                                  ) qry
                             GROUP BY konto
                         ) tmp
                    WHERE summa <> 0
                    LOOP
                        l_rows = l_rows + 1;
                        -- готовим параметры сохранения проводки
                        SELECT 0                                                                   AS id,
                               v_journal.summa                                                     AS summa,
                               'EUR'                                                               AS valuuta,
                               1                                                                   AS kuurs,
                               v_journal.konto                                                     AS deebet,
                               CASE WHEN v_rekv.rekv_id = 63 THEN '298000' ELSE '299000' END::TEXT AS kreedit,
                               ''                                                                  AS lisa_d,
                               ''                                                                  AS lisa_k,
                               ''                                                                  AS tunnus,
                               ''                                                                  AS proj,
                               ''                                                                  AS kood1,
                               ''                                                                  AS kood2,
                               '00'                                                                AS kood3,
                               ''                                                                  AS kood4,
                               ''                                                                  AS kood5
                               INTO v_json;

                        l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_json);


                    END LOOP;

                IF l_rows > 0
                THEN
                    -- ищем проводку с результатом
                    SELECT d.id INTO l_journal_id
                    FROM docs.doc d
                             INNER JOIN docs.journal j ON d.id = j.parentid
                    WHERE j.rekvid = v_rekv.rekv_id
                      AND kpv = make_date(l_aasta, 12, 31) + 1
--          AND d.status = 4 -- 4 - особый статус для итогов
                      AND j.muud IS NOT NULL
                      AND j.muud = 'TULEMUSED, TULUD'
                      AND d.status <> 3
                    ORDER BY id DESC
                    LIMIT 1;

                    --lausendi parametrid

                    SELECT coalesce(l_journal_id, 0)             AS id,
                           'JOURNAL'                             AS doc_type_id,
                           make_date(l_aasta, 12, 31) + 1        AS kpv,
                           'Tulemused, tulud, ' || l_aasta::TEXT AS selg,
                           'TULEMUSED, TULUD'                    AS muud,
                           NULL                                  AS Asutusid,
                           ''::TEXT                              AS dok
                           INTO v_json;

                    l_json = to_jsonb(v_json);

                    l_json = ('{"id": ' || coalesce(l_journal_id, 0)::TEXT || ',"data":' ||
                              trim(TRAILING FROM l_json::TEXT, '}') :: TEXT || ',"gridData":' || l_json_details::TEXT ||
                              '}}');

                    /* salvestan lausend */

                    l_journal_id = docs.sp_salvesta_journal(l_json :: JSON, l_asutuse_kasutaja_id, v_rekv.rekv_id);

                    IF (l_journal_id IS NOT NULL AND l_journal_id > 0)
                    THEN
                        -- salvesta alg_saldo tabelis
                        DELETE FROM docs.alg_saldo WHERE journal_id = l_journal_id;
                        INSERT INTO docs.alg_saldo (journal_id, kpv)
                        VALUES (l_journal_id, make_date(l_aasta, 12, 31));

                    END IF;

                    -- parandan status
                    --UPDATE docs.doc SET status = 4 WHERE id = l_journal_id;
                END IF;

                l_json_details = '[]'::JSONB;

                -- расходы
                FOR v_journal IN
                    SELECT *
                    FROM (
                             SELECT sum(summa) AS summa, konto
                             FROM (
                                      SELECT sum(summa) AS summa, deebet AS konto
                                      FROM docs.doc d
                                               INNER JOIN docs.journal j ON j.parentid = d.id
                                               INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                                               INNER JOIN libs.library l ON l.library = 'KONTOD'
                                          AND l.tun5 = 3 -- D
                                          AND left(l.kood, 1) IN ('4', '5', '6')
                                          AND l.kood::TEXT = j1.deebet::TEXT
                                      WHERE j.rekvid = v_rekv.rekv_id
                                        AND j.kpv <= make_date(l_aasta, 12, 31)
                                        AND d.status <> 3
                                      GROUP BY deebet
                                      UNION ALL
                                      SELECT sum(-1 * summa) AS summa
                                           , kreedit         AS konto
                                      FROM docs.doc d
                                               INNER JOIN docs.journal j ON j.parentid = d.id
                                               INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                                               INNER JOIN libs.library l ON l.library = 'KONTOD'
                                          AND l.tun5 = 3 -- D
                                          AND left(l.kood, 1) IN ('4', '5', '6')
                                          AND l.kood::TEXT = j1.kreedit::TEXT
                                      WHERE j.rekvid = v_rekv.rekv_id
                                        AND j.kpv <= make_date(l_aasta, 12, 31)
                                        AND d.status <> 3
                                      GROUP BY kreedit
                                  ) qry
                             GROUP BY konto
                         ) tmp
                    WHERE summa <> 0
                    LOOP
                        l_rows = l_rows + 1;
                        -- готовим параметры сохранения проводки
                        SELECT 0                                                                   AS id,
                               v_journal.summa                                                     AS summa,
                               'EUR'                                                               AS valuuta,
                               1                                                                   AS kuurs,
                               v_journal.konto                                                     AS kreedit,
                               CASE WHEN v_rekv.rekv_id = 63 THEN '298000' ELSE '299000' END::TEXT AS deebet,
                               ''                                                                  AS lisa_d,
                               ''                                                                  AS lisa_k,
                               ''                                                                  AS tunnus,
                               ''                                                                  AS proj,
                               ''                                                                  AS kood1,
                               ''                                                                  AS kood2,
                               '00'                                                                AS kood3,
                               ''                                                                  AS kood4,
                               ''                                                                  AS kood5
                               INTO v_json;

                        l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_json);

                    END LOOP;

                IF l_rows > 0
                THEN
                    -- ищем проводку с результатом
                    SELECT d.id INTO l_journal_id
                    FROM docs.doc d
                             INNER JOIN docs.journal j ON d.id = j.parentid
                    WHERE j.rekvid = v_rekv.rekv_id
                      AND kpv = make_date(l_aasta, 12, 31) + 1
--          AND d.status = 4 -- 4 - особый статус для итогов
                      AND j.muud IS NOT NULL
                      AND j.muud = 'TULEMUSED, KULUD'
                      AND d.status <> 3
                    ORDER BY id DESC
                    LIMIT 1;

                    --lausendi parametrid

                    SELECT coalesce(l_journal_id, 0)             AS id,
                           'JOURNAL'                             AS doc_type_id,
                           make_date(l_aasta, 12, 31) + 1        AS kpv,
                           'Tulemused, kulud, ' || l_aasta::TEXT AS selg,
                           'TULEMUSED, KULUD'                    AS muud,
                           NULL                                  AS Asutusid,
                           ''::TEXT                              AS dok
                           INTO v_json;

                    l_json = to_jsonb(v_json);

                    l_json = ('{"id": ' || coalesce(l_journal_id, 0)::TEXT || ',"data":' ||
                              trim(TRAILING FROM l_json::TEXT, '}') :: TEXT || ',"gridData":' || l_json_details::TEXT ||
                              '}}');

                    /* salvestan lausend */


                    l_journal_id = docs.sp_salvesta_journal(l_json :: JSON, l_asutuse_kasutaja_id, v_rekv.rekv_id);

                    IF (l_journal_id IS NOT NULL AND l_journal_id > 0)
                    THEN
                        -- salvesta alg_saldo tabelis
                        DELETE FROM docs.alg_saldo WHERE journal_id = l_journal_id;
                        INSERT INTO docs.alg_saldo (journal_id, kpv)
                        VALUES (l_journal_id, make_date(l_aasta, 12, 31));

                    END IF;

                    -- parandan status
                    --UPDATE docs.doc SET status = 4 WHERE id = l_journal_id;

                END IF;
            END IF;

            -- 7x saldo
            l_json_details = '[]'::jsonb;
            FOR v_journal IN
                SELECT *
                FROM (
                         SELECT sum(summa) AS summa, konto
                         FROM (
                                  SELECT sum(summa) AS summa, j1.deebet AS konto
                                  FROM docs.doc d
                                           INNER JOIN docs.journal j ON j.parentid = d.id
                                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                                  WHERE j.rekvid = v_rekv.rekv_id
                                    AND j.kpv <= make_date(l_aasta, 12, 31)
                                    AND d.status <> 3
                                    AND left(j1.deebet, 1) = '7'
                                  GROUP BY j1.deebet
                                  UNION ALL
                                  SELECT sum(-1 * summa) AS summa
                                       , j1.kreedit      AS konto
                                  FROM docs.doc d
                                           INNER JOIN docs.journal j ON j.parentid = d.id
                                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                                  WHERE j.rekvid = v_rekv.rekv_id
                                    AND j.kpv <= make_date(l_aasta, 12, 31)
                                    AND d.status <> 3
                                    AND left(j1.kreedit, 1) = '7'
                                  GROUP BY j1.kreedit
                              ) qry
                         GROUP BY konto
                     ) tmp
                WHERE summa <> 0
                LOOP
                    l_rows = l_rows + 1;
                    -- готовим параметры сохранения проводки
                    SELECT 0               AS id,
                           v_journal.summa AS summa,
                           'EUR'           AS valuuta,
                           1               AS kuurs,
                           v_journal.konto AS kreedit,
                           '999990'::TEXT  AS deebet,
                           ''              AS lisa_d,
                           ''              AS lisa_k,
                           ''              AS tunnus,
                           ''              AS proj,
                           ''              AS kood1,
                           ''              AS kood2,
                           '00'            AS kood3,
                           ''              AS kood4,
                           ''              AS kood5
                           INTO v_json;

                    l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_json);

                END LOOP;

            IF l_rows > 0
            THEN
                -- ищем проводку с результатом
                SELECT d.id INTO l_journal_id
                FROM docs.doc d
                         INNER JOIN docs.journal j ON d.id = j.parentid
                WHERE j.rekvid = v_rekv.rekv_id
                  AND kpv = make_date(l_aasta, 12, 31) + 1
--          AND d.status = 4 -- 4 - особый статус для итогов
                  AND j.muud IS NOT NULL
                  AND j.muud = 'TULEMUSED, 7x'
                  AND d.status <> 3
                ORDER BY id DESC
                LIMIT 1;

                --lausendi parametrid

                SELECT coalesce(l_journal_id, 0)          AS id,
                       'JOURNAL'                          AS doc_type_id,
                       make_date(l_aasta, 12, 31) + 1     AS kpv,
                       'Tulemused, 7x, ' || l_aasta::TEXT AS selg,
                       'TULEMUSED, 7x'                    AS muud,
                       NULL                               AS Asutusid,
                       ''::TEXT                           AS dok
                       INTO v_json;

                l_json = to_jsonb(v_json);

                l_json = ('{"id": ' || coalesce(l_journal_id, 0)::TEXT || ',"data":' ||
                          trim(TRAILING FROM l_json::TEXT, '}') :: TEXT || ',"gridData":' || l_json_details::TEXT ||
                          '}}');

                /* salvestan lausend */


                l_journal_id = docs.sp_salvesta_journal(l_json :: JSON, l_asutuse_kasutaja_id, v_rekv.rekv_id);

                IF (l_journal_id IS NOT NULL AND l_journal_id > 0)
                THEN
                    -- salvesta alg_saldo tabelis
                    DELETE FROM docs.alg_saldo WHERE journal_id = l_journal_id;
                    INSERT INTO docs.alg_saldo (journal_id, kpv)
                    VALUES (l_journal_id, make_date(l_aasta, 12, 31));

                END IF;

                -- parandan status
                --UPDATE docs.doc SET status = 4 WHERE id = l_journal_id;

            END IF;


        END LOOP;

    result = 1;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.arvesta_tulemused(INTEGER, JSON) TO dbpeakasutaja;

/*
select * from sp_execute_task(956::integer, '{"aasta":2019}'::JSON, 'docs.arvesta_tulemused'::TEXT )

 */
