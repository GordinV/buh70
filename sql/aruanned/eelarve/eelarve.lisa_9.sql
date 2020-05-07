DROP FUNCTION IF EXISTS eelarve.lisa_9(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.lisa_9(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE (
        rekv_id        INTEGER,
        maksja_regkood VARCHAR(20),
        saaja_regkood  VARCHAR(20),
        saaja_tp       VARCHAR(20),
        saaja_nimi     TEXT,
        kpv            DATE,
        summa          NUMERIC(14, 2),
        artikkel       VARCHAR(20),
        tegev          VARCHAR(20)
    ) AS
$BODY$
SELECT j.rekvid::INTEGER            AS rekv_id,
       r.regkood::VARCHAR(20)       AS maksja_regkood,
       a.regkood::VARCHAR(20)       AS saaja_regkood,
       a.tp::VARCHAR(20)            AS saaja_tp,
       a.nimetus::TEXT     AS saaja_nimi,
       j.kpv::DATE                  AS kpv,
       sum(j.summa)::NUMERIC(14, 2) AS summa,
       j.kood5::VARCHAR(20)         AS artikkel,
       j.kood1::VARCHAR(20)         AS tegev

FROM cur_journal j
         INNER JOIN ou.rekv r ON r.id = j.rekvid
         INNER JOIN libs.asutus a ON a.id = j.asutusid
    WHERE
     j.rekvid = (CASE
                     WHEN l_kond = 1
                         THEN j.rekvid
                     ELSE l_rekvid END)
         AND j.rekvid IN (SELECT rekv_id
                          FROM get_asutuse_struktuur(l_rekvid))
         AND j.kpv >= l_kpv1 AND j.kpv <= l_kpv2
         AND j.kreedit LIKE '100%' --
         AND j.deebet LIKE '201%'
    GROUP BY
     j.rekvid,
     r.regkood,
     a.regkood,
     a.tp,
     a.nimetus,
     j.kpv,
     j.kood1,
     j.kood5;


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.lisa_9(DATE, DATE, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.lisa_9(DATE, DATE, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.lisa_9(DATE, DATE, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.lisa_9(DATE, DATE, INTEGER, INTEGER) TO dbvaatleja;
/*
selec

SELECT *
FROM eelarve.lisa_9('2020-01-01', '2020-06-30', 63,  1)

*/