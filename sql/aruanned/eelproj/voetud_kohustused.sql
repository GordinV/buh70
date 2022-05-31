DROP FUNCTION IF EXISTS eelarve.voetud_kohustused(DATE, INTEGER);
DROP FUNCTION IF EXISTS eelarve.voetud_kohustused(DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.voetud_kohustused(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE (
        liik                VARCHAR(254),
        aasta_1_pohiosa     NUMERIC(14, 2),
        aasta_1_intress     NUMERIC(14, 2),
        aasta_2_pohiosa     NUMERIC(14, 2),
        aasta_2_intress     NUMERIC(14, 2),
        aasta_3_pohiosa     NUMERIC(14, 2),
        aasta_3_intress     NUMERIC(14, 2),
        aasta_4_pohiosa     NUMERIC(14, 2),
        aasta_4_intress     NUMERIC(14, 2),
        aasta_5_pohiosa     NUMERIC(14, 2),
        aasta_5_intress     NUMERIC(14, 2),
        aasta_6_pohiosa     NUMERIC(14, 2),
        aasta_6_intress     NUMERIC(14, 2),
        aasta_kokku_pohiosa NUMERIC(14, 2),
        aasta_kokku_intress NUMERIC(14, 2)
    )
AS
$BODY$

SELECT liik,
       coalesce(aasta_1_pohiosa, 0)     AS aasta_1_pohiosa,
       coalesce(aasta_1_intress, 0)     AS aasta_1_intress,
       coalesce(aasta_2_pohiosa, 0)     AS aasta_2_pohiosa,
       coalesce(aasta_2_intress, 0)     AS aasta_2_intress,
       coalesce(aasta_3_pohiosa, 0)     AS aasta_3_pohiosa,
       coalesce(aasta_3_intress, 0)     AS aasta_3_intress,
       coalesce(aasta_4_pohiosa, 0)     AS aasta_4_pohiosa,
       coalesce(aasta_4_intress, 0)     AS aasta_4_intress,
       coalesce(aasta_5_pohiosa, 0)     AS aasta_5_pohiosa,
       coalesce(aasta_5_intress, 0)     AS aasta_5_intress,
       coalesce(aasta_6_pohiosa, 0)     AS aasta_6_pohiosa,
       coalesce(aasta_6_intress, 0)     AS aasta_6_intress,
       coalesce(aasta_kokku_pohiosa, 0) AS aasta_kokku_pohiosa,
       coalesce(aasta_kokku_intress, 0) AS aasta_kokku_intress
FROM (
         SELECT 'Laen'::VARCHAR(254)                                                                AS liik,
                sum(db) FILTER (WHERE konto = '910010'
                    AND (rahavoo = '92' AND kpv = make_date((year(l_kpv)), 12, 31)
                        OR rahavoo = '93' AND kpv = make_date((year(l_kpv) - 1), 12, 31)
                                          )
                    )                                                                               AS aasta_1_pohiosa,
                sum(db) FILTER (WHERE konto = '910019'
                    AND (rahavoo = '93' AND kpv = make_date((year(l_kpv)), 12, 31)
                        OR rahavoo = '94' AND kpv = make_date((year(l_kpv) - 1), 12, 31))
                    )                                                                               AS aasta_2_intress,
                sum(db) FILTER (WHERE konto = '910010'
                    AND (rahavoo = '93' AND kpv = make_date((year(l_kpv)), 12, 31)
                        OR rahavoo = '94' AND kpv = make_date((year(l_kpv) - 1), 12, 31)
                                          )
                    )                                                                               AS aasta_2_pohiosa,
                sum(db) FILTER (WHERE konto = '910019'
                    AND (rahavoo = '92' AND kpv = make_date((year(l_kpv)), 12, 31)
                        OR rahavoo = '93' AND kpv = make_date((year(l_kpv) - 1), 12, 31))
                    )                                                                               AS aasta_1_intress,
                sum(db) FILTER (WHERE konto = '910010' AND
                                      rahavoo = (94 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_3_pohiosa,
                sum(db) FILTER (WHERE konto = '910019' AND
                                      rahavoo = (94 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_3_intress,
                sum(db) FILTER (WHERE konto = '910010' AND
                                      rahavoo = (95 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_4_pohiosa,
                sum(db) FILTER (WHERE konto = '910019' AND
                                      rahavoo = (95 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_4_intress,
                sum(db) FILTER (WHERE konto = '910010' AND
                                      rahavoo = (96 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_5_pohiosa,
                sum(db) FILTER (WHERE konto = '910019' AND
                                      rahavoo = (96 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_5_intress,
                sum(db) FILTER (WHERE konto = '910010' AND
                                      rahavoo = (97 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_6_pohiosa,
                sum(db) FILTER (WHERE konto = '910019' AND
                                      rahavoo = (97 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_6_intress,
                sum(db)
                FILTER (WHERE konto = '910010' AND rahavoo IN ('91', '92', '93', '94', '95', '96')) AS aasta_kokku_pohiosa,
                sum(db)
                FILTER (WHERE konto = '910019' AND rahavoo IN ('91', '92', '93', '94', '95', '96')) AS aasta_kokku_intress
         FROM eelarve.saldoandmik
         WHERE rekvid = (CASE
                             WHEN l_kond = 1 and l_rekvid = 63 THEN 999
                             WHEN l_kond = 1 and l_rekvid <> 63
                                 THEN rekvid
                             ELSE l_rekvid END)
           AND rekvid IN (SELECT rekv_id
                          FROM get_asutuse_struktuur(l_rekvid)
                          UNION ALL
                          SELECT l_rekvid
         )
         UNION ALL
         SELECT 'Kapitalirent'::VARCHAR(254)                                                        AS liik,
                sum(db) FILTER (WHERE konto = '910020' AND
                                      rahavoo = (92 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_1_pohiosa,
                sum(db) FILTER (WHERE konto = '910029' AND
                                      rahavoo = (92 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_1_intress,
                sum(db) FILTER (WHERE konto = '910020' AND
                                      rahavoo = (93 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_2_pohiosa,
                sum(db) FILTER (WHERE konto = '910029' AND
                                      rahavoo = (93 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_2_intress,
                sum(db) FILTER (WHERE konto = '910020' AND
                                      rahavoo = (94 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_3_pohiosa,
                sum(db) FILTER (WHERE konto = '910029' AND
                                      rahavoo = (94 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_3_intress,
                sum(db) FILTER (WHERE konto = '910020' AND
                                      rahavoo = (95 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_4_pohiosa,
                sum(db) FILTER (WHERE konto = '910029' AND
                                      rahavoo = (95 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_4_intress,
                sum(db) FILTER (WHERE konto = '910020' AND
                                      rahavoo = (96 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_5_pohiosa,
                sum(db) FILTER (WHERE konto = '910029' AND
                                      rahavoo = (96 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_5_intress,
                sum(db) FILTER (WHERE konto = '910020' AND
                                      rahavoo = (97 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_6_pohiosa,
                sum(db) FILTER (WHERE konto = '910029' AND
                                      rahavoo = (97 + year(l_kpv) - year(current_date))::TEXT)      AS aasta_6_intress,
                sum(db)
                FILTER (WHERE konto = '910020' AND rahavoo IN ('91', '92', '93', '94', '95', '96')) AS aasta_kokku_pohiosa,
                sum(db)
                FILTER (WHERE konto = '910029' AND rahavoo IN ('91', '92', '93', '94', '95', '96')) AS aasta_kokku_intress
         FROM eelarve.saldoandmik
         WHERE rekvid = (CASE
                             WHEN l_kond = 1
                                 THEN rekvid
                             ELSE l_rekvid END)
           AND rekvid IN (SELECT rekv_id
                          FROM get_asutuse_struktuur(l_rekvid)
                          UNION ALL
                          SELECT l_rekvid
         )
           AND kpv = make_date((year(l_kpv)), 12, 31)
     ) qry
ORDER BY liik DESC
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.voetud_kohustused(DATE, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.voetud_kohustused(DATE, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.voetud_kohustused(DATE, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.voetud_kohustused(DATE, INTEGER, INTEGER) TO dbvaatleja;


/*

SELECT *
FROM eelarve.voetud_kohustused('2022-12-31'::DATE, 63:: INTEGER, 1)



SELECT *
FROM eelarve.saldoandmik
WHERE konto = '910010'
  AND rahavoo IN ('92', '93')
  AND kpv = '2021-12-31'

*/
