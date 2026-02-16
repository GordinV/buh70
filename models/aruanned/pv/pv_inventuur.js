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
        sqlString: `        WITH
                                params as (
                                              select
                                                  $1::date    as kpv,
                                                  $2::integer as rekvid,
                                                  $3::integer as kond
                                          ),
                                rekv_ids AS (
                                              SELECT
                                                  rekv_id
                                              FROM
                                                  params p, get_asutuse_struktuur(p.rekvid)
                                              WHERE
                                                  rekv_id = CASE
                                                                WHEN p.kond = 1
                                                                    THEN rekv_id
                                                                ELSE p.rekvid END
                                          ),
                                cur_pv as (
                                              SELECT
                                                  l.id,
                                                  l.kood,
                                                  l.nimetus,
                                                  l.rekvid,
                                                  coalesce(a.nimetus, '') :: VARCHAR(254)                                                AS vastisik,
                                                  (l.properties :: JSONB ->> 'vastisikid') :: INTEGER                                    AS vastisikid,
                                                  coalesce((l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 2), 0):: NUMERIC(12, 2) AS algkulum,
                                                  (l.properties :: JSONB ->> 'kulum') :: NUMERIC(12, 2)                                  AS kulum,
                                                  (l.properties :: JSONB ->> 'soetmaks') :: NUMERIC(12, 2)                               AS soetmaks,
                                                  coalesce((l.properties :: JSONB ->> 'parhind') :: NUMERIC(12, 2),
                                                           (l.properties :: JSONB ->> 'soetmaks') :: NUMERIC(12, 2))                     AS parhind,
                                                  coalesce((l.properties :: JSONB ->> 'kulum_kokku') :: NUMERIC(12, 2),
                                                           0) :: NUMERIC(12, 2)                                                          AS kulum_kokku,
                                                  coalesce((l.properties :: JSONB ->> 'jaak') :: NUMERIC(12, 2), 0) :: NUMERIC(12, 2)    AS jaak,
                                                  coalesce((l.properties :: JSONB ->> 'soetkpv') :: DATE,
                                                           date(1900, 01, 01))                                                           AS soetkpv,
                                                  coalesce((l.properties :: JSONB ->> 'konto'), '') :: VARCHAR(20)                       AS konto,
                                                  coalesce((l.properties :: JSONB ->> 'tunnus'), '') :: VARCHAR(20)                      AS tunnus,
                                                  (l.properties :: JSONB ->> 'mahakantud') :: DATE                                       AS mahakantud,
                                                  coalesce((l.properties :: JSONB ->> 'rentnik'), '') :: VARCHAR(120)                    AS rentnik,
                                                  (l.properties :: JSONB ->> 'liik') :: VARCHAR(120)                                     AS liik,
                                                  coalesce((l.properties :: JSONB ->> 'selg'), '') :: VARCHAR(120)                       AS selgitus,
                                                  (l.properties :: JSONB ->> 'parent_id') :: INTEGER                                     AS parent_id,
                                                  coalesce((l.properties :: JSONB ->> 'pindala') :: NUMERIC(12, 4), 0):: NUMERIC(12, 4)  AS pindala,
                                                  libs.get_pv_kaart_grupp(l.id, p.kpv)                                                   AS gruppid,
                                                  coalesce((l.properties :: JSONB ->> 'aadress'), ''):: VARCHAR(254)                     AS aadress,
                                                  l.status
                                              FROM
                                                  params                    p,
                                                  libs.library              l
                                                      LEFT JOIN libs.asutus a
                                                                ON (l.properties :: JSONB -> 'vastisikid') = to_jsonb(a.id)
                                              WHERE
                                                    l.status <> 3
                                                AND l.rekvid IN (
                                                                    SELECT
                                                                        rekv_id
                                                                    FROM
                                                                        rekv_ids
                                                                )
                                          )
                            SELECT
                                coalesce((
                                             SELECT
                                                 sum(summa)
                                             FROM
                                                 docs.pv_oper po
                                             WHERE
                                                   po.pv_kaart_id = pv.id
                                               AND po.kpv <= p.kpv::DATE
                                               AND liik = 2
                                         ), 0) + pv.algkulum                             AS arv_kulum,
                                coalesce((
                                             SELECT
                                                 sum(summa)
                                             FROM
                                                 docs.pv_oper po
                                             WHERE
                                                   po.pv_kaart_id = pv.id
                                               AND liik IN (1, 3)
                                               AND po.kpv <= p.kpv::DATE
                                         ), 0)                                           AS soetmaks,
                                (
                                    SELECT eluiga FROM libs.get_pv_kaart_jaak(pv.id::INTEGER, p.kpv::DATE)
                                )::NUMERIC(12, 4)                                        AS eluiga,
                                pv.id,
                                libs.get_pv_kaart_konto(pv.id, p.kpv::date)::varchar(20) as konto,
                                pv.tunnus,
                                pv.rekvid,
                                pv.kulum,
                                pv.nimetus,
                                pv.kood,
                                pv.liik,
                                pv.soetkpv,
                                pv.jaak,
                                pv.algkulum,
                                pv.aadress,
                                grupp.nimetus                                            as grupp,
                                pv.gruppid,
                                pv.kulum_kokku,
                                pv.mahakantud,
                                pv.vastisik,
                                pv.vastisikid,
                                pv.rentnik,
                                r.nimetus                                                as asutus
                            FROM
                                params                      p,
                                cur_pv                      pv
                                    JOIN       libs.library grupp ON pv.gruppid = grupp.id
                                    inner join ou.rekv      r on r.id = pv.rekvid
                            WHERE
                                  (pv.mahakantud IS NULL or pv.mahakantud > p.kpv)
                              and pv.soetkpv <= p.kpv::DATE
        `,
        // $1 - kpv, $2 - rekvid , $3 - kond
        params: '',
        alias: 'pv_inventuur_report'
    }
};
