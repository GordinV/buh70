DROP FUNCTION IF EXISTS hooldekodu.sp_calc_hoojaak(INTEGER);

CREATE OR REPLACE FUNCTION hooldekodu.sp_calc_hoojaak(l_isik_id INTEGER)
    RETURNS SMALLINT AS
$BODY$

DECLARE
    l_pension_85  NUMERIC(16, 2) = 0;
    l_pension_15  NUMERIC(16, 2) = 0;
    l_taskuraha  NUMERIC(16, 2) = 0;
    l_toetus      NUMERIC(16, 2) = 0;
    l_vara        NUMERIC(16, 2) = 0;
    l_omavalitsus NUMERIC(16, 2) = 0;
    l_laen        NUMERIC(16, 2) = 0;
    l_muud        NUMERIC(16, 2) = 0;
    l_tulud       NUMERIC(16, 2) = 0;
    l_kulud       NUMERIC(16, 2) = 0;
    v_hoojaak     RECORD;


BEGIN

    -- leiame jaagirea
    IF NOT exists(SELECT id FROM hooldekodu.hoojaak WHERE isikid = l_isik_id)
    THEN
        INSERT INTO hooldekodu.hoojaak (isikid, pension85, pension15, taskuraha_kov, toetus, vara, omavalitsus, laen, muud)
        VALUES (l_isik_id, 0, 0, 0, 0, 0, 0, 0, 0);
    END IF;

    FOR v_hoojaak IN
        SELECT sum(summa) AS summa, allikas
        FROM (SELECT tyyp,
                     summa,
                     allikas
              FROM hooldekodu.hootehingud
              WHERE isikid = l_isik_id
                AND status < 3) tmp
        GROUP BY allikas

        LOOP
            IF ltrim(rtrim(v_hoojaak.allikas)) = 'PENSION85'
            THEN
                l_pension_85 = v_hoojaak.summa;
            END IF;
            IF ltrim(rtrim(v_hoojaak.allikas)) = 'PENSION15'
            THEN
                l_pension_15 = v_hoojaak.summa;
            END IF;
            IF ltrim(rtrim(v_hoojaak.allikas)) = 'TASKURAHA'
            THEN
                l_taskuraha = v_hoojaak.summa;
            END IF;
            IF ltrim(rtrim(v_hoojaak.allikas)) = 'TOETUS'
            THEN
                l_toetus = v_hoojaak.summa;
            END IF;
            IF ltrim(rtrim(v_hoojaak.allikas)) = 'VARA'
            THEN
                l_vara = v_hoojaak.summa;
            END IF;
/*            IF ltrim(rtrim(v_hoojaak.allikas)) = 'OMAVALITSUS'
            THEN
                l_omavalitsus = v_hoojaak.summa;
            END IF;
            IF ltrim(rtrim(v_hoojaak.allikas)) = 'LAEN'
            THEN
                l_laen = v_hoojaak.summa;
            END IF;
*/ IF ltrim(rtrim(v_hoojaak.allikas)) = 'MUUD'
            THEN
                l_muud = v_hoojaak.summa;
            END IF;
        END LOOP;

    SELECT sum(summa) FILTER (WHERE tyyp = 'TULUD' AND status < 3) AS TULUD,
           sum(summa) FILTER (WHERE tyyp = 'KULUD' AND status < 3) AS kULUD
    INTO l_tulud, l_kulud
    FROM hooldekodu.hootehingud
    WHERE isikid = l_isik_id
      AND status < 3;


    UPDATE hooldekodu.hoojaak
    SET pension85   = l_pension_85,
        pension15   = l_pension_15,
        taskuraha_kov = l_taskuraha,
        toetus      = l_toetus,
        vara        = l_vara,
        omavalitsus = l_omavalitsus,
        laen        = l_laen,
        muud        = l_muud,
        kulud       = coalesce(l_kulud, 0),
        tulud       = coalesce(l_tulud, 0)
    WHERE isikId = l_isik_id;

    RETURN 1;
END;

$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION hooldekodu.sp_calc_hoojaak(INTEGER) TO hkametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_calc_hoojaak(INTEGER) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_calc_hoojaak(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_calc_hoojaak(INTEGER) TO dbpeakasutaja;

/*
select hooldekodu.sp_calc_hoojaak(45514)
 */