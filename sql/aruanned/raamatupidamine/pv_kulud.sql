DROP FUNCTION IF EXISTS docs.pv_kulud(DATE, DATE, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.pv_kulud(kpv_start DATE, kpv_end DATE, l_rekvid INTEGER, params JSONB DEFAULT NULL)
    RETURNS TABLE (
        konto         VARCHAR(20),
        konto_nimetus VARCHAR(254),
        dokument      VARCHAR(254),
        artikkel      VARCHAR(20),
        tegevus       VARCHAR(20),
        allikas       VARCHAR(20),
        tunnus        VARCHAR(20),
        uritus        VARCHAR(20),
        projekt       VARCHAR(20),
        objekt        VARCHAR(20),
        summa         NUMERIC(12, 2),
        kaibemaks     NUMERIC(12, 2),
        kokku         NUMERIC(12, 2),
        kreedit_100   NUMERIC(12, 2),
        partner       VARCHAR(254),
        asutus        VARCHAR(254)
    )
AS
$BODY$
WITH params AS (
    SELECT coalesce((params::JSONB ->> 'kond')::INTEGER, 0)               AS kond,
           coalesce(params::JSONB ->> 'konto', '')::TEXT || '%'           AS konto,
           coalesce(params::JSONB ->> 'tunnus', '')::TEXT || '%'          AS tunnus,
           coalesce(params::JSONB ->> 'proj', '')::TEXT || '%'            AS proj,
           coalesce(params::JSONB ->> 'uritus', '')::TEXT || '%'          AS uritus,
           coalesce(params::JSONB ->> 'objekt', '')::TEXT || '%'          AS objekt,
           coalesce(params::JSONB ->> 'artikkel', '')::TEXT || '%'        AS artikkel,
           coalesce(params::JSONB ->> 'allikas', '')::TEXT || '%'         AS allikas,
           coalesce(params::JSONB ->> 'tegevus', '')::TEXT || '%'         AS tegev,
           coalesce((params::JSONB ->> 'asutus_id')::INTEGER, 0)::INTEGER AS asutus_id,
           kpv_start                                                      AS kpv_1,
           kpv_end                                                        AS kpv_2
),
     rekv_ids AS (
         SELECT rekv_id
         FROM PUBLIC.get_asutuse_struktuur(l_rekvid) r,
              params p
         WHERE CASE
                   WHEN p.kond = 1 THEN TRUE
                   ELSE l_rekvid = r.rekv_id END
     ),

     qry_docs AS (
         SELECT d.id                                                AS doc_id,
                a.number                                            AS dokument,
                a1.konto                                            AS konto,
                coalesce(a1.kood5, '')::VARCHAR(20)                 AS artikkel,
                coalesce(a1.kood1, '')::VARCHAR(20)                 AS tegevus,
                coalesce(a1.kood2, '')::VARCHAR(20)                 AS allikas,
                coalesce(a1.tunnus, '')::VARCHAR(20)                AS tunnus,
                coalesce(a1.kood4, '')                              AS uritus,
                coalesce(a1.objekt, '')::VARCHAR(20)                AS objekt,
                coalesce(a1.proj, '')::VARCHAR(20)                  AS projekt,
                (a1.summa - a1.kbm):: NUMERIC(12, 2)                AS summa,
                a1.kbm:: NUMERIC(12, 2)                             AS kaibemaks,
                a1.summa:: NUMERIC(12, 2)                           AS kokku,
                a.summa                                             AS doc_summa,
                d.rekvid,
                a.asutusid,
                coalesce((dp.details ->> 'konto'), '')::VARCHAR(20) AS korr_konto
         FROM docs.doc d
                  INNER JOIN docs.arv a ON a.parentid = d.id
                  INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
                  LEFT OUTER JOIN libs.dokprop dp ON dp.id = a.doklausid,
              params p
         WHERE d.status < 3
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND a.kpv >= p.kpv_1
           AND a.kpv <= p.kpv_2
           AND a.liik = 1 -- только входящие счета
           AND (a1.kood3 = '01' -- Только Rv01
             OR left(a1.konto, 2) = '55'
             )
         UNION ALL
         SELECT d.id                                   AS doc_id,
                j.dok                                  AS dokument,
                j1.deebet                              AS konto,
                coalesce(j1.kood5, '')::VARCHAR(20)    AS artikkel,
                coalesce(j1.kood1, '')::VARCHAR(20)    AS tegevus,
                coalesce(j1.kood2, '')::VARCHAR(20)    AS allikas,
                coalesce(j1.tunnus, '')::VARCHAR(20)   AS tunnus,
                coalesce(j1.kood4, '')                 AS uritus,
                coalesce(j1.objekt, '')::VARCHAR(20)   AS objekt,
                coalesce(j1.proj, '')::VARCHAR(20)     AS projekt,
                (j1.summa):: NUMERIC(12, 2)            AS summa,
                0:: NUMERIC(12, 2)                     AS kaibemaks,
                j1.summa:: NUMERIC(12, 2)              AS kokku,
                sum(j1.summa) OVER ():: NUMERIC(12, 2) AS doc_summa,
                d.rekvid,
                j.asutusid,
                j1.kreedit::VARCHAR(20)                AS korr_konto
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
              params p
         WHERE d.status < 3
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND j.kpv >= p.kpv_1
           AND j.kpv <= p.kpv_2
           AND left(j1.deebet, 1) = '4'
     ),
     qry_kassa AS (
         SELECT at.doc_arv_id AS doc_id, sum(at.summa) AS summa
         FROM docs.arvtasu at,
              params p
         WHERE doc_arv_id IN (SELECT doc_id FROM qry_docs)
           AND at.kpv >= p.kpv_1
           AND at.kpv <= p.kpv_2
           AND at.status < 3
         GROUP BY at.doc_arv_id
     )
SELECT r.konto:: VARCHAR(20),
       k.nimetus:: VARCHAR(254)          AS konto_nimetus,
       r.dokument:: VARCHAR(254),
       r.artikkel:: VARCHAR(20),
       r.tegevus:: VARCHAR(20),
       r.allikas:: VARCHAR(20),
       r.tunnus:: VARCHAR(20),
       r.uritus:: VARCHAR(20),
       r.projekt:: VARCHAR(20),
       r.objekt:: VARCHAR(20),
       sum(summa):: NUMERIC(12, 2)       AS summa,
       sum(kaibemaks):: NUMERIC(12, 2)   AS kaibemaks,
       sum(kokku):: NUMERIC(12, 2)       AS kokku,
       sum(kreedit_100):: NUMERIC(12, 2) AS kreedit_100,
       a.nimetus :: VARCHAR(254)         AS partner,
       rekv.nimetus:: VARCHAR(254)       AS asutus
FROM (
         SELECT d.doc_id,
                d.dokument,
                d.konto,
                d.artikkel,
                d.tegevus,
                d.allikas,
                d.tunnus,
                d.uritus,
                d.objekt,
                d.projekt,
                d.kokku,
                CASE WHEN left(d.korr_konto, 3) = '103' THEN d.kokku ELSE d.summa END      AS summa,
                CASE WHEN left(d.korr_konto, 3) = '103' THEN 0 ELSE d.kaibemaks END        AS kaibemaks,
                CASE WHEN k.doc_id IS NULL THEN 0 ELSE k.summa / d.doc_summa * d.kokku END AS kreedit_100,
                d.asutusid,
                d.rekvid
         FROM qry_docs d
                  LEFT OUTER JOIN qry_kassa k ON k.doc_id = d.doc_id
     ) r
         INNER JOIN libs.asutus a ON a.id = r.asutusid
         INNER JOIN ou.rekv rekv ON rekv.id = r.rekvid
         LEFT OUTER JOIN com_kontoplaan k ON k.kood = r.konto,
     params p
WHERE r.konto LIKE p.konto
  AND r.artikkel LIKE p.artikkel
  AND r.allikas ILIKE p.allikas
  AND r.tegevus LIKE p.tegev
  AND r.tunnus ILIKE p.tunnus
  AND r.uritus ILIKE p.uritus
  AND r.projekt ILIKE p.proj
  AND r.objekt ILIKE p.objekt
  AND r.asutusid = CASE WHEN p.asutus_id > 0 THEN p.asutus_id ELSE r.asutusid END
GROUP BY r.konto
        , k.nimetus
        , r.dokument
        , r.artikkel
        , r.tegevus
        , r.allikas
        , r.tunnus
        , r.uritus
        , r.projekt
        , r.objekt
        , a.nimetus
        , rekv.nimetus
ORDER BY rekv.nimetus, r.dokument, r.artikkel, r.tegevus, r.allikas, r.tunnus, r.uritus, r.projekt, r.objekt

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.pv_kulud(DATE, DATE, INTEGER, JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.pv_kulud(DATE, DATE, INTEGER, JSONB) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.pv_kulud(DATE, DATE, INTEGER, JSONB) TO dbkasutaja;

/*
SELECT *
FROM docs.pv_kulud('2023-04-01'::DATE, '2024-05-31':: DATE, 119, '    {
  "tunnus": "",
  "konto": "4",
  "proj": "",
  "uritus": "",
  "artikkel": "",
  "tegevus": "",
  "allikas": "",
  "kond": 0,
  "objekt": ""
}':: JSONB)*/
--where dokument = 'U13883851'

/*
select * from docs.pv_kulud('2023-01-01'::date, '2023-12-31':: DATE, 63, null:: JSONB)

select *
        from docs.pv_kulud('2024-01-01'::DATE, '2024-12-31'::DATE, 130::INTEGER, '{
		"tunnus":"",
		"konto":"",
		"proj":"",
		"uritus":"",
		"artikkel":"",
		"tegevus":"",
		"allikas":"",
		"kond":0,
		"objekt":"                    "
	}'::JSONB) qry

*/