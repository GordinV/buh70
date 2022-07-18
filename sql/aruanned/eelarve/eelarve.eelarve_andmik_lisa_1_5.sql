DROP FUNCTION IF EXISTS eelarve.eelarve_andmik_lisa_1_5(DATE, INTEGER, INTEGER);



CREATE OR REPLACE FUNCTION eelarve.eelarve_andmik_lisa_1_5(IN l_kpv DATE,
                                                           IN l_rekvid INTEGER,
                                                           IN l_kond INTEGER)
    RETURNS TABLE (
        idx                VARCHAR(20),
        is_e               INTEGER,
        rekvid             INTEGER,
        tegev              VARCHAR(20),
        allikas            VARCHAR(20),
        artikkel           VARCHAR(20),
        nimetus            VARCHAR(254),
        eelarve            NUMERIC(14, 2),
        eelarve_kassa      NUMERIC(14, 2),
        eelarve_taps       NUMERIC(14, 2),
        eelarve_kassa_taps NUMERIC(14, 2),
        tegelik            NUMERIC(14, 2),
        kassa              NUMERIC(14, 2),
        saldoandmik        NUMERIC(14, 2)
    )
AS
$$
DECLARE
    is_kond         BOOLEAN        = NOT empty(l_kond);
    l_kuu           INTEGER        = month(l_kpv);
    l_aasta         INTEGER        = year(l_kpv);
    la_kontod       TEXT[]         = ARRAY ['100','1000','1001','15','1501','1502','1511','1512','1531','1532','2580','2581','2585','2586','3000','3030',
        '3034','3041','3044','3045','3047','32','3500','3502','352','35200','35201','381','382','38250','38251',
        '38252','38254','3880','3882','3888','40','413','4500','4502','452','50','55','60','650','655'];

    l_3888          NUMERIC(16, 4) = 0;
    l_2580          NUMERIC(16, 4) = 0;
    l_2580_kassa    NUMERIC(16, 4) = 0;
    l_2580_eelarve  NUMERIC(16, 4) = 0;

    l_2581          NUMERIC(16, 4) = 0;
    l_2581_kassa    NUMERIC(16, 4) = 0;

    l_9100          NUMERIC(16, 4) = 0;
    l_9100_periodis NUMERIC(16, 4) = 0;
    l_9101          NUMERIC(16, 4) = 0;
    l_9101_taps     NUMERIC(16, 4) = 0;
    l_linna_eelarve BOOLEAN        = CASE WHEN l_kond > 0 AND l_rekvid = 63 THEN TRUE ELSE FALSE END;

BEGIN
    -- ,'9100','9101'

    -- will fill temp table with row data
    PERFORM eelarve.eelarve_andmik_lisa_1_5_query(l_kpv, l_rekvid, l_kond);


    SELECT sum((kr - db))
    INTO l_2580
    FROM tmp_andmik s,
         (SELECT min(aasta) AS eelmine_aasta, max(aasta) AS aasta, min(kuu) AS eelmine_kuu, max(kuu) AS kuu
          FROM tmp_andmik) aasta
    WHERE s.tyyp = 2
      AND s.aasta = aasta.eelmine_aasta
      AND (left(s.artikkel, 4) IN ('1535', '2035', '2038', '2530', '2535', '2536')
        OR left(s.artikkel, 3) IN ('208', '250', '256', '258')
        OR left(s.artikkel, 6) IN ('203650', '203655', '203670', '913100')
        OR val(ltrim(rtrim(s.artikkel))) >= 913010 AND val(ltrim(rtrim(s.artikkel))) <= 913090);

    l_2580 = coalesce(l_2580, 0);

    l_2580_kassa = get_saldo('MKD', '203620', NULL, NULL) +
                   get_saldo('MKD', '203630', NULL, NULL);

    l_2580_eelarve = get_saldo('MKD', '208', NULL, NULL) +
                     get_saldo('MKD', '258', NULL, NULL); -- MKD208+MKD258


    SELECT sum((kr - db))
    INTO l_2581
    FROM tmp_andmik s,
         (SELECT min(aasta) AS eelmine_aasta, max(aasta) AS aasta, min(kuu) AS eelmine_kuu, max(kuu) AS kuu
          FROM tmp_andmik) aasta
    WHERE s.tyyp = 2
      AND s.aasta = aasta.aasta
      AND (left(s.artikkel, 4) IN ('1535', '2035', '2038', '2530', '2535', '2536')
        OR left(s.artikkel, 3) IN ('208', '250', '256', '258')
        OR left(s.artikkel, 6) IN ('203650', '203655', '203670', '913100')
        OR val(ltrim(rtrim(s.artikkel))) >= 913010 AND val(ltrim(rtrim(s.artikkel))) <= 913090);

    l_2581 = coalesce(l_2581, 0);
    l_2581_kassa = get_saldo('KD', '203620', NULL, NULL) +
                   get_saldo('KD', '203630', NULL, NULL);


    l_9100 = -1 * get_saldo('MKD', '910090', NULL, NULL);
    l_9100_periodis = -1 * get_saldo('KD', '910090', NULL, NULL);

    l_9101 = -1 * get_saldo('KD', '910090', NULL, NULL);


