-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS docs.koosta_teatis(INTEGER, DATE);

CREATE OR REPLACE FUNCTION docs.koosta_teatis(IN user_id INTEGER,
                                              IN l_kpv DATE DEFAULT current_date,
                                              OUT error_code INTEGER,
                                              OUT result INTEGER,
                                              OUT doc_type_id TEXT,
                                              OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid    INTEGER = (SELECT rekvid
                           FROM ou.userid u
                           WHERE id = user_id
                           LIMIT 1);

    v_arv       RECORD;
    v_teatis    RECORD;
    json_object JSONB;

    l_status    INTEGER;
    DOC_STATUS  INTEGER = 1; -- только активные услуги
    l_teatis_id INTEGER;
    l_count     INTEGER = 0;
    l_sisu      TEXT;
BEGIN
    doc_type_id = 'TEATIS';
    -- will return docTypeid of new doc

    -- делаем выборку неоплаченных счетов на дату

    FOR v_arv IN
        SELECT array_to_string(array_agg(d.id), ',')                                                   AS docs,
               sum(a.jaak)                                                                             AS volg,
               a.asutusid,
               array_agg('Arve nr.:' || a.number::TEXT || ' kuupäev:' || to_char(a.kpv, 'DD.MM.YYYY')) AS selg
        FROM docs.doc d
                 INNER JOIN docs.arv a ON a.parentid = d.id
                 INNER JOIN lapsed.liidestamine l ON l.docid = d.id
        WHERE a.jaak > 0
          AND (a.tahtaeg IS NULL
            OR a.tahtaeg < l_kpv)
          AND d.rekvid = l_rekvid
          AND a.asutusid NOT IN (SELECT t.asutusid
                                 FROM docs.teatis t
                                          INNER JOIN docs.doc dd ON dd.id = t.parentid
                                 WHERE dd.rekvid = l_rekvid
                                   AND dd.status <> 3
                                   AND t.kpv = l_kpv)
        GROUP BY a.asutusid
        LOOP
            -- ищем требование. если есть и датировано сегодня - то осключаем (не нужны повторы)
            -- критерий

            SELECT d.id,
                   d.status
                   INTO l_teatis_id, l_status
            FROM docs.doc d
                     INNER JOIN docs.teatis t ON t.parentid = d.id
            WHERE t.asutusid = v_arv.asutusid
              AND t.kpv = l_kpv
              AND d.rekvid = l_rekvid
              AND d.status <> 3
            LIMIT 1;

            IF l_teatis_id IS NULL OR l_status <> 1
            THEN

                -- продолжаем расчет
                l_sisu = 'Teavitame Teid arve(te)st, mis on jäänud maksetähtajaks tasumata: ' ||
                         array_to_string(v_arv.selg, ','):: TEXT || '.'
                             'Palume tasuda summa ' || v_arv.volg::TEXT;


                SELECT v_arv.asutusid AS asutusid,
                       v_arv.docs     AS docs,
                       l_sisu         AS sisu
                       INTO v_teatis;

                -- подготавливаем параметры для сохранения
                SELECT row_to_json(row) INTO json_object
                FROM (SELECT coalesce(l_teatis_id, 0)      AS id,
                             (SELECT to_jsonb(v_teatis.*)) AS data) row;

                SELECT docs.sp_salvesta_teatis(json_object :: JSONB, user_id, l_rekvid) INTO l_teatis_id;

                IF l_teatis_id > 0
                THEN
                    l_count = l_count + 1;
                END IF;

            END IF;

        END LOOP;


    -- проверка

    IF l_count > 0
    THEN
        result = l_count ;
    ELSE
        result = 0;
        error_message = 'Dokumendid ei leidnud';
        error_code = 0;
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
END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.koosta_teatis(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.koosta_teatis(INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.koosta_teatis(INTEGER, DATE) TO arvestaja;


/*
select docs.koosta_teatis(70,'2019-12-15')

 */