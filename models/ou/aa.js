module.exports = {
    selectAsLibs: `SELECT
              id,
              trim(arve)::varchar(20)    AS kood,
              trim(nimetus)::varchar(120) AS nimetus,
              aa.default_,
              aa.konto,
              aa.tp
            FROM ou.aa aa
            WHERE parentid = $1
                  AND kassa = 1
            ORDER BY default_ DESC`,
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