-- data analise
    RETURN QUERY
        WITH tmp_report AS (
            SELECT qry.idx::VARCHAR(20),
                   CASE
                       WHEN qry.is_e = 0 AND ARRAY [qry.artikkel::TEXT] <@ la_kontod THEN 1
                       ELSE qry.is_e END:: INTEGER                                                  AS is_e,
                   qry.rekvid::INTEGER,
                   qry.tegev::VARCHAR(20),
                   qry.allikas::VARCHAR(20),
                   qry.artikkel::VARCHAR(20),
                   qry.nimetus::VARCHAR(254),
                   (CASE WHEN qry.eelarve IS NULL THEN 0 ELSE qry.eelarve END)::NUMERIC             AS eelarve,
                   (CASE WHEN qry.eelarve_kassa IS NULL THEN 0 ELSE qry.eelarve_kassa END)::NUMERIC AS eelarve_kassa,
                   ((CASE WHEN qry.eelarve_taps IS NULL THEN 0 ELSE qry.eelarve_taps END) +
                    (CASE WHEN qry.eelarve IS NULL THEN 0 ELSE qry.eelarve END))::NUMERIC           AS eelarve_taps,
                   (CASE WHEN qry.eelarve_kassa IS NULL THEN 0 ELSE qry.eelarve_kassa END)::NUMERIC +
                   (CASE
                        WHEN qry.eelarve_kassa_taps IS NULL
                            THEN 0
                        ELSE qry.eelarve_kassa_taps END)::NUMERIC                                   AS eelarve_kassa_taps,
                   (CASE WHEN qry.tegelik IS NULL THEN 0 ELSE qry.tegelik END)::NUMERIC             AS tegelik,
                   (CASE WHEN qry.kassa IS NULL THEN 0 ELSE qry.kassa END)::NUMERIC                 AS kassa,
                   (CASE WHEN qry.saldoandmik IS NULL THEN 0 ELSE qry.saldoandmik END)::NUMERIC     AS saldoandmik
            FROM (
                     SELECT '2.1'::VARCHAR(20)                                       AS idx,
                            1                                                        AS is_e,
                            $2                                                       AS rekvid,
                            ''::VARCHAR(20)                                          AS tegev,
                            ''::VARCHAR(20)                                          AS allikas,
                            '32'::VARCHAR(20)                                        AS artikkel,
                            'Tulud kaupade ja teenuste müügist'::VARCHAR(254)        AS nimetus,
                            coalesce(sum(q.eelarve), 0)::NUMERIC(12, 2)              AS eelarve,
                            coalesce(sum(q.eelarve_kassa), 0)::NUMERIC(12, 2)        AS eelarve_kassa,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)         AS eelarve_taps,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2)   AS eelarve_kassa_taps,
                            coalesce(coalesce(sum(q.tegelik), 0), 0)::NUMERIC(12, 2) AS tegelik,
                            coalesce(coalesce(sum(q.kassa), 0), 0)::NUMERIC(12, 2)   AS kassa,
                            get_saldo('KD', '32', NULL, NULL)::NUMERIC(12, 2)        AS saldoandmik
                     FROM tmp_andmik q
                          -- Сумма 320+3220+3221+3222+3224+3229+3232+3233+3237+3238
                     WHERE (
                                 q.artikkel IN
                                 ('3220', '3221', '3222', '3224', '3229', '3232', '3233', '3237', '3238')
                             OR q.artikkel LIKE '320%'
                         )
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.1'::VARCHAR(20)                                       AS idx
                             ,
                            1                                                        AS is_e
                             ,
                            $2                                                       AS rekvid
                             ,
                            ''::VARCHAR(20)                                          AS tegev
                             ,
                            ''::VARCHAR(20)                                          AS allikas
                             ,
                            '320'::VARCHAR(20)                                       AS artikkel
                             ,
                            'Riigilõivud'::VARCHAR(254)                              AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)::NUMERIC(12, 2)              AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)::NUMERIC(12, 2)        AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)         AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2)   AS eelarve_kassa_taps
                             ,
                            coalesce(coalesce(sum(q.tegelik), 0), 0)::NUMERIC(12, 2) AS tegelik
                             ,
                            coalesce(coalesce(sum(q.kassa), 0), 0)::NUMERIC(12, 2)   AS kassa
                             ,
                            get_saldo('KD', '320', NULL, NULL)::NUMERIC(12, 2)       AS saldoandmik
                     FROM tmp_andmik q
                          -- Сумма 320+3220+3221+3222+3224+3229+3232+3233+3237+3238
                     WHERE q.artikkel LIKE '320%'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.1'::VARCHAR(20),
                            0                                                      AS is_e
                             ,
                            $2                                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                                        AS tegev
                             ,
                            ''::VARCHAR(20)                                        AS allikas
                             ,
                            '352'::VARCHAR(20)                                     AS artikkel
                             ,
                            'Mittesihtotstarbelised toetused'                      AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '352', NULL, NULL) -
                            get_saldo('KD', '352000', NULL, NULL) -
                            get_saldo('KD', '352001', NULL, NULL)                  AS saldoandmik
-- KD352-KD352000-KD352010
                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '352%'
                       AND q.artikkel NOT IN ('35200', '35201')
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.1'::VARCHAR(20)
                             ,
                            0                                                      AS is_e
                             ,
                            $2                                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                                        AS tegev
                             ,
                            ''::VARCHAR(20)                                        AS allikas
                             ,
                            '35200'::VARCHAR(20)                                   AS artikkel
                             ,
                            'Tasandusfond'                                         AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '352001', NULL, NULL)                  AS saldoandmik
-- KD352000
                     FROM tmp_andmik q
                     WHERE q.artikkel = '35200'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.1'::VARCHAR(20)
                             ,
                            0                                                      AS is_e
                             ,
                            $2                                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                                        AS tegev
                             ,
                            ''::VARCHAR(20)                                        AS allikas
                             ,
                            '35201'::VARCHAR(20)                                   AS artikkel
                             ,
                            'Toetusfond '                                          AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '352000', NULL, NULL)                  AS saldoandmik
-- KD352010
                     FROM tmp_andmik q
                     WHERE q.artikkel = '35201'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.1'::VARCHAR(20)
                             ,
                            0                                                      AS is_e
                             ,
                            $2                                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                                        AS tegev
                             ,
                            ''::VARCHAR(20)                                        AS allikas
                             ,
                            '382'::VARCHAR(20)                                     AS artikkel
                             ,
                            'Muud tulud varadelt'                                  AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
--                            KD382-38250-38251-38252-38254
                            get_saldo('KD', '382', NULL, NULL)
                                - get_saldo('KD', '38250', NULL, NULL)
                                - get_saldo('KD', '38251', NULL, NULL)
                                - get_saldo('KD', '38252', NULL, NULL)
                                - get_saldo('KD', '38254', NULL, NULL)             AS saldoandmik
-- KD382+KD382520+KD382550+KD382560

                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '382%'
                       AND q.artikkel NOT IN ('38250', '38251', '38252', '38254')
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.11'::VARCHAR(20)
                             ,
                            1                                                      AS is_e
                             ,
                            $2                                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                                        AS tegev
                             ,
                            ''::VARCHAR(20)                                        AS allikas
                             ,
                            '40'::VARCHAR(20)                                      AS artikkel
                             ,
                            'Subsiidiumid ettevõtlusega tegelevatele isikutele'    AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '40', NULL, NULL)                      AS saldoandmik
