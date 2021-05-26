DROP FUNCTION IF EXISTS palk.sp_calc_arv(params JSONB);
DROP FUNCTION IF EXISTS palk.sp_calc_arv(INTEGER, params JSON);

CREATE OR
    REPLACE FUNCTION palk.sp_calc_arv(IN user_id INTEGER, IN params JSON,
                                      OUT selg TEXT,
                                      OUT tki NUMERIC,
                                      OUT tka NUMERIC,
                                      OUT tm NUMERIC,
                                      OUT tm_kokku NUMERIC,
                                      OUT pm NUMERIC,
                                      OUT sm NUMERIC,
                                      OUT summa NUMERIC,
                                      OUT mvt NUMERIC(14, 4),
                                      OUT error_code INTEGER,
                                      OUT result INTEGER,
                                      OUT error_message TEXT,
                                      OUT data JSONB)
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_lepingid      INTEGER         = params ->> 'lepingid';
    l_libid         INTEGER         = params ->> 'libid';
    l_kpv           DATE            = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_alus_summa    NUMERIC         = params ->> 'alus_summa'; -- для расчета налогов
    l_used_mvt      NUMERIC         = params ->> 'mvt'; -- для учета применненого необлагаемого
    is_umardamine   BOOLEAN         = coalesce((params ->> 'umardamine')::BOOLEAN, FALSE); -- если истина, то это округление
    is_percent      BOOLEAN         = coalesce((params ->> 'is_percent') :: BOOLEAN,
                                               TRUE); -- kas pk summa percentis (100%)
    l_palk_summa    NUMERIC         = coalesce((params ->> 'palk') :: NUMERIC, 0);
    l_pk_summa      NUMERIC         = coalesce((params ->> 'summa') :: NUMERIC, CASE
                                                                                    WHEN is_percent
                                                                                        THEN 100
                                                                                    ELSE l_palk_summa END);
    is_alimentid    BOOLEAN         = coalesce((params ->> 'alimentid') :: BOOLEAN, FALSE); -- начисление алиментов
    l_tund          INTEGER         = params ->> 'tund'; -- tunni liik
    l_tunnid_kokku  NUMERIC         = params ->> 'tunnid_kokku'; -- tunnid taabeli jargi

    l_tululiik      TEXT            = coalesce((params ->> 'tululiik') :: TEXT, '10');
    l_PM_maksustav  INTEGER         = coalesce((params ->> 'pm_maksustav') :: INTEGER, 1); -- является основой для ПН налога
    l_SM_maksustav  INTEGER         = coalesce((params ->> 'sm_maksustav') :: INTEGER, 1); -- облагается соц. налогом
    l_tasuliik      INTEGER         = array_position((enum_range(NULL :: PALK_TASU_LIIK)), 'ASTMEPALK');
    l_koormus       NUMERIC         = 100;

    tdperiod        DATE;
    l_hours         NUMERIC(20, 10) = 0;
    l_rate          NUMERIC(20, 10); -- bruttopalk
    lnBaas          NUMERIC(20, 10) = 0;
    ltEnter         TEXT            = '(r)'; -- перевод строки

    l_mvt_kokku     NUMERIC(14, 4)  = 0; -- mvt taotluse summa
    l_kasutatud_mvt NUMERIC(14, 4)  = 0;
    l_isiku_mvt     NUMERIC(14, 4)  = 0; -- isiku kasutatud mvt

    l_PM_maar       NUMERIC(8, 2)   = 2;
    l_TKI_maar      NUMERIC(8, 2)   = 1.6;
    l_TKA_maar      NUMERIC(8, 2)   = 0.8;
    l_SM_maar       NUMERIC(8, 2)   = 33;
    l_TM_maar       NUMERIC(8, 2)   = 20;
    l_min_sots      INTEGER         = 0; -- kas arvesta min.sots.maks
    l_kuu_alg       DATE            = date(year(l_kpv), month(l_kpv), 01);
    l_kuu_lopp      DATE            = date(year(l_kpv), month(l_kpv), day(get_last_day(l_kpv)));
    l_round         NUMERIC         = 0.01;
    l_params        JSON;
    l_min_palk      NUMERIC         = 500;
    l_toopaev       NUMERIC         = 8;
    l_rekvid        INTEGER;
    l_isik_id       INTEGER;

    l_tulud_kokku   NUMERIC; -- temp
    is_pm           NUMERIC         = 1;
    is_tki          NUMERIC         = 1;
    doc_ids         INTEGER[];

