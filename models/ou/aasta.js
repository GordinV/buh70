module.exports = {
    selectAsLibs: `SELECT id,
                          kuu,
                          aasta,
                          kinni,
                          palk_kinni,
                          eelarve_kinni,
                          default_,
                          ou.is_last_quarter_opened(aasta.rekvid,
                                                       make_date(aasta.aasta, aasta.kuu, 01))::INTEGER AS kas_veerand_avatud
                   FROM ou.aasta aasta
                   WHERE Aasta.rekvid = $1
                   ORDER BY default_ DESC`,
    select: [{
        sql: null,
        alias: null
    }],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kuu", name: "Kuu", width: "25%"},
            {id: "aasta", name: "Aasta", width: "35%"},
            {id: "kinni", name: "Kinni", width: "25%"},
            {id: "default_", name: "Default", width: "25%"}
        ],

        sqlString: `SELECT id,
                           kuu,
                           aasta,
                           CASE
                               WHEN kinni = 1
                                   THEN 'Jah'
                               ELSE 'Ei' END :: VARCHAR                                  AS kinni,
                           CASE
                               WHEN palk_kinni = 1
                                   THEN 'Jah'
                               ELSE 'Ei' END :: VARCHAR                                  AS palk_kinni,
                           CASE
                               WHEN eelarve_kinni = 1
                                   THEN 'Jah'
                               ELSE 'Ei' END :: VARCHAR                                  AS eelarve_kinni,
                           CASE
                               WHEN default_ = 1
                                   THEN 'JAH'
                               ELSE 'Ei' END :: VARCHAR                                  AS default_,
                           ou.is_last_quarter_opened(Aasta.rekvid, DATE(aasta, kuu, 01))::INTEGER AS kas_veerand_avatud
                    FROM ou.aasta Aasta
                    WHERE Aasta.rekvid = $1
                    ORDER BY aasta, kuu`, //$1 rekvid
        alias: 'curAasta'
    },
    returnData: null,
    executeCommand: {
        command: `SELECT *
                  FROM sp_execute_task($1::INTEGER, $2::JSON, $3::TEXT)`, //$1- userId, $2 - params, $3 - task
        type: 'sql',
        alias: 'executeTask'
    },

    saveDoc: null,
    deleteDoc: null,
    requiredFields: null
};
