DROP FUNCTION IF EXISTS docs.kond_journal(INTEGER, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.kond_journal(l_rekvid INTEGER,
                                             l_kond INTEGER DEFAULT 0,
                                             l_params JSONB DEFAULT NULL::JSONB)
    RETURNS TABLE (
        created    TEXT,
        lastupdate TEXT,
        status     VARCHAR(20),
        number     INTEGER,
        id         INTEGER,
        kpv        DATE,
        journalid  INTEGER,
        rekvId     INTEGER,
        asutusid   INTEGER,
        kuu        INTEGER,
        aasta      INTEGER,
        selg       VARCHAR(254),
        dok        VARCHAR(254),
        objekt     VARCHAR(254),
        muud       VARCHAR(254),
        deebet     VARCHAR(20),
        lisa_d     VARCHAR(20),
        kreedit    VARCHAR(20),
        lisa_k     VARCHAR(20),
        summa      NUMERIC(12, 2),
        valsumma   NUMERIC(12, 2),
        valuuta    CHAR(3),
        kuurs      NUMERIC(12, 6),
        kood1      VARCHAR(20),
        kood2      VARCHAR(20),
        kood3      VARCHAR(20),
        kood4      VARCHAR(20),
        kood5      VARCHAR(20),
        proj       VARCHAR(20),
        asutus     VARCHAR(254),
        tunnus     VARCHAR(20),
        kasutaja   VARCHAR(254),
        rekvAsutus VARCHAR(254)
    )
AS
$BODY$

WITH params AS (
    SELECT l_params ->> 'proj'              AS proj,
           l_params ->> 'tunnus'            AS tunnus,
           l_params ->> 'uritus'            AS uritus,
           l_params ->> 'objekt'            AS objekt,
           l_params ->> 'kood1'             AS kood1,
           l_params ->> 'kood2'             AS kood2,
           l_params ->> 'kood3'             AS kood3,
           l_params ->> 'kood4'             AS kood4,
           l_params ->> 'kood5'             AS kood5,
           l_params ->> 'selg'              AS selg,
           l_params ->> 'deebet'            AS deebet,
           l_params ->> 'kreedit'           AS kreedit,
           l_params ->> 'tpd'               AS tpd,
           l_params ->> 'tpk'               AS tpk,
           l_params ->> 'asutus'            AS asutus,
           l_params ->> 'dok'               AS dok,
           l_params ->> 'kasutaja'          AS kasutaja,
           l_params ->> 'muud'              AS muud,
           (l_params ->> 'kpv1')::DATE      AS kpv1,
           (l_params ->> 'kpv2')::DATE      AS kpv2,
           (l_params ->> 'summa1')::NUMERIC AS summa1,
           (l_params ->> 'summa2')::NUMERIC AS summa2
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
     doc_type AS (
         SELECT id
         FROM libs.library WHERE library.library = 'DOK' AND kood IN ('JOURNAL')
     )
    SELECT
     j.created:: TEXT,
     j.lastupdate:: TEXT,
     j.status:: VARCHAR(20),
     j.number:: INTEGER,
     j.id:: INTEGER,
     j.kpv:: DATE,
     j.journalid:: INTEGER,
     j.rekvId:: INTEGER,
     j.asutusid:: INTEGER,
     j.kuu:: INTEGER,
     j.aasta:: INTEGER,
     j.selg:: VARCHAR(254),
     j.dok:: VARCHAR(254),
     j.objekt:: VARCHAR(254),
     j.muud:: VARCHAR(254),
     j.deebet:: VARCHAR(20),
     j.lisa_d:: VARCHAR(20),
     j.kreedit:: VARCHAR(20),
     j.lisa_k:: VARCHAR(20),
     j.summa:: NUMERIC(12, 2),
     j.valsumma:: NUMERIC(12, 2),
     j.valuuta:: CHAR(3),
     j.kuurs:: NUMERIC(12, 6),
     j.kood1:: VARCHAR(20),
     j.kood2:: VARCHAR(20),
     j.kood3:: VARCHAR(20),
     j.kood4:: VARCHAR(20),
     j.kood5:: VARCHAR(20),
     j.proj:: VARCHAR(20),
     j.asutus:: VARCHAR(254),
     j.tunnus:: VARCHAR(20),
     j.kasutaja:: VARCHAR(254),
     j.rekvAsutus:: VARCHAR(254)
    FROM
     (SELECT to_char(d.created, 'DD.MM.YYYY HH:MI')                                                 AS created,
             to_char(d.lastupdate, 'DD.MM.YYYY HH:MI')                                              AS lastupdate,
             s.nimetus                                                                              AS status,
             d.id                                                                                   AS id,
             j.kpv                                                                                  AS kpv,
             jid.number,
             j.id                                                                                   AS journalid,
             j.rekvId,
             j.asutusid,
             month(j.kpv) :: INTEGER                                                                AS kuu,
             year(j.kpv) :: INTEGER                                                                 AS aasta,
             regexp_replace(regexp_replace(coalesce(j.selg, ''), '["/]', ' ', 'g'), '/n/r', '',
                            'g') :: VARCHAR(254)                                                    AS selg,
             COALESCE(j.dok, '') :: VARCHAR(50)                                                     AS dok,
             COALESCE(j1.objekt, '') :: VARCHAR(20)                                                 AS objekt,
             regexp_replace(regexp_replace(replace(coalesce(j.muud, ''), chr(13), ' '), '["/]', ' ', 'g'),
                            '/n/r', '',
                            'g') :: VARCHAR(254)                                                    AS muud,
             j1.deebet,
             COALESCE(j1.lisa_d, '') :: VARCHAR(20)                                                 AS lisa_d,
             j1.kreedit,
             COALESCE(j1.lisa_k, '') :: VARCHAR(20)                                                 AS lisa_k,
             j1.summa,
             j1.summa                                                                               AS valsumma,
             'EUR' :: VARCHAR(20)                                                                   AS valuuta,
             1 :: NUMERIC(12, 6)                                                                    AS kuurs,
             COALESCE(j1.kood1, '') :: VARCHAR(20)                                                  AS kood1,
             COALESCE(j1.kood2, '') :: VARCHAR(20)                                                  AS kood2,
             COALESCE(j1.kood3, '') :: VARCHAR(20)                                                  AS kood3,
             COALESCE(j1.kood4, '') :: VARCHAR(20)                                                  AS kood4,
             COALESCE(j1.kood5, '') :: VARCHAR(20)                                                  AS kood5,
             COALESCE(j1.proj, '') :: VARCHAR(20)                                                   AS proj,
             COALESCE(ltrim(rtrim(a.nimetus)) || ' ' || ltrim(rtrim(a.omvorm)), '') :: VARCHAR(120) AS asutus,
             COALESCE(j1.tunnus, '') :: VARCHAR(20)                                                 AS tunnus,
             COALESCE(u.ametnik, '') :: VARCHAR(120)                                                AS kasutaja,
             ltrim(rtrim(r.nimetus)):: VARCHAR(254)                                                 AS rekvAsutus
      FROM docs.journal j
               LEFT JOIN libs.asutus a ON a.id = j.asutusid
               LEFT OUTER JOIN ou.userid u ON u.id = j.userid,
           doc_type,
           docs.doc D,
           docs.journal1 j1,
           docs.journalid jid,
           ou.rekv r,
           libs.library S
          WHERE
           D.status <> 3
               AND d.doc_type_id = doc_type.id
               AND j.id = jid.journalid
               AND j.id = j1.parentid
               AND D.id = j.parentid
               AND r.id = j.rekvid
               AND S.kood = D.status :: TEXT
               AND S.library = 'STATUS'
               AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
     ) j,
     params
    WHERE
     (params.kpv1 IS NULL OR j.kpv >= params.kpv1)
         AND (params.kpv2 IS NULL OR j.kpv <= params.kpv2)
         AND (params.proj IS NULL OR j.proj ilike params.proj || '%')
         AND (params.tunnus IS NULL OR j.tunnus ilike params.tunnus || '%')
         AND (params.uritus IS NULL OR j.kood4 ilike params.uritus || '%')
         AND (params.kood1 IS NULL OR j.kood1 ilike params.kood1 || '%')
         AND (params.kood2 IS NULL OR j.kood1 ilike params.kood2 || '%')
         AND (params.kood3 IS NULL OR j.kood1 ilike params.kood3 || '%')
         AND (params.kood5 IS NULL OR j.kood1 ilike params.kood5 || '%')
    LIMIT
     10 ;

/*
 */

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION docs.kond_journal( INTEGER, INTEGER, JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kond_journal( INTEGER, INTEGER, JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kond_journal( INTEGER, INTEGER, JSONB) TO dbkasutaja;

SELECT  *
FROM docs.kond_journal(63, 0, '{"kpv1":"2023-01-01", "kpv2":"2023-01-31", "tunnus": "OSAK", "kood1":"01112","kood5":"55"}'::jsonb)


/*



SELECT  *
FROM docs.kond_journal(63, 0, '{"kpv1":"2023-01-01", "kpv2":"2023-01-31"}'::jsonb)

*/

