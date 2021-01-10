/**
 * Справочник доступныйх профилей контировки для типа документа.
 */
module.exports = {
    select: [{
        sql: `SELECT d.id,
                     d.selg,
                     l.id                                                             AS parentid,
                     l.nimetus                                                        AS dok,
                     d.rekvid,
                     $2 :: INTEGER                                                    AS userid,
                     coalesce((d.details :: JSONB ->> 'konto'), '') :: VARCHAR(20)    AS konto,
                     coalesce((d.details :: JSONB ->> 'kbmkonto'), '') :: VARCHAR(20) AS kbmkonto,
                     coalesce((d.details :: JSONB ->> 'kood1'), '') :: VARCHAR(20)    AS kood1,
                     coalesce((d.details :: JSONB ->> 'kood2'), '') :: VARCHAR(20)    AS kood2,
                     coalesce((d.details :: JSONB ->> 'kood3'), '') :: VARCHAR(20)    AS kood3,
                     coalesce((d.details :: JSONB ->> 'kood5'), '') :: VARCHAR(20)    AS kood5,
                     coalesce(d.proc_, '')::VARCHAR(20)                               AS proc_,
                     d.registr,
                     d.vaatalaus,
                     d.muud,
                     coalesce(d.asutusid, 0)                                          AS asutusid
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
    },
        {
            sql: `SELECT *
                  FROM jsonb_to_recordset(
                               fnc_check_libs($2::JSON, $3::DATE, $1::INTEGER))
                           AS x (error_message TEXT)
                  WHERE error_message IS NOT NULL
            `, //$1 rekvid, $2 tunnus, $3 kuupaev
            query: null,
            multiple: true,
            alias: 'validate_libs',
            data: []

        },

    ],
    returnData: {
        row: {}
    },
    requiredFields: [
        {
            name: 'selg',
            type: 'C'
        },
        {
            name: 'parentid',
            type: 'I'
        },

    ],
    saveDoc: `select libs.sp_salvesta_dokprop($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_dokprop($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    selectAsLibs: `SELECT id,
                          nimetus::VARCHAR(254),
                          dok::VARCHAR(20),
                          kood,
                          kbmkonto,
                          kood1,
                          kood2,
                          kood3,
                          kood5,
                          asutusid,
                          rekvid,
                          valid
                   FROM com_dokprop l
                   WHERE (l.rekvId = $1 OR l.rekvid IS NULL)`,
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "selg", name: "Selgitus", width: "60%"},
            {id: "dok", name: "Dok", width: "30%"}
        ],
        sqlString: `SELECT d.id,
                           d.selg::VARCHAR(254)                                               AS SELG,
                           d.parentid,
                           l.nimetus::VARCHAR(254)                                            AS nimetus,
                           l.kood                                                             AS dok,
                           coalesce((d.details ->> 'konto')::VARCHAR(20), '')::VARCHAR(20)    AS konto,
                           coalesce((d.details ->> 'kbmkonto')::VARCHAR(20), '')::VARCHAR(20) AS kbmkonto
                    FROM libs.library l
                             INNER JOIN libs.dokprop d ON l.id = d.parentId
                    WHERE l.library = 'DOK'
                      AND d.status <> 3
                      AND d.rekvId = $1
                    ORDER BY trim(selg)
        `,  //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curDokprop'
    },

};