-- KD40
                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '40%'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.11'::VARCHAR(20)
                             ,
                            1                                                             AS is_e
                             ,
                            $2                                                            AS rekvid
                             ,
                            ''::VARCHAR(20)                                               AS tegev
                             ,
                            ''::VARCHAR(20)                                               AS allikas
                             ,
                            '413'::VARCHAR(20)                                            AS artikkel
                             ,
                            'Sotsiaalabitoetused ja muud toetused füüsilistele isikutele' AS nimetus
                             ,
                            -1 * coalesce(sum(q.eelarve), 0)                              AS eelarve
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa), 0)                        AS eelarve_kassa
                             ,
                            -1 * coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)         AS eelarve_taps
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2)   AS eelarve_kassa_taps
                             ,
                            -1 * coalesce(sum(q.tegelik), 0)                              AS tegelik
                             ,
                            -1 * coalesce(sum(q.kassa), 0)                                AS kassa
                             ,
                            get_saldo('KD', '413', NULL, NULL)                            AS saldoandmik
-- KD413
                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '413%'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.11'::VARCHAR(20)
                             ,
                            1                                                           AS is_e
                             ,
                            $2                                                          AS rekvid
                             ,
                            ''::VARCHAR(20)                                             AS tegev
                             ,
                            ''::VARCHAR(20)                                             AS allikas
                             ,
                            '4500'::VARCHAR(20)                                         AS artikkel
                             ,
                            'Sihtotstarbelised toetused tegevuskuludeks'                AS nimetus
                             ,
                            -1 * coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            -1 * coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            -1 * coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            -1 * coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '4500', NULL, NULL)                         AS saldoandmik
-- KD4500
                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '4500%'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.11'::VARCHAR(20)
                             ,
                            1                                                           AS is_e
                             ,
                            $2                                                          AS rekvid
                             ,
                            ''::VARCHAR(20)                                             AS tegev
                             ,
                            ''::VARCHAR(20)                                             AS allikas
                             ,
                            '452'::VARCHAR(20)                                          AS artikkel
                             ,
                            'Mittesihtotstarbelised toetused'                           AS nimetus
                             ,
                            -1 * coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            -1 * coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            -1 * coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            -1 * coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '452', NULL, NULL)                          AS saldoandmik
-- KD452
                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '452%'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.12'::VARCHAR(20)
                             ,
                            1                                                           AS is_e
                             ,
                            $2                                                          AS rekvid
                             ,
                            ''::VARCHAR(20)                                             AS tegev
                             ,
                            ''::VARCHAR(20)                                             AS allikas
                             ,
                            '50'::VARCHAR(20)                                           AS artikkel
                             ,
                            'Tööjõukulud'                                               AS nimetus
                             ,
                            -1 * coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            -1 * coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            -1 * coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            -1 * coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '50', NULL, NULL)                           AS saldoandmik
                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '50%'
                       AND tyyp = 1
                     UNION ALL
-- Строка 55 - Tekke täitmine – добавляем к уже имеющейся формуле KD 55 налог с оборота KD601 минус KD 601002.
                     SELECT '2.12',
                            1                                                           AS is_e,
                            $2                                                          AS rekvid,
                            ''::VARCHAR(20)                                             AS tegev,
                            ''::VARCHAR(20)                                             AS allikas,
                            '55'::VARCHAR(20)                                           AS artikkel,
                            'Majandamiskulud'                                           AS nimetus,
                            -1 * coalesce(sum(q.eelarve), 0)                            AS eelarve,
                            -1 * coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa,
                            -1 * coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps,
                            -1 * coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps,
                            -1 * coalesce(sum(q.tegelik), 0)                            AS tegelik,
                            -1 * coalesce(sum(q.kassa), 0)                              AS kassa,
                            get_saldo('KD', '55', NULL, NULL) +
                            get_saldo('KD', '601000', NULL, NULL)                       AS saldoandmik
                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '55%'
                       AND tyyp = 1
                     UNION ALL
                     --  KD60 минус KD 601
                     SELECT '2.13'::VARCHAR(20),
                            1                                                           AS is_e,
                            $2                                                          AS rekvid,
                            ''::VARCHAR(20)                                             AS tegev,
                            ''::VARCHAR(20)                                             AS allikas,
                            '60'::VARCHAR(20)                                           AS artikkel,
                            'Muud kulud'                                                AS nimetus,
                            -1 * coalesce(sum(q.eelarve), 0)                            AS eelarve,
                            -1 * coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa,
                            -1 * coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps,
                            -1 * coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps,
                            -1 * coalesce(sum(q.tegelik), 0)                            AS tegelik,
                            -1 * coalesce(sum(q.kassa), 0)                              AS kassa,
                            get_saldo('KD', '60', NULL, NULL) -
                            get_saldo('KD', '601000', NULL, NULL) -
                            get_saldo('KD', '601002', NULL, NULL)                       AS saldoandmik
                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '60%'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.4'::VARCHAR(20)
                             ,
                            1                                                      AS is_e
                             ,
                            $2                                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                                        AS tegev
                             ,
                            ''::VARCHAR(20)                                        AS allikas
                             ,
                            '381'::VARCHAR(20)                                     AS artikkel
                             ,
                            'Põhivara müük (+)'                                    AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
--                            KD381-KD3818-KD154RV02-KD155RV02-KD156RV02-KD157RV02-KD109RV02
                            get_saldo('KD', '381', NULL, NULL) -
                            get_saldo('KD', '3818', NULL, NULL) -
                            get_saldo('DK', '154', '02', NULL) -
                            get_saldo('DK', '155', '02', NULL) -
                            get_saldo('DK', '156', '02', NULL) -
                            get_saldo('DK', '157', '02', NULL) -
                            get_saldo('DK', '109', '02', NULL)                     AS saldoandmik
-- KD381-KD3818-KD154RV02-KD155RV02-KD156RV02-KD157RV02-KD109RV02

                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '381%'
                       AND q.artikkel <> '3818'
                       AND tyyp = 1
                     UNION ALL
                     SELECT q.idx
                             ,
                            1                                                      AS is_e
                             ,
                            $2                                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                                        AS tegev
                             ,
                            ''::VARCHAR(20)                                        AS allikas
                             ,
                            q.artikkel::VARCHAR(20)                                AS artikkel
                             ,
                            q.nimetus                                              AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '3818', NULL, NULL)                    AS saldoandmik
