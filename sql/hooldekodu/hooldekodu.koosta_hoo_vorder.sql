-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS hooldekodu.koosta_hoo_vorder(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION hooldekodu.koosta_hoo_vorder(IN user_id INTEGER,
                                                        IN l_isik_id INTEGER,
                                                        IN l_kpv DATE DEFAULT current_date,
                                                        OUT error_code INTEGER,
                                                        OUT result INTEGER,
                                                        OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid      INTEGER     = (SELECT rekvid
                                 FROM ou.userid u
                                 WHERE id = user_id
                                 LIMIT 1);

    l_korder_id   INTEGER;
    v_korder1     RECORD;
    v_leping      RECORD;
    v_params      RECORD;
    json_object   JSONB;
    l_error       TEXT; -- извещение о том, что пошло не так
    l_dokprop_id  INTEGER;
    l_kassa_id    INTEGER;
    l_aa          TEXT;
    l_nom_id      INTEGER;
    json_korder   JSONB       = '[]'::JSONB;
    DOC_TYPE_CODE VARCHAR(20) = 'VORDER';
    l_tunnus       TEXT    = case when l_rekvid = 64 then '4023' else '2101' end;
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
           hl.rekvid AS rekv_id,
           j.taskuraha_kov,
           a.id      AS asutusid,
           a.nimetus AS nimi,
           a.aadress AS aadress,
           hl.tunnus,
           j.pension15
    INTO v_leping
    FROM hooldekodu.hooleping hl
             INNER JOIN libs.asutus a ON a.id = hl.isikid
             INNER JOIN hooldekodu.hoojaak j ON j.isikid = a.id
    WHERE hl.isikid = l_isik_id
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

    SELECT id
    INTO l_kassa_id
    FROM ou.aa
    WHERE parentid = v_leping.rekv_id
      AND kassa = 0
    ORDER BY default_ DESC
    LIMIT 1;


-- dokprop_id
    IF (SELECT count(d.id)
        FROM libs.dokprop d
                 INNER JOIN libs.library l ON l.id = d.parentid
        WHERE d.rekvid = v_leping.rekv_id
          AND l.kood = DOC_TYPE_CODE
       ) <= 1
    THEN
        l_dokprop_id = (SELECT D.id
                        FROM libs.dokprop D
                                 INNER JOIN libs.library l ON l.id = d.parentid
                        WHERE d.rekvid = v_leping.rekv_id
                          AND l.kood = DOC_TYPE_CODE);

    END IF;

    IF l_dokprop_id IS NULL
    THEN
        -- берем последний
        l_dokprop_id = (SELECT D.id
                        FROM libs.dokprop D
                                 INNER JOIN libs.library l ON l.id = d.parentid
                        WHERE d.rekvid = v_leping.rekv_id
                          AND l.kood = DOC_TYPE_CODE
                        ORDER BY id DESC
                        LIMIT 1);
    END IF;

    -- создаем ордер

    IF (v_leping.taskuraha_kov > 0)
    THEN

        l_nom_id = (SELECT id
                    FROM libs.nomenklatuur n
                    WHERE rekvid = l_rekvId
                      AND status < 3
                      AND dok IN (DOC_TYPE_CODE)
                      AND ltrim(rtrim((properties ->> 'konto'))) = '20356001'
                    ORDER BY kood
                            , id DESC
                    LIMIT 1);

        SELECT 0                      AS id,
               l_nom_id               AS nomid,
               v_leping.taskuraha_kov AS summa,
               '20356001'             AS konto,
               '10200'                AS kood1,
               'LE-P'                 AS kood2,
               '4138'                 AS kood5,
               '800699'               AS tp,
               l_tunnus                 AS tunnus
        INTO v_korder1;

        json_korder = json_korder::JSONB || array_to_json((SELECT array_agg(row_to_json(v_korder1))))::JSONB;

    END IF;

    IF coalesce(v_leping.pension15, 0) > 0
    THEN
        -- вторая строка с собственными карманными деньгами

        l_nom_id = (SELECT id
                    FROM libs.nomenklatuur n
                    WHERE rekvid = l_rekvId
                      AND status < 3
                      AND dok IN (DOC_TYPE_CODE)
                      AND ltrim(rtrim((properties ->> 'konto'))) = '20363002'
                    ORDER BY kood
                            , id DESC
                    LIMIT 1);

        SELECT 0                  AS id,
               l_nom_id           AS nomid,
               v_leping.pension15 AS summa,
               '20363002'         AS konto,
               '10200'            AS kood1,
               '80'             AS kood2,
               '2586'             AS kood5,
               '800699'           AS tp,
               l_tunnus             AS tunnus
        INTO v_korder1;

        json_korder = json_korder::JSONB || array_to_json((SELECT array_agg(row_to_json(v_korder1))))::JSONB;

    END IF;


    SELECT 0                                                             AS id,
           l_dokprop_id                                                  AS doklausid,
           (docs.sp_get_number(l_rekvid::INTEGER, 'VORDER'::TEXT,
                               year(l_kpv), NULL::INTEGER))::VARCHAR(20) AS number,
           l_kassa_id                                                    AS kassa_id,
           l_isik_id                                                     AS asutusid,
           2                                                             AS tyyp,
           ''                                                            AS dokument,
           v_leping.taskuraha_kov                                        AS summa,
           'Taskuraha'                                                   AS selg,
           v_leping.nimi                                                 AS nimi,
           v_leping.aadress                                              AS aadress,
           'Taskuraha'                                                   AS alus,
           l_kpv                                                         AS kpv,
           NULL                                                          AS muud,
           json_korder                                                   AS "gridData"
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT 0        AS id,
                 v_params AS data) row;

    SELECT docs.sp_salvesta_korder(json_object :: JSON, user_id, l_rekvId) INTO l_korder_id;


    IF l_korder_id IS NOT NULL AND l_korder_id > 0
    THEN
        -- lausend
        PERFORM docs.gen_lausend_vorder(l_korder_id, user_id);
    END IF;
    result = l_korder_id;
    RETURN;
END ;
$BODY$ LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION hooldekodu.koosta_hoo_vorder(INTEGER, INTEGER, DATE) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.koosta_hoo_vorder(INTEGER, INTEGER, DATE) TO hkametnik;


/*

SELECT hooldekodu.koosta_hoo_vorder(5175, 21639, '2023-07-07')


select * from ou.userid where kasutaja = 'vlad' and rekvid = 132

 */

