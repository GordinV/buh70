-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS hooldekodu.koosta_hoo_mk(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION hooldekodu.koosta_hoo_mk(IN user_id INTEGER,
                                                    IN l_isik_id INTEGER,
                                                    IN l_kpv DATE DEFAULT current_date,
                                                    OUT error_code INTEGER,
                                                    OUT result INTEGER,
                                                    OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid       INTEGER = (SELECT rekvid
                              FROM ou.userid u
                              WHERE id = user_id
                              LIMIT 1);

    l_mk_id        INTEGER;
    v_mk1          RECORD;
    v_leping       RECORD;
    v_params       RECORD;
    json_object    JSONB;
    l_error        TEXT; -- извещение о том, что пошло не так
    l_db_konto     TEXT    = '100100'; -- дебетовая (банк) сторона
    l_dokprop_id   INTEGER;
    l_pank_id      INTEGER;
    l_aa           TEXT;
    l_nom_id       INTEGER;
    json_mk1       JSONB   = '[]'::JSONB;
    l_rahasaaja_id INTEGER = l_isik_id;
    l_tunnus       TEXT    = CASE WHEN l_rekvid = 64 THEN '4023' ELSE '2101' END;
BEGIN

    IF l_isik_id IS NULL
    THEN
        -- контр-анет не найден, выходим
        result = 0;
        error_message = 'Puudub kontragent';
        error_code = 1;
        RETURN;
    END IF;


    SELECT hl.id,
           hl.rekvid                                 AS rekv_id,
           j.taskuraha_kov,
           j.pension15,
           a.id                                      AS asutusid,
           a.properties -> 'asutus_aa' -> 0 ->> 'aa' AS maksja_aa,
           hl.tunnus,
           hl.rahasaaja_id,
           hl.aa
    INTO v_leping
    FROM hooldekodu.hooleping hl
             INNER JOIN libs.asutus a ON a.id = hl.isikid
             INNER JOIN hooldekodu.hoojaak j ON j.isikid = a.id
    WHERE hl.isikid = l_isik_id
      AND hl.algkpv <= l_kpv
      AND (hl.loppkpv IS NULL OR hl.loppkpv >= l_kpv)
      AND hl.rekvid = l_rekvid;

    IF (v_leping IS NULL OR (empty(v_leping.taskuraha_kov) AND empty(v_leping.pension15)))
    THEN
        -- сальдо карманных нет
        result = 0;
        error_message = 'Taskuraha saldo = 0';
        error_code = 1;
        RETURN;

    END IF;

-- dokprop_id
    IF (SELECT count(d.id)
        FROM libs.dokprop d
                 INNER JOIN libs.library l ON l.id = d.parentid
        WHERE d.rekvid = v_leping.rekv_id
          AND l.kood = 'VMK'
       ) <= 1
    THEN
        l_dokprop_id = (SELECT D.id
                        FROM libs.dokprop D
                                 INNER JOIN libs.library l ON l.id = d.parentid
                        WHERE d.rekvid = v_leping.rekv_id
                          AND l.kood = 'VMK');
    ELSE
        -- пытаемся опредеоить по расч счету
        SELECT konto, arve, id
        INTO l_db_konto, l_aa, l_pank_id
        FROM ou.aa
        WHERE parentid = v_leping.rekv_id
          AND kassa = 1
        ORDER BY default_ DESC
        LIMIT 1;

        IF l_db_konto IS NOT NULL
        THEN
            -- ишем по конто
            l_dokprop_id = (SELECT D.id
                            FROM libs.dokprop D
                                     INNER JOIN libs.library l ON l.id = d.parentid
                            WHERE d.rekvid = v_leping.rekv_id
                              AND l.kood = 'VMK'
                              AND d.details::JSONB ->> 'konto' = l_db_konto
                            ORDER BY id DESC
                            LIMIT 1);
        END IF;
    END IF;

    IF l_dokprop_id IS NULL
    THEN
        -- берем последний
        l_dokprop_id = (SELECT D.id
                        FROM libs.dokprop D
                                 INNER JOIN libs.library l ON l.id = d.parentid
                        WHERE d.rekvid = v_leping.rekv_id
                          AND l.kood = 'VMK'
                        ORDER BY id DESC
                        LIMIT 1);
    END IF;

    l_nom_id = (SELECT id
                FROM libs.nomenklatuur n
                WHERE rekvid = l_rekvId
                  AND status < 3
                  AND dok IN ('VMK')
                ORDER BY kood
                        , id DESC
                LIMIT 1);

    IF l_nom_id IS NULL
    THEN
        error_code = 9;
        error_message = 'Viga, puudub nomenklatuur';
        RAISE EXCEPTION '%',error_message;
    END IF;

    l_aa = (COALESCE((SELECT (e.element ->> 'aa') :: VARCHAR(20) AS aa
                      FROM libs.asutus a,
                           json_array_elements(CASE
                                                   WHEN (a.properties ->> 'asutus_aa') IS NULL
                                                       THEN '[]'::JSON
                                                   ELSE (a.properties -> 'asutus_aa') :: JSON END) AS e (ELEMENT)
                      WHERE a.id = l_isik_id
                      LIMIT 1
                     ), ''));
    -- если расчетный счет задан в договоре. то применяем его
    -- и если указан получатель средств

    IF (v_leping.aa IS NOT NULL AND NOT empty(v_leping.aa) AND v_leping.rahasaaja_id IS NOT NULL AND
        NOT empty(v_leping.rahasaaja_id))
    THEN

        l_aa = v_leping.aa;
        l_rahasaaja_id = v_leping.rahasaaja_id;
    END IF;

    IF (v_leping.taskuraha_kov > 0)
    THEN
        -- создаем платежку
        SELECT 0                      AS id,
               l_nom_id               AS nomid,
               l_rahasaaja_id         AS asutusid,
               v_leping.taskuraha_kov AS summa,
               l_aa                   AS aa,
               '20356001'             AS konto,
               '10200'                AS kood1,
               'LE-P'                 AS kood2,
               '4131'                 AS kood5, -- Поправлено 29.01.24 В.Б
               'Taskuraha'            AS kood4,
               '800699'               AS tp,
               l_tunnus               AS tunnus -- VB 25.07.2023
        INTO v_mk1;

        json_mk1 = '[]'::JSONB || array_to_json((SELECT array_agg(row_to_json(v_mk1))))::JSONB;
    END IF;

    IF (coalesce(v_leping.pension15, 0) > 0)
    THEN
        SELECT 0                  AS id,
               l_nom_id           AS nomid,
               l_rahasaaja_id     AS asutusid,
               v_leping.pension15 AS summa,
               l_aa               AS aa,
               '20363002'         AS konto,
               '10200'            AS kood1,
               '80'               AS kood2,
               '2586'             AS kood5,
               '800699'           AS tp,
               l_tunnus           AS tunnus
        INTO v_mk1;
        json_mk1 = json_mk1::JSONB || array_to_json((SELECT array_agg(row_to_json(v_mk1))))::JSONB;

    END IF;


    SELECT 0            AS id,
           l_dokprop_id AS doklausid,
           l_pank_id    AS aa_id,
           l_isik_id    AS kasusaaja_id,
           1            AS opt,
           l_kpv        AS kpv,
           l_kpv        AS maksepaev,
           'Taskuraha'  AS selg,
           NULL         AS muud,
           json_mk1     AS "gridData"
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT 0        AS id,
                 v_params AS data) row;

    SELECT docs.sp_salvesta_mk(json_object :: JSON, user_id, l_rekvId) INTO l_mk_id;


    IF l_mk_id IS NOT NULL AND l_mk_id > 0
    THEN
        -- lausend
        PERFORM docs.gen_lausend_vmk(l_mk_id, user_id);
    END IF;
    result = l_mk_id;
    RETURN;
END ;
$BODY$ LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION hooldekodu.koosta_hoo_mk(INTEGER, INTEGER, DATE) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.koosta_hoo_mk(INTEGER, INTEGER, DATE) TO hkametnik;


/*
SELECT * FROM LIBS.ASUTUS WHERE REgkood = '10000000 '

SELECT hooldekodu.koosta_hoo_mk(5175, 20225, '2023-07-31')


select * from ou.userid where kasutaja = 'vlad' and rekvid = 132

 */

