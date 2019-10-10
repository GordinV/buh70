DROP FUNCTION IF EXISTS docs.create_new_order(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.create_new_order(IN user_id INTEGER,
                                                 IN params JSONB,
                                                 OUT error_code INTEGER,
                                                 OUT result INTEGER,
                                                 OUT doc_type_id TEXT,
                                                 OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_arv_id     INTEGER = params ->> 'arv_id';
    l_dok        TEXT    = coalesce((params ->> 'dok') :: TEXT, 'SORDER');
    korder_id    INTEGER;
    v_arv        RECORD;
    json_object  JSONB;
    v_params     RECORD;
    json_korder1 JSONB;
    l_kassa_id   INTEGER;
    l_laps_id    INTEGER = (SELECT parentid
                            FROM lapsed.liidestamine
                            WHERE docid = l_arv_id);

BEGIN

    -- выборка из "документа"
    SELECT a.*,
           isik.nimetus AS nimi,
           isik.aadress
           INTO v_arv
    FROM docs.doc d
             INNER JOIN docs.arv a ON a.parentid = d.id
             INNER JOIN libs.asutus isik ON isik.id = a.asutusid
    WHERE d.id = l_arv_id;

    IF l_arv_id IS NULL OR v_arv.id IS NULL OR empty(l_arv_id)
    THEN
        error_message = 'Arve puudub või vale parametrid';
        error_code = 6;
        result = 0;
        RETURN;
    END IF;

    IF v_arv.jaak <= 0
    THEN
        result = 0;
        error_code = 0;
        error_message = 'Arve jaak <= 0';
        RETURN;
    END IF;

    -- создаем параметры для платежки

    l_kassa_id = (SELECT id
                  FROM ou.aa
                  WHERE kassa = 0
                    AND parentid = v_arv.rekvid
                  ORDER BY default_
                  LIMIT 1);

    json_korder1 = array_to_json((SELECT array_agg(row_to_json(m1.*))
                                  FROM (SELECT 0          AS id,
                                               (SELECT id
                                                FROM libs.nomenklatuur n
                                                WHERE rekvid = v_arv.rekvid
                                                  AND dok IN (l_dok)
                                                ORDER BY id DESC
                                                LIMIT 1)  AS nomid,
                                               a1.kood1,
                                               a1.kood2,
                                               a1.kood3,
                                               a1.kood4,
                                               a1.kood5,
                                               a1.konto,
                                               a1.tp,
                                               a1.tunnus,
                                               a1.proj,
                                               v_arv.jaak AS summa
                                        FROM docs.arv1 a1
                                        WHERE a1.parentid = v_arv.id
                                        ORDER BY kood5, kood2 DESC, kood1 DESC
                                        LIMIT 1
                                       ) AS m1
    ));

    SELECT 0                                                                            AS id,
           NULL                                                                         AS doklausid,
           v_arv.asutusid                                                               AS asutusid,
           v_arv.nimi                                                                   AS nimi,
           v_arv.aadress,
           l_kassa_id                                                                   AS kassaid,
           v_arv.parentid                                                               AS arvid,
           CASE
               WHEN v_arv.liik = 0
                   THEN 1
               ELSE 2 END                                                               AS TYYP,
           v_arv.jaak                                                                   AS summa,
           date()                                                                       AS kpv,
           NULL                                                                         AS selg,
           NULL                                                                         AS muud,
           l_laps_id                                                                    AS lapsid,
           json_korder1                                                                 AS "gridData"
           INTO v_params;

    SELECT row_to_json(row) INTO json_object
    FROM (SELECT 0        AS id,
                 v_params AS data) row;

    SELECT docs.sp_salvesta_korder(json_object :: JSON, user_id, v_arv.rekvid) INTO korder_id;

    doc_type_id = CASE WHEN v_arv.liik = 0 THEN 'SORDER' ELSE 'VORDER' END;

    IF korder_id IS NOT NULL AND korder_id > 0
    THEN
        result = korder_id;
        RAISE NOTICE 'order saved korder_id %', korder_id;
    ELSE
        result = 0;
        error_message = 'Dokumendi koostamise viga';
        error_code = 1;
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
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.create_new_order(INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.create_new_order(INTEGER, JSONB) TO dbpeakasutaja;


/*
SELECT docs.create_new_mk(2477, '{"arv_id":1245465,"dok":"SMK"}')
select * from docs.arv where rekvid = 63 order by id desc limit 1

select * from docs.doc where id = 1245484

select * from docs.mk where parentid = 1245484

select * from docs.mk1 where parentid = 283417

select * from docs.arvtasu where doc_arv_id = 1245465

select d.*, 0 as valitud from cur_mk d
                where d.rekvId = 63
                and coalesce(docs.usersRigths(d.id, 'select', 2477),true)

select * from libs.library where id = 55
*/