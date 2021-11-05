DROP FUNCTION IF EXISTS palk.sp_calc_min_sots(IN user_id INTEGER, IN params JSON);

CREATE OR REPLACE FUNCTION palk.sp_calc_min_sots(IN user_id INTEGER, IN params JSON,
                                                 OUT result INTEGER,
                                                 OUT error_code INTEGER,
                                                 OUT error_message TEXT,
                                                 OUT summa NUMERIC,
                                                 OUT alus NUMERIC,
                                                 OUT sm NUMERIC,
                                                 OUT selg text)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_lepingid   INTEGER = params ->> 'lepingid';
    l_kpv        DATE    = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_last_paev  DATE    = (date(YEAR(l_kpv), MONTH(l_kpv), 1) + INTERVAL '1 month') :: DATE - 1;
    v_arvestus   RECORD;
    v_tooleping  RECORD;
    v_puhkus     RECORD;
    v_po         RECORD;
    lopp_kpv     DATE;
    l_paevad     INTEGER = 30;
    l_min_sots   NUMERIC(14, 4);
    l_korr_sm    NUMERIC(14, 4);
    l_korr_summa NUMERIC(14, 4);
BEGIN

    raise notice 'calc minsost params %', params;

    IF NOT exists(SELECT 1
                  FROM ou.userid u
                  WHERE u.id = user_Id)

    THEN
        error_code = 5;
        error_message = 'Kasutaja ei leitud,  userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        RETURN;
    END IF;

    IF l_lepingid IS NULL
    THEN
        error_code = 6;
        error_message = 'Parametrid on vale või puuduvad';
        result = 0;
        RETURN;
    END IF;

    SELECT *
    INTO v_tooleping
    FROM palk.tooleping t
    WHERE t.id = l_lepingid;

    lopp_kpv = (SELECT max(COALESCE(lopp, current_date + INTERVAL '1 year'))
                FROM palk.tooleping t
                WHERE t.parentid = v_tooleping.parentid
                  AND t.rekvid = v_tooleping.rekvid);

    -- sotsmsks min palgast ei arvestatakse (palk_kaart)

    IF NOT exists(SELECT 1
                  FROM palk.cur_palk_kaart pk
                  WHERE pk.lepingid IN (SELECT t.id
                                        FROM palk.tooleping t
                                        WHERE t.parentid = v_tooleping.parentid
                                          AND t.rekvid = v_tooleping.rekvid
                                          AND t.pohikoht = 1)
                    AND pk.status = 1
                    AND NOT empty(pk.minsots))
    THEN
        error_message = 'Pole vaja arvestada';
        summa = 0;
        result = 1;
        RETURN;
    END IF;



    -- puhkusepaevad arvestame
    SELECT sum(palk.get_puudumine((SELECT row_to_json(row)
                                   FROM (SELECT l_lepingid   AS lepingid,
                                                month(l_kpv) AS kuu,
                                                year(l_kpv)  AS aasta,
                                                TRUE         AS kas_kalendripaevad,
                                                'PUHKUS'     AS pohjus) row) :: JSONB)) AS puhkuse_paevad
    INTO v_puhkus
    FROM palk.tooleping t
    WHERE t.parentid = v_tooleping.parentid
      AND t.rekvid = v_tooleping.rekvid
      AND t.pohikoht = 1;

    -- palgaoperatsioonid
    SELECT sum(po.summa)                           AS summa,
           sum(po.sotsmaks)                        AS sm,
           sum(po.summa)
           FILTER (WHERE po.kood ILIKE '%PUHKUS%') AS puhkused,
           sum(po.sotsmaks)
           FILTER (WHERE po.kood ILIKE '%PUHKUS%') AS sm_puhkused,
           sum(po.summa)
           FILTER (WHERE po.kood ILIKE '%HAIGUS%') AS haigused,
           sum(po.sotsmaks)
           FILTER (WHERE po.kood ILIKE '%HAIGUS%') AS sm_haigused,
           max(mk.sm_arv) as sm_arv
    INTO v_po
    FROM palk.cur_palkoper po
             INNER JOIN palk.com_maksukood mk ON mk.kood = po.tululiik :: TEXT AND NOT empty(mk.sm_arv)
    WHERE po.palk_liik = 'ARVESTUSED'
      AND po.lepingid IN (SELECT id
                          FROM palk.tooleping
                          WHERE parentid = v_tooleping.parentid
                            AND tooleping.rekvid = v_tooleping.rekvid)
      AND month(kpv) = month(l_kpv)
      AND year(kpv) = year(l_kpv)
      AND period IS NULL;

    SELECT coalesce(v_po.summa, 0)                                 AS summa,
           coalesce(v_po.puhkused, 0)                              AS puhkused,
           coalesce(v_po.haigused, 0)                              AS haigused,
           coalesce(v_po.sm, 0)                                    AS sm,
           coalesce(v_po.sm_puhkused, 0)                           AS sm_puhkused,
           coalesce(v_po.sm_haigused, 0)                           AS sm_haigused,
           coalesce(v_puhkus.puhkuse_paevad, 0)                    AS puhkused_paevad,
           lopp_kpv                                                AS lopp,
           (pc.minpalk * pc.sm / 100)                              AS minsots,
           pc.minpalk,
           day(l_last_paev) - coalesce(v_puhkus.puhkuse_paevad, 0) AS paevad,
           v_po.sm_arv
    INTO v_arvestus
    FROM palk.palk_config pc
    WHERE pc.rekvid = v_tooleping.rekvid;

    if v_po.sm_arv is null then
        -- нет облагаемых соц.налогом сумм
        error_message = 'Pole vaja arvestada';
        summa = 0;
        result = 1;
        RETURN;

    END IF;

    l_paevad = (CASE
                    WHEN COALESCE(v_puhkus.puhkuse_paevad, 0) = 0
                        THEN 30
                    ELSE v_arvestus.paevad END);

    IF l_paevad < 0
    THEN
        l_paevad = 0;
    END IF;

    l_min_sots = v_arvestus.minsots / 30 * l_paevad;

    l_korr_sm = v_arvestus.sm - (v_arvestus.sm_puhkused + v_arvestus.sm_haigused);
    l_korr_summa = v_arvestus.summa - (v_arvestus.puhkused + v_arvestus.haigused);

    IF (l_min_sots - l_korr_sm) > 0
    THEN
        summa = round(l_min_sots - l_korr_sm, 2);
        alus = round(v_arvestus.minpalk / 30 * l_paevad - l_korr_summa, 2);
        selg = 'lisa SM (' + v_arvestus.minpalk::TEXT + '/30 * ' ||
                       coalesce(l_paevad, 30)::TEXT || '-' + coalesce(alus, 0)::TEXT +
                                                                ') = ' + coalesce(sm, 0)::TEXT ||
                       '* 0.33 = ' || coalesce(summa, 0)::TEXT;
        sm = alus;
    END IF;

    result = 1;
    RETURN;

END;
$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;


SELECT *
FROM palk.sp_calc_min_sots(1, '{
  "lepingid": 4
}' :: JSON);

/*
select * from palk.sp_calc_min_sots(1, '{"lepingid":31524}'::JSON);

*/