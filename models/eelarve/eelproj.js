'use strict';

const EelProj = {
    select: [
        {
            sql: `SELECT
                      e.id,
                      $2                                                  AS userid,
                      e.rekvid,
                      e.aasta,
                      e.kuu,
                      e.kinnitaja,
                      e.muud,
                      e.status,                    
                      (enum_range(NULL :: DOK_STATUS)) [e.status] :: TEXT AS dok_status
                    FROM eelarve.eelproj e
                    WHERE e.id = $1`,
            sqlAsNew: `SELECT 
                      $1 :: INTEGER                                 AS id,
                      $2 :: INTEGER                                 AS userid,
                      0::integer as rekvid,
                      extract(year from current_date)::integer as aasta,
                      0::integer as kuu,
                      $2::integer as kinnitaja,
                      null::text as muud,
                      1::integer as status,
                      'new' as dok_status`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        }
    ],
    grid: {
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
                          d.
                        FROM cur_eelproj d
                        WHERE d.rekvId in (select rekv_id from get_asutuse_struktuur($1))`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curEelproj'
    },
    returnData: {
        row: {},
        details: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'nimetus', name: 'Nimetus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: "nomid", name: "nomid", width: "200px", show: false},
            {id: 'asutus', name: 'Maksja', width: '200px', show: true, type: 'text', readOnly: false},
            {id: 'aa', name: 'Arveldus arve', width: '150px', show: true, type: 'text', readOnly: false},
            {id: 'summa', name: 'Summa', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'konto', name: 'Korr.konto', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'tunnus', name: 'Tunnus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'proj', name: 'Projekt', width: '100px', show: true, type: 'text', readOnly: false}
        ]
    },
    saveDoc: `select eelarve.sp_salvesta_eelproj($1, $2, $3) as id`,
    deleteDoc: `select error_code, result, error_message from eelarve.sp_delete_eelproj($1, $2)`, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'aasta',
            type: 'I',
        },
        {
            name: 'rekvid',
            type: 'I',
        },
        {
            name: 'kinnitaja',
            type: 'I',
        }


    ],
    executeCommand: {
        command: `select error_code, result, error_message from sp_execute_task($1::integer, $2::JSON, $3::TEXT )`, //$1- userId, $2 - params, $3 - task
        type:'sql',
        alias:'executeTask'
    },

};

module.exports = EelProj;
