module.exports = {
    grid: {
        gridConfiguration: [
            {id: "period", name: "Period", width: "5%", show: false, type: "date", interval: false},
            {id: "maksja_nimi", name: "Maksja nimi", width: "30%"},
            {id: "maksja_isikukood", name: "Maksja isikukood", width: "10%", show: true},
            {id: "saldo", name: "Saldo", width: "10%", type: "number", interval: true},
            {id: "kokku_kuued", name: "Ettemaksu vanus", width: "15%", type: "integer", interval: true},
            {id: "viimane_tehing_print", name: "Viimane tehing", width: "15%", type: "date", interval: true, show: true},
            {id: "asutus", name: "Asutus", width: "20%"},
        ],
        sqlString: `with
                        params as (
                                      select
                                          $3::DATE::date as kpv,
                                          $1             as rekv_id,
                                          1              as kond
                                  ),
                        saldo as (
                                      SELECT
                                          p.kpv as period,
                                          rep.konto,
                                          rep.alg_saldo + rep.deebet - rep.kreedit as saldo,
                                          rep.asutus_id,
                                          rep.viimane_tehing,
                                          to_char(rep.viimane_tehing,'DD.MM.YYYY') as viimane_tehing_print,
                                          rep.rekv_id
                                      FROM
                                          params                              p,
                                          docs.kaibeasutusandmik('1030002%'::text, null::integer, p.kpv::date, p.kpv::date, p.rekv_id::integer,
                                                                 '%'::text, p.kond::integer) rep
                                  ),
                        report as (
                                      select
                                          $2                                               AS user_id,
                                          sum(s.saldo) over ()                             as saldo_kokku,
                                          EXTRACT(year from age(p.kpv, s.viimane_tehing)) * 12 +
                                          EXTRACT(month FROM age(p.kpv, s.viimane_tehing)) AS kokku_kuued,
                                          s.*
                                      from
                                          params p,
                                          saldo  s
                                      where
                                          s.saldo < 0
                                  )
                    select
                        rep.*,
                        a.nimetus as maksja_nimi,
                        a.regkood as maksja_isikukood,
                        r.nimetus as asutus
                    from
                        report                     rep
                            inner join libs.asutus a on a.id = rep.asutus_id
                            inner join ou.rekv     r on r.id = rep.rekv_id
                    where
                        rep.kokku_kuued >= 12
                    order by
                        r.nimetus, a.nimetus
        `,     // $1 - rekvid, $3 - alg_kpv, $4 - lopp_kpv
        params: ['rekvid', 'userid', 'period'],
        min_params: 2,
        notReloadWithoutParameters: true,
        alias: 'ettemaksete_report'
    },
    print: [
        {
            view: 'ettemaksete_register',
            params: 'sqlWhere',
            group: ['asutus'],
            converter: function (data) {
                let saldo_kokku = 0;
                let row_id = 0;
                let groupedData = {};
                data.forEach(row => {
                    saldo_kokku = Number(saldo_kokku) + Number(row.saldo);
                });

                return data.map(row => {
                    row_id++;
                    row.saldo_kokku = saldo_kokku;
                    row.row_id = row_id;
                    return row;
                })
            }

        },
    ],

};
