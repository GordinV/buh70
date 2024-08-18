'use strict';

let now = new Date();

const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');


const Hooleping = {
    selectAsLibs: `SELECT id,
                          isikukood,
                          nimi,
                          rekvid,
                          hooldekodu,
                          algkpv,
                          loppkpv
                   FROM hooldekodu.com_asutus_hooldekodu hi
                   WHERE hi.rekvid = $1
                   ORDER BY nimi`,
    select: [
        {
            sql: `SELECT hl.id,
                         hl.number                                                     AS number,
                         hl.rekvid,
                         hl.isikid,
                         hl.omavalitsusId,
                         hl.hooldekoduid,
                         hl.sugulane_id,
                         hl.muud                                                       AS muud,
                         hl.algkpv,
                         hl.loppkpv,
                         hl.summa,
                         hl.jaak,
                         hl.kovjaak,
                         hl.osa,
                         hl.tasku_raha,
                         hl.makse_viis,
                         hl.rahasaaja_id,
                         hl.aa,
                         hl.tunnus,
                         hl.bruttosissetulek,
                         coalesce(hl.netosissetulek, 0)                                AS netosissetulek,
                         hl.sugulane_osa,
                         hl.status,
                         coalesce((hl.properties ->> 'algoritm')::INTEGER, 0)::INTEGER AS algoritm,
                         CASE
                             WHEN coalesce(hl.hoolduskulud, 0) = 0 THEN h.summa
                             ELSE hl.hoolduskulud END                                  AS hoolduskulud,
                         hl.summa - (CASE
                                         WHEN coalesce(hl.hoolduskulud, 0) = 0 THEN h.summa
                                         ELSE hl.hoolduskulud END)                     AS isiku_kulud
                  FROM hooldekodu.hooleping hl
                           INNER JOIN libs.asutus a ON a.id = hl.hooldekoduid,
                       (SELECT summa
                        FROM hooldekodu.hoo_config
                        WHERE library = 'RIIGI_TOETUS'
                          AND status < 3
                        ORDER BY kpv DESC
                        LIMIT 1) h
                  WHERE hl.id = $1`,
            sqlAsNew: `SELECT $1 :: INTEGER                                                                AS id,
                              docs.sp_get_number(u.rekvId, 'HOOLEPING', year(date()), NULL) :: VARCHAR(20) AS number,
                              (SELECT rekvid FROM ou.userid WHERE id = $2 LIMIT 1)::INTEGER                AS rekvid,
                              0::INTEGER                                                                   AS isikId,
                              0 :: INTEGER                                                                 AS omavalitsusId,
                              0::INTEGER                                                                   AS hooldekoduId,
                              0::INTEGER                                                                   AS sugulane_id,
                              '' :: TEXT                                                                   AS muud,
                              (make_date(date_part('year', CURRENT_DATE)::INTEGER,
                                         date_part('month', CURRENT_DATE) :: INTEGER, 1) -
                               INTERVAL
                                   '1 month') :: DATE                                                      AS algkpv,
                              (make_date(date_part(
                                                 'year', CURRENT_DATE)::INTEGER,
                                         date_part(
                                                 'month', CURRENT_DATE) :: INTEGER, 1) -
                               INTERVAL
                                   '1 day') :: DATE                                                        AS loppkpv,
                              0 :: NUMERIC                                                                 AS summa,
                              0 :: NUMERIC                                                                 AS jaak,
                              0 :: NUMERIC                                                                 AS kovjaak,
                              0 :: NUMERIC                                                                 AS sugulane_osa,
                              NULL::INTEGER                                                                AS makse_viis,
                              NULL::INTEGER                                                                AS rahasaaja_id,
                              NULL::VARCHAR(20)                                                            AS aa,
                              NULL::VARCHAR(20)                                                            AS tunnus,
                              0::INTEGER                                                                   AS osa,
                              15::INTEGER                                                                  AS tasku_raha,
                              1                                                                            AS status,
                              0                                                                            AS algoritm
                       FROM ou.userid u
                       WHERE u.id = $2 :: INTEGER            `,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT ht.id,
                         ht.lepingid,
                         ht.nomid,
                         nom.kood,
                         nom.nimetus,
                         ht.hind::NUMERIC(12, 2),
                         ht.allikas,
                         ht.tuluosa,
                         ht.jaak::NUMERIC(12, 2),
                         ht.muud,
                         ht.muud::VARCHAR(254) AS selg,
                         ht.kehtivus,
                         $2                    AS user_id
                  FROM hooldekodu.hooTeenused ht
                           INNER JOIN libs.nomenklatuur nom ON nom.id = ht.nomid
                  WHERE ht.lepingid IN (SELECT id FROM hooldekodu.hooleping WHERE ht.lepingid = $1)`,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        },
        {
            sql: `SELECT rd.id, $2 :: INTEGER AS userid, trim(l.kood) AS doc_type, trim(l.nimetus) AS name
                  FROM docs.doc d
                           LEFT OUTER JOIN docs.doc rd ON rd.id IN (SELECT unnest(d.docs_ids))
                           LEFT OUTER JOIN libs.library l ON rd.doc_type_id = l.id
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                  WHERE d.id = $1`,
            query: null,
            multiple: true,
            alias: 'relations',
            data: []
        },
        {
            sql: `select 0 as id, 'Jääk kuu lõpus'::varchar(254) as nimetus, $1 as param1, $2 as param2
                    union all
                  select 1 as id, 'Vaba jääk'::varchar(254) as nimetus, $1 as param1, $2 as param2
                    union all
                  select 2 as id, 'Tulu arve'::varchar(254) as nimetus, $1 as param1, $2 as param2`,
            query: null,
            multiple: true,
            alias: 'algoritmid',
            data: []
        },
        {
            sql: `select 1 as id, 'Makse korraldus'::varchar(254) as nimetus, $1 as param1, $2 as param2
                    union all
                  select 2 as id, 'Väljamakse kassaorder'::varchar(254) as nimetus, $1 as param1, $2 as param2
                    union all
                  select 3 as id, 'Tasaarveldus'::varchar(254) as nimetus, $1 as param1, $2 as param2`,
            query: null,
            multiple: true,
            alias: 'makse_viis',
            data: []
        },
        {
            sql: `select hooldekodu.sp_calc_netosissetulek($1::integer, $2::numeric) as summa`,
            query: null,
            multiple: true,
            alias: 'calcNeto',
            data: []
        },

    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "algkpv", name: "Alg.Kpv", width: "100px"},
            {id: "loppkpv", name: "Lõpp kpv", width: "100px"},
            {id: "nomid", name: "nomid", width: "200px", show: false},
            {id: "summa", name: "Summa", width: "100px"},
            {id: "volg", name: "Võlg", width: "100px"},
            {id: "status", name: "Staatus", width: "100px"}
        ],
        sqlString: `SELECT d.*
                    FROM hooldekodu.cur_hooleping d
                    WHERE d.rekvId = $1`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curHooLeping'
    },
    returnData: {
        row: {},
        details: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'kood', name: 'Kood', width: '100px', show: true, type: 'text', readOnly: false},
            {id: "nomid", name: "nomid", width: "10px", show: false},
            {id: 'maksumaar', name: 'Maksumaar', width: '200px', show: true, type: 'text', readOnly: false},
            {id: 'kogus', name: 'Kogus', width: '150px', show: true, type: 'text', readOnly: false},
            {id: 'liik', name: 'Sooduseliik', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'soodus', name: 'Soodus', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'summa', name: 'Summa', width: '100px', show: true, type: 'number', readOnly: false}
        ]
    },
    saveDoc: `select hooldekodu.sp_salvesta_hooleping($1, $2, $3) as id`,
    deleteDoc: `SELECT error_code, result, error_message
                FROM hooldekodu.sp_delete_hooleping($1, $2)`, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'algkpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {
            name: 'loppkpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {
            name: 'hooldekoduid',
            type: 'I',
        },
        {
            name: 'summa',
            type: 'N',
        },
        {
            name: 'number',
            type: 'C',
        }


    ],
    bpm: [],
    executeTask: (task, docId, userId) => {
        // выполнит задачу, переданную в параметре

        let executeTask = task;
        if (executeTask.length == 0) {
            executeTask = ['start'];
        }

        let taskFunction = eval(executeTask[0]);
        return taskFunction(docId, userId, Hooleping);
    },
    executeCommand: {
        command: `SELECT *
                  FROM sp_execute_task($1 :: INTEGER, $2 :: JSON, $3 :: TEXT)`, //$1- userId, $2 - params, $3 - task
        type: 'sql',
        alias: 'executeTask'
    },


};

module.exports = Hooleping;
