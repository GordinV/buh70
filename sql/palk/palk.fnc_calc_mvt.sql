DROP FUNCTION IF EXISTS palk.fnc_calc_mvt(JSONB);

CREATE OR REPLACE FUNCTION palk.fnc_calc_mvt(params JSONB)
    RETURNS NUMERIC AS
$BODY$

    -- tnMVT_kokku personal taotluse summa
DECLARE
    l_alus_summa            NUMERIC = coalesce((params ->> 'summa') :: NUMERIC, 0); -- tulu
    l_mvt_kokku             NUMERIC = coalesce((params ->> 'mvt_kokku') :: NUMERIC, 0); -- taotluse summa
    l_kokku_kasutatud_mvt   NUMERIC = coalesce((params ->> 'kokku_kasutatud_mvt') :: NUMERIC,
                                               0); -- kokku kasutatud mvt kuues

    l_enne_arvestatud_tulud NUMERIC = coalesce((params ->> 'tulud_kokku') :: NUMERIC, 0); -- enne arvesatud tulud

    l_tki                   NUMERIC = coalesce((params ->> 'tki') :: NUMERIC, 0);
    l_pm                    NUMERIC = coalesce((params ->> 'pm') :: NUMERIC, 0);

    kas_pensionar           BOOLEAN = coalesce((params ->> 'kas_pensionar') :: BOOLEAN, FALSE);
    l_isiku_MVT             NUMERIC = palk.calc_mvt((l_alus_summa + l_enne_arvestatud_tulud), l_mvt_kokku); -- сумма, которую можно использовать как мвт
    l_taotluse_MVT          NUMERIC = CASE
                                          WHEN NOT kas_pensionar THEN l_isiku_MVT
                                          ELSE coalesce((params ->> 'taotluse_MVT') :: NUMERIC, 0) END; -- сумма, по заявлению
    l_MVT                   NUMERIC = l_isiku_MVT - l_kokku_kasutatud_mvt;

BEGIN
    RAISE NOTICE 'fnc params %',params;
    IF (kas_pensionar)
    THEN
        l_isiku_MVT = l_mvt_kokku - l_kokku_kasutatud_mvt;
        l_MVT = CASE WHEN l_isiku_MVT > 0 THEN l_isiku_MVT ELSE 0 END;
    END IF;
    RAISE NOTICE 'fnc l_isiku_MVT %, l_alus_summa %, l_MVT %',l_isiku_MVT, l_alus_summa, l_MVT;

    IF l_MVT > (l_alus_summa - l_tki - l_pm)
    THEN
        l_MVT = l_alus_summa - l_tki - l_pm;
        l_isiku_MVT = l_MVT; -- поправим мвт
    END IF;

    IF l_alus_summa < 0
    THEN
        -- if summa < 0 then returning 0
        l_MVT = -1 * (abs(l_alus_summa) - abs(l_tki) - abs(l_pm));
        IF abs(l_MVT) > l_mvt_kokku
        THEN
            l_MVT = -1 * l_mvt_kokku;
        END IF;
    END IF;

    l_MVT = round(l_MVT, 2);

    -- MVT kokku kontrol

    IF l_MVT > l_mvt_kokku
    THEN
        l_MVT = l_mvt_kokku;
    END IF;

    RETURN l_MVT;


END;

$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.fnc_calc_mvt(JSONB) TO dbkasutaja;



SELECT palk.fnc_calc_mvt('{
  "summa": 239.3200,
  "mvt_kokku": 500.0000,
  "kokku_kasutatud_mvt": 177.4600,
  "tulud_kokku": 184.0900,
  "tki": 3.8300,
  "pm": 4.7900
}'::JSONB)

/*
SELECT palk.fnc_calc_mvt(
           '{"tulud_kokku":700, "kokku_kasutatud_mvt":500,"summa":200, "mvt_kokku":500, "tki":3.2, "pm":4}'::JSONB)

select palk.fnc_calc_mvt('{"summa":1000}'::jsonb)
select palk.fnc_calc_mvt('{"summa":1000, "mvt_kokku":500}'::jsonb)
select palk.fnc_calc_mvt('{"summa":120, "mvt_kokku":540, "kokku_kasutatud_mvt":500}'::jsonb)

*/