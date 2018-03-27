module.exports = {
    selectAsLibs: null,
    select: [{
        sql: `select l.id, 
                l.rekvid, 
                l.kood, 
                l.nimetus, 
                l.muud, 
                l.status, 
                l.library, 
                $2::integer as userid, 
                $1::integer as rekv_id,
                'EEL_CONFIG' as doc_type_id
                from libs.library l 
                where l.library = 'KASSAKONTOD'`,
        sqlAsNew: `select  
                    $1::integer as id , 
                    $2::integer as userid, 
                    'EEL_CONFIG' as doc_type_id,
                    null::text as  kood,
                    null::integer as rekvid,
                    null::text as nimetus,
                    'KASSAKONTOD'::text as library,
                    0::integer as status,
                    null::text as muud`,
        query: null,
        multiple: true,
        alias: 'kassa_kontod',
        data: []
    },
        {
            sql: `select l.id, 
                l.rekvid, 
                l.kood, 
                l.nimetus, 
                l.muud, 
                l.status, 
                l.library, 
                $2::integer as userid, 
                $1::integer as rekv_id,
                'EEL_CONFIG' as doc_type_id
                from libs.library l 
                where l.library = 'KASSAKULUD'`,
            query: null,
            multiple: true,
            alias: 'kassa_kulud',
            data: []
        },
        {
            sql: `select l.id, 
                l.rekvid, 
                l.kood, 
                l.nimetus, 
                l.muud, 
                l.status, 
                l.library, 
                $2::integer as userid, 
                $1::integer as rekv_id,
                'EEL_CONFIG' as doc_type_id
                from libs.library l 
                where l.library = 'KULUKONTOD'`,
            query: null,
            multiple: true,
            alias: 'kulu_kontod',
            data: []
        },
        {
            sql: `select l.id, 
                l.rekvid, 
                l.kood, 
                l.nimetus, 
                l.muud, 
                l.status, 
                l.library, 
                $2::integer as userid, 
                $1::integer as rekv_id,
                'EEL_CONFIG' as doc_type_id
                from libs.library l 
                where l.library = 'KASSATULUD'`,
            query: null,
            multiple: true,
            alias: 'kassa_tulud',
            data: []
        },
        {
            sql: `select l.id, 
                l.rekvid, 
                l.kood, 
                l.nimetus, 
                l.muud, 
                l.status, 
                l.library, 
                $2::integer as userid, 
                $1::integer as rekv_id,
                'EEL_CONFIG' as doc_type_id
                from libs.library l 
                where l.library = 'TULUKONTOD'`,
            query: null,
            multiple: true,
            alias: 'tulu_kontod',
            data: []
        }
    ],
    returnData: {
        row: {},
        kassaKontod: [],
        kassaKulud: [],
        kuluKontod: [],
        kassaTulud: [],
        tuluKontod: []
    },
    requiredFields: [
        {name: 'kood', type: 'C'},
        {name: 'library', type: 'C'}
    ],
    saveDoc: `select eelarve.sp_salvesta_eel_config($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: null, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [],
        sqlString:null
    },

};
