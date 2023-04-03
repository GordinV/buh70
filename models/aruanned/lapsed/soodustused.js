module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "vanem_isikukood", name: "Esindaja isikukood", width: "10%"},
            {id: "vanem_nimi", name: "Esindaja nimi", width: "15%"},
            {id: "lapse_isikukood", name: "Lapse isikukood", width: "10%"},
            {id: "lapse_nimi", name: "Lapse nimi", width: "15%"},
            {id: "lapsed", name: "Lapsed kokku", width: "15%", type: "number", interval: true},
            {id: "viitenumber", name: "Viitenumber", width: "10%"},
            {id: "vana_vn", name: "Vana VN", width: "10%"},
            {id: "soodustus", name: "Soodustus", width: "5%", type: "number"},
            {id: "arv_percent", name: "Sood(%)", width: "5%", type: "number"},
            {id: "period", name: "Period", width: "5%", show: false, type: "date", interval: true},
            {id: "viga", name: "Viga", width: "10%"},
            {id: "asutus", name: "Asutus", width: "10%"},
        ],
        sqlString: `with report as (select * from lapsed.soodustused($1, 1, $3, $4)),
                     pered AS (
                         SELECT jsonb_agg(jsonb_build_object('lapsed', coalesce(lapsed,0), 'pered_kokku', pered_kokku, 'kokku', kokku)) AS kokkuvote
                
                         FROM (
                                select sum(pered_kokku) over() as kokku, pered_kokku, lapsed from (
                                  SELECT  count(*)  as pered_kokku , lapsed
                                  FROM (select distinct vanem_id, lapsed from report) report
                                 group by lapsed order by lapsed) rep
                             ) qry
                     ),
                     lapsed AS (
                                      SELECT  count(*) AS kogus, percent
                                      FROM (
                                               SELECT DISTINCT lapse_isikukood, arv_percent as percent
                                               FROM report
                                           ) qry
                                      GROUP BY percent
                                  ),                     
                     soodtused AS (
                         SELECT jsonb_agg(jsonb_build_object('kokku', kokku_total,
                                                             'lapsed', kogus,
                                                             'lapsed_total', kogus_total,                         
                                                             'kood', kood_total,
                                                             'soodustus', soodustus,
                                                             'percent', percent,
                                                             'kokku', kokku,
                                                             'soodustus_total', soodustus_total,
                                                             'kokku_total', kokku_total,                                                             
                                                             'kokku_322020', kokku_322020,
                                                             'soodustus_322020', soodustus_322020,
                                                             'kokku_322030', kokku_322030,
                                                             'soodustus_322030', soodustus_322030,
                                                             'soodustus_322020_total', soodustus_322020_total,
                                                             'soodustus_322030_total', soodustus_322030_total,
                                                             'kokku_322020_total', kokku_322020_total,
                                                             'kokku_322030_total', kokku_322030_total,
                                                             'soodustus_rea_summa',(soodustus_322020 + soodustus_322030),                                                     
                                                             'soodustus_rea_total',(soodustus_322020_total + soodustus_322030_total)                                                    
                                                             
                             )
                                    ) AS kokkuvote
                         FROM (
                                  SELECT sum(soodustus_322020) OVER () AS soodustus_322020_total,
                                         sum(soodustus_322030) OVER () AS soodustus_322030_total,
                                         sum(kokku_322020) OVER ()     AS kokku_322020_total,
                                         sum(kokku_322030) OVER ()     AS kokku_322030_total,                                         
                                         sum(soodustus) OVER ()  AS soodustus_total,
                                         sum(kokku) over() as kokku_total,
                                         sum(kogus) OVER ()            AS kogus_total,                                         
                                         soodustus,
                                         kokku,
                                         kood_total,
                                         kokku_322020,
                                         kokku_322030,
                                         soodustus_322020,
                                         soodustus_322030,
                                         pre_rep.percent,
                                         l.kogus
                                  FROM (
                                           WITH qry AS (SELECT count(*)       AS kokku,
                                                               left(kood, 6)  AS kood,
                                                               arv_percent as percent,
                                                               sum(soodustus) AS soodustus
                                                        FROM report
                                                        WHERE soodustus > 0
                                                        GROUP BY left(kood, 6), arv_percent
                                                        HAVING NOT empty(arv_percent)
                                                        ORDER BY arv_percent)
                                           SELECT sum(kokku)                             AS kokku,
                                                  sum(soodustus)                         AS soodustus,
                                                  '322020,322030'                        AS kood_total,
                                                  sum(kokku) FILTER (WHERE kood =
                                                                           '322020')     AS kokku_322020,
                                                  sum(kokku) FILTER (WHERE kood =
                                                                           '322030')     AS kokku_322030,
                                                  sum(soodustus) FILTER (WHERE kood =
                                                                               '322020') AS soodustus_322020,
                                                  sum(soodustus) FILTER (WHERE kood =
                                                                               '322030') AS soodustus_322030,
                                                  percent
                                           FROM qry
                                           GROUP BY percent
                                       ) pre_rep
                                           LEFT OUTER JOIN lapsed l ON l.percent = pre_rep.percent                                       
                              ) rep
                                     ),
                     
                     kokku_lapsed as (
                        select count(*) as kokku from (
                            SELECT DISTINCT lapse_isikukood FROM report
                        ) qry
                     )
                     
                    SELECT row_number() OVER () AS id,
                           kokku_lapsed.kokku   AS lapsed_kokku,
                           vead_kokku           AS vead_kokku,
                           summa                AS summa,
                           soodustus,
                           percent::TEXT        AS percent,
                           arv_percent::TEXT    AS arv_percent,
                           period               AS period,
                           lapse_isikukood,
                           lapse_nimi,
                           vanem_nimi,
                           vanem_isikukood,
                           lapsed,
                           pered_kokku,
                           asutus,
                           viga::TEXT           AS viga,
                           kood::TEXT           AS kood,
                           $2                   AS user_id,
                           vn.vn                AS vana_vn,
                           qry.viitenumber,
                           pered.kokkuvote      AS pered_kokkuvote,
                           soodtused.kokkuvote  AS soodustus_kokkuvote                                                      
                    FROM report qry
                             LEFT OUTER JOIN (SELECT string_agg(viitenumber, ', ') AS vn, vn.isikukood
                                              FROM lapsed.viitenr vn
                                              WHERE vn.rekv_id IN (SELECT rekv_id
                                                                   FROM get_asutuse_struktuur($1))
                                                  GROUP BY vn.isikukood
                    ) vn
                                             ON vn.isikukood = qry.lapse_isikukood,
                                             pered,
                                             soodtused,
                                             kokku_lapsed
                    ORDER BY vanem_isikukood, lapse_nimi
        `,     // $1 - rekvid, $3 - kond
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
        min_params: 2,
        notReloadWithoutParameters: true,
        alias: 'soodustused_report'
    },
    print: [
        {
            view: 'soodustused_register',
            params: 'sqlWhere',
            group: 'vanem_isikukood'
            /*            converter: function (data) {
                            let pered_2 = 0;

                            let pered_3 = 0;
                            let pered_4 = 0;
                            let pered = new Set; // сюда пишем ид счетом, которые под обработку

                            data.forEach(row => {
                                pered_2 = pered_2 + Number(row.lapsed == 2 ? 1: 0);
                                pered_3 = pered_3 + Number(row.lapsed == 3 ? 1: 0);
                                pered_4 = pered_4 + Number(row.lapsed > 3 ? 1: 0);
                            });

                            return data.map(row => {
                                row.pered_2 = pered_2;
                                row.pered_3 = pered_3;
                                row.pered_3 = pered_4;
                                return row;
                            })
                            return out;


            }
*/
        },
    ],

};
