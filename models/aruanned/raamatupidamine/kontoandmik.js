module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px", show: false},
            {id: "number", name: "Number", width: "100px"},
            {id: "kpv", name: "Kuupaev", width: "100px"},
            {id: "summa", name: "Summa", width: "75px"},
            {id: "tahtaeg", name: "Tähtaeg", width: "100px"},
            {id: "jaak", name: "Jääk", width: "100px"},
            {id: "tasud", name: "Tasud", width: "100px"},
            {id: "asutus", name: "Asutus", width: "200px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Staatus", width: "100px"},
        ],
        sqlString: `SELECT qry.*, l.nimetus, 
                        (qry.alg_saldo + db_kokku - kr_kokku) as lopp_saldo 
                        FROM docs.kontoandmik($1::text, $2::date, $3::date, $4::integer, $5::text, $6::JSONB) qry
                        inner join com_kontoplaan l on l.kood = qry.konto
                        `,     //  $1 конто $2 - kpv1, $3 - kpv2, $4 - rekvid (svod), $4 - tunnus,  $6 - доп. параметры
        params: '',
        alias: 'kontoandmik_report'
    }
};
