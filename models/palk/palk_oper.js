'use strict';

let now = new Date();

const PalkOper = {
    select: [
        {
            sql: `SELECT
                      d.id,
                      d.docs_ids,
                      (to_char(d.created, 'DD.MM.YYYY HH:MM:SS')) :: TEXT    AS created,
                      (to_char(d.lastupdate, 'DD.MM.YYYY HH:MM:SS')) :: TEXT AS lastupdate,
                      d.bpm,
                      trim(l.nimetus)                                        AS doc,
                      trim(l.kood)                                           AS doc_type_id,
                      trim(s.nimetus)                                        AS status,
                      p.kpv                                                  AS kpv,
                      p.rekvid,
                      p.libid,
                      p.lepingid,
                      p.summa,
                      p.tululiik,
                      p.journalid,
                      p.muud,
                      p.kood1,
                      p.kood2,
                      p.kood3,
                      p.kood4,
                      p.kood5,
                      p.konto,
                      p.tp,
                      p.tunnus,
                      p.proj,
                      p.tulumaks,
                      p.sotsmaks,
                      p.tootumaks,
                      p.pensmaks,
                      p.tulubaas,
                      p.tka,
                      p.period,
                      p.pohjus,
                      dp.selg :: VARCHAR(120)                                AS dokprop,
                      (case when empty(dp.registr::integer) then false else true end)::boolean as kas_lausend,                      
                      p.doklausid                                            AS dokpropid,
                      coalesce(jid.number, 0) :: INTEGER                     AS lausend,
                      t.parentid,
                      (pl.properties::jsonb->>'liik')::integer as liik,
                      (pl.properties::jsonb->>'asutusest')::integer as asutusest                                             
                    FROM docs.doc d
                      INNER JOIN palk.palk_oper p ON p.parentId = d.id
                      INNER JOIN palk.tooleping t ON t.id = p.lepingid
                      INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                      INNER JOIN libs.asutus a ON a.id = t.parentid
                      LEFT OUTER JOIN libs.library pl ON pl.id = p.libid
                      LEFT OUTER JOIN libs.library l ON l.id = d.doc_type_id
                      LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                      LEFT OUTER JOIN libs.dokprop dp ON dp.id = p.doklausid
                      LEFT OUTER JOIN docs.doc dj ON p.journalid = dj.id
                      LEFT OUTER JOIN docs.journal j ON j.parentid = dj.id
                      LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
                    WHERE d.id = $1`,
            sqlAsNew: `SELECT
                          $1 :: INTEGER                                 AS id,
                          $2 :: INTEGER                                 AS userid,
                          to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT AS created,
                          to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT AS lastupdate,
                          NULL                                          AS bpm,
                          'PALK_OPER'                                   AS doc_type_id,
                          1                                             AS status,
                          NULL :: INTEGER                               AS rekvId,
                          null::integer as lepingid,
                          null::integer as libid,
                          now() :: DATE                                 AS kpv,
                          NULL :: TEXT                                  AS selg,
                          NULL :: TEXT                                  AS muud,
                          0 :: NUMERIC(12, 2)                           AS summa,
                          NULL :: INTEGER                               AS journalid,
                          NULL :: VARCHAR(20)                           AS tululiik,
                          NULL :: VARCHAR(20)                           AS kood1,
                          NULL :: VARCHAR(20)                           AS kood2,
                          NULL :: VARCHAR(20)                           AS kood3,
                          NULL :: VARCHAR(20)                           AS kood4,
                          NULL :: VARCHAR(20)                           AS kood5,
                          NULL :: VARCHAR(20)                           AS konto,
                          NULL :: VARCHAR(20)                           AS proj,
                          NULL :: VARCHAR(20)                           AS tp,
                          NULL :: VARCHAR(20)                           AS tunnus,
                          0 :: NUMERIC(12, 2)                           AS tulumaks,
                          0 :: NUMERIC(12, 2)                           AS sotsmaks,
                          0 :: NUMERIC(12, 2)                           AS tootumaks,
                          0 :: NUMERIC(12, 2)                           AS pensmaks,
                          0 :: NUMERIC(12, 2)                           AS tulubaas,
                          0 :: NUMERIC(12, 2)                           AS tka,
                          NULL :: DATE                                  AS period,
                          NULL :: TEXT                                  AS pohjus,
                          NULL :: INTEGER                               AS journalid,
                          NULL :: INTEGER                               AS dokpropid,
                          false as kas_lausend,
                          NULL::INTEGER                                 AS parentid,
                          1                                             AS liik,
                          NULL :: INTEGER                               AS lausend`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT
                      rd.id,
                      $2 :: INTEGER   AS userid,
                      trim(l.kood)    AS doc_type,
                      trim(l.nimetus) AS name
                    FROM docs.doc d
                      LEFT OUTER JOIN docs.doc rd ON rd.id IN (SELECT unnest(d.docs_ids))
                      LEFT OUTER JOIN libs.library l ON rd.doc_type_id = l.id
                      INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                    WHERE d.id = $1`,
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
            {id: "summa", name: "Summa", width: "100px"},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "liik", name: "Liik", width: "100px"},
            {id: "journalid", name: "Lausend", width: "100px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Status", width: "100px"}
        ],
        sqlString: `SELECT
                          d.*
                        FROM palk.cur_palkoper d
                        WHERE d.rekvId = $1
                              AND coalesce(docs.usersRigths(d.id, 'select', $2), TRUE)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPalkOper'
    },
    returnData: {
        row: {},
        relations: []
    },
    saveDoc: `select palk.sp_salvesta_palk_oper($1, $2, $3) as id`,
    deleteDoc: `select error_code, result, error_message from palk.sp_delete_palk_oper($1, $2)`, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'kpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {
            name: 'lepingid',
            type: 'I',
        },
        {
            name: 'libid',
            type: 'I',
        },
        {
            name: 'summa',
            type: 'N',
        }

    ],
    generateJournal: {
        command: `select error_code, result, error_message from docs.gen_lausend_avans($2, $1)`, // $1 - userId, $2 - docId
        type: "sql",
        alias: 'generateJournal'
    },
    executeCommand: {
        command: `select * from sp_execute_task($1::integer, $2::JSON, $3::TEXT )`, //$1- userId, $2 - params, $3 - task
        type:'sql',
        alias:'executeTask'
    },


    /*
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
*/
/*
    executeTask: (task, docId, userId) => {
        // выполнит задачу, переданную в параметре

        let executeTask = task;
        if (executeTask.length == 0) {
            executeTask = ['start'];
        }

        let taskFunction = eval(executeTask[0]);
        return taskFunction(docId, userId, PalkOper);
    },
    register: {command: `update docs.doc set status = 1 where id = $1`, type: "sql"},
    generateJournal: {
        command: `select error_code, result, error_message from docs.gen_lausend_avans($2, $1)`, // $1 - userId, $2 - docId
        type: "sql",
        alias: 'generateJournal'
    },
    endProcess: {command: `update docs.doc set status = 2 where id = $1`, type: "sql"},
    executeCommand: {
        command: `select result, error_message from docs.fnc_avansijaak(?tnId)`,
        type:'sql',
        alias:'fncAvansiJaak'
    },
*/


};

module.exports = PalkOper;
