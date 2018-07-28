'use strict';

const Saadetud = {
    select: [],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "kpv", name: "Kpv", width: "100px"},
            {id: "summa", name: "Summa", width: "100px"},
            {id: "tahtaeg", name: "Tähtaeg", width: "100px"},
            {id: "tyyp", name: "Tüüp", width: "100px"},
            {id: "volg", name: "Võlg", width: "100px"},
            {id: "lausend", name: "Lausend", width: "100px"},
            {id: "parandus", name: "Parandus", width: "100px"},
            {id: "status", name: "Staatus", width: "100px"}
        ],
        sqlString: `SELECT
                          d.*
                        FROM cur_saadetud d
                        WHERE d.rekvId = $1
                              AND coalesce(docs.usersRigths(d.id, 'select', $2), TRUE)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curSaadetud'
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

module.exports = Saadetud;
