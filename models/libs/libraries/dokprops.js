/**
 * Справочник доступныйх профилей контировки для типа документа.
 */
module.exports = {
    select: [{
        sql: `SELECT
              d.id,
              d.selg,
              l.id as parentid,
              l.nimetus                                          AS dok,
              l.rekvid,
              $2 :: INTEGER                                       AS userid,
              coalesce((d.details :: JSONB ->> 'konto'),'') :: VARCHAR(20)    AS konto,
              coalesce((d.details :: JSONB ->> 'kbmkonto'),'') :: VARCHAR(20) AS kbmkonto,
              coalesce((d.details :: JSONB ->> 'kood1'),'') :: VARCHAR(20)    AS kood1,
              coalesce((d.details :: JSONB ->> 'kood2'),'') :: VARCHAR(20)    AS kood2,
              coalesce((d.details :: JSONB ->> 'kood3'),'') :: VARCHAR(20)    AS kood3,
              coalesce((d.details :: JSONB ->> 'kood5'),'') :: VARCHAR(20)    AS kood5,
              coalesce(d.proc_,'')::varchar(20) as proc_,
              d.registr,
              d.vaatalaus,
              d.muud,
              coalesce(d.asutusid,0) as asutusid
            FROM libs.library l
              LEFT OUTER JOIN libs.dokprop d ON l.id = d.parentId
            WHERE d.id = $1`,
        sqlAsNew: `SELECT
              $1::integer as id,
              null::text as selg,
              null::varchar(254) as nimetus,
              null::integer as parentid,
              null::varchar(20) AS dok,
              null::integer as rekvid,
              $2:: INTEGER                                       AS userid,
              null :: VARCHAR(20)    AS konto,
              null :: VARCHAR(20) AS kbmkonto,
              null :: VARCHAR(20)    AS kood1,
              null :: VARCHAR(20)    AS kood2,
              null :: VARCHAR(20)    AS kood3,
              null :: VARCHAR(20)    AS kood5,
              null :: VARCHAR(20)    AS proc_,
              0::integer as registr,
              0::integer as vaatalaus,
              null::text as muud,
              0::integer as asutusid`,
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
            name: 'selg',
            type: 'C'
        },
        {
            name: 'dok',
            type: 'C'
        }
    ],
    saveDoc: `select libs.sp_salvesta_dokprop($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_dokprop($1, $2)`, // $1 - userId, $2 - docId
    selectAsLibs: `SELECT *
                        FROM com_dokprop l
                        WHERE (l.rekvId = $1 OR l.rekvid IS NULL)`,
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "selg", name: "Selgitus", width: "60%"},
            {id: "dok", name: "Dok", width: "30%"}
        ],
        sqlString: `SELECT
                      d.id,
                      d.selg    AS SELG,
                      d.parentid,
                      l.nimetus AS nimetus, 
                      l.kood AS dok
                    FROM libs.library l
                      LEFT OUTER JOIN libs.dokprop d ON l.id = d.parentId
                    WHERE l.library = 'DOK'
                          AND d.status <> 3
                          AND (l.rekvId = $1 OR l.rekvid IS NULL)`,  //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curDokprop'
    },

};
