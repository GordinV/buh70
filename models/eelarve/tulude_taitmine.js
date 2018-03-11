'use strict';

const TuludeTaitmine = {
    select: [],
    grid:
        {
            gridConfiguration: [
                {id: "id", name: "id", width: "25px"},
                {id: "kpv", name: "Kuupäev", width: "100px"},
                {id: "number", name: "Number", width: "100px"},
                {id: "asutus", name: "Maksja", width: "200px"},
                {id: "asutusid", name: "asutusid", width: "200px", show: false},
                {id: "nomid", name: "nomid", width: "200px", show: false},
                {id: "aa", name: "Arveldus arve", width: "100px"},
                {id: "viitenr", name: "Viite number", width: "100px"},
                {id: "maksepaev", name: "Maksepäev", width: "100px"},
                {id: "created", name: "Lisatud", width: "150px"},
                {id: "lastupdate", name: "Viimane parandus", width: "150px"},
                {id: "status", name: "Status", width: "100px"}
            ],
            sqlString: `SELECT
                          d.*
                        FROM get_eelarve_taitmine(false, $1, false, $2) as d`, //  is_kassa BOOLEAN, $1 is_arhiiv BOOLEAN, is_kulud BOOLEAN, $2 params JSON
            params: '',
            alias: 'curTuluTaitm'
        }
    ,
    returnData: {},
    saveDoc: null,
    deleteDoc: null,
    requiredFields: []
};

module.exports = TuludeTaitmine;
