-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS hooldekodu.koosta_hoo_taabelid(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION hooldekodu.koosta_hoo_taabelid(IN user_id INTEGER,
                                                          IN l_isik_id INTEGER,
                                                          IN l_kpv DATE DEFAULT current_date,
                                                          OUT error_code INTEGER,
                                                          OUT result INTEGER,
                                                          OUT doc_type_id TEXT,
                                                          OUT error_message TEXT,
                                                          OUT viitenr TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid          INTEGER = (SELECT rekvid
                                 FROM ou.userid u
                                 WHERE id = user_id
                                 LIMIT 1);

    v_isik            RECORD;
    v_taabel          RECORD;
    json_rea          JSONB   = '[]'::JSONB;
    l_taabel_id       INTEGER;
    l_kuu             INTEGER = date_part('month', l_kpv);
    l_aasta           INTEGER = date_part('year', l_kpv);
    l_kalendri_paevad INTEGER = palk.get_days_of_month_in_period(l_kuu, l_aasta,
                                                                 make_date(l_aasta, l_kuu, 01),
                                                                 gomonth(make_date(l_aasta, l_kuu, 01), 1) - 1, FALSE,
                                                                 FALSE);


BEGIN

    IF l_isik_id IS NULL
    THEN
        -- контр-анет не найден, выходим
        result = 0;
        error_message = 'Puudub kontragent';
        error_code = 1;
        RETURN;

    END IF;

    SELECT regkood AS isikukood, nimetus AS nimi FROM libs.asutus WHERE id = l_isik_id INTO v_isik;

    -- delete taabelit

    PERFORM hooldekodu.sp_delete_hootaabel(user_id, id)
    FROM hooldekodu.hootaabel ht
    WHERE rekvid = l_rekvid
      AND date_part('month', kpv) = l_kuu
      AND date_part('year', kpv) = l_aasta
      AND isikid = l_isik_id
      AND ht.status < 3;

    FOR v_taabel IN
        WITH hl AS (
            SELECT ht.nomid,
                   n.kood,
                   n.uhik,
                   hl.algkpv,
                   hl.loppkpv,
                   l_kalendri_paevad                                                           AS kalendri_paevad,
                   date_part('day', CASE
                                        WHEN hl.algkpv > make_date(l_aasta, l_kuu, 1) THEN hl.algkpv
                                        ELSE make_date(l_aasta, l_kuu, 1) END)                 AS alg_paev,
                   date_part('day', CASE
                                        WHEN hl.loppkpv < gomonth(make_date(l_aasta, l_kuu, 1), 1) - 1 THEN hl.loppkpv
                                        ELSE gomonth(make_date(l_aasta, l_kuu, 1), 1) - 1 END) AS lopp_paev,
                   CASE
                       WHEN upper(n.uhik) IN ('KUU', 'PAEV', 'PÄEV') THEN l_kalendri_paevad
                       ELSE 1 END::NUMERIC(12, 4)                                              AS kogus,
                   CASE
                       WHEN upper(n.uhik) IN ('KUU') THEN n.hind / l_kalendri_paevad
                       ELSE n.hind END::NUMERIC(12, 2)                                         AS hind,
                   CASE WHEN upper(n.uhik) IN ('KUU', 'PAEV', 'PÄEV') THEN l_kalendri_paevad ELSE 1 END *
                   CASE
                       WHEN upper(n.uhik) IN ('KUU') THEN n.hind / l_kalendri_paevad
                       ELSE n.hind END::NUMERIC(12, 2)                                         AS summa,
                   n.hind                                                                      AS alus_hind,
                   0                                                                           AS soodustus,
                   ht.lepingid,
                   hl.isikid,
                   public.get_last_day(l_kpv)                                                  AS kpv
            FROM hooldekodu.hooteenused ht
                     INNER JOIN hooldekodu.hooleping hl ON ht.lepingid = hl.id
                     INNER JOIN libs.nomenklatuur n ON n.id = ht.nomid
            WHERE (ht.kehtivus IS NULL
                OR ht.kehtivus >= l_kpv)
              AND lepingid IN (SELECT id
                               FROM hooldekodu.hooleping
                               WHERE rekvid = l_rekvid
                                 AND isikid = l_isik_id::INTEGER
                                 AND hl.loppkpv >= make_date(l_aasta, l_kuu, 1)
                                 AND hl.algkpv <= gomonth(make_date(l_aasta, l_kuu, 1), 1) - 1
            )
        )
        SELECT *,
               CASE
                   WHEN kogus > 1 AND (alg_paev > 1 OR lopp_paev < kalendri_paevad) THEN (lopp_paev - alg_paev) + 1
                   ELSE kalendri_paevad END AS arvestatud_kogus,
               CASE
                   WHEN coalesce(hl.kalendri_paevad, 0) > 0 AND upper(hl.uhik) = 'KUU' THEN hl.alus_hind -
                                                                                            round(hl.alus_hind / hl.kalendri_paevad,2) *
                                                                                            hl.kalendri_paevad
                   ELSE 0 END               AS umardamine
        FROM hl
        LOOP
            -- формируем строку
            json_rea = json_rea || (SELECT row_to_json(ROW)
                                    FROM (SELECT v_taabel.nomid                                         AS nomid,
                                                 v_taabel.kpv                                           AS kpv,
                                                 v_taabel.arvestatud_kogus                              AS kogus,
                                                 v_taabel.hind,
                                                 (v_taabel.arvestatud_kogus *
                                                  (v_taabel.hind - v_taabel.soodustus))::NUMERIC(12, 2) AS summa,
                                                 v_taabel.soodustus                                     AS soodustus,
                                                 v_taabel.umardamine,
                                                 v_taabel.isikid                                        AS isikid,
                                                 v_taabel.alus_hind,
                                                 v_taabel.lepingid                                      AS lepingid) ROW) :: JSONB;
        END LOOP;
    json_rea = (SELECT to_json(ROW)
                FROM (SELECT 0        AS id,
                             json_rea AS "gridData") ROW);
    SELECT to_jsonb(ROW)
    INTO json_rea
    FROM (SELECT 0 AS id, json_rea AS DATA) ROW;

    l_taabel_id = hooldekodu.sp_salvesta_hootaabel(json_rea::JSONB, user_id::INTEGER, l_rekvid::INTEGER);

    IF l_taabel_id IS NOT NULL AND l_taabel_id > 0
    THEN
        error_message = 'Isikukood: ' || v_isik.isikukood || ', Nimi:' || v_isik.nimi || ', taabel_id: ' ||
                        l_taabel_id::TEXT;
        result = l_taabel_id;
    ELSE
        error_code = 1;
        error_message =
                        'Dokumendi koostamise viga,  Isikukood: ' || v_isik.isikukood || ', Nimi:' || v_isik.nimi;
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
$BODY$ LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION hooldekodu.koosta_hoo_taabelid(INTEGER, INTEGER, DATE) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.koosta_hoo_taabelid(INTEGER, INTEGER, DATE) TO hkametnik;


/*
select hooldekodu.koosta_hoo_taabelid(5175, 24768, '2022-10-31')

select * from hooldekodu.hooleping
select * from ou.userid where kasutaja = 'vlad' and rekvid = 132
 */