-- KD381-KD3818-KD154RV02-KD155RV02-KD156RV02-KD157RV02-KD109RV02

                     FROM tmp_andmik q
                     WHERE q.artikkel = '3818'
                       AND tyyp = 1
                     GROUP BY q.idx
                             ,
                              q.artikkel
                             ,
                              q.nimetus
                     UNION ALL
                     SELECT '2.4.1'::VARCHAR(20)
                             ,
                            1                                                           AS is_e
                             ,
                            $2                                                          AS rekvid
                             ,
                            ''::VARCHAR(20)                                             AS tegev
                             ,
                            ''::VARCHAR(20)                                             AS allikas
                             ,
                            '15'::VARCHAR(20)                                           AS artikkel
                             ,
                            'Põhivara soetus (-)'                                       AS nimetus
                             ,
                            coalesce(sum(-1 * q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(-1 * q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(-1 * q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(-1 * q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(-1 * q.tegelik), 0)::NUMERIC(12, 2)            AS tegelik
                             ,
                            coalesce(sum(-1 * q.kassa), 0)::NUMERIC(12, 2)              AS kassa
                             ,
                            (coalesce(get_saldo('KD', '154', '01', NULL) +
                                      get_saldo('KD', '155', '01', NULL) +
                                      get_saldo('KD', '156', '01', NULL) +
                                      get_saldo('KD', '157', '01', NULL) +
                                      get_saldo('KD', '601002', NULL, NULL), 0))        AS saldoandmik
                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '15%'
                       AND q.artikkel NOT IN ('1501', '1502', '1532')
                       AND tyyp = 1

-- KD154RV01+KD155RV01+KD156RV01+KD157RV01+601002KD
                     UNION ALL
                     SELECT '2.4.1'::VARCHAR(20)
                             ,
                            1                                                      AS is_e
                             ,
                            $2                                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                                        AS tegev
                             ,
                            ''::VARCHAR(20)                                        AS allikas
                             ,
                            '3502'::VARCHAR(20)                                    AS artikkel
                             ,
                            'Põhivara soetuseks saadav sihtfinantseerimine(+)'     AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '3502', '01', NULL) +
                            get_saldo('KD', '3502', '05', NULL) +
                            get_saldo('KD', '3502', '', NULL)                      AS saldoandmik
-- KD3502RV01+KD3502RV05

                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '3502%'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.4.1'::VARCHAR(20)
                             ,
                            1                                                           AS is_e
                             ,
                            $2                                                          AS rekvid
                             ,
                            ''::VARCHAR(20)                                             AS tegev
                             ,
                            ''::VARCHAR(20)                                             AS allikas
                             ,
                            '4502'::VARCHAR(20)                                         AS artikkel
                             ,
                            'Põhivara soetuseks antav sihtfinantseerimine(-)'           AS nimetus
                             ,
                            -1 * coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            -1 * coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            -1 * coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            -1 * coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '4502', NULL, NULL) +
                            get_saldo('KD', '1', '24', NULL)                            AS saldoandmik
-- KD4502+KD1RV24

                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '4502%'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.4.2'::VARCHAR(20)
                             ,
                            1                                                      AS is_e
                             ,
                            $2                                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                                        AS tegev
                             ,
                            ''::VARCHAR(20)                                        AS allikas
                             ,
                            '1502'::VARCHAR(20)                                    AS artikkel
                             ,
                            'Osaluste müük (+)'                                    AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '150', '02', NULL)                     AS saldoandmik
-- KD150RV02

                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '1502%'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.4.3'
                             ,
                            1                                                           AS is_e
                             ,
                            $2                                                          AS rekvid
                             ,
                            ''::VARCHAR(20)                                             AS tegev
                             ,
                            ''::VARCHAR(20)                                             AS allikas
                             ,
                            '1501'::VARCHAR(20)                                         AS artikkel
                             ,
                            'Osaluste soetus (-)'                                       AS nimetus
                             ,
                            -1 * coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            -1 * coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            -1 * coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            -1 * coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '150', '01', NULL)                          AS saldoandmik
-- KD150RV01
                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '1501%'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.4.3'
                             ,
                            1                                                      AS is_e
                             ,
                            $2                                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                                        AS tegev
                             ,
                            ''::VARCHAR(20)                                        AS allikas
                             ,
                            '1512'::VARCHAR(20)                                    AS artikkel
                             ,
                            'Muude aktsiate ja osade müük (+)'                     AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '151910', '02', NULL) +
                            get_saldo('KD', '101900', '02', NULL)                  AS saldoandmik
-- KD151910RV02+KD101900RV02
                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '1512%'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.4.4'
                             ,
                            1                                                      AS is_e
                             ,
                            $2                                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                                        AS tegev
                             ,
                            ''::VARCHAR(20)                                        AS allikas
                             ,
                            '1511'::VARCHAR(20)                                    AS artikkel
                             ,
                            'Muude aktsiate ja osade soetus (-)'                   AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '151910', '01', NULL) +
                            get_saldo('KD', '101900', '01', NULL)                  AS saldoandmik
-- KD151910RV01+KD101900RV01
                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '1511%'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.4.4'
                             ,
                            1                                                      AS is_e
                             ,
                            $2                                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                                        AS tegev
                             ,
                            ''::VARCHAR(20)                                        AS allikas
                             ,
                            '1532'::VARCHAR(20)                                    AS artikkel
                             ,
                            'Tagasilaekuvad laenud (+)'                            AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '1032', '02', NULL) +
                            get_saldo('KD', '1532', '02', NULL)                    AS saldoandmik
-- KD1032RV02+KD1532RV02
                     FROM tmp_andmik q
                     WHERE left(q.artikkel, 4) IN ('1032', '1532')
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.4.5'
                             ,
                            1                                                      AS is_e
                             ,
                            $2                                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                                        AS tegev
                             ,
                            ''::VARCHAR(20)                                        AS allikas
                             ,
                            '1531'::VARCHAR(20)                                    AS artikkel
                             ,
                            'Antavad laenud (-)'                                   AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '1032', '01', NULL) +
                            get_saldo('KD', '1532', '01', NULL)                    AS saldoandmik
-- KD1032RV01+KD1532RV01
                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '1531%'
                       AND tyyp = 1
                     UNION ALL
                     -- 655 KD652-KD652000-KD652030+ KD655+KD658-KD658950
                     SELECT '2.4.5',
                            1                                                      AS is_e,
                            $2                                                     AS rekvid,
                            ''::VARCHAR(20)                                        AS tegev,
                            ''::VARCHAR(20)                                        AS allikas,
                            '655'::VARCHAR(20)                                     AS artikkel,
                            'Finantstulud (+)'                                     AS nimetus,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik,
                            coalesce(sum(q.kassa), 0)                              AS kassa,
                            get_saldo('KD', '652', NULL, NULL) -
                            get_saldo('KD', '652000', NULL, NULL) -
                            get_saldo('KD', '652030', NULL, NULL) +
                            get_saldo('KD', '655', NULL, NULL) +
                            get_saldo('KD', '658', NULL, NULL) -
                            get_saldo('KD', '658950', NULL, NULL)                  AS saldoandmik
