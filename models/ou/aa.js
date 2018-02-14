module.exports = {
    selectAsLibs: `SELECT
              id,
              trim(arve)::varchar(20)    AS kood,
              trim(nimetus)::varchar(120) AS nimetus
            FROM ou.aa aa
            WHERE (parentid = $1 OR aa.parentid IS NULL)
                  AND pank = 1
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
