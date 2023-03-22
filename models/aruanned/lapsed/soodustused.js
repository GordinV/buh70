module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "vanem_isikukood", name: "Vanem isikukood", width: "10%"},
            {id: "vanem_nimi", name: "Vanem nimi", width: "15%"},
            {id: "lapse_isikukood", name: "Lapse isikukood", width: "10%"},
            {id: "lapse_nimi", name: "Lapse nimi", width: "15%"},
            {id: "lapsed", name: "Lapsed kokku", width: "15%", type: "number",interval: true},
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
                     soodtused AS (
                         SELECT jsonb_agg(jsonb_build_object('kokku', kokku, 'kood', kood, 'soodustus', soodustus, 'percent', percent, 
                            'kokku_total',kokku_total, 'soodustus_total',soodustus_total)) AS kokkuvote
                         FROM (
                  SELECT sum(kokku) OVER ()     AS kokku_total,
                         sum(soodustus) OVER () AS soodustus_total,
                         *
                  FROM (
                           SELECT count(*)            AS kokku,
                                  CASE
                                      WHEN left(kood, 6) IN ('322020', '322030')
                                          THEN '322020,322030'
                                      ELSE 'MUUD' END AS kood,
                                  percent,
                                  sum(soodustus)      AS soodustus
                           FROM report
                           WHERE soodustus > 0
                           GROUP BY CASE
                                        WHEN left(kood, 6) IN ('322020', '322030') THEN '322020,322030'
                                        ELSE 'MUUD' END, percent
                           HAVING NOT empty(percent)
                              AND percent <> '0'
                           ORDER BY percent) qry
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
