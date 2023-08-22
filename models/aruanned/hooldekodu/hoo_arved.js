module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "asutus", name: "Asutud", width: "20%"},
        ],
        sqlString: `SELECT qry.*,
                           $2        AS user_id
                    FROM hooldekodu.hoo_arved($3::DATE, $4:: DATE, $1::INTEGER, $5::INTEGER) qry
                    ORDER BY qry.number        `,
        params: '',
        alias: 'hoo_arved'
    },
};
