-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.koosta_paevad_taabel(JSONB, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.koosta_paevad_taabel(IN params JSONB,
                                                       IN user_id INTEGER,
                                                       OUT error_code INTEGER,
                                                       OUT result INTEGER,
                                                       OUT doc_type_id TEXT,
                                                       OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid       INTEGER = (SELECT rekvid
                              FROM ou.userid u
                              WHERE id = user_id
                              LIMIT 1);
    l_kpv          DATE    = coalesce((params ->> 'kpv')::DATE, current_date);
    l_grupp_id     INTEGER = (params ->> 'grupp_id')::INTEGER;
    l_json         JSONB;
    v_lapsed       RECORD;
    v_row          RECORD;
    l_json_details JSONB   = '[]'::JSONB;
    v_params       RECORD;
    tab_id         INTEGER;
BEGIN
    -- проверка
    IF l_grupp_id IS NULL OR EXISTS(SELECT id
                                    FROM lapsed.day_taabel
                                    WHERE rekv_id = l_rekvid
                                      AND grupp_id = l_grupp_id
                                      AND kpv = l_kpv
                                      AND staatus <> 3)
    THEN
        RAISE NOTICE 'Табель уже сформирован %, %', l_grupp_id, l_kpv;
        error_code = 4;
        error_message = 'Taabel juba olemas.';
        result = 0;
        RETURN;
    END IF;

    -- создаем параметры
    FOR v_lapsed IN
        SELECT lk.parentid AS lapsId,
               l_grupp_id  AS grupp_id,
               lk.rekvid,
               lk.nomid,
               -- услуга должна ьыть в группе
               CASE
                   WHEN (('[]'::JSONB || jsonb_build_object('nomid', lk.nomid) <@
                          (l.properties::JSONB ->> 'teenused')::JSONB) OR
                         ('[]'::JSONB || jsonb_build_object('nomid', lk.nomid::TEXT) <@
                          (l.properties::JSONB ->> 'teenused')::JSONB)
                            )
                       AND
                        lower(ltrim(rtrim(n.uhik))) IN ('paev', 'päev')
                       THEN 1
                   ELSE NULL END
                           AS kogus
        FROM lapsed.lapse_kaart lk
                 INNER JOIN libs.library l ON l.kood = lk.properties ->> 'yksus'
            AND l.library = 'LAPSE_GRUPP'
            AND l.status <> 3
                 INNER JOIN (SELECT id, kood, nimetus, uhik
                             FROM libs.nomenklatuur n
                             WHERE rekvid = l_rekvid
                               AND lower(ltrim(rtrim(n.uhik))) IN ('paev', 'päev')) n ON n.id = lk.nomid
        WHERE lk.staatus <> 3
          AND lk.rekvid = l_rekvid
          AND l.id = l_grupp_id
          AND (lk.properties ->> 'alg_kpv' IS NULL OR
               (lk.properties ->> 'alg_kpv')::DATE <= l_kpv) -- услуга должны действоаать в периоде
          AND (lk.properties ->> 'lopp_kpv' IS NULL OR (lk.properties ->> 'lopp_kpv')::DATE >= l_kpv)
          AND n.uhik IN ('paev', 'päev', 'PAEV', 'PÄEV')
        LOOP
            RAISE NOTICE 'v_lapsed.nomid %, v_lapsed.lapsId  %, v_lapsed.kogus %', v_lapsed.nomid, v_lapsed.lapsId, v_lapsed.kogus;
            -- details
            SELECT 0               AS id,
                   v_lapsed.nomid  AS nom_id,
                   v_lapsed.lapsId AS laps_id,
                   v_lapsed.kogus  AS kogus,
                   1               AS osalemine,
                   0               AS covid
            INTO v_row;

            l_json_details = coalesce(l_json_details, '{}'::JSONB) || to_jsonb(v_row);
        END LOOP;

    -- сохранить

    SELECT 0              AS id,
           l_grupp_id     AS grupp_id,
           l_rekvid       AS rekv_id,
           l_kpv          AS kpv,
           l_json_details AS "gridData"
    INTO v_params;

    SELECT row_to_json(row)
    INTO l_json
    FROM (SELECT 0        AS id,
                 v_params AS data) row;

    SELECT lapsed.sp_salvesta_day_taabel(l_json :: JSONB, user_id, l_rekvId) INTO tab_id;
    result = tab_id;

    -- удалим операции с ед. изм не день

    DELETE
    FROM lapsed.day_taabel1
    WHERE parent_id = tab_id
      AND nom_id IN (
        SELECT id
        FROM libs.nomenklatuur
        WHERE lower(uhik) NOT IN ('paev', 'päev')
    );

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

--GRANT EXECUTE ON FUNCTION lapsed.koosta_paevad_taabel(JSONB, INTEGER) TO dbkasutaja;
--GRANT EXECUTE ON FUNCTION lapsed.koosta_paevad_taabel(JSONB, INTEGER) TO dbpeakasutaja;
REVOKE EXECUTE ON FUNCTION lapsed.koosta_paevad_taabel(JSONB, INTEGER) FROM dbkasutaja;
REVOKE EXECUTE ON FUNCTION lapsed.koosta_paevad_taabel(JSONB, INTEGER) FROM dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.koosta_paevad_taabel(JSONB, INTEGER) TO arvestaja;


/*
select lapsed.koosta_paevad_taabel('{"kpv":"2022-05-23","grupp_id":"214218"}', 70)
select * from lapsed.day_taabel1 where parent_id = 45714

*/
