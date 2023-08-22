DROP FUNCTION IF EXISTS hooldekodu.sp_calc_netosissetulek(INTEGER, NUMERIC);

CREATE OR REPLACE FUNCTION hooldekodu.sp_calc_netosissetulek(l_isik_id INTEGER, l_bruttosissetulek NUMERIC)
    RETURNS NUMERIC AS
$BODY$

DECLARE
    l_netosissetulek NUMERIC(16, 2) = l_bruttosissetulek;
    l_tm             NUMERIC(12, 2) = 0;
    l_MVT            NUMERIC        = 654;
    l_isikukood      TEXT;
    v_palk_config    RECORD;
BEGIN

    SELECT *
    INTO v_palk_config
    FROM palk.palk_config
    WHERE rekvid = 64;

    SELECT regkood
    INTO l_isikukood
    FROM libs.asutus
    WHERE id = l_isik_id;
    l_MVT = CASE
                WHEN palk.kas_soodustus_mvt(l_isikukood, current_date) THEN v_palk_config.pensionari_tulubaas
                ELSE v_palk_config.tulubaas END;

    RAISE NOTICE 'l_isik_id %', l_isik_id;
    l_tm = (l_bruttosissetulek - (SELECT palk.fnc_calc_mvt(
                                                 jsonb_build_object('kpv', current_date, 'summa', l_bruttosissetulek,
                                                                    'mvt_kokku', l_MVT, 'kas_pensionar', TRUE)::JSONB))
               )::NUMERIC * v_palk_config.tm * 0.01;


    l_netosissetulek = l_bruttosissetulek - l_tm;
    RAISE NOTICE 'l_tm %, l_netosissetulek %, l_MVT %',l_tm, l_netosissetulek, l_MVT;
    RETURN l_netosissetulek;
END ;

$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION hooldekodu.sp_calc_netosissetulek(INTEGER, NUMERIC) TO hkametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_calc_netosissetulek(INTEGER, NUMERIC) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_calc_netosissetulek(INTEGER, NUMERIC) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_calc_netosissetulek(INTEGER, NUMERIC) TO dbpeakasutaja;

SELECT hooldekodu.sp_calc_netosissetulek(45514, 1000)

/*
select hooldekodu.sp_calc_netosissetulek(45514, 1000)
 */