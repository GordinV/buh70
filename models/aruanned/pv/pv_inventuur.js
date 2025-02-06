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
                                         ), 0) + pv.algkulum                AS arv_kulum,
                                coalesce((
                                             SELECT
                                                 sum(summa)
                                             FROM
                                                 docs.pv_oper po
                                             WHERE
                                                   po.pv_kaart_id = pv.id
                                               AND liik IN (1, 3)
                                               AND po.kpv <= p.kpv::DATE
                                         ), 0)                              AS soetmaks,
                                (
                                    SELECT eluiga FROM libs.get_pv_kaart_jaak(pv.id::INTEGER, p.kpv::DATE)
                                )::NUMERIC(12, 4)                           AS eluiga,
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
                                pv.grupp,
                                pv.gruppid,
                                pv.kulum_kokku,
                                pv.mahakantud,
                                pv.vastisik,
                                pv.vastisikid,
                                pv.rentnik,
                                r.nimetus                                   as asutus
                            FROM
                                params                 p,
                                cur_pohivara           pv
                                    inner join ou.rekv r on r.id = pv.rekvid
                            WHERE
                                  (pv.mahakantud IS NULL or pv.mahakantud > p.kpv)
                              and pv.soetkpv <= p.kpv::DATE
                              AND pv.rekvid IN (
                                                   SELECT
                                                       rekv_id
                                                   FROM
                                                       rekv_ids
                                               )
        `,
        // $1 - kpv, $2 - rekvid , $3 - kond
        params: '',
        alias: 'pv_inventuur_report'
    }
};
