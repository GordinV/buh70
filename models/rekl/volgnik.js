'use strict';

const Volgnik = {
    select: [],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "regkood", name: "Kood", width: "200px"},
            {id: "nimetus", name: "Nimetus", width: "400px"},
            {id: "jaak", name: "Jääk", width: "100px"},
            {id: "volg", name: "Võlg", width: "100px"},
            {id: "intress", name: "Intress", width: "100px"}
        ],
        sqlString: `SELECT $2 as user_id,
                          d.*
                        FROM cur_volgnik d
                        WHERE d.rekvId = $1`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curVolgnik'
    },
    returnData: null,
    saveDoc: null,
    deleteDoc: null, // $1 - userId, $2 - docId
    requiredFields: [],
    executeCommand: {
        command: `select * from sp_execute_task($1::integer, $2::JSON, $3::TEXT )`, //$1- userId, $2 - params, $3 - task
        type:'sql',
        alias:'executeTask'
    },


};

module.exports = Volgnik;
