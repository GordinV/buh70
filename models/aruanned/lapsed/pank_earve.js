module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1px", show: false},
            {id: "number", name: "Number", width: "3%", type: "text"},
            {id: "kpv", name: "Kuupaev", width: "5%", type: 'date', interval: true},
            {id: "asutus", name: "Maksja", width: "10%"},
            {id: "summa", name: "Summa", width: "5%", type: "number", interval: true},
            {id: "yksus", name: "Üksus", width: "7%"},
            {id: "nimi", name: "Nimi", width: "10%"},
            {id: "isikukood", name: "Isikukood", width: "7%"},
            {id: "viitenr", name: "Viitenr", width: "6%"},
            {id: "printimine", name: "Arve esitatakse", width: "10%"},
            {id: "select", name: "Valitud", width: "5%", show: false, type: 'boolean', hideFilter: true},
            {id: "esitatud", name: "Kas esitatud?", width: "5%", type: 'select', data: ['', 'Jah', 'Ei'], show: false},
            {id: "rekv_asutus", name: "Asutus", width: "10%"},

        ],
        sqlString: `WITH arved AS (
                        SELECT a.id,
                           number :: TEXT,
                           rekvid,
                           to_char(kpv, 'DD.MM.YYYY') :: TEXT   AS kpv,
                           summa,
                           to_char(tahtaeg, 'DD.MM.YYYY')::TEXT AS tahtaeg,
                           jaak,
                           lisa,
                           to_char(tasud, 'DD.MM.YYYY')::TEXT   AS tasud,
                           tasudok,
                           userid,
                           asutus :: TEXT                       AS asutus,
                           vanem_isikukood::TEXT,
                           asutusid,
                           journalid,
                           markused,
                           lausnr,
                           docs_ids,
                           a.arve::TEXT                         AS aa,
                           a.viitenr ::TEXT                     AS viitenr,
                           a.isikukood,
                           a.nimi,
                           a.tyyp,
                           $2::INTEGER                          AS userId,
                           TRUE                                 AS select,
                           CASE
                               WHEN kas_esitatud THEN 'JAH'
                               ELSE 'EI' END::TEXT              AS esitatud,
                           pank::TEXT,
                           CASE
                               WHEN (kas_email)::BOOLEAN
                                   THEN 'email;'
                               ELSE '' END ||
                           CASE
                               WHEN (kas_paberil)::BOOLEAN
                                   THEN 'paber;'
                               ELSE '' END ||
                           CASE
                               WHEN (kas_earved)::BOOLEAN AND
                                    empty(pank)
                                   THEN 'e-arve;'
                               ELSE '' END ||
                           CASE
                               WHEN (kas_earved)::BOOLEAN AND
                                    NOT empty(pank) AND
                                    pank = 'SEB' THEN 'SEB;'
                               ELSE '' END ||
                           CASE
                               WHEN (kas_earved)::BOOLEAN AND
                                    NOT empty(pank) AND
                                    pank = 'SWED' THEN 'SWED;'
                               ELSE '' END ::TEXT               AS printimine,
                               a.arv_id
                    FROM lapsed.cur_laste_arved a
                    WHERE a.rekvId in (SELECT rekv_id FROM get_asutuse_struktuur($1::INTEGER))
                      AND (kas_earved)::BOOLEAN
                      AND NOT empty(pank)
                    ),
                  yksused AS (
                      SELECT array_to_string(public.get_unique_value_from_array(array_agg(a1.properties ->> 'yksus')),',') AS yksus,
                             a1.parentid                                                        AS arv_id
                      FROM docs.arv1 a1
                      WHERE a1.parentid IN (SELECT arv_id FROM arved)
                      GROUP BY a1.parentid
                  )
         SELECT a.*, 
         y.yksus, 
         r.nimetus as rekv_asutus 
         FROM arved a
            inner join ou.rekv r on r.id = a.rekvid
            LEFT OUTER JOIN yksused y ON y.arv_id = a.arv_id
         order by yksus`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curLasteArved',
    },
    print: [
        {
            view: 'arve_register',
            params: 'sqlWhere'
        },
    ],
    earve: [
        {
            params: 'id',
            register: `UPDATE docs.doc
                       SET history = history ||
                                     (SELECT row_to_json(row)
                                      FROM (SELECT now()                                                AS earve,
                                                   (SELECT kasutaja FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                       WHERE id IN (
                           SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER
                       )`

        }
    ]

};
