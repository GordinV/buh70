CREATE OR REPLACE FUNCTION docs.kassatulude_uleviimine(l_user_id INTEGER, l_tasu_id INTEGER) RETURNS BOOLEAN
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_makse             RECORD;
    v_arv1              RECORD;
    v_journal           RECORD;
    l_json_details      JSONB;
    l_json              JSONB;
    l_parrallel_id_from INTEGER;
    l_parrallel_id_to   INTEGER;
    l_asendus_user_id   INTEGER;
    l_deleted           BOOLEAN = FALSE;
BEGIN
    -- род. плата , перенос оплат на замещающие услуги
    IF exists(
            SELECT a.id, a1.properties, a1.properties ->> 'asendus_id'
            FROM docs.arv a
                     INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
            WHERE a.parentid IN
                  (SELECT at.doc_arv_id FROM docs.arvtasu at WHERE doc_tasu_id = l_tasu_id AND at.status < 3)
              AND a.jaak = 0
              AND a1.properties ->> 'asendus_id' IS NOT NULL
              AND (a1.properties ->> 'asendus_id')::INTEGER > 0)
    THEN
        -- счет оплачен и есть импортированные услуги

        SELECT j1.lisa_d,
               j1.lisa_k,
               j.asutusid,
               j1.kood1,
               j1.kood2,
               j1.kood3,
               j1.kood4,
               j1.kood5,
               j1.tunnus,
               j1.proj,
               j.kpv,
               at.doc_arv_id AS doc_arv_id
        INTO v_makse
        FROM docs.arvtasu at
                 INNER JOIN docs.doc d ON d.id = at.doc_tasu_id
                 LEFT OUTER JOIN docs.mk mk ON mk.parentid = d.id
                 LEFT OUTER JOIN docs.mk1 mk1 ON mk1.parentid = mk.id
                 LEFT OUTER JOIN docs.journal j ON j.parentid = mk1.journalid
                 LEFT OUTER JOIN docs.journal1 j1 ON j1.parentid = j.id
        WHERE at.doc_tasu_id = l_tasu_id
          AND left(j1.deebet, 6) IN ('100100', '999999')
        ORDER BY j1.id
        LIMIT 1;

        FOR v_arv1 IN
            SELECT 0                                            AS id,
                   (a1.properties ->> 'asendus_id')::INTEGER    AS asendus_id,
                   -1 * coalesce(a1.summa, 0)                   AS summa,
                   '999999'                                     AS deebet,
                   v_makse.lisa_d                               AS lisa_d,
                   '20363005'                                   AS kreedit,
                   v_makse.lisa_k                               AS lisa_k,
                   v_makse.tunnus                               AS tunnus,
                   v_makse.proj                                 AS proj,
                   v_makse.kood1                                AS kood1,
                   v_makse.kood2                                AS kood2,
                   v_makse.kood3                                AS kood3,
                   v_makse.kood4                                AS kood4,
                   v_makse.kood5                                AS kood5,
                   v_makse.kpv,
                   a.number,
                   a.muud,
                   a.asutusid,
                   'Toitlustamine, Kassatulude teise lasteaeda' AS selg,
                   at.rekvid                                    AS asendus_rekvid,
                   a.rekvid                                     AS rekv_id,
                   a.id                                         AS arv_id
            FROM docs.arv a
                     INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
                     INNER JOIN lapsed.asendus_taabel at ON at.id = (a1.properties ->> 'asendus_id')::INTEGER
            WHERE a.parentid = v_makse.doc_arv_id
              AND v_makse.doc_arv_id IS NOT NULL
            LOOP
                IF (NOT l_deleted)
                THEN


                    -- удаляем ранее сделанные проводки
                    PERFORM docs.sp_delete_journal(qry.userid, qry.id)
                    FROM (SELECT j.parentid AS id,
                                 (SELECT id
                                  FROM ou.userid u
                                  WHERE u.rekvid = j.rekvid
                                    AND kasutaja IN (SELECT kasutaja FROM ou.userid WHERE id = l_user_Id)
                                    AND status < 3
                                  LIMIT 1)  AS userid
                          FROM docs.journal j
                          WHERE j.properties IS NOT NULL
                            AND (j.properties ->> 'asendus_id')::INTEGER IN (
                              SELECT (properties ->> 'asendus_id')::INTEGER
                              FROM docs.arv1 a1
                              WHERE a1.properties ->> 'asendus_id' IS NOT NULL
                                AND a1.parentid = v_arv1.arv_id)
                            AND j.id IN
                                (SELECT parentid
                                 FROM docs.journal1
                                 WHERE deebet = '999999') -- только передачу кассы
                         ) qry;
                    l_deleted = TRUE; -- чтобы не было повторов
                END IF;

                l_json_details = '[]'::JSONB || to_jsonb(v_arv1);

                SELECT 0                                    AS id,
                       'JOURNAL'                            AS doc_type_id,
                       v_arv1.kpv                           AS kpv,
                       v_arv1.selg                          AS selg,
                       v_arv1.muud                          AS muud,
                       'Arve nr. ' || v_arv1.number::TEXT   AS dok,
                       v_arv1.asutusid                      AS asutusid,
                       v_arv1.asendus_id                    AS asendus_id,
                       '[]'::JSONB || l_json_details::JSONB AS gridData
                INTO v_journal;
                -- создаем параметры
                l_json = jsonb_build_object('id', 0, 'data', to_jsonb(v_journal));

                -- снимаем доходы с учреждение куда поступили деньги
                l_parrallel_id_from = docs.sp_salvesta_journal(l_json :: JSON, l_user_id, v_arv1.rekv_id);

                -- пользователь другого учреждения
                -- подготавливаем параметры для создания проводки
                l_asendus_user_id = (SELECT id
                                     FROM ou.userid u
                                     WHERE u.rekvid = v_arv1.asendus_rekvid
                                       AND u.kasutaja IN (SELECT kasutaja FROM ou.userid WHERE id = l_user_id)
                                       AND status < 3
                                     LIMIT 1);

                v_arv1.summa = -1 * v_arv1.summa;
                v_arv1.tunnus =
                        (SELECT left(r.nimetus, 7) AS tunnus FROM ou.rekv r WHERE r.id = v_arv1.asendus_rekvid LIMIT 1);

                l_json_details = '[]'::JSONB || to_jsonb(v_arv1);
                SELECT 0                                    AS id,
                       'JOURNAL'                            AS doc_type_id,
                       v_arv1.kpv                           AS kpv,
                       v_arv1.selg                          AS selg,
                       v_arv1.muud                          AS muud,
                       'Arve nr. ' || v_arv1.number::TEXT   AS dok,
                       v_arv1.asutusid                      AS asutusid,
                       v_arv1.asendus_id                    AS asendus_id,
                       '[]'::JSONB || l_json_details::JSONB AS gridData
                INTO v_journal;

                -- создаем параметры
                l_json = jsonb_build_object('id', 0, 'data', to_jsonb(v_journal));

                -- если первая часть создана, делаем втору
                IF (l_parrallel_id_from IS NOT NULL AND l_parrallel_id_from > 0)
                THEN
                    l_parrallel_id_to =
                            docs.sp_salvesta_journal(l_json :: JSON, l_asendus_user_id, v_arv1.asendus_rekvid);
                END IF;

            END LOOP;

    END IF;
    RETURN TRUE;

END
$$;

ALTER FUNCTION docs.kassatulude_uleviimine(INTEGER, INTEGER) OWNER TO vlad;

GRANT EXECUTE ON FUNCTION docs.kassatulude_uleviimine(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kassatulude_uleviimine(INTEGER, INTEGER) TO dbkasutaja;
