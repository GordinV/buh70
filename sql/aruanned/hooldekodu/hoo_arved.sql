DROP FUNCTION IF EXISTS hooldekodu.hoo_arved(DATE, DATE, INTEGER, INTEGER);


CREATE OR REPLACE FUNCTION hooldekodu.hoo_arved(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
                                                l_kond INTEGER DEFAULT 0)
    RETURNS TABLE (
        number           VARCHAR(20),
        kpv              DATE,
        teenuse_maksumus NUMERIC(14, 2),
        hooldus_kulud    NUMERIC(14, 2),
        kov_osa          NUMERIC(14, 2),
        sugulaste_osa    NUMERIC(14, 2),
        dok_summa        NUMERIC(14, 2),
        asutus           VARCHAR(254),
        tahtaeg          DATE,
        tasud            DATE,
        jaak             NUMERIC(14, 2),
        laus_nr          INTEGER
    )
AS
$BODY$
WITH rekv_ids AS (
    SELECT rekv_id
    FROM public.get_asutuse_struktuur(l_rekvid) r
    WHERE CASE
              WHEN l_kond = 1 THEN TRUE
              ELSE l_rekvid = rekv_id END
),
     lepingud AS (
         SELECT isikid, summa
         FROM hooldekodu.hooleping
         WHERE rekvid IN (SELECT rekv_id FROM rekv_ids)
           and status < 3
           AND (loppkpv IS NULL OR loppkpv >= l_kpv1)
     )
SELECT a.number::VARCHAR(20),
       a.kpv,
       hl.summa                   AS teenuse_maksumus,
       a1.Hoolduskulu,
       a1.kov_osa,
       a1.sugulaste_osa,
       a.summa                    AS dok_summa,
       isik.nimetus::VARCHAR(254) AS asutus,
       a.tahtaeg                  AS tahtaeg,
       a.tasud                    AS tasud,
       a.jaak                     AS jaak,
       jid.number                 AS laus_nr
FROM docs.doc d
         INNER JOIN docs.arv a ON d.id = a.parentid
         INNER JOIN libs.asutus isik ON a.asutusid = isik.id
         INNER JOIN lepingud hl ON hl.isikid = a.asutusid
         INNER JOIN
     (SELECT distinct a1.parentid,
             coalesce(-1 * sum(summa) FILTER (WHERE muud = 'Hoolduskulu'), 0)                                AS Hoolduskulu,
             coalesce(-1 * sum(summa)
                           FILTER (WHERE coalesce((properties ->> 'omavalitsuse_osa')::NUMERIC, 0) > 0 ), 0) AS kov_osa,
             coalesce(-1 * sum(summa)
                           FILTER (WHERE coalesce((properties ->> 'sugulane_osa')::NUMERIC, 0) > 0 ),
                      0)                                                                                     AS sugulaste_osa
      FROM docs.arv1 a1
      GROUP BY a1.parentid
     ) a1 ON a.id = a1.parentid
         LEFT OUTER JOIN docs.journal j ON j.parentid = a.journalid
         LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id

WHERE d.rekvid IN (SELECT rekv_id FROM rekv_ids)
  and a.number like 'HKOP%'
  AND a.kpv >= l_kpv1
  AND a.kpv <= l_kpv2;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION hooldekodu.hoo_arved( DATE, DATE, INTEGER,INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION hooldekodu.hoo_arved( DATE, DATE, INTEGER, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION hooldekodu.hoo_arved( DATE, DATE, INTEGER,INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION hooldekodu.hoo_arved( DATE, DATE, INTEGER,INTEGER) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.hoo_arved( DATE, DATE, INTEGER,INTEGER) TO hkametnik;


/*

*/
SELECT *
FROM hooldekodu.hoo_arved('2023-07-01', '2023-07-31':: DATE, 132, 1)

