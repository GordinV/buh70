'use strict';

let now = new Date();

const Tulud = {
    select: [
        {
            sql: `SELECT
                    e.id,
                    $2 AS userid,
                    e.rekvid,
                    e.aasta,
                    e.kuu,
                    e.summa,
                    e.muud,
                    e.kood1::varchar(20) as kood1 ,
                    e.kood2::varchar(20) as kood2,
                    e.kood3::varchar(20) as kood3,
                    e.kood4::varchar(20) as kood4,
                    e.kood5::varchar(20) as kood5,
                    e.tunnus,
                    e.is_parandus,
                    coalesce(e.is_kulud,0)::integer as is_kulud,
                    e.kpv  as kpv,
                    'EUR' as valuuta,
                    1::numeric as kuurs,
                    (enum_range(NULL :: DOK_STATUS))[e.status]::varchar(20) as dok_status
                    FROM eelarve.tulud e
                    WHERE e.id = $1`,
            sqlAsNew: `SELECT
                      $1 :: INTEGER                                 AS id,
                      $2 :: INTEGER                                 AS userid,
                      0::integer as rekvid,
                      extract(year from current_date)::integer as aasta,
                      0::integer as kuu,
                      0::numeric(12,2) as summa,
                      null::text as muud,
                      null::varchar(20) as kood1,
                      null::varchar(20) as kood2,
                      null::varchar(20) as kood3,
                      null::varchar(20) as kood4,
                      null::varchar(20) as kood5,
                      null::date as kpv,
                      null::varchar(20) as tunnus,
                      'EUR'::varchar(20) as valuuta,
                      1::numeric(12,4) as kuurs,
                      'new' as dok_status,
                      null::date as kpv,
                      0 as is_paranadus,
                      0 as is_kulud`,
            query: null,
            multiple: false,
            alias: 'row',
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
                          d.*,
                          'TULUD'::varchar(20) as liik
                        FROM cur_tulud d
                        WHERE d.rekvId in (select rekv_id from get_asutuse_struktuur($1::integer))`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
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
    saveDoc: `select docs.sp_salvesta_eelarve($1::json, $2::integer, $3::integer) as id`,
    deleteDoc: `select error_code, result, error_message from eelarve.sp_delete_eelarve($1::integer, $2::integer, 0)`, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'summa',
            type: 'N',
        },
        {
            name: 'kood5',
            type: 'C',
        },
        {
            name: 'aasta',
            type: 'I',
        }


    ]
};

module.exports = Tulud;