-- KD652+KD655+KD658-KD658950

                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '655%'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.4.5'
                             ,
                            1                                                           AS is_e
                             ,
                            $2                                                          AS rekvid
                             ,
                            ''::VARCHAR(20)                                             AS tegev
                             ,
                            ''::VARCHAR(20)                                             AS allikas
                             ,
                            '650'::VARCHAR(20)                                          AS artikkel
                             ,
                            'Finantstkulud (-)'                                         AS nimetus
                             ,
                            -1 * coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            -1 * coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            -1 * coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            -1 * coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '650', NULL, NULL) +
                            get_saldo('KD', '658950', NULL, NULL)                       AS saldoandmik
-- KD650+KD658950
                     FROM tmp_andmik q
                     WHERE q.artikkel LIKE '650%'
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.4.6'
                             ,
                            1                                                      AS is_e
                             ,
                            $2                                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                                        AS tegev
                             ,
                            ''::VARCHAR(20)                                        AS allikas
                             ,
                            '2585'::VARCHAR(20)                                    AS artikkel
                             ,
                            'Kohustuste võtmine (+)'                               AS nimetus
                             ,
                            coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            coalesce(sum(q.kassa), 0)                              AS kassa
                             ,
                            get_saldo('KD', '208', '05', NULL) +
                            get_saldo('KD', '258', '05', NULL)                     AS saldoandmik
-- KD208RV05+KD258RV05
                     FROM tmp_andmik q
                     WHERE (left(q.artikkel, 3) = '255' OR left(q.artikkel, 4) = '2585')
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.4.6'
                             ,
                            1                                                           AS is_e
                             ,
                            $2                                                          AS rekvid
                             ,
                            ''::VARCHAR(20)                                             AS tegev
                             ,
                            ''::VARCHAR(20)                                             AS allikas
                             ,
                            '2586'::VARCHAR(20)                                         AS artikkel
                             ,
                            'Kohustuste tasumine (-)'                                   AS nimetus
                             ,
                            -1 * coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            -1 * coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            -1 * coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
--                            -1 * coalesce(sum(q.kassa), 0)                              AS kassa,
                            -1 * ((SELECT sum(summa)
                                   FROM cur_journal j
                                   WHERE j.rekvid = (CASE
                                                         WHEN l_kond = 1
                                                             THEN j.rekvid
                                                         ELSE l_rekvid END)
                                     AND j.rekvid IN (SELECT rekv_id
                                                      FROM get_asutuse_struktuur(l_rekvid, l_kpv))
                                     AND (j.kreedit LIKE '100%' OR j.kreedit LIKE '999%')
                                     AND j.kood5 = '2586'
                                     AND year(kpv) = year(l_kpv)
                                     AND j.kpv <= l_kpv
                            ))                                                          AS kassa
                             ,
                            get_saldo('KD', '208', '06', NULL) +
                            get_saldo('KD', '258', '06', NULL)                          AS saldoandmik
-- KD208RV06+KD258RV06

                     FROM tmp_andmik q
                     WHERE (left(q.artikkel, 3) = '206' OR left(q.artikkel, 4) = '2586')
                       AND tyyp = 1
                     UNION ALL
                     SELECT '2.4.7'
                             ,
                            1                                                           AS is_e
                             ,
                            $2                                                          AS rekvid
                             ,
                            ''::VARCHAR(20)                                             AS tegev
                             ,
                            ''::VARCHAR(20)                                             AS allikas
                             ,
                            '100'::VARCHAR(20)                                          AS artikkel
                             ,
                            'LIKVIIDSETE VARADE MUUTUS (+ suurenemine, - vähenemine)'   AS nimetus
                             ,
                            -1 * coalesce(sum(q.eelarve), 0)                            AS eelarve
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa), 0)                      AS eelarve_kassa
                             ,
                            -1 * coalesce(sum(q.eelarve_taps), 0)::NUMERIC(12, 2)       AS eelarve_taps
                             ,
                            -1 * coalesce(sum(q.eelarve_kassa_taps), 0)::NUMERIC(12, 2) AS eelarve_kassa_taps
                             ,
                            -1 * coalesce(sum(q.tegelik), 0)                            AS tegelik
                             ,
                            (get_saldo('DK', '100', NULL, NULL) -
                             get_saldo('DK', '100080', NULL, NULL)) -
                            (get_saldo('MDK', '100', NULL, NULL) -
                             get_saldo('MDK', '100080', NULL, NULL))                    AS kassa
                             ,
--                            DK100-MDK100+DK101-MDK101-DK1019+MDK1019+DK151-MDK151-DK1519+MDK1519
                            get_saldo('DK', '100', NULL, NULL)
                                - get_saldo('MDK', '100', NULL, NULL) +
                            get_saldo('DK', '101', NULL, NULL) -
                            get_saldo('MDK', '101', NULL, NULL) -
                            get_saldo('DK', '1019', NULL, NULL) +
                            get_saldo('MDK', '1019', NULL, NULL) +
                            get_saldo('DK', '151', NULL, NULL) -
                            get_saldo('MDK', '151', NULL, NULL) -
                            get_saldo('DK', '1519', NULL, NULL) +
                            get_saldo('MDK', '1519', NULL, NULL)
                                                                                        AS saldoandmik
-- DK100-MDK100+DK101-MDK101-DK1019+MDK1019+DK151-MDK151-DK1519+MDK1519

                     FROM tmp_andmik q
                     WHERE (q.artikkel LIKE '1001.%' OR q.artikkel = '100')
                       AND tyyp = 1
                     UNION ALL
                     SELECT '8.11',
                            1                             AS is_e,
                            $2                            AS rekvid,
                            ''::VARCHAR(20)               AS tegev,
                            ''::VARCHAR(20)               AS allikas,
                            '2580'::VARCHAR(20)           AS artikkel,
                            'Võlakohustused'              AS nimetus,
                            l_2580_eelarve                AS eelarve,
                            l_2580_eelarve + l_2580_kassa AS eelarve_kassa,
                            0                             AS eelarve_taps,
                            0                             AS eelarve_kassa_taps,
                            l_2580                        AS tegelik,
                            l_2580 + l_2580_kassa         AS kassa,
                            l_2580                        AS saldoandmik

