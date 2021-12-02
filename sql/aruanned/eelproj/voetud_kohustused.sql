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
       coalesce(aasta_kokku_pohiosa, 0) AS aasta_kokku_pohiosa,
       coalesce(aasta_kokku_intress, 0) AS aasta_kokku_intress
FROM (
         SELECT 'Laen'::VARCHAR(254)                                                    AS liik,
                sum(db) FILTER (WHERE konto = '910010' AND rahavoo = '93')              AS aasta_1_pohiosa,
                sum(db) FILTER (WHERE konto = '910019' AND rahavoo = '93')              AS aasta_1_intress,
                sum(db) FILTER (WHERE konto = '910010' AND rahavoo = '94')              AS aasta_2_pohiosa,
                sum(db) FILTER (WHERE konto = '910019' AND rahavoo = '94')              AS aasta_2_intress,
                sum(db) FILTER (WHERE konto = '910010' AND rahavoo = '95')              AS aasta_3_pohiosa,
                sum(db) FILTER (WHERE konto = '910019' AND rahavoo = '95')              AS aasta_3_intress,
                sum(db) FILTER (WHERE konto = '910010' AND rahavoo = '96')              AS aasta_4_pohiosa,
                sum(db) FILTER (WHERE konto = '910019' AND rahavoo = '96')              AS aasta_4_intress,
                sum(db)
                FILTER (WHERE konto = '910010' AND rahavoo IN ('93', '94', '95', '96')) AS aasta_kokku_pohiosa,
                sum(db)
                FILTER (WHERE konto = '910019' AND rahavoo IN ('93', '94', '95', '96')) AS aasta_kokku_intress
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
           AND kpv >= make_date((year(l_kpv) - 1), 12, 31)
           AND kpv < make_date((year(l_kpv)), 12, 31)
         UNION ALL
         SELECT 'Kapitalirent'::VARCHAR(254)                                            AS liik,
                sum(db) FILTER (WHERE konto = '910020' AND rahavoo = '93')              AS aasta_1_pohiosa,
                sum(db) FILTER (WHERE konto = '910029' AND rahavoo = '93')              AS aasta_1_intress,
                sum(db) FILTER (WHERE konto = '910020' AND rahavoo = '94')              AS aasta_2_pohiosa,
                sum(db) FILTER (WHERE konto = '910029' AND rahavoo = '94')              AS aasta_2_intress,
                sum(db) FILTER (WHERE konto = '910020' AND rahavoo = '95')              AS aasta_3_pohiosa,
                sum(db) FILTER (WHERE konto = '910029' AND rahavoo = '95')              AS aasta_3_intress,
                sum(db) FILTER (WHERE konto = '910020' AND rahavoo = '96')              AS aasta_4_pohiosa,
                sum(db) FILTER (WHERE konto = '910029' AND rahavoo = '96')              AS aasta_4_intress,
                sum(db)
                FILTER (WHERE konto = '910020' AND rahavoo IN ('93', '94', '95', '96')) AS aasta_kokku_pohiosa,
                sum(db)
                FILTER (WHERE konto = '910029' AND rahavoo IN ('93', '94', '95', '96')) AS aasta_kokku_intress
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

           AND kpv >= make_date((year(l_kpv) - 1), 12, 31)
           AND kpv < make_date((year(l_kpv)), 12, 31)
     ) qry
ORDER BY liik desc
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
FROM eelarve.voetud_kohustused(current_date::DATE, 63:: INTEGER, 0)


*/


