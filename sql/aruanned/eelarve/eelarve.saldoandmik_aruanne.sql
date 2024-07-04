DROP FUNCTION IF EXISTS eelarve.saldoandmik_aruanne(l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER, JSONB);


CREATE OR REPLACE FUNCTION eelarve.saldoandmik_aruanne(l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER,
                                                        l_params JSONB DEFAULT NULL)
    RETURNS TABLE (
        rekv_id  INTEGER,
        konto    VARCHAR(20),
        tp       VARCHAR(20),
        tegev    VARCHAR(20),
        allikas  VARCHAR(20),
        rahavoog VARCHAR(20),
        deebet   NUMERIC(14, 2),
        kreedit  NUMERIC(14, 2),
        tyyp     INTEGER,
        docs_ids INTEGER[]
    )
AS
$BODY$
WITH qryParams AS (
    SELECT l_kpv2::DATE                                              AS kpv,
           l_rekvid::INTEGER                                         AS rekvid,
           l_kond::INTEGER                                           AS kond,
           l_params::JSONB                                           AS jsonb_params,
           make_date(date_part('year', l_kpv2::DATE)::INTEGER, 1, 1) AS alg_kpv
),

     rekv_ids AS (
         SELECT rekv_id
         FROM qryParams,
              public.get_asutuse_struktuur(qryParams.rekvid)

         WHERE rekv_id = CASE
                             WHEN qryParams.kond = 1
                                 THEN rekv_id
                             ELSE qryParams.rekvid END
     ),
     docs_types AS (
         SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood = 'JOURNAL'
     )
SELECT rekv_id,
       konto::VARCHAR(20),
       tp::VARCHAR(20),
       tegev::VARCHAR(20),
       allikas::VARCHAR(20),
       rahavoog::VARCHAR(20),
       sum(deebet)   AS deebet,
       sum(kreedit)  AS kreedit,
       tyyp::INTEGER AS tyyp
