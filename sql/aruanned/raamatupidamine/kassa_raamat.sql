DROP FUNCTION IF EXISTS docs.kassa_raamat(DATE, DATE, INTEGER);

CREATE OR REPLACE FUNCTION docs.kassa_raamat(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER)
    RETURNS TABLE (
        rekv_id          INTEGER,
        kassa            VARCHAR(120),
        kpv              DATE,
        alus             TEXT,
        alg_saldo        NUMERIC(14, 2),
        alg_paevi_saldo  NUMERIC(14, 2),
        deebet           NUMERIC(14, 2),
        kreedit          NUMERIC(14, 2),
        lopp_saldo       NUMERIC(14, 2),
        lopp_paevi_saldo NUMERIC(14, 2),
        number           VARCHAR(20),
        isik             VARCHAR(254),
        konto            VARCHAR(20),
        kood1            VARCHAR(20),
        kood2            VARCHAR(20),
        kood3            VARCHAR(20),
        kood4            VARCHAR(20),
        kood5            VARCHAR(20),
        tunnus           VARCHAR(20)

    )
AS
$BODY$
DECLARE
    v_orderid         RECORD;
    l_alg_saldo       NUMERIC(14, 2) = 0;
    l_alg_paevi_saldo NUMERIC(14, 2) = 0;
    l_kassa           TEXT;
    l_kpv             DATE;
