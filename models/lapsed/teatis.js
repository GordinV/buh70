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
                                                           'lapse_nimi', laps.nimi,
                                                           'rekvid', a.rekvid,
                                                           'jaak', a.jaak)                              as arve,
                                        teatis.id,
                                        array_agg(lapsed.get_viitenumber(a.rekvid, l.parentid)) over () as lapsed
                                    from
                                        docs.arv                                a
                                            left outer join lapsed.liidestamine l on l.docid = a.parentid
                                            left outer join lapsed.laps         laps on laps.id = l.parentid,
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
                           LEFT OUTER JOIN docs.doc rd ON rd.id = any (d.docs_ids)
                           LEFT OUTER JOIN libs.library l ON rd.doc_type_id = l.id
                           LEFT OUTER JOIN docs.arv a ON a.parentid = rd.id
                      WHERE d.id = $1 :: INTEGER`,
            query: null,
            multiple: true,
            alias: 'relations',
            data: []
        },

    ],
    multiple_print_doc: {
        command: `WITH
                      params as (
                                    SELECT
                                        make_date(year(current_date), month(current_date), 1) AS kpv1,
                                        get_last_day(current_date)                            AS kpv2,
                                        string_to_array($1::text, ',')::INTEGER[]             AS ids,
                                        $2::integer                                           as user_id
                                ),
                      teatised as (
                                    SELECT
                                        d.id,
                                        t.number,
                                        t.kpv,
                                        to_char(t.kpv, 'DD.MM.YYYY')                         as print_kpv,
                                        t.asutusid,
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
                                        docs.teatis                t
                                            INNER JOIN docs.doc    d ON t.parentid = d.id
                                            inner join libs.asutus a on a.id = t.asutusid
                                            inner join ou.rekv     r on r.id = d.rekvid
                                      ,                            params
                                    WHERE
                                          d.status <> 3
                                      and d.id = any (params.ids)
                                      and d.history::text not ilike '%"email"%'
                                      and d.history::text not ilike '%"email_error"%'
                                      and d.history::text not ilike '%"email_error_3"%'
                                      AND d.rekvid IN (
                                                          SELECT
                                                              id
                                                          FROM
                                                              ou.rekv
                                                          WHERE
                                                              parentid = 119
                                                      )
                                ),

                      arved as (
                                    with
                                        arvete_info as (
                                                           select
                                                               sum(a.jaak) over (partition by t.id)         as jaak_kokku,
                                                               a.jaak,
                                                               a.number,
                                                               to_char(a.kpv, 'DD.MM.YYYY')                 as kpv,
                                                               lapsed.get_viitenumber(a.rekvid, l.parentid) as viitenr,
                                                               laps.nimi                                    as lapse_nimi,
                                                               a.rekvid                                     as rekvid,
                                                               t.id                                         as teatis_id
                                                           from
                                                               docs.arv                                a
                                                                   inner join      teatised            t on a.parentid = any (t.docs_ids)
                                                                   left outer join lapsed.liidestamine l on l.docid = a.parentid
                                                                   left outer join lapsed.laps         laps on laps.id = l.parentid

                                        )
                                    select
                                        jsonb_agg(jsonb_build_object('kokku', a.jaak_kokku,
                                                                     'number', a.number,
                                                                     'kpv', a.kpv,
                                                                     'viitenr', a.viitenr,
                                                                     'lapse_nimi', a.lapse_nimi,
                                                                     'rekvid', a.rekvid,
                                                                     'jaak', a.jaak)) as arve,
                                        a.teatis_id                                   as teatis_id,
                                        array_agg(a.viitenr)                          as lapsed
                                    from
                                        arvete_info a
                                    group by a.teatis_id
                                )

                  SELECT
                      t.id,
                      t.created,
                      t.lastupdate,
                      t.doc_status,
                      t.number::TEXT                                                                                    AS number,
                      t.rekvId,
                      to_char(t.kpv, 'YYYY-MM-DD')::TEXT                                                                AS kpv,
                      to_char(t.kpv, 'DD.MM.YYYY')::TEXT                                                                AS kpv_print,
                      t.asutusid,
                      asutus.regkood,
                      asutus.nimetus::TEXT                                                                              AS asutus,
                      asutus.aadress,
                      asutus.email::TEXT                                                                                AS email,
                      t.koostaja,
                      to_char(current_date, 'DD.MM.YYYY HH:MM:SS')                                                      AS print_aeg,
                      t.sisu,
                      t.muud,
                      to_jsonb((
                                   SELECT arve
                                   FROM arved a
                                   WHERE a.teatis_id = t.id
                               ))                                                                                       AS arved,
                      to_jsonb(get_unique_value_from_array(array(SELECT lapsed FROM arved a WHERE a.teatis_id = t.id))) as lapsed,
                      t.tais_nimetus,
                      t.rekv_tel,
                      t.rekv_aadress,
                      t.rekv_regkood,
                      t.rekv_email
                  FROM
                      teatised                      t
                          INNER JOIN libs.asutus AS asutus ON asutus.id = t.asutusId,
                                                    params
        `
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
    multiple_print: [
        {
            view: 'teatis_kaartid',
            params: 'id',
            register: `UPDATE docs.doc
                       SET history = history ||
                                     (SELECT row_to_json(row)
                                      FROM (SELECT now()                                                AS print,
                                                   (SELECT kasutaja FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                       WHERE id IN (
                           SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER
                       )`
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
                       SET
                           history = history ||
                                     (
                                         SELECT
                                             row_to_json(row)
                                         FROM
                                             (
                                                 SELECT
                                                     now()   AS email,
                                                     $3      AS aadress,
                                                     (
                                                         SELECT
                                                             kasutaja
                                                         FROM
                                                             ou.userid
                                                         WHERE
                                                             id = $2
                                                     )::TEXT AS user
                                             ) row
                                     )::JSONB
                       WHERE
                           id = $1`,
            register_error: `Select docs.register_email_error($1::INTEGER,$3::TEXT, $2::INTEGER)`,
            log: `INSERT INTO
                      ou.logs (rekvid, user_id, doc_id, timestamp, propertis)
                  SELECT
                      (
                          SELECT rekvid
                          FROM ou.userid
                          WHERE id = $2
                          LIMIT 1
                      )  AS rekv_id,
                      $2 AS user_id,
                      $1 AS doc_id,
                      now(),
                      jsonb_build_object('table', 'teatis', 'event', 'email', 'info', $3::JSONB)`

        }
    ],

};

module.exports = Teatis;