BEGIN
    IF l_lepingid IS NOT NULL
    THEN
        SELECT t.toopaev,
               pc.minpalk,
               t.rekvid,
               CASE
                   WHEN t.algab > l_kuu_alg AND month(t.algab) = month(l_kpv) AND
                        year(t.algab) = year(l_kpv)
                       THEN t.algab
                   ELSE l_kuu_alg END,
               CASE
                   WHEN t.lopp IS NOT NULL AND t.lopp < l_kuu_lopp AND month(t.lopp) = month(l_kpv) AND
                        year(t.lopp) = year(l_kpv)
                       THEN t.lopp
                   ELSE l_kuu_lopp END,
               t.tasuliik,
               t.koormus,
               t.palk,
               t.parentid
               INTO l_toopaev, l_min_palk, l_rekvid, l_kuu_alg, l_kuu_lopp, l_tasuliik, l_koormus, l_palk_summa, l_isik_id
        FROM palk.com_toolepingud t
                 LEFT OUTER JOIN palk.palk_config pc ON pc.rekvid = t.rekvid
        WHERE t.id = l_lepingid;

        -- parametrid puuduvad, võttame kõik andmebaasist
        -- palk kaart
        SELECT pk.percent_,
               pk.summa,
               NOT empty(pk.alimentid),
               pk.round,
               pk.tund,
               pk.tululiik,
               pk.liik
               INTO is_percent, l_pk_summa, is_alimentid, l_round, l_tund, l_tululiik
        FROM palk.cur_palk_kaart pk
        WHERE pk.lepingid = l_lepingid
          AND pk.libId = l_libId;

        SELECT CASE l_tund
                   WHEN 1 --'KÕIK'
                       THEN kokku
                   WHEN 2 --'PÄEVAD'
                       THEN paev
                   WHEN 3 -- 'ÕHTUL'
                       THEN ohtu
                   WHEN 4 --'ÖÖSEL'
                       THEN oo
                   WHEN 5 --'PUHKUS'
                       THEN tahtpaev
                   WHEN 6 --'PÜHAPAEVAL'
                       THEN puhapaev
                   WHEN 7 --'ÜLEAJATÖÖ'
                       THEN uleajatoo
                   END AS tunnid INTO l_tunnid_kokku
        FROM palk.cur_palk_taabel t
        WHERE lepingId = l_lepingid
          AND kuu = month(l_kpv)
          AND aasta = year(l_kpv);

    END IF;

    -- проверим на наличие в карте ПН
    IF NOT exists(SELECT 1
                  FROM palk.palk_kaart pk
                           INNER JOIN com_palklib l ON l.id = pk.libid
                  WHERE pk.lepingid = l_lepingid
                    AND pk.status = 1
                    AND l.liik = 8)
    THEN
        is_pm = 0;
    END IF;

    -- проверим на наличие в карте TKI
    IF NOT exists(SELECT 1
                  FROM palk.palk_kaart pk
                           INNER JOIN com_palklib l ON l.id = pk.libid
                  WHERE pk.lepingid = l_lepingid
                    AND pk.status = 1
                    AND l.liik = 7
                    AND (l.asutusest IS NULL OR empty(l.asutusest) OR l.asutusest::TEXT = '0'))
    THEN
        is_tki = 0;
