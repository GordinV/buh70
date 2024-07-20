DROP FUNCTION IF EXISTS docs.ulekanne_ebatoenaolised(JSONB);

CREATE OR REPLACE FUNCTION docs.ulekanne_ebatoenaolised(IN params JSONB,
                                                        OUT error_code INTEGER,
                                                        OUT result INTEGER,
                                                        OUT doc_type_id TEXT,
                                                        OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_alus_arv_id            INTEGER = params ->> 'arv_id';
    l_volg_arv_id            INTEGER; -- копия счета, созданного при переносе сальдо
    l_alus_ebatoenaolised_id INTEGER = params ->> 'ebatoenaolised_id'; -- проводка , переноса маловероятных
    l_uus_ebatoenaolised_id  INTEGER; -- проводка , переноса маловероятных
    userName                 TEXT    = 'temp'; -- имя пользователя, который выполняет таску
    l_tp_rekvid              INTEGER = 9;
    l_user_id                INTEGER; -- пользователь в базе ТП
    l_json_details           JSONB   = '[]'::JSONB;
    v_journal                RECORD;
    v_journal1               RECORD;
    l_tunnus                 TEXT    = '0911088'; -- признак базы ТП
    v_params                 RECORD;
    l_json                   JSON;
    l_kreedit_arve_id        INTEGER; -- кредитовый счет переноса сальдо
    l_dok                    TEXT; -- номер нового (переноса) счета
BEGIN
    RAISE NOTICE 'params %, l_alus_arv_id %, l_alus_ebatoenaolised_id %', params, l_alus_arv_id, l_alus_ebatoenaolised_id;

    -- 1. создаем проводку начисление маловероятных - копию начисленной проводки
    -- ищем пользователя в этом учреждении
    l_user_id = (SELECT id
                 FROM ou.userid
                 WHERE kasutaja::TEXT = userName
                   AND rekvid = l_tp_rekvid
                 LIMIT 1);

    -- ищем счет переноса сальдо в базе ТП
    l_kreedit_arve_id = (SELECT (a.properties ->> 'kreedit_arve_id')::INTEGER
                         FROM docs.arv a
                         WHERE parentid = l_alus_arv_id
                         LIMIT 1);

    l_volg_arv_id = (SELECT parentid
                     FROM docs.arv
                     WHERE properties -> 'doc_kreedit_arved' @> to_jsonb(l_kreedit_arve_id)
                       AND rekvid = l_tp_rekvid
    );

    RAISE NOTICE 'l_kreedit_arve_id %, l_volg_arv_id %', l_kreedit_arve_id, l_volg_arv_id;

    IF l_volg_arv_id IS NULL OR l_kreedit_arve_id IS NULL
    THEN
        -- ошибка, прерываем
        RAISE EXCEPTION 'Viga, ülekanne võlgu arve ei leidnud, kreedit arveId= %', l_kreedit_arve_id;
    END IF;

    l_dok = (SELECT ltrim(rtrim(number)) FROM docs.arv WHERE parentid = l_volg_arv_id);

    -- делаем проводку
    SELECT j.id,
           j.kpv,
           j.selg,
           j.dok,
           j.asutusid
    INTO v_journal
    FROM docs.journal j
    WHERE j.parentid = l_alus_ebatoenaolised_id
    LIMIT 1;

    FOR v_journal1 IN
        SELECT j1.summa,
               j1.deebet,
               j1.kreedit,
               j1.lisa_d,
               j1.lisa_k,
               j1.kood1,
               j1.kood2,
               j1.kood3,
               j1.kood4,
               j1.kood5,
               l_tunnus AS tunnus
        FROM docs.journal1 j1
        WHERE parentid = v_journal.id
        LOOP

            l_json_details = l_json_details || to_jsonb(row)
                             FROM (SELECT 0                     AS id,
                                          -1 * v_journal1.summa AS summa,
                                          v_journal1.deebet     AS deebet,
                                          v_journal1.kreedit    AS kreedit,
                                          v_journal1.kood1      AS kood1,
                                          v_journal1.kood2      AS kood2,
                                          v_journal1.kood3,
                                          l_tunnus              AS tunnus,
                                          v_journal1.kood5      AS kood5,
                                          v_journal1.lisa_d     AS lisa_d,
                                          v_journal1.lisa_k     AS lisa_k
                                  ) row;


        END LOOP;

    SELECT 0                   AS id,
           'JOURNAL'           AS doc_type_id,
           v_journal.kpv       AS kpv,
           v_journal.selg      AS selg,
           v_journal.Asutusid,
           'Arve nr.' || l_dok AS dok,
           l_json_details      AS "gridData"
    INTO v_params;

    l_json = to_json(row)
             FROM (SELECT 0        AS id,
                          v_params AS data) row;

    l_uus_ebatoenaolised_id = docs.sp_salvesta_journal(l_json :: JSON, l_user_id, l_tp_rekvid);

    IF coalesce(l_uus_ebatoenaolised_id, 0) > 0
    THEN
        -- 2. увязываем проводку с новым счетом

-- проводка создана, сохраняем ссылку
        l_json = to_json(row)
                 FROM (SELECT l_uus_ebatoenaolised_id AS ebatoenaolised_1_id
                      ) row;

        UPDATE docs.arv
        SET properties = properties::JSONB || l_json::JSONB
        WHERE id = l_volg_arv_id;

        l_json = to_json(row)
                 FROM (SELECT now()                   AS updated,
                              userName                AS user,
                              'ebatoenaolised'        AS task,
                              l_uus_ebatoenaolised_id AS result
                      ) row;

        -- связываем документы
        UPDATE docs.doc
        SET docs_ids   = array_append(docs_ids, l_uus_ebatoenaolised_id),
            lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || l_json::JSONB
        WHERE id = l_volg_arv_id;
    ELSE
        RAISE EXCEPTION 'Viga, lausendi salvestamine ebaõnnestus, alus lausendi ID %', l_alus_ebatoenaolised_id;
    END IF;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.ulekanne_ebatoenaolised(JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.ulekanne_ebatoenaolised(JSONB) TO dbpeakasutaja;


/*
SELECT docs.ulekanne_ebatoenaolised('{"arv_id":4519925, "ebatoenaolised_id":6302596}')

*/