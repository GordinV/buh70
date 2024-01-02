DROP FUNCTION IF EXISTS docs.ebatoenaolised(INTEGER, DATE);

CREATE OR REPLACE FUNCTION docs.ebatoenaolised(IN l_rekv_id INTEGER,
                                               IN l_kpv DATE DEFAULT current_date,
                                               OUT error_code INTEGER,
                                               OUT result INTEGER,
                                               OUT error_message TEXT)
    RETURNS SETOF RECORD
AS
$BODY$
DECLARE
    v_arv          RECORD;
    v_tasud        RECORD;
    l_json         JSONB;
    l_json_details JSONB          = '[]'::JSONB;
    v_params       RECORD;
    l_user_id      INTEGER; -- Иимя пользователя от чьего имени будет создана проводка
    userName       TEXT           = 'temp'; -- имя пользователя, который выполняет таску
    l_journal_id   INTEGER;
    l_summa        NUMERIC(14, 2) = 0;
    v_aasta        RECORD;
    l_selg         TEXT           = 'Ebatõenäolised nõuded';
    l_seisuga      DATE           = (WITH params AS (
        SELECT l_kpv AS kpv
    )
                                     SELECT CASE
                                                WHEN (params.kpv) > make_date(year(params.kpv) - 1, 12, 31) AND
                                                     params.kpv < make_date(year(params.kpv), 03, 31)
                                                    THEN make_date(year(params.kpv) - 1, 12, 31)
                                                WHEN (params.kpv) > make_date(year(params.kpv), 03, 31) AND
                                                     params.kpv < make_date(year(params.kpv), 06, 30)
                                                    THEN make_date(year(params.kpv), 03, 31)
                                                WHEN (params.kpv) > make_date(year(params.kpv), 06, 30) AND
                                                     params.kpv < make_date(year(params.kpv), 09, 30)
                                                    THEN make_date(year(params.kpv), 06, 30)
                                                WHEN (params.kpv) > make_date(year(params.kpv), 09, 30) AND
                                                     params.kpv < make_date(year(params.kpv), 12, 31)
                                                    THEN make_date(year(params.kpv), 09, 30)
                                                ELSE
                                                    make_date(year(params.kpv), 12, 31)
                                                END AS kpv
                                     FROM params);
BEGIN

    IF l_rekv_id in (select id from ou.rekv where parentid = 119 or id = 119) and l_seisuga = '2023-09-30'::DATE
    THEN
        -- S.Guljaeva
        l_seisuga = '2023-10-31'::DATE;
    END IF;

    IF l_kpv NOT IN
       (make_date(year(l_seisuga), 01, 05), make_date(year(l_seisuga), 04, 05), make_date(year(l_seisuga), 07, 05),
        make_date(year(l_seisuga), 10, 05))
    THEN
        RAISE EXCEPTION 'Viga, vale kuupaev %',l_kpv;
    END IF;

