'use strict';

let now = new Date();

const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');


const Vorder = {
    select: [
        {
            sql: `select d.id,  d.docs_ids, (created::date || 'T' || created::time)::text as created, (lastupdate::date || 'T' || lastupdate::time)::text as lastupdate, d.bpm, 
             trim(l.nimetus) as doc, trim(l.kood) as doc_type_id, 
             trim(s.nimetus) as status, 
             k.number as number, k.summa, 
             k.kassaid as kassa_id, trim(aa.nimetus) as kassa, 
             k.rekvId, to_char(k.kpv,'YYYY-MM-DD') as kpv, k.asutusid,  trim(k.dokument) as dokument, k.alus, k.muud, k.nimi, k.aadress, k.tyyp, 
             asutus.regkood, trim(asutus.nimetus) as asutus, 
             k.arvid, ('Number:' || arv.number::text || ' Kuupäev:' || arv.kpv::text || ' Jääk:' || arv.jaak::text) as arvnr 
             from docs.doc d 
             inner join libs.library l on l.id = d.doc_type_id 
             inner join docs.korder1 k on k.parentId = d.id 
             left outer join libs.library s on s.library = 'STATUS' and s.kood = d.status::text 
             left outer join libs.asutus as asutus on asutus.id = k.asutusId  
             left outer join ou.aa as aa on k.kassaid = aa.Id 
             left outer join docs.arv as arv on k.arvid = arv.Id 
             inner join ou.userid u on u.id = $2::integer 
             where d.id = $1`,
            sqlAsNew: `select $1::integer as id, $2::integer as userid, 
             (now()::date || 'T' || now()::time)::text as created, 
             (now()::date || 'T' || now()::time)::text as lastupdate, 
             null as bpm,
             trim(l.nimetus) as doc, trim(l.kood) as doc_type_id, 
             trim(s.nimetus) as status, 
             (select max(number) from docs.korder1 where tyyp = 2 )::integer + 1  as number,  
             0 as summa, 
             aa.id as kassa_id, trim(aa.name) as kassa, 
             null as rekvId,  to_char(now(),'YYYY-MM-DD') as kpv, 
             null as asutusid, null as dokument, null as alus, null as muud, null as nimi, 
             null as aadress, 
             2 as tyyp,  0 as summa,  null as regkood, null as asutus, 
             null as arvid, null as arvnr
             from libs.library l,  
              ou.userid u,
             libs.library s, 
             (select id, trim(nimetus) as name 
                from ou.aa where kassa = 1 order by default_ limit 1) as aa 
             where l.library = 'DOK' and l.kood = 'VORDER'
             and u.id = $2::integer 
             and s.library = 'STATUS' and s.kood = '0'`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: "select k1.id, $2::integer as userid, trim(n.kood) as kood,  trim(n.nimetus) as nimetus, trim(n.uhik) as uhik, k1.* " +
            " from docs.korder2 as k1 " +
            " inner join docs.korder1 k on k.id = k1.parentId " +
            " inner join libs.nomenklatuur n on n.id = k1.nomid " +
            " inner join ou.userid u on u.id = $2::integer " +
            " where k.parentid = $1",
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
            {id: "id", name: "id", width: "25px"},
            {id: "kpv", name: "Kuupaev", width: "100px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "nimi", name: "Nimi", width: "200px"},
            {id: "dokument", name: "Dokument", width: "200px"},
            {id: "summa", name: "Summa", width: "100px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Status", width: "100px"}
        ],
        sqlString: `select d.id, to_char(k.kpv,'DD-MM-YYYY') as kpv, trim(k.number) as number, 
             trim(k.nimi) as nimi, trim(k.dokument) as dokument,
             to_char(d.created,'DD.MM.YYYY HH:MM') as created, to_char(d.lastupdate,'DD.MM.YYYY HH:MM') as lastupdate , 
             k.summa, 
             s.nimetus as status 
             from docs.doc d 
             inner join docs.korder1 k on d.id = k.parentid 
             inner join libs.library s on s.kood = d.status::text
             where k.tyyp = 2
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
            {id: 'summa', name: 'Summa', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'tunnus', name: 'Tunnus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'proj', name: 'Projekt', width: '100px', show: true, type: 'text', readOnly: false}

            /*
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
             */
        ]
    },
    requiredFields: [
        {
            name: 'kpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {name: 'asutusid', type: 'N', min: null, max: null},
        {name: 'summa', type: 'N', min: -9999999, max: 999999}
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
        return taskFunction(docId, userId, Vorder);
    },
    register: {command: `update docs.doc set status = 1 where id = $1`, type: "sql"},
    generateJournal: {command: `select docs.gen_lausend_arv($1, $2)`, type: "sql"},
    endProcess: {command: `update docs.doc set status = 2 where id = $1`, type: "sql"},
    saveDoc: "select docs.sp_salvesta_korder($1, $2, $3) as id",
    deleteDoc: `select error_code, result, error_message from docs.sp_delete_korder($1, $2)`, // $1 - userId, $2 - docId

};

module.exports = Vorder;
