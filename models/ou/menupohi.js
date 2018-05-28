module.exports = {
    selectAsLibs: `SELECT menu.*
                        FROM ou.cur_menu menu
                          INNER JOIN ou.get_menu($1 :: TEXT [], $2 :: TEXT []) QRY_menu ON qry_menu.id = menu.id
                        ORDER BY idx`, // $1 - modules array, like '{"EELARVE","RAAMA"}', $2 array, like '{"KASUTAJA","ADMIN"}'
    select: [{
        sql:null,
        alias: null
    }],
    grid: {
        sqlString: null,
        alias: null
    },
    returnData: null,
    saveDoc: null,
    deleteDoc: null,
    requiredFields: null
};
