'use strict';
//var co = require('co');
let now = new Date();

const Teatis = {
    select: [
        {
            sql: `WITH
                      params as (
                                    SELECT
                                        $1:: INTEGER as id,
                                        $2:: INTEGER as user_id
                                ),
                      teatis AS (
                                    SELECT
                                        t.number,
                                        t.kpv,
                                        to_char(t.kpv, 'DD.MM.YYYY')                         as print_kpv,
                                        t.asutusid,
                                        t.parentid                                           AS id,
                                        t.sisu,
                                        t.muud,
                                        d.docs_ids,
                                        to_char(d.created, 'DD.MM.YYYY HH:MM:SS') :: TEXT    AS created,
                                        to_char(d.lastupdate, 'DD.MM.YYYY HH:MM:SS') :: TEXT AS lastupdate,
                                        d.status                                             AS doc_status,
                                        d.rekvid,
                                        d.history -> 0 ->> 'user'                            AS koostaja,
                                        r.muud                                               as tais_nimetus,
                                        r.tel                                                as rekv_tel,
                                        r.email                                              as rekv_email,
                                        r.aadress                                            as rekv_aadress,
                                        r.regkood                                            as rekv_regkood
                                    FROM
                                        docs.teatis t,
                                        docs.doc    d,
                                        ou.rekv     r,
                                                    params
                                    where
                                          t.parentid = params.id
                                      and d.id = params.id
                                      and r.id = d.rekvid
                                ),
                      arved as (
                                    select
                                        jsonb_build_object('kokku',
                                                           sum(a.jaak) over (),
                                                           'number', a.number,
                                                           'kpv', to_char(a.kpv, 'DD.MM.YYYY'),
                                                           'viitenr', lapsed.get_viitenumber(a.rekvid, l.parentid),
                                                           'rekvid', a.rekvid,
                                                           'jaak', a.jaak)                              as arve,
                                        teatis.id,
                                        array_agg(lapsed.get_viitenumber(a.rekvid, l.parentid)) over () as lapsed
                                    from
                                        docs.arv                                a
                                            left outer join lapsed.liidestamine l on l.docid = a.parentid,
                                                                                teatis
                                    where
                                        a.parentid in (
                                                          select
                                                              unnest(docs_ids)
                                                          from
                                                              teatis
                                                      )
                                    order by l.parentid, a.kpv
                                )
                  SELECT
                      t.id,
                      t.created,
                      t.lastupdate,
                      t.doc_status,
                      t.number::TEXT                                                                             AS number,
                      t.rekvId,
                      to_char(t.kpv, 'YYYY-MM-DD')::TEXT                                                         AS kpv,
                      to_char(t.kpv, 'DD.MM.YYYY')::TEXT                                                         AS kpv_print,
                      t.asutusid,
                      asutus.regkood,
                      asutus.nimetus::TEXT                                                                       AS asutus,
                      asutus.aadress,
                      asutus.email::TEXT                                                                         AS email,
                      t.koostaja,
                      to_char(current_date, 'DD.MM.YYYY HH:MM:SS')                                               AS print_aeg,
                      t.sisu,
                      t.muud,
                      to_jsonb(array(SELECT arve FROM arved a WHERE a.id = t.id))                                AS arved,
                      to_jsonb(get_unique_value_from_array(array(SELECT lapsed FROM arved a WHERE a.id = t.id))) as lapsed,
                      t.tais_nimetus,
                      t.rekv_tel,
                      t.rekv_aadress,
                      t.rekv_regkood,
                      t.rekv_email
                  FROM
                      teatis                        t
                          INNER JOIN libs.asutus AS asutus ON asutus.id = t.asutusId,
                                                    params
                  WHERE
                      t.id = params.id`,
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
    multiple_print_doc: {
        command: `WITH params AS (
                        SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER AS ids,
                            $2::integer as user_id                               
                    ),                    
                         arved AS (
                             SELECT jsonb_build_object('kokku',
                                                       sum(a.jaak) OVER (PARTITION BY a.asutusid),
                                                       'number', a.number,
                                                       'kpv', to_char(a.kpv, 'DD.MM.YYYY'),
                                                       'viitenr', lapsed.get_viitenumber(a.rekvid, l.parentid),
                                                       'rekvid', a.rekvid,
                                                       'jaak', a.jaak) AS arve,
                                    lapsed.get_viitenumber(a.rekvid, l.parentid) as laps,                                
                                    a.parentid                         AS id
                                    
                             FROM docs.arv a
                                      LEFT OUTER JOIN lapsed.liidestamine l ON l.docid = a.parentid
                                 WHERE
                                  a.parentid IN (
                                      SELECT unnest(t.docs)
                                      FROM docs.teatis t
                                      where t.parentid in (SELECT ids FROM params)
                                  )
                                     
                         )
                        SELECT
                         t.id,
                         t.number :: TEXT,
                         t.rekvid,
                         to_char(t.kpv, 'DD.MM.YYYY') :: TEXT AS kpv,
                         t.asutus :: TEXT AS asutus,
                         t.regkood::text as regkood,
                         t.aadress::text as aadress,
                         t.email::text as email,
                         to_char(t.saadetud, 'DD.MM.YYYY') AS saadetud,
                         to_char(t.print, 'DD.MM.YYYY HH24:MI:SS') AS print,
                         to_jsonb(array((SELECT arve
                                         FROM arved WHERE arved.id IN (SELECT unnest(t.docs))))) AS arved,
                         to_jsonb(get_unique_value_from_array(array(SELECT laps as lapsed FROM arved a WHERE a.id IN (SELECT unnest(t.docs))))) as lapsed,
                            
                        r.muud as tais_nimetus,
                        r.tel as rekv_tel,
                        r.email as rekv_email,
                        r.aadress as rekv_aadress,
                        r.regkood as rekv_regkood,                                         
                         TRUE AS select
                        FROM cur_teatised t
                             INNER JOIN ou.rekv r ON r.id = t.rekvid
                        WHERE  t.id IN (SELECT ids FROM params)`
    },
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "number", name: "Number", width: "10%"},
            {id: "kpv", name: "Kuupaev", width: "15%", type: "date", interval: true},
            {id: "asutus", name: "Saaja", width: "30%"},
            {id: "saadetud", name: "Saadetud", width: "15%", type: "date", interval: true},
            {id: "print", name: "Trükitud", width: "15%", type: "date", interval: true},
            {id: "select", name: "Valitud", width: "10%", show: false}

        ],
        sqlString: `WITH params AS (
                        SELECT $1::integer AS rekv_id,
                               $2::integer  AS user_id
                    ) SELECT
                         t.id,
                         t.number :: TEXT,
                         t.rekvid,
                         to_char(t.kpv, 'DD.MM.YYYY') :: TEXT AS kpv,
                         params.user_id::INTEGER AS userId,
                         t.asutus :: TEXT AS asutus,
                         to_char(t.saadetud, 'DD.MM.YYYY') AS saadetud,
                         to_char(t.print, 'DD.MM.YYYY HH24:MI:SS') AS print,
                        r.muud as tais_nimetus,
                        r.tel as rekv_tel,
                        r.email as rekv_email,
                        r.aadress as rekv_aadress,
                        r.regkood as rekv_regkood,                                         
                         TRUE AS select
                        FROM cur_teatised t,
                         params,
                         ou.rekv r 
                        WHERE r.id = t.rekvId
                         and t.rekvId = params.rekv_id::INTEGER`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
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
                  FROM docs.koosta_teatis($1::INTEGER, $2::DATE)`, //$1  - userId, $2 - seisuga
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
                               WHERE
                                d.id = $1
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
                                      FROM (SELECT now()                                AS print,
                                                   (SELECT kasutaja
                                                    FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                       WHERE id = $1`
        },
        {
            view: 'teatis_register',
            params: 'sqlWhere'
        },
    ],
    email: [
        {
            view: 'teatis_kaart',
            params: 'id',
            register: `UPDATE docs.doc
                       SET history = history ||
                                     (SELECT row_to_json(row)
                                      FROM (SELECT now()                                AS email,
                                                   (SELECT kasutaja
                                                    FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                       WHERE id = $1`
        }
    ],

};

module.exports = Teatis;

