module.exports = {
    grid: {
        gridConfiguration: [
            {id: "konto", name: "konto", width: "25px", show: false},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "alg_db", name: "Alg.Deebet", width: "100px"},
            {id: "alg_kr", name: "Alg.Kreedit", width: "75px"},
            {id: "deebet", name: "Deebet", width: "100px"},
            {id: "kreedit", name: "Kreedit", width: "100px"},
            {id: "alopp_db", name: "Lõpp deebet", width: "100px"},
            {id: "lopp_kr", name: "Lõpp kreedit", width: "200px"}
        ],
        sqlString: `SELECT *
                    FROM eelarve.eelarve_andmik_lisa_1_5($1::DATE, $2::INTEGER,
                                                         $3::INTEGER)
                    WHERE NOT EMPTY(tegev)
                       OR NOT empty(artikkel)
                       OR NOT EMPTY(saldoandmik)
                    ORDER BY tegev, artikkel`,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'eelarve_andmik_lisa_1_5_report'
    },
    select: [
        {
            sql: `SELECT eelarve::CHAR(20),
                         eelarve_taps::CHAR(20),
                         eelarve_kassa::CHAR(20),
                         eelarve_kassa_taps::CHAR(20),
                         saldoandmik::CHAR(20),
                         kassa::CHAR(20),
                         selg::TEXT
                  FROM eelarve.lisa1_lisa5_kontrol_pohitegevuse_tulud($1::TEXT, $2::JSON, $3::JSON) WHERE (eelarve <> 0
                      AND eelarve_taps <> 0
                      AND eelarve_kassa <> 0
                      AND eelarve_kassa_taps <> 0
                      AND saldoandmik <> 0
                      AND kassa <> 0
                  )
                  OR
                  COALESCE(selg,'') ='test'`,
            query: null,
            multiple: true,
            alias: 'kontrol_pohitegevuse_tulud',
            data: []

        },
        {
            sql: `SELECT eelarve::CHAR(20),
                         eelarve_taps::CHAR(20),
                         eelarve_kassa::CHAR(20),
                         eelarve_kassa_taps::CHAR(20),
                         saldoandmik::CHAR(20),
                         kassa::CHAR(20),
                         selg::TEXT
                  FROM eelarve.lisa1_lisa5_kontrol_30($1::TEXT, $2::JSON, $3::JSON) where (eelarve <> 0
                      AND eelarve_taps <> 0
                      AND eelarve_kassa <> 0
                      AND eelarve_kassa_taps <> 0
                      AND saldoandmik <> 0
                      AND kassa <> 0
                  )
                  OR
                  COALESCE
                  (
                  selg
                  ,
                  ''
                  )
                  =
                  'test'`,
            query: null,
            multiple: true,
            alias: 'kontrol_30',
            data: []

        },
        {
            sql: `SELECT eelarve::CHAR(20),
                         eelarve_taps::CHAR(20),
                         eelarve_kassa::CHAR(20),
                         eelarve_kassa_taps::CHAR(20),
                         saldoandmik::CHAR(20),
                         kassa::CHAR(20),
                         selg::TEXT
                  FROM eelarve.lisa1_lisa5_kontrol_3000($1::TEXT, $2::JSON, $3::JSON) where (eelarve <> 0
                      AND eelarve_taps <> 0
                      AND eelarve_kassa <> 0
                      AND eelarve_kassa_taps <> 0
                      AND saldoandmik <> 0
                      AND kassa <> 0
                  )
                  OR
                  COALESCE
                  (
                  selg
                  ,
                  ''
                  )
                  =
                  'test'`,
            query: null,
            multiple: true,
            alias: 'kontrol_3000',
            data: []
        },
        {
            sql: `SELECT eelarve::CHAR(20),
                         eelarve_taps::CHAR(20),
                         eelarve_kassa::CHAR(20),
                         eelarve_kassa_taps::CHAR(20),
                         saldoandmik::CHAR(20),
                         kassa::CHAR(20),
                         selg::TEXT
                  FROM eelarve.lisa1_lisa5_kontrol_3030($1::TEXT, $2::JSON, $3::JSON) where (eelarve <> 0
                      AND eelarve_taps <> 0
                      AND eelarve_kassa <> 0
                      AND eelarve_kassa_taps <> 0
                      AND saldoandmik <> 0
                      AND kassa <> 0
                  )
                  OR
                  COALESCE
                  (
                  selg
                  ,
                  ''
                  )
                  =
                  'test'`,
            query: null,
            multiple: true,
            alias: 'kontrol_3030',
            data: []
        },
        {
            sql: `SELECT eelarve::CHAR(20),
                         eelarve_taps::CHAR(20),
                         eelarve_kassa::CHAR(20),
                         eelarve_kassa_taps::CHAR(20),
                         saldoandmik::CHAR(20),
                         kassa::CHAR(20),
                         selg::TEXT
                  FROM eelarve.lisa1_lisa5_kontrol_3044($1::TEXT, $2::JSON, $3::JSON) where (eelarve <> 0
                      AND eelarve_taps <> 0
                      AND eelarve_kassa <> 0
                      AND eelarve_kassa_taps <> 0
                      AND saldoandmik <> 0
                      AND kassa <> 0
                  )
                  OR
                  COALESCE
                  (
                  selg
                  ,
                  ''
                  )
                  =
                  'test'`,
            query: null,
            multiple: true,
            alias: 'kontrol_3044',
            data: []
        },
        {
            sql: `SELECT eelarve::CHAR(20),
                         eelarve_taps::CHAR(20),
                         eelarve_kassa::CHAR(20),
                         eelarve_kassa_taps::CHAR(20),
                         saldoandmik::CHAR(20),
                         kassa::CHAR(20),
                         selg::TEXT
                  FROM eelarve.lisa1_lisa5_kontrol_art($1::TEXT, $2::JSON, $3::JSON) where (eelarve <> 0
                      AND eelarve_taps <> 0
                      AND eelarve_kassa <> 0
                      AND eelarve_kassa_taps <> 0
                      AND saldoandmik <> 0
                      AND kassa <> 0
                  )
                  OR
                  COALESCE
                  (
                  selg
                  ,
                  ''
                  )
                  =
                  'test'`,
            query: null,
            multiple: true,
            alias: 'kontrol_art',
            data: []
        }


    ]
};
