-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.koosta_ettemaksu_arve(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.koosta_ettemaksu_arve(IN user_id INTEGER,
                                                        IN l_laps_id INTEGER,
                                                        IN l_kpv DATE DEFAULT current_date,
                                                        OUT error_code INTEGER,
                                                        OUT result INTEGER,
                                                        OUT doc_type_id TEXT,
                                                        OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_asutus_id     INTEGER = (SELECT asutusid
                               FROM lapsed.vanemad v
                               WHERE v.parentid = l_laps_id
                                 AND v.staatus <> 3
                               ORDER BY (coalesce(properties ->> 'arved', 'ei')) DESC
                               LIMIT 1);
    l_nom_id        INTEGER;
    l_doklausend_id INTEGER;
    l_details       JSON;
    l_liik          INTEGER = 0;
    v_kaart         RECORD;
    v_arv_details   RECORD;
    json_object     JSONB;
    l_json_arve     JSON;
    json_arvread    JSONB   = '[]';
    v_nom           RECORD;

    l_tp            TEXT    = '800699'; -- (SELECT tp FROM libs.asutus a WHERE id = l_asutus_id);

    l_rekvid        INTEGER = (SELECT rekvid
                               FROM ou.userid u
                               WHERE id = user_id
                               LIMIT 1);
    l_arv_id        INTEGER;
BEGIN

    -- читаем табель и создаем детали счета
    FOR v_kaart IN
        SELECT lk.nomid,
               1                                                       AS kogus,
               coalesce(n.hind, 0)                                     AS hind,
               1 * coalesce(n.hind, 0)                                 AS kbmta,

               coalesce((n.properties ->> 'vat')::NUMERIC, 0)::NUMERIC AS vat,
               (n.properties::JSONB ->> 'konto')::VARCHAR(20)          AS konto,
               (n.properties::JSONB ->> 'projekt')::VARCHAR(20)        AS projekt,
               (n.properties::JSONB ->> 'tunnus')::VARCHAR(20)         AS tunnus,
               (n.properties::JSONB ->> 'tegev')::VARCHAR(20)          AS tegev,
               (n.properties::JSONB ->> 'allikas')::VARCHAR(20)        AS allikas,
               (n.properties::JSONB ->> 'rahavoog')::VARCHAR(20)       AS rahavoog,
               (n.properties::JSONB ->> 'artikkel')::VARCHAR(20)       AS artikkel

        FROM lapsed.lapse_kaart lk
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
        WHERE lk.parentid = l_laps_id
        and lk.staatus <> 3
        and (lk.properties ->>'kas_ettemaks')::boolean 
        LOOP
            -- формируем строку
            json_arvread = json_arvread || (SELECT row_to_json(row)
                                            FROM (SELECT v_kaart.nomid                                         AS nomid,
                                                         v_kaart.kogus                                         AS kogus,
                                                         v_kaart.hind                                          AS hind,
                                                         v_kaart.kbmta                                         AS kbmta,
                                                         (v_kaart.kbmta * (v_kaart.vat / 100))                 AS kbm,
                                                         (v_kaart.kbmta * (v_kaart.vat / 100)) + v_kaart.kbmta AS summa,
                                                         v_kaart.tegev                                         AS kood1,
                                                         v_kaart.allikas                                       AS kood2,
                                                         v_kaart.rahavoog                                      AS kood3,
                                                         v_kaart.artikkel                                      AS kood5,
                                                         v_kaart.konto                                         AS konto,
                                                         v_kaart.tunnus,
                                                         v_kaart.projekt,
                                                         l_tp                                                  AS tp) row) :: JSONB;

        END LOOP;

    -- создаем параметры
    l_json_arve = (SELECT to_json(row)
                   FROM (SELECT 0               AS id,
                                l_doklausend_id AS doklausid,
                                l_liik          AS liik,
                                l_kpv           AS kpv,
                                l_kpv + 15      AS tahtaeg,
                                l_asutus_id     AS asutusid,
                                l_laps_id       AS lapsid,
                                json_arvread    AS "gridData") row);

    -- подготавливаем параметры для создания счета
    SELECT row_to_json(row) INTO json_object
    FROM (SELECT 0 AS id, l_json_arve AS data) row;

    SELECT docs.sp_salvesta_arv(json_object :: JSON, user_id, l_rekvid) INTO l_arv_id;

    -- проверка

    IF l_arv_id IS NOT NULL AND l_arv_id > 0
    THEN
        doc_type_id = 'ARV'; -- will return docTypeid of new doc
        result = l_arv_id;
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
END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.koosta_ettemaksu_arve(INTEGER, INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.koosta_ettemaksu_arve(INTEGER, INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.koosta_ettemaksu_arve(INTEGER, INTEGER, DATE) TO arvestaja;


/*
select lapsed.koosta_arve_taabeli_alusel(70, 16)

select * from lapsed.laps where staatus = 1

select * from lapsed.lapse_taabel

update lapsed.lapse_taabel set staatus = 1 where id = 5
 */