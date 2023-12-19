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
        sqlString: `SELECT k.*, 
                    r.nimetus as asutus
                    FROM eelarve.lisa_1_5_kontrol k
                             INNER JOIN ou.rekv r ON r.id = k.rekv_id
                    WHERE kpv = get_last_day($1::DATE)
                      and rekv_id <> 9
                      AND rekv_id IN (SELECT rekv_id
                                      FROM get_asutuse_struktuur($2::INTEGER))
                      AND rekv_id = (CASE
                                         WHEN $3::INTEGER = 1
                                             THEN rekv_id
                                         ELSE $2::INTEGER END)
                    ORDER BY CASE WHEN r.id = 63 THEN 0 WHEN parentid = 63 THEN 1 ELSE 2 END,
                             r.id::TEXT || '-' || r.parentid ::TEXT, k.idx,
                             CASE WHEN k.nimetus = 'PÕHITEGEVUSE TULUD KOKKU' THEN '1' ELSE k.nimetus END`,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'lisa1_lisa5_kontrol'
    },
    executeCommand: {
        command: `select error_code, result, error_message from eelarve.koosta_lisa_1_5_kontrol($1::integer, $2::date)`, //$1- userId, $2 - date
        type: 'sql',
        alias: 'koosta_lisa1_lisa5_kontrol'
    },

};
