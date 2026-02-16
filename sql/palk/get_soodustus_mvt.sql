DROP FUNCTION IF EXISTS palk.get_soodustus_mvt(TEXT, DATE, BOOLEAN);

CREATE FUNCTION palk.get_soodustus_mvt(l_isikukood TEXT, l_kpv DATE DEFAULT current_date,
                                       l_soodustus BOOLEAN DEFAULT FALSE)
    RETURNS NUMERIC
    LANGUAGE plpgsql
AS
$$
DECLARE
    tuulemus      BOOLEAN = FALSE;
    v_palk_config record;
BEGIN
    -- выбираем данные по льготе
    select
        pc.pensionari_tulubaas,

        case
            when palk.kas_soodustus_mvt(l_isikukood, l_kpv::date)::BOOLEAN
                THEN pc.pensionari_tulubaas
            when year(l_kpv) = 2025 and month(l_kpv) = 12 then 700
            when year(l_kpv) = 2025 then 654
            when year(l_kpv) = 2026 then 700
            else pc.tulubaas
            end                  as tapsestatud_pensionari_tulubaas,
        case
            when year(l_kpv) = 2025 and month(l_kpv) = 12 then 700
            when year(l_kpv) = 2025 then 654
            when year(l_kpv) = 2026 then 700
            else pc.tulubaas end as tapsestatud_tulubaas,
        pc.tulubaas
    into v_palk_config
    from
        palk.palk_config pc
    where
        rekvid = 63
    limit 1;

    IF l_isikukood IS NULL OR l_isikukood = '' OR len(l_isikukood) < 7
    THEN
        -- личный код не задан. возвращаем стандар до 2026 654, после 700
        RETURN v_palk_config.tapsestatud_tulubaas;
    END IF;

    -- расчитываем день рождения
    tuulemus = palk.kas_soodustus_mvt(l_isikukood::TEXT, l_kpv::DATE);

    RETURN case
               when tuulemus then v_palk_config.tapsestatud_pensionari_tulubaas
               else v_palk_config.tapsestatud_tulubaas end;

END
$$;


GRANT EXECUTE ON FUNCTION palk.get_soodustus_mvt(TEXT, DATE, BOOLEAN) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_soodustus_mvt(TEXT, DATE, BOOLEAN) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.get_soodustus_mvt(TEXT, DATE, BOOLEAN) TO dbvaatleja;

SELECT
    palk.get_soodustus_mvt('46708180105', '2025-12-06'::date)::INTEGER
-- -> 0

-- -> 0

/*
SELECT palk.kas_soodustus_mvt('46102213714', current_date)::INTEGER -- -> 0

SELECT palk.kas_soodustus_mvt('37303023721', current_date)::INTEGER -- -> 0



*/