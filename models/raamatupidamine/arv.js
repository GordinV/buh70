'use strict';
//var co = require('co');
let now = new Date();
const start = require('./../BP/start'),
    generateJournal = require('./../BP/generateJournal'),
    endProcess = require('./../BP/endProcess');

const Arv = {
    selectAsLibs: `SELECT id,
                          arv_id,
                          number,
                          kpv,
                          summa,
                          liik,
                          asutus::VARCHAR(254) AS asutus,
                          asutusid,
                          arvid,
                          rekvid,
                          jaak,
                          tasudok,
                          tasud,
                          $2                   AS rekvid
                   FROM com_arved a
                   WHERE (a.rekvId = $1::INTEGER)`, //$1 - rekvid, $2 userid
    select: [
        {
            sql: `SELECT
                      d.id,
                      $2 :: INTEGER                                                         AS userid,
                      to_char(created, 'DD.MM.YYYY HH:MI:SS') :: TEXT                       AS created,
                      to_char(lastupdate, 'DD.MM.YYYY HH:MI:SS') :: TEXT                    AS lastupdate,
                      d.bpm,
                      trim(l.nimetus)                                                       AS doc,
                      trim(l.kood)                                                          AS doc_type_id,
                      trim(s.nimetus)                                                       AS status,
                      d.status                                                              AS doc_status,
                      trim(a.number) :: VARCHAR(20)                                         AS number,
                      a.rekvId,
                      a.liik,
                      a.operid,
                      a.kpv                                                                 AS kpv,
                      a.asutusid,
                      a.arvId,
                      trim(coalesce(a.lisa, '')) :: VARCHAR(120)                            AS lisa,
                      a.tahtaeg                                                             AS tahtaeg,
                      a.kbmta,
                      a.kbm,
                      a.summa,
                      a.tasud,
                      trim(a.tasudok)                                                       AS tasudok,
                      a.muud,
                      a.jaak,
                      coalesce(a.objektId, 0)::INTEGER                                      AS objektId,
                      trim(a.objekt)                                                        AS objekt,
                      asutus.regkood,
                      trim(asutus.nimetus)                                                  AS asutus,
                      asutus.aadress,
                      (asutus.properties ->> 'kmkr') :: VARCHAR(20)                         AS kmkr,
                      a.doklausid,
                      a.journalid,
                      coalesce(jid.number, 0) :: INTEGER                                    AS laus_nr,
                      coalesce((dp.details :: JSONB ->> 'konto'), '') :: VARCHAR(20)        AS konto,
                      coalesce((dp.details :: JSONB ->> 'kbmkonto'), '') :: VARCHAR(20)     AS kbmkonto,
                      dp.selg :: VARCHAR(120)                                               AS dokprop,
                      dp.vaatalaus                                                          AS is_show_journal,
                      (d.history -> 0 ->> 'user') :: VARCHAR(120)                           AS koostaja,
                      coalesce((a.properties ->> 'aa')::TEXT, qry_aa.arve)::VARCHAR(20)     AS aa,
                      coalesce((a.properties ->> 'viitenr')::TEXT, '')::VARCHAR(120)        AS viitenr,
                      coalesce((a.properties ->> 'tyyp')::TEXT, '')::VARCHAR(20)            AS tyyp,
                      coalesce((a.properties ->> 'taskuraha_kov')::NUMERIC, 0)              AS taskuraha_kov,
                      (
                          SELECT
                              arv.number
                          FROM
                              docs.arvtasu            at
                                  INNER JOIN docs.arv arv ON arv.parentid = at.doc_arv_id
                          WHERE
                                at.pankkassa = 4 -- kreeditarve
                            AND at.doc_tasu_id = a.parentid
                            AND at.status < 3
                          LIMIT 1
                      )                                                                     AS kr_number,
                      (a.properties ->> 'alus_arve_id')::INTEGER                            AS alus_arve_id,
                      (a.properties ->> 'raha_saaja')::VARCHAR(254)                         AS raha_saaja,
                      coalesce((a.properties ->> 'umardamine')::numeric, 0)::numeric(12, 2) as umardamine
                  FROM
                      docs.doc                           d
                          INNER JOIN      libs.library   l ON l.id = d.doc_type_id
                          INNER JOIN      docs.arv       a ON a.parentId = d.id
                          INNER JOIN      libs.asutus AS asutus ON asutus.id = a.asutusId
                          INNER JOIN      ou.userid      u ON u.id = $2 :: INTEGER
                          LEFT OUTER JOIN libs.library   s ON s.library = 'STATUS' AND s.kood = d.status :: TEXT
                          LEFT OUTER JOIN libs.dokprop   dp ON dp.id = a.doklausid
                          LEFT OUTER JOIN docs.journal   j ON j.parentid = a.journalid
                          LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id,
                      (
                          SELECT
                              arve
                          FROM
                              ou.aa                    aa
                                  INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                          WHERE
                                aa.parentid = u.rekvid
                            AND NOT empty(default_::INTEGER)
                            AND NOT empty(kassa::INTEGER)
                            AND kassa = 1
                          LIMIT 1
                      )                                  qry_aa
                  WHERE
                      d.id = $1`,
            sqlAsNew: `SELECT $1 :: INTEGER                                                          AS id,
                              $2 :: INTEGER                                                          AS userid,
                              to_char(now(), 'DD.MM.YYYY HH:MI:SS') :: TEXT                          AS created,
                              to_char(now(), 'DD.MM.YYYY HH:MI:SS') :: TEXT                          AS lastupdate,
                              NULL                                                                   AS bpm,
                              trim(l.nimetus)                                                        AS doc,
                              trim(l.kood)                                                           AS doc_type_id,
                              trim(s.nimetus)                                                        AS status,
                              0                                                                      AS doc_status,
                              (SELECT arve
                               FROM ou.aa
                               WHERE id = ou.get_aa(u.rekvid, 'TULUD'::TEXT)::INTEGER
                               LIMIT 1)::VARCHAR(20)                                                 AS aa,
                              docs.sp_get_number(u.rekvId, 'ARV', year(date()), NULL) :: VARCHAR(20) AS number,
                              0.00                                                                   AS summa,
                              NULL :: INTEGER                                                        AS rekvId,
                              0                                                                      AS liik,
                              NULL :: INTEGER                                                        AS operid,
                              now() :: DATE                                                          AS kpv,
                              NULL :: INTEGER                                                        AS asutusid,
                              NULL :: INTEGER                                                        AS arvId,
                              '' :: VARCHAR(120)                                                     AS lisa,
                              (now() + INTERVAL '14 days') :: DATE                                   AS tahtaeg,
                              0 :: NUMERIC                                                           AS kbmta,
                              0.00 :: NUMERIC                                                        AS kbm,
                              0 :: NUMERIC(14, 2)                                                    AS summa,
                              NULL :: DATE                                                           AS tasud,
                              NULL :: VARCHAR(20)                                                    AS tasudok,
                              NULL :: TEXT                                                           AS muud,
                              0.00                                                                   AS jaak,
                              0 :: INTEGER                                                           AS objektId,
                              NULL :: VARCHAR(20)                                                    AS objekt,
                              NULL :: VARCHAR(20)                                                    AS regkood,
                              NULL :: VARCHAR(120)                                                   AS asutus,
                              NULL :: TEXT                                                           AS aadress,
                              NULL :: VARCHAR(120)                                                   AS kmkr,
                              NULL :: INTEGER                                                        AS doklausid,
                              NULL :: VARCHAR(120)                                                   AS dokprop,
                              NULL :: TEXT                                                           AS konto,
                              NULL :: TEXT                                                           AS kbmkonto,
                              NULL :: INTEGER                                                        AS journalid,
                              NULL :: INTEGER                                                        AS laus_nr,
                              NULL :: VARCHAR(120)                                                   AS koostaja,
                              0 ::INTEGER                                                            AS is_show_journal,
                              ''::VARCHAR(120)                                                       AS viitenr,
                              0::NUMERIC                                                             AS taskuraha_kov,
                              NULL::INTEGER                                                          AS alus_arve_id
                       FROM libs.library l,
                            libs.library s,
                            ou.userid u
                       WHERE l.library = 'DOK'
                         AND l.kood = 'ARV'
                         AND u.id = $2 :: INTEGER
                         AND s.library = 'STATUS'
                         AND s.kood = '0'`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT a1.id,
                         $2 :: INTEGER                                                                 AS userid,
                         a1.nomid,
                         a1.kogus,
                         a1.hind,
                         a1.kbm,
                         a1.kbmta,
                         a1.summa,
                         trim(n.kood) :: VARCHAR(20)                                                   AS kood,
                         trim(n.nimetus) :: VARCHAR(254)                                               AS nimetus,
                         a1.soodus,
                         a1.kood1,
                         a1.kood2,
                         a1.kood3,
                         a1.kood4,
                         a1.kood5,
                         a1.tunnus,
                         a1.proj,
                         a1.objekt,
                         a1.konto,
                         a1.tp,
                         NULL :: TEXT                                                                  AS vastisik,
                         NULL :: TEXT                                                                  AS formula,
                         'EUR' :: VARCHAR(20)                                                          AS valuuta,
                         1 :: NUMERIC                                                                  AS kuurs,
                         (CASE
                              WHEN a1.kbm_maar IS NULL
                                  THEN coalesce((n.properties :: JSONB ->> 'vat'), '-') :: VARCHAR(20)
                              ELSE a1.kbm_maar END)::VARCHAR(20)                                       AS km,
                         n.uhik,
                         coalesce((a1.properties ->> 'allikas_85')::NUMERIC, 0)::NUMERIC(12, 2)        AS allikas_85,
                         coalesce((a1.properties ->> 'allikas_muud')::NUMERIC, 0)::NUMERIC(12, 2)      AS allikas_muud,
                         coalesce((a1.properties ->> 'allikas_vara')::NUMERIC, 0)::NUMERIC(12, 2)      AS allikas_vara,
                         coalesce((a1.properties ->> 'omavalitsuse_osa')::NUMERIC, 0)::NUMERIC(12, 2)  AS omavalitsuse_osa,
                         coalesce((a1.properties ->> 'sugulane_osa')::NUMERIC, 0)::NUMERIC(12, 2)      AS sugulane_osa,
                         coalesce((a1.properties ->> 'allikas_taskuraha')::NUMERIC, 0)::NUMERIC(12, 2) AS taskuraha,
                         coalesce((a1.properties ->> 'allikas_taskuraha')::NUMERIC, 0)::NUMERIC(12, 2) AS allikas_taskuraha,
                         coalesce((a1.properties ->> 'umardamine')::NUMERIC, 0)::NUMERIC(12, 2)        AS umardamine,
                         a1.muud
                  FROM docs.arv1 AS a1
                           INNER JOIN docs.arv a ON a.id = a1.parentId
                           INNER JOIN libs.nomenklatuur n ON n.id = a1.nomId
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                  WHERE a.parentid = $1 :: INTEGER`,
            query: null,
            multiple: true,
            alias: 'details',
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
        {
            sql: `SELECT Arvtasu.id,
                         arvtasu.kpv,
                         arvtasu.summa,
                         'MK' :: VARCHAR(20)           AS dok,
                         'PANK' :: VARCHAR             AS liik,
                         pankkassa,
                         mk1.journalid,
                         doc_tasu_id,
                         coalesce(journalid.number, 0) AS number,
                         'EUR' :: VARCHAR              AS valuuta,
                         1 :: NUMERIC                  AS kuurs,
                         coalesce(a.kinni, 0)          AS kinni
                  FROM docs.arvtasu arvtasu
                           INNER JOIN docs.mk mk ON (arvtasu.doc_tasu_id = mk.parentid AND arvtasu.pankkassa = 1)
                           INNER JOIN docs.mk1 mk1 ON (mk.id = mk1.parentid)
                           LEFT OUTER JOIN docs.journal j ON mk1.journalId = j.parentid
                           LEFT OUTER JOIN docs.journalid journalid ON j.id = journalId.journalId
                           LEFT OUTER JOIN ou.aasta a
                                           ON a.rekvid = arvtasu.rekvid AND month(arvtasu.kpv) = a.kuu AND
                                              year(arvtasu.kpv) = a.aasta
                  WHERE Arvtasu.doc_arv_id = $1
                    AND arvtasu.summa <> 0
                    AND arvtasu.status <> 3
                  UNION ALL
                  SELECT Arvtasu.id
                          ,
                         arvtasu.kpv
                          ,
                         arvtasu.summa
                          ,
                         'KASSAORDER' :: VARCHAR(20)   AS dok
                          ,
                         'KASSA' :: VARCHAR            AS liik
                          ,
                         pankkassa
                          ,
                         korder1.journalid
                          ,
                         doc_tasu_id
                          ,
                         coalesce(journalid.number, 0) AS number
                          ,
                         'EUR' :: VARCHAR              AS valuuta
                          ,
                         1 :: NUMERIC                  AS kuurs
                          ,
                         coalesce(a.kinni, 0)          AS kinni
                  FROM docs.arvtasu arvtasu
                           INNER JOIN docs.korder1 korder1
                                      ON (arvtasu.doc_tasu_id = korder1.parentid AND arvtasu.pankkassa = 2)
                           LEFT OUTER JOIN docs.journal j ON korder1.journalId = j.parentid
                           LEFT OUTER JOIN docs.journalid journalid ON j.id = journalId.journalId
                           LEFT OUTER JOIN ou.aasta a
                                           ON a.rekvid = arvtasu.rekvid AND month(arvtasu.kpv) = a.kuu AND
                                              year(arvtasu.kpv) = a.aasta
                  WHERE Arvtasu.doc_arv_id = $1
                    AND arvtasu.summa <> 0
                    AND arvtasu.status <> 3
                  UNION ALL
                  SELECT Arvtasu.id
                          ,
                         arvtasu.kpv
                          ,
                         arvtasu.summa
                          ,
                         'PAEVARAAMAT' :: VARCHAR(20)  AS dok
                          ,
                         'JOURNAL' :: VARCHAR          AS liik
                          ,
                         pankkassa
                          ,
                         arvtasu.doc_tasu_id           AS journalid
                          ,
                         doc_tasu_id
                          ,
                         coalesce(journalid.number, 0) AS number
                          ,
                         'EUR' :: VARCHAR              AS valuuta
                          ,
                         1 :: NUMERIC                  AS kuurs
                          ,
                         coalesce(a.kinni, 0)          AS kinni
                  FROM docs.arvtasu arvtasu
                           LEFT OUTER JOIN docs.journal journal
                                           ON (arvtasu.doc_tasu_id = journal.parentId AND arvtasu.pankkassa = 3)
                           LEFT OUTER JOIN docs.journalid journalid ON (journal.id = journalId.journalId)
                           LEFT OUTER JOIN ou.aasta a
                                           ON a.rekvid = arvtasu.rekvid AND month(arvtasu.kpv) = a.kuu AND
                                              year(arvtasu.kpv) = a.aasta
                  WHERE Arvtasu.doc_arv_id = $1
                    AND arvtasu.summa <> 0
                    AND arvtasu.status <> 3
                    AND arvtasu.pankkassa = 3
                  UNION ALL
                  SELECT Arvtasu.id
                          ,
                         arvtasu.kpv
                          ,
                         arvtasu.summa
                          ,
                         '' :: VARCHAR(20)    AS dok
                          ,
                         'MUUD' :: VARCHAR    AS liik
                          ,
                         pankkassa
                          ,
                         0                    AS journalid
                          ,
                         NULL
                          ,
                         0                    AS number
                          ,
                         'EUR' :: VARCHAR     AS valuuta
                          ,
                         1 :: NUMERIC         AS kuurs
                          ,
                         coalesce(a.kinni, 0) AS kinni
                  FROM docs.arvtasu arvtasu
                           LEFT OUTER JOIN ou.aasta a
                                           ON a.rekvid = arvtasu.rekvid AND month(arvtasu.kpv) = a.kuu AND
                                              year(arvtasu.kpv) = a.aasta
                  WHERE Arvtasu.doc_arv_id = $1
                    AND arvtasu.summa <> 0
                    AND arvtasu.status <> 3
                    AND arvtasu.pankkassa IN (0, 4)`,
            query: null,
            multiple: true,
            alias: 'queryArvTasu',
            data: []
        },
        {
            sql: `SELECT result, error_code, error_message
                  FROM docs.create_new_mk($1::INTEGER, $2::JSONB)`, //$1 - userId, $2 - params -> {"arv_id": ?, "dok":"SMK" }
            query: null,
            multuple: false,
            alias: 'create_new_mk',
            data: []
        },
        {
            sql: `SELECT result, error_code, error_message
                  FROM docs.create_new_order($1::INTEGER, $2::JSONB)`, //$1 - userId, $2 - params -> {"arv_id": ?, "dok":"SORDER" }
            query: null,
            multuple: false,
            alias: 'create_new_order',
            data: []
        },
        {
            sql: `SELECT docs.check_arv_number($1::integer, $2::JSON)::integer as tulemus`, //$1 - rekvId, $2 - params ->'{"tyyp":1, "number":"10", "aasta": 2017, "asutus": 5155}'
            query: null,
            multuple: false,
            alias: 'validate_arve_number',
            data: []

        },
        {
            sql: `SELECT docs.sp_update_doc_bpm_data($1::integer, $2::integer, $3::JSONB)::integer as tulemus`, //$1 - docId, $2 - userId, $3 - params ->'{"omniva":[{"isik":"koostaja", "kpv":"2019-05-31","rolli":"creator"},{"isik":"koostaja", "kpv":"2019-05-31","rolli":"kinnitaja"}]}')
            query: null,
            multuple: false,
            alias: 'update_bpm',
            data: []

        },
        {
            sql: `SELECT *
                  FROM json_to_recordset((SELECT (bpm ->> 'omniva')::JSON
                                          FROM docs.doc
                                          WHERE id = $1)) AS x(kpv VARCHAR(40), isik VARCHAR(254), rolli VARCHAR(20))`, //$1 - docId
            query: null,
            multuple: false,
            alias: 'get_omniva_bpm',
            data: []
        },
        {
            sql: `SELECT *
                  FROM docs.check_arv_jaak($1, $2)`, //$1 - docId, $2 userId
            query: null,
            multuple: false,
            alias: 'check_arv_jaak',
            data: []
        },
        {
            sql: `SELECT error_code, result, error_message,  'ARV' AS doc_type_id
                  FROM docs.koosta_kreedit_arve($2::INTEGER, $1::INTEGER)`, //$1 - docs.doc.id, $2 - userId
            query: null,
            multuple: false,
            alias: 'koostaKreeditArve',
            data: [],
            not_initial_load: true
        },
        {
            sql: `SELECT $1::INTEGER                                                   AS rekv_id,
                         coalesce(error_code, 0)                                       AS error_code,
                         result,
                         error_message::VARCHAR(254)                                   AS error_message,
                         CASE WHEN empty(error_code) THEN TRUE ELSE FALSE END::BOOLEAN AS kas_vigane,
                         *
                  FROM docs.ebatoenaolised($1, $2::DATE)`, //$1 - rekvId, $2 kpv
            query: null,
            multuple: false,
            alias: 'arvesta_ebatoenaolised',
            data: [],
            not_initial_load: true
        },
        {
            sql: `SELECT error_code, result, error_message, 'ARV' AS doc_type_id
                  FROM docs.ebatoenaolised_mahakandmine($1::INTEGER, $2::INTEGER, $3::DATE)`, //$1 - userId, $2 - id, $3 kpv
            query: null,
            multuple: false,
            alias: 'ebatoenaolised',
            data: [],
            not_initial_load: true
        },
        {
            sql: `SELECT *
                  FROM libs.asutus
                  WHERE regkood = $1
                  ORDER BY staatus
                  LIMIT 1`,
            query: null,
            multiple: false,
            alias: 'validate_asutus',
            data: []
        },
        {
            sql: `SELECT parentid as id, jaak, kpv 
                  FROM docs.arv a
                  WHERE a.asutusid = $3::INTEGER
                    AND number = $2::TEXT
                    AND rekvid = $1::INTEGER
                  ORDER BY jaak DESC
                  LIMIT 1`,
            query: null,
            multiple: false,
            alias: 'locate_arve_by_number',
            data: []
        },


    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px", show: false},
            {id: "number", name: "Number", width: "100px"},
            {id: "kpv", name: "Kuupaev", width: "100px"},
            {id: "summa", name: "Summa", width: "75px"},
            {id: "tahtaeg", name: "Tähtaeg", width: "100px"},
            {id: "jaak", name: "Jääk", width: "100px"},
            {id: "tasud", name: "Tasud", width: "100px"},
            {id: "asutus", name: "Asutus", width: "200px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Staatus", width: "100px"},
        ],
        sqlString: `WITH params AS (
                        SELECT $1::INTEGER AS rekv_id,
                               $2::INTEGER AS user_id
                    ),
                         arved AS (
                             SELECT id,
                                    arv_id,
                                    number :: VARCHAR(20),
                                    rekvid,
                                    kpv,
                                    summa,
                                    kbm,
                                    kbmta,
                                    tahtaeg,
                                    jaak,
                                    lisa,
                                    tasud,
                                    tasudok,
                                    userid,
                                    asutus :: VARCHAR(254),
                                    regkood::VARCHAR(20),
                                    omvorm::VARCHAR(20),
                                    aadress::TEXT,
                                    email::VARCHAR(254),
                                    asutusid,
                                    journalid,
                                    liik,
                                    ametnik,
                                    objektid,
                                    objekt :: VARCHAR(254),
                                    markused,
                                    lausnr,
                                    docs_ids,
                                    coalesce(a.arve, qry_aa.arve)::VARCHAR(20) AS aa,
                                    a.viitenr::VARCHAR(120)                    AS viitenr,
                                    ebatoenaolised,
                                    korr_konto,
                                    raha_saaja
                             FROM cur_arved a,
                                  params,
                                  (SELECT arve
                                   FROM ou.aa aa,
                                        params
                                   WHERE aa.parentid = params.rekv_id
                                     AND NOT empty(default_::INTEGER)
                                     AND NOT empty(kassa::INTEGER)
                                     AND kassa = 1
                                   LIMIT 1) qry_aa
                             WHERE a.rekvId = params.rekv_id::INTEGER
                         ),
                         ebatoenaolised_tagastamine AS (
                             SELECT DISTINCT doc_arv_id AS arv_id
                             FROM docs.arvtasu,
                                  params
                             WHERE rekvid = params.rekv_id::INTEGER
                               AND status < 3
                               AND pankkassa <> 4 
                               AND (properties ->> 'ebatoenaolised_tagastamine_id' IS NOT NULL AND
                                    (properties ->> 'ebatoenaolised_tagastamine_id')::INTEGER > 0)
                         ),
                         ebatoenaolised_mahakandmine AS (
                             SELECT doc_arv_id    AS arv_id,
                                    sum(at.summa) AS summa
                             FROM docs.arvtasu at
                                      INNER JOIN docs.journal j ON at.doc_tasu_id = j.parentid
                                      INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
                                  params
                             WHERE at.rekvid = params.rekv_id::INTEGER
                               AND at.status < 3
                               AND j1.deebet = '103009'
                               AND status < 3
                             GROUP BY at.doc_arv_id
                         ),
                         ebatoenaolised_kreedit_arve AS (
                             SELECT doc_arv_id    AS arv_id,
                                    sum(at.summa) AS summa
                             FROM docs.arvtasu at
                                      INNER JOIN docs.arv a ON at.doc_tasu_id = a.parentid,
                                  params
                             WHERE at.rekvid = params.rekv_id::INTEGER
                               AND at.status < 3
                               AND at.pankkassa = 4 
                               AND status < 3
                             GROUP BY at.doc_arv_id
                         ),
                         kreedit_arved AS (
                             SELECT at.doc_arv_id, at.doc_tasu_id
                             FROM docs.arvtasu at
                                      INNER JOIN docs.arv a ON a.parentid = at.doc_arv_id,
                                  params
                             WHERE at.pankkassa = 4 
                               AND at.rekvid = params.rekv_id::INTEGER
                               AND at.doc_arv_id IS NOT NULL
                               AND at.doc_tasu_id IS NOT NULL
                               AND at.status < 3
                         )
                    SELECT a.*,
                           CASE
                               WHEN em.arv_id IS NOT NULL THEN 'Maha kantud'
                               WHEN et.arv_id IS NOT NULL AND a.jaak = 0 THEN 'Tasutud'
                               WHEN et.arv_id IS NOT NULL AND a.jaak > 0 THEN 'Tasutud osaliselt'
                               WHEN eka.arv_id IS NOT NULL THEN 'Kreeditarve'
                               WHEN a.jaak = 0 AND coalesce(ebatoenaolised, '') <> '0' THEN 'Vigane'
                               WHEN a.ebatoenaolised IS NOT NULL AND a.ebatoenaolised <> '0' AND a.jaak > 0 THEN 'Sulgemata'
                               ELSE ''
                               END::varchar(100)         AS ebatoenaolised_status,
                           CASE
                               WHEN exists(SELECT 1 FROM kreedit_arved WHERE doc_arv_id = a.id) THEN 'DB'
                               WHEN exists(SELECT 1 FROM kreedit_arved WHERE doc_tasu_id = a.id) THEN 'KR'
                               ELSE '' END::varchar(20) AS kr_tyyp
                    FROM arved a
                             LEFT OUTER JOIN ebatoenaolised_mahakandmine em ON em.arv_id = a.id
                             LEFT JOIN ebatoenaolised_tagastamine et ON et.arv_id = a.id
                             LEFT JOIN ebatoenaolised_kreedit_arve eka ON eka.arv_id = a.id
                    `,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curArved'
    },
    returnData: {
        row: {},
        details: [],
        relations: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'nomid', name: 'nomId', width: '0px', show: false, type: 'text', readOnly: false},
            {
                id: 'kood',
                name: 'Kood',
                width: '100px',
                show: true,
                type: 'select',
                readOnly: false,
                dataSet: 'nomenclature',
                valueFieldName: 'nomid'
            },
            {id: 'nimetus', name: 'Nimetus', width: '300px', show: true, readOnly: true},
            {id: 'hind', name: 'Hind', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'kogus', name: 'kogus', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'kbm', name: 'Käibemaks', width: '100px', show: true, type: 'number', readOnly: false},
            {id: 'summa', name: 'Summa', width: '100px', show: true, type: 'number', readOnly: false}
        ]
    },
    saveDoc: `select docs.sp_salvesta_arv($1::json, $2::integer, $3::integer) as id`,
    deleteDoc: `SELECT error_code, result, error_message
                FROM docs.sp_delete_arv($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'kpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {
            name: 'tahtaeg',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {name: 'asutusid', type: 'N', min: null, max: null},
        {name: 'summa', type: 'N', min: -9999999, max: 999999}
    ],
    executeCommand: {
        command: `select docs.sp_kooperi_arv($1::integer, $2::integer) as result`,
        type: 'sql',
        alias: 'kooperiArv'
    },
    bpm: [
        {
            step: 0,
            name: 'Регистация документа',
            action: 'start',
            nextStep: 1,
            task: 'human',
            data: [],
            actors: [],
            status: null,
            actualStep: false
        },
        {
            step: 1,
            name: 'Контировка',
            action: 'generateJournal',
            nextStep: 2,
            task: 'automat',
            data: [],
            status: null,
            actualStep: false
        },
//        {step:2, name:'Оплата', action: 'tasumine', nextStep:3, task:'human', data:[], status:null, actualStep:false},
        {
            step: 2,
            name: 'Конец',
            action: 'endProcess',
            nextStep: null,
            task: 'automat',
            data: [],
            actors: [],
            status: null,
            actualStep: false
        }
    ],
    register: {
        command: `UPDATE docs.doc
                  SET status = 1
                  WHERE id = $1`, type: "sql"
    },
    generateJournal: {
        command: "SELECT error_code, result, error_message FROM docs.gen_lausend_arv($2::INTEGER, $1::INTEGER)", //$1 - docs.doc.id, $2 - userId
        type: "sql",
        alias: 'generateJournal'
    },
    endProcess: {command: "UPDATE docs.doc SET status = 2 WHERE id = $1", type: "sql"},
    executeTask: function (task, docId, userId) {
        // выполнит задачу, переданную в параметре

        let executeTask = task;
        if (executeTask.length == 0) {
            executeTask = ['start'];
        }

        let taskFunction = eval(executeTask[0]);
        return taskFunction(docId, userId, this);
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
                  FROM (
                           SELECT jsonb_array_elements(history) AS ajalugu, d.id, d.rekvid
                           FROM docs.doc d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry`,
        type: "sql",
        alias: "getLogs"
    },

};

module.exports = Arv;