-- MKD208+MKD258
                     UNION ALL
                     SELECT '8.11',
                            1                      AS is_e,
                            $2                     AS rekvid,
                            ''::VARCHAR(20)        AS tegev,
                            ''::VARCHAR(20)        AS allikas,
                            '9100'::VARCHAR(20)    AS artikkel,
                            'sh sildfinantseering' AS nimetus,
                            l_9100                 AS eelarve,
                            l_9100                 AS eelarve_kassa,
                            0                      AS eelarve_taps,
                            0                      AS eelarve_kassa_taps,
                            l_9100                 AS tegelik,
                            l_9100                 AS kassa,
                            l_9100                 AS saldoandmik
-- MKD910090
                     UNION ALL
                     SELECT '8.11'
                             ,
                            1                                      AS is_e
                             ,
                            $2                                     AS rekvid
                             ,
                            ''::VARCHAR(20)                        AS tegev
                             ,
                            ''::VARCHAR(20)                        AS allikas
                             ,
                            '1000'::VARCHAR(20)                    AS artikkel
                             ,
                            'Likviidsed varad'                     AS nimetus
                             ,
                            get_saldo('MDK', '100', NULL, NULL) +
                            get_saldo('MDK', '101', NULL, NULL) -
                            get_saldo('MDK', '1019', NULL, NULL) +
                            get_saldo('MDK', '151', NULL, NULL) -
                            get_saldo('MDK', '1519', NULL, NULL)   AS eelarve
                             ,
                            get_saldo('MDK', '100', NULL, NULL) +
                            get_saldo('MDK', '101', NULL, NULL) -
                            get_saldo('MDK', '1019', NULL, NULL) +
                            get_saldo('MDK', '151', NULL, NULL) -
                            get_saldo('MDK', '1519', NULL, NULL)   AS eelarve_kassa
                             ,
                            0                                      AS eelarve_taps
                             ,
                            0                                      AS eelarve_kassa_taps
                             ,
                            0                                      AS tegelik
                             ,
                            get_saldo('MDK', '100', NULL, NULL) -
                            get_saldo('MDK', '100080', NULL, NULL) AS kassa
                             ,
                            get_saldo('MDK', '100', NULL, NULL) +
                            get_saldo('MDK', '101', NULL, NULL) -
                            get_saldo('MDK', '1019', NULL, NULL) +
                            get_saldo('MDK', '151', NULL, NULL) -
                            get_saldo('MDK', '1519', NULL, NULL)
                                                                   AS saldoandmik
-- MDK100+MDK101-MDK1019+MDK151-MDK1519
-- KD208+KD258
                     UNION ALL
/*
Строка 9101
Tekkepõhine eelarve kinn - это сумма из утвержденного бюджета расходов блока Eelarve с кодом источника LE-LASF.  Эту же сумму надо показать в Kassa eelarve kinn
Tekke eelarve täps - это сумма из уточненного бюджета расходов блока Eelarve с кодом источника LE-LASF. Эту же сумму надо показать в Kassa eelarve täps.
Строка 9101 Tekke täitmine = KD910090
Строка 9101 Kassa täitmine = KD910090

 */

                     SELECT '8.2'
                             ,
                            1                         AS is_e
                             ,
                            $2                        AS rekvid
                             ,
                            ''::VARCHAR(20)           AS tegev
                             ,
                            ''::VARCHAR(20)           AS allikas
                             ,
                            '9101'::VARCHAR(20)       AS artikkel
                             ,
                            'sh sildfinantseering'    AS nimetus
                             ,
                            sum(q.eelarve)            AS eelarve
                             ,
                            sum(q.eelarve_kassa)      AS eelarve_kassa
                             ,
                            sum(q.eelarve_taps)       AS eelarve_taps
                             ,
                            sum(q.eelarve_kassa_taps) AS eelarve_kassa_taps
                             ,
                            l_9101                    AS tegelik
                             ,
                            l_9101                    AS kassa
                             ,
                            l_9101                    AS saldoandmik
                     FROM tmp_andmik q
                     WHERE q.allikas = 'LE-LASF'
                       AND q.is_kulud > 0
