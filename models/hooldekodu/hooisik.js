module.exports = {

    select: [{
        sql: `SELECT id,
                     regkood,
                     nimetus,
                     omvorm,
                     aadress,
                     kontakt,
                     tel,
                     faks,
                     email,
                     muud,
                     tp,
                     staatus,
                     mark,
                     $2::INTEGER                                     AS userid,
                     'HOOISIK'                                       AS doc_type_id,
                     (properties ->> 'pank')::VARCHAR(20)            AS pank,
                     (properties ->> 'kmkr')::VARCHAR(20)            AS kmkr,
                     (properties ->> 'kehtivus')::DATE               AS kehtivus,
                     (properties ->> 'kehtivus')::DATE               AS valid,
                     (properties -> 'asutus_aa' -> 0 ->> 'aa')::TEXT AS aa
              FROM libs.asutus
              WHERE id = $1`,
        sqlAsNew: `SELECT $1::INTEGER                                          AS id,
                          $2::INTEGER                                          AS userid,
                          'HOOISIK'                                            AS doc_type_id,
                          ''::TEXT                                             AS regkood,
                          ''::TEXT                                             AS nimetus,
                          ''::TEXT                                             AS omvorm,
                          ''::TEXT                                             AS aadress,
                          ''::TEXT                                             AS kontakt,
                          ''::TEXT                                             AS tel,
                          ''::TEXT                                             AS faks,
                          ''::TEXT                                             AS email,
                          NULL::TEXT                                           AS muud,
                          ''::TEXT                                             AS tp,
                          0::INTEGER                                           AS staatus,
                          ''::VARCHAR(20)                                      AS pank,
                          ''::VARCHAR(20)                                      AS kmkr,
                          ''::TEXT                                             AS mark,
                          ''::TEXT                                             AS aa`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT (e.element ->> 'aa') :: VARCHAR(20)                  AS aa,
                         $2 :: INTEGER                                        AS userid,
                         ((e.element ->> 'kas_palk') :: BOOLEAN)::INTEGER     AS kas_palk,
                         ((e.element ->> 'kas_raama') :: BOOLEAN)::INTEGER    AS kas_raama,
                         ((e.element ->> 'kas_oppetasu') :: BOOLEAN)::INTEGER AS kas_oppetasu,
                         row_number() OVER ()                                 AS id,
                         libs.get_asutuse_aa(a.id, 'RAAMA'::TEXT)             AS default_aa
                  FROM libs.asutus a,
                       json_array_elements(CASE
                                               WHEN (a.properties ->> 'asutus_aa') IS NULL THEN '[]'::JSON
                                               ELSE (a.properties -> 'asutus_aa') :: JSON END) AS e (element)
                  WHERE a.id = $1`, //$1 - doc_id, $2 0 userId
            query: null,
            multiple: true,
            alias: 'asutus_aa',
            data: []

        },
        {
            sql: `SELECT Asutus.id
                  FROM libs.asutus Asutus
                  WHERE (upper(rtrim(ltrim(Asutus.regkood))) = upper($1) OR empty($1))
                    AND (upper(rtrim(ltrim(Asutus.nimetus))) = upper($2) OR empty($2))`, //$1 regkood, $2 nimetus
            query: null,
            multiple: false,
            alias: 'validate_asutus',
            data: [],
            not_initial_load: true

        },
        {
            sql: `SELECT ht.id,
                         ht.lepingid,
                         ht.nomid,
                         nom.kood,
                         nom.nimetus,
                         ht.hind,
                         ht.allikas,
                         ht.tuluosa,
                         ht.jaak,
                         ht.muud,
                         coalesce(ht.muud, '')::VARCHAR(254) AS selg,
                         ht.kehtivus,
                         $2 :: INTEGER                       AS userid
                  FROM hooldekodu.hooTeenused ht
                           INNER JOIN libs.nomenklatuur nom ON nom.id = ht.nomid
                  WHERE ht.lepingid IN (SELECT id FROM hooldekodu.hooleping hl WHERE hl.isikid = $1 AND hl.status < 3)
                    AND nom.rekvid IN (SELECT rekvid FROM ou.userid WHERE id = $2)`, //$1 regkood, $2 nimetus
            query: null,
            multiple: true,
            alias: 'teenused',
            data: []
        },
        {
            sql: `SELECT h.id,
                         h.hooldajaid,
                         a.nimetus                          AS hooldaja,
                         h.isikid,
                         h.kohtumaarus,
                         h.algkpv,
                         h.loppkpv,
                         coalesce(h.muud, '')               AS muud,
                         coalesce(h.muud, '')::VARCHAR(254) AS selg,
                         $2                                 AS user_id
                  FROM hooldekodu.hooldaja h
                           INNER JOIN libs.asutus a ON h.hooldajaId = a.id
                  WHERE h.isikid = $1
                    AND status < 3`, //$1 regkood, $2 nimetus
            query: null,
            multiple: true,
            alias: 'hooldajad',
            data: []
        },
        {
            sql: `with qryTab as (
                    SELECT year(htab.kpv)                          AS aasta,
                         month(htab.kpv)                         AS kuu,
                         htab.id,
                         htab.kpv,
                         htab.nomid,
                         nom.kood,
                         (htab.kogus)                            AS kogus,
                         (htab.summa)                            AS arv_summa,
                         htab.arvid,
                         coalesce(arv.number, '')::VARCHAR(20)   AS number,
                         htab.rekvid,
                         htab.isikid,
                         coalesce((htab.properties->>'umardamine')::numeric,0) as umardamine,
                         $2                                      AS user_id,
                         coalesce(arv.allikas_85,0) as allikas_85,
                         coalesce(arv.allikas_muud,0) as allikas_muud,
                         coalesce(arv.allikas_vara,0) as allikas_vara,
                         coalesce(arv.omavalitsuse_osa,0) as omavalitsus_osa,
                         coalesce(arv.sugulane_osa,0) as sugulane_osa
                  FROM hooldekodu.hootaabel htab
                           INNER JOIN libs.nomenklatuur nom ON htab.nomid = nom.id
                       LEFT OUTER JOIN (
                          SELECT d.id,
                                 a.number,
                                 sum(coalesce((a1.properties ->> 'allikas_85')::NUMERIC, 0))   AS allikas_85,
                                 sum(coalesce((a1.properties ->> 'allikas_muud')::NUMERIC, 0)) AS allikas_muud,
                                 sum(coalesce((a1.properties ->> 'allikas_vara')::NUMERIC, 0)) AS allikas_vara,
                                 sum(coalesce((a1.properties ->> 'omavalitsuse_osa')::NUMERIC, 0)) AS omavalitsuse_osa,
                                 sum(coalesce((a1.properties ->> 'sugulane_osa')::NUMERIC, 0))     AS sugulane_osa                             
                          FROM docs.doc d
                                   INNER JOIN docs.arv a ON d.id = a.parentid
                                   LEFT JOIN docs.arv1 a1 ON a1.parentid = a.id
                          WHERE a.properties ->> 'tyyp' = 'HOOLDEKODU_ISIKU_OSA'
                            AND d.rekvid  = $1
                            and d.status < 3
                          GROUP BY d.id, a.number
                      ) arv ON arv.id = htab.arvid
                  WHERE htab.rekvid  = $1
                    AND htab.status < 3)
                    select qryTab.*, 
                    arv_summa + umardamine as summa
                    from qryTab
                    `, //$1 rekvid, $2 userid
            query: null,
            multiple: true,
            alias: 'curHooTaabel',
            data: []
        },
        {
            sql: `SELECT id,
                         kpv,
                         isikid,
                         aruanne,
                         kellele,
                         koostaja,
                         muud::VARCHAR(254) AS muud,
                         rekvid,
                         $2                 AS used_id
                  FROM hooldekodu.hootoendid htd
                  WHERE htd.rekvid = $1
            `, //$1 rekvid, $2 userid
            query: null,
            multiple: true,
            alias: 'curHooToendid',
            data: []
        },
        {
            sql: `SELECT *,
                         $2 AS user_id
                  FROM hooldekodu.cur_hoojaak h
                  WHERE h.isikid = $1`, //$1 regkood, $2 nimetus
            query: null,
            multiple: true,
            alias: 'hoojaak',
            data: []
        },
        {
            sql: `SELECT *,
                         $2 AS user_id
                  FROM hooldekodu.cur_hoojaak h
                  WHERE h.isikid = $1`, //$1 regkood, $2 nimetus
            query: null,
            multiple: true,
            alias: 'hoojaagid',
            data: []
        },
        {
            sql: `SELECT *,
                         $2 AS user_id
                  FROM hooldekodu.cur_hoojaak h
                  WHERE h.isikid IN (SELECT isikid FROM hooldekodu.hooleping hl 
                    WHERE rekvid = $1 AND status < 3
                      and (hl.loppkpv >= current_date or hl.loppkpv is null)
                      )`, //$1 regkood, $2 nimetus
            query: null,
            multiple: true,
            alias: 'print_hoojaagid',
            data: []
        },
        {
            sql: `SELECT *
                  FROM jsonb_to_recordset(
                               get_asutus_kasutus($2::INTEGER, $3::DATE,
                                                  $1::INTEGER)
                           ) AS x (error_message TEXT, error_code INTEGER)
                  WHERE error_message IS NOT NULL
            `, //$1 rekvid, $2 v_nom.kood
            query: null,
            multiple: true,
            alias: 'validate_lib_usage',
            data: [],
            not_initial_load: true

        },
        {
            sql: `SELECT hooldekodu.set_dead($1::INTEGER, $2::INTEGER, $3::DATE) as result`, //$1 - docs.doc.id, $2 - userId, $3 - kpv
            query: null,
            multuple: false,
            not_initial_load: true,
            alias: 'setDead'
        },
        {
            sql: `SELECT row_number() OVER ()                                          AS id,
                         tulemus -> 'result'                                           AS result,
                         tulemus -> 'error_code'                                       AS error_code,
                         coalesce((tulemus ->> 'error_code')::INTEGER, 0)::INTEGER > 0 AS kas_vigane,
                         tulemus -> 'error_message'                                    AS error_message
                  FROM (
                           SELECT to_jsonb(
                                          hooldekodu.koosta_hoo_taabelid($2::INTEGER, id::INTEGER,
                                                                         $3::DATE)) tulemus
                           FROM libs.asutus
                           WHERE id IN (
                               SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER
                           )) qry`, //$1 - docs.doc.id, $2 - userId, $3 - kpv
            query: null,
            multuple: false,
            not_initial_load: true,
            alias: 'koostaTaabel'
        },
        {
            sql: `SELECT row_number() OVER ()                                          AS id,
                         tulemus -> 'result'                                           AS result,
                         tulemus -> 'error_code'                                       AS error_code,
                         coalesce((tulemus ->> 'error_code')::INTEGER, 0)::INTEGER > 0 AS kas_vigane,
                         tulemus -> 'error_message'                                    AS error_message
                  FROM (
                           SELECT to_jsonb(
                                          hooldekodu.arvuta_tasku_raha($2::INTEGER, id::INTEGER,
                                                                       $3::DATE)) tulemus
                           FROM libs.asutus
                           WHERE id IN (
                               SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER
                           )) qry`, //$1 - docs.doc.id, $2 - userId, $3 - kpv
            query: null,
            multuple: false,
            not_initial_load: true,
            alias: 'arvutaTaskuRaha'
        },
        {
            sql: `SELECT row_number() OVER ()                                          AS id,
                         tulemus -> 'result'                                           AS result,
                         tulemus -> 'error_code'                                       AS error_code,
                         coalesce((tulemus ->> 'error_code')::INTEGER, 0)::INTEGER > 0 AS kas_vigane,
                         tulemus -> 'error_message'                                    AS error_message
                  FROM (
                           SELECT to_jsonb(
                                          hooldekodu.koosta_hoo_mk($2::INTEGER, id::INTEGER,
                                                                   $3::DATE)) tulemus
                           FROM libs.asutus
                           WHERE id IN (
                               SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER
                           )) qry`, //$1 - docs.doc.id, $2 - userId, $3 - kpv
            query: null,
            multuple: false,
            not_initial_load: true,
            alias: 'koostaHooMk'
        },
        {
            sql: `SELECT row_number() OVER ()                                          AS id,
                         tulemus -> 'result'                                           AS result,
                         tulemus -> 'error_code'                                       AS error_code,
                         coalesce((tulemus ->> 'error_code')::INTEGER, 0)::INTEGER > 0 AS kas_vigane,
                         tulemus -> 'error_message'                                    AS error_message
                  FROM (
                           SELECT to_jsonb(
                                          hooldekodu.koosta_hoo_vorder($2::INTEGER, id::INTEGER,
                                                                   $3::DATE)) tulemus
                           FROM libs.asutus
                           WHERE id IN (
                               SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER
                           )) qry`, //$1 - docs.doc.id, $2 - userId, $3 - kpv
            query: null,
            multuple: false,
            not_initial_load: true,
            alias: 'koostaHooVorder'
        },
        {
            sql: `SELECT row_number() OVER ()                                          AS id,
                         tulemus -> 'result'                                           AS result,
                         tulemus -> 'error_code'                                       AS error_code,
                         coalesce((tulemus ->> 'error_code')::INTEGER, 0)::INTEGER > 0 AS kas_vigane,
                         tulemus -> 'error_message'                                    AS error_message
                  FROM (
                           SELECT to_jsonb(
                                          hooldekodu.koosta_arve_hootaabeli_alusel($2::INTEGER, id::INTEGER,
                                                                                   $3::DATE)) tulemus
                           FROM libs.asutus
                           WHERE id IN (
                               SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER
                           )) qry`, //$1 - docs.doc.id, $2 - userId, $3 - kpv
            query: null,
            multuple: false,
            not_initial_load: true,
            alias: 'koostaArved'
        },

    ],
    selectAsLibs: `SELECT id,
                          isikukood,
                          nimi,
                          rekvid,
                          hooldekodu,
                          algkpv,
                          loppkpv,
                          makse_viis
                   FROM hooldekodu.com_asutus_hooldekodu hi
                   WHERE hi.rekvid = $1
                   ORDER BY nimi`, //$1 - rekvId

    libGridConfig: {
        grid: [
            {id: "id", name: "id", width: "50px", show: false},
            {id: "regkood", name: "Isikukood", width: "25%"},
            {id: "nimetus", name: "Nimi", width: "75%"}
        ]
    },
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'regkood', type: 'C', serverValidation: 'validateIsikukood'},
        {name: 'nimetus', type: 'C'},
        {name: 'omvorm', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_asutus($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_asutus($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "regkood", name: "Reg.kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "omvorm", name: "Om.vorm", width: "20%"},
            {id: "aadress", name: "Aadress", width: "25%"},
            {id: "valid", name: "Kehtivus", width: "10%", type: 'date', show: false},
        ],
        sqlString: `SELECT a.*, $2::INTEGER AS userId, a.kehtivus AS valid
                    FROM cur_asutused a
                    WHERE libs.check_asutus(a.id::INTEGER, $1::INTEGER)`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curAsutused'
    },

    validateIsikukood: {
        command: `SELECT id
                  FROM libs.asutus
                  WHERE regkood = $1::TEXT
                  ORDER BY id DESC
                  LIMIT 1`,
        type: 'sql',
        alias: 'validateIsikukood'
    },


    print: [
        {
            view: 'asutus_register',
            params: 'id'
        },
        {
            view: 'asutus_register',
            params: 'sqlWhere'
        },
    ],
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
    koostaArved: {
        command: `SELECT row_number() OVER ()                                          AS id,
                         tulemus -> 'result'                                           AS result,
                         tulemus -> 'error_code'                                       AS error_code,
                         coalesce((tulemus ->> 'error_code')::INTEGER, 0)::INTEGER > 0 AS kas_vigane,
                         tulemus -> 'error_message'                                    AS error_message,
                         tulemus ->> 'viitenr'                                         AS viitenr
                  FROM (
                           SELECT to_jsonb(
                                          hooldekodu.koosta_arve_hootaabeli_alusel($2::INTEGER, id::INTEGER,
                                                                                   $3::DATE)) tulemus
                           FROM libs.asutus
                           WHERE id IN (
                               SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER
                           )) qry`, //$1 docId, $2 - userId
        type: 'sql',
        alias: 'koostaArved'
    },

};