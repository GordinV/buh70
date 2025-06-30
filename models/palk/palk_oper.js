'use strict';

let now = new Date();

const PalkOper = {
    select: [
        {
            sql: `SELECT d.id,
                         d.docs_ids,
                         (to_char(d.created, 'DD.MM.YYYY HH:MM:SS')) :: TEXT               AS created,
                         (to_char(d.lastupdate, 'DD.MM.YYYY HH:MM:SS')) :: TEXT            AS lastupdate,
                         d.bpm,
                         trim(l.nimetus)                                                   AS doc,
                         trim(l.kood)                                                      AS doc_type_id,
                         trim(s.nimetus)                                                   AS status,
                         p.kpv                                                             AS kpv,
                         p.rekvid,
                         p.libid,
                         p.lepingid,
                         p.summa,
                         p.tululiik,
                         p.journalid,
                         p.muud,
                         p.kood1,
                         p.kood2,
                         p.kood3,
                         p.kood4,
                         p.kood5,
                         p.konto,
                         p.tp,
                         p.tunnus,
                         p.proj,
                         p.tulumaks,
                         p.sotsmaks,
                         p.tootumaks,
                         p.pensmaks,
                         p.tulubaas,
                         p.tka,
                         p.period,
                         p.pohjus,
                         (p.properties ->> 'pohjus_selg')::VARCHAR(254)                    AS pohjus_selg,
                         (p.properties ->> 'paranduse_kpv')::DATE                          AS paranduse_kpv,
                         coalesce((dp.details :: JSONB ->> 'konto'), '') :: VARCHAR(20)    AS korr_konto,
                         dp.selg :: VARCHAR(120)                                           AS dokprop,
                         (CASE WHEN empty(dp.registr::INTEGER) THEN 0 ELSE 1 END)::INTEGER AS kas_lausend,
                         p.doklausid                                                       AS dokpropid,
                         coalesce(jid.number, 0) :: INTEGER                                AS lausend,
                         t.parentid,
                         (pl.properties::JSONB ->> 'liik')::INTEGER                        AS liik,
                         (pl.properties::JSONB ->> 'asutusest')::INTEGER                   AS asutusest,
                         (d.history -> 0 ->> 'user')::VARCHAR(120)                         AS koostaja,
                         (p.properties ->> 'objekt')::VARCHAR(20)                          as objekt,
                         (p.properties ->> 'maksekpv')::DATE                               AS maksekpv,
                         (p.properties ->> 'alus_oper_ids')::text                          as alus_oper_ids,
                         (p.properties ->> 'kas_ettemaks')::boolean                        as kas_ettemaks,
                         (p.properties ->> 'puudumise_id')::integer                        as puudumise_id,
                         (p.properties ->> 'alus_oper_ids')::text                          as alus_oper_ids,
                         (p.properties ->> 'ettemaksu_periood')::date                      as ettemaksu_periood,
                         (p.properties ->> 'ettemaksu_oper_ids')::text                     as ettemaksu_oper_ids

                  FROM docs.doc d
                           INNER JOIN palk.palk_oper p ON p.parentId = d.id
                           INNER JOIN palk.tooleping t ON t.id = p.lepingid
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                           INNER JOIN libs.asutus a ON a.id = t.parentid
                           LEFT OUTER JOIN libs.library pl ON pl.id = p.libid
                           LEFT OUTER JOIN libs.library l ON l.id = d.doc_type_id
                           LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                           LEFT OUTER JOIN libs.dokprop dp ON dp.id = p.doklausid
                           LEFT OUTER JOIN docs.doc dj ON p.journalid = dj.id
                           LEFT OUTER JOIN docs.journal j ON j.parentid = dj.id
                           LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
                  WHERE d.id = $1`,
            sqlAsNew: `SELECT
                          $1 :: INTEGER                                 AS id,
                          $2 :: INTEGER                                 AS userid,
                          to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT AS created,
                          to_char(now(), 'DD.MM.YYYY HH:MM:SS') :: TEXT AS lastupdate,
                          NULL                                          AS bpm,
                          'PALK_OPER'                                   AS doc_type_id,
                          1                                             AS status,
                          NULL :: INTEGER                               AS rekvId,
                          null::integer as lepingid,
                          null::integer as libid,
                          now() :: DATE                                 AS kpv,
                          NULL :: TEXT                                  AS selg,
                          NULL :: TEXT                                  AS muud,
                          0 :: NUMERIC(12, 2)                           AS summa,
                          NULL :: INTEGER                               AS journalid,
                          NULL :: VARCHAR(20)                           AS tululiik,
                          NULL :: VARCHAR(20)                           AS kood1,
                          NULL :: VARCHAR(20)                           AS kood2,
                          NULL :: VARCHAR(20)                           AS kood3,
                          NULL :: VARCHAR(20)                           AS kood4,
                          NULL :: VARCHAR(20)                           AS kood5,
                          NULL :: VARCHAR(20)                           AS konto,
                          NULL :: VARCHAR(20)                           AS proj,
                          NULL :: VARCHAR(20)                           AS tp,
                          NULL :: VARCHAR(20)                           AS tunnus,
                          0 :: NUMERIC(12, 2)                           AS tulumaks,
                          0 :: NUMERIC(12, 2)                           AS sotsmaks,
                          0 :: NUMERIC(12, 2)                           AS tootumaks,
                          0 :: NUMERIC(12, 2)                           AS pensmaks,
                          0 :: NUMERIC(12, 2)                           AS tulubaas,
                          0 :: NUMERIC(12, 2)                           AS tka,
                          NULL :: DATE                                  AS period,
                          NULL :: TEXT                                  AS pohjus,
                          NULL::varchar(254)                            AS pohjus_selg,
                          null::date                                    as paranduse_kpv,
                          NULL :: INTEGER                               AS journalid,
                          null :: VARCHAR(20)                           AS korr_konto,
                          null :: VARCHAR(120)                          AS dokprop,                          
                          NULL :: INTEGER                               AS dokpropid,
                          0::integer                                AS kas_lausend,
                          NULL::INTEGER                                 AS parentid,
                          1                                             AS liik,
                          NULL :: INTEGER                               AS lausend,
                          NULL :: VARCHAR(20)                           AS objekt,
                          NULL::DATE                                    AS maksekpv,
                          null::text as alus_oper_ids,
                          false::boolean as kas_ettemaks,
                          null::integer as puudumise_id,
                          null::text as alus_oper_ids,
                          null::date as ettemaksu_periood,
                         null::text as ettemaksu_oper_ids`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT d.*
                  FROM docs.get_relative_docs($1::INTEGER) d
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER`,
            query: null,
            multiple: true,
            alias: 'relations',
            data: []
        },
    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "kpv", name: "Kuupäev", width: "100px"},
            {id: "summa", name: "Summa", width: "100px"},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "liik", name: "Liik", width: "100px"},
            {id: "journalid", name: "Lausend", width: "100px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Status", width: "100px"}
        ],
        sqlString: `SELECT d.*
                    FROM (SELECT d.id,
                                 p.kpv,
                                 p.summa,
                                 p.rekvid,
                                 a.regkood                                                                                  AS isikukood,
                                 a.nimetus                                                                                  AS isik,
                                 a.id                                                                                       as isikid,
                                 coalesce(jid.number, 0)                                                                    AS journalid,
                                 coalesce(j.parentid, 0)                                                                    AS lausend_id,
                                 o.kood                                                                                     AS osakond,
                                 lib.nimetus,
                                 ((enum_range(NULL :: PALK_LIIK))[(lib.properties :: JSONB ->> 'liik') :: INTEGER]) :: TEXT AS palk_liik,
                                 ((enum_range(NULL :: PALK_OPER_LIIK))[CASE ((lib.properties :: JSONB ->> 'liik') ||
                                                                             (lib.properties :: JSONB ->> 'asutusest')) :: TEXT
                                                                           WHEN '10'
                                                                               THEN 1
                                                                           WHEN '20'
                                                                               THEN 2
                                                                           WHEN '40'
                                                                               THEN 2
                                                                           WHEN '70'
                                                                               THEN 2
                                                                           WHEN '71'
                                                                               THEN 3
                                                                           WHEN '80'
                                                                               THEN 2
                                                                           WHEN '60'
                                                                               THEN 2
                                                                           ELSE 3 END]) :: VARCHAR(20)                      AS liik,
                                 (lib.properties :: JSONB ->> 'tululiik') :: TEXT                                           AS tululiik,
                                 coalesce(p.konto, '')::varchar(20)                                                         as konto,
                                 coalesce(p.kood2, '')::varchar(20)                                                         as allikas,
                                 coalesce(p.tunnus, '')::varchar(20)                                                        as tunnus,
                                 coalesce(p.proj, '')::varchar(20)                                                          as proj,
                                 coalesce(lib.tun1, 0)::INTEGER                                                             AS is_ametiuhingu_liikme,
                                 (lib.properties :: JSONB ->> 'asutusest') :: BOOLEAN                                       AS is_asutusest,
                                 (lib.properties :: JSONB ->> 'maks') :: BOOLEAN                                            AS is_maksustatav,
                                 (lib.properties :: JSONB ->> 'sots') :: BOOLEAN                                            AS is_sotsmaks

                          FROM docs.doc d
                                   INNER JOIN palk.palk_oper p ON p.parentid = d.id
                                   INNER JOIN libs.library lib ON p.libid = lib.id AND lib.library = 'PALK'
                                   INNER JOIN palk.tooleping t ON p.lepingid = t.id
                                   INNER JOIN libs.asutus a ON t.parentid = a.id
                                   LEFT OUTER JOIN libs.library o ON o.id = t.osakondid
                                   LEFT OUTER JOIN docs.doc dd ON p.journalid = dd.id
                                   LEFT OUTER JOIN docs.journal j ON j.parentid = dd.id
                                   LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
                          WHERE d.doc_type_id IN (SELECT id
                                                  FROM libs.library l
                                                  WHERE l.library = 'DOK'
                                                    AND l.kood = 'PALK_OPER')
                            AND d.status <> 3) d
                    WHERE d.rekvId = $1
                      AND coalesce(docs.usersRigths(d.id, 'select', $2::INTEGER), TRUE)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPalkOper'
    },
    returnData: {
        row: {},
        relations: []
    },
    saveDoc: `select palk.sp_salvesta_palk_oper($1::json, $2::INTEGER, $3::INTEGER) as id`,
    deleteDoc: `SELECT error_code, result, error_message
                FROM palk.sp_delete_palk_oper($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'kpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {
            name: 'lepingid',
            type: 'I',
        },
        {
            name: 'libid',
            type: 'I',
        }

    ],
    generateJournal: {
        command: `SELECT error_code, result, error_message
                  FROM docs.gen_lausend_avans($2::INTEGER, $1::INTEGER)`, // $1 - userId, $2 - docId
        type: "sql",
        alias: 'generateJournal'
    },
    executeCommand: {
        command: `SELECT DISTINCT *
                  FROM jsonb_to_recordset(
                               (SELECT qry.data -> 'data'
                                FROM (SELECT *
                                      FROM sp_execute_task($1::INTEGER, $2::JSON, $3::TEXT)) qry)
                       ) AS x (error_message TEXT, error_code INTEGER, summa NUMERIC, selg TEXT, tki NUMERIC,
                               tka NUMERIC, tm NUMERIC, pm NUMERIC, sm NUMERIC, mvt NUMERIC)
        `, //$1- userId, $2 - params, $3 - task
        type: 'sql',
        alias: 'executeTask'
    },
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                                                        AS id,
                         (ajalugu ->> 'user')::VARCHAR(20)                                                           AS kasutaja,
                         coalesce(to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS koostatud,
                         coalesce(to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS muudatud,
                         coalesce(to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS prinditud,
                         coalesce(to_char((ajalugu ->> 'email')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'), '')::VARCHAR(20) AS
                                                                                                                        email,
                         coalesce(to_char((ajalugu ->> 'earve')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS earve,
                         coalesce(to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS kustutatud
                  FROM (SELECT jsonb_array_elements(history) AS ajalugu, d.id, d.rekvid
                        FROM docs.doc d,
                             ou.userid u
                        WHERE d.id = $1
                          AND u.id = $2) qry`,
        type: "sql",
        alias: "getLogs"
    },

};

module.exports = PalkOper;
