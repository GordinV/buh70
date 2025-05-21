--DROP FUNCTION IF EXISTS palk.tsd_lisa_1(DATE, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.tsd_lisa_1_(DATE, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.tsd_lisa_1(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION palk.tsd_lisa_1(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE
            (
                isikukood          VARCHAR(20),
                isik               VARCHAR(254),
                tululiik           VARCHAR(20),
                liik               INTEGER,
                minsots            NUMERIC(14, 2),
                sm_arv             INTEGER,
                tk_arv             INTEGER,
                minpalk            NUMERIC(14, 2),
                summa              NUMERIC(14, 2),
                puhkused           NUMERIC(14, 2),
                haigused           NUMERIC(14, 2),
                tm                 NUMERIC(14, 2),
                sm                 NUMERIC(14, 2),
                tki                NUMERIC(14, 2),
                pm                 NUMERIC(14, 2),
                tka                NUMERIC(14, 2),
                tulubaas           NUMERIC(14, 2),
                puhkus             NUMERIC(14, 2),
                v1040              NUMERIC(14, 2),
                lopp               DATE,
                arv_min_sots       NUMERIC(14, 2),
                min_sots_alus      NUMERIC(14, 2),
                eri_tm             NUMERIC(14, 2),
                eri_sm             NUMERIC(14, 2),
                lisa_min_sots      NUMERIC(14, 2),
                lisa_sm_alus       NUMERIC(14, 2),
                sm_kokku           NUMERIC(14, 2),
                lisa_sm_arvestatud NUMERIC(14, 2),
                alus_sm_arvestatud NUMERIC(14, 2),
                kas_pensionar      INTEGER

            )
AS
$BODY$
WITH
    qrySMKokku AS (
                      SELECT
                          sum(summa) AS sm_kokku
                      FROM
                          palk.cur_palkoper po
                      WHERE
                            po.palk_liik = 'SOTSMAKS'
                        AND (
                                (po.kpv >= l_kpv1
                                    AND po.kpv <= l_kpv2
                                    and po.dekl_kpv is null)
                                    or (po.dekl_kpv is not null
                                    and po.dekl_kpv >= l_kpv1
                                    and po.dekl_kpv <= l_kpv2)
                                )
                        AND rekvid = (CASE
                                          WHEN l_kond IS NOT NULL
                                              THEN l_rekvid
                                          ELSE rekvid END)
                        AND rekvId IN (
                                          SELECT
                                              rekv_id
                                          FROM
                                              get_asutuse_struktuur(l_rekvid)
                                      )
    )
SELECT
    isikukood,
    isik,
    tululiik,
    liik,
    minsots,
    sm_arv,
    tk_arv,
    minpalk,
    coalesce(summa, 0)::NUMERIC(14, 2),
    coalesce(puhkused, 0)::NUMERIC(14, 2),
    coalesce(haigused, 0)::NUMERIC(14, 2),
    coalesce(tm, 0)::NUMERIC(14, 2),
    coalesce(sm, 0)::NUMERIC(14, 2),
    coalesce(tki, 0)::NUMERIC(14, 2),
    coalesce(pm, 0)::NUMERIC(14, 2),
    coalesce(tka, 0)::NUMERIC(14, 2),
    coalesce(tulubaas, 0)::NUMERIC(14, 2),
    coalesce(puhkus, 0)::NUMERIC(14, 2),
    coalesce(v1040, 0)::NUMERIC(14, 2),
    lopp,
    coalesce(arv_min_sots, 0)::NUMERIC(14, 2),
    coalesce(min_sots_alus, 0)::NUMERIC(14, 2),
    coalesce(eri_tm, 0)::NUMERIC(14, 2),
    coalesce(eri_sm, 0)::NUMERIC(14, 2),
    arv_min_sots * sm_arv                                                 AS lisa_min_sots,
    min_sots_alus * sm_arv                                                AS lisa_sm_alus,
    qrySMKokku.sm_kokku                                                   AS sm_kokku,
    lisa_sm_arvestatud,
    alus_sm_arvestatud,
    CASE WHEN palk.kas_soodustus_mvt(isikukood, l_kpv1) THEN 1 ELSE 0 END AS kas_pensionar
FROM
    (
        WITH
            qryKoormus AS (
                              SELECT
                                  a.regkood :: VARCHAR(20)                   AS isikukood,
                                  a.nimetus :: VARCHAR(254)                  AS isik,
                                  sum(koormus) :: NUMERIC                    AS koormus,
                                  max(coalesce(qryMinSots.arv_min_sots, 0))  AS arv_min_sots,
                                  max(coalesce(qryMinSots.min_sots_alus, 0)) AS min_sots_alus
                              FROM
                                  palk.tooleping                  t
                                      INNER JOIN      libs.asutus a ON a.id = t.parentId
                                      INNER JOIN      ou.rekv ON rekv.id = t.rekvId
                                      LEFT OUTER JOIN (
                                                          SELECT
                                                              po.lepingid,
                                                              po.rekvid,
                                                              po.summa    AS arv_min_sots,
                                                              po.sotsmaks AS min_sots_alus
                                                          FROM
                                                              palk.palk_oper             po
                                                                  INNER JOIN com_palklib pl
                                                                             ON pl.id = po.libid AND pl.liik = 5 AND po.sotsmaks <> 0
                                                          WHERE
                                                                (
                                                                    (po.kpv >= l_kpv1
                                                                        AND po.kpv <= l_kpv2
                                                                        and po.properties ->> 'maksekpv' is null)
                                                                        or (po.properties ->> 'maksekpv' is not null
                                                                        and (po.properties ->> 'maksekpv')::date >=
                                                                            l_kpv1
                                                                        and (po.properties ->> 'maksekpv')::date <=
                                                                            l_kpv2)
                                                                    )
                                                            AND po.period IS NULL -- убрать доп.соц налог из lisa1b
                                                      )           qryMinSots
                                                      ON qryMinSots.lepingid = t.id AND qryMinSots.rekvid = rekv.id
                              WHERE
                                    rekv.id = (CASE
                                                   WHEN l_kond IS NOT NULL
                                                       THEN l_rekvid
                                                   ELSE rekv.id END)
                                AND rekv.Id IN (
                                                   SELECT
                                                       rekv_id
                                                   FROM
                                                       get_asutuse_struktuur(l_rekvid)
                                               )
                                AND algab <= l_kpv2
                                AND (lopp IS NULL OR lopp >= l_kpv1)
                                AND t.resident = 1
                                AND t.status < 3
                              GROUP BY a.regkood, a.nimetus
                          ),
            qryLisaSM AS (
                              SELECT
                                  a.regkood     AS isikukood,
                                  sum(summa)    AS sotsmaks,
                                  sum(sotsmaks) AS alus
                              FROM
                                  palk.palk_oper                po
                                      INNER JOIN libs.library   l ON l.id = po.libid
                                      INNER JOIN palk.tooleping t ON t.id = po.lepingid
                                      INNER JOIN libs.asutus    a ON a.id = t.parentid
                              WHERE
                                    po.rekvid IN (
                                                     SELECT
                                                         rekv_id
                                                     FROM
                                                         get_asutuse_struktuur(l_rekvid)
                                                 )
                                AND po.rekvid = (CASE
                                                     WHEN l_kond IS NOT NULL
                                                         THEN l_rekvid
                                                     ELSE po.rekvid END)
                                AND po.kpv >= l_kpv1
                                AND po.kpv <= l_kpv2
                                AND po.period IS NULL -- убрать доп.соц налог из lisa1b
                                AND l.properties::JSONB ->> 'liik' = '5'
                              GROUP BY a.regkood
                          ),

            qryEriTM AS (
                              SELECT
                                  sum(summa) AS summa,
                                  asutusid
                              FROM
                                  cur_journal j
                              WHERE
                                    kpv >= l_kpv1
                                AND kpv <= l_kpv2
                                AND kreedit LIKE '203040%'
                                AND rekvid = (CASE
                                                  WHEN l_kond IS NOT NULL
                                                      THEN l_rekvid
                                                  ELSE rekvid END)
                                AND rekvId IN (
                                                  SELECT
                                                      rekv_id
                                                  FROM
                                                      get_asutuse_struktuur(l_rekvid)
                                              )
                              GROUP BY asutusid
                          ),
            qryEriSM AS (
                              SELECT
                                  sum(summa) AS summa,
                                  asutusid
                              FROM
                                  cur_journal j
                              WHERE
                                    kpv >= l_kpv1
                                AND kpv <= l_kpv2
                                AND deebet LIKE '506010%'
                                AND kreedit LIKE '203010%'
                                AND rekvid = (CASE
                                                  WHEN l_kond IS NOT NULL
                                                      THEN l_rekvid
                                                  ELSE rekvid END)
                                AND rekvId IN (
                                                  SELECT
                                                      rekv_id
                                                  FROM
                                                      get_asutuse_struktuur(l_rekvid)
                                              )
                              GROUP BY asutusid
                          )


        SELECT
            (CASE
                 WHEN qry.isikukood IS NULL
                     THEN qryKoormus.isikukood
                 ELSE qry.isikukood END) :: VARCHAR(20),
            (CASE
                 WHEN qry.isik IS NULL
                     THEN qryKoormus.isik
                 ELSE qry.isik END) :: VARCHAR(253),
            qry.tululiik,
            qry.liik,
            max(COALESCE(qry.minsots, 0) :: NUMERIC(14, 2))      AS minsots,
            qry.sm_arv,
            qry.tk_arv,
            max(COALESCE(qry.minpalk, 0) :: NUMERIC(14, 2))      AS minpalk,
            sum(qry.summa)                                       AS summa,
            sum(qry.puhkused)                                    AS puhkused,
            sum(qry.haigused)                                    AS haigused,
            sum(qry.tm)                                          AS tm,
            sum(qry.sm)                                          AS sm,
            sum(qry.tki)                                         AS tki,
            sum(qry.pm)                                          AS pm,
            sum(qry.tka)                                         AS tka,
            sum(qry.tulubaas)                                    AS tulubaas,
            sum(qry.puhkus)                                      AS puhkus,

            max(round(CASE
                          WHEN qryKoormus.koormus IS NULL
                              THEN qry.koormus
                          ELSE qryKoormus.koormus END / 100, 2)) AS v1040,

            MAX(qry.lopp)                                        AS lopp,
            max(qry.arv_min_sots)                                AS arv_min_sots,
            max(qry.min_sots_alus)                               AS min_sots_alus,
            sum(COALESCE(qryEriTm.summa, 0))::NUMERIC(14, 2)     AS eri_tm,
            sum(COALESCE(qryEriSm.summa, 0))::NUMERIC(14, 2)     AS eri_sm,
            sum(qryLisaSM.sotsmaks)                              AS lisa_sm_arvestatud,
            sum(qryLisaSM.alus)                                  AS alus_sm_arvestatud
        FROM
            (
                SELECT
                    a.regkood                                                         AS isikukood,
                    a.nimetus                                                         AS isik,
                    po.summa                                                          AS summa,
                    (CASE
                         WHEN pl.liik = 1 AND pl.kood ILIKE '%PUHKUS%'
                             THEN po.summa
                         ELSE 0 END)                                                  AS puhkused,
                    (CASE
                         WHEN pl.liik = 1 AND pl.kood ILIKE '%HAIGUS%'
                             THEN po.summa
                         ELSE 0 END)                                                  AS haigused,
                    (po.tulumaks)                                                     AS tm,
                    (po.sotsmaks)                                                     AS sm,
                    (po.tootumaks)                                                    AS tki,
                    (po.pensmaks)                                                     AS pm,
                    (po.tka)                                                          AS tka,
                    (po.tulubaas)                                                     AS tulubaas,
                    po.tululiik,
                    pl.liik,
                    COALESCE(l.tun1, 0)                                               AS tm_maar,
                    COALESCE(l.tun4, 0)                                               AS tk_arv,
                    COALESCE(l.tun5, 0)                                               AS pm_arv,
                    COALESCE(l.tun1, 0)                                               AS tm_arv,
                    COALESCE(l.tun2, 0)                                               AS sm_arv,
                    t.riik,
                    po.period,
                    (pc.minpalk * (
                                      SELECT
                                          minsots
                                      FROM
                                          palk.palk_kaart            pk_
                                              INNER JOIN com_palklib pl_ ON pl_.id = pk_.libid AND pl_.liik = 5
                                      WHERE
                                            pk_.lepingid = t.id
                                        AND pk_.status = 1
                                      LIMIT 1
                                  ) * pc.sm / 100)                                    AS minsots,
                    pc.minpalk,
                    a.id,
                    COALESCE(t.lopp, '2099-12-31' :: DATE)                            AS lopp,
                    COALESCE(qryMinSots.arv_min_sots, 0)                              AS arv_min_sots,
                    COALESCE(qryMinSots.min_sots_alus, 0)                             AS min_sots_alus,
                    COALESCE(sp_puudumise_paevad(l_kpv1 :: DATE, t.id), 0) :: NUMERIC AS puhkus,
                    COALESCE(t.koormus, 0)                                            AS koormus
                FROM
                    palk.tooleping                       t
                        INNER JOIN      libs.asutus      a ON a.id = t.parentid
                        INNER JOIN      palk.palk_oper   po ON po.lepingid = t.id
                        INNER JOIN      com_palklib      pl ON pl.id = po.libId
                                            --                           LEFT OUTER JOIN palk.palk_kaart pk ON pk.lepingId = t.id AND pk.libid = po.libid
--                           INNER JOIN ou.rekv ON rekv.id = po.rekvid
                        LEFT OUTER JOIN libs.LIBRARY     l ON l.kood = po.tululiik AND l.library = 'MAKSUKOOD'
                        LEFT OUTER JOIN palk.palk_config pc ON pc.rekvid = t.rekvid
                        LEFT OUTER JOIN (
                                            SELECT
                                                po.lepingid,
                                                po.rekvid,
                                                po.summa    AS arv_min_sots,
                                                po.sotsmaks AS min_sots_alus
                                            FROM
                                                palk.palk_oper             po
                                                    INNER JOIN com_palklib pl ON pl.id = po.libid AND pl.liik = 5 AND po.sotsmaks <> 0
                                            WHERE
                                                  po.kpv >= l_kpv1
                                              AND po.kpv <= l_kpv2
                                        )                qryMinSots
                                        ON qryMinSots.lepingid = t.id AND qryMinSots.rekvid = t.rekvid

                WHERE
--                      po.kpv >= l_kpv1
--                  AND po.kpv <= l_kpv2
--                  AND
                    (
                        (po.kpv >= l_kpv1
                        AND po.kpv <= l_kpv2
                        and po.properties ->> 'maksekpv' is null)
                        or (po.properties ->> 'maksekpv' is not null
                            and (po.properties ->> 'maksekpv')::date >= l_kpv1
                            and (po.properties ->> 'maksekpv')::date <= l_kpv2)
                    )

                  AND period IS NULL
                  AND pl.liik = 1
                  AND t.resident = 1
                  AND t.rekvid = (CASE
                                      WHEN l_kond IS NOT NULL
                                          THEN l_rekvid
                                      ELSE t.rekvid END)
                  AND t.rekvId IN (
                                      SELECT
                                          rekv_id
                                      FROM
                                          get_asutuse_struktuur(l_rekvid)
                                  )
            ) qry
                FULL OUTER JOIN qryKoormus ON qryKoormus.isikukood = qry.isikukood
                LEFT OUTER JOIN qryLisaSM ON qryLisaSM.isikukood = qryKoormus.isikukood
                FULL OUTER JOIN qryEriTm ON qryEriTm.asutusid = qry.Id
                FULL OUTER JOIN qryEriSm ON qryEriSm.asutusid = qry.Id
        GROUP BY
            qry.id, qry.isikukood, qryKoormus.isikukood, qry.isik, qryKoormus.isik,
            tululiik, liik, riik, period, sm_arv, tk_arv --, minsots, minpalk
    ) qry,
      qrySMKokku
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.tsd_lisa_1( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.tsd_lisa_1( DATE, DATE, INTEGER, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.tsd_lisa_1( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;


/*

SELECT sum(qry.sm_kokku) as sm, sum(sm_kokku_1) as sm_1
FROM
(

isikukood in ('46408083713','37502100015')


) qry
where isikukood = '47608283744'

union all
         SELECT -1 * sum(c_1410)
         FROM palk.tsd_lisa_1b('2021-01-01', '2021-01-31', 96, 0 :: INTEGER)
) qry

--where isikukood = '35908263723'

select * from ou.rekv where nimetus like '0911007 %'
*/