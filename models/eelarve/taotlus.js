module.exports = {
    select: [{
        sql: `SELECT d.id,
                     $2 :: INTEGER                                                                 AS userid,
                     to_char(created, 'DD.MM.YYYY HH:MM:SS') :: TEXT                               AS created,
                     to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS') :: TEXT                            AS lastupdate,
                     d.bpm,
                     trim(l.nimetus)                                                               AS doc,
                     trim(l.kood)                                                                  AS doc_type_id,
                     d.status                                                                      AS status,
                     t.status                                                                      AS taotlus_status,
                     t.rekvid,
                     t.koostajaId,
                     t.ametnikId,
                     t.aktseptid,
                     t.kpv,
                     to_char(t.kpv, 'DD.MM.YYYY')::TEXT                                            AS kpv_print,
                     t.number,
                     t.aasta,
                     t.kuu,
                     t.status                                                                      AS taotlus_status,
                     t.allkiri,
                     t.muud,
                     coalesce(t.tunnus, 0)::INTEGER                                                AS tunnus,
                     coalesce(koostaja.ametnik, '') :: VARCHAR(120)                                AS koostaja,
                     coalesce(esitaja.ametnik, '') :: VARCHAR(120)                                 AS esitaja,
                     coalesce(aktsepteerija.ametnik, '') :: VARCHAR(120)                           AS aktseptja,
                     (SELECT sum(summa)
                      FROM eelarve.taotlus1 t1
                      WHERE t1.parentid = t.id)::NUMERIC(12, 2)                                    AS summa,
                     (SELECT sum(summa_kassa)
                      FROM eelarve.taotlus1 t1
                      WHERE t1.parentid = t.id)::NUMERIC(12, 2)                                    AS summa_kassa,
                     (SELECT sum(oodatav_taitmine)
                      FROM eelarve.taotlus1 t1
                      WHERE t1.parentid = t.id)::NUMERIC(12, 2)                                    AS oodatav_taitmine,
                     (to_json($2::INTEGER)::JSONB <@ (d.rigths ->> 'EelKoostaja')::JSONB)::BOOLEAN AS is_koostaja,
                     (to_json($2::INTEGER)::JSONB <@
                      (d.rigths ->> 'EelAktsepterja')::JSONB)::BOOLEAN                             AS is_aktsepterja,
                     (to_json($2::INTEGER)::JSONB <@
                      (d.rigths ->> 'EelAllkirjastaja')::JSONB)::BOOLEAN                           AS is_allkirjastaja,
                     (to_json($2::INTEGER)::JSONB <@ (d.rigths ->> 'Eelesitaja')::JSONB)::BOOLEAN  AS is_esitaja,
                     r.regkood,
                     r.nimetus                                                                     AS asutus
              FROM docs.doc d
                       INNER JOIN libs.library l ON l.id = d.doc_type_id
                       INNER JOIN eelarve.taotlus t ON t.parentId = d.id
                       INNER JOIN ou.rekv r ON r.id = t.rekvid
                       LEFT OUTER JOIN ou.userid koostaja ON t.koostajaid = koostaja.id
                       LEFT OUTER JOIN ou.userid esitaja ON t.ametnikid = esitaja.id
                       LEFT OUTER JOIN ou.userid aktsepteerija ON t.aktseptid = aktsepteerija.id
                       LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
              WHERE d.id = $1`,
        sqlAsNew: `SELECT FALSE                                                                    AS is_koostaja,
                          FALSE                                                                    AS is_aktsepterja,
                          FALSE                                                                    AS is_allkirjastaja,
                          FALSE                                                                    AS is_esitaja,
                          $1 :: INTEGER                                                            AS id,
                          $2 :: INTEGER                                                            AS userid,
                          to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT                            AS created,
                          to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT                            AS lastupdate,
                          NULL                                                                     AS bpm,
                          trim(l.nimetus)                                                          AS doc,
                          trim(l.kood)                                                             AS doc_type_id,
                          0::INTEGER                                                               AS status,
                          0                                                                        AS taotlus_status,
                          0                                                                        AS taotlus_status,
                          docs.sp_get_number(u.rekvId, 'TAOTLUS', year(date()), NULL)::VARCHAR(20) AS number,
                          NULL :: INTEGER                                                          AS rekvId,
                          $2 :: INTEGER                                                            AS koostajaId,
                          u.ametnik :: VARCHAR(120)                                                AS koostaja,
                          NULL :: INTEGER                                                          AS ametnikId,
                          NULL :: INTEGER                                                          AS aktseptid,
                          now() :: DATE                                                            AS kpv,
                          date_part('year', now())                                                 AS aasta,
                          0 :: INTEGER                                                             AS kuu,
                          NULL :: INTEGER                                                          AS allkiri,
                          NULL :: TEXT                                                             AS muud,
                          0 :: INTEGER                                                             AS tunnus,
                          NULL :: VARCHAR(120)                                                     AS esitaja,
                          NULL::VARCHAR(120)                                                       AS aktseptja,
                          0::NUMERIC(12, 2)                                                        AS summa,
                          0::NUMERIC(12, 2)                                                        AS oodatav_taitmine
                   FROM libs.library l,
                        libs.library s,
                        ou.userid u
                   WHERE l.library = 'DOK'
                     AND l.kood = 'TAOTLUS'
                     AND u.id = $2 :: INTEGER
                     AND s.library = 'STATUS'
                     AND s.kood = '0'`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }, {
        sql: `SELECT $2 :: INTEGER                                    AS userid,
                     a.is_kulud,
                     t1.id,
                     t1.parentid,
                     t1.eelprojid,
                     t1.eelarveid,
                     t1.kood1,
                     t1.kood2,
                     t1.kood3,
                     t1.kood4,
                     t1.kood5,
                     t1.proj,
                     coalesce(t1.objekt,'')::varchar(20) as objekt,
                     t1.tunnus,
                     t1.summa,
                     t1.summa_kassa,
                     COALESCE(t1.oodatav_taitmine, 0)::NUMERIC(14, 2) AS oodatav_taitmine,
                     t1.selg,
                     t1.status,
                     t1.markused,
                     t1.muud,
                     coalesce(left(t1.selg, 254), '') :: VARCHAR(254) AS selgrea
              FROM eelarve.taotlus1 t1
                       INNER JOIN eelarve.taotlus t ON t.id = t1.parentid
                       LEFT OUTER JOIN com_artikkel a ON a.kood = t1.kood5
              WHERE t.parentid = $1
              ORDER BY kood1, kood2, kood5, tunnus, proj`,
        query: null,
        multiple: true,
        alias: 'details',
        data: []
    },
        {
            sql: `select eelarve.sp_kooperi_taotlus($1::integer, $2::INTEGER) as id`, //$1 - user_id, $2 doc_id
            query: null,
            multiple: true,
            alias: 'kooperi_taotlus',
            data: []

        },
        {
            sql: `SELECT sum(summa)       AS summa,
                         sum(summa_kassa) AS summa_kassa,
                         tunnus,
                         kood1            AS tegev,
                         kood2            AS allikas,
                         kood3            AS rahavoog,
                         kood5            AS artikkel
                  FROM eelarve.eelarve
                  WHERE aasta = $1::INTEGER
                    AND rekvid = $2::INTEGER
                  GROUP BY tunnus, kood1, kood2, kood3, kood5`, // $1 - aasta, $2 - rekvId
            query: null,
            multiple: true,
            alias: 'oodatav_taitmine',
            data: []
        }
    ],
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'koostajaId', type: 'I'},
        {name: 'aasta', type: 'I'},
        {name: 'kpv', type: 'D'},
        {name: 'number', type: 'C'},
        {name: 'muud', type: 'T'}
    ],
    saveDoc: `select eelarve.sp_salvesta_taotlus($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM eelarve.sp_delete_hoo_config($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    executeCommand: {
        command: `SELECT error_code, result, error_message
                  FROM sp_execute_task($1::INTEGER, $2::JSON, $3::TEXT)`, //$1- userId, $2 - params, $3 - task
        type: 'sql',
        alias: 'executeTask'
    },
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "number", name: "Number", width: "25%"},
            {id: "kpv", name: "Kuupäev", width: "15%"},
            {id: "asutus", name: "Asutus", width: "25%"},
            {id: "koostaja", name: "Koostaja", width: "20%"},
            {id: "summa", name: "Summa", width: "15%"},
            {id: "tunnus", name: "Tunnus", width: "15%"},
            {id: "allikas", name: "Allikas", width: "15%"},
            {id: "artikkel", name: "Artikkel", width: "15%"},
            {id: "tegev", name: "Tegevusalla", width: "15%"},

        ],
        sqlString: `SELECT t.id,
                           t.rekvid,
                           koostajaid,
                           aktseptid,
                           kpv,
                           number::INTEGER,
                           aasta,
                           kuu,
                           t.status AS status,
                           allkiri,
                           kood1,
                           kood2,
                           kood3,
                           kood4,
                           kood5,
                           proj,
                           objekt,
                           tunnus,
                           summa,
                           summa_kassa,
                           oodatav_taitmine,
                           parentid,
                           regkood,
                           nimetus::VARCHAR(254),
                           t.ametnik::VARCHAR(254),
                           rea_selg::TEXT,
                           dok_mark::TEXT
                    FROM cur_taotlused t
                    WHERE t.rekvId IN (SELECT rekv_id
                                       FROM get_asutuse_struktuur($1::INTEGER))
                      AND docs.usersRigths(t.id::INTEGER, 'select', $2::INTEGER)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curTaotlus'
    },
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                                                        AS id,
                         (ajalugu ->> 'user')::VARCHAR(20)                                                           AS kasutaja,
                         coalesce(to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS koostatud,
                         coalesce(to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS muudatud,
                         coalesce(to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS prinditud,
                         coalesce(to_char((ajalugu ->> 'email')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'), '')::VARCHAR(20) AS
                                                                                                                        email,
                         coalesce(to_char((ajalugu ->> 'earve')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS earve,
                         coalesce(to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS kustutatud
                  FROM (
                           SELECT jsonb_array_elements(history) AS ajalugu, d.id, d.rekvid
                           FROM docs.doc d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry
                  WHERE (ajalugu ->> 'user') IS NOT NULL`,
        type: "sql",
        alias: "getLogs"
    },
    print: [
        {
            view: 'taotlus',
            params: 'id',
            register: ``,
        }
    ],
    email: [
        {
            view: 'taotlus_email',
            params: 'id',
            register: ``
        }
    ],

};
