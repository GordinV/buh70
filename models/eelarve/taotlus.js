module.exports = {
    select: [{
        sql: `SELECT
                  d.id,
                  $2 :: INTEGER                                        AS userid,
                  to_char(created, 'DD.MM.YYYY HH:MM:SS') :: TEXT     AS created,
                  to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS') :: TEXT  AS lastupdate,
                  d.bpm,
                  trim(l.nimetus)                                     AS doc,
                  trim(l.kood)                                        AS doc_type_id,
                  trim(s.nimetus)                                     AS status,
                  d.status                                            AS doc_status,
                  t.rekvid,
                  t.koostajaId,
                  t.ametnikId,
                  t.aktseptid,
                  t.kpv,
                  t.number,
                  t.aasta,
                  t.kuu,
                  t.status as taotlus_status,
                  t.allkiri,
                  t.muud,
                  t.tunnus,
                  coalesce(koostaja.ametnik, '') :: VARCHAR(120)      AS koostaja,
                  coalesce(esitaja.ametnik, '') :: VARCHAR(120)       AS esitaja,
                  coalesce(aktsepteerija.ametnik, '') :: VARCHAR(120) AS aktseptja,
                  (select sum(summa) from eelarve.taotlus1 t1  where t1.parentid = t.id)::numeric(12,2) as summa,
                  (to_json($2::integer)::jsonb <@ (d.rigths ->>'EelKoostaja')::jsonb)::boolean as is_koostaja,
                  (to_json($2::integer)::jsonb <@ (d.rigths ->>'EelAktsepterja')::jsonb)::boolean as is_aktsepterja,
                  (to_json($2::integer)::jsonb <@ (d.rigths ->>'EelAllkirjastaja')::jsonb)::boolean as is_allkirjastaja,
                  (to_json($2::integer)::jsonb <@ (d.rigths ->>'Eelesitaja')::jsonb)::boolean as is_esitaja
                FROM docs.doc d
                  INNER JOIN libs.library l ON l.id = d.doc_type_id
                  INNER JOIN eelarve.taotlus t ON t.parentId = d.id
                  LEFT OUTER JOIN ou.userid koostaja ON t.koostajaid = koostaja.id
                  LEFT OUTER JOIN ou.userid esitaja ON t.ametnikid = esitaja.id
                  LEFT OUTER JOIN ou.userid aktsepteerija ON t.aktseptid = aktsepteerija.id
                  LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                WHERE d.id = $1`,
        sqlAsNew: `SELECT
                      false as is_koostaja,
                      false as is_aktsepterja,
                      false as is_allkirjastaja,
                      false as is_esitaja,
                      $1 :: INTEGER                                               AS id,
                      $2 :: INTEGER                                               AS userid,
                      to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT               AS created,
                      to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT               AS lastupdate,
                      NULL                                                        AS bpm,
                      trim(l.nimetus)                                             AS doc,
                      trim(l.kood)                                                AS doc_type_id,
                      trim(s.nimetus)                                             AS status,
                      0                                                           AS doc_status,
                      0 as taotlus_status,
                      docs.sp_get_number(u.rekvId, 'TAOTLUS', year(date()), NULL) AS number,
                      NULL :: INTEGER                                             AS rekvId,
                      $2 :: INTEGER                                             AS koostajaId,
                      NULL :: INTEGER                                             AS ametnikId,
                      NULL :: INTEGER                                             AS aktseptid,
                      now() :: DATE                                               AS kpv,
                      date_part('year', now())                                    AS aasta,
                      0 :: INTEGER                                                AS kuu,
                      NULL :: INTEGER                                             AS allkiri,
                      NULL :: TEXT                                                AS muud,
                      NULL :: INTEGER                                             AS tunnus,
                      NULL :: VARCHAR(120)                                        AS koostaja,
                      NULL :: VARCHAR(120)                                        AS esitaja,
                      null::varchar(120) as aktseptja,
                      0::numeric(12,2) as summa
                    FROM libs.library l, libs.library s, ou.userid u
                    WHERE l.library = 'DOK' AND l.kood = 'TAOTLUS'
                          AND u.id = $2 :: INTEGER
                          AND s.library = 'STATUS' AND s.kood = '0'`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }, {
        sql: `select $2::integer as userid, 
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
                  t1.tunnus,
                  t1.summa,
                  t1.selg,
                  t1.status,
                  t1.markused,
                  t1.muud,
                  coalesce(left(t1.selg,254),'')::varchar(254) as selgrea
                FROM eelarve.taotlus1 t1
                inner join eelarve.taotlus t on t.id = t1.parentid
                WHERE t.parentid = $1
                ORDER BY kood1, kood2, kood5`,
        query: null,
        multiple: true,
        alias: 'details',
        data: []
    }],
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'summa', type: 'N'},
        {name: 'koostajaId', type: 'I'},
        {name: 'aasta', type: 'I'},
        {name: 'kpv', type: 'D'}
    ],
    saveDoc: `select eelarve.sp_salvesta_taotlus($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from eelarve.sp_delete_taotlus($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    executeCommand: {
        command: `select error_code, result, error_message from sp_execute_task($1::integer, $2::JSON, $3::TEXT )`, //$1- userId, $2 - params, $3 - task
        type:'sql',
        alias:'executeTask'
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
        sqlString: `SELECT       
                      id,
                      rekvid,
                      koostajaid,
                      aktseptid,
                      kpv,
                      number,
                      aasta,
                      kuu,
                      status as status,
                      allkiri,
                      kood1,
                      kood2,
                      kood3,
                      kood4,
                      kood5,
                      tunnus,
                      summa,
                      parentid,
                      regkood,
                      nimetus::varchar(254),
                      ametnik::varchar(254)
                        FROM cur_taotlused t
                        WHERE t.rekvId IN (SELECT rekv_id
                            FROM get_asutuse_struktuur($1))
                            and docs.usersRigths(t.id, 'select', $2)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curTaotlus'
    },

};
