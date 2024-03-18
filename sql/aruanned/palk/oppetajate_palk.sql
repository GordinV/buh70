DROP FUNCTION IF EXISTS palk.pedagoogide_palk(DATE, DATE, INTEGER, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION palk.pedagoogide_palk(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER,
                                                 params JSONB)
    RETURNS TABLE (
        rekv_id       INTEGER,
        isik_id       INTEGER,
        isik          VARCHAR(254),
        konto         VARCHAR(20),
        konto_nimetus VARCHAR(254),
        proj          VARCHAR(20),
        a_21          NUMERIC(14, 2),
        a_39          NUMERIC(14, 2),
        a_60          NUMERIC(14, 2),
        a_60RE        NUMERIC(14, 2),
        a_80          NUMERIC(14, 2),
        a_LEP         NUMERIC(14, 2),
        a_REAH        NUMERIC(14, 2),
        a_REHKG       NUMERIC(14, 2),
        a_REHKJ       NUMERIC(14, 2),
        a_REHKP       NUMERIC(14, 2),
        a_REHKU       NUMERIC(14, 2),
        a_REHT        NUMERIC(14, 2),
        a_RET         NUMERIC(14, 2),
        a_muud        NUMERIC(14, 2),
        t_3008        NUMERIC(14, 2),
        a_kokku       NUMERIC(14, 2)
    )
AS
$BODY$
WITH params AS (
    SELECT l_kpv1 AS kpv_1,
           l_kpv2 AS kpv_2
),
     rekv_ids AS (
         SELECT rekv_id
         FROM get_asutuse_struktuur(l_rekvid)
         WHERE rekv_id = CASE
                             WHEN l_kond = 1
                                 -- kond
                                 THEN rekv_id
                             ELSE l_rekvid END
     ),

     ametid AS (
         SELECT id
         FROM libs.library
         WHERE rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND library.library = 'AMET'
           AND (kood ILIKE 'pedagoog-%' OR kood ILIKE 'ped-%' OR kood ILIKE 'opetaja-%' OR kood ILIKE 'õpetaja%' or kood in ('pedagoog56', 'pedagoog60'))
           and kood not ilike '%logopeed%'
           AND status < 3
     ),
     docs AS (SELECT d.rekvid,
                     t.parentid                           AS isik_id,
                     sum(po.summa)                        AS summa,
                     po.konto,
                     po.proj,
                     coalesce(ltrim(rtrim(po.kood2)), '') AS allikas,
                     tunnus
              FROM params p,
                   docs.doc d
                       INNER JOIN palk.palk_oper po ON po.parentid = d.id
                       INNER JOIN palk.tooleping t ON t.id = po.lepingid
              WHERE d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                AND po.kpv >= p.kpv_1
                AND po.kpv <= p.kpv_2
                AND po.kood1 in ('09212','09213')         -- только школы
                AND left(po.konto, 1) IN ('5') -- только расходы
                AND t.ametid IN (SELECT id FROM ametid)
              GROUP BY t.parentid, D.rekvid, po.konto, po.proj, po.kood2, po.tunnus
     ),
     pre_report AS (
         SELECT rekvid,
                isik_id,
                konto,
                proj,
                sum(a_21)     AS a_21,
                sum(a_39)     AS a_39,
                sum(a_60)     AS a_60,
                sum(a_60RE)   AS a_60RE,
                sum(a_80)     AS a_80,
                sum(a_LEP)    AS a_LEP,
                sum(a_REAH)   AS a_REAH,
                sum(a_REHKG)  AS a_REHKG,
                sum(a_REHKJ)  AS a_REHKJ,
                sum(a_REHKP)  AS a_REHKP,
                sum(a_REHKU)  AS a_REHKU,
                sum(a_REHT)   AS a_REHT,
                sum(a_REPHKT) AS a_REPHKT,
                sum(a_RERT)   AS a_RERT,
                sum(a_muud)   AS a_muud,
                sum(t_3008)   AS t_3008
         FROM (
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         CASE WHEN allikas = '21' THEN d.summa ELSE 0 END  AS a_21,
                         0                                                 AS a_39,
                         0                                                 AS a_60,
                         0                                                 AS a_60RE,
                         0                                                 AS a_80,
                         0                                                 AS a_LEP,
                         0                                                 AS a_REAH,
                         0                                                 AS a_REHKG,
                         0                                                 AS a_REHKJ,
                         0                                                 AS a_REHKP,
                         0                                                 AS a_REHKU,
                         0                                                 AS a_REHT,
                         0                                                 AS a_REPHKT,
                         0                                                 AS a_RERT,
                         0                                                 AS a_muud,
                         CASE WHEN tunnus = '3008' THEN d.summa ELSE 0 END AS t_3008
                  FROM docs d
                  UNION ALL
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         0                                                AS a_21,
                         CASE WHEN allikas = '39' THEN d.summa ELSE 0 END AS a_39,
                         0                                                AS a_60,
                         0                                                AS a_60RE,
                         0                                                AS a_80,
                         0                                                AS a_LEP,
                         0                                                AS a_REAH,
                         0                                                AS a_REHKG,
                         0                                                AS a_REHKJ,
                         0                                                AS a_REHKP,
                         0                                                AS a_REHKU,
                         0                                                AS a_REHT,
                         0                                                AS a_REPHKT,
                         0                                                AS a_RERT,
                         0                                                AS a_muud,
                         0                                                AS t_3008

                  FROM docs d
                  UNION ALL
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         0                                                AS a_21,
                         0                                                AS a_39,
                         CASE WHEN allikas = '60' THEN d.summa ELSE 0 END AS a_60,
                         0                                                AS a_60RE,
                         0                                                AS a_80,
                         0                                                AS a_LEP,
                         0                                                AS a_REAH,
                         0                                                AS a_REHKG,
                         0                                                AS a_REHKJ,
                         0                                                AS a_REHKP,
                         0                                                AS a_REHKU,
                         0                                                AS a_REHT,
                         0                                                AS a_REPHKT,
                         0                                                AS a_RERT,
                         0                                                AS a_muud,
                         0                                                AS t_3008

                  FROM docs d
                  UNION ALL
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         0                                                   AS a_21,
                         0                                                   AS a_39,
                         0                                                   AS a_60,
                         CASE WHEN allikas = '60-RE' THEN d.summa ELSE 0 END AS a_60RE,
                         0                                                   AS a_80,
                         0                                                   AS a_LEP,
                         0                                                   AS a_REAH,
                         0                                                   AS a_REHKG,
                         0                                                   AS a_REHKJ,
                         0                                                   AS a_REHKP,
                         0                                                   AS a_REHKU,
                         0                                                   AS a_REHT,
                         0                                                   AS a_REPHKT,
                         0                                                   AS a_RERT,
                         0                                                   AS a_muud,
                         0                                                   AS t_3008

                  FROM docs d
                  UNION ALL
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         0                                                AS a_21,
                         0                                                AS a_39,
                         0                                                AS a_60,
                         0                                                AS a_60RE,
                         CASE WHEN allikas = '80' THEN d.summa ELSE 0 END AS a_80,
                         0                                                AS a_LEP,
                         0                                                AS a_REAH,
                         0                                                AS a_REHKG,
                         0                                                AS a_REHKJ,
                         0                                                AS a_REHKP,
                         0                                                AS a_REHKU,
                         0                                                AS a_REHT,
                         0                                                AS a_REPHKT,
                         0                                                AS a_RERT,
                         0                                                AS a_muud,
                         0                                                AS t_3008

                  FROM docs d
                  UNION ALL
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         0                                                  AS a_21,
                         0                                                  AS a_39,
                         0                                                  AS a_60,
                         0                                                  AS a_60RE,
                         0                                                  AS a_80,
                         CASE WHEN allikas = 'LE-P' THEN d.summa ELSE 0 END AS a_LEP,
                         0                                                  AS a_REAH,
                         0                                                  AS a_REHKG,
                         0                                                  AS a_REHKJ,
                         0                                                  AS a_REHKP,
                         0                                                  AS a_REHKU,
                         0                                                  AS a_REHT,
                         0                                                  AS a_REPHKT,
                         0                                                  AS a_RERT,
                         0                                                  AS a_muud,
                         0                                                  AS t_3008

                  FROM docs d
                  UNION ALL
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         0                                                   AS a_21,
                         0                                                   AS a_39,
                         0                                                   AS a_60,
                         0                                                   AS a_60RE,
                         0                                                   AS a_80,
                         0                                                   AS a_LEP,
                         CASE WHEN allikas = 'RE-AH' THEN d.summa ELSE 0 END AS a_REAH,
                         0                                                   AS a_REHKG,
                         0                                                   AS a_REHKJ,
                         0                                                   AS a_REHKP,
                         0                                                   AS a_REHKU,
                         0                                                   AS a_REHT,
                         0                                                   AS a_REPHKT,
                         0                                                   AS a_RERT,
                         0                                                   AS a_muud,
                         0                                                   AS t_3008

                  FROM docs d
                  UNION ALL
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         0                                                    AS a_21,
                         0                                                    AS a_39,
                         0                                                    AS a_60,
                         0                                                    AS a_60RE,
                         0                                                    AS a_80,
                         0                                                    AS a_LEP,
                         0                                                    AS a_REAH,
                         CASE WHEN allikas = 'RE-HKG' THEN d.summa ELSE 0 END AS a_REHKG,
                         0                                                    AS a_REHKJ,
                         0                                                    AS a_REHKP,
                         0                                                    AS a_REHKU,
                         0                                                    AS a_REHT,
                         0                                                    AS a_REPHKT,
                         0                                                    AS a_RERT,
                         0                                                    AS a_muud,
                         0                                                    AS t_3008

                  FROM docs d
                  UNION ALL
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         0                                                    AS a_21,
                         0                                                    AS a_39,
                         0                                                    AS a_60,
                         0                                                    AS a_60RE,
                         0                                                    AS a_80,
                         0                                                    AS a_LEP,
                         0                                                    AS a_REAH,
                         0                                                    AS a_REHKG,
                         CASE WHEN allikas = 'RE-HKJ' THEN d.summa ELSE 0 END AS a_REHKJ,
                         0                                                    AS a_REHKP,
                         0                                                    AS a_REHKU,
                         0                                                    AS a_REHT,
                         0                                                    AS a_REPHKT,
                         0                                                    AS a_RERT,
                         0                                                    AS a_muud,
                         0                                                    AS t_3008

                  FROM docs d
                  UNION ALL
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         0                                                    AS a_21,
                         0                                                    AS a_39,
                         0                                                    AS a_60,
                         0                                                    AS a_60RE,
                         0                                                    AS a_80,
                         0                                                    AS a_LEP,
                         0                                                    AS a_REAH,
                         0                                                    AS a_REHKG,
                         0                                                    AS a_REHKJ,
                         CASE WHEN allikas = 'RE-HKP' THEN d.summa ELSE 0 END AS a_REHKP,
                         0                                                    AS a_REHKU,
                         0                                                    AS a_REHT,
                         0                                                    AS a_REPHKT,
                         0                                                    AS a_RERT,
                         0                                                    AS a_muud,
                         0                                                    AS t_3008

                  FROM docs d
                  UNION ALL
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         0                                                    AS a_21,
                         0                                                    AS a_39,
                         0                                                    AS a_60,
                         0                                                    AS a_60RE,
                         0                                                    AS a_80,
                         0                                                    AS a_LEP,
                         0                                                    AS a_REAH,
                         0                                                    AS a_REHKG,
                         0                                                    AS a_REHKJ,
                         0                                                    AS a_REHKP,
                         CASE WHEN allikas = 'RE-HKU' THEN d.summa ELSE 0 END AS a_REHKU,
                         0                                                    AS a_REHT,
                         0                                                    AS a_REPHKT,
                         0                                                    AS a_RERT,
                         0                                                    AS a_muud,
                         0                                                    AS t_3008

                  FROM docs d
                  UNION ALL
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         0                                                   AS a_21,
                         0                                                   AS a_39,
                         0                                                   AS a_60,
                         0                                                   AS a_60RE,
                         0                                                   AS a_80,
                         0                                                   AS a_LEP,
                         0                                                   AS a_REAH,
                         0                                                   AS a_REHKG,
                         0                                                   AS a_REHKJ,
                         0                                                   AS a_REHKP,
                         0                                                   AS a_REHKU,
                         CASE WHEN allikas = 'RE-HT' THEN d.summa ELSE 0 END AS a_REHT,
                         0                                                   AS a_REPHKT,
                         0                                                   AS a_RERT,
                         0                                                   AS a_muud,
                         0                                                   AS t_3008

                  FROM docs d
                  UNION ALL
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         0                                                     AS a_21,
                         0                                                     AS a_39,
                         0                                                     AS a_60,
                         0                                                     AS a_60RE,
                         0                                                     AS a_80,
                         0                                                     AS a_LEP,
                         0                                                     AS a_REAH,
                         0                                                     AS a_REHKG,
                         0                                                     AS a_REHKJ,
                         0                                                     AS a_REHKP,
                         0                                                     AS a_REHKU,
                         0                                                     AS a_REHT,
                         CASE WHEN allikas = 'RE-PHKT' THEN d.summa ELSE 0 END AS a_REPHKT,
                         0                                                     AS a_RERT,
                         0                                                     AS a_muud,
                         0                                                     AS t_3008

                  FROM docs d
                  UNION ALL
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         0                                                   AS a_21,
                         0                                                   AS a_39,
                         0                                                   AS a_60,
                         0                                                   AS a_60RE,
                         0                                                   AS a_80,
                         0                                                   AS a_LEP,
                         0                                                   AS a_REAH,
                         0                                                   AS a_REHKG,
                         0                                                   AS a_REHKJ,
                         0                                                   AS a_REHKP,
                         0                                                   AS a_REHKU,
                         0                                                   AS a_REHT,
                         0                                                   AS a_REPHKT,
                         CASE WHEN allikas = 'RE-RT' THEN d.summa ELSE 0 END AS a_RERT,
                         0                                                   AS a_muud,
                         0                                                   AS t_3008
                  FROM docs d
                  UNION ALL
                  SELECT rekvid,
                         isik_id,
                         konto,
                         proj,
                         d.summa,
                         0              AS a_21,
                         0              AS a_39,
                         0              AS a_60,
                         0              AS a_60RE,
                         0              AS a_80,
                         0              AS a_LEP,
                         0              AS a_REAH,
                         0              AS a_REHKG,
                         0              AS a_REHKJ,
                         0              AS a_REHKP,
                         0              AS a_REHKU,
                         0              AS a_REHT,
                         0              AS a_REPHKT,
                         0              AS a_RERT,
                         CASE
                             WHEN empty(allikas) OR ltrim(rtrim(allikas)) NOT IN
                                                    ('21', '39', '60', '60-RE', '80', 'LE-P', 'RE-AH', 'RE-HKG',
                                                     'RE-HKJ', 'RE-HKP', 'RE-HKU', 'RE-HT', 'RE-PHKT', 'RE-RT')
                                 THEN d.summa
                             ELSE 0 END AS a_muud,
                         0              AS t_3008
                  FROM docs d
              ) qry
         GROUP BY qry.rekvid, qry.isik_id, qry.konto, qry.proj
     ),
     isiku_kond AS (
         SELECT r.rekvid,
                r.isik_id,
                '500x'       AS konto,
                ''            AS proj,
                sum(a_21)     AS a_21,
                sum(a_39)     AS a_39,
                sum(a_60)     AS a_60,
                sum(a_60RE)   AS a_60RE,
                sum(a_80)     AS a_80,
                sum(a_LEP)    AS a_LEP,
                sum(a_REAH)   AS a_REAH,
                sum(a_REHKG)  AS a_REHKG,
                sum(a_REHKJ)  AS a_REHKJ,
                sum(a_REHKP)  AS a_REHKP,
                sum(a_REHKU)  AS a_REHKU,
                sum(a_REHT)   AS a_REHT,
                sum(a_REPHKT) AS a_REPHKT,
                sum(a_muud)   AS a_muud,
                sum(t_3008)   AS t_3008
         FROM pre_report r
         WHERE left(konto, 3) = '500'
         GROUP BY r.rekvid, r.isik_id
         UNION ALL
         SELECT r.rekvid,
                r.isik_id,
                '506x'        AS konto,
                ''            AS proj,
                sum(a_21)     AS a_21,
                sum(a_39)     AS a_39,
                sum(a_60)     AS a_60,
                sum(a_60RE)   AS a_60RE,
                sum(a_80)     AS a_80,
                sum(a_LEP)    AS a_LEP,
                sum(a_REAH)   AS a_REAH,
                sum(a_REHKG)  AS a_REHKG,
                sum(a_REHKJ)  AS a_REHKJ,
                sum(a_REHKP)  AS a_REHKP,
                sum(a_REHKU)  AS a_REHKU,
                sum(a_REHT)   AS a_REHT,
                sum(a_REPHKT) AS a_REPHKT,
                sum(a_muud)   AS a_muud,
                sum(t_3008)   AS t_3008
         FROM pre_report r
         WHERE left(konto, 3) = '506'
         GROUP BY r.rekvid, r.isik_id
     )
SELECT r.rekvid,
       r.isik_id,
       a.nimetus::VARCHAR(254) AS isik,
       konto,
       l.nimetus::VARCHAR(254) AS konto_nimetus,
       proj,
       a_21,
       a_39,
       a_60,
       a_60RE,
       a_80,
       a_LEP,
       a_REAH,
       a_REHKG,
       a_REHKJ,
       a_REHKP,
       a_REHKU,
       a_REHT,
       a_REPHKT,
       a_muud,
       t_3008,
       a_21 + a_39 + a_60 + a_60RE + a_80 + a_LEP + a_REAH + a_REHKG + a_REHKJ + a_REHKP + a_REHKU + a_REHT + a_REPHKT +
       a_muud                  AS kokku
FROM pre_report r
         INNER JOIN libs.asutus a ON a.id = r.isik_id
         LEFT OUTER JOIN libs.library l ON l.kood = r.konto AND l.library = 'KONTOD' AND l.status < 3 AND
                                           length(ltrim(rtrim(l.kood))) >= 6
UNION ALL
SELECT r.rekvid,
       r.isik_id,
       a.nimetus::VARCHAR(254) AS isik,
       konto,
       l.nimetus::VARCHAR(254) AS konto_nimetus,
       proj,
       a_21,
       a_39,
       a_60,
       a_60RE,
       a_80,
       a_LEP,
       a_REAH,
       a_REHKG,
       a_REHKJ,
       a_REHKP,
       a_REHKU,
       a_REHT,
       a_REPHKT,
       a_muud,
       t_3008,
       a_21 + a_39 + a_60 + a_60RE + a_80 + a_LEP + a_REAH + a_REHKG + a_REHKJ + a_REHKP + a_REHKU + a_REHT + a_REPHKT +
       a_muud                  AS kokku
FROM isiku_kond r
         INNER JOIN libs.asutus a ON a.id = r.isik_id
         LEFT OUTER JOIN (
    SELECT '500x' AS kood, upper('Kokku palk') AS nimetus
    UNION ALL
    SELECT '506x' AS kood, upper('Kokku maksud') AS nimetus
) l ON l.kood = r.konto

    -- $BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION palk.pedagoogide_palk( DATE, DATE, INTEGER, INTEGER,JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.pedagoogide_palk( DATE, DATE, INTEGER, INTEGER,JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.pedagoogide_palk( DATE, DATE, INTEGER, INTEGER,JSONB) TO dbkasutaja;


SELECT qry.*, r.nimetus AS asutus
FROM palk.pedagoogide_palk('2023-01-01'::DATE, '2023-12-31'::DATE, 119::INTEGER, 1::INTEGER, NULL::JSONB) qry
         INNER JOIN ou.rekv r ON r.id = qry.rekv_id
ORDER BY r.nimetus, qry.Isik, qry.konto


/*

SELECT *
FROM palk.pedagoogide_palk( '2023-01-01'::DATE, '2023-12-31'::DATE, 119::INTEGER, 1::INTEGER,NULL::JSONB)
where isik = 'Morozova Olga'
*/