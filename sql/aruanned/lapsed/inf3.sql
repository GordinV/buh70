DROP FUNCTION IF EXISTS lapsed.inf3(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.inf3(INTEGER, TEXT);

CREATE OR REPLACE FUNCTION lapsed.inf3(l_rekvid INTEGER, l_aasta TEXT DEFAULT year(current_date)::TEXT)
    RETURNS TABLE
            (
                summa              NUMERIC(14, 2),
                maksja_nimi        TEXT,
                maksja_isikukood   TEXT,
                lapse_nimi         TEXT,
                lapse_isikukood    TEXT,
                aasta              INTEGER,
                rekvid             INTEGER,
                liik               INTEGER,
                docs_arv_ids       TEXT,
                docs_tasu_ids      TEXT,
                doc_tagastused_ids TEXT,
                asutuse_regkood    text,
                kas_18             boolean
            )
AS
$BODY$
WITH
    params AS (
                  SELECT
                      CASE
                          WHEN l_aasta IS NULL OR l_aasta::TEXT = '' THEN year(current_date)::TEXT
                          ELSE l_aasta END::INTEGER AS aasta
              ),
    asutuse_rekv as (
                  select
                      regkood
                  from
                      ou.rekv r
                  where
                      r.id = l_rekvid
                  limit 1
              )
SELECT
    report.summa,
    --CASE WHEN report.summa < 0 THEN 0 ELSE report.summa END::NUMERIC(14, 2) AS summa,
    report.maksja_nimi,
    ltrim(rtrim(report.maksja_isikukood))                                                     AS maksja_isikukood,
    report.lapse_nimi,
    ltrim(rtrim(report.lapse_isikukood))                                                      AS lapse_isikukood,
    report.aasta::INTEGER,
    report.rekvid::INTEGER,
    report.liik::INTEGER,
    report.docs_arv_ids::TEXT,
    report.docs_tasu_ids::TEXT,
    report.doc_tagastused_ids::TEXT,
    r.regkood::text                                                                           as asutuse_regkood,
    extract('year' FROM
            age(make_date(params.aasta, 01, 01), palk.get_sunnipaev(report.lapse_isikukood))) < 18 as kas_18
FROM
    (
        SELECT
            sum(summa)                             AS summa,
            a.nimetus::TEXT                        AS maksja_nimi,
            a.regkood::TEXT                        AS maksja_isikukood,
            lapse_nimi::TEXT                       AS lapse_nimi,
            lapse_isikukood::TEXT                  AS lapse_isikukood,
            qry.aasta::INTEGER                     AS aasta,
            qry.rekvid::INTEGER                    AS rekvid,
            CASE
                WHEN coalesce((r.properties ->> 'liik')::TEXT, '') = 'LASTEAED' THEN 1
                ELSE 3 END::INTEGER                AS liik,
            string_agg(DISTINCT doc_arv_id, ',')   AS docs_arv_ids,
            string_agg(DISTINCT doc_tasud_id, ',') AS docs_tasu_ids,
            string_agg(doc_tagastused_id, ',')     AS doc_tagastused_ids

        FROM
            (
                WITH
                    rekv_ids AS (
                                    SELECT
                                        rekv_id
                                    FROM
                                        get_asutuse_struktuur(l_rekvid)
                                ),
                    arved AS (
                                    SELECT
                                        a.parentid    AS id,
                                        sum(a1.summa) AS a1_summa,
                                        a.summa       AS a_kokku
                                    FROM
                                        docs.arv                         a
                                            INNER JOIN docs.arv1         a1 ON a.id = a1.parentid
                                            INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid,
                                                                         params
                                    WHERE
                                          a.rekvid IN (
                                                          SELECT
                                                              rekv_id
                                                          FROM
                                                              rekv_ids
                                                      )
                                      AND a.tasud IS NOT NULL
                                      AND YEAR(a.tasud) >= params.aasta
                                      AND COALESCE((n.properties ->> 'kas_inf3')::BOOLEAN, FALSE)
                                      AND COALESCE(a.properties ->> 'tyyp', '') <> 'ETTEMAKS'
                                      AND a.liik = 0
                                      AND a1.summa <> 0
                                      AND (CASE WHEN a.summa > 0 THEN (a.jaak < a.summa) ELSE TRUE END) -- без неоплаченных счетов
                                      AND year(a.kpv) <= l_aasta::INTEGER
                                    GROUP BY
                                        a.parentid,
                                        a.summa
                                ),
                    lapsed AS (
                                    SELECT DISTINCT
                                        l.parentid AS laps_id,
                                        a.rekvid
                                    FROM
                                        lapsed.liidestamine l,
                                        docs.arv            a,
                                        docs.arv1           a1,
                                        libs.nomenklatuur   n
                                    WHERE
                                          a.parentid = l.docid
                                      AND a.id = a1.parentid
                                      AND n.id = a1.nomid
                                      AND COALESCE((n.properties ->> 'kas_inf3')::BOOLEAN, FALSE)
                                      AND a1.summa <> 0
                                      AND a.rekvid IN (
                                                          SELECT
                                                              rekv_id
                                                          FROM
                                                              rekv_ids
                                                      )
                                ),

                    tasud AS (
                                    SELECT DISTINCT
                                        asutusid,
                                        M.parentid AS tasu_id
                                    FROM
                                        docs.mk                            M
                                            INNER JOIN docs.mk1            m1 ON M.id = m1.parentid
                                            INNER JOIN lapsed.liidestamine l ON l.docid = M.parentid
                                            INNER JOIN lapsed ON lapsed.laps_id = l.parentid AND lapsed.rekvid = m.rekvid,
                                                                           params
                                    WHERE
                                          M.rekvid IN (
                                                          SELECT
                                                              rekv_id
                                                          FROM
                                                              rekv_ids
                                                      )
                                      AND YEAR(M.maksepaev) = params.aasta
--                             AND m.opt = 2 -- только поступления
--                             AND m1.summa > 0 -- включая минуса (переносы)
                                )
                SELECT
                    AT.rekvid                                             AS rekvid,
                    l.nimi                                                AS lapse_nimi,
                    l.isikukood                                           AS lapse_isikukood,
                    (l.properties ->> 'inf3_kpv')::date                   as inf3_kpv,
                    round((arved.a1_summa / arved.a_kokku) * AT.summa, 2) AS summa,
                    tasud.asutusid                                        AS asutusId,
                    YEAR(AT.kpv)                                          AS aasta,
                    AT.doc_arv_id::TEXT                                   AS doc_arv_id,
                    at.doc_tasu_id::TEXT                                  AS doc_tasud_id,
                    ''::TEXT                                              AS doc_tagastused_id
                FROM
                    docs.arvtasu                       AT
                        INNER JOIN lapsed.liidestamine ld
                                   ON ld.docid = AT.doc_tasu_id
                        INNER JOIN lapsed.laps         l ON l.id = ld.parentid
                        INNER JOIN arved ON arved.id = AT.doc_arv_id
                        INNER JOIN tasud ON tasud.tasu_id = AT.doc_tasu_id
                WHERE
                      AT.rekvid IN (
                                       SELECT
                                           rekv_id
                                       FROM
                                           rekv_ids
                                   )
                  AND AT.status <> 3
            )                          qry
                INNER JOIN ou.rekv     r ON r.id = qry.rekvid
                INNER JOIN libs.asutus a ON a.id = qry.asutusId,
                                       params
        WHERE
            qry.summa IS NOT NULL
          AND len(ltrim(rtrim(a.regkood))) >= 11 -- только частники
          AND (params.aasta <= coalesce(year(qry.inf3_kpv::date),params.aasta - 1)  or
               extract('year' FROM
                       age(make_date(params.aasta, 01, 01), palk.get_sunnipaev(qry.lapse_isikukood))) <
               18) -- только до 18 лет или если указана дата в карточке ребенка
        GROUP BY
            lapse_isikukood,
            lapse_nimi,
            a.nimetus,
            a.regkood,
            qry.aasta,
            qry.rekvid,
            r.properties ->> 'liik'
    )            report,
    asutuse_rekv r,
    params
WHERE
      summa <> 0
  AND left(lapse_isikukood, 1) NOT IN ('9') -- А. Варгунин, 01.02.2024
  AND maksja_isikukood NOT IN (
    '19701028-00172') -- А. Варгунин, 01.02.2024
--  AND (left(lapse_isikukood, 1) IN ('3', '4', '5', '6') AND len(lapse_isikukood) = 11)
    ;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, TEXT) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, TEXT) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.inf3(INTEGER, TEXT) TO arvestaja;


/*

select * from (
                  SELECT *
                  FROM lapsed.inf3(66, '2025')
              ) qry
where  lapse_isikukood ilike '%50305170213%'


-- execution: 12 s 27 ms, fetching: 185 ms)
-- summa;maksja_nimi;maksja_isikukood
-- 276.92;Denisova Olesja;48601122264
-- 26;Denisova Olesja;48601122264

(execution: 12 s 973 ms, fetching: 289 ms)

select * from libs.asutus where regkood = '48101293714'

*/
