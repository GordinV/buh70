module.exports = {
    selectAsLibs: `SELECT *
                   FROM com_projekt l
                   WHERE (l.rekvId = $1 OR l.rekvid IS NULL)`,
    select: [{
        sql: `SELECT
                  l.id,
                  l.rekvid,
                  l.kood,
                  l.nimetus,
                  l.muud,
                  l.status,
                  l.library,
                  $2::INTEGER                                     AS userid,
                  'PROJECT'                                       AS doc_type_id,
                  (l.properties::JSONB ->> 'proj_alates')::DATE   AS proj_alates,
                  (l.properties::JSONB ->> 'proj_kuni')::DATE     AS proj_kuni,
                  (l.properties::JSONB ->> 'proj_summa')::Numeric AS proj_summa,
                  (l.properties::JSONB ->> 'valid')::DATE         AS valid
              FROM
                  libs.library l
              WHERE
                  l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            $2::integer as userid, 
            'PROJECT' as doc_type_id,
            ''::text as  kood,
            0::integer as rekvid,
            ''::text as nimetus,
            'PROJ'::text as library,
            0::integer as status,
            null::date as proj_alates,
            null::date as proj_kuni,
            null::numeric as proj_summa,
            null::date as valid,
            null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `with
                      proj_details as (
                                          SELECT
                                              $2 :: INTEGER                                                                AS userid,
                                              l.kood,
                                              l.nimetus,
                                              (l.properties::JSONB ->> 'proj_alates')::DATE                                AS proj_alates,
                                              (l.properties::JSONB ->> 'proj_kuni')::DATE                                  AS proj_kuni,
                                              l.rekvid                                                                     as rekv_id,
                                              a.regkood                                                                    as isikukood,
                                              a.nimetus                                                                    as isik,
                                              pl.proj_id                                                                   as parentid,
                                              amet.kood                                                                    as amet,
                                              coalesce((l.properties::jsonb ->> 'proj_summa')::numeric, 0)::numeric(12, 2) as proj_summa,
                                              pl.selgitus                                                                  as selgitus,
                                              pl.leping_id,
                                              pl.proj_id,
                                              pl.kuu_summa,
                                              pl.summa::numeric(12, 2)                                                     as summa,
                                              pl.korrigeerimine::numeric(12, 2)                                            as korrigeerimine,
                                              pl.sm::numeric(12, 2)                                                        as sm,
                                              palk.get_projekt_kasutatud_summa(pl.leping_id:: integer,
                                                                               pl.proj_id:: INTEGER,
                                                                               coalesce((l.properties::JSONB ->> 'proj_kuni')::DATE, date()),
                                                                               'sm')::numeric(12, 2)                       as sm_kasutatud,
                                              palk.get_projekt_kasutatud_summa(pl.leping_id:: integer,
                                                                               pl.proj_id:: INTEGER,
                                                                               coalesce((l.properties::JSONB ->> 'proj_kuni')::DATE, date()),
                                                                               'summa')::numeric(12, 2)                    as kasutatud,
                                              round(((l.properties::jsonb ->> 'proj_kuni')::date -
                                                     (l.properties::jsonb ->> 'proj_alates')::date) / 30,
                                                    0)                                                                     as proj_osad_kokku,
                                              coalesce(round((get_last_day((
                                                                               select
                                                                                   max(kpv) as kpv
                                                                               from
                                                                                   palk.palk_oper po
                                                                               where
                                                                                     po.kpv < get_last_day(current_date)
                                                                                 and po.lepingid = tl.id
                                                                                 and po.kpv >= (l.properties::jsonb ->> 'proj_alates')::date
                                                                           )) -
                                                              (l.properties::jsonb ->> 'proj_alates')::date)::numeric /
                                                             30,
                                                             0),
                                                       0)                                                                  as cur_osad_used

                                          FROM
                                              libs.library                      l
                                                  inner join libs.proj_laiendus pl on l.id = pl.proj_id
                                                  inner join palk.tooleping     tl on tl.id = pl.leping_id
                                                  inner join libs.asutus        a on a.id = tl.parentid
                                                  inner join libs.library       amet on amet.id = tl.ametid
                                          WHERE
                                              pl.proj_id = $1
                      )
                  select
                      pd.*,
                      (pd.summa + korrigeerimine - pd.kasutatud)::numeric(12, 2)     as jaak,
                      (pd.sm - pd.sm_kasutatud)::numeric(12, 2)                      as sm_jaak,
                      case
                          when (pd.kuu_summa * pd.cur_osad_used - pd.kasutatud) > 0
                              then (pd.kuu_summa * pd.cur_osad_used - pd.kasutatud)
                          else 0 end::numeric(12, 2)                                 as tagastus,
                      ((case
                            when (pd.kuu_summa * pd.cur_osad_used - pd.kasutatud) > 0
                                then (pd.kuu_summa * pd.cur_osad_used - pd.kasutatud)
                            else 0 end) * (pc.sm + pc.tka) * 0.01) ::numeric(12, 2)  as sm_tagastus,
                      (pd.korrigeerimine * (pc.sm + pc.tka) * 0.01) ::numeric(12, 2) as sm_korrigeerimine

                  from
                      proj_details     pd,
                      palk.palk_config pc
                  where
                      pc.rekvid = pd.rekv_id
                  order by
                      pd.isik, pd.amet

            `, //$1 doc_id, $2 userId
            multiple: true,
            alias: 'details',
            data: []
        },
        {
            sql: `SELECT $1 AS rekv_id, *
                  FROM jsonb_to_recordset(
                               get_proj_kasutus($2::INTEGER, $3::DATE)
                           ) AS x (error_message TEXT, error_code INTEGER)
                  WHERE error_message IS NOT NULL
            `, //$1 rekvid, $2 v_nom.kood
            query: null,
            multiple: true,
            alias: 'validate_lib_usage',
            data: []
        },
        {
            sql: `select
                      sum(summa) as summa
                  from
                      cur_journal
                  where
                        rekvid = $1::integer
                    and deebet like '100100%'
                    and kpv >= $2::date
                    and kpv <= $3::date
                    and kood2 = '60'
                    and kood5 = '3500'
                    and proj = $4::varchar(20)`,
            query: null,
            multiple: true,
            alias: 'get_projekt_summa',
            data: []

        },
        {
            sql: `select
                      leping_Id:: INTEGER,
                      proj_id:: INTEGER,
                      isik:: varchar(254),
                      amet:: varchar(254),
                      summa:: NUMERIC(14, 2),
                      sm:: numeric(14, 2),
                      selgitus::text 
                  from
                      palk.get_projekt_jaotamine($1::integer, $2::numeric)`, // $1 proj_id, $2 summa
            query: null,
            multiple: true,
            alias: 'get_projekti_jaotamine',
            data: []
        },
        {
            sql: `select palk.paranda_palga_kaardid($1::integer, $2::integer)`, // $1 usewrid, $2 proj_id
            query: null,
            multiple: true,
            alias: 'paranda_palga_kaardid',
            data: []
        }


    ],
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'kood', type: 'C'},
        {name: 'nimetus', type: 'C'},
        {name: 'library', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_proj($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_library($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"}
        ],
        sqlString: `SELECT id,
                           kood,
                           nimetus,
                           $2::INTEGER                           AS userId,
                           (properties::JSONB ->> 'valid')::DATE AS valid
                    FROM libs.library l
                    WHERE l.library = 'PROJ'
                      AND l.status <> 3
                      AND (l.rekvId = $1 OR l.rekvid IS NULL)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curProjektid'
    },
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()              AS id,
                         (ajalugu ->> 'user')::VARCHAR(20) AS kasutaja,
                         coalesce(to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)         AS koostatud,
                         coalesce(to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)         AS muudatud,
                         coalesce(to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)         AS prinditud,
                         coalesce(to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)         AS kustutatud

                  FROM (SELECT $2                                                      AS user_id,
                               jsonb_array_elements(jsonb_agg(jsonb_build_object('updated', propertis ->> 'updated', 'user',
                                                            ltrim(rtrim(u.kasutaja))))) AS ajalugu
                        FROM ou.logs l
                                 LEFT OUTER JOIN ou.userid u ON u.id = l.user_id
                        WHERE propertis ->> 'table' = 'library'
                          AND doc_id = $1) qry
        `,
        type: "sql",
        alias: "getLogs"
    },

};
