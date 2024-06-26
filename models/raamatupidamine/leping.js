'use strict';
let now = new Date();
const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');

const DOC_TYPE_ID = 'LEPING';

const Leping = {
    select: [
        {
            sql: `select d.id, $2::integer as userid, to_char(created, 'DD.MM.YYYY HH:MI:SS')::text as created, 
                to_char(lastupdate,'DD.MM.YYYY HH:MI:SS')::text as lastupdate, d.bpm, 
                 trim(l.nimetus) as doc, trim(l.kood) as doc_type_id,
                 trim(s.nimetus) as status, d.status as doc_status,
                 trim(a.number)::varchar(20) as number, a.rekvId, 
                 a.kpv as kpv, 
                 a.asutusid,
                 a.selgitus, 
                 a.doklausid,                
                 a.tahtaeg, 
                 a.dok, 
                 a.pakettid,
                 a.objektid,
                 a.muud,
                 (d.history->0->>'user')::varchar(120)                                          AS koostaja
                 from docs.doc d 
                 inner join libs.library l on l.id = d.doc_type_id 
                 inner join docs.leping1 a on a.parentId = d.id 
                 left outer join libs.library s on s.library = 'STATUS' and s.kood = d.status::text 
                 inner join libs.asutus as asutus on asutus.id = a.asutusId 
                 inner join ou.userid u on u.id = $2::integer 
                 where d.id = $1`,
            sqlAsNew: `select $1::integer as id, $2::integer as userid,  
                    to_char(now(), 'DD.MM.YYYY HH:MM:SS')::text as created, 
                    to_char(now(), 'DD.MM.YYYY HH:MM:SS')::text as lastupdate, null as bpm,
                 trim(l.nimetus) as doc, trim(l.kood) as doc_type_id, 
                 trim(s.nimetus) as status, 0 as doc_status, 
                 docs.sp_get_number(u.rekvId, 'LEPING', year(date()), null)::varchar(20) as number, 
                 null as rekvId, 
                 now()::date as kpv,
                 5 as doklausid,
                 null as asutusid, 
                 null::text as selgitus, 
                 (now()  + interval '365 days')::date as tahtaeg, 
                 null::text as dok, 
                 null::integer as pakettid, 
                 null::integer as objektId,
                 null::text as muud
                 from libs.library l,   libs.library s, ou.userid u  
                 where l.library = 'DOK' and l.kood = 'LEPING' 
                 and u.id = $2::integer 
                 and s.library = 'STATUS' and s.kood = '0'`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `select a1.id, $2::integer as userid, 
                 a1.nomid, a1.kogus, a1.hind, a1.kbm, a1.summa,
                 trim(n.kood)::varchar(20) as kood, trim(n.nimetus)::varchar(254) as nimetus,
                 a1.soodus,
                 a1.soodusalg::date,
                 a1.sooduslopp::date,
                 a1.status,
                 a1.formula,
                 a1.muud
                 from docs.leping2 as a1 
                 inner join docs.leping1 a on a.id = a1.parentId 
                 inner join libs.nomenklatuur n on n.id = a1.nomId 
                 inner join ou.userid u on u.id = $2::integer 
                 where a.parentid = $1::integer`,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        },
        {
            sql: `select rd.id, $2::integer as userid, trim(l.kood) as doc_type, trim(l.nimetus) as name 
                 from docs.doc d 
                 left outer join docs.doc rd on rd.id in (select unnest(d.docs_ids)) 
                 left outer join libs.library l on rd.doc_type_id = l.id 
                 inner join ou.userid u on u.id = $2::integer 
                 where d.id = $1::integer`,
            query: null,
            multiple: true,
            alias: 'relations',
            data: []
        }

    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px", show: false},
            {id: "number", name: "Number", width: "100px"},
            {id: "kpv", name: "Kuupaev", width: "100px"},
            {id: "asutus", name: "Asutus", width: "200px"},
            {id: "selgitus", name: "Selgitus", width: "200px"},
            {id: "pakett", name: "pakett", width: "75px"},
            {id: "objekt", name: "Objekt", width: "100px"},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "tahtaeg", name: "Tahtaeg", width: "100px"},
            {id: "created", name: "Lisatud", width: "150px"},
        ],
        sqlString: `select d.*
         from cur_lepingud d         
         where d.rekvId = $1 
         and docs.usersRigths(d.id, 'select', $2)
         order by d.number`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curLepingud'
    },
    returnData: {
        row: {},
        details: [],
        relations: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'nomid', name: 'nomId', width: '0px', show: false, type: 'text', readOnly: false},
            {
                id: 'kood',
                name: 'Kood',
                width: '100px',
                show: true,
                type: 'select',
                readOnly: false,
                dataSet: 'nomenclature',
                valueFieldName: 'nomid'
            },
            {id: 'nimetus', name: 'Nimetus', width: '300px', show: true, readOnly: true},
            {id: 'hind', name: 'Hind', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'kogus', name: 'kogus', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'kbm', name: 'Käibemaks', width: '100px', show: true, type: 'number', readOnly: false}
        ]
    },
    saveDoc: `select docs.sp_salvesta_leping($1, $2, $3) as id`,
    deleteDoc: `select error_code, result, error_message from docs.sp_delete_leping($1, $2)`, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'kpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {
            name: 'tahtaeg',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {name: 'asutusid', type: 'N', min: null, max: null},
        {name: 'kogus', type: 'N', min: -9999999, max: 999999}
    ],
    bpm: [
        {
            step: 0,
            name: 'Регистация документа',
            action: 'start',
            nextStep: 1,
            task: 'human',
            data: [],
            actors: [],
            status: null,
            actualStep: false
        },
//        {step:2, name:'Оплата', action: 'tasumine', nextStep:3, task:'human', data:[], status:null, actualStep:false},
        {
            step: 2,
            name: 'Конец',
            action: 'endProcess',
            nextStep: null,
            task: 'automat',
            data: [],
            actors: [],
            status: null,
            actualStep: false
        }
    ],
    register: {command: `update docs.doc set status = 1 where id = $1`, type: "sql"},
    endProcess: {command: "update docs.doc set status = 2 where id = $1", type: "sql"},
    executeCommand: {
        command: `select * from docs.sp_calc_viivised($1::integer, $2::JSON)`, //$1- userId, $2 - params
        type:'sql',
        alias:'calcViivised'
    },

    executeTask: function (task, docId, userId) {
        console.log('executeTask', task, docId, userId);
        // выполнит задачу, переданную в параметре

        let executeTask = task;
        if (executeTask.length == 0) {
            executeTask = ['start'];
        }

        let taskFunction = eval(executeTask[0]);
        return taskFunction(docId, userId, this);
    },
    print: [
        {
            sql: `SELECT DISTINCT
                  $2                                                              AS user_id,
                  l.id,
                  l.kood,
                  l.nomid,
                  left(rtrim(l.asutus) || ' ' || rtrim(nimetus), 120) :: VARCHAR AS nimetus,
                  l.objektid,
                  l.pakettId,
                  l.tahtaeg
                FROM wizlepingud l
                WHERE l.rekvId = $1`,     // $1 всегда ид учреждения $2 - всегда ид пользователя,
            alias: 'wizlepingud'

        }
    ],
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                                                        AS id,
                         (ajalugu ->> 'user')::VARCHAR(20)                                                           AS kasutaja,
                         coalesce(to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS koostatud,
                         coalesce(to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS muudatud,
                         coalesce(to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS prinditud,
                         coalesce(to_char((ajalugu ->> 'email')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'), '')::VARCHAR(20) AS
                                                                                                                        email,
                         coalesce(to_char((ajalugu ->> 'earve')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS earve,
                         coalesce(to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS kustutatud
                  FROM (
                           SELECT jsonb_array_elements( history) AS ajalugu, d.id, d.rekvid
                           FROM docs.doc d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry`,
        type: "sql",
        alias: "getLogs"
    },

};

module.exports = Leping;

