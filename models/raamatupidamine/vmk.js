'use strict';

let now = new Date();

const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');


const Vmk = {
    select: [
        {
            sql: `select d.id,  d.docs_ids, (created::date || 'T' || created::time)::text as created, (lastupdate::date || 'T' || lastupdate::time)::text as lastupdate, d.bpm, 
                trim(l.nimetus) as doc, trim(l.kood) as doc_type_id, 
                trim(s.nimetus) as status, 
                k.number as number,  to_char(k.maksepaev,'YYYY-MM-DD') as maksepaev, k.viitenr,
                k.aaid as aa_id, trim(aa.nimetus) as pank, 
                k.rekvId, to_char(k.kpv,'YYYY-MM-DD') as kpv, k.selg, k.muud, k.opt, 
                k.arvid, ('Number:' || arv.number::text || ' Kuupäev:' || arv.kpv::text || ' Jääk:' || arv.jaak::text) as arvnr,
                (select sum(summa) from docs.mk1 where parentid = k.id) as summa
                from docs.doc d 
                inner join libs.library l on l.id = d.doc_type_id 
                inner join docs.mk k on k.parentId = d.id 
                left outer join libs.library s on s.library = 'STATUS' and s.kood = d.status::text 
                left outer join ou.aa as aa on k.aaid = aa.Id 
                left outer join docs.arv as arv on k.arvid = arv.Id 
                inner join ou.userid u on u.id = $2::integer 
                where d.id = $1`,
            sqlAsNew: `select $1::integer as id, $2::integer as userid, (now()::date || 'T' || now()::time)::text as created, (now()::date || 'T' || now()::time)::text as lastupdate, null as bpm,
                trim(l.nimetus) as doc, trim(l.kood) as doc_type_id, 
                trim(s.nimetus) as status, 
                coalesce((select max(number) from docs.mk where opt = 1 ),'0')::integer + 1  as number, to_char(now(),'YYYY-MM-DD') as maksepaev,  
                aa.id as aa_id, trim(aa.name) as pank, 
                null as rekvId,  to_char(now(),'YYYY-MM-DD') as kpv, null as viitenr,
                null as selg, null as muud, 1 as  opt, null as regkood, null as asutus, 
                null as arvid, null as arvnr, 0 as summa
                from libs.library l,   libs.library s, 
                (select id, trim(nimetus) as name from ou.aa where pank = 1 order by default_ limit 1) as aa, 
                (select * from ou.userid u where u.id = $2::integer) as u                
                where l.library = 'DOK' and l.kood = 'VMK'
                and u.id = $2::integer 
                and s.library = 'STATUS' and s.kood = '0'`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `select k1.id, $2::integer as userid, trim(n.kood) as kood, trim(n.nimetus) as nimetus, 
                trim(a.nimetus) as asutus,
                k1.* 
                from docs.mk1 as k1 
                inner join docs.mk k on k.id = k1.parentId 
                inner join libs.nomenklatuur n on n.id = k1.nomid 
                inner join libs.asutus a on a.id = k1.asutusid 
                inner join ou.userid u on u.id = $2::integer 
                where k.parentid = $1`,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        },
        {
            sql: `select rd.id, $2::integer as userid,  trim(l.kood) as doc_type, trim(l.nimetus) as name 
                from docs.doc d 
                left outer join docs.doc rd on rd.id in (select unnest(d.docs_ids)) 
                left outer join libs.library l on rd.doc_type_id = l.id 
                inner join ou.userid u on u.id = $2::integer 
                where d.id = $1`,
            query: null,
            multiple: true,
            alias: 'relations',
            data: []
        }

    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "kpv", name: "Kuupäev", width: "100px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "asutus", name: "Maksja", width: "200px"},
            {id: "aa", name: "Arveldus arve", width: "100px"},
            {id: "viitenr", name: "Viite number", width: "100px"},
            {id: "maksepaev", name: "Maksepäev", width: "100px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Status", width: "100px"}
        ],
        sqlString: `select d.id, to_char(k.kpv,'DD-MM-YYYY') as kpv, trim(k.number) as number, 
             trim(a.nimetus) as asutus, k1.aa, k1.summa, k.viitenr,
             to_char(k.maksepaev,'DD-MM-YYYY') as maksepaev,
             to_char(d.created,'DD.MM.YYYY HH:MM') as created, to_char(d.lastupdate,'DD.MM.YYYY HH:MM') as lastupdate , 
             s.nimetus as status 
             from docs.doc d 
             inner join docs.mk k on d.id = k.parentid 
             inner join docs.mk1 k1 on k.id = k1.parentid 
             inner join libs.asutus a on a.id = k1.asutusid
             inner join libs.library s on s.kood = d.status::text 
             where k.opt = 1
                and d.rekvId = $1
                and coalesce(docs.usersRigths(d.id, 'select', $2),true)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: ''
    },
    returnData: {
        row: {},
        details: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'nimetus', name: 'Nimetus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'asutus', name: 'Maksja', width: '200px', show: true, type: 'text', readOnly: false},
            {id: 'aa', name: 'Arveldus arve', width: '150px', show: true, type: 'text', readOnly: false},
            {id: 'summa', name: 'Summa', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'konto', name: 'Korr.konto', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'tunnus', name: 'Tunnus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'proj', name: 'Projekt', width: '100px', show: true, type: 'text', readOnly: false}
        ]
    },
    saveDoc: `select docs.sp_salvesta_mk($1, $2, $3) as id`,
    deleteDoc: `select error_code, result, error_message from docs.sp_delete_mk($1, $2)`, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'kpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        }
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
            name: 'Контировка',
            action: 'generateJournal',
            nextStep: 2,
            task: 'automat',
            data: [],
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
    executeTask: (task, docId, userId) => {
        // выполнит задачу, переданную в параметре

        let executeTask = task;
        if (executeTask.length == 0) {
            executeTask = ['start'];
        }

        let taskFunction = eval(executeTask[0]);
        return taskFunction(docId, userId, Vmk);
    },
    register: {command: `update docs.doc set status = 1 where id = $1`, type: "sql"},
    generateJournal: {command: `select docs.gen_lausend_mk($1, $2)`, type: "sql"},
    endProcess: {command: `update docs.doc set status = 2 where id = $1`, type: "sql"},


};

module.exports = Vmk;
