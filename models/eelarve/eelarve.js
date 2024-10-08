'use strict';

let now = new Date();

const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');


const Eelarve = {
    select: [
        {
            sql: `SELECT
                      d.id,
                      d.docs_ids,
                      (to_char(d.created, 'DD.MM.YYYY HH:MM:SS')) :: TEXT              AS created,
                      (to_char(d.lastupdate, 'DD.MM.YYYY HH:MM:SS')) :: TEXT           AS lastupdate,
                      d.bpm,
                      trim(l.nimetus)                                                AS doc,
                      trim(l.kood)                                                   AS doc_type_id,
                      trim(s.nimetus)                                                AS status,
                      d1.number                                                      AS number,
                      d1.kpv                                                         AS kpv,
                      d1.rekvid,
                      d1.selg                                                        AS selg,
                      d1.asutusid,
                      d1.journalid,
                      d1.dokpropid,
                      coalesce((SELECT sum(summa)
                                FROM docs.avans2
                                WHERE parentid = d1.id), 0) :: NUMERIC(12, 2)        AS summa,
                      d1.jaak                                                        AS jaak,
                      d1.muud                                                        AS muud,
                      coalesce((dp.details :: JSONB ->> 'konto'), '') :: VARCHAR(20) AS konto,
                      dp.selg :: VARCHAR(120)                                        AS dokprop,
                      d1.dokpropid,
                      coalesce(jid.number, 0) :: INTEGER                             AS lausend
                    FROM docs.doc d
                      INNER JOIN docs.avans1 d1 ON d1.parentId = d.id
                      INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                      INNER JOIN libs.asutus a ON a.id = d1.asutusid
                      LEFT OUTER JOIN libs.library l ON l.id = d.doc_type_id
                      LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                      LEFT OUTER JOIN libs.dokprop dp ON dp.id = d1.dokpropid
                      LEFT OUTER JOIN docs.doc dj ON d1.journalid = dj.id
                      LEFT OUTER JOIN docs.journal j ON j.parentid = dj.id
                      LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
                    WHERE d.id = $1`,
            sqlAsNew: `SELECT
                      $1 :: INTEGER                                 AS id,
                      $2 :: INTEGER                                 AS userid,
                      to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT AS created,
                      to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT AS lastupdate,
                      NULL                                         AS bpm,
                      trim(l.nimetus)                               AS doc,
                      trim(l.kood)                                  AS doc_type_id,
                      trim(s.nimetus)                               AS status,
                      coalesce((SELECT max(val(array_to_string(regexp_match(number, '\\d+'),'')))
                       FROM docs.avans1
                       WHERE rekvid in (
                       select rekvid from ou.userid where id = $2)
                       )::integer,0) :: INTEGER + 1                             AS number,
                      NULL::integer                                 AS rekvId,
                      now() :: DATE                                 AS kpv,
                      NULL::TEXT                                    AS selg,
                      NULL::TEXT                                    AS muud,
                      NULL::integer as asutusid,
                      NULL::varchar(20)                             AS regkood,
                      NULL::varchar(254)                            AS asutus,
                      0::numeric(12,2) as summa,
                      0::numeric(12,2)                              AS jaak,
                     null::varchar(120) as  dokprop,
                     null::varchar(20) as konto,
                     0 as doklausid,
                     null::integer as journalid,
                     null::integer as dokpropid,
                     null::integer as lausend
                    FROM libs.library l,
                      libs.library s,
                      (SELECT *
                       FROM ou.userid u
                       WHERE u.id = $2 :: INTEGER) AS u
                    WHERE l.library = 'DOK' AND l.kood = 'AVANS'
                          AND u.id = $2 :: INTEGER
                          AND s.library = 'STATUS' AND s.kood = '0'`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT
                      $2 :: INTEGER    AS userid,
                      trim(n.kood)    AS kood,
                      trim(n.nimetus) AS nimetus,
                      a2.*,
                      coalesce(v.valuuta,'EUR')::varchar(20) as valuuta,
                      coalesce(v.kuurs,1)::numeric(12,4) as kuurs
                    FROM docs.avans1 AS a1
                      INNER JOIN docs.avans2 a2 ON a2.parentid = a1.Id
                      INNER JOIN libs.nomenklatuur n ON n.id = a2.nomid
                      INNER JOIN libs.asutus a ON a.id = a1.asutusid
                      INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                      LEFT OUTER JOIN docs.dokvaluuta1 v ON (v.dokid = a2.id AND v.dokliik = array_position((enum_range(NULL :: DOK_VALUUTA)), 'avans2'))
                      left outer join docs.doc d on a1.journalid = d.id
                      left outer join docs.journal j on j.parentid = d.id
                      left outer join docs.journalid jid on jid.journalid = j.id
                    WHERE a1.parentid = $1`,
            query: null,
            multiple: true,
            alias: 'details',
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
                        FROM cur_eelarve d
                        WHERE d.rekvId = $1
                        and (d.summa <> 0 or d.summa_kassa <> 0)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curEelarve'
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
    saveDoc: `select eelarve.sp_salvesta_eelarve($1, $2, $3) as id`,
    deleteDoc: `select error_code, result, error_message from eelarve.sp_delete_eelarve($1, $2)`, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'kpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {
            name: 'asutusid',
            type: 'I',
        },
        {
            name: 'number',
            type: 'C',
        }

    ],


};

module.exports = Eelarve;