FROM (
         WITH qryKontod AS (
             (SELECT l.kood,
                     NOT empty(l.tun1)                                                  AS is_tp,
                     NOT empty(l.tun2)                                                  AS is_tegev,
                     NOT empty(l.tun3)                                                  AS is_allikas,
                     NOT empty(l.tun4)                                                  AS is_rahavoog,
                     coalesce(l.tun5, 1)                                                AS tyyp,
--                     l.muud,
                     coalesce((l.properties::JSONB ->> 'tp_req')::CHAR(1), '')::CHAR(1) AS tp_req,
                     coalesce((l.properties::JSONB ->> 'tt_req')::CHAR(1), '')::CHAR(1) AS tt_req,
                     coalesce((l.properties::JSONB ->> 'a_req')::CHAR(1), '')::CHAR(1)  AS a_req,
                     coalesce((l.properties::JSONB ->> 'rv_req')::CHAR(1), '')::CHAR(1) AS rv_req

              FROM libs.library l
              WHERE l.library = 'KONTOD'
                AND l.status <> 3)
         ),
              qrySaldoAndmik AS (
                  -- alg db kaived
                  SELECT qryParams.alg_kpv - 1                 AS kpv,
                         j.rekvid,
                         j1.deebet                             AS konto,
                         j1.lisa_d                             AS tp,
                         coalesce(j1.kood1, ''):: VARCHAR(20)  AS tegev,
                         coalesce(j1.kood2, '') :: VARCHAR(20) AS allikas,
                         '00'::VARCHAR(20)                     AS rahavoog,
                         sum(j1.summa)                         AS deebet,
                         0 :: NUMERIC                          AS kreedit,
                         j1.tunnus,
                         j1.proj,
                         array_agg(d.id) as docs_ids
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                           INNER JOIN qryKontod l ON ltrim(rtrim(l.kood)) = ltrim(rtrim(j1.deebet)),
                       qryParams
                  WHERE d.rekvid IN (SELECT rekv_id
                                     FROM rekv_ids)
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
                    AND d.status <> 3
                    AND coalesce(a.kpv, j.kpv) <= qryParams.kpv::DATE
                    AND coalesce(a.kpv, j.kpv) < qryParams.alg_kpv::DATE
                    AND (j1.deebet = '155920' AND j1.kreedit <> '888888' AND d.rekvid IN (130, 28) OR
                         year(qryParams.kpv) < year(qryParams.kpv) OR j1.deebet <> '155920')
                  GROUP BY qryParams.alg_kpv, j.rekvid, j1.deebet, j1.lisa_d, j1.kood1, j1.kood2, j1.tunnus,
                           j1.proj
                  UNION ALL
                  -- db kaived

                  SELECT qryParams.kpv                         AS kpv,
                         j.rekvid,
                         j1.deebet                             AS konto,
                         j1.lisa_d                             AS tp,
                         coalesce(j1.kood1, ''):: VARCHAR(20)  AS tegev,
                         coalesce(j1.kood2, '') :: VARCHAR(20) AS allikas,
                         coalesce(j1.kood3, '')::VARCHAR(20)   AS rahavoog,
                         sum(j1.summa)                         AS deebet,
                         0 :: NUMERIC                          AS kreedit,
                         j1.tunnus,
                         j1.proj,
                         array_agg(d.id) as docs_ids
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                           INNER JOIN qryKontod l ON ltrim(rtrim(l.kood)) = ltrim(rtrim(j1.deebet)),
                       qryParams
                  WHERE d.rekvid IN (SELECT rekv_id
                                     FROM rekv_ids)
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
                    AND d.status <> 3
--                    AND coalesce(a.kpv, j.kpv) <= qryParams.kpv::DATE
                    AND j.kpv <= qryParams.kpv::DATE
                    AND coalesce(a.kpv, j.kpv) >= qryParams.alg_kpv::DATE
                    AND (j1.deebet = '155920' AND j1.kreedit <> '888888' AND d.rekvid IN (130, 28) OR
                         year(qryParams.kpv) < year(qryParams.kpv) OR j1.deebet <> '155920')
                  GROUP BY qryParams.kpv, j.rekvid, j1.deebet, j1.lisa_d, j1.kood1, j1.kood2, j1.kood3, j1.tunnus,
                           j1.proj

                  UNION ALL
                  --                   -- alg kr kaived
                  SELECT qryParams.alg_kpv - 1                 AS kpv,
                         j.rekvid,
                         j1.kreedit                            AS konto,
                         coalesce(j1.lisa_k, ''):: VARCHAR(20) AS tp,
                         coalesce(j1.kood1, '') :: VARCHAR(20) AS tegev,
                         coalesce(j1.kood2, '') :: VARCHAR(20) AS allikas,
                         '00'::VARCHAR(20)                     AS rahavoog,
                         0 :: NUMERIC                          AS deebet,
                         sum(j1.summa)                         AS kreedit,
                         j1.tunnus,
                         j1.proj,
                         array_agg(d.id) as docs_ids
                  FROM docs.doc d
                           INNER JOIN docs.journal j
                                      ON j.parentid = D.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                           INNER JOIN libs.library l ON l.library = 'KONTOD' AND
                                                        l.status <> 3 AND
                                                        ltrim(rtrim(l.kood)) = ltrim(rtrim(j1.kreedit))
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
                       qryParams
                  WHERE d.rekvid IN (SELECT rekv_id
                                     FROM rekv_ids)
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
--                    AND j.kpv <= qryParams.kpv::DATE
                    AND coalesce(a.kpv, j.kpv) <= qryParams.kpv::DATE
                    AND coalesce(a.kpv, j.kpv) < qryParams.alg_kpv::DATE
                    AND d.status <> 3
                    AND (j1.kreedit = '155920' AND j1.deebet <> '888888' AND d.rekvid IN (130, 28) OR
                         year(qryParams.kpv) < year(qryParams.kpv) OR j1.kreedit <> '155920')
                  GROUP BY qryParams.alg_kpv, j.rekvid, j1.kreedit, j1.lisa_k, j1.kood1, j1.kood2, j1.tunnus,
                           j1.proj
                  UNION ALL
                  -- kr kaived
                  SELECT qryParams.kpv                         AS kpv,
                         j.rekvid,
                         j1.kreedit                            AS konto,
                         coalesce(j1.lisa_k, ''):: VARCHAR(20) AS tp,
                         coalesce(j1.kood1, '') :: VARCHAR(20) AS tegev,
                         coalesce(j1.kood2, '') :: VARCHAR(20) AS allikas,
                         coalesce(j1.kood3, '')::VARCHAR(20)   AS rahavoog,
                         0 :: NUMERIC                          AS deebet,
                         sum(j1.summa)                         AS kreedit,
                         j1.tunnus,
                         j1.proj,
                         array_agg(d.id) as docs_ids
                  FROM docs.doc d
                           INNER JOIN docs.journal j
                                      ON j.parentid = D.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                           INNER JOIN libs.library l ON l.library = 'KONTOD' AND
                                                        l.status <> 3 AND
                                                        ltrim(rtrim(l.kood)) = ltrim(rtrim(j1.kreedit))
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
                       qryParams
                  WHERE d.rekvid IN (SELECT rekv_id
                                     FROM rekv_ids)
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
                    AND j.kpv <= qryParams.kpv::DATE
--                    AND coalesce(a.kpv, j.kpv) <= qryParams.kpv::DATE
                    AND coalesce(a.kpv, j.kpv) >= qryParams.alg_kpv::DATE
                    AND d.status <> 3
                    AND (j1.kreedit = '155920' AND j1.deebet <> '888888' AND d.rekvid IN (130, 28) OR
                         year(qryParams.kpv) < year(qryParams.kpv) OR j1.kreedit <> '155920')
                  GROUP BY qryParams.kpv, j.rekvid, j1.kreedit, j1.lisa_k, j1.kood1, j1.kood2, j1.kood3, j1.tunnus,
                           j1.proj
              )
         SELECT rekv_id,
                trim(konto) :: VARCHAR(20)              AS konto,
                trim(tp):: VARCHAR(20)                  AS TP,
                trim(tegev) :: VARCHAR(20)              AS tegev,
                trim(allikas) :: VARCHAR(20)            AS allikas,
                trim(rahavoog) :: VARCHAR(20)           AS rahavoog,
                sum(CASE
                        WHEN EMPTY(qry.tyyp) OR qry.tyyp = 1 OR qry.tyyp = 3 THEN deebet - kreedit
                        ELSE 0 END)::NUMERIC(14, 2)     AS deebet,
                sum(
                        CASE
                            WHEN qry.tyyp = 2 OR qry.tyyp = 4 THEN kreedit - deebet
                            ELSE 0 END)::NUMERIC(14, 2) AS kreedit,
                qry.tyyp::INTEGER
         FROM (
                  SELECT qry.rekvid                  AS rekv_id,
                         konto::TEXT                 AS konto,
                         (CASE
                              WHEN left(konto, 6) IN ('155920')
                                  AND qry.kpv < '2022-10-01'
                                  AND (qry.rahavoog = '00' OR qry.kpv <
                                                              make_date(date_part('year', qryParams.kpv::DATE)::INTEGER, 1, 1))
                                  AND year(qryParams.kpv) < year(qryParams.kpv)
                                  THEN ''
/*                              WHEN l.is_tp AND left(konto, 6) IN ('150200', '150210', '150020') AND
                                   ltrim(rtrim(coalesce(rahavoog, ''))) IN ('01', '00', '17', '21','18')
                                  THEN tp
*/
                              WHEN l.is_tp AND
                                   (l.tp_req <> '*' OR
                                    ltrim(rtrim(coalesce(rahavoog, ''))) = '01')
                                  THEN tp
                              ELSE '' END)::CHAR(20) AS tp,
                         (CASE
                              WHEN left(konto, 6) IN ('155920') AND (qry.rahavoog = '00' OR qry.kpv <
                                                                                            make_date(date_part('year', qryParams.kpv::DATE)::INTEGER, 1, 1))
                                  AND qry.kpv < '2022-10-01' AND year(qryParams.kpv) < year(qryParams.kpv)
                                  THEN ''
                              WHEN l.is_tegev AND (l.tt_req <> '*' OR
                                                   ltrim(rtrim(qry.rahavoog)) = '01')
                                  THEN tegev
                              ELSE
                                  '' END)::TEXT      AS tegev,
                         (CASE
                              WHEN l.is_allikas AND (l.a_req <> '*' OR
                                                     ltrim(rtrim(qry.rahavoog)) = '01')
                                  THEN allikas
                              ELSE
                                  '' END)::TEXT      AS allikas,
                         (CASE
                              WHEN l.is_rahavoog
                                  THEN '00'
                              ELSE
                                  '' END)::TEXT      AS rahavoog,
                         CASE
                             WHEN l.tyyp IS NULL OR l.tyyp IN (0, 1, 3)
                                 THEN (deebet) - (kreedit)
                             ELSE 0 END              AS deebet,
                         CASE
                             WHEN l.tyyp IS NOT NULL AND l.tyyp IN (2, 4)
                                 THEN (kreedit) - (deebet)
                             ELSE 0 END              AS kreedit,
                         l.tyyp                      AS tyyp
                  FROM qrySaldoAndmik qry
                           INNER JOIN qryKontod l ON ltrim(rtrim(l.kood)) = ltrim(rtrim(qry.konto)),
                       qryParams
                  WHERE konto NOT IN ('999999',
                                      '000000',
                                      '888888')
                    AND qry.kpv < make_date(date_part('year', qryParams.kpv::DATE)::INTEGER, 1, 1)
                    AND l.tyyp < 3
                    AND ((qryParams.jsonb_params::JSONB ->> 'tunnus') IS NULL OR
                         coalesce(qry.tunnus, '') ILIKE
                         coalesce((qryParams.jsonb_params::JSONB ->> 'tunnus'), '') || '%')
                    AND ((qryParams.jsonb_params::JSONB ->> 'proj') IS NULL OR
                         coalesce(qry.proj, '') ILIKE
                         coalesce((qryParams.jsonb_params::JSONB ->> 'proj'), '') || '%')
                  UNION ALL
                  SELECT qry.rekvid                 AS rekv_id,
                         konto::TEXT                AS konto,
                         (CASE
                              WHEN is_tp AND (l.tp_req <> '*' OR
                                              ltrim(rtrim(qry.rahavoog)) IN ('01'))
                                  THEN tp
                              ELSE
                                  '' END)::CHAR(20) AS tp,
                         (CASE
                              WHEN is_tegev AND (l.tt_req <> '*' OR
                                                 ltrim(rtrim(qry.rahavoog)) = '01')
                                  THEN tegev
                              ELSE
                                  '' END)::TEXT     AS tegev,
                         (CASE
                              WHEN is_allikas AND (l.a_req <> '*' OR
                                                   ltrim(rtrim(qry.rahavoog)) = '01')
                                  THEN allikas
                              ELSE
                                  '' END)::TEXT     AS allikas,
                         (CASE
                              WHEN is_rahavoog
                                  THEN rahavoog
                              ELSE
                                  '' END)::TEXT     AS rahavoog,
                         CASE
                             WHEN l.tyyp IS NULL OR l.tyyp IN (0, 1, 3)
                                 THEN (deebet) - (kreedit)
                             ELSE 0 END             AS deebet,
                         CASE
                             WHEN l.tyyp IS NOT NULL AND l.tyyp IN (2, 4)
                                 THEN (kreedit) - (deebet)
                             ELSE 0 END             AS kreedit,
                         l.tyyp
                  FROM qrySaldoAndmik qry
                           INNER JOIN qryKontod l ON ltrim(rtrim(l.kood)) = ltrim(rtrim(qry.konto)),
                       qryParams
                  WHERE konto NOT IN ('999999',
                                      '000000',
                                      '888888')
                    AND qry.kpv >= make_date(date_part('year', qryParams.kpv::DATE)::INTEGER, 1, 1)
                    AND ((qryParams.jsonb_params::JSONB ->> 'tunnus') IS NULL OR
                         coalesce(qry.tunnus, '') ILIKE
                         coalesce((qryParams.jsonb_params::JSONB ->> 'tunnus'), '') || '%')
                    AND ((qryParams.jsonb_params::JSONB ->> 'proj') IS NULL OR
                         coalesce(qry.proj, '') ILIKE
                         coalesce((qryParams.jsonb_params::JSONB ->> 'proj'), '') || '%')
              ) qry
         WHERE deebet <> 0
            OR kreedit <> 0
         GROUP BY rekv_id
                 , trim(konto)
                 , trim(tp)
                 , trim(tegev)
                 , trim(allikas)
                 , trim(rahavoog)
                 , tyyp
     ) tmp
