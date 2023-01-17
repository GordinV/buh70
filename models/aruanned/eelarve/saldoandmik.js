module.exports = {
    grid: {
        gridConfiguration: [
            {id: "konto", name: "konto", width: "25px", show: false},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "alg_db", name: "Alg.Deebet", width: "100px"},
            {id: "alg_kr", name: "Alg.Kreedit", width: "75px"},
            {id: "deebet", name: "Deebet", width: "100px"},
            {id: "kreedit", name: "Kreedit", width: "100px"},
            {id: "lopp_db", name: "Lõpp deebet", width: "100px"},
            {id: "lopp_kr", name: "Lõpp kreedit", width: "200px"}
        ],
        sqlString: ` WITH qryParams AS (
                         SELECT $1::date        AS kpv,
                                $2::integer        AS rekvid,
                                $3::integer        AS kond,
                                $4::JSONB AS jsonb_params
                     ),
                          rekv_ids AS (
                              SELECT rekv_id
                              FROM qryParams, public.get_asutuse_struktuur(qryParams.rekvid)

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
                                          NOT empty(l.tun1)   AS is_tp,
                                          NOT empty(l.tun2)   AS is_tegev,
                                          NOT empty(l.tun3)   AS is_allikas,
                                          NOT empty(l.tun4)   AS is_rahavoog,
                                          coalesce(l.tun5, 1) AS tyyp,
                                          l.muud
                                   FROM libs.library l
                                   WHERE l.library = 'KONTOD'
                                     AND l.status <> 3)
                              ),

                                   qrySaldoAndmik AS (
                                       SELECT coalesce(a.kpv, j.kpv)                AS kpv,
                                              j.rekvid,
                                              j1.deebet                             AS konto,
                                              j1.lisa_d                             AS tp,
                                              coalesce(j1.kood1, ''):: VARCHAR(20)  AS tegev,
                                              coalesce(j1.kood2, '') :: VARCHAR(20) AS allikas,
                                              coalesce(CASE
                                                           WHEN j.kpv <
                                                                make_date(date_part('year', qryParams.kpv::DATE)::INTEGER, 1, 1)
                                                               THEN '00'
                                                           ELSE j1.kood3 :: VARCHAR(20) END,
                                                       '')::VARCHAR(20)             AS rahavoog,
                                              (j1.summa)                            AS deebet,
                                              0 :: NUMERIC                          AS kreedit,
                                              j1.tunnus,
                                              j1.proj
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
                                         AND j.kpv <= qryParams.kpv::DATE
                                       UNION ALL
                                       SELECT coalesce(a.kpv, j.kpv),
                                              j.rekvid,
                                              j1.kreedit                            AS konto,
                                              coalesce(j1.lisa_k, ''):: VARCHAR(20) AS tp,
                                              j1.kood1 :: VARCHAR(20)               AS tegev,
                                              coalesce(j1.kood2, '') :: VARCHAR(20) AS allikas,
                                              coalesce(CASE
                                                           WHEN j.kpv <
                                                                make_date(date_part('year', qryParams.kpv::DATE)::INTEGER, 1, 1)
                                                               THEN '00'
                                                           ELSE j1.kood3 :: VARCHAR(20) END,
                                                       '')::VARCHAR(20)             AS rahavoog,
                                              0 :: NUMERIC                          AS deebet,
                                              (j1.summa)                            AS kreedit,
                                              j1.tunnus,
                                              j1.proj

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
                                         AND d.status <> 3
                                   )
                              SELECT rekv_id,
                                     konto :: VARCHAR(20),
                                     tp:: CHAR(20),
                                     tegev :: VARCHAR(20),
                                     allikas :: VARCHAR(20),
                                     rahavoog :: VARCHAR(20),
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
                                              konto::TEXT        AS konto,
                                              (CASE
                                                   WHEN left(konto, 6) IN ('155920') AND (qry.rahavoog = '00' OR qry.kpv <
                                                                                                                 make_date(date_part('year', qryParams.kpv::DATE)::INTEGER, 1, 1))                                                                                                                 
                                                       AND qry.kpv < '2022-10-01'
                                                       THEN ''                                              
                                                   WHEN l.is_tp AND left(konto, 6) IN ('150200', '150210', '150020') AND
                                                        ltrim(rtrim(coalesce(rahavoog, ''))) IN ('01', '00', '17', '21','18')
                                                       THEN tp
                                                   WHEN l.is_tp AND
                                                        (ltrim(rtrim(coalesce(l.muud, ''))) <> '*' OR
                                                         ltrim(rtrim(coalesce(rahavoog, ''))) = '01')
                                                       THEN tp
                                                   ELSE '' END)::CHAR(20) AS tp,
                                              (CASE
                                                   WHEN left(konto, 6) IN ('155920') AND (qry.rahavoog = '00' OR qry.kpv <
                                                                                                                 make_date(date_part('year', qryParams.kpv::DATE)::INTEGER, 1, 1))
                                                       AND qry.kpv < '2022-10-01'
                                                       THEN ''
                                                   WHEN l.is_tegev AND (ltrim(rtrim(COALESCE(l.muud, ''))) <> '*' OR
                                                                        ltrim(rtrim(qry.rahavoog)) = '01')
                                                       THEN tegev
                                                   ELSE
                                                       '' END)::TEXT      AS tegev,
                                              (CASE
                                                   WHEN l.is_allikas
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
                                              konto::TEXT       AS konto,
                                              (CASE
                                                   WHEN is_tp AND (ltrim(rtrim(COALESCE(l.muud, ''))) <> '*' OR
                                                                   ltrim(rtrim(qry.rahavoog)) IN ('01', '00', '21', '17','18'))
                                                       THEN tp
                                                   ELSE
                                                       '' END)::CHAR(20) AS tp,
                                              (CASE
                                                   WHEN is_tegev AND (ltrim(rtrim(COALESCE(l.muud, ''))) <> '*' OR
                                                                      ltrim(rtrim(qry.rahavoog)) = '01')
                                                       THEN tegev
                                                   ELSE
                                                       '' END)::TEXT     AS tegev,
                                              (CASE
                                                   WHEN is_allikas
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
                                      , konto
                                      , tp
                                      , tegev
                                      , allikas
                                      , rahavoog
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
                             , tyyp`,
        // $1 - kpv $2 - rekvid , $3 - KOND, $4 tunnus
        params: '',
        alias: 'saldoandmik_report'
    }
};
