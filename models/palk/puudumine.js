module.exports = {
    select: [{
        sql: `SELECT
                  $2 :: INTEGER            AS userid,
                 'PUUDUMINE' AS doc_type_id,
                  p.id,
                  p.lepingid,
                  p.libid,
                  p.summa,
                  p.kpv1,
                  p.kpv2,
                  p.paevad,
                  p.puudumiste_liik::varchar(20),
                  p.tyyp,
                  p.status,
                  p.muud,
                  t.parentid
                FROM palk.puudumine p
                inner join palk.tooleping t on t.id = p.lepingid
                WHERE p.id = $1`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER        AS id,
                      $2 :: INTEGER        AS userid,
                      'PUUDUMINE'        AS doc_type_id,
                      0::integer          as parentid,
                      0 :: INTEGER        AS lepingid,
                      0 :: INTEGER        AS libid,
                      0 :: NUMERIC(14, 4) AS summa,
                      now()::date as kpv1,
                      now()::date as kpv2,
                      0::integer as paevad,
                      'PUHKUS'::varchar(20) as puudumiste_liik,
                      0 as tyyp,
                      1 as status,
                      null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql:`select id, liik::varchar(20), eesti::varchar(120), vene::varchar(120) 
                    from palk.com_puudumiste_tyyp`,
            query: null,
            multiple: true,
            alias: 'com_puudumised',
            data: []

        },
        {
            sql: `SELECT *
                  FROM
                      jsonb_to_recordset((
                                             SELECT
                                                 p.data
                                             from
                                                 palk.sp_import_puudumine_from_virosoft($2::integer,$3::integer, $1::JSONB) p
                                         )
                      )
                          AS x (error_message TEXT, error_code INTEGER, result INTEGER)`,
            query: null,
            multiple: false,
            alias: 'importDok',
            data: [],
            not_initial_load: true
        },

    ],
    returnData: {
        row: {},
        comPuudumised: []
    },
    requiredFields: [
        {name: 'puudumiste_liik', type: 'I'},
        {name: 'tyyp', type: 'I'},
        {name: 'lepingid', type: 'I'},
        {name: 'kpv1', type: 'D'},
        {name: 'kpv2', type: 'D'},
        {name: 'paev', type: 'I'},
        {name: 'summa', type: 'N'}

    ],
    saveDoc: `select palk.sp_salvesta_puudumine($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from palk.sp_delete_puudumine($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "isik", name: "Isik", width: "25%"},
            {id: "amet", name: "Amet", width: "15%"},
            {id: "kpv1", name: "Kpv-st", width: "15%"},
            {id: "kpv2", name: "Kpv-ni", width: "15%"},
            {id: "paevad", name: "Päevad", width: "10%"},
            {id: "pohjus", name: "Põhjus", width: "15%"},
            {id: "liik", name: "Liik", width: "15%"},
        ],
        sqlString: `select a.*, $2::integer as userId
            from palk.cur_puudumine a
            where rekvid = $1`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPuudumine'
    },
     executeCommand: {
         command: `select error_code, result, error_message from palk.sp_calc_puhkuse_paevad($1, $2)`, //$1 - user_id, $2 - params (lepingid, tyyp)
         type: 'sql',
         alias: 'calcPuhkusePaevad'
     },
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                                                        AS id,
                         (qry.ajalugu ->> 'user')::VARCHAR(20)                                                           AS kasutaja,
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
                           SELECT jsonb_array_elements('[]'::jsonb || d.ajalugu) AS ajalugu, d.id
                           FROM palk.puudumine d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry
                  WHERE (qry.ajalugu ->> 'user') IS NOT NULL
        `,
        type: "sql",
        alias: "getLogs"
    },
    importDoc: {
        comment: 'import from virosoft',
        command: `SELECT result AS id, result, error_message, $2::integer as userId, $3::integer as rekvId
                  FROM palk.sp_import_puudumine_from_virosoft($2::integer,$3::integer, $1::JSONB)`, // $1 - data json, $2 - userid, $3 - rekvid
        type: 'sql',
        alias: 'importRaama'
    },

};