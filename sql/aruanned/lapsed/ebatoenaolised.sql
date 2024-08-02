DROP FUNCTION IF EXISTS lapsed.ebatoenaolised(INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.ebatoenaolised(l_rekvid INTEGER,
                                                 l_kpv DATE DEFAULT current_date)
    RETURNS TABLE (
        rekvid           INTEGER,
        kpv              DATE,
        number           TEXT,
        tahtaeg          DATE,
        lapse_nimi       TEXT,
        lapse_isikukood  TEXT,
        maksja_nimi      TEXT,
        maksja_isikukood TEXT,
        noude_50         NUMERIC(12, 2),
        noude_100        NUMERIC(12, 2),
        jaak             NUMERIC(12, 2),
        doc_id           INTEGER,
        konto            VARCHAR(20)
    )
AS
$BODY$
WITH report AS (
    SELECT rekvid,
           l_kpv                                                                      AS kpv,
           number,
           tahtaeg,
           lapse_nimi,
           lapse_isikukood,
           maksja_nimi,
           maksja_isikukood,
           CASE WHEN paevad >= 90 AND paevad < 180 and jaak >= 0  THEN round(jaak / 2, 2) ELSE 0 END AS noude_50,
           CASE WHEN paevad >= 180 and jaak >= 0 THEN jaak ELSE 0 END                               AS noude_100,
           jaak,
           doc_id
    FROM (
             WITH arvtasu AS (
                 SELECT doc_arv_id AS arv_id, sum(summa) AS summa
                 FROM docs.arvtasu at
                 WHERE at.status < 3
                   AND at.kpv <= l_kpv
                   AND at.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                 GROUP BY doc_arv_id
             )
             SELECT d.rekvid,
                    a.kpv,
                    a.number::TEXT,
                    a.tahtaeg,
                    (l_kpv - coalesce(a.tahtaeg, a.kpv))              AS paevad,
                    (a.summa - coalesce(at.summa, 0))::NUMERIC(12, 2) AS jaak,
                    laps.isikukood::TEXT                              AS lapse_isikukood,
                    laps.nimi::TEXT                                   AS lapse_nimi,
                    m.regkood::TEXT                                   AS maksja_isikukood,
                    m.nimetus::TEXT                                   AS maksja_nimi,
                    d.id                                              AS doc_id
             FROM docs.doc d
                      INNER JOIN docs.arv a ON a.parentid = d.id
                      INNER JOIN libs.asutus m ON m.id = a.asutusid
                      LEFT OUTER JOIN lapsed.liidestamine l ON l.docid = d.id
                      LEFT OUTER JOIN lapsed.laps laps ON laps.id = l.parentid
                      LEFT OUTER JOIN arvtasu at ON d.id = at.arv_id
             WHERE a.tahtaeg <= l_kpv
--           AND coalesce((a.properties ->> 'ebatoenaolised_1_id')::INTEGER, 0) > 0
               AND d.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
--               AND a.jaak >= 0
         ) qry
--    WHERE qry.jaak > 0
)
SELECT *,
       CASE WHEN lapse_isikukood IS NULL THEN '10300928' ELSE '10300929' END::VARCHAR(20) AS konto
FROM report r


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.ebatoenaolised(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.ebatoenaolised(INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.ebatoenaolised(INTEGER, DATE) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.ebatoenaolised(INTEGER, DATE) TO dbvaatleja;


/*
select * from lapsed.ebatoenaolised(94, '2024-06-30')
where konto = '10300928'
maksja_nimi ilike '%Pidvy%'
from ou.rekv where parentid = 119
*/
