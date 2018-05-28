module.exports = {
    selectAsLibs: `select * from com_objekt l where (l.rekvId = $1 or l.rekvid is null) order by kood`,
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "20%"},
            {id: "nimetus", name: "Nimetus", width: "40%"},
            {id: "asutus", name: "Omanik", width: "40%"}
        ],
        sqlString: `select $2::integer as userId,
             o.*
            FROM cur_objekt o 
            WHERE o.rekvid = $1::integer`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curObjekt'
    }

};