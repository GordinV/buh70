module.exports = {
    grid: {
        gridConfiguration: [
            {id: "konto", name: "konto", width: "25px", show: false},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "alg_db", name: "Alg.Deebet", width: "100px"},
            {id: "alg_kr", name: "Alg.Kreedit", width: "75px"},
            {id: "deebet", name: "Deebet", width: "100px"},
            {id: "kreedit", name: "Kreedit", width: "100px"},
            {id: "lopp_db", name: "Lõpp deebet", width: "100px"},
            {id: "lopp_kr", name: "Lõpp kreedit", width: "200px"}
        ],
        sqlString: `with
                        params as (
                                      select
                                          case
                                              when $1::date > $2::date then date(year($2::date), month($2::date), 1)
                                              else $1::date end::date as kpv1,
                                          $2::date                    as kpv2,
                                          r.id                        as rekv_id,
                                          $4::integer                 as kond,
                                          r.regkood
                                      from
                                          ou.rekv r
                                      where
                                          id = $3::integer

                                  ),
                        report as (
                                      select
                                          *
                                      FROM
                                          params                           p,
                                          palk.tsd_2026(p.kpv1::date, p.kpv2::date, p.rekv_id::integer,
                                                          p.kond::integer) qry
                                  )
                    select
                        r.*
                    from
                        report r
                    order by
                        r.isikukood, r.tululiik`,     //  $1 - kpv1, $2 - kpv2, $3 - rekvid, $4 svod (null)
        params: '',
        alias: 'tsd_2026'
    },
    ai : {
        endpoint: `https://check-xml-1088344506167.europe-north1.run.app`,
        type: `link`,
        alias: `ai`
    },

};
