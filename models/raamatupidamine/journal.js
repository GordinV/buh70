'use strict';

let now = new Date();

const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');

const Journal = {
    select: [
        {
            sql: `select d.id, $2::integer as userid, d.docs_ids, (to_char(created,'DD.MM.YYYY HH:MM:SS'))::text as created, 
                (to_char(lastupdate,'DD.MM.YYYY HH:MM:SS'))::text as lastupdate, d.bpm, 
                 trim(l.nimetus) as doc, trim(l.kood) as doc_type_id, 
                 trim(s.nimetus) as status, d.status as doc_status,
                 jid.number as number, 
                 j.rekvId, to_char(j.kpv,'YYYY-MM-DD') as kpv, j.asutusid,  trim(j.dok) as dok, j.selg, j.muud, 
                 (select sum(j1.summa) as summa from docs.journal1 as j1 where parentid = j.id) as summa, 
                 asutus.regkood, trim(asutus.nimetus) as asutus 
                 from docs.doc d 
                 inner join libs.library l on l.id = d.doc_type_id 
                 inner join docs.journal j on j.parentId = d.id 
                 inner join ou.userid u on u.id = $2::integer 
                 left outer join docs.journalid jid on j.Id = jid.journalid 
                 left outer join libs.library s on s.library = 'STATUS' and s.kood = d.status::text
                 left outer join libs.asutus as asutus on asutus.id = j.asutusId 
                 where d.id = $1`,
            sqlAsNew: `select $1::integer as id, 
                    to_char(now(), 'DD.MM.YYYY HH:MM:SS')::text as created, 
                    to_char(now(), 'DD.MM.YYYY HH:MM:SS')::text as lastupdate,            
                    null as bpm,
                    trim(l.nimetus) as doc, trim(l.kood) as doc_type_id,
                    trim(s.nimetus) as status, 0 as doc_status, 
                    trim('') as number,  null as rekvId,  to_char(now(),'YYYY-MM-DD') as kpv, 
                    null as asutusid, null as dok, null as selg, null as muud, 0 as summa,  null as regkood, null as asutus 
                    from libs.library l,   libs.library s, ou.userid u
                    where l.library = 'DOK' and l.kood = 'JOURNAL'
                    and u.id = $2::integer 
                    and s.library = 'STATUS' and s.kood = '0'`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: "select j1.*, $2::integer as userid " +
            " from docs.journal1 as j1 " +
            " inner join docs.journal j on j.id = j1.parentId " +
            " inner join ou.userid u on u.id = $2::integer " +
            " where j.parentid = $1",
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        },
        {
            sql: "select rd.id, $2::integer as userid, trim(l.kood) as doc_type, trim(l.nimetus) as name " +
            " from docs.doc d " +
            " left outer join docs.doc rd on rd.id in (select unnest(d.docs_ids)) " +
            " left outer join libs.library l on rd.doc_type_id = l.id " +
            " inner join ou.userid u on u.id = $2::integer " +
            " where d.id = $1",
            query: null,
            multiple: true,
            alias: 'relations',
            data: []
        }

    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px", "type": "integer"},
            {id: "kpv", name: "Kuupaev", width: "100px", "type": "text"},
            {id: "number", name: "Number", width: "100px", "type": "integer"},
            {id: "selg", name: "Selgitus", width: "200px", "type": "text"},
            {id: "dok", name: "Dokument", width: "200px", "type": "text"},
            {id: "deebet", name: "Db", width: "50px", "type": "string"},
            {id: "kreedit", name: "Kr", width: "50px", "type": "string"},
            {id: "summa", name: "Summa", width: "100px", "type": "number"},
            {id: "created", name: "Lisatud", width: "150px", "type": "date"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px", "type": "date"},
            {id: "status", name: "Status", width: "100px", "type": "string"}
        ],
        sqlString: `select d.id, to_char(j.kpv,'DD.MM.YYYY') as kpv, jid.number, j.selg, j.dok, 
         j1.deebet, j1.kreedit, j1.summa, 
         to_char(d.created,'DD.MM.YYYY HH:MM') as created, to_char(d.lastupdate,'DD.MM.YYYY HH:MM') as lastupdate , 
         s.nimetus as status 
         from docs.journal j 
         inner join docs.doc d on d.id = j.parentid 
         inner join docs.journalid jid on j.id = jid.journalid 
         inner join docs.journal1 j1 on j.id = j1.parentid 
         inner join libs.library s on s.kood = d.status::text 
         where d.rekvId = $1
            and coalesce(docs.usersRigths(d.id, 'select', $2),true)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: ''
    },
    returnData: {
        row: {},
        details: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'deebet', name: 'Deebet', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'kreedit', name: 'Kreedit', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'summa', name: 'Summa', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'tunnus', name: 'Tunnus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'proj', name: 'Projekt', width: '100px', show: true, type: 'text', readOnly: false}
        ]
    },
    requiredFields: [
        {
            name: 'kpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {name: 'selg', type: 'C'},
        {name: 'summa', type: 'N'}
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
        {
            step: 1,
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
    saveDoc: "select docs.sp_salvesta_journal($1, $2, $3) as id",
    deleteDoc: `select error_code, result, error_message from docs.sp_delete_journal($1, $2)`, // $1 - userId, $2 - docId
    register: {command: `update docs.doc set status = 1 where id = $1`, type: "sql"},
    endProcess: {command: "update docs.doc set status = 2 where id = $1", type: "sql"},
    executeTask: function (task, docId, userId) {
        // выполнит задачу, переданную в параметре

        let executeTask = task;
        if (executeTask.length == 0) {
            executeTask = ['start'];
        }

        let taskFunction = eval(executeTask[0]);
        return taskFunction(docId, userId, Journal);
    }
};

module.exports = Journal;