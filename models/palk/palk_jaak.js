'use strict';
const PalkJaak = {
    select: [],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "kpv", name: "Kuupäev", width: "100px"},
            {id: "summa", name: "Summa", width: "100px"},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "liik", name: "Liik", width: "100px"},
            {id: "journalid", name: "Lausend", width: "100px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Status", width: "100px"}
        ],
        sqlString: `SELECT
                          p.*,
                          $2 as user_id
                        FROM palk.cur_palk_jaak p
                        WHERE p.rekvId in (select rekv_id from get_asutuse_struktuur($1))`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPalkJaak'
    },
    returnData: {
        row: {},
        relations: []
    },
    saveDoc: null,
    deleteDoc: null,
    requiredFields: [],
    executeCommand: {
        command: `select palk.sp_calc_palgajaak($1::integer, $2::JSON)::integer as result`, //$1- userId, $2 - params
        type:'sql',
        alias:'executeTask'
    },

};

module.exports = PalkJaak;
