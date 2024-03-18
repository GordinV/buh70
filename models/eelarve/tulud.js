'use strict';

let now = new Date();

const Tulud = {
    select: [
        {
            sql: `SELECT e.id,
                         $2                                                      AS userid,
                         e.rekvid,
                         e.aasta,
                         e.kuu,
                         e.summa,
                         e.summa_kassa,
                         e.muud,
                         e.kood1::VARCHAR(20)                                    AS kood1,
                         e.kood2::VARCHAR(20)                                    AS kood2,
                         e.kood3::VARCHAR(20)                                    AS kood3,
                         e.kood4::VARCHAR(20)                                    AS kood4,
                         e.kood5::VARCHAR(20)                                    AS kood5,
                         t1.objekt::VARCHAR(20)                                  AS objekt,
                         e.tunnus,
                         e.is_parandus,
                         coalesce(e.is_kulud, 0)::INTEGER                        AS is_kulud,
                         e.kpv                                                   AS kpv,
                         'EUR'                                                   AS valuuta,
                         1::NUMERIC                                              AS kuurs,
                         (enum_range(NULL :: DOK_STATUS))[e.status]::VARCHAR(20) AS dok_status
                  FROM eelarve.tulud e
                           LEFT OUTER JOIN eelarve.taotlus1 t1 ON t1.eelarveid = e.id
                  WHERE e.id = $1`,
            sqlAsNew: `SELECT $1 :: INTEGER                            AS id,
                              $2 :: INTEGER                            AS userid,
                              0::INTEGER                               AS rekvid,
                              extract(YEAR FROM current_date)::INTEGER AS aasta,
                              0::INTEGER                               AS kuu,
                              0::NUMERIC(12, 2)                        AS summa,
                              0::NUMERIC(12, 2)                        AS summa_kassa,
                              NULL::TEXT                               AS muud,
                              NULL::VARCHAR(20)                        AS kood1,
                              NULL::VARCHAR(20)                        AS kood2,
                              NULL::VARCHAR(20)                        AS kood3,
                              NULL::VARCHAR(20)                        AS kood4,
                              NULL::VARCHAR(20)                        AS kood5,
                              NULL::DATE                               AS kpv,
                              NULL::VARCHAR(20)                        AS tunnus,
                              'EUR'::VARCHAR(20)                       AS valuuta,
                              1::NUMERIC(12, 4)                        AS kuurs,
                              'new'                                    AS dok_status,
                              NULL::DATE                               AS kpv,
                              0                                        AS is_paranadus,
                              0                                        AS is_kulud`,
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
        sqlString: `SELECT d.*,
                           'TULUD'::VARCHAR(20) AS liik
                    FROM cur_tulud d
                    WHERE d.rekvId IN (SELECT rekv_id FROM get_asutuse_struktuur($1::INTEGER))
                      AND (d.summa <> 0 OR d.summa_kassa <> 0)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
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
    deleteDoc: `SELECT error_code, result, error_message
                FROM eelarve.sp_delete_eelarve($1::INTEGER, $2::INTEGER, 0)`, // $1 - userId, $2 - docId
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
