DROP FUNCTION IF EXISTS eelarve.salvesta_lisa_1_5_kontrol(INTEGER, DATE, INTEGER);
DROP FUNCTION IF EXISTS eelarve.salvesta_lisa_1_5_kontrol(INTEGER, DATE);

CREATE OR REPLACE FUNCTION eelarve.salvesta_lisa_1_5_kontrol(IN user_id INTEGER,
                                                             IN l_kpv DATE,
                                                             IN l_rekv_id INTEGER DEFAULT NULL,
                                                             OUT error_code INTEGER,
                                                             OUT result INTEGER,
                                                             OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

BEGIN
    raise notice 'start salvesta %',l_rekv_id;

    DROP TABLE IF EXISTS tmp_andmik;
    CREATE TABLE IF NOT EXISTS tmp_andmik
    (
        idx                TEXT,
        tyyp               INTEGER,
        rekvid             INTEGER,
        tegev              VARCHAR(20),
        allikas            VARCHAR(20),
        artikkel           VARCHAR(20),
        rahavoog           VARCHAR(20),
        nimetus            VARCHAR(254),
        eelarve            NUMERIC(14, 2),
        eelarve_taps       NUMERIC(14, 2),
        eelarve_kassa      NUMERIC(14, 2),
        eelarve_kassa_taps NUMERIC(14, 2),
        tegelik            NUMERIC(14, 2),
        kassa              NUMERIC(14, 2),
        saldoandmik        NUMERIC(14, 2),
        db                 NUMERIC(14, 2),
        kr                 NUMERIC(14, 2),
        aasta              INTEGER,
        kuu                INTEGER,
        is_kulud           INTEGER DEFAULT 0,
        rekv_id            INTEGER NULL
    );


--            TRUNCATE TABLE tmp_andmik;

-- удаляем прежнюю версию
    DELETE
    FROM
        eelarve.lisa_1_5_kontrol l
    WHERE
          kpv = l_kpv
      AND l.rekv_id = l_rekv_id;

    INSERT INTO
        eelarve.lisa_1_5_kontrol (nimetus, eelarve, eelarve_kassa, eelarve_taps, eelarve_kassa_taps,
                                  kassa,
                                  saldoandmik, idx, kpv, rekv_id)
    SELECT
        nimetus,
        eelarve,
        eelarve_kassa,
        eelarve_taps,
        eelarve_kassa_taps,
        kassa,
        saldoandmik,
        idx,
        l_kpv,
        l_rekv_id
    FROM
        eelarve.lisa1_lisa5_kontrol(l_kpv, l_rekv_id, 1 );

    RAISE NOTICE 'finished v_rekv.id %', l_rekv_id;

    result = 1;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION eelarve.salvesta_lisa_1_5_kontrol(INTEGER, DATE, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.salvesta_lisa_1_5_kontrol(INTEGER, DATE, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION eelarve.salvesta_lisa_1_5_kontrol(INTEGER, DATE, INTEGER) TO dbkasutaja;


/*
SELECT eelarve.koosta_lisa_1_5_kontrol_(2477, '2024-08-31'::date)


*/

--select * from ou.userid where rekvid = 63 and kasutaja = 'vlad'