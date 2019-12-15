'use strict';
//var co = require('co');
let now = new Date();

const Teatis = {
    select: [
        {
            sql: `SELECT d.id,
                         $2 :: INTEGER                                      AS userid,
                         to_char(created, 'DD.MM.YYYY HH:MM:SS') :: TEXT    AS created,
                         to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS') :: TEXT AS lastupdate,
                         d.status                                           AS doc_status,
                         t.number::TEXT                                     AS number,
                         d.rekvId,
                         to_char(t.kpv, 'YYYY-MM-DD')::TEXT                 AS kpv,
                         to_char(t.kpv, 'DD.MM.YYYY')::TEXT                 AS kpv_print,
                         t.asutusid,
                         asutus.regkood,
                         asutus.nimetus::TEXT                               AS asutus,
                         asutus.aadress,
                         asutus.email::TEXT                                 AS email,
                         d.history -> 0 ->> 'user'                          AS koostaja,
                         to_char(current_date, 'DD.MM.YYYY HH:MM:SS')       AS print_aeg,
                         t.sisu,
                         t.muud
                  FROM docs.doc d
                           INNER JOIN docs.teatis t ON t.parentId = d.id
                           INNER JOIN libs.asutus AS asutus ON asutus.id = t.asutusId
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                  WHERE d.id = $1`,
            sqlAsNew: `SELECT $1 :: INTEGER                                                             AS id,
                              $2 :: INTEGER                                                             AS userid,
                              to_char(now(), 'YYYY-MM-DD HH:MM:SS') :: TEXT                             AS created,
                              to_char(now(), 'YYYY-MM-DD HH:MM:SS') :: TEXT                             AS lastupdate,
                              0                                                                         AS doc_status,
                              docs.sp_get_number(u.rekvId, 'TEATIS', year(date()), NULL) :: VARCHAR(20) AS number,
                              NULL :: INTEGER                                                           AS rekvId,
                              to_char(now() :: DATE, 'YYYY-MM-DD')::TEXT                                AS kpv,
                              NULL :: INTEGER                                                           AS asutusid,
                              NULL :: TEXT                                                              AS muud,
                              NULL :: VARCHAR(20)                                                       AS regkood,
                              NULL :: VARCHAR(120)                                                      AS asutus,
                              NULL :: TEXT                                                              AS aadress,
                              NULL :: VARCHAR(120)                                                      AS koostaja,
                              NULL::TEXT                                                                AS sisu
                              `,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT rd.id,
                         $2 :: INTEGER   AS userid,
                         trim(l.kood)    AS doc_type,
                         trim(l.nimetus) AS name,
                         a.number        AS number
                  FROM docs.doc d
                           LEFT OUTER JOIN docs.doc rd ON rd.id IN (SELECT unnest(d.docs_ids))
                           LEFT OUTER JOIN libs.library l ON rd.doc_type_id = l.id
                           LEFT OUTER JOIN docs.arv a ON a.parentid = rd.id
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                  WHERE d.id = $1 :: INTEGER`,
            query: null,
            multiple: true,
            alias: 'relations',
            data: []
        },

    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "number", name: "Number", width: "10%"},
            {id: "kpv", name: "Kuupaev", width: "15%", type: "date", interval: true},
            {id: "asutus", name: "Saaja", width: "30%"},
            {id: "saadetud", name: "Saadetud", width: "15%", type:"date", interval: true },
            {id: "print", name: "Trükitud", width: "15%", type:"date", interval: true },
            {id: "select", name: "Valitud", width: "10%", show: false}

        ],
        sqlString: `SELECT id,
                           number :: TEXT,
                           rekvid,
                           to_char(kpv, 'DD.MM.YYYY') :: TEXT      AS kpv,
                           $2::INTEGER                             AS userId,
                           asutus :: TEXT                          AS asutus,
                           to_char(t.saadetud, 'DD.MM.YYYY')       AS saadetud,
                           to_char(t.print, 'DD.MM.YYYY HH24:MI:SS') AS print,
                           TRUE                                    AS select
                    FROM cur_teatised t
                    WHERE t.rekvId = $1::INTEGER`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curTeatised'
    },
    returnData: {
        row: {},
        relations: [],
    },
    saveDoc: `select docs.sp_salvesta_teatis($1::jsonb, $2::integer, $3::integer) as id`,
    deleteDoc: `SELECT error_code, result, error_message
                FROM docs.sp_delete_teatis($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    koostaTeatis: {
        command: `SELECT error_code, result, error_message, doc_type_id
                  FROM docs.koosta_teatis($1::INTEGER, $2::date)`, //$1  - userId, $2 - seisuga
        type: "sql",
        alias: 'koostaTeatis'
    },

    requiredFields: [
        {
            name: 'kpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {
            name: 'number',
            type: 'C'
        },
        {name: 'asutusid', type: 'N', min: null, max: null}
    ],
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                               AS id,
                         (ajalugu ->> 'user')::TEXT                                         AS kasutaja,
                         to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS') AS koostatud,
                         to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS')   AS prinditud,
                         to_char((ajalugu ->> 'email')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS')   AS email,
                         to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS') AS kustutatud

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

    print: [
        {
            view: 'teatis_kaart',
            params: 'id',
            register: `UPDATE docs.doc
                       SET history = history ||
                                     (SELECT row_to_json(row)
                                      FROM (SELECT now()                                                AS print,
                                                   (SELECT kasutaja FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                       WHERE id = $1`
        },
        {
            view: 'teatis_register',
            params: 'sqlWhere'
        },
    ],
    email: [
        {
            view: 'teatis_email',
            params: 'id',
            register: `UPDATE docs.doc
                       SET history = history ||
                                     (SELECT row_to_json(row)
                                      FROM (SELECT now()                                                AS email,
                                                   (SELECT kasutaja FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                       WHERE id = $1`
        }
    ],

};

module.exports = Teatis;

