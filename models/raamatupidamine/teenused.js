'use strict';
//var co = require('co');
let now = new Date();
const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');

const Teenused = {
    selectAsLibs: null,
    select: [{
        sql: null,
        alias: null
    }],
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
        sqlString: `select * from cur_teenused a 
         where a.rekvId = $1 
         and docs.usersRigths(a.id, 'select', $2)
         order by a.lastupdate desc`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curTeenused'
    },
    returnData: null,
    saveDoc: null,
    deleteDoc: `select error_code, result, error_message from docs.sp_delete_arv($1, $2)`, // $1 - userId, $2 - docId
    executeCommand: {
        command: `select docs.sp_kooperi_arv(?gnUser, ?tnId) as result`,
        type: 'sql',
        alias: 'kooperiArv'
    },
    executeTask: function (task, docId, userId) {
        // выполнит задачу, переданную в параметре

        let executeTask = task;
        if (executeTask.length == 0) {
            executeTask = ['start'];
        }

        let taskFunction = eval(executeTask[0]);
        return taskFunction(docId, userId, this);
    },
    requiredFields: null
};

module.exports = Teenused;

