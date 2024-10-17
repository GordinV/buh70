DROP FUNCTION IF EXISTS docs.ebatoenaolised(INTEGER, DATE);
DROP FUNCTION IF EXISTS docs.ebatoenaolised(INTEGER, DATE, INTEGER);

CREATE OR REPLACE FUNCTION docs.ebatoenaolised(IN l_rekv_id INTEGER,
                                               IN l_kpv DATE DEFAULT current_date,
                                               IN l_arv_id INTEGER DEFAULT NULL,
                                               OUT error_code INTEGER,
                                               OUT result INTEGER,
                                               OUT error_message TEXT)
    RETURNS SETOF RECORD
AS
$BODY$
DECLARE
    l_json             JSONB;
    l_json_details     JSONB          = '[]'::JSONB;
    v_params           RECORD;
    l_user_id          INTEGER; -- Иимя пользователя от чьего имени будет создана проводка
    userName           TEXT           = 'temp'; -- имя пользователя, который выполняет таску
    l_journal_id       INTEGER;
    l_summa            NUMERIC(14, 2) = 0;
    v_aasta            RECORD;
    v_aruanne          RECORD;
    l_selg             TEXT           = 'Ebatõenäolised nõuded';
    l_seisuga          DATE           = l_kpv;
    l_noude_vahe       NUMERIC        = 0; -- тут отражается разница начтсленного и суммы отчета
    kas_noude_100      BOOLEAN        = FALSE; -- первое или второе начисление
    l_lausendi_period  DATE           = l_kpv; -- дата проводки
    l_db_konto         TEXT ;
    l_kr_konto         TEXT           = '10300929'; -- для род.платы, иначе 10300928
    kas_vanemtasu      BOOLEAN        = TRUE;
    kas_saldo_ulekkane BOOLEAN        = FALSE; -- если счет "оплачен" через перенос, то проводка иная плюс перенос маловероятных
    l_lisa_selg        TEXT           = '';
    l_kreedit_arve_id  INTEGER; -- кредитовый счет переноса сальдо
    l_aasta            integer        = year(l_seisuga);
BEGIN

    if month(l_seisuga) = 1 then
        l_aasta = l_aasta - 1; -- а январе считаем за прошлый год
    end if;

    if month(l_seisuga) not in (4, 7, 10, 1) then
        raise exception 'Viga, vale period %', l_seisuga;
    end if;

    l_seisuga = (select case
                            when month(l_seisuga) >= 1 and month(l_seisuga) < 3 then date(l_aasta, 12, 31)
                            when month(l_seisuga) >= 3 and month(l_seisuga) < 6 then date(l_aasta, 3, 31)
                            when month(l_seisuga) >= 6 and month(l_seisuga) < 9 then date(l_aasta, 6, 30)
                            when month(l_seisuga) >= 9 and month(l_seisuga) < 12 then date(l_aasta, 09, 30)
                            end);

    l_lausendi_period = l_seisuga;

    -- формируем список просроченных счетов (50%)
    -- формируем отчет и сравниваем со начислениями по счетам
    FOR v_aruanne IN
        WITH reports AS (SELECT r.*,
                                (a.properties ->> 'ebatoenaolised_1_id')::INTEGER              AS arv_noude_50,
                                (a.properties ->> 'ebatoenaolised_2_id')::INTEGER              AS arv_noude_100,
                                a.id                                                           AS arv_id,
                                a.asutusid,
                                coalesce((a.properties ->> 'ebatoenaolised_1_id')::INTEGER, 0) AS ebatoenaolised_1_id,
                                coalesce((a.properties ->> 'ebatoenaolised_2_id')::INTEGER, 0) AS ebatoenaolised_2_id,
                                d.docs_ids

                         FROM lapsed.ebatoenaolised(l_rekv_id::INTEGER, l_seisuga) r
                                  LEFT OUTER JOIN docs.arv a ON a.parentid = r.doc_id
                                  INNER JOIN docs.doc d ON d.id = a.parentid
--            WHERE r.konto = '10300929'
--            WHERE (l_arv_id IS NULL
--                OR r.doc_id = l_arv_id)
        )
        SELECT *
        FROM reports r
        WHERE (CASE WHEN l_arv_id IS NULL THEN TRUE ELSE r.doc_id = l_arv_id END)
          AND (
            CASE
                WHEN (coalesce(r.noude_50, 0) + coalesce(r.noude_100, 0)) > 0 THEN TRUE
                WHEN (r.ebatoenaolised_1_id + ebatoenaolised_2_id > 0) THEN TRUE
                WHEN (
                    r.ebatoenaolised_1_id + ebatoenaolised_2_id = 0 AND
                    exists(SELECT j.id
                           FROM docs.journal j,
                                docs.journal1 j1
                           WHERE j.id = j1.parentid
                             AND j.parentid IN (SELECT unnest(r.docs_ids))
                             AND left(j1.kreedit, 6) = left('103009', 6))
                    ) THEN TRUE
                ELSE FALSE END)
        /*


                      (l_arv_id IS NULL
                    OR r.doc_id = l_arv_id)
                  AND ((r.noude_50 + r.noude_100) > 0
                    OR (r.ebatoenaolised_1_id + ebatoenaolised_2_id > 0)
                    OR (
                               r.ebatoenaolised_1_id + ebatoenaolised_2_id = 0 AND
                               exists(SELECT id
                                      FROM cur_journal
                                      WHERE id IN (SELECT unnest(r.docs_ids))
                                        AND left(kreedit, 6) = left(l_kr_konto, 6))
                           ))
        */--        order by id desc limit 100
        LOOP
            RAISE NOTICE 'loop v_aruanne.arv_id %', v_aruanne.arv_id;

            l_journal_id = 0;
            l_lisa_selg = '';
            l_db_konto = '605030'; -- дефольный счет
            kas_saldo_ulekkane = FALSE;

            -- обнулим
            -- суммируем маловероятные для счетов в отчете
            SELECT sum(summa)
            INTO l_summa
            FROM cur_journal j
            WHERE deebet = l_db_konto
              AND left(kreedit, 6) = left(l_kr_konto, 6)
              and (j.selg ilike '%Ebatõenäolised%' or j.selg ilike 'Ebatoenaolised%')
              AND j.id IN (SELECT unnest(d.docs_ids)
                           FROM docs.doc d
                           WHERE d.id = v_aruanne.doc_id
                             AND j.kpv > '2023-09-01'::DATE -- с момента аннулирования маловероятных
            );

            RAISE NOTICE 'l_summa %, v_aruanne.noude_50 %, v_aruanne.noude_100 %', l_summa, v_aruanne.noude_50, v_aruanne.noude_100;
