module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "isikukood", name: "Isikukood", width: "20%"},
            {id: "nimi", name: "Lapse nimi", width: "40%"},
            {id: "age", name: "Sünniaeg", width: "10%", type: "date", interval: true},
            {id: "age_27", name: "27 aastane", width: "10%", type: "date", interval: true},
            {id: "asutus", name: "Asutud", width: "20%"},
        ],
        sqlString: `SELECT qry.*,
                           a.nimetus AS isik,
                           a.regkood AS isikukood,
                           $2        AS user_id
                    FROM hooldekodu.hoo_kaibeandmik($3::DATE, $4:: DATE, $1::INTEGER, $5::INTEGER) qry
                             LEFT OUTER JOIN libs.asutus a ON a.id = qry.isik_id
                    ORDER BY a.nimetus        `,
        params: '',
        alias: 'hoo_kaibeandmik'
    },
};
