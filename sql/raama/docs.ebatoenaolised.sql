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
    v_arv1         RECORD;
    l_json         JSONB;
    l_json_details JSONB          = '[]'::JSONB;
    v_params       RECORD;
    l_user_id      INTEGER; -- Иимя пользователя от чьего имени будет создана проводка
    userName       TEXT           = 'temp'; -- имя пользователя, который выполняет таску
    l_journal_id   INTEGER;
    l_summa        NUMERIC(14, 2) = 0;
BEGIN
    -- формируем список просроченных счетов (50%)
    FOR v_arv IN
        SELECT parentid                                          AS id,
               a.id                                              AS arv_id,
               d.rekvid                                          AS rekv_id,
               a.tahtaeg                                         AS tahtaeg,
               a.jaak,
               a.asutusid,
               a.number,
               CASE
                   WHEN (a.tahtaeg + 90) > make_date(year(a.kpv), 03, 31) AND
                        (a.tahtaeg + 90) <= make_date(year(a.kpv), 06, 30) THEN make_date(year(a.kpv), 06, 30)
                   WHEN (a.tahtaeg + 90) > make_date(year(a.kpv), 06, 30) AND
                        (a.tahtaeg + 90) <= make_date(year(a.kpv), 09, 30) THEN make_date(year(a.kpv), 09, 30)
                   WHEN (a.tahtaeg + 90) > make_date(year(a.kpv), 09, 30) AND
                        (a.tahtaeg + 90) <= make_date(year(a.kpv), 12, 31) THEN make_date(year(a.kpv), 12, 31)
                   ELSE
                       make_date(year(a.kpv) + 1, 03, 31)
                   END                                           AS lausendi_period,
               (a.properties ->> 'ebatoenaolised_1_id')::INTEGER AS ebatoenaolised_1_id,
               (a.properties ->> 'ebatoenaolised_2_id')::INTEGER AS ebatoenaolised_2_id
        FROM docs.doc d
                 INNER JOIN docs.arv a ON a.parentid = d.id
        WHERE (d.rekvid = l_rekv_id OR l_rekv_id IS NULL)
          AND a.jaak > 0
          AND year(a.kpv) >= 2020               -- начиная с 2020 года
          AND (a.properties ->> 'tyyp') IS NULL -- исключить предоплатные счета
          AND (l_kpv - a.tahtaeg) > 3 * 30      -- просрочен более чем на 4 месяца
          AND ((a.properties ->> 'ebatoenaolised_1_id') IS NULL -- помметка, что на счет начислено списание
            OR (a.properties ->> 'ebatoenaolised_2_id') IS NULL)
          AND a.liik = 0 -- только доходы
        LOOP
            l_json_details = '[]'::JSONB; -- инициализируем массив под проводку

            l_user_id = (SELECT id FROM ou.userid WHERE kasutaja::TEXT = userName AND rekvid = v_arv.rekv_id LIMIT 1);
            -- ищем пользователя в этом учреждении

            -- расчет суммы
            l_summa = (v_arv.jaak * 0.5)::NUMERIC(14, 2);
            IF v_arv.ebatoenaolised_1_id IS NOT NULL AND v_arv.ebatoenaolised_1_id > 0 and exists(select id from cur_journal where id = v_arv.ebatoenaolised_1_id)
            THEN
                -- расчет суммы
                l_summa = v_arv.jaak - coalesce((SELECT sum(j1.summa)
                                                 FROM docs.journal1 j1
                                                          INNER JOIN docs.journal j ON j.id = j1.parentid
                                                 WHERE j.parentid IN (coalesce(v_arv.ebatoenaolised_1_id, 0),
                                                                      coalesce(v_arv.ebatoenaolised_2_id, 0))));
            END IF;

            IF l_summa > 0
            THEN
                -- делаем проводку

                --    l_json_details = '';
                l_json_details = l_json_details || to_jsonb(row)
                                 FROM (SELECT 0        AS id,
                                              l_summa  AS summa, -- 50% от требования
                                              '605030' AS deebet,
                                              '103009' AS kreedit,
                                              a1.kood1,
                                              a1.kood2,
                                              a1.kood3,
                                              a1.tunnus,
                                              a1.konto,
                                              '608',
                                              a1.tp    AS lisa_d,
                                              a1.tp    AS lisa_k
                                       FROM docs.arv1 a1
                                       WHERE a1.parentid = v_arv.arv_id
                                       ORDER BY summa DESC
                                       LIMIT 1
                                      ) row;

                SELECT 0                               AS id,
                       'JOURNAL'                       AS doc_type_id,
                       v_arv.lausendi_period           AS kpv,
                       'Ebatõenäolised nõuded'         AS selg,
                       v_arv.Asutusid,
                       'Arve nr.' || v_arv.number::TEXT AS dok,
                       l_json_details                  AS "gridData"
                       INTO v_params;

                l_json = to_json(row)
                         FROM (SELECT 0        AS id,
                                      v_params AS data) row;

                l_journal_id = docs.sp_salvesta_journal(l_json :: JSON, l_user_id, v_arv.rekv_Id);
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

END;

$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

ALTER FUNCTION docs.ebatoenaolised( INTEGER, DATE )
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.ebatoenaolised(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.ebatoenaolised(INTEGER, DATE) TO dbpeakasutaja;

--SELECT docs.ebatoenaolised(69, '2020-12-31'::DATE);

/*


SELECT
  error_code,
  result,
  error_message
FROM docs.gen_lausend_smk(1016,1);

select * from libs.dokprop

select * from libs.library where library = 'DOK'
-- 7

insert into libs.dokprop (parentid, registr, selg, details, tyyp)
	values (7, 1, 'Sorder', '{"konto":"100000"}'::jsonb, 1 )

update docs.korder1 set doklausid = 4 where tyyp = 1
*/