BEGIN
    DROP TABLE IF EXISTS temp_kassaraamat_table;

    CREATE TEMPORARY TABLE temp_kassaraamat_table (
        rekv_id          INTEGER,
        kassa            VARCHAR(120),
        kpv              DATE,
        alus             TEXT,
        alg_saldo        NUMERIC(14, 2),
        alg_paevi_saldo  NUMERIC(14, 2),
        deebet           NUMERIC(14, 2),
        kreedit          NUMERIC(14, 2),
        lopp_saldo       NUMERIC(14, 2),
        lopp_paevi_saldo NUMERIC(14, 2),
        number           VARCHAR(20),
        isik             VARCHAR(254),
        konto            VARCHAR(20),
        kood1            VARCHAR(20),
        kood2            VARCHAR(20),
        kood3            VARCHAR(20),
        kood4            VARCHAR(20),
        kood5            VARCHAR(20),
        tunnus           VARCHAR(20)
    );

    FOR v_orderid IN
        WITH algsaldo AS (
            SELECT sum(coalesce(qry.deebet, 0)) - sum(coalesce(qry.kreedit, 0)) AS alg_saldo,
                   qry.kassaid,
                   qry.rekvid
            FROM (
                     SELECT d.rekvid,
                            k.kassaid,
                            CASE WHEN k.tyyp = 1 THEN k.summa ELSE 0 END::NUMERIC AS deebet,
                            CASE WHEN k.tyyp = 2 THEN k.summa ELSE 0 END::NUMERIC AS kreedit
                     FROM docs.doc d
                              INNER JOIN docs.korder1 k ON k.parentid = d.id
                     WHERE k.kpv < l_kpv1
                       AND d.status <> 3
                       AND d.rekvid IN (SELECT qry.rekv_id
                                        FROM get_asutuse_struktuur(l_rekvid) qry)
                 ) qry
            GROUP BY qry.kassaid, qry.rekvid)
        SELECT qry.rekvid,
               qry.kassa,
               qry.kpv,
               qry.alus,
               qry.deebet              AS deebet,
               qry.kreedit::NUMERIC    AS kreedit,
               qry.number              AS number,
               qry.isik:: VARCHAR(254) AS isik,
               qry.konto::VARCHAR(20)  AS konto,
               qry.kood1::VARCHAR(20)  AS kood1,
               qry.kood2::VARCHAR(20)  AS kood2,
               qry.kood3::VARCHAR(20)  AS kood3,
               qry.kood4::VARCHAR(20)  AS kood4,
               qry.kood5::VARCHAR(20)  AS kood5,
               qry.tunnus::VARCHAR(20) AS tunnus
        FROM (
                 SELECT rekvid,
                        aa.nimetus::VARCHAR(120)                        AS kassa,
                        $1 - 1                                          AS kpv,
                        'Alg. saldo'                                    AS alus,
                        coalesce(algsaldo.alg_saldo, 0)::NUMERIC(14, 2) AS deebet,
                        0::NUMERIC(14, 2)                               AS kreedit,
                        ''                                              AS number,
                        '':: VARCHAR(254)                               AS isik,
                        ''::VARCHAR(20)                                 AS konto,
                        ''::VARCHAR(20)                                 AS kood1,
                        ''::VARCHAR(20)                                 AS kood2,
                        ''::VARCHAR(20)                                 AS kood3,
                        ''::VARCHAR(20)                                 AS kood4,
                        ''::VARCHAR(20)                                 AS kood5,
                        ''::VARCHAR(20)                                 AS tunnus
                 FROM algsaldo
                          LEFT OUTER JOIN ou.aa aa ON aa.id = algsaldo.kassaid
                 UNION ALL
                 SELECT d.rekvid,
                        aa.nimetus::VARCHAR(120)                               AS kassa,
                        k.kpv,
                        k.alus,
                        CASE WHEN k.tyyp = 1 THEN k2.summa ELSE 0 END::NUMERIC AS deebet,
                        CASE WHEN k.tyyp = 2 THEN k2.summa ELSE 0 END::NUMERIC AS kreedit,
                        k.number                                               AS number,
                        k.nimi:: VARCHAR(254)                                  AS isik,
                        k2.konto::VARCHAR(20)                                  AS konto,
                        k2.kood1::VARCHAR(20)                                  AS kood1,
                        k2.kood2::VARCHAR(20)                                  AS kood2,
                        k2.kood3::VARCHAR(20)                                  AS kood3,
                        k2.kood4::VARCHAR(20)                                  AS kood4,
                        k2.kood5::VARCHAR(20)                                  AS kood5,
                        k2.tunnus::VARCHAR(20)                                 AS tunnus
                 FROM docs.doc d
                          INNER JOIN docs.korder1 k ON d.id = k.parentid
                          INNER JOIN(SELECT sum(coalesce(k2.summa, 0))                                          AS summa,
                                            k2.konto,
                                            coalesce(k2.kood1, '')                                              AS kood1,
                                            coalesce(k2.kood2, '')                                              AS kood2,
                                            coalesce(CASE WHEN k2.kood3 = 'null' THEN '' ELSE k2.kood3 END, '') AS kood3,
                                            coalesce(k2.kood4, '')                                              AS kood4,
                                            coalesce(k2.kood5, '')                                              AS kood5,
                                            k2.tunnus,
                                            k2.parentid
                                     FROM docs.korder2 k2
                                     GROUP BY k2.konto, k2.kood1, k2.kood2,
                                              coalesce(CASE WHEN k2.kood3 = 'null' THEN '' ELSE k2.kood3 END, ''),
                                              k2.kood4, k2.kood5, k2.tunnus,
                                              k2.parentid
                 ) k2 ON k2.parentid = k.id
                          LEFT OUTER JOIN ou.aa aa ON k.kassaid = aa.id
                 WHERE k.kpv >= $1
                   AND k.kpv <= $2
                   AND d.rekvid IN (SELECT qry.rekv_id
                                    FROM get_asutuse_struktuur(l_rekvid) qry)
                   AND d.status <> 3
             ) qry
        ORDER BY qry.kassa, qry.kpv
        LOOP
            IF l_kassa IS NULL OR l_kassa <> v_orderid.kassa
            THEN
                l_kassa = v_orderid.kassa;
                l_alg_saldo = 0;
                l_alg_paevi_saldo = 0;

            END IF;

            IF l_kpv IS NULL OR l_kpv <> v_orderid.kpv
            THEN
                IF l_kpv IS NOT NULL
                THEN
                    UPDATE temp_kassaraamat_table
                    SET lopp_paevi_saldo = coalesce(l_alg_saldo, 0)
                    WHERE temp_kassaraamat_table.kassa = l_kassa
                      AND temp_kassaraamat_table.kpv = l_kpv;
                END IF;

                l_kpv = v_orderid.kpv;
                l_alg_paevi_saldo = l_alg_saldo;
            END IF;

            INSERT INTO temp_kassaraamat_table (rekv_id, kassa, kpv, alus, alg_saldo, alg_paevi_saldo, deebet, kreedit,
                                                lopp_saldo, number,
                                                isik, konto, kood1, kood2, kood3, kood4, kood5, tunnus,
                                                lopp_paevi_saldo)
            VALUES (v_orderid.rekvid,
                    v_orderid.kassa,
                    v_orderid.kpv,
                    v_orderid.alus,
                    l_alg_saldo,
                    l_alg_paevi_saldo,
                    v_orderid.deebet,
                    v_orderid.kreedit,
                    (coalesce(l_alg_saldo, 0) + coalesce(v_orderid.deebet, 0) - coalesce(v_orderid.kreedit, 0)),
                    v_orderid.number,
                    v_orderid.isik,
                    v_orderid.konto,
                    v_orderid.kood1,
                    v_orderid.kood2,
                    v_orderid.kood3,
                    v_orderid.kood4,
                    v_orderid.kood5,
                    v_orderid.tunnus,
                    (coalesce(l_alg_saldo, 0) + coalesce(v_orderid.deebet, 0) - coalesce(v_orderid.kreedit, 0)));

            -- сохраним сальдо
            l_alg_saldo = coalesce(l_alg_saldo, 0) + coalesce(v_orderid.deebet, 0) - coalesce(v_orderid.kreedit, 0);

        END LOOP;
    UPDATE temp_kassaraamat_table
    SET lopp_paevi_saldo = coalesce(l_alg_saldo, 0)
    WHERE temp_kassaraamat_table.kassa = l_kassa
      AND temp_kassaraamat_table.kpv = l_kpv;


    RETURN QUERY SELECT * FROM temp_kassaraamat_table;
END;
$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.kassa_raamat( DATE, DATE, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kassa_raamat( DATE, DATE, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kassa_raamat( DATE, DATE, INTEGER ) TO dbkasutaja;



SELECT *
FROM docs.kassa_raamat('2021-09-30', current_date :: DATE, 64)
WHERE number = '1600'
