module.exports = {
    grid: {
        gridConfiguration: [
            {id: "number", name: "Arve nr", width: "5%"},
            {id: "print_kpv", name: "Arve kuupäev", width: "8%", type: "date", interval: true},
            {id: "viitenumber", name: "Viitenumber", width: "8%"},
            {id: "saaja_nimi", name: "Saaja nimi", width: "13%", show: true},
            {id: "saaja_isikukood", name: "Saaja isikukood", width: "8%"},
            {id: "saaja_email", name: "Saaja email", width: "13%"},
            {id: "print", name: "Prinditud", width: "8%"},
            {id: "email", name: "Emailitud", width: "8%"},
            {id: "status", name: "E-kirja saatmise staatus", width: "10%"},
            {id: "earve", name: "Saadetud e-arvega", width: "8%"},
            {id: "asutus", name: "Asutus", width: "8%"},
        ],
        sqlString: `SELECT
                        a.number,
                        to_char(a.kpv, 'DD.MM.YYYY')                                   AS print_kpv,
                        a.kpv::DATE                                                    AS kpv,
                        a.summa,
                        coalesce((a.properties ->> 'viitenr'),
                                 lapsed.get_viitenumber(a.rekvid, l.parentid)) :: TEXT AS viitenumber,
                        c.regkood                                                      AS saaja_isikukood,
                        c.nimetus                                                      AS saaja_nimi,
                        coalesce(log.email_aadress, c.email)::TEXT                     AS saaja_email,
                        coalesce(log.status, 'Edukalt') ::text as status,
                        to_char(log.email, 'DD.MM.YYYY HH24:MI:SS')                    AS email,
                        to_char(log.earve, 'DD.MM.YYYY HH24:MI:SS')                    AS earve,
                        to_char(log.print, 'DD.MM.YYYY HH24:MI:SS')                    AS print,
                        r.nimetus                                                      AS asutus,
                        $2                                                             AS user_id
                    FROM
                        docs.cur_doc_sent                  log
                            INNER JOIN docs.arv            a ON a.parentid = log.doc_id
                            INNER JOIN lapsed.liidestamine l ON l.docid = log.doc_id
                            INNER JOIN libs.asutus         c ON c.id = a.asutusid
                            INNER JOIN ou.rekv             r ON r.id = a.rekvid
                    WHERE
                        a.rekvid IN (
                                        SELECT
                                            rekv_id
                                        FROM
                                            get_asutuse_struktuur($1)
                                    )
                    ORDER BY
                        r.nimetus, a.kpv, a.number
        `,     // $1 - rekvid, $3 - kond
        params: '',
        alias: 'sent_docs_report'
    },
    print: [
        {
            view: 'sent_docs_register',
            params: 'sqlWhere'
        },
    ],

};
