DROP FUNCTION IF EXISTS lapsed.koosta_mk_arve_alusel(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.koosta_mk_arve_alusel(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.koosta_mk_arve_alusel(IN user_id INTEGER, IN l_arv_id INTEGER,
                                                        IN l_kpv DATE DEFAULT current_date,
                                                        OUT error_code INTEGER,
                                                        OUT result INTEGER,
                                                        OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_mk_id      INTEGER;
    v_arv        RECORD;
    json_object  JSONB;
    l_error      TEXT; -- извещение о том, что пошло не так
    l_db_konto   TEXT = '100100'; -- дебетовая (банк) сторона
    l_dokprop_id INTEGER;
BEGIN

    SELECT d.id,
           d.rekvid                                       AS rekv_id,
           a.jaak,
           a.asutusid,
           a.properties::JSONB ->> 'viitenr'              AS viitenr,
           a.properties::JSONB ->> 'aa'                   AS aa,
           a.number::TEXT                                 AS number,
           maksja.properties -> 'asutus_aa' -> 0 ->> 'aa' AS maksja_aa
           INTO v_arv
    FROM docs.doc d
             INNER JOIN docs.arv a ON d.id = a.parentid
             INNER JOIN libs.asutus maksja ON maksja.id = a.asutusid
    WHERE d.id = l_arv_id;

-- dokprop_id
    IF (SELECT count(d.id)
        FROM libs.dokprop d
                 INNER JOIN libs.library l ON l.id = d.parentid
        WHERE d.rekvid = v_arv.rekv_id
          AND l.kood = 'SMK'
       ) <= 1
    THEN
        l_dokprop_id = (SELECT D.id
                        FROM libs.dokprop D
                                 INNER JOIN libs.library l ON l.id = d.parentid
                        WHERE d.rekvid = v_arv.rekv_id
                          AND l.kood = 'SMK');
    ELSE
        -- пытаемся опредеоить по расчю счету
        l_db_konto = (SELECT konto
                      FROM ou.aa
                      WHERE parentid = v_arv.rekv_id
                        AND kassa = 1
                        AND arve::TEXT = v_arv.aa
                      ORDER BY default_ DESC
                      LIMIT 1
        );

        IF l_db_konto IS NOT NULL
        THEN
            -- ишем по конто
            l_dokprop_id = (SELECT D.id
                            FROM libs.dokprop D
                                     INNER JOIN libs.library l ON l.id = d.parentid
                            WHERE d.rekvid = v_arv.rekv_id
                              AND l.kood = 'SMK'
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
                        WHERE d.rekvid = v_arv.rekv_id
                          AND l.kood = 'SMK'
                        ORDER BY id DESC
                        LIMIT 1);
    END IF;

    -- создаем параметры для расчета платежкм
    SELECT row_to_json(row) INTO json_object
    FROM (SELECT v_arv.id                    AS arv_id,
                 v_arv.asutusid              AS maksja_id,
                 l_dokprop_id                AS dokprop_id,
                 v_arv.viitenr               AS viitenumber,
                 'Arve nr.:' || v_arv.number AS selg,
                 current_date                AS kpv,
                 v_arv.aa                    AS aa,
                 v_arv.maksja_aa             AS maksja_arve,
                 v_arv.jaak                  AS summa,
                 l_kpv                       AS kpv
         ) ROW;

    -- создаем платежку
    SELECT fnc.result, fnc.error_message INTO l_mk_id, l_error
    FROM docs.create_new_mk(user_id, json_object) fnc;

    IF l_mk_id IS NOT NULL AND l_mk_id > 0
    THEN
        -- lausend
        PERFORM docs.gen_lausend_smk(l_mk_id, user_id);
    END IF;
    result = l_mk_id;
    RETURN;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
            RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.koosta_mk_arve_alusel(INTEGER,INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.koosta_mk_arve_alusel(INTEGER,INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.koosta_mk_arve_alusel(INTEGER,INTEGER, DATE) TO arvestaja;


/*
-- 1616795

SELECT * from lapsed.koosta_mk_arve_alusel(70,1616793)


doc_aa_id 11,  user_rekvid 63
[2019-12-10 20:52:57] [00000] l_tasu_summa 7.0000, l_kpv 2019-12-10
[2019-12-10 20:52:57] [00000] l_tasu_summa 7.0000, l_kpv 2019-12-10
[2019-12-10 20:52:57] [00000] l_mk_id 1616718, l_error <NULL>, v_arv.id 1616712
[2019-12-10 20:52:57] [00000] l_tasu_jaak 0.00
*/