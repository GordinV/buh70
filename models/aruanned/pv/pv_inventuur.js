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
        sqlString: `WITH rekv_ids AS (
                        SELECT rekv_id
                        FROM get_asutuse_struktuur($2)
                        WHERE rekv_id = CASE
                                            WHEN $3 = 1
                                                THEN rekv_id
                                            ELSE $2 END)
                    SELECT
                      coalesce((SELECT sum(summa)
                                FROM docs.pv_oper po
                                WHERE po.pv_kaart_id = p.id 
                                AND po.kpv <= $1::DATE
                                AND liik = 2), 0) + p.algkulum AS arv_kulum,
                      coalesce((SELECT sum(summa)
                                FROM docs.pv_oper po
                                WHERE po.pv_kaart_id = p.id AND liik IN (1, 3)), 0)        AS soetmaks,
                      (SELECT eluiga FROM libs.get_pv_kaart_jaak(p.id::INTEGER, $1::DATE))::NUMERIC(12,4) AS eluiga,
                      p.*,
                      r.nimetus as asutus
                    FROM cur_pohivara p
                    inner join ou.rekv r on r.id = p.rekvid
                    WHERE (p.mahakantud IS NULL or p.mahakantud > $1)
                      AND p.rekvid IN (SELECT rekv_id FROM rekv_ids)`,
        // $1 - kpv, $2 - rekvid , $3 - kond
        params: '',
        alias: 'pv_inventuur_report'
    }
};