raise notice 'l_seisuga %', l_seisuga;
    -- формируем список просроченных счетов (50%)
    FOR v_arv IN
        WITH arved AS (
            SELECT parentid                                          AS id,
                   a.id                                              AS arv_id,
                   d.rekvid                                          AS rekv_id,
                   a.tahtaeg                                         AS tahtaeg,
                   a.jaak,
                   a.asutusid,
                   a.number,
                   a.summa,
                   CASE
                       WHEN (a.tahtaeg +
                             90 * CASE WHEN (a.properties ->> 'ebatoenaolised_1_id') IS NOT NULL THEN 2 ELSE 1 END) >
                            make_date(year(a.kpv), 03, 31) AND
                            (a.tahtaeg +
                             90 * CASE WHEN (a.properties ->> 'ebatoenaolised_1_id') IS NOT NULL THEN 2 ELSE 1 END) <=
                            make_date(year(a.kpv), 06, 30) THEN make_date(year(a.kpv), 06, 30)
                       WHEN (a.tahtaeg +
                             90 * CASE WHEN (a.properties ->> 'ebatoenaolised_1_id') IS NOT NULL THEN 2 ELSE 1 END) >
                            make_date(year(a.kpv), 06, 30) AND
                            (a.tahtaeg +
                             90 * CASE WHEN (a.properties ->> 'ebatoenaolised_1_id') IS NOT NULL THEN 2 ELSE 1 END) <=
                            make_date(year(a.kpv), 09, 30) THEN make_date(year(a.kpv), 09, 30)
                       WHEN (a.tahtaeg +
                             90 * CASE WHEN (a.properties ->> 'ebatoenaolised_1_id') IS NOT NULL THEN 2 ELSE 1 END) >
                            make_date(2023, 06, 30) AND
                            (a.tahtaeg +
                             90 * CASE WHEN (a.properties ->> 'ebatoenaolised_1_id') IS NOT NULL THEN 2 ELSE 1 END) <=
                            make_date(2023, 10, 31) THEN make_date(2023, 10, 31)

                       WHEN (a.tahtaeg +
                             90 * CASE WHEN (a.properties ->> 'ebatoenaolised_1_id') IS NOT NULL THEN 2 ELSE 1 END) >
                            make_date(year(a.kpv), 09, 30) AND
                            (a.tahtaeg +
                             90 * CASE WHEN (a.properties ->> 'ebatoenaolised_1_id') IS NOT NULL THEN 2 ELSE 1 END) <=
                            make_date(year(a.kpv), 12, 31) THEN make_date(year(a.kpv), 12, 31)
                       ELSE
                           make_date(year(a.kpv) + 1, 03, 31)
                       END                                           AS lausendi_period,
                   (a.properties ->> 'ebatoenaolised_1_id')::INTEGER AS ebatoenaolised_1_id,
                   (a.properties ->> 'ebatoenaolised_2_id')::INTEGER AS ebatoenaolised_2_id
            FROM docs.doc d
                     INNER JOIN docs.arv a ON a.parentid = d.id
            WHERE (d.rekvid = l_rekv_id OR l_rekv_id IS NULL)
--          AND a.jaak > 0
              AND (a.kpv) >= date(2022, 12, 31)     -- начиная с 2023 года
              AND (a.properties ->> 'tyyp') IS NULL -- исключить предоплатные счета
              AND (l_kpv - a.tahtaeg) > 3 * 30      -- просрочен более чем на 4 месяца
              AND ((a.properties ->> 'ebatoenaolised_1_id') IS NULL -- помметка, что на счет начислено списание
                OR (a.properties ->> 'ebatoenaolised_2_id') IS NULL)
              AND a.liik = 0 -- только доходы
            -- AND a.asutusid = 40589 -- только заданный пример
        ),
             tasud AS (
                 SELECT sum(summa) AS summa, doc_arv_id
                 FROM docs.arvtasu at
                 WHERE (rekvid = l_rekv_id OR l_rekv_id IS NULL)
                   AND at.kpv <= l_seisuga
                   AND at.status < 3
                 GROUP BY doc_arv_id
             )

        SELECT a.*, (a.summa - coalesce(t.summa, 0)) AS saldo
        FROM arved a
                 LEFT OUTER JOIN tasud t ON a.id = t.doc_arv_id
        WHERE (a.summa - coalesce(t.summa, 0) > 0)

        LOOP
            raise notice 'arv %', v_arv.id;

            IF v_arv.lausendi_period = '2023-09-30'::DATE
            THEN
                v_arv.lausendi_period = '2023-10-31'::DATE;
            END IF;

            -- проверяем период
            IF exists(SELECT id
                      FROM ou.aasta
                      WHERE rekvid = v_arv.rekv_id
                        AND kuu = month(v_arv.lausendi_period)
                        AND aasta = year(v_arv.lausendi_period)
                        AND kinni = 1)
            THEN
                -- То есть тогда, если вдруг по каким-то причинам период закрыт, то алгоритм должен это учитывать и делать проводки в первом месяце открытого периода.
                SELECT *
                INTO v_aasta
                FROM ou.aasta
                WHERE rekvid = v_arv.rekv_id
                  AND aasta = year(v_arv.lausendi_period)
                  AND kinni = 1
                ORDER BY make_date(aasta, kuu, 1) DESC
                LIMIT 1;

                v_arv.lausendi_period = get_last_day(gomonth(make_date(v_aasta.aasta, v_aasta.kuu, 1)::DATE, 1));
                RAISE NOTICE 'new kpv v_arv.lausendi_period %', v_arv.lausendi_period;
            END IF;

            l_json_details = '[]'::JSONB; -- инициализируем массив под проводку

            l_user_id = (SELECT id FROM ou.userid WHERE kasutaja::TEXT = userName AND rekvid = v_arv.rekv_id LIMIT 1);
            -- ищем пользователя в этом учреждении

            -- расчет суммы
            l_summa = (v_arv.saldo * 0.5)::NUMERIC(14, 2);
            IF v_arv.ebatoenaolised_1_id IS NOT NULL AND v_arv.ebatoenaolised_1_id > 0 AND
               exists(SELECT id FROM cur_journal WHERE id = v_arv.ebatoenaolised_1_id)
            THEN
                -- первое начисление уже сделано, это второе
                l_selg = 'Ebatõenäolised nõuded (100)';

                -- расчет суммы
                l_summa = v_arv.saldo - coalesce((SELECT sum(j1.summa)
                                                  FROM docs.journal1 j1
                                                           INNER JOIN docs.journal j ON j.id = j1.parentid
                                                  WHERE j.parentid IN (coalesce(v_arv.ebatoenaolised_1_id, 0),
                                                                       coalesce(v_arv.ebatoenaolised_2_id, 0))));
            ELSE
                -- первое начисление (50%)
                l_selg = 'Ebatõenäolised nõuded (50)';

            END IF;

            raise notice 'l_summa %, v_arv.lausendi_period %, l_kpv %', l_summa, v_arv.lausendi_period, l_kpv;
            IF l_summa > 0
                   --AND v_arv.lausendi_period <= l_kpv
            THEN
                -- делаем проводку

                --    l_json_details = '';
                l_json_details = l_json_details || to_jsonb(row)
                                 FROM (SELECT 0                                                                    AS id,
                                              l_summa                                                              AS summa, -- 50% от требования
                                              '605030'                                                             AS deebet,
                                              '103009'                                                             AS kreedit,
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
                                       WHERE a1.parentid = v_arv.arv_id
                                       ORDER BY summa DESC
                                       LIMIT 1
                                      ) row;

                SELECT 0                                AS id,
                       'JOURNAL'                        AS doc_type_id,
                       v_arv.lausendi_period            AS kpv,
                       l_selg                           AS selg,
                       v_arv.Asutusid,
                       'Arve nr.' || v_arv.number::TEXT AS dok,
                       l_json_details                   AS "gridData"
                INTO v_params;

                l_json = to_json(row)
                         FROM (SELECT 0        AS id,
                                      v_params AS data) row;

                l_journal_id = docs.sp_salvesta_journal(l_json :: JSON, l_user_id, v_arv.rekv_Id);

                RAISE NOTICE 'l_journal_id %', l_journal_id;
                IF (l_journal_id IS NOT NULL AND l_journal_id > 0)
                THEN
                    -- проводка создана, сохраняем ссылку
                    IF v_arv.ebatoenaolised_1_id IS NULL OR empty(v_arv.ebatoenaolised_1_id)
                    THEN
                        l_json = to_json(row)
                                 FROM (SELECT l_journal_id AS ebatoenaolised_1_id
                                      ) row;
                    ELSE
                        l_json = to_json(row)
                                 FROM (SELECT l_journal_id AS ebatoenaolised_2_id
                                      ) row;
                    END IF;

                    UPDATE docs.arv
                    SET properties = properties::JSONB || l_json::JSONB
                    WHERE id = v_arv.arv_id;

                    l_json = to_json(row)
                             FROM (SELECT now()            AS updated,
                                          userName         AS user,
                                          'ebatoenaolised' AS task,
                                          l_journal_id     AS result
                                  ) row;

                    -- связываем документы
                    UPDATE docs.doc
                    SET docs_ids   = array_append(docs_ids, l_journal_id),
                        lastupdate = now(),
                        history    = coalesce(history, '[]') :: JSONB || l_json::JSONB
                    WHERE id = v_arv.id;

                    -- если счет на момент расчет уже оплачен (a.jaak = 0)тогда вызываем оплату маловероятных (Калле 19.10.2023)
                    IF v_arv.jaak = 0
                    THEN
                        FOR v_tasud IN
                            SELECT at.doc_tasu_id
                            FROM docs.arvtasu at
                            WHERE at.doc_arv_id = v_arv.id
                              AND kpv > l_seisuga
                              AND at.status < 3
                            LOOP
                                RAISE NOTICE 'tasumine ebatoenalised v_tasud.doc_tasu_id %', v_tasud.doc_tasu_id;
                                PERFORM docs.tasumine_ebatoenaolised(v_tasud.doc_tasu_id, v_arv.id, l_user_id);
                            END LOOP;
                    END IF;

                END IF;

                result = l_journal_id;
                error_message = 'Koostatud ebatõenäolised lausend, arve nr. ' || ltrim(rtrim(v_arv.number));
                RETURN NEXT;
            END IF;
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

ALTER FUNCTION docs.ebatoenaolised( INTEGER, DATE )
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.ebatoenaolised(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.ebatoenaolised(INTEGER, DATE) TO dbpeakasutaja;

/*
SELECT docs.ebatoenaolised(id, current_date::DATE)
from ou.rekv where parentid = 119
*/

