DROP FUNCTION IF EXISTS eelarve.lisa_9(DATE, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.lisa_9_(DATE, DATE, INTEGER, INTEGER);

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
        tegev          VARCHAR(20),
        docs_ids       INTEGER[]
    )
AS
$BODY$

SELECT rekv_id,
       maksja_regkood,
       saaja_regkood,
       saaja_tp,
       left(ltrim(rtrim(saaja_nimi)), 98)::TEXT AS saaja_nimi,
       kpv,
       sum(summa)                               AS summa,
       artikkel,
       tegev,
       array_agg(id)                            AS docs_ids
FROM (
         SELECT j.rekvid::INTEGER              AS rekv_id,
                r.regkood::VARCHAR(20)         AS maksja_regkood,
                a.regkood::VARCHAR(20)         AS saaja_regkood,
                a.tp::VARCHAR(20)              AS saaja_tp,
                a.nimetus::TEXT                AS saaja_nimi,
                j.kpv::DATE                    AS kpv,
                j.summa::NUMERIC(14, 2)        AS summa,
                CASE
                    WHEN (j.deebet::TEXT LIKE '208120%'::TEXT OR j.deebet::TEXT LIKE '20%'::TEXT) AND
                         j.kreedit::TEXT LIKE '100100%'::TEXT AND j.kood5::TEXT = '2586'::TEXT AND
                         j.kood3::TEXT = '06'::TEXT
                        THEN '20'::BPCHAR
                    ELSE left(j.kood5, 2)
                    END::CHARACTER VARYING(20) AS artikkel,
                j.kood1::VARCHAR(20)           AS tegev,
                J.id

         FROM cur_journal j
                  INNER JOIN ou.rekv r ON r.id = j.rekvid
                  INNER JOIN libs.asutus a ON a.id = j.asutusid
         WHERE j.rekvid = (CASE
                               WHEN l_kond = 1
                                   THEN j.rekvid
                               ELSE l_rekvid END)
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND j.kpv >= l_kpv1
           AND j.kpv <= l_kpv2
           AND (j.kreedit LIKE '100%'
                    AND left(j.kood5, 2) IN ('15', '20', '25', '41', '45', '50', '55', '65')
                    AND left(j.lisa_d, 6) NOT IN ('185101', '800699', '014001')
             OR (j.deebet::TEXT LIKE '208120%'::TEXT OR j.deebet::TEXT LIKE '20%'::TEXT) AND
                j.kreedit::TEXT LIKE '100100%'::TEXT
                    AND j.kood5::TEXT = '2586'::TEXT AND j.kood3::TEXT = '06'::TEXT)
           AND j.deebet NOT LIKE '100%'
           AND deebet NOT IN ('203620')
           -- J.Tekanina
           AND j.id NOT IN (SELECT id
                            FROM cur_journal
                            WHERE deebet = '203910'
                              AND kood5 = '2586'
                              AND j.kpv >= l_kpv1
                              AND j.kpv <= l_kpv2
                              AND j.rekvid IN (SELECT rekv_id
                                               FROM get_asutuse_struktuur(l_rekvid))
         )
     ) qry
--WHERE saaja_tp <> '800699'

GROUP BY rekv_id, maksja_regkood, saaja_regkood, saaja_tp, saaja_nimi, kpv, artikkel, tegev;


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.lisa_9(DATE, DATE, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.lisa_9(DATE, DATE, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.lisa_9(DATE, DATE, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.lisa_9(DATE, DATE, INTEGER, INTEGER) TO dbvaatleja;
/*

select * from (
                    SELECT len(saaja_nimi), *
                    FROM eelarve.lisa_9('2022-06-01', '2022-06-30', 63,  1)
                ) qry
  where  summa >= 100
and saaja_regkood= '80356461'

select * from ou.rekv where parentid = 64

select * from cur_journal where id = 3198106

select * from libs.asutus where id = 7455
*/