--    l_TKA_maar = 0;
    END IF;

    SELECT
        --    l.muud              AS lisa,
        l.tun1              AS tm_maar,
        l.tun2              AS sm_maksustav,
        l.tun4 * l_TKI_maar AS tki_maar,
        l.tun5              AS pm_maksustav
        INTO l_TM_maar, l_SM_maksustav, l_TKI_maar, l_PM_maksustav
    FROM libs.library l
    WHERE LIBRARY = 'MAKSUKOOD'
      AND l.kood = l_tululiik
      AND l.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted');

    IF l_TKI_maar = 0
    THEN
        l_TKA_maar = 0;
    END IF;

    IF l_alus_summa IS NULL
    THEN
        IF is_percent
        THEN
            -- calc based on taabel
            -- prepaire parameters for hours calculation

            -- установим 1 день для получения часов в месяц
            l_kuu_alg = make_date(year(l_kuu_alg), month(l_kuu_alg), 1);

            SELECT row_to_json(row) INTO l_params
            FROM (SELECT l_kpv           AS kpv,
                         month(l_kpv)    AS kuu,
                         year(l_kpv)     AS aasta,
                         l_lepingid      AS lepingid,
                         TRUE            AS kas_tahtpaevad,
                         l_toopaev       AS toopaev,
                         day(l_kuu_alg)  AS paev,
                         day(l_kuu_lopp) AS lopp) row;


            l_hours = palk.get_work_hours(l_params :: JSONB);

            selg = coalesce(selg, '') + 'Kokku tunnid kuues,:' + ltrim(rtrim(round(l_hours, 2) :: VARCHAR)) + ltEnter;

            IF l_tasuliik = array_position((enum_range(NULL :: PALK_TASU_LIIK)), 'ASTMEPALK')
            THEN
                l_rate := l_palk_summa / l_hours * 0.01 * l_koormus;

                selg = coalesce(selg, '') + 'Palk kokku:' + ltrim(rtrim(round(l_palk_summa, 2) :: VARCHAR)) + ltEnter;
                selg = coalesce(selg, '') + 'Tunni hind:' + ltrim(rtrim(round(l_rate, 2) :: VARCHAR)) + ltEnter;

                summa = f_round(l_rate * l_pk_summa * 0.01 * l_tunnid_kokku, l_round);
                selg = coalesce(selg, '') + 'parandamine:' + ltrim(rtrim(round(l_rate, 2) :: VARCHAR)) + '*' +
                       ltrim(rtrim(round(l_pk_summa, 2) :: VARCHAR)) + ' * 0.01 * ' +
                       ltrim(rtrim(round(l_tunnid_kokku, 3) :: VARCHAR)) + ltEnter;

                lnBaas := l_tunnid_kokku;

            ELSE
                --tunni alusel
                summa = f_round((l_palk_summa) * l_tunnid_kokku, l_round);
                l_rate = l_palk_summa;
                selg = coalesce(selg, '') + 'arvestus:' + ltrim(rtrim(l_palk_summa :: TEXT)) + '*' +
                       ltrim(rtrim(round(l_tunnid_kokku, 3) :: TEXT)) + ltEnter;

            END IF;

        ELSE
            -- not percent
            summa = f_round(l_pk_summa, l_round);
            selg = coalesce(selg, '') + ltrim(rtrim(l_pk_summa :: VARCHAR)) + '/' + ltEnter;
        END IF;
    ELSE
        selg = coalesce(selg, '') + ' Käsi arvestus või ümardamine ' + ltEnter;
        summa = l_alus_summa;
    END IF;

    --TKI arvestus
    SELECT row_to_json(row) INTO l_params
    FROM (SELECT summa      AS alus_summa,
                 l_TKI_maar AS summa,
                 7          AS liik) row;

    tki = is_tki * f_round((SELECT qry.summa
                            FROM palk.sp_calc_kinni(user_id, l_params :: JSON) AS qry), l_round);

    selg = coalesce(selg, '') + 'TKI arvestus:' + round(summa, 2) :: TEXT + '*' + (0.01 * l_TKI_maar) :: TEXT + '*' +
           l_TKI_maar :: TEXT + '*' + is_tki::TEXT + ltEnter;

    -- PM arvestus
    SELECT row_to_json(row) INTO l_params
    FROM (SELECT summa     AS alus_summa,
                 l_PM_maar AS summa,
                 8         AS liik) row;

    pm = is_pm * f_round(coalesce((SELECT qry_pm.summa
                                   FROM palk.sp_calc_kinni(user_id, l_params :: JSON) AS qry_pm), 0), l_round) *
         coalesce(l_PM_maksustav, 0);

    selg = coalesce(selg, '') + 'PM arvestus:' + round(summa, 2) :: TEXT + '*' + (0.01 * l_PM_maar) :: TEXT + '*' +
           coalesce(l_PM_maksustav, 0) :: TEXT + '*' + is_pm:: TEXT + ltEnter;

    --SM arvestus
    SELECT row_to_json(row) INTO l_params
    FROM (SELECT summa      AS alus_summa,
                 l_SM_maar  AS summa,
                 l_min_sots AS minsots) row;

    sm = f_round(coalesce((SELECT qry.summa
                           FROM palk.sp_calc_sots(user_id, l_params :: JSON) AS qry), 0), l_round) *
         coalesce(l_SM_maksustav, 0);

    selg = coalesce(selg, '') + 'SM arvestus: ' + (CASE
                                                       WHEN summa < l_min_palk * l_min_sots
                                                           THEN l_min_palk
                                                       ELSE round(summa, 2) END) :: TEXT +
           '*' + (0.01 * l_SM_maar) :: TEXT + '*' + coalesce(l_SM_maksustav, 0) :: TEXT + ltEnter;

    -- TKA arvestus
    SELECT row_to_json(row) INTO l_params
    FROM (SELECT summa      AS alus_summa,
                 7          AS liik,
                 0          AS asutusest,
                 l_TKA_maar AS summa) row;

    tka = f_round(coalesce((SELECT qry.summa
                            FROM palk.sp_calc_muuda(user_id, l_params :: JSON) AS qry), 0), l_round);
    selg = coalesce(selg, '') + 'TKA arvestus:' + round(summa, 2) :: TEXT +
           '*' + (0.01 * l_TKA_maar) :: TEXT + ltEnter;


    IF l_lepingid IS NOT NULL AND l_libid IS NOT NULL
    THEN
        -- get taotluse_summa
        l_mvt_kokku = coalesce((SELECT sum(mvt.summa)
                                FROM palk.taotlus_mvt mvt
                                         INNER JOIN palk.com_toolepingud t ON t.id = mvt.lepingId
                                WHERE t.parentId = l_isik_id
                                  AND mvt.status <> 'deleted'
                                  AND (l_rekvid IS NULL OR t.rekvid = l_rekvid)
                                  AND alg_kpv <= l_kpv
                                  AND lopp_kpv >= l_kpv), 0);

        l_isiku_mvt = 0;
        l_kasutatud_mvt = 0;

        IF (l_mvt_kokku > 0)
        THEN
            SELECT sum(po.tulubaas)                                            AS isiku_tulubaas,
                   sum(po.tulubaas)
                       FILTER (WHERE po.tululiik :: TEXT = l_tululiik :: TEXT) AS kasutatud_mvt,
                   sum(po.summa)                                               AS tulud_kokku,
                   array_agg(po.id)
                   INTO l_isiku_mvt, l_kasutatud_mvt, l_tulud_kokku, doc_ids
            FROM palk.cur_palkoper po
                     INNER JOIN palk.com_toolepingud t ON t.id = po.lepingId
            WHERE t.parentid = l_isik_id
              AND (l_rekvid IS NULL OR t.rekvid = l_rekvid)
              AND po.period IS NULL
              AND po.palk_liik = 'ARVESTUSED'
              AND (l_alus_summa IS NULL OR is_umardamine OR
                   po.tululiik :: TEXT = l_tululiik :: TEXT) -- если округления то считаем все виды дохода
              -- calculate only 1 tululiik
              AND year(po.kpv) = year(l_kpv)
              AND month(po.kpv) = month(l_kpv)
              AND (l_alus_summa IS NOT NULL OR po.id NOT IN (SELECT id
                                                             FROM palk.palk_oper
                                                             WHERE kpv = l_kpv
                                                               AND lepingid = l_lepingid
                                                               AND libid = l_libId));

        END IF;
    END IF;

    mvt = 0;

    IF is_umardamine AND l_mvt_kokku > 0
    THEN

        -- не будем считать MVT, а используем уже примененный
        mvt = CASE WHEN l_used_mvt IS NULL THEN coalesce(l_isiku_mvt, 0) ELSE l_used_mvt END;

        raise notice 'umardamine tm mvt %, l_used_mvt %, l_tulud_kokku %, summa %, l_tululiik %', mvt, l_used_mvt, l_tulud_kokku, summa, l_tululiik;

        -- но если доход менее 500 (минимального оклада)
        IF (l_tulud_kokku < l_min_palk)
        THEN
            mvt = coalesce(l_tulud_kokku, 0) - coalesce(pm, 0) - coalesce(tki, 0);
            IF mvt > l_mvt_kokku
            THEN
                mvt = l_mvt_kokku;
            END IF;
        END IF;
    ELSE
        -- MVT  arvestus
        IF l_mvt_kokku > 0
        THEN
            SELECT row_to_json(row) INTO l_params
            FROM (SELECT summa                      AS summa,
                         coalesce(l_mvt_kokku, 0)   AS mvt_kokku,
                         -- should select from taotlused
                         coalesce(l_isiku_mvt, 0)   AS kokku_kasutatud_mvt,
                         coalesce(l_tulud_kokku, 0) AS tulud_kokku,
                         -- enne arvestatud isiku tulud
                         -- should select from palk.palk_oper
                         coalesce(tki, 0)           AS tki,
                         coalesce(pm, 0)            AS pm) row;

            mvt = palk.fnc_calc_mvt(l_params :: JSONB);

            IF mvt > 0 AND mvt > summa
            THEN
                -- обработаем возможную ошибку
                mvt = summa;
            END IF;

        END IF;

    END IF;

    -- TM arvestus

    tm = palk.fnc_calc_tm(summa, mvt, tki, pm, l_tululiik);
    tm_kokku = palk.fnc_calc_tm(l_tulud_kokku, mvt, tki, pm, NULL::TEXT);

    raise notice 'umardamine tm %, tm_kokku %', tm, tm_kokku;


    selg = coalesce(selg, '') + 'TM arvestus:' + round(tm, 2) :: TEXT + ltEnter;
    IF summa IS NOT NULL
    THEN
        result = 1;
    ELSE
        result = 0;
    END IF;

    summa = coalesce(summa, 0);
    -- empty result
    l_params = to_jsonb(row.*)
               FROM (
                        SELECT NULL                    AS doc_id,
                               'Kehtiv makseid ei ole' AS error_message,
                               0::INTEGER              AS error_code,
                               summa                   AS summa,
                               selg                    AS selg,
                               tki:: NUMERIC           AS tki,
                               tka::NUMERIC            AS tka,
                               tm:: NUMERIC            AS tm,
                               pm::NUMERIC             AS pm,
                               sm:: NUMERIC            AS sm,
                               mvt::NUMERIC            AS mvt
                    ) row;
    data = coalesce(data, '[]'::JSONB) || l_params::JSONB;


    RETURN;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            selg = selg || SQLERRM;
            summa = 0;
            RETURN;

