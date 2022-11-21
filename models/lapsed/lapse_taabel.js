module.exports = {
    selectAsLibs: ``,

    select: [{
        sql: `SELECT lt.id,
                     lt.staatus                                                                AS doc_status,
                     lt.parentid,
                     lt.rekvid,
                     lt.nomid,
                     lt.lapse_kaart_id,
                     lk.properties ->> 'yksus'                                                 AS yksys,
                     lk.properties ->> 'all_yksus'                                             AS all_yksys,
                     lt.umberarvestus::BOOLEAN                                                 AS umberarvestus,
                     coalesce((n.properties ->> 'kas_umberarvestus')::BOOLEAN, FALSE)::BOOLEAN AS kas_umberarvestus,
                     lt.kuu,
                     lt.aasta,
                     lt.kogus,
                     lt.hind,
                     (lt.properties ->> 'alus_hind')::NUMERIC(12, 2)                           AS alus_hind,
                     (lt.properties ->> 'alus_soodustus')::NUMERIC(12, 2)                      AS alus_soodustus,
                     (lt.properties ->> 'sooduse_alg')::DATE                                   AS sooduse_alg,
                     (lt.properties ->> 'sooduse_lopp')::DATE                                  AS sooduse_lopp,
                     lt.soodustus,
                     lt.vahe,
                     lt.summa,
                     lt.muud,
                     l.isikukood,
                     l.nimi,
                     $2                                                                        AS userid,
                     n.kood,
                     n.nimetus                                                                 AS teenus
              FROM lapsed.lapse_taabel lt
                       INNER JOIN lapsed.laps l ON l.id = lt.parentid
                       INNER JOIN libs.nomenklatuur n ON n.id = lt.nomid
                       LEFT OUTER JOIN lapsed.lapse_kaart lk ON lk.id = lt.lapse_kaart_id
              WHERE lt.id = $1::INTEGER`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid,
                  1::integer as doc_status,
                  null::integer as nomid,
                  null::integer as lapse_kaart_id,
                  null::text as yksus,
                  null::text as all_yksus,
                  date_part('month', now()) as kuu,
                  date_part('year', now()) as aasta,
                  0::numeric as kogus,
                  0::numeric as hind,
                  0::numeric as alus_hind,
                  0::numeric as alus_soodustus,
                  null::date as sooduse_alg,
                  null::date as sooduse_lopp,
                  0::numeric as soodustus,
                  0::numeric as summa,
                  0::numeric as vahe,
                  false as umberarvestus,
                  false as kas_umberarvestus,                  
                  null::text as isikukood,
                  null::text as nimi,
                  null::text as kood,
                  null::text as nimetus,
                  null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }
    ],
    returnData:
        {
            row: {}
        }
    ,


    requiredFields: [
        {name: 'lapse_kaart_id', type: 'I'},
        {name: 'parentid', type: 'I'},
        {name: 'kogus', type: 'N'},
        {name: 'kuu', type: 'I'},
        {name: 'aasta', type: 'I'}

    ],
    saveDoc:
        `select lapsed.sp_salvesta_lapse_taabel($1::jsonb, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT lapsed.sp_delete_lapse_taabel($1::INTEGER, id::INTEGER)
                FROM lapsed.cur_lapse_taabel
                WHERE id::TEXT IN (SELECT unnest(string_to_array($2::TEXT, ',')))`, // $1 - userId, $2 - docId
    grid:
        {
            gridConfiguration: [
                {id: "id", name: "id", width: "1%", show: false},
                {id: "isikukood", name: "Isikukood", width: "10%"},
                {id: "nimi", name: "Nimi", width: "20%"},
                {id: "viitenumber", name: "Viitenumber", width: "10%"},
                {id: "viitenr", name: "Vana VN", width: "6%"},
                {id: "teenus", name: "Teenus", width: "25%"},
                {id: "yksus", name: "Üksus", width: "15%"},
                {id: "kuu", name: "Kuu", width: "5%", type: "integer", interval: true},
                {id: "aasta", name: "Aasta", width: "5%", type: "integer"},
                {id: "kogus", name: "Kogus", width: "8%", type: "number", interval: true},
                {id: "hind", name: "Hind", width: "8%", type: "number", interval: true},
                {id: "uhik", name: "Ühik", width: "5%"},
                {id: "arv_soodustus", name: "Soodustus", width: "10%", type: "number", show: true},
                {id: "arv_summa", name: "Summa", width: "10%", type: "number", interval: true},
                {id: "vahe", name: "Vahe", width: "5%", type: "number", interval: true},
                {id: "umberarvestus", name: "Ümberarv", width: "7%"},
                {id: "tab_tyyp", name: "Tüüp", width: "10%", type: "text"},
                {id: "select", name: "Valitud", width: "10%", show: false, type: 'boolean', hideFilter: true}
            ],
            sqlString:
                `WITH is_ettemaks AS (
                         SELECT exists(SELECT 1
                                       FROM lapsed.lapse_kaart lk
                                       WHERE lk.rekvid in (SELECT rekv_id
                                                         FROM get_asutuse_struktuur($1::INTEGER))                         
                                         AND (lk.properties -> 'kas_ettemaks') = 'true'
                                         AND lk.staatus <> 3
                                    ) AS kas_ettemaks
                     ),                                 
                     qryTabs AS
                         (SELECT 
                                 lt.id,
                                 lt.parentid,
                                 lt.rekvid,
                                 lt.nomid,
                                 lt.kuu::INTEGER,
                                 lt.aasta::INTEGER,
                                 lt.kogus::NUMERIC(12, 4),
                                 lt.hind::NUMERIC(12, 2),
                                 lt.uhik,
                                 CASE WHEN lt.umberarvestus THEN 'Jah' ELSE 'Ei' END::TEXT                    AS umberarvestus,
                                 lt.alus_soodustus AS alus_soodustus,
                                 lt.soodustus AS soodustus,
                                 lt.arv_soodustus::NUMERIC(12, 2) AS arv_soodustus,
                                 lt.arv_soodustus_kokku::NUMERIC(12, 2) AS arv_soodustus_kokku,
                                 lt.summa                                                   AS summa,
                                 lt.arv_summa::NUMERIC(12, 2) as arv_summa,
                                 lt.isikukood,
                                 lt.nimi,
                                 lt.kood,
                                 lt.teenus,
                                 (coalesce(lt.yksus, '') ||
                                  CASE WHEN lt.all_yksus IS NULL THEN '' ELSE '-' || lt.all_yksus END)        AS yksus,
                                  lt.viitenr,
                                 $2::INTEGER                                                           AS userid,
                                 lt.muud,
                                 lt.kulastused,
                                 lt.too_paevad,
                                 lt.kovid,
                                 lt.vahe::numeric
                          FROM lapsed.cur_lapse_taabel lt
                          WHERE lt.rekvid in
                          (SELECT rekv_id
                                                         FROM get_asutuse_struktuur($1::INTEGER))                         
                         ),
                     qryVirtTabs AS (SELECT FALSE::boolean                                  AS select,
                                            lt.id,
                                            lt.parentid,
                                            lt.rekvid,
                                            lt.nomid,
                                            lt.kuu::INTEGER,
                                            lt.aasta::INTEGER,
                                            lt.kogus::NUMERIC(12, 4),
                                            lt.hind::NUMERIC(12, 2),
                                            lt.uhik,
                                            'Ei'                    AS umberarvestus,
                                            (CASE
                                                 WHEN lt.kas_protsent::BOOLEAN THEN (lt.hind * lt.kogus)::NUMERIC(12, 2) *
                                                                           ((lt.soodustus * lt.sooduse_kehtivus) / 100)
                                                 ELSE lt.soodustus * lt.kogus * lt.sooduse_kehtivus END)::NUMERIC(12, 2) AS alus_soodustus,
                                            (CASE
                                                 WHEN lt.kas_protsent::BOOLEAN THEN (lt.hind * lt.kogus)::NUMERIC(12, 2) *
                                                                           ((lt.soodustus * lt.sooduse_kehtivus) / 100)
                                                 ELSE lt.soodustus * lt.kogus * lt.sooduse_kehtivus END)::NUMERIC(12, 2) AS soodustus,
                                                 
                                            ((lt.hind * lt.kogus - (CASE
                                                                        WHEN lt.kas_protsent::BOOLEAN THEN (lt.hind * lt.kogus)::NUMERIC(12, 2) *
                                                                                                  ((lt.soodustus * lt.sooduse_kehtivus) / 100)
                                                                        ELSE lt.soodustus * lt.kogus * lt.sooduse_kehtivus
                                                END)))::NUMERIC(12, 2)                                                   AS summa,
                                            lt.isikukood,
                                            lt.nimi,
                                            lt.kood,
                                            lt.teenus,
                                            (coalesce(lt.yksus, '') ||
                                             CASE WHEN lt.all_yksus IS NULL THEN '' ELSE '-' || lt.all_yksus END)        AS yksus,
                                             lt.viitenr,
                                 $2::INTEGER                                                           AS userid,
                                 ''::text as muud
                                     FROM is_ettemaks,
                                        lapsed.cur_lapse_virtuaal_taabel lt
                                     WHERE is_ettemaks.kas_ettemaks::BOOLEAN
                                        and lt.rekvid in (SELECT rekv_id
                                                         FROM get_asutuse_struktuur($1::INTEGER))                         

                     )
                SELECT id::integer, "select", parentid, rekvid, nomid, kuu, aasta, kogus, hind, uhik, umberarvestus, 
                            alus_soodustus, soodustus, arv_soodustus::NUMERIC(12, 2), arv_soodustus_kokku, summa, arv_summa,
                            isikukood,  nimi, kood, teenus, yksus, viitenr, userid, muud,                            
                            tab_tyyp, kulastused, too_paevad, kovid, vahe,
                            lapsed.get_viitenumber(rekvid, parentid) AS viitenumber
                FROM (
                         select false:: boolean as select, id::integer, parentid, rekvid, nomid, kuu, aasta, kogus, hind, uhik, umberarvestus, 
                            alus_soodustus, soodustus, arv_soodustus, arv_soodustus_kokku, summa, arv_summa, 
                            isikukood,  nimi, kood, teenus, yksus, viitenr, userid, muud,                           
                            'Tavaline' as tab_tyyp, kulastused, too_paevad, kovid, vahe
                         from qryTabs
                         UNION ALL
                         SELECT false:: boolean as select, id::integer, parentid, rekvid, nomid, kuu, aasta, kogus, hind, uhik, umberarvestus, 
                            alus_soodustus, soodustus, soodustus as arv_soodustus, soodustus  as arv_soodustus_kokku, summa, summa as arv_summa, 
                            isikukood,  nimi, kood, teenus, yksus, viitenr, userid, muud,                           
                            'Virtuaalne' as tab_tyyp, 0 as kulastused, 0 as too_paevad , 0 as kovid, 0.00::numeric as vahe                                                         
                         FROM qryVirtTabs
                     ) tab
                ORDER BY aasta DESC, kuu DESC, nimi`,     //  $1 всегда ид учреждения, $2 - userId
            params: '',
            alias: 'curLapseTaabel',
            totals: `sum(arv_soodustus_kokku) over() as soodustus_kokku,  
                   sum(arv_summa) over() as summa_kokku, sum(vahe) over() as vahe_kokku `
        },
    print: [
        {
            view: 'lapse_taabel_register',
            params: 'id'
        },
        {
            view: 'lapse_taabel_register',
            params: 'sqlWhere'
        },
    ],
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                               AS id,
                         (ajalugu ->> 'user')::TEXT                                         AS kasutaja,
                         to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS') AS koostatud,
                         to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS') AS muudatud,
                         to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS')   AS prinditud,
                         to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS') AS kustutatud

                  FROM (
                           SELECT jsonb_array_elements(d.ajalugu) AS ajalugu
                           FROM lapsed.lapse_taabel d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry`,
        type: "sql",
        alias: "getLogs"
    },
    importTaabel: {
        command: `SELECT error_code, result, error_message
                  FROM lapsed.import_laste_taabelid($1::JSONB, $2::INTEGER, $3::INTEGER)`,//$1 data [], $2 - userId, $3 rekvid
        type: 'sql',
        alias: 'importTaabel'
    }


};

