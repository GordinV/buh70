module.exports = {
    select: [{
        sql: `SELECT coalesce(l.rekvid, 0)                                         AS rekvid,
                     CASE
                         WHEN l.tun5 = 1 THEN 'SD'
                         WHEN l.tun5 = 2 THEN 'SK'
                         WHEN l.tun5 = 3 THEN 'D'
                         WHEN l.tun5 = 4 THEN 'K'
                         ELSE NULL END::VARCHAR(20)                                AS konto_tyyp,
                     l.id,
                     trim(l.kood)::VARCHAR(20)                                     AS kood,
                     trim(l.nimetus)::VARCHAR(254)                                 AS nimetus,
                     l.library,
                     l.tun1,
                     l.tun2,
                     l.tun3,
                     l.tun4,
                     l.muud,
                     $2::INTEGER                                                   AS userid,
                     'KONTOD'                                                      AS doc_type_id,
                     l.tun5                                                        AS tyyp,
                     l.status,
                     coalesce((l.properties::JSONB ->> 'kas_virtual')::INTEGER, 0) AS kas_virtual,
                     (l.properties::JSONB ->> 'valid')::DATE                       AS valid
              FROM libs.library l
              WHERE id = $1`,
        sqlAsNew: `select null::integer as rekvId, 
            'SD'::varchar(20) as konto_tyyp, 
            $1::integer as id , $2::integer as userid, 'KONTOD' as doc_type_id,
            null::varchar(20) as  kood,
            null::varchar(20) as nimetus,
            'KONTOD'::text as library,
            null::integer as tun1,
            null::integer as tun2,
            null::integer as tun3,
            null::integer as tun4,
            2 as tyyp,
            0 as status,
            0 as kas_virtual,
            null::text as muud,
            null::date as valid`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT s.*,
                         left(a.nimetus, 120)::VARCHAR AS nimetus
                  FROM libs.subkonto s
                           INNER JOIN libs.asutus a ON a.id = s.asutusid
                           INNER JOIN ou.userid u ON u.id = $2
                  WHERE s.kontoid = $1
                    AND s.rekvid = u.rekvId`,
            query: null,
            multiple: true,
            alias: 'subkonto',
            data: []
        },
        {
            sql: `SELECT $1 AS rekv_id, *
                  FROM jsonb_to_recordset(
                               get_konto_kasutus($2::INTEGER, $3::DATE)
                           ) AS x (error_message TEXT, error_code INTEGER)
                  WHERE error_message IS NOT NULL
            `, //$1 rekvid, $2 v_nom.kood
            query: null,
            multiple: true,
            alias: 'validate_lib_usage',
            data: []
        }

    ],
    selectAsLibs: `SELECT *, $1 AS rekv_id
                   FROM com_kontoplaan l
                   ORDER BY kood`, //where ($1::integer is null or l.rekvId = $1 or l.rekvid is null)
    returnData: {
        row: {}
    },
    requiredFields: [
        {
            name: 'kood',
            type: 'C'
        },
        {
            name: 'nimetus',
            type: 'C'
        }
    ],
    saveDoc: `select libs.sp_salvesta_konto($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_konto($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "konto_tyyp", name: "Konto tüüp", width: "20%"}
        ],
        sqlString: `SELECT id,
                           trim(kood)::VARCHAR(20)        AS kood,
                           trim(nimetus)::VARCHAR(254)    AS nimetus,
                           $2::INTEGER                    AS userId,
                           CASE
                               WHEN l.tun5 = 1 THEN 'SD'
                               WHEN l.tun5 = 2 THEN 'SK'
                               WHEN l.tun5 = 3 THEN 'D'
                               WHEN l.tun5 = 4 THEN 'K'
                               ELSE NULL END::VARCHAR(20) AS konto_tyyp
                    FROM libs.library l
                    WHERE library = 'KONTOD'
                      AND l.status <> 3`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curKontod'
    },

};
