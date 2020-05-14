'use strict';

let now = new Date();

const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');

const DokLausend = {
    select: [
        {
            sql: `SELECT
                    d.id,
                    u.id as userid,
                    d.rekvId,
                    d.dok,
                    d.selg,
                    d.muud,
                    d.status
                    FROM docs.doklausheader d
                    INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                    WHERE d.id = $1`,
            sqlAsNew: `SELECT
                          $1 :: INTEGER        AS id,
                          $2 :: INTEGER        AS userid,
                          0 :: INTEGER     AS rekvid,
                          '' :: VARCHAR(50) AS dok,
                          '' :: TEXT        AS selg,
                          '' :: TEXT        AS muud,
                          1 :: INTEGER        AS status`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT
                      d1.id,
                      $2 :: INTEGER   AS userid,
                      d1.*
                    FROM docs.doklausend AS d1
                      INNER JOIN docs.doklausheader d ON d.id = d1.parentId
                      INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                    WHERE d1.parentid = $1`,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        }
    ],
    returnData: {
        row: {},
        relations: [],
        details: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'deebet', name: 'Deebet', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'lisa_d', name: 'TP-D', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'kreedit', name: 'Kreedit', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'lisa_k', name: 'TP-K', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'summa', name: 'Summa', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'dok', name: 'Dokument', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'selg', name: 'Selgitus', width: '100px', show: true, type: 'text', readOnly: false}
        ]
    },

    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "deebet", name: "Deebet", width: "100px"},
            {id: "kreedit", name: "Kreedit", width: "100px"},
            {id: "summa", name: "Summa", width: "100px"},
            {id: "dok", name: "Dokument", width: "200px"},
            {id: "selg", name: "Selgitus", width: "200px"},
            {id: "tegev", name: "Tegevusala", width: "150px"},
            {id: "allikas", name: "Allikas", width: "150px"},
            {id: "rahavoog", name: "Rahavoog", width: "100px"},
            {id: "Artikkel", name: "Artikkel", width: "100px"}
        ],
        sqlString: `SELECT  d.id,
                        d.rekvid,
                        d.dok,
                        d.selg::varchar(254),
                        d.deebet,
                        d.kreedit,
                        d.summa,
                        d.tegev,
                        d.allikas,
                        d.rahavoog,
                        d.artikkel,
                        d.lisa_d,
                        d.lisa_k,
                        d.lausend
                    FROM cur_doklausend d
                    WHERE (d.rekvId = $1 or d.rekvid is null)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curDoklausend'
    },
    saveDoc: `select docs.sp_salvesta_doklausend($1, $2, $3) as id`,
    deleteDoc: `select error_code, result, error_message from docs.sp_delete_doklausend($1, $2)`, // $1 - userId, $2 - docId
    requiredFields: [
        {name: 'selg', type: 'C'}
    ]
};

module.exports = DokLausend;
