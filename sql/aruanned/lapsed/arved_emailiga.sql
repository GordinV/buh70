DROP FUNCTION IF EXISTS lapsed.arved_emailiga(INTEGER, DATE, DATE);


CREATE OR REPLACE FUNCTION lapsed.arved_emailiga(l_rekvid INTEGER,
                                                 kpv_start DATE DEFAULT date(year(current_date), 1, 1),
                                                 kpv_end DATE DEFAULT current_date)
    RETURNS TABLE (
        id               INTEGER,
        rekvid           INTEGER,
        asutus           TEXT,
        number           TEXT,
        kpv              DATE,
        maksja           TEXT,
        viitenumber      TEXT,
        lapse_nimi       TEXT,
        saadetud         TEXT, -- время и дата отправки счета
        saatmise_staatus TEXT
    )
AS
$BODY$
WITH qryRekv AS (
    SELECT rekv_id
    FROM get_asutuse_struktuur(l_rekvid)
),
     params AS (
         SELECT coalesce(kpv_start, make_date(year(now()::DATE) - 1, 01, 01)) AS kpv_1,
                coalesce(kpv_end, make_date(year(now()::DATE), 12, 31))       AS kpv_2
     ),
     arved AS (
         SELECT d.id,
                d.rekvid,
                d.history,
                a.kpv,
                a.number,
                asutus.nimetus                                                                         AS maksja,
                coalesce((a.properties ->> 'viitenr'), lapsed.get_viitenumber(d.rekvid, l.id)) :: TEXT AS viitenr,
                l.nimi                                                                                 AS lapse_nimi,
                CASE
                    WHEN position('"email"' IN d.history::TEXT) > 0 THEN 'SAADETUD'
                    WHEN position('email_error' IN history::TEXT) > 0
                        THEN 'VIGANE'
                    WHEN position('email_viga' IN history::TEXT) > 0
                        THEN 'VIGANE'
                    WHEN empty(asutus.email) THEN 'PUUDUB EMAIL'
                    ELSE 'MUUD'
                    END                                                                                AS saatmise_staatus
         FROM docs.doc d
                  INNER JOIN docs.arv a ON d.id = a.parentid
                  INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                  INNER JOIN lapsed.laps l ON l.id = ld.parentid
                  INNER JOIN libs.asutus asutus ON a.asutusid = asutus.id
                  INNER JOIN lapsed.vanem_arveldus va
                             ON l.id = va.parentid AND va.asutusid = asutus.id AND va.rekvid = a.rekvid
                 ,
              params p
         WHERE a.kpv >= p.kpv_1
           AND a.kpv <= p.kpv_2
           AND d.doc_type_id IN (SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood = 'ARV')
           AND d.rekvid IN (SELECT rekv_id FROM qryRekv)
           AND (va.properties ->> 'email_alates' IS NULL OR
                (va.properties ->> 'email_alates')::DATE <= (a.kpv + INTERVAL '1 month'))
           AND va.kas_email),
     logs AS (
         WITH doc AS (
             SELECT qry.id,
                    to_char((ajalugu ->> 'email')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS')         AS email,
                    to_char((ajalugu ->> 'email_error')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS')   AS email_error,
                    to_char((ajalugu ->> 'email_viga')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS')    AS email_viga,
                    to_char((ajalugu ->> 'email_error_1')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS') AS email_error_1,
                    to_char((ajalugu ->> 'email_error_2')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS') AS email_error_2,
                    to_char((ajalugu ->> 'email_error_3')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS') AS email_error_3

             FROM (
                      SELECT jsonb_array_elements(history) AS ajalugu, a.id
                      FROM arved a
                  ) qry
         )
         SELECT d.id, max(saadetud) AS saadetud
         FROM (
                  SELECT l.id,
                         CASE
                             WHEN l.email IS NOT NULL THEN l.email
                             WHEN l.email_error IS NOT NULL THEN l.email_error
                             WHEN l.email_viga IS NOT NULL THEN l.email_viga
                             WHEN l.email_error_3 IS NOT NULL THEN l.email_error_3
                             WHEN l.email_error_2 IS NOT NULL THEN l.email_error_2
                             WHEN l.email_error_1 IS NOT NULL THEN l.email_error_1
                             END AS saadetud
                  FROM doc l) d
         GROUP BY d.id
     )
SELECT a.id,
       a.rekvid,
       r.nimetus        AS asutus,
       a.number::TEXT,
       a.kpv,
       a.maksja::TEXT,
       a.viitenr::TEXT  AS viitenumber,
       a.lapse_nimi::TEXT,
       l.saadetud::TEXT AS saadetud,
       a.saatmise_staatus::TEXT
FROM arved a
         LEFT OUTER JOIN logs l ON l.id = a.id
         INNER JOIN ou.rekv r ON r.id = a.rekvid
ORDER BY a.kpv DESC, a.number
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.arved_emailiga(INTEGER, DATE, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.arved_emailiga(INTEGER, DATE, DATE) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.arved_emailiga(INTEGER, DATE, DATE) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.arved_emailiga(INTEGER, DATE, DATE) TO arvestaja;

/*

SELECT *
FROM  lapsed.arved_emailiga(69, null::date, null::date)
where empty(saadetud)
limit 100

--test
*/
