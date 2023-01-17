DROP FUNCTION IF EXISTS hooldekodu.hoo_kaibeandmik(DATE, DATE, INTEGER, INTEGER);


CREATE OR REPLACE FUNCTION hooldekodu.hoo_kaibeandmik(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
                                                      l_kond INTEGER DEFAULT 0)
    RETURNS TABLE (
        isik_id         INTEGER,
        pension_85_alg  NUMERIC(14, 2),
        pension_15_alg  NUMERIC(14, 2),
        toetus_alg      NUMERIC(14, 2),
        vara_alg        NUMERIC(14, 2),
        muud_alg        NUMERIC(14, 2),
        pension_85_laek NUMERIC(14, 2),
        pension_15_laek NUMERIC(14, 2),
        toetus_laek     NUMERIC(14, 2),
        vara_laek       NUMERIC(14, 2),
        muud_laek       NUMERIC(14, 2),
        pension_85_arv  NUMERIC(14, 2),
        pension_15_arv  NUMERIC(14, 2),
        toetus_arv      NUMERIC(14, 2),
        vara_arv        NUMERIC(14, 2),
        muud_arv        NUMERIC(14, 2),
        pension_85_lopp NUMERIC(14, 2),
        pension_15_lopp NUMERIC(14, 2),
        toetus_lopp     NUMERIC(14, 2),
        vara_lopp       NUMERIC(14, 2),
        muud_lopp       NUMERIC(14, 2)
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
     algsaldo AS (
         SELECT isik_id,
                sum(pension_85) AS pension_85,
                sum(pension_15) AS pension_15,
                sum(toetus)     AS toetus,
                sum(vara)       AS vara,
                sum(muud)       AS muud
         FROM (SELECT isikid                                                                 AS isik_id,
                      CASE WHEN ltrim(rtrim(ht.allikas)) = 'PENSION85' THEN summa ELSE 0 END AS pension_85,
                      CASE WHEN ltrim(rtrim(ht.allikas)) = 'PENSION15' THEN summa ELSE 0 END AS pension_15,
                      CASE WHEN ltrim(rtrim(ht.allikas)) = 'TOETUS' THEN summa ELSE 0 END    AS toetus,
                      CASE WHEN ltrim(rtrim(ht.allikas)) = 'VARA' THEN summa ELSE 0 END      AS vara,
                      CASE
                          WHEN ltrim(rtrim(ht.allikas)) NOT IN
                               ('VARA', 'TOETUS', 'PENSION15', 'PENSION85')
                              THEN summa
                          ELSE 0 END                                                         AS muud
               FROM hooldekodu.hootehingud ht
               WHERE rekvid IN (SELECT rekv_id FROM rekv_ids)
                 AND kpv < l_kpv1
                 AND status < 3) tmp
         GROUP BY isik_id),
     laekumised AS (
         SELECT isik_id,
                sum(pension_85) AS pension_85,
                sum(pension_15) AS pension_15,
                sum(toetus)     AS toetus,
                sum(vara)       AS vara,
                sum(muud)       AS muud
         FROM (SELECT isikid                                                                 AS isik_id,
                      CASE WHEN ltrim(rtrim(ht.allikas)) = 'PENSION85' THEN summa ELSE 0 END AS pension_85,
                      CASE WHEN ltrim(rtrim(ht.allikas)) = 'PENSION15' THEN summa ELSE 0 END AS pension_15,
                      CASE WHEN ltrim(rtrim(ht.allikas)) = 'TOETUS' THEN summa ELSE 0 END    AS toetus,
                      CASE WHEN ltrim(rtrim(ht.allikas)) = 'VARA' THEN summa ELSE 0 END      AS vara,
                      CASE
                          WHEN ltrim(rtrim(ht.allikas)) NOT IN ('VARA', 'TOETUS', 'PENSION15', 'PENSION85')
                              THEN summa
                          ELSE 0 END                                                         AS muud
               FROM hooldekodu.hootehingud ht
               WHERE rekvid IN (SELECT rekv_id FROM rekv_ids)
                 AND kpv >= l_kpv1
                 AND kpv <= l_kpv2
                 AND ht.tyyp = 'TULUD'
                 AND status < 3) tmp
         GROUP BY isik_id),
     arvestus AS (
         SELECT isik_id,
                sum(pension_85) AS pension_85,
                sum(pension_15) AS pension_15,
                sum(toetus)     AS toetus,
                sum(vara)       AS vara,
                sum(muud)       AS muud
         FROM (SELECT isikid                                                                      AS isik_id,
                      -1 * CASE WHEN ltrim(rtrim(ht.allikas)) = 'PENSION85' THEN summa ELSE 0 END AS pension_85,
                      -1 * CASE WHEN ltrim(rtrim(ht.allikas)) = 'PENSION15' THEN summa ELSE 0 END AS pension_15,
                      -1 * CASE WHEN ltrim(rtrim(ht.allikas)) = 'TOETUS' THEN summa ELSE 0 END    AS toetus,
                      -1 * CASE WHEN ltrim(rtrim(ht.allikas)) = 'VARA' THEN summa ELSE 0 END      AS vara,
                      -1 * CASE
                               WHEN ltrim(rtrim(ht.allikas)) NOT IN ('VARA', 'TOETUS', 'PENSION15', 'PENSION85')
                                   THEN summa
                               ELSE 0 END                                                         AS muud
               FROM hooldekodu.hootehingud ht
               WHERE rekvid IN (SELECT rekv_id FROM rekv_ids)
                 AND kpv >= l_kpv1
                 AND kpv <= l_kpv2
                 AND ht.tyyp = 'KULUD'
                 AND status < 3) tmp
         GROUP BY isik_id)
SELECT qry.isik_id,
       sum(pension_85_alg)                                    AS pension_85_alg,
       sum(pension_15_alg)                                    AS pension_15_alg,
       sum(toetus_alg)                                        AS toetus_alg,
       sum(vara_alg)                                          AS vara_alg,
       sum(muud_alg)                                          AS muud_alg,
       sum(pension_85_laek)                                   AS pension_85_laek,
       sum(pension_15_laek)                                   AS pension_15_laek,
       sum(toetus_laek)                                       AS toetus_laek,
       sum(vara_laek)                                         AS vara_laek,
       sum(muud_laek)                                         AS muud_laek,
       sum(pension_85_arv)                                    AS pension_85_arv,
       sum(pension_15_arv)                                    AS pension_15_arv,
       sum(toetus_arv)                                        AS toetus_arv,
       sum(vara_arv)                                          AS vara_arv,
       sum(muud_arv)                                          AS muud_arv,
       sum(pension_85_alg + pension_85_laek - pension_85_arv) AS pension_85_lopp,
       sum(pension_15_alg + pension_15_laek - pension_15_arv) AS pension_15_lopp,
       sum(toetus_alg + toetus_laek - toetus_arv)             AS toetus_lopp,
       sum(vara_alg + vara_laek - vara_arv)                   AS vara_lopp,
       sum(muud_alg + muud_laek - muud_arv)                   AS muud_lopp
FROM (
         SELECT a.isik_id,
                a.pension_85 AS pension_85_alg,
                a.pension_15 AS pension_15_alg,
                a.toetus     AS toetus_alg,
                a.vara       AS vara_alg,
                a.muud       AS muud_alg,
                0            AS pension_85_laek,
                0            AS pension_15_laek,
                0            AS toetus_laek,
                0            AS vara_laek,
                0            AS muud_laek,
                0            AS pension_85_arv,
                0            AS pension_15_arv,
                0            AS toetus_arv,
                0            AS vara_arv,
                0            AS muud_arv
         FROM algsaldo a
         UNION ALL
         SELECT isik_id,
                0            AS pension_85_alg,
                0            AS pension_15_alg,
                0            AS toetus_alg,
                0            AS vara_alg,
                0            AS muud_alg,
                a.pension_85 AS pension_85_laek,
                a.pension_15 AS pension_15_laek,
                a.toetus     AS toetus_laek,
                a.vara       AS vara_laek,
                a.muud       AS muud_laek,
                0            AS pension_85_arv,
                0            AS pension_15_arv,
                0            AS toetus_arv,
                0            AS vara_arv,
                0            AS muud_arv
         FROM laekumised a
         UNION ALL
         SELECT isik_id,
                0            AS pension_85_alg,
                0            AS pension_15_alg,
                0            AS toetus_alg,
                0            AS vara_alg,
                0            AS muud_alg,
                0            AS pension_85_laek,
                0            AS pension_15_laek,
                0            AS toetus_laek,
                0            AS vara_laek,
                0            AS muud_laek,
                a.pension_85 AS pension_85_arv,
                a.pension_15 AS pension_15_arv,
                a.toetus     AS toetus_arv,
                a.vara       AS vara_arv,
                a.muud       AS muud_arv
         FROM arvestus a) qry
GROUP BY isik_id
    ;
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION hooldekodu.hoo_kaibeandmik( DATE, DATE, INTEGER,INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION hooldekodu.hoo_kaibeandmik( DATE, DATE, INTEGER, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION hooldekodu.hoo_kaibeandmik( DATE, DATE, INTEGER,INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION hooldekodu.hoo_kaibeandmik( DATE, DATE, INTEGER,INTEGER) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.hoo_kaibeandmik( DATE, DATE, INTEGER,INTEGER) TO hkametnik;


/*

*/SELECT *
  FROM hooldekodu.hoo_kaibeandmik('2022-10-01', '2022-10-31':: DATE, 132, 1)

