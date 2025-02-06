DROP FUNCTION IF EXISTS lapsed.aasta_naitajad_liik(INTEGER, DATE, TEXT, TEXT, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.aasta_naitajad_liik(l_rekvid INTEGER,
                                                      l_kpv DATE DEFAULT current_date,
                                                      l_liik TEXT DEFAULT '',
                                                      l_tyyp TEXT DEFAULT '',
                                                      l_kond INTEGER DEFAULT 1)
    RETURNS TABLE
            (
                period        DATE,
                rekvid        INTEGER,
                liik          TEXT,
                tyyp          TEXT,
                tyyp_nimi     TEXT,
                yksused       TEXT,
                lapsed_kokku  INTEGER,
                jaanuar       INTEGER,
                veebruar      INTEGER,
                marts         INTEGER,
                apriil        INTEGER,
                mai           INTEGER,
                juuni         INTEGER,
                juuli         INTEGER,
                august        INTEGER,
                september     INTEGER,
                oktoober      INTEGER,
                november      INTEGER,
                detsember     INTEGER,
                toppelt_kogus INTEGER
            )
AS
$BODY$
WITH params AS (SELECT l_rekvid                                  AS rekv_id,
                       ltrim(rtrim(coalesce(l_liik, ''))) || '%' AS liik,
                       ltrim(rtrim(coalesce(l_tyyp, ''))) || '%' AS tyyp,
                       CASE
                           WHEN l_kpv IS NULL OR empty(l_kpv::TEXT) THEN date(year(current_date), 12, 31)
                           ELSE l_kpv END::DATE                  AS kpv)

SELECT params.kpv::DATE     AS period,
       qry.rekvid::INTEGER,
       qry.liik::TEXT,
       qry.tyyp::TEXT,
       qry.tyyp_nimi::TEXT,
       NULL::TEXT           AS yksused,
       (jaanuar + veebruar + marts + apriil + mai + juuni + juuli + august + september + oktoober + november +
        detsember)::INTEGER AS lapsed_kokku,
       jaanuar::INTEGER,
       veebruar::INTEGER,
       marts::INTEGER,
       apriil::INTEGER,
       mai::INTEGER,
       juuni::INTEGER,
       juuli::INTEGER,
       august::INTEGER,
       september::INTEGER,
       oktoober::INTEGER,
       november::INTEGER,
       detsember::INTEGER,
       qry.toppelt_kogus::integer

FROM (WITH rekv_ids AS (SELECT r.rekv_id
                        FROM params p,
                             get_asutuse_struktuur(p.rekv_id) r),
           qry_liik AS (SELECT DISTINCT coalesce((n.properties ->> 'oppe_tyyp')::TEXT, 'Põhiõpe')::TEXT AS liik,
                                        d.id,
                                        d.rekvid,
                                        date_part('month', a.kpv)                                       AS kuu,
                                        l.parentid                                                      AS laps_id,
                                        CASE
                                            WHEN (l_kond <> 1) THEN left((a1.properties ->> 'yksus'), 8)
                                            ELSE NULL::TEXT END                                         AS tyyp
                        FROM docs.doc d
                                 INNER JOIN docs.arv a ON d.id = a.parentid
                                 INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                                 INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                                 INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                                 INNER JOIN ou.rekv r ON r.id = a.rekvid,
                             params p
                        WHERE year(a.kpv) = year(p.kpv)
                          AND a.liik = 0
                          AND a.kpv <= p.kpv
                          AND d.rekvid IN (SELECT rekv_id
                                           FROM rekv_ids)
                          AND d.doc_type_id IN
                              (SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood IN ('ARV'))
                          and a.properties ->> 'alus_arve_id' is null -- кредитовые счета убираем
                          AND CASE
                                  when a.properties ->> 'kreedit_arve_id' is not null then false -- выкинуть аннулированный счет
                                  WHEN a.properties ->> 'doc_kreedit_arved' IS NOT NULL AND a.summa > 0 THEN TRUE
                                  WHEN a.properties ->> 'doc_kreedit_arved' IS NULL THEN TRUE
                                  ELSE FALSE END
--                    and a.properties->>'doc_kreedit_arved' is null -- убираем переносы долгов

--                    AND coalesce(r.properties ->> 'liik', '') ILIKE p.liik
                          AND left((a1.properties ->> 'yksus'), 8) ILIKE p.tyyp),
           report AS (SELECT d.laps_id                                 AS laps_id,
                             d.rekvid,
                             d.liik,
                             d.kuu                                     AS kuu,
                             d.tyyp::TEXT                              AS tyyp,
                             ltrim(rtrim(l.nimetus))::TEXT             AS tyyp_nimi,
                             count(*) over (partition by laps_id, kuu) as kogus
                      FROM qry_liik d
                               LEFT OUTER JOIN libs.library l ON l.kood = d.tyyp AND l.rekvid = d.rekvid AND
                                                                 l.library = 'KOOLITUSE_TYYP' AND status <> 3
               --       GROUP BY laps_id, d.rekvid, liik, kuu, tyyp, ltrim(rtrim(l.nimetus))
           )
      SELECT rekvid,
             liik::TEXT,
             tyyp::TEXT,
             tyyp_nimi::TEXT,
             sum(CASE WHEN kuu = 1 THEN 1 ELSE 0 END)  AS jaanuar,
             sum(CASE WHEN kuu = 2 THEN 1 ELSE 0 END)  AS veebruar,
             sum(CASE WHEN kuu = 3 THEN 1 ELSE 0 END)  AS marts,
             sum(CASE WHEN kuu = 4 THEN 1 ELSE 0 END)  AS apriil,
             sum(CASE WHEN kuu = 5 THEN 1 ELSE 0 END)  AS mai,
             sum(CASE WHEN kuu = 6 THEN 1 ELSE 0 END)  AS juuni,
             sum(CASE WHEN kuu = 7 THEN 1 ELSE 0 END)  AS juuli,
             sum(CASE WHEN kuu = 8 THEN 1 ELSE 0 END)  AS august,
             sum(CASE WHEN kuu = 9 THEN 1 ELSE 0 END)  AS september,
             sum(CASE WHEN kuu = 10 THEN 1 ELSE 0 END) AS oktoober,
             sum(CASE WHEN kuu = 11 THEN 1 ELSE 0 END) AS november,
             sum(CASE WHEN kuu = 12 THEN 1 ELSE 0 END) AS detsember,
             count(kogus) filter ( where kogus > 1 )   as toppelt_kogus -- расчет задвоений (из-за разных типов в одном счете
      FROM report
      GROUP BY rekvid, liik::TEXT, tyyp::TEXT, tyyp_nimi) qry,
     params
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.aasta_naitajad_liik(INTEGER, DATE, TEXT, TEXT, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.aasta_naitajad_liik(INTEGER, DATE, TEXT, TEXT, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.aasta_naitajad_liik(INTEGER, DATE, TEXT, TEXT, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.aasta_naitajad_liik(INTEGER, DATE, TEXT, TEXT, INTEGER) TO dbvaatleja;


/*
SELECT *
FROM lapsed.aasta_naitajad_liik(72, '2024-10-31'::date, '', '',0) a
left outer join libs.library l on l.kood = a.tyyp and l.rekvid = a.rekvid and l.library = 'KOOLITUSE_TYYP' and status <> 3
where liik = 'Muud'
order by tyyp, liik

SELECT period::       DATE,
        rekvid::       INTEGER,
        liik::         TEXT,
        sum(lapsed_kokku):: INTEGER as lapsed_kokku,
        sum(jaanuar)::      INTEGER as jaanuar,
        sum(veebruar)::     INTEGER as veebruar,
        sum(marts)::       INTEGER as marts,
        sum(apriil)::       INTEGER as apriil,
        sum(mai)::          INTEGER as mai,
        sum(juuni)::        INTEGER as juuni,
        sum(juuli)::        INTEGER as juuli,
        sum(august)::       INTEGER as august,
        sum(september)::    INTEGER as september,
        sum(oktoober)::     INTEGER as oktoober,
        sum(november)::     INTEGER as november,
        sum(detsember)::    INTEGER as detsember
FROM lapsed.aasta_naitajad_(72, '2023-12-31'::date) a
group by liik, rekvid, period
order by rekvid,liik

*/