-- KD910090
                     UNION ALL
                     SELECT q.idx
                             ,
                            CASE
                                WHEN q.artikkel IN ('3880',
                                                    '3818',
                                                    '3888') THEN 0
                                ELSE 1 END                         AS is_e
                             ,
                            l_rekvid                               AS rekvid
                             ,
                            ''::VARCHAR(20)                        AS tegev
                             ,
                            ''::VARCHAR(20)                        AS allikas
                             ,
                            q.artikkel
                             ,
                            q.nimetus
                             ,
                            COALESCE(sum(q.eelarve), 0)            AS eelarve
                             ,
                            COALESCE(sum(q.eelarve_kassa), 0)      AS eelarve_kassa
                             ,
                            COALESCE(sum(q.eelarve_taps), 0)       AS eelarve_taps
                             ,
                            COALESCE(sum(q.eelarve_kassa_taps), 0) AS eelarve_kassa_taps
                             ,
                            COALESCE(sum(q.tegelik), 0)            AS tegelik
                             ,
                            COALESCE(sum(q.kassa), 0)              AS kassa
                             ,
                            get_saldo(
                                    'KD', q.artikkel, NULL, NULL)  AS saldoandmik
                     FROM tmp_andmik q
                     WHERE LEFT(q.artikkel, 2) NOT IN ('15', '40', '50', '55', '60', '91')
                       AND LEFT(q.artikkel, 4) NOT IN (
                                                       '3200',
                                                       '3201',
                                                       '3203',
                                                       '3209',
                                                       '3501',
                                                       '3502',
                                                       '3823',
                                                       '2585',
                                                       '2586',
                                                       '1001',
                                                       '4500',
                                                       '4502')
                       AND LEFT(q.artikkel, 3) NOT IN ('655', '650', '352', '381', '413', '452', '910', '320')
                       AND trim(q.artikkel) NOT IN ('382', '100')
                       AND tyyp = 1
                     GROUP BY q.idx,
                              q.artikkel,
                              q.nimetus
                     UNION ALL
                     SELECT qry.idx,
                            qry.is_e,
                            qry.rekvid,
                            qry.tegev,
                            qry.allikas,
                            qry.artikkel,
                            qry.nimetus,
                            sum(qry.eelarve)            AS eelarve,
                            sum(qry.eelarve_kassa)      AS eelarve_kassa,
                            sum(qry.eelarve_taps)       AS eelarve_taps,
                            sum(qry.eelarve_kassa_taps) AS eelarve_kassa_taps,
                            sum(qry.tegelik)            AS tegelik,
                            sum(qry.kassa)              AS kassa,
                            sum(qry.saldoandmik)        AS saldoandmik
                     FROM (
                              SELECT '3.1'::VARCHAR(20)   AS idx,
                                     1                    AS is_e,
                                     l_rekvid             AS rekvid,
                                     qry.tegev,
                                     ''::VARCHAR(20)      AS allikas,
                                     ''::VARCHAR(20)      AS artikkel,
                                     l.nimetus,
                                     COALESCE(sum(CASE
                                                      WHEN qry.tegev = '01112' AND qry.artikkel = '1532'
                                                          THEN 0
                                                      ELSE qry.eelarve END),
                                              0)          AS eelarve,
                                     COALESCE(sum(CASE
                                                      WHEN qry.tegev = '01112' AND qry.artikkel = '1532'
                                                          THEN 0
                                                      ELSE qry.eelarve_kassa END),
                                              0)          AS eelarve_kassa,
                                     COALESCE(sum(CASE
                                                      WHEN qry.tegev = '01112' AND qry.artikkel = '1532'
                                                          THEN 0
                                                      ELSE qry.eelarve_taps END),
                                              0)          AS eelarve_taps,
                                     COALESCE(sum(CASE
                                                      WHEN qry.tegev = '01112' AND qry.artikkel = '1532'
                                                          THEN 0
                                                      ELSE qry.eelarve_kassa_taps END),
                                              0)          AS eelarve_kassa_taps
                                      ,
                                     COALESCE(sum(CASE
                                                      WHEN qry.tegev =
                                                           '01112' AND qry.artikkel =
                                                                       '1532' THEN 0
                                                      ELSE qry.tegelik END),
                                              0)          AS tegelik,
                                     COALESCE(sum(CASE
                                                      WHEN qry.tegev = '01112' AND qry.artikkel = '1532'
                                                          THEN 0
                                                      ELSE qry.kassa END),
                                              0)          AS kassa,
                                     (get_saldo('DK', '4', NULL, qry.tegev) +
                                      get_saldo('DK', '5', NULL, qry.tegev) +
                                      get_saldo('DK', '6', NULL, qry.tegev) +
                                      get_saldo('DK', '15', '01', qry.tegev) -
                                      get_saldo(
                                              'DK',
                                              '610', NULL, qry.tegev) -
                                      get_saldo(
                                              'DK',
                                              '611', NULL, qry.tegev) -
                                      get_saldo(
                                              'DK',
                                              '613', NULL,
                                              qry.tegev)) AS saldoandmik
                              FROM tmp_andmik qry
                                       LEFT OUTER JOIN libs.library l
                                                       ON l.kood = qry.tegev
                                                           AND l.library = 'TEGEV'
                                                           AND l.status <> 3
                              WHERE tyyp = 1
                                AND NOT empty(qry.is_kulud)
                                AND qry.artikkel
                                  NOT IN ('2586')
                                AND LEFT(qry.artikkel, 3) NOT IN ('610', '611', '613', '655')
                                AND qry.tegev NOT IN ('07230', '07240', '07320')
                              GROUP BY qry.tegev, l.nimetus
                              UNION ALL
                              SELECT '3.1'::VARCHAR(20)                    AS idx,
                                     1                                     AS is_e,
                                     l_rekvid                              AS rekvid,
                                     '01112'                               AS tegev,
                                     ''::VARCHAR(20)                       AS allikas,
                                     ''::VARCHAR(20)                       AS artikkel,
                                     'Valla- ja linnavalitsus'             AS nimetus,
                                     0                                     AS eelarve,
                                     0                                     AS eelarve_kassa,
                                     0                                     AS eelarve_taps,
                                     0                                     AS eelarve_kassa_taps,
                                     0                                     AS tegelik,
                                     0                                     AS kassa,
                                     get_saldo('DK', '608000', NULL, NULL) AS saldoandmik
                          ) qry
                     GROUP BY qry.idx, qry.is_e, qry.rekvid, qry.tegev, qry.allikas, qry.artikkel, qry.nimetus
                 ) qry
            WHERE qry.artikkel NOT IN ('3500.00', '3209')) -- VB, нет необходимости
        SELECT *
        FROM tmp_report
        WHERE tmp_report.artikkel NOT IN ('6580')
        UNION ALL
        -- Строка 1001 = строка 1000+ строка 100 во всех колонках
        SELECT '8.2'
                ,
               1                         AS is_e
                ,
               $2                        AS rekvid
                ,
               ''::VARCHAR(20)           AS tegev
                ,
               ''::VARCHAR(20)           AS allikas
                ,
               '1001'::VARCHAR(20)       AS artikkel
                ,
               'Likviidsed varad'        AS nimetus
                ,
               sum(t.eelarve)            AS eelarve
                ,
               sum(t.eelarve_kassa)      AS eelarve_kassa
                ,
               sum(t.eelarve_taps)       AS eelarve_taps
                ,
               sum(t.eelarve_kassa_taps) AS eelarve_kassa_taps
                ,
               sum(t.tegelik)            AS tegelik
                ,
               sum(t.kassa)              AS kassa
                ,
               sum(t.saldoandmik)        AS saldoandmik
        FROM tmp_report t
        WHERE t.artikkel IN ('1000', '100')
        UNION ALL
        SELECT '8.2',
               1                         AS is_e,
               $2                        AS rekvid,
               ''::VARCHAR(20)           AS tegev,
               ''::VARCHAR(20)           AS allikas,
               '2581'::VARCHAR(20)       AS artikkel,
               'Võlakohustused'          AS nimetus,
               SUM(t.eelarve)            AS eelarve,
               sum(t.eelarve_kassa)      AS eelarve_kassa,
               sum(t.eelarve_taps)       AS eelarve_taps,
               sum(t.eelarve_kassa_taps) AS eelarve_kassa_taps,
               l_2581                    AS tegelik,
               l_2581 + l_2581_kassa     AS kassa,
               l_2581                    AS saldoandmik
        FROM tmp_report t
        WHERE t.artikkel IN ('2580', '2585', '2586')
        UNION ALL
        -- 3501
        SELECT *
        FROM (
                 WITH qryEelarve AS (
                     SELECT
                         -- Берем из блока Eelarve, закладка Kulud,  Summa kokku - колонка tekkepõhine утвержденная и  вычитаем утвержденные бюджеты доходов 3500, бюджет 352, бюджет 3502 колонка tekkepõhine

                         (
                                 coalesce(sum(e.summa) FILTER (WHERE e.is_kulud > 0 AND e.kpv IS NULL), 0)
                                 - coalesce(sum(e.summa)
                                            FILTER (WHERE e.is_kulud = 0 AND e.kpv IS NULL AND e.kood5 IN ('3500', '352', '3502')),
                                            0)
                             ) AS eelarve_kinni,
                         (
                                 coalesce(sum(e.summa_kassa) FILTER (WHERE e.is_kulud > 0 AND e.kpv IS NULL), 0)
                                 - coalesce(sum(e.summa_kassa)
                                            FILTER (WHERE e.is_kulud = 0 AND e.kpv IS NULL AND e.kood5 IN ('3500', '352', '3502')),
                                            0)
                             ) AS eelarve_kassa_kinni,

                         --  Берем из блока Eelarve, закладка Kulud,  Summa kokku  - колонка tekkepõhine  уточненная и вычитаем уточненные бюджеты  доходов 3500, бюджет 352, бюджет 3502 колонка tekkepõhine
                         (
                                 coalesce(sum(e.summa)
                                          FILTER (WHERE e.is_kulud > 0 AND e.kpv IS NOT NULL AND e.kpv <= l_kpv), 0)
                                 - coalesce(sum(e.summa)
                                            FILTER (WHERE e.is_kulud = 0
                                                AND e.kpv IS NOT NULL
                                                AND e.kpv <= l_kpv
                                                AND e.kood5 IN ('3500', '352', '3502')), 0)
                             ) AS eelarve_taps,
                         (
                                 coalesce(sum(e.summa_kassa)
                                          FILTER (WHERE e.is_kulud > 0 AND e.kpv IS NOT NULL AND e.kpv <= l_kpv), 0)
                                 - coalesce(sum(e.summa_kassa)
                                            FILTER (WHERE e.is_kulud = 0 AND e.kpv IS NOT NULL AND
                                                          e.kpv <= l_kpv AND
                                                          e.kood5 IN ('3500', '352', '3502')), 0)
                             ) AS eelarve_kassa_taps

                     FROM eelarve.eelarve e
                     WHERE e.rekvid = (CASE
                                           WHEN l_kond = 1
                                               THEN e.rekvid
                                           ELSE l_rekvid END)
                       AND e.rekvid IN (SELECT rekv_id
                                        FROM get_asutuse_struktuur(l_rekvid))
                       AND e.aasta = year(l_kpv)
                       AND e.status <> 3
                 ),
                      qryKassa AS (
                          -- Из Päevaraamat: дебет 100 art 3501 минус кредит 100 art 3501
                          SELECT coalesce((
                                              SELECT sum(summa) AS summa
                                              FROM (
                                                       SELECT j1.summa
                                                       FROM docs.doc d
                                                                INNER JOIN docs.journal j ON j.parentid = d.id
                                                                INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                                                       WHERE j.rekvid = (CASE
--                                                                             WHEN l_kond = 1 and l_rekvid = 63 then 63
                                                                             WHEN l_kond = 1
                                                                                 THEN j.rekvid
                                                                             ELSE l_rekvid END)
                                                         AND j.rekvid IN (SELECT rekv_id
                                                                          FROM get_asutuse_struktuur(l_rekvid))
                                                         AND j.kpv <= l_kpv
                                                         AND kpv >= make_date(year(l_kpv), 01, 01)
                                                         AND (j1.deebet LIKE '100%' OR left(j1.deebet, 6) = '999999')
                                                         AND j1.kood5 = '3501'
                                                         AND d.status <> 3
                                                       UNION ALL
                                                       SELECT -1 * j1.summa AS summa
                                                       FROM docs.doc d
                                                                INNER JOIN docs.journal j ON j.parentid = d.id
                                                                INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                                                       WHERE j.rekvid = (CASE
--                                                                             WHEN l_kond = 1 and l_rekvid = 63 then 63
                                                                             WHEN l_kond = 1
                                                                                 THEN j.rekvid
                                                                             ELSE l_rekvid END)
                                                         AND j.rekvid IN (SELECT rekv_id
                                                                          FROM get_asutuse_struktuur(l_rekvid))
                                                         AND j.kpv <= l_kpv
                                                         AND kpv >= make_date(year(l_kpv), 01, 01)
                                                         AND (j1.kreedit LIKE '100%' OR j1.kreedit LIKE '999999%')
                                                         AND j1.kood5 = '3501'
                                                         AND d.status <> 3
                                                   ) qry
                                          ), 0) AS kassa
                      )

                 SELECT '2.1',
                        1                           AS is_e,
                        $2                          AS rekvid,
                        ''::VARCHAR(20)             AS tegev,
                        ''::VARCHAR(20)             AS allikas,
                        '3501'::VARCHAR(20)         AS artikkel,
                        'Siirded eelarvest'         AS nimetus,
                        0                           AS eelarve,
                        0                           AS eelarve_kassa,
                        0                           AS eelarve_taps,
                        0                           AS eelarve_kassa_taps,
                        0                           AS tegelik,
                        coalesce(qryKassa.kassa, 0) AS kassa,
                        coalesce(qryKassa.kassa, 0) AS saldoandmik
                 FROM qryEelarve,
                      qryKassa
             ) a;
