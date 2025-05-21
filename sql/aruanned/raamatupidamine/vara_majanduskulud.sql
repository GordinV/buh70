DROP FUNCTION IF EXISTS docs.vara_majanduskulud(DATE, DATE, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.vara_majanduskulud(kpv_start DATE, kpv_end DATE, l_rekv_id INTEGER,
                                                   l_params JSONB DEFAULT NULL::JSONB)
    RETURNS TABLE
            (
                konto         VARCHAR(20),
                konto_nimetus VARCHAR(254),
                objekt        VARCHAR(254),
                uksus         VARCHAR(20),
                kogus         NUMERIC(12, 4),
                summa         NUMERIC(12, 2),
                kaibemaks     NUMERIC(12, 2),
                kokku         NUMERIC(12, 2),
                tunnus        VARCHAR(20),
                tegev         VARCHAR(20),
                artikkel      VARCHAR(20),
                allikas       VARCHAR(20),
                projekt       VARCHAR(20),
                uritus        VARCHAR(20),
                partner       VARCHAR(254),
                asutus        VARCHAR(254),
                kas_kulud     INTEGER -- 0 - tulud, 1- kulud
            )
AS
$BODY$
WITH
    params AS (
                  SELECT
                      coalesce(l_params::JSONB ->> 'konto', '')::TEXT || '%'                                                                                         AS konto,
                      coalesce(l_params::JSONB ->> 'tunnus', '')::TEXT || '%'                                                                                        AS tunnus,
                      coalesce(l_params::JSONB ->> 'proj', '')::TEXT || '%'                                                                                          AS proj,
                      coalesce(l_params::JSONB ->> 'objekt', '')::TEXT || '%'                                                                                        AS objekt,
                      coalesce(l_params::JSONB ->> 'uritus', '')::TEXT || '%'                                                                                        AS uritus,
                      coalesce(l_params::JSONB ->> 'tegevus', '')::TEXT || '%'                                                                                       AS tegev,
                      coalesce(l_params::JSONB ->> 'artikkel', '')::TEXT || '%'                                                                                      AS artikkel,
                      coalesce(l_params::JSONB ->> 'allikas', '')::TEXT || '%'                                                                                       AS allikas,
                      coalesce((l_params::JSONB ->> 'kond')::INTEGER, 0)                                                                                             AS kond,
                      coalesce((l_params::JSONB ->> 'asutus_id')::INTEGER, 0)                                                                                        AS asutus_id,
                      kpv_start                                                                                                                                      AS kpv_1,
                      kpv_end                                                                                                                                        AS kpv_2,
                      ARRAY ['551100','551101','551102','551120','551121','551122','551130','551131','551132','551200','551210','551220','323340','323350','323360'] AS kontod
              ),
    rekv_ids AS (
                  SELECT
                      rekv_id
                  FROM
                      params                           p,
                      get_asutuse_struktuur(l_rekv_id) r
                  WHERE
                      CASE
                          WHEN p.kond = 1 THEN TRUE
                          ELSE l_rekv_id = rekv_id END
              ),

    docs_types AS (
                  SELECT
                      id,
                      kood
                  FROM
                      libs.library
                  WHERE
                        library.library = 'DOK'
                    AND kood IN ('ARV')
              ),

    qry_docs AS (
                  SELECT
                      a1.konto                                                         AS konto,
                      coalesce(a1.kood5, '')::VARCHAR(20)                              AS artikkel,
                      coalesce(a1.kood1, '')::VARCHAR(20)                              AS tegevus,
                      coalesce(a1.kood2, '')::VARCHAR(20)                              AS allikas,
                      coalesce(a1.tunnus, '')::VARCHAR(20)                             AS tunnus,
                      coalesce(a1.kood4, '')                                           AS uritus,
                      coalesce(a1.objekt, '')::VARCHAR(20)                             AS objekt,
                      coalesce(a1.proj, '')::VARCHAR(20)                               AS projekt,
                      (a1.summa - a1.kbm):: NUMERIC(12, 2)                             AS summa,
                      a1.kbm:: NUMERIC(12, 2)                                          AS kaibemaks,
                      a1.summa:: NUMERIC(12, 2)                                        AS kokku,
                      a.summa                                                          AS doc_summa,
                      d.rekvid,
                      a.asutusid,
                      coalesce((dp.details ->> 'konto'), '')::VARCHAR(20)              AS korr_konto,
                      CASE
                          WHEN left(a1.konto, 1) IN ('3') THEN -1
                          WHEN a.liik = 1 AND left(a1.konto, 1) IN ('5', '6') THEN 1
                          WHEN a.liik = 0 AND left(a1.konto, 1) IN ('5', '6') THEN -1
                          ELSE 1 END                                                   AS mark, -- если восстановление расходов, то знак минус
                      CASE WHEN left(a1.konto, 1) IN ('4', '5', '6') THEN 1 ELSE 0 END AS kas_kulud
                  FROM
                      docs.doc                         d
                          INNER JOIN      docs.arv     a ON a.parentid = d.id
                          left outer join docs.journal j on j.parentid = a.journalid
                          INNER JOIN      docs.arv1    a1 ON a.id = a1.parentid
                          LEFT OUTER JOIN libs.dokprop dp ON dp.id = a.doklausid,
                      params                           p
                  WHERE
                        d.status < 3
                    AND d.rekvid IN (
                                        SELECT
                                            rekv_id
                                        FROM
                                            rekv_ids
                                    )
                    AND coalesce(j.kpv, a.kpv) >= p.kpv_1
                    AND coalesce(j.kpv, a.kpv) <= p.kpv_2
                    AND (left(a1.konto, 3) IN ('551') OR left(a1.konto, 4) IN ('3233'))
                    AND coalesce(a1.tunnus, '') ILIKE p.tunnus
                    AND a1.konto LIKE p.konto
                    AND a1.kood1 LIKE p.tegev
                    AND a1.kood2 ILIKE p.allikas
                    AND a1.kood5 LIKE p.artikkel
                    AND coalesce(a1.proj, '') ILIKE p.proj
                    AND coalesce(a1.objekt, '') ILIKE p.objekt
                    AND coalesce(a1.kood4, '') ILIKE p.uritus
                    AND a.asutusid = CASE WHEN p.asutus_id = 0 THEN a.asutusid ELSE p.asutus_id END
                    AND left(a1.konto, 6) IN (
                                                 SELECT unnest(p.kontod)
                                             )
              )
SELECT
    konto,
    konto_nimetus,
    objekt,
    uksus,
    kogus,
    coalesce(summa, 0)     AS summa,
    coalesce(kaibemaks, 0) AS kaibemaks,
    coalesce(kokku, 0)     AS kokku,
    tunnus,
    tegevus,
    artikkel,
    allikas,
    projekt,
    uritus,
    partner,
    asutus,
    kas_kulud
FROM
    (
        SELECT
            d.konto,
            l.nimetus::VARCHAR(254) AS konto_nimetus,
            d.objekt,
            ''                      AS uksus,
            1::NUMERIC(12, 4)       AS kogus,
            sum(d.mark * summa)     AS summa,
            sum(d.mark * kaibemaks) AS kaibemaks,
            sum(d.mark * kokku)     AS kokku,
            d.tunnus,
            d.tegevus,
            d.artikkel,
            d.allikas,
            d.projekt,
            d.uritus,
            a.nimetus::VARCHAR(254) AS partner,
            r.nimetus::VARCHAR(254) AS asutus,
            kas_kulud::INTEGER,
            10 + kas_kulud          AS idx
        FROM
            qry_docs                         d
                INNER JOIN      ou.rekv      r ON r.id = d.rekvid
                INNER JOIN      libs.asutus  a ON a.id = d.asutusid
                LEFT OUTER JOIN libs.library l ON l.kood = d.konto AND l.library = 'KONTOD' AND l.status < 3
        GROUP BY
            konto,
            artikkel,
            tegevus,
            allikas,
            tunnus,
            uritus,
            objekt,
            projekt,
            a.nimetus,
            r.nimetus,
            l.nimetus,
            d.kas_kulud
        UNION ALL
        -- kokku kulud
        SELECT
            'KOKKU'                 AS konto,
            ''                      AS konto_nimetus,
            ''                      AS objekt,
            ''                      AS uksus,
            0::NUMERIC(12, 4)       AS kogus,
            sum(d.mark * summa)     AS summa,
            sum(d.mark * kaibemaks) AS kaibemaks,
            sum(d.mark * kokku)     AS kokku,
            ''                      AS tunnus,
            ''                      AS tegevus,
            ''                      AS artikkel,
            ''                      AS allikas,
            ''                      AS projekt,
            ''                      AS uritus,
            ''::VARCHAR(254)        AS partner,
            ''::VARCHAR(254)        AS asutus,
            1::INTEGER,
            10                      AS idx
        FROM
            qry_docs                         d
                INNER JOIN      ou.rekv      r ON r.id = d.rekvid
                INNER JOIN      libs.asutus  a ON a.id = d.asutusid
                LEFT OUTER JOIN libs.library l ON l.kood = d.konto AND l.library = 'KONTOD' AND l.status < 3
        WHERE
            kas_kulud = 1
        UNION ALL
        -- kokku tulud
        SELECT
            'KOKKU'                 AS konto,
            ''                      AS konto_nimetus,
            ''                      AS objekt,
            ''                      AS uksus,
            0::NUMERIC(12, 4)       AS kogus,
            sum(d.mark * summa)     AS summa,
            sum(d.mark * kaibemaks) AS kaibemaks,
            sum(d.mark * kokku)     AS kokku,
            ''                      AS tunnus,
            ''                      AS tegevus,
            ''                      AS artikkel,
            ''                      AS allikas,
            ''                      AS projekt,
            ''                      AS uritus,
            ''::VARCHAR(254)        AS partner,
            ''::VARCHAR(254)        AS asutus,
            0::INTEGER,
            11                      AS idx
        FROM
            qry_docs                         d
                INNER JOIN      ou.rekv      r ON r.id = d.rekvid
                INNER JOIN      libs.asutus  a ON a.id = d.asutusid
                LEFT OUTER JOIN libs.library l ON l.kood = d.konto AND l.library = 'KONTOD' AND l.status < 3
        WHERE
            kas_kulud = 0
        UNION ALL
        -- kokku
        SELECT
            'KOKKU'                            AS konto,
            'võttes arvesse kulude taastamist' AS konto_nimetus,
            ''                                 AS objekt,
            ''                                 AS uksus,
            0::NUMERIC(12, 4)                  AS kogus,
            sum(d.mark * summa)                AS summa,
            sum(d.mark * kaibemaks)            AS kaibemaks,
            sum(d.mark * kokku)                AS kokku,
            ''                                 AS tunnus,
            ''                                 AS tegevus,
            ''                                 AS artikkel,
            ''                                 AS allikas,
            ''                                 AS projekt,
            ''                                 AS uritus,
            ''::VARCHAR(254)                   AS partner,
            ''::VARCHAR(254)                   AS asutus,
            0::INTEGER,
            12                                 AS idx
        FROM
            qry_docs                         d
                INNER JOIN      ou.rekv      r ON r.id = d.rekvid
                INNER JOIN      libs.asutus  a ON a.id = d.asutusid
                LEFT OUTER JOIN libs.library l ON l.kood = d.konto AND l.library = 'KONTOD' AND l.status < 3
    ) qry
ORDER BY
    kas_kulud DESC, konto, idx, asutus, partner


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.vara_majanduskulud(DATE, DATE, INTEGER, JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.vara_majanduskulud(DATE, DATE, INTEGER, JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.vara_majanduskulud(DATE, DATE, INTEGER, JSONB) TO dbkasutaja;

SELECT *
FROM
    docs.vara_majanduskulud('2024-01-01'::DATE, '2024-02-28'::DATE, 66::INTEGER, NULL::JSONB)
--WHERE partner = 'Osauhing CHIC Ilustuudio'

/*
select * from libs.asutus where nimetus like '%DATEL%'

select * from docs.dokumendid(3022499)


*/