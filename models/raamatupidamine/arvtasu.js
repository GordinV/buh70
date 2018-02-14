/**
 * Справочник доступныйх профилей контировки для типа документа.
 */
module.exports = {
    select: [{
        sql: `SELECT
                  a.id,  
                  $2 :: INTEGER                                       AS userid,
                  a.rekvid,
                  a.doc_arv_id,
                  a.doc_tasu_id,
                  a.kpv,
                  a.summa,
                  a.dok,
                  a.pankkassa,
                  a.muud,
                  (case when a.pankkassa = 3 then 'JOURNAL' when a.pankkassa = 1 then 'MK' when a.pankkassa = 2 then 'KASSA' end)::text as dok_type,
                  (case when a.pankkassa = 3 then j.number::text when a.pankkassa = 1 then m.number when a.pankkassa = 2 then k.number end)::text as number,
                  coalesce(v.kuurs,1)::numeric(12,4) as kuurs, 
                  coalesce(v.valuuta,'EUR')::varchar(20) as valuuta
                FROM docs.arvtasu a
                LEFT OUTER JOIN docs.journalid j on j.journalid = a.doc_tasu_id
                LEFT OUTER JOIN docs.mk m on m.id = a.doc_tasu_id
                LEFT OUTER JOIN docs.korder1 k on k.id = a.doc_tasu_id
                LEFT JOIN docs.dokvaluuta1 v ON a.id = v.dokid AND v.dokliik = 10
                WHERE a.id = $1`,
        sqlAsNew: `SELECT
                      $1::integer as id,
                      $2 :: INTEGER                                       AS userid,
                      null::integer as rekvid,
                      null::integer as doc_arv_id,
                      null::integer as doc_tasu_id,
                      now()::date as kpv,
                      0::numeric(14,2) as summa,
                      null::text as dok,
                      0 as pankkassa,
                      null::text as muud,
                      null::text as dok_type,
                      null::text as number,
                      1::numeric(12,4) as kuurs,
                      'EUR'::varchar(20) as valuuta`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    returnData: {
        row: {}
    },
    requiredFields: [
        {
            name: 'doc_arv_id',
            type: 'I'
        },
        {
            name: 'summa',
            type: 'N'
        }

    ],
    saveDoc: `select docs.sp_salvesta_arvtasu($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from docs.sp_delete_arvtasu($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "number", name: "Arve number", width: "30%"},
            {id: "dok", name: "Dok", width: "30%"},
            {id: "summa", name: "Summa", width: "20%"},
            {id: "asutus", name: "Asutus", width: "40%"},
        ],
        sqlString: `SELECT * 
                    FROM cur_arvtasud a
                    WHERE (a.rekvId = $1 OR a.rekvid IS NULL)`,  //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curArvTasud'
    },

};
