module.exports = {
    select: [{
        sql: `SELECT h.id,
                     h.isikid,
                     h.kpv,
                     h.summa,
                     h.dokid,
                     h.doktyyp,
                     h.selg,
                     h.rekvid,
                     coalesce(h.muud, '')                                                         AS muud,
                     a.nimetus                                                                    AS isik,
                     CASE
                         WHEN h.doktyyp = 'LAUSEND'
                             THEN (SELECT number FROM cur_journal WHERE id = h.dokid LIMIT 1) END AS number,
                     $2::INTEGER                                                                  AS user_id
              FROM hooldekodu.hooettemaksud h
                       INNER JOIN libs.asutus a ON a.id = h.isikid
              WHERE h.id = $1`,
        sqlAsNew: `SELECT $1::INTEGER                                  AS id,
                          $2::INTEGER                                  AS userid,
                          NULL::INTEGER                                AS isikid,
                          current_date::DATE                           AS kpv,
                          0::NUMERIC(12, 2)                            AS summa,
                          NULL                                         AS dokid,
                          ''                                           AS doktyyp,
                          NULL::TEXT                                   AS selg,
                          (SELECT rekvid FROM ou.userid WHERE id = $2) AS rekvid,
                          ''                                           AS isik,
                          NULL::VARCHAR(20)                            AS number,
                          NULL::TEXT                                   AS muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT h.id,
                         h.kpv,
                         h.isikid,
                         h.ettemaksid,
                         h.journalid,
                         h.dokid,
                         h.doktyyp,
                         h.summa,
                         h.allikas,
                         h.tyyp,
                         h.jaak,
                         h.rekvid,
                         h.muud::VARCHAR(254) AS muud,
                         h.rekvid,
                         hl.osa,
                         'KINNI'::VARCHAR(20) AS status,
                         $2                   AS used_id
                  FROM hooldekodu.hootehingud h
                           INNER JOIN hooldekodu.hooleping hl ON h.isikid = hl.isikid AND hl.status < 3
                  WHERE h.ettemaksid = $1
            `, //$1 id, $2 userid
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        },

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
        sqlString: `SELECT a.*,
                           $2::INTEGER AS userId
                    FROM hooldekodu.cur_hooettemaksud a
                    WHERE a.rekvid = $1`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curHooEttemaksud'
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