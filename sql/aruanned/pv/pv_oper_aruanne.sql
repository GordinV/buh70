DROP FUNCTION IF EXISTS docs.pv_oper_aruanne(DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.pv_oper_aruanne(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.pv_oper_aruanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
                                                l_kond INTEGER DEFAULT NULL)
    RETURNS TABLE
            (
                pvnimetus   VARCHAR(254),
                pvkood      VARCHAR(20),
                kood        VARCHAR(20),
                nimetus     varchar(254),
                korr_konto  VARCHAR(20),
                kood3       VARCHAR(20),
                deebet      NUMERIC(14, 2),
                kreedit     NUMERIC(14, 2),
                kpv         DATE,
                grupp       VARCHAR(254),
                grupp_id    INTEGER,
                rekv_id     INTEGER,
                konto       VARCHAR(20),
                vastisik_id INTEGER
            )
AS
$BODY$
WITH
    rekv_ids AS (
                    SELECT
                        rekv_id
                    FROM
                        get_asutuse_struktuur(l_rekvid)
                    WHERE
                        rekv_id = CASE
                                      WHEN l_kond = 1
                                          THEN rekv_id
                                      ELSE l_rekvid END
    )
SELECT
    p.nimetus::VARCHAR(254)                         AS pvnimetus,
    po.kood::VARCHAR(20)                            as pvkood,
    po.kood::VARCHAR(20)                            as kood,
    p.nimetus::VARCHAR(254)                         as nimetus,
    po.konto::VARCHAR(20)                           as korr_konto,
    po.kood3::VARCHAR(20)                           as kood3,
    case
        when po.liik in (1, 5) then po.summa
        when po.liik in (3) and coalesce(po.kood3, '') not in ('12') then po.summa
        else 0::numeric(14, 2)
        end::numeric(14, 2)                         as deebet,
    case
        when po.liik in (4) then po.summa
        when po.liik in (2) and coalesce(po.kood3, '') not in ('12') then po.summa
        when po.liik in (2) and coalesce(po.kood3, '') = '12' then -1 * po.summa
        when po.liik in (3) and coalesce(po.kood3, '') = '12' then -1 * po.summa
        else 0::numeric(14, 2) end                  as kreedit,
    po.kpv,
    g.nimetus::VARCHAR(254)                         as grupp,
    g.id                                            as grupp_id,
    p.rekvid                                        as rekv_id,
    (p.properties::jsonb ->> 'konto')::varchar(20)  as konto,
    (p.properties::JSONB ->> 'vastisikid')::INTEGER AS vastisik_id
FROM
    libs.library                p
        INNER JOIN cur_pv_oper  po ON p.id = po.pv_kaart_id
        INNER JOIN libs.library g ON g.id = (p.properties :: JSONB ->> 'gruppid') :: INTEGER
WHERE
      p.library = 'POHIVARA'
  AND p.status not in (3)
  and p.rekvid = l_rekvid
  and po.kpv >= l_kpv1
  and po.kpv <= l_kpv2;


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.pv_oper_aruanne( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.pv_oper_aruanne( DATE, DATE, INTEGER, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.pv_oper_aruanne( DATE, DATE, INTEGER , INTEGER) TO dbkasutaja;


/*
SELECT *
FROM docs.pv_oper_aruanne( '2024-01-01'::date,'2024-12-31':: DATE, 28 , 0::INTEGER)

*/