END;
$$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;


--GRANT EXECUTE ON FUNCTION eelarve_andmik(DATE, INTEGER, INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_andmik_lisa_1_5(DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_andmik_lisa_1_5(DATE, INTEGER, INTEGER ) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_andmik_lisa_1_5(DATE, INTEGER, INTEGER ) TO dbvaatleja;

/*
SELECT *
FROM (
         SELECT *
         FROM eelarve.eelarve_andmik_lisa_1_5(DATE(2022,06, 30),130, 1) qry
         where artikkel like '3501%'
     ) qry
--test
-- 12330698.41

select * from eelarve.saldoandmik
where konto like '382%'
and aasta = 2021

select get_saldo('MKD', '208', '00', NULL) ,
             get_saldo('MKD', '258', '00', NULL)






SELECT *
FROM eelarve.eelarve
WHERE eelarve.kood5 = '320'
  AND aasta = 2021
  AND id NOT IN (SELECT new_id FROM import_log WHERE lib_name = 'EELARVE')


select get_saldo('MDK', '100', NULL, NULL) as s_100,  get_saldo('MDK', '101', NULL, NULL) as s_101,
                            get_saldo('MDK', '1019', NULL, NULL)  as s_1019,
                            get_saldo('MDK', '151', NULL, NULL) as s_151,
                            get_saldo('MDK', '1519', NULL, NULL) as s_1519

 */