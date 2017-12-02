'use strict';

let now = new Date();

const Smk = {
    select: [
        {
            sql: `select d.id,  d.docs_ids, (created::date || 'T' || created::time)::text as created, 
                (lastupdate::date || 'T' || lastupdate::time)::text as lastupdate, d.bpm, 
                trim(l.nimetus) as doc, trim(l.kood) as doc_type_id, 
                trim(s.nimetus) as status, 
                k.number as number,  to_char(k.maksepaev,'YYYY-MM-DD') as maksepaev, k.viitenr,
                k.aaid as aa_id, trim(aa.nimetus) as pank, 
                k.rekvId, to_char(k.kpv,'YYYY-MM-DD') as kpv, k.selg, k.muud, k.opt, 
                k.arvid, ('Number:' || arv.number::text || ' Kuupäev:' || arv.kpv::text || ' Jääk:' || arv.jaak::text) as arvnr ,
                (select sum(summa) from docs.mk1 where parentid = k.id) as summa
                from docs.doc d 
                inner join libs.library l on l.id = d.doc_type_id 
                inner join docs.mk k on k.parentId = d.id 
                left outer join libs.library s on s.library = 'STATUS' and s.kood = d.status::text 
                left outer join ou.aa as aa on k.aaid = aa.Id 
                left outer join docs.arv as arv on k.arvid = arv.Id 
                inner join ou.userid u on u.id = $2::integer 
                where d.id = $1`,
            sqlAsNew: `select $1::integer as id, $2::integer as userid, 
                (now()::date || 'T' || now()::time)::text as created, 
                (now()::date || 'T' || now()::time)::text as lastupdate, null as bpm,
                trim(l.nimetus) as doc, trim(l.kood) as doc_type_id, 
                trim(s.nimetus) as status, 
                (select max(number) from docs.korder1 where tyyp = 1 )::integer + 1  as number, 
                to_char(now(),'YYYY-MM-DD') as maksepaev,  
                aa.id as aa_id, trim(aa.name) as pank, 
                null as rekvId,  to_char(now(),'YYYY-MM-DD') as kpv, null as viitenr,
                null as selg, null as muud, 0 as  tyyp, null as regkood, null as asutus, 
                null as arvid, null as arvnr, 0 as summa
                from libs.library l,   
                libs.library s, 
                (select id, trim(nimetus) as name from ou.aa where pank = 1 order by default_ limit 1) as aa ,
                (select * from ou.userid u where u.id = $2::integer) as u                
                where l.library = 'DOK' and l.kood = 'SMK'
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
             where k.opt = 0
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
        return taskFunction(docId, userId);
    },
    register: {command: `update docs.doc set status = 1 where id = $1`, type: "sql"},
    generateJournal: {command: `select docs.gen_lausend_mk($1, $2)`, type: "sql"},
    endProcess: {command: `update docs.doc set status = 2 where id = $1`, type: "sql"},


};

module.exports = Smk;

const start =(docId, userId)=> {
    // реализует старт БП документа
    const DOC_STATUS = 1, // устанавливаем активный статус для документа
        DocDataObject = require('./../documents'),
        SQL_UPDATE = 'update docs.doc set status = $1, bpm = $2, history = $4 where id = $3',
        SQL_SELECT_DOC = Smk.select[0].sql;

    let  bpm = setBpmStatuses(0, userId), // выставим актуальный статус для следующего процесса
        history = {user: userId, updated: Date.now()};

    // выполнить запрос и вернуть промис
    return DocDataObject.executeSqlQueryPromise(SQL_UPDATE, [DOC_STATUS, JSON.stringify(bpm), docId, JSON.stringify(history)]);

};

const setBpmStatuses = (actualStepIndex, userId)=>  {
// собираем данные на на статус документа, правим данные БП документа
    // 1. установить на actualStep = false
    // 2. задать статус документу
    // 3. выставить стутус задаче (пока только finished)
    // 4. если есть следующий шаг, то выставить там actualStep = true, статус задачи opened


    try {
        var bpm =  Smk.bpm, // нельзя использовать let из - за использования try {}
            nextStep = bpm[actualStepIndex].nextStep,
            executors = bpm[actualStepIndex].actors || [];

        if (!executors || executors.length == 0) {
            // если исполнители не заданы, то добавляем автора
            executors.push({
                id: userId,
                name: 'AUTHOR',
                role: 'AUTHOR'
            })
        }

        bpm[actualStepIndex].data = [{execution: Date.now(), executor: userId, vars: null}];
        bpm[actualStepIndex].status = 'finished';  // 3. выставить стутус задаче (пока только finished)
        bpm[actualStepIndex].actualStatus = false;  // 1. установить на actualStep = false
        bpm[actualStepIndex].actors = executors;  // установить список акторов

        // выставим флаг на следующий щаг
        bpm = bpm.map(stepData => {
            if (stepData.step === nextStep) {
                // 4. если есть следующий шаг, то выставить там actualStep = true, статус задачи opened
                stepData.actualStep = true;
                stepData.status = 'opened';
            }
            return stepData;
        });

    } catch (e) {
        console.error('try error', e);
    }
    return bpm;

};


/*

// generateJournal
const generateJournal = (docId, userId)=> {
    // реализует контировка

    const ACTUAL_STEP_STATUS = 1, // актуальный шаг БП
        SQL_GENERATE_LAUSEND = 'select docs.gen_lausend_arv((select id from docs.arv where parentid = $1), $2) as journal_id',
        SQL_UPDATE_DOCUMENT_BPM = 'update docs.doc set bpm = $2, history = $3  where id = $1',
        DocDataObject = require('./documents');

    let   bpm = setBpmStatuses(ACTUAL_STEP_STATUS, userId),
        tasks = [],
        history = {user: userId, updated: Date.now()};

    // выполнить запрос и вернуть промис
    return Promise.all([
        DocDataObject.executeSqlQueryPromise(SQL_GENERATE_LAUSEND, [docId, userId]),
        DocDataObject.executeSqlQueryPromise(SQL_UPDATE_DOCUMENT_BPM, [docId, JSON.stringify(bpm), JSON.stringify(history)])
    ]);
};
*/
