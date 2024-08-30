'use strict';

let now = new Date();

const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');

const Journal = {
    select: [
        {
            sql: `SELECT d.id,
                         $2 :: INTEGER                                                                      AS userid,
                         d.docs_ids,
                         (to_char(created, 'DD.MM.YYYY HH:MI:SS')) :: TEXT                                  AS created,
                         (to_char(lastupdate, 'DD.MM.YYYY HH:MI:SS')) :: TEXT                               AS lastupdate,
                         d.bpm,
                         trim(l.nimetus)                                                                    AS doc,
                         trim(l.kood)                                                                       AS doc_type_id,
                         trim(s.nimetus)                                                                    AS status,
                         d.status                                                                           AS doc_status,
                         jid.number                                                                         AS number,
                         j.rekvId,
                         j.kpv                                                                              AS kpv,
                         j.asutusid,
                         trim(j.dok) :: VARCHAR(120)                                                        AS dok,
                         j.selg,
                         j.muud,
                         j.objekt :: VARCHAR(254),
                         (SELECT sum(j1.summa) AS summa
                          FROM docs.journal1 AS j1
                          WHERE parentid = j.id)                                                            AS summa,
                         asutus.regkood,
                         trim(asutus.nimetus)                                                               AS asutus,
                         u.ametnik                                                                          AS kasutaja,
                         (SELECT ametnik
                          FROM ou.userid
                          WHERE rekvid = j.rekvid
                            AND kasutaja = (d.history -> 0 ->> 'user')::VARCHAR(120) LIMIT 1)::VARCHAR(120) AS koostaja
                  FROM docs.doc d
                           INNER JOIN libs.library l ON l.id = d.doc_type_id
                           INNER JOIN docs.journal j ON j.parentId = d.id
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                           LEFT OUTER JOIN docs.journalid jid ON j.Id = jid.journalid
                           LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                           LEFT OUTER JOIN libs.asutus AS asutus ON asutus.id = j.asutusId
                  WHERE d.id = $1`,
            sqlAsNew: `SELECT $1 :: INTEGER                                 AS id,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT AS created,
                              to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT AS lastupdate,
                              NULL :: TEXT []                               AS bpm,
                              'JOURNAL'                                     AS doc,
                              'JOURNAL'                                     AS doc_type_id,
                              ''                                            AS status,
                              0                                             AS doc_status,
                              0 :: INTEGER                               AS number,
                              0 :: INTEGER                               AS rekvId,
                              now() :: DATE                                 AS kpv,
                              0 :: INTEGER                               AS asutusid,
                              '' :: VARCHAR(120)                          AS dok,
                              '' :: TEXT                                  AS selg,
                              NULL :: TEXT                                  AS muud,
                              '' :: VARCHAR(254)                           AS objekt,
                              0 :: NUMERIC                                  AS summa,
                              '' :: VARCHAR(20)                           AS regkood,
                              '' :: VARCHAR(254)                          AS asutus,
                              '' :: VARCHAR(120)                          AS kasutaja,
                              '' :: VARCHAR(120)                          AS koostaja`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT j1.*, $2 :: INTEGER AS userid, 1 :: NUMERIC AS kuurs, 'EUR' :: VARCHAR(20) AS valuuta
                  FROM docs.journal1 AS j1
                           INNER JOIN docs.journal j ON j.id = j1.parentId
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                  WHERE j.parentid = $1
                    AND j1.summa <> 0
                      ORDER BY j1.id DESC`,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        },
        {
            sql: `SELECT d.*
                  FROM docs.get_relative_docs($1::INTEGER) d
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER`,
            query: null,
            multiple: true,
            alias: 'relations',
            data: []
        },
        {
            sql: `SELECT *
                  FROM libs.asutus
                  WHERE regkood = $1
                      ORDER BY staatus
                      LIMIT 1`,
            query: null,
            multiple: false,
            alias: 'validate_asutus',
            data: [],
            not_initial_load: true
        },
        {
            sql: `select docs.sp_kooperi_journal($1::integer, $2::integer, $3::date) as result`,
            query: null,
            multiple: false,
            alias: 'kooperi_journal',
            data: [],
            not_initial_load: true
        },
        {
            sql: `select docs.sp_lausendikontrol($1::JSONB) as result`,
            query: null,
            multiple: false,
            alias: 'validate_journal',
            data: [],
            not_initial_load: true

        },

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
        sqlString: `WITH doc_type AS (
                     SELECT id
                     FROM libs.library
                     WHERE library = 'DOK'
                       AND kood = 'JOURNAL'
                 ),
                  rekv_ids as (
                      SELECT rekv_id FROM get_asutuse_struktuur($1::INTEGER)
                  )
             SELECT to_char(d.created, 'DD.MM.YYYY HH:MI')    AS created,
                    to_char(d.lastupdate, 'DD.MM.YYYY HH:MI') AS lastupdate,
                    s.nimetus                                 AS status,
                    d.id                                      AS id,
                    j.kpv                                     AS kpv,
                    jid.number,
                    j.id                                      AS journalid,
                    j.rekvId,
                    j.asutusid,
                    month(j.kpv) :: INTEGER                   AS kuu,
                    year(j.kpv) :: INTEGER                    AS aasta,
                    regexp_replace(regexp_replace(coalesce(j.selg, ''), '["/]', ' ', 'g'), '/n/r', '',
                                   'g') :: VARCHAR(254)       AS selg,
                    COALESCE(j.dok, '') :: VARCHAR(50)        AS dok,
                    COALESCE(j1.objekt, '') :: VARCHAR(20)    AS objekt,
                    regexp_replace(regexp_replace(replace(coalesce(j.muud, ''), chr(13), ' '), '["/]', ' ', 'g'),
                                   '/n/r', '',
                                   'g') :: VARCHAR(254)       AS muud,
                    j1.deebet,
                    COALESCE(j1.lisa_d, '') :: VARCHAR(20)    AS lisa_d,
                    j1.kreedit,
                    COALESCE(j1.lisa_k, '') :: VARCHAR(20)    AS lisa_k,
                    j1.summa,
                    j1.summa                                  AS valsumma,
                    'EUR' :: VARCHAR(20)                      AS valuuta,
                    1 :: NUMERIC(12, 6)                       AS kuurs,
                    COALESCE(j1.kood1, '') :: VARCHAR(20)     AS kood1,
                    COALESCE(j1.kood2, '') :: VARCHAR(20)     AS kood2,
                    COALESCE(j1.kood3, '') :: VARCHAR(20)     AS kood3,
                    COALESCE(j1.kood4, '') :: VARCHAR(20)     AS kood4,
                    COALESCE(j1.kood5, '') :: VARCHAR(20)     AS kood5,
                    COALESCE(j1.proj, '') :: VARCHAR(20)      AS proj,
                    COALESCE(ltrim(rtrim(a.nimetus)) || ' ' || ltrim(rtrim(a.omvorm)),'') :: VARCHAR(120) AS asutus,
                    COALESCE(j1.tunnus, '') :: VARCHAR(20)    AS tunnus,
                    COALESCE(u.ametnik, '') :: VARCHAR(120)   AS kasutaja,
                    ltrim(rtrim(r.nimetus)):: VARCHAR(254)    AS rekvAsutus
             FROM docs.journal j
                      LEFT JOIN libs.asutus a ON a.id = j.asutusid
                      LEFT OUTER JOIN ou.userid u ON u.id = j.userid,
                  doc_type,
                  docs.doc D,
                  docs.journal1 j1,
                  docs.journalid jid,
                  ou.rekv r,
                  libs.library S
             WHERE D.status <> 3
               AND d.doc_type_id = doc_type.id
               AND j.id = jid.journalid
               AND j.id = j1.parentid
               AND D.id = j.parentid
               and r.id = j.rekvid
               AND S.kood = D.status :: TEXT
               AND S.library = 'STATUS'
               and d.rekvid in (select rekv_id from rekv_ids)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curJournal'
    },
    register: {
        command: `UPDATE docs.doc
                  SET status = 1
                  WHERE id = $1`,
        type: "sql",
        alias: 'registrateDoc'
    },
    endProcess: {
        command: "UPDATE docs.doc SET status = 2 WHERE id = $1",
        type: "sql",
        alias: "end"
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
            max: now.setFullYear(now.getFullYear() + 1),
            period: true
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
    saveDoc: "select docs.sp_salvesta_journal($1::json, $2::integer, $3::integer) as id",
    deleteDoc: `SELECT error_code, result, error_message
                FROM docs.sp_delete_journal($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    executeCommand: {
        command: `SELECT result, error_code, error_message, data
                  FROM sp_execute_task($1 :: INTEGER, $2 :: JSON, $3 :: TEXT)`, //$1- userId, $2 - params, $3 - task
        type: 'sql',
        alias: 'executeTask'
    },
    executeTask: function (task, docId, userId) {
        // выполнит задачу, переданную в параметре

        let executeTask = task;
        if (executeTask.length == 0) {
            executeTask = ['start'];
        }

        let taskFunction = eval(executeTask[0]);
        return taskFunction(docId, userId, Journal);
    },
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
                           SELECT jsonb_array_elements(history) AS ajalugu, d.id, d.rekvid
                           FROM docs.doc d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry`,
        type: "sql",
        alias: "getLogs"
    },
    // import from virasoft
    importDoc: {
        command: `SELECT result AS id, result, error_message, $2::integer as userId, $3::integer as rekvId
                  FROM docs.sp_import_from_virasoft($1::JSONB)`, // $1 - data json, $2 - userid, $3 - rekvid
        type: 'sql',
        alias: 'importRaama'
    },

};

module.exports = Journal;