END;
$$;

/*
SELECT *
FROM palk.sp_calc_arv(1, '{"lepingid":31113,"libid":135748,"kpv":20210430}' :: JSON)

select * from palk.l


select * from palk.sp_calc_arv(1,'{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSON)
SELECT * FROM palk.sp_calc_arv(1,'{ "alus_summa": 100,"kpv": "2018-04-09"}' :: JSON)
SELECT * FROM palk.sp_calc_arv(1,'{ "alus_summa": 100,"tululiik":"13","kpv": "2018-04-09"}' :: JSON)
SELECT * FROM palk.sp_calc_arv(1,'{"kpv": "2018-04-09", "palk": 1200,  "summa":100,"tunnid_kokku":168}' :: JSON)
SELECT * FROM palk.sp_calc_arv(1,'{"kpv": "2018-04-09", "palk": 1200, "is_percent":false}' :: JSON)
SELECT * FROM palk.sp_calc_arv(1,'{"kpv": "2018-04-09", "palk": 1200, "is_percent":false, "pm_maksustav":0}' :: JSON)
SELECT * FROM palk.sp_calc_arv(1,'{"kpv": "2018-04-09", "palk": 1200, "is_percent":false, "sm_maksustav":0}' :: JSON)
SELECT * FROM palk.sp_calc_arv(1,'{"lepingid":4,"libid":526,"kpv":20180630}'::json)
        {"kpv":"2018-06-30","lepingid":4,"lib":526}
*/

