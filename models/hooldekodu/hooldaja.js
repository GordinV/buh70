module.exports = {
    select: [{
        sql: `SELECT h.id,
                     h.hooldajaid,
                     h.isikid,
                     h.kohtumaarus,
                     h.algkpv,
                     h.loppkpv,
                     coalesce(h.muud,'') as muud,
                     $2::INTEGER AS user_id
              FROM hooldekodu.hooldaja h
              WHERE id = $1`,
        sqlAsNew: `select $1::integer as id , $2::integer as userid, 
            'HOOLDAJA' as doc_type_id,
            0::integer AS hooldajaid,
            0::integer AS isikid,
            ''::text as  kohtumaarus,
            make_date(year(current_date),01,01)::date  as algkpv,
            make_date(year(current_date),12,31)::date  as loppkpv,
            null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }
    ],
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'hooldajaid', type: 'I'},
        {name: 'isikid', type: 'I'}
    ],
    saveDoc: `select hooldekodu.sp_salvesta_hooldaja($1::jsonb, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM hooldekodu.sp_delete_hooldaja($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "regkood", name: "Reg.kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "omvorm", name: "Om.vorm", width: "20%"},
            {id: "aadress", name: "Aadress", width: "25%"},
            {id: "valid", name: "Kehtivus", width: "10%", type: 'date', show: false},
        ],
        sqlString: `SELECT a.*, $2::INTEGER AS userId, a.kehtivus AS valid
                    FROM cur_asutused a
                    WHERE libs.check_asutus(a.id::INTEGER, $1::INTEGER)`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curAsutused'
    },

    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()              AS id,
                         (ajalugu ->> 'user')::VARCHAR(20) AS kasutaja,
                         coalesce(to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS koostatud,
                         coalesce(to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS muudatud,
                         coalesce(to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS prinditud,
                         coalesce(to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS kustutatud

                  FROM (
                           SELECT jsonb_array_elements('[]'::JSONB || d.ajalugu::JSONB) AS ajalugu, d.id
                           FROM libs.asutus d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry
                  WHERE (ajalugu ->> 'user') IS NOT NULL`,
        type: "sql",
        alias: "getLogs"
    },

};