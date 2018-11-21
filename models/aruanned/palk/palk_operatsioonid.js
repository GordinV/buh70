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
        sqlString: `SELECT d.palk_liik :: VARCHAR(20) AS liik, nimetus, kpv, isik, summa, osakond, kood, isikid,osakondid
                    FROM palk.cur_palkoper d
                    WHERE d.rekvId = $3
                      AND d.kpv >= $1
                      AND d.kpv <= $2`,     //  $1 - kpv1, $2 - kpv2, $3 - rekvid
        params: '',
        alias: 'palk_oper'
    }
};
