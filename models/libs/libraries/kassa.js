module.exports = {
    selectAsLibs: `SELECT id,
                          trim(arve)    AS kood,
                          trim(nimetus) AS name,
                          NULL::DATE    AS valid
                   FROM ou.aa
                   WHERE parentid = 1
                     AND kassa = 1
                   ORDER BY default_ DESC`
};
