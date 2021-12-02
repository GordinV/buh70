DROP FUNCTION IF EXISTS fill_data_from_saldoandmik(DATE, INTEGER, INTEGER);


CREATE OR REPLACE FUNCTION fill_data_from_saldoandmik(l_kpv DATE DEFAULT current_date, l_rekvid INTEGER DEFAULT 63, l_kond INTEGER DEFAULT 1)
    RETURNS NUMERIC
AS
$$
BEGIN
    DROP TABLE IF EXISTS tmp_andmik;
    CREATE TEMPORARY TABLE tmp_andmik (
        idx         TEXT,
        tyyp        INTEGER,
        tegev       VARCHAR(20),
        artikkel    VARCHAR(20),
        rahavoog    VARCHAR(20),
        nimetus     VARCHAR(254),
        eelarve     NUMERIC(14, 2),
        tegelik     NUMERIC(14, 2),
        kassa       NUMERIC(14, 2),
        saldoandmik NUMERIC(14, 2),
        db          NUMERIC(14, 2),
        kr          NUMERIC(14, 2),
        aasta       INTEGER,
        kuu         INTEGER,
        rekv_id integer null
    );

    INSERT INTO tmp_andmik (idx, tyyp, tegev, artikkel, rahavoog, db, kr, aasta, kuu, rekv_id)
    SELECT 0,
           2,
           tegev,
           konto,
           rahavoo,
           db,
           kr,
           aasta,
           kuu,
           rekvid
    FROM eelarve.saldoandmik
    WHERE aasta = year(l_kpv) - 1
      AND kuu = 12
      AND rekvid = (CASE
                        WHEN l_kond = 1 THEN rekvid
                        ELSE l_rekvid END)
      AND rekvid IN (SELECT rekv_id
                     FROM get_asutuse_struktuur(l_rekvid)
    );

    INSERT INTO tmp_andmik (idx, tyyp, tegev, artikkel, rahavoog, db, kr, aasta, kuu, rekv_id)
    SELECT 0,
           2,
           tegev,
           konto,
           rahavoo,
           db,
           kr,
           aasta,
           kuu,
           rekvid
    FROM eelarve.saldoandmik
    WHERE aasta = year(l_kpv) - 2
      AND kuu = 12
      AND rekvid = (CASE
                        WHEN l_kond = 1 THEN rekvid
                        ELSE l_rekvid END)
      AND rekvid IN (SELECT rekv_id
                     FROM get_asutuse_struktuur(l_rekvid)
    );

    INSERT INTO tmp_andmik (idx, tyyp, tegev, artikkel, rahavoog, db, kr, aasta, kuu, rekv_id)
    SELECT 0,
           2,
           tegev,
           konto,
           rahavoo,
           db,
           kr,
           aasta,
           kuu,
           rekvid
    FROM eelarve.saldoandmik
    WHERE aasta = year(l_kpv)
      AND kuu = 6
      AND rekvid = (CASE
                        WHEN l_kond = 1 THEN rekvid
                        ELSE l_rekvid END)
      AND rekvid IN (SELECT rekv_id
                     FROM get_asutuse_struktuur(l_rekvid)
    );

    return 1;
END
$$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION fill_data_from_saldoandmik(DATE, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION fill_data_from_saldoandmik(DATE, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION fill_data_from_saldoandmik(DATE, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION fill_data_from_saldoandmik(DATE, INTEGER, INTEGER) TO dbvaatleja;


/*
select fill_data_from_saldoandmik()
*/