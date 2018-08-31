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
        sqlString: `SELECT
                      p.kood          AS pvkood,
                      p.nimetus       AS pvnimetus,
                      po.kood,
                      p.nimetus,
                      case when po.liik in (1, 3, 5) then po.summa else 0::numeric(14,2) end as deebet,
                      case when po.liik in (2, 4) then po.summa else 0::numeric(14,2) end as kreedit,
                      po.kpv,
                      g.nimetus as grupp,
                      g.id as grupp_id,
                      p.rekvid as rekv_id,
                      p.properties::jsonb->>'konto' as konto
                    FROM libs.library p
                      INNER JOIN cur_pv_oper po ON p.id = po.pv_kaart_id
                      INNER JOIN libs.library g ON g.id = (p.properties :: JSONB ->> 'gruppid') :: INTEGER
                    WHERE p.library = 'POHIVARA'
                      and p.rekvid = $3
                      and po.kpv >= $1
                      and po.kpv <= $2`,     // $1 - kpv1, $2 - kpv2, $3- rekvid (svod)
        params: '',
        alias: 'pv_oper_aruanne_report'
    }
};
