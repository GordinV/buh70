module.exports = {
    select: [{
        sql: `SELECT
                  $2 :: INTEGER                                                            AS userid,
                  'PUUDUMINE'                                                              AS doc_type_id,
                  p.id,
                  p.lepingid,
                  p.libid,
                  p.summa,
                  p.kpv1,
                  p.kpv2,
                  p.paevad,
                  coalesce((p.properties ->> 'arvestatud_paevad')::integer, p.paevad)      as arvestatud_paevad,
                  coalesce((p.properties ->> 'arvestatud_paevad_j')::integer, p.paevad)    as arvestatud_paevad_j,
                  p.puudumiste_liik::varchar(20),
                  p.tyyp,
                  p.status,
                  p.muud,
                  t.parentid,
--                  coalesce((p.properties ->> 'palk_oper_id')::integer, 0)::integer         as palk_oper_id,
                  case
                      when (p.properties ->> 'palk_oper_id') is not null and
                           exists
                           (
                               select 1 from palk.palk_oper po where po.parentid = (p.properties ->> 'palk_oper_id')::integer
                           )
                          then (p.properties ->> 'palk_oper_id')::integer
                      else 0 end::integer                                                  as palk_oper_id,

                  (p.properties ->> 'algorithm')::varchar(100)                             as algorithm,
                  (p.properties ->> 'amet')::varchar(254)                                  as amet,
                  case
                      when p.properties ->> 'puhkuse_summa' is not null and
                           (p.properties ->> 'puhkuse_summa')::numeric > 0
                          then (p.properties ->> 'puhkuse_summa')::numeric(12, 2)
                      when p.properties -> 'data' is not null and p.properties -> 'data' -> 0 is not null
                          then (p.properties -> 'data' -> 0 ->> 'summa')::numeric
                      else
                          round((p.properties ->> 'avg_paeva_summa')::numeric *
                                (p.properties ->> 'arvestatud_paevad')::numeric,
                                2) end::numeric(12, 2)                                     as puhkuse_summa,

                  (p.properties ->> 'avg_paeva_summa')::numeric                            as avg_paeva_summa,
                  case
                      when p.properties ->> 'puhkuse_summa' is not null and
                           (p.properties ->> 'puhkuse_summa')::numeric > 0
                          then round((p.properties ->> 'puhkuse_summa')::numeric /
                                     (p.properties ->> 'avg_paeva_summa')::numeric, 0)
                      else (p.properties ->> 'arv_paevad_perioodis')::integer
                      end::integer                                                         as arv_paevad_perioodis,
                  p.properties ->> 'selg'                                                  as selg,
                  coalesce((p.properties ->> 'konto'), '')::varchar(20)                    as konto,
                  (p.properties ->> 'allikas')::varchar(20)                                as allikas,
                  (p.properties ->> 'tegev')::varchar(20)                                  as tegev,
                  (p.properties ->> 'artikkel')::varchar(20)                               as artikkel,
                  (p.properties ->> 'tunnus')::varchar(20)                                 as tunnus,
                  (p.properties ->> 'kpv1')::date                                          as params_kpv1,
                  (p.properties ->> 'kpv2')::date                                          as params_kpv2,
                  (p.properties ->> 'vm_kpv')::date                                        as params_vm_kpv,
                  (p.properties ->> 'kokkuleppe_summa')::numeric                           as kokkuleppe_summa,
                  coalesce((p.properties ->> 'kas_arvesta_parandus')::integer, 0)::integer as kas_arvesta_parandus,
                  pt.vs_kooded,
                  pt.eesti                                                                 as pt_nimetus,
                  (p.properties ->> 'puudumiste_kood')::varchar(20)                        as puudumiste_kood,
                  (p.properties ->> 'puudumise_tyyp')::char(1)                             as puudumise_tyyp,
                  (p.properties ->> 'eelmise_puudumine_id')::integer                       as eelmise_puudumine_id,
                  (p.properties ->> 'allikas_e')::varchar(20)                              as allikas_e,
                  (p.properties ->> 'allikas_j')::varchar(20)                              as allikas_j
              FROM
                  palk.puudumine                               p
                      inner join      palk.tooleping           t on t.id = p.lepingid
                      left outer join palk.com_puudumiste_tyyp pt on pt.liik = p.puudumiste_liik and pt.id = p.tyyp
              WHERE
                  p.id = $1`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER        AS id,
                      $2 :: INTEGER        AS userid,
                      'PUUDUMINE'        AS doc_type_id,
                      0::integer          as parentid,
                      0 :: INTEGER        AS lepingid,
                      0 :: INTEGER        AS libid,
                      0 :: NUMERIC(14, 4) AS summa,
                      now()::date as kpv1,
                      now()::date as kpv2,
                      0::integer as paevad,
                      'PUHKUS'::varchar(20) as puudumiste_liik,
                      0 as tyyp,
                      1 as status,
                      null::integer as palk_oper_id,
                      0::integer as kas_arvesta_parandus,
                      null::date                                          as params_kpv1,
                      null::date                                          as params_kpv2,
                      null::date                                        as params_vm_kpv,   
                      null::text                                       as puudumiste_kood,
                      null::text                                        as puudumise_tyyp,
                      null::integer                       as eelmise_puudumine_id,        
                      null::varchar(20) as allikas_e,
                      null::varchar(20) as allikas_j,           
                      null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `select
                      id,
                      liik::varchar(20),
                      eesti::varchar(120),
                      vene::varchar(120),
                      kas_luba_allikad::integer  
                  from
                      palk.com_puudumiste_tyyp
                  where
                      kas_kehtiv`,
            query: null,
            multiple: true,
            alias: 'com_puudumised',
            data: []

        },
        {
            sql: `
                select
                    p.id , 
                    p.eesti::varchar(254) as nimetus, 
                    pt.kood::varchar(20), 
                    p.liik
                from
                    (select distinct unnest(p.vs_kooded) as kood
                     from palk.com_puudumiste_tyyp p )
                                                            pt
                        inner join palk.com_puudumiste_tyyp p on array[pt.kood] <@ p.vs_kooded
                where
                    p.kas_kehtiv`,
            query: null,
            multiple: true,
            alias: 'com_vs_puudumised',
            data: []

        },
        {
            sql: `SELECT *
                  FROM
                      jsonb_to_recordset((
                                             SELECT
                                                 p.data
                                             from
                                                 palk.sp_import_puudumine_from_virosoft($2::integer, $3::integer,
                                                                                        $1::JSONB) p
                                         )
                      )
                          AS x (error_message TEXT, error_code INTEGER, result INTEGER)`,
            query: null,
            multiple: false,
            alias: 'importDok',
        },
        {
            sql: `select *
                  from
                      palk.calc_avg_income_vacation($1::INTEGER, $2:: JSON) a
                  order by
                      a.puhkuse_summa desc, a.avg_paeva_summa desc`,
            query: null,
            multiple: false,
            alias: 'arvutaKeskPalk',
            data: [],
            not_initial_load: true
        },
        {
            sql: `select *
                  from
                      palk.gen_puhkuse_oper($1::INTEGER, $2:: JSONB) `,
            query: null,
            multiple: false,
            alias: 'genPuhkuseOper',
            data: [],
            not_initial_load: true
        },
        {
            sql: `select *
                  from
                      palk.arvuta_keskpalga_period($1:: JSONB) a`,
            query: null,
            multiple: false,
            alias: 'arvutaKeskPalgaPeriod',
            data: [],
            not_initial_load: true
        },
        {
            sql: `select *
                  from
                      palk.get_keskpalga_details($1::integer, $2::text, $3::text)`,
            query: null,
            multiple: true,
            alias: 'getArvestuseDetails',
            data: [],
            not_initial_load: true

        },
        {
            sql: `select *
                  from
                      palk.get_full_keskpalga_arvestus($1::integer, $2::text, $3::text)`,
            query: null,
            multiple: true,
            alias: 'getFullArvestus',
            data: [],
            not_initial_load: true
        },
        {
            sql: `select *
                  from
                      palk.arvuta_puudumise_paevad($1:: JSONB) a`,
            query: null,
            multiple: false,
            alias: 'arvutaPuudumisePaevad',
            data: [],
            not_initial_load: true
        },
        {
            sql: `select
                      x.kpv1,
                      x.kpv2,
                      x.paevad,
                      case
                          when x.toopaevad is null then
                              palk.get_work_days(jsonb_build_object('kuu', extract(month from x.kpv1),
                                                                    'aasta', extract(year from x.kpv1),
                                                                    'paev', extract(day from x.kpv1),
                                                                    'lopp', extract(day from x.kpv2)) :: JSON)
                          else x.toopaevad end::integer as toopaevad,
                      x.summa::numeric(12, 2),
                      x.alus,
                      x.palk_oper_id,
                      coalesce(x.deleted, '0')          as deleted,
                      $2 :: INTEGER                     AS userid
                  from
                      jsonb_to_recordset(
                              coalesce(
                                      (
                                          select
                                              properties -> 'pk'
                                          from
                                              palk.puudumine p
                                          where
                                                p.id = $1
                                            and p.properties ->> 'pk' is not null
                                      ), '[]'::jsonb || jsonb_build_object(
                                      'kpv1', null::date, 'kpv2', null::date, 'paevad', 0, 'toopaevad', 0, 'summa', 0,
                                      'alus', null, 'palk_oper_id', 0, 'deleted', '1')
                              )
                      ) as x(
                             kpv1 date, kpv2 date, paevad integer, toopaevad integer, summa numeric(12, 2), alus text,
                             palk_oper_id integer, deleted varchar(1))
            `,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        }

    ],
    returnData: {
        row: {},
        comPuudumised: []
    },
    requiredFields: [
        {name: 'puudumiste_liik', type: 'I'},
        {name: 'tyyp', type: 'I'},
        {name: 'lepingid', type: 'I'},
        {name: 'kpv1', type: 'D'},
        {name: 'kpv2', type: 'D'},
        {name: 'paev', type: 'I'}

    ],
    saveDoc: `select palk.sp_salvesta_puudumine($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select
                    error_code,
                    result,
                    error_message
                from
                    palk.sp_delete_puudumine($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "isik", name: "Isik", width: "25%"},
            {id: "ameti_kood", name: "Ameti kood", width: "15%"},
            {id: "amet", name: "Amet", width: "15%"},
            {id: "kpv1", name: "Kpv-st", width: "15%"},
            {id: "kpv2", name: "Kpv-ni", width: "15%"},
            {id: "paevad", name: "Päevad", width: "10%"},
            {id: "pohjus", name: "Põhjus", width: "15%"},
            {id: "liik", name: "Liik", width: "15%"},
        ],
        sqlString: `select
                        a.*,
                        $2::integer as userId
                    from
                        palk.cur_puudumine a
                    where
                        rekvid = $1`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPuudumine'
    },
    executeCommand: {
        command: `select
                      error_code,
                      result,
                      error_message
                  from
                      palk.sp_calc_puhkuse_paevad($1, $2)`, //$1 - user_id, $2 - params (lepingid, tyyp)
        type: 'sql',
        alias: 'calcPuhkusePaevad'
    },
    getLog: {
        command: `SELECT
                      ROW_NUMBER() OVER ()                                                                        AS id,
                      (qry.ajalugu ->> 'user')::VARCHAR(20)                                                       AS kasutaja,
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
                  FROM
                      (
                          SELECT
                              jsonb_array_elements('[]'::jsonb || d.ajalugu) AS ajalugu,
                              d.id
                          FROM
                              palk.puudumine d,
                              ou.userid      u
                          WHERE
                                d.id = $1
                            AND u.id = $2
                      ) qry
                  WHERE
                      (qry.ajalugu ->> 'user') IS NOT NULL
        `,
        type: "sql",
        alias: "getLogs"
    },
    importDoc: {
        comment: 'import from virosoft',
        command: `SELECT
                      result      AS id,
                      result,
                      error_message,
                      $2::integer as userId,
                      $3::integer as rekvId
                  FROM
                      palk.sp_import_puudumine_from_virosoft($2::integer, $3::integer, $1::JSONB)`, // $1 - data json, $2 - userid, $3 - rekvid
        type: 'sql',
        alias: 'importRaama'
    },

};