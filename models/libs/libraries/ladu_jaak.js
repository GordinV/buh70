module.exports = {
    selectAsLibs: `SELECT *, NULL::DATE AS valid
                   FROM com_ladu_jaak
                   WHERE (rekvid = $1 OR rekvid IS NULL)
                     AND jaak > 0`,
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "kood", name: "Kood", width: "15%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "grupp", name: "Grupp", width: "10%"},
            {id: "hind", name: "Hind", width: "10%"},
            {id: "jaak", name: "Jääk", width: "10%"},
            {id: "ladu", name: "ladu", width: "20%"}
        ],
        sqlString: `SELECT *
                    FROM cur_ladu_jaak j
                    WHERE (j.rekvId = $1 OR j.rekvid IS NULL)
                      AND j.jaak > 0`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curLaduJaak'
    },
    executeSql: {
        sqlString: `SELECT arv.number,
                           arv.kpv,
                           a.nimetus                             AS asutus,
                           arv.lisa,
                           arv.jaak,
                           coalesce(v.valuuta, 'EUR') :: VARCHAR AS valuuta,
                           arv.tasud
                    FROM docs.arv arv
                             INNER JOIN libs.asutus a ON arv.asutusid = a.id
                             LEFT OUTER JOIN docs.dokvaluuta1 v ON v.dokid = arv.id AND v.dokliik = 3
                    WHERE arv.rekvid = ?gRekv AND arv.id IN (
                        SELECT a.parentid FROM docs.arv1 a WHERE a.id IN
                        (
                        SELECT j.dokitemid
                        FROM libs.ladu_jaak j
                        INNER JOIN libs.nomenklatuur n ON j.nomid = n.id
                        WHERE ltrim(rtrim(upper(n.kood))) = ?tcKood AND j.hind = ?tcHind
                        ))`,
        alias: `Analuus`
    },
    executeCommand: {
        command: `select sp_recalc_ladujaak(?gRekv, ?tnNomId, ?tnArveId) as result`,
        type: 'sql',
        alias: 'recalcLaduJaak'
    }


};