-- сравниваем
            IF ((v_aruanne.noude_50 <> 0 OR v_aruanne.noude_100 <> 0) OR
                (coalesce(l_summa, 0) <> 0 AND coalesce(l_summa, 0) <> (v_aruanne.noude_50 + v_aruanne.noude_100)))
            THEN
                -- есть отличие, считаем разницу
                l_noude_vahe = (v_aruanne.noude_50 + v_aruanne.noude_100) - coalesce(l_summa, 0);
                kas_noude_100 = v_aruanne.noude_100 <> 0;

                RAISE NOTICE 'Vahe l_noude_vahe %,kas_noude_100 %, (v_aruanne.noude_50 + v_aruanne.noude_100) %, l_summa %', l_noude_vahe, kas_noude_100, (v_aruanne.noude_50 + v_aruanne.noude_100),l_summa;

                IF l_noude_vahe <> 0
                THEN

                    -- проверяем период
                    IF exists(SELECT id
                              FROM ou.aasta
                              WHERE rekvid = v_aruanne.rekvid
                                AND kuu = month(l_kpv)
                                AND aasta = year(l_kpv)
                                AND kinni = 1)
                    THEN
                        -- То есть тогда, если вдруг по каким-то причинам период закрыт, то алгоритм должен это учитывать и делать проводки в первом месяце открытого периода.
                        SELECT *
                        INTO v_aasta
                        FROM ou.aasta
                        WHERE rekvid = v_aruanne.rekvid
                          AND aasta = year(l_kpv)
                          AND kinni = 1
                        ORDER BY make_date(aasta, kuu, 1) DESC
                        LIMIT 1;

                        l_lausendi_period = get_last_day(gomonth(make_date(v_aasta.aasta, v_aasta.kuu, 1)::DATE, 1));
                    END IF;

                    -- ищем пользователя в этом учреждении
                    l_user_id = (SELECT id
                                 FROM ou.userid
                                 WHERE kasutaja::TEXT = userName
                                   AND rekvid = v_aruanne.rekvid
                                 LIMIT 1);


                    -- проверяем перенос ли это
                    l_kreedit_arve_id = (SELECT (a.properties ->> 'kreedit_arve_id')::INTEGER
                                         FROM docs.arv a
                                         WHERE parentid = v_aruanne.doc_id
                                         LIMIT 1);

                    RAISE NOTICE 'kas ulekanne l_kreedit_arve_id %, v_aruanne.doc_id %, kas_saldo_ulekkane %',l_kreedit_arve_id, v_aruanne.doc_id, kas_saldo_ulekkane;

                    IF l_kreedit_arve_id IS NOT NULL AND exists(SELECT id
                                                                FROM docs.arv
                                                                WHERE properties -> 'doc_kreedit_arved' @> to_jsonb(l_kreedit_arve_id)
                                                                  AND rekvid = 9)
                    THEN


                        kas_saldo_ulekkane = TRUE;
                        l_lisa_selg = '(üleviimine)';

                        -- меняем кор.счет
                        /*
                         Переносы маловероятных:
                        - Д888888-К10300929 (-) Ebatõenäolised nõuded (50) (üleviimine), либо Ebatõenäolised nõuded (100) (üleviimine) - из одного учреждения
                        - Д888888-К10300929 (+) Ebatõenäolised nõuded (50) (üleviimine), либо Ebatõenäolised nõuded (100) (üleviimine) - в другое учреждение
                         */
                        l_db_konto = '888888';
                    END IF;
                    l_kr_konto = v_aruanne.konto;
                    -- берем из отчета

                    -- делаем проводку
                    l_json_details = '[]'::JSONB; -- инициализируем массив под проводку
                    l_json_details = l_json_details || to_jsonb(row)
                                     FROM (SELECT 0                                                                    AS id,
                                                  l_noude_vahe                                                         AS summa,
                                                  l_db_konto                                                           AS deebet,
                                                  l_kr_konto                                                           AS kreedit,
                                                  CASE
                                                      WHEN a1.kood1 IS NULL OR empty(a1.kood1) THEN '01112'
                                                      ELSE a1.kood1 END                                                AS kood1,
                                                  CASE
                                                      WHEN a1.kood2 IS NULL OR empty(a1.kood2) THEN '80'
                                                      ELSE a1.kood2 END                                                AS kood2,
                                                  a1.kood3,
                                                  a1.tunnus,
                                                  CASE
                                                      WHEN a1.konto IS NULL OR empty(a1.konto) THEN '322000'
                                                      ELSE a1.konto END                                                AS konto,
                                                  '608'                                                                AS kood5,
                                                  CASE WHEN a1.tp IS NULL OR empty(a1.tp) THEN '800699' ELSE a1.tp END AS lisa_d,
                                                  CASE WHEN a1.tp IS NULL OR empty(a1.tp) THEN '800699' ELSE a1.tp END AS lisa_k
                                           FROM docs.arv1 a1
                                           WHERE a1.parentid = v_aruanne.arv_id
                                           ORDER BY summa DESC
                                           LIMIT 1) row;


                    SELECT 0                                                                             AS id,
                           'JOURNAL'                                                                     AS doc_type_id,
                           l_lausendi_period                                                             AS kpv,
                           l_selg || CASE WHEN kas_noude_100 THEN '(100)' ELSE '(50)' END || l_lisa_selg AS selg,
                           v_aruanne.Asutusid,
                           'Arve nr.' || v_aruanne.number::TEXT                                          AS dok,
                           l_json_details                                                                AS "gridData"
                    INTO v_params;

                    l_json = to_json(row)
                             FROM (SELECT 0        AS id,
                                          v_params AS data) row;

                    l_journal_id = docs.sp_salvesta_journal(l_json :: JSON, l_user_id, v_aruanne.rekvId);

                    IF (l_journal_id IS NOT NULL AND l_journal_id > 0 AND
                        exists(SELECT id FROM cur_journal WHERE id = l_journal_id))
                    THEN
                        -- проводка создана, сохраняем ссылку
                        IF NOT kas_noude_100
                        THEN
                            l_json = to_json(row)
                                     FROM (SELECT l_journal_id AS ebatoenaolised_1_id) row;
                        ELSE
                            l_json = to_json(row)
                                     FROM (SELECT l_journal_id AS ebatoenaolised_2_id) row;
                        END IF;

                        UPDATE docs.arv
                        SET properties = properties::JSONB || l_json::JSONB
                        WHERE id = v_aruanne.arv_id;

                        l_json = to_json(row)
                                 FROM (SELECT now()            AS updated,
                                              userName         AS user,
                                              'ebatoenaolised' AS task,
                                              l_journal_id     AS result) row;

                        -- связываем документы
                        UPDATE docs.doc
                        SET docs_ids   = array_append(docs_ids, l_journal_id),
                            lastupdate = now(),
                            history    = coalesce(history, '[]') :: JSONB || l_json::JSONB
                        WHERE id = v_aruanne.doc_id;

                        -- если перенос, то создаем параллельную проводку
                        IF kas_saldo_ulekkane
                        THEN
                            RAISE NOTICE 'ebatoenaolised ulekanne';
                            l_json = json_build_object('arv_id', v_aruanne.doc_id, 'ebatoenaolised_id', l_journal_id);
                            PERFORM docs.ulekanne_ebatoenaolised(l_json);
                        END IF;

                    ELSE
                        l_journal_id = 0;
                        result = 0;
                        error_message = 'Viga, arve nr. ' || ltrim(rtrim(v_aruanne.number));
                        RETURN NEXT;
                    END IF;
                END IF;
            END IF; -- есть разница
            IF coalesce(l_journal_id, 0) > 0
            THEN
                result = l_journal_id;
                error_message = 'Koostatud ebatõenäolised lausend, arve nr. ' || ltrim(rtrim(v_aruanne.number));
            ELSE
                result = 0;
                error_message = 'Arve nr. ' || ltrim(rtrim(v_aruanne.number)) || ' ebatõenäolised = 0';
            END IF;
            l_journal_id = 0;
            RETURN NEXT;

        END LOOP;
    RETURN;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            result = 0;
            error_code = 9;
            error_message = 'tekkis viga: ' || coalesce(SQLERRM, '');
            RETURN;

END ;

$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

ALTER FUNCTION docs.ebatoenaolised( INTEGER, DATE , INTEGER)
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.ebatoenaolised(INTEGER, DATE, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.ebatoenaolised(INTEGER, DATE, INTEGER) TO dbpeakasutaja;

/*
SELECT docs.ebatoenaolised(77, '2024-10-06',4784987)
from ou.rekv
where parentid = 119
and id  in (94)
*/