WHERE deebet <> 0
   OR kreedit <> 0
GROUP BY rekv_id
        , konto
        , tp
        , tegev
        , allikas
        , rahavoog
        , tyyp ;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION eelarve.saldoandmik_aruanne(DATE, INTEGER, INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.saldoandmik_aruanne(DATE, INTEGER, INTEGER, JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.saldoandmik_aruanne(DATE, INTEGER, INTEGER, JSONB) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.saldoandmik_aruanne(DATE, INTEGER, INTEGER, JSONB) TO dbvaatleja;


/*

execution: 5 s 606 ms , 124, 137795039.74,137795039.74
75545499.52,120946102.82

explain

SELECT sum(deebet) over(), sum(kreedit) over(), *
FROM eelarve.saldoandmik_aruanne_('2023-12-31' :: DATE, 131 :: INTEGER, 1 ::integer)
WHERE konto like '150020%'
--and rahavoog = '01'
--GROUP BY konto, tp


konto;tp;tegev;allikas;rahavoog;deebet;kreedit;tyyp
103799;014001;"";"";"";2654.62;0;1
155400;"";"";"";00;34500;0;1
155410;"";"";"";00;-2300;0;1
155410;"";"";"";11;-6900;0;1
201000;800599;"";"";"";0;49.95;2
202010;800699;"";"";"";0;8285.32;2
203010;014001;"";"";"";0;4165.12;2
203020;014001;"";"";"";0;2447.67;2
203030;014001;"";"";"";0;262.91;2
203035;014001;"";"";"";0;45.02;2


*/