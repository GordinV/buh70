'use strict';
//var co = require('co');
let now = new Date();

const Arv = {
    selectAsLibs: `SELECT *
                   FROM com_arved a
                   WHERE (a.rekvId = $1::INTEGER)`, //$1 - rekvid, $2 userid
    libGridConfig: {
        grid: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "number", name: "Number", width: "15%"},
            {id: "kpv", name: "Kuupäev", width: "15%", type: "date"},
            {id: "asutus", name: "Maksja", width: "55%"},
            {id: "jaak", name: "Jääk", width: "15%"}
        ]
    },

    multiple_print_doc: {
        command: `with doc as (
         WITH params AS (
                SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER AS ids
             ),
              arved AS (
                 SELECT min(a.kpv) as alg_kpv, max(a.kpv) as lopp_kpv, a.rekvid
                 FROM docs.arv a
                 WHERE parentid IN (SELECT ids FROM params)
                 group by a.rekvid
             ),
             
         kaibed AS (
              with lapsed AS (
                      SELECT array_agg(parentid) AS isik_ids
                      FROM lapsed.liidestamine l
                      WHERE docid IN (SELECT ids FROM params)
                  )
             SELECT jsonb_build_object('alg_db', sum(kb.alg_db),
                                       'alg_kr', sum(kb.alg_kr),
                                       'db', sum(kb.db),
                                       'kr', sum(kb.kr),
                                       'lopp_db', sum(kb.lopp_db),
                                       'lopp_kr', sum(kb.lopp_kr)) AS kaibed,
                    kb.isik_id
             FROM arved a,
                  lapsed,
                  lapsed.saldo_ja_kaibeandmik(a.rekvid,
                                              make_date(year(a.alg_kpv), month(a.alg_kpv), 01)::DATE,
                                              gomonth(make_date(year(a.lopp_kpv), month(a.lopp_kpv), 01), 1) - 1) kb
             GROUP BY kb.isik_id
         ),
         details AS (
             SELECT a.parentid,
                    jsonb_build_object('id', a1.id, 'parentid', a1.parentid,
                                       'nomid', a1.nomid,
                                       'kogus', a1.kogus,
                                       'hind', a1.hind::NUMERIC(12, 4),
                                       'kbm', a1.kbm::NUMERIC(12, 2),
                                       'kbmta', a1.kbmta::NUMERIC(12, 2),
                                       'summa', a1.summa::NUMERIC(12, 2),
                                       'kood', TRIM(n.kood):: VARCHAR(20),
                                       'nimetus', TRIM(n.nimetus) :: VARCHAR(254),
                                       'uhik', n.uhik :: TEXT,
                                       'vahe', (COALESCE((SELECT vahe
                                                          FROM lapsed.cur_lapse_taabel
                                                          WHERE id = (a1.properties ->> 'lapse_taabel_id')::INTEGER
                                                          LIMIT 1)::NUMERIC(12, 4),
                                                         0)::NUMERIC(12, 4)),
                                       'soodustus',
                                       (COALESCE((a1.properties ->> 'soodustus')::NUMERIC(12, 4), 0)::NUMERIC(12, 4)),
                                       'tais_hind', a1.hind::NUMERIC(12, 4),
                                       'soodus', a1.soodus::NUMERIC(12, 4),
                                       'kood1', a1.kood1,
                                       'kood2', a1.kood2,
                                       'kood3', a1.kood3,
                                       'kood4', a1.kood4,
                                       'kood5', a1.kood5,
                                       'tunnus', a1.tunnus,
                                       'proj', a1.proj,
                                       'konto', a1.konto,
                                       'tp', a1.tp,
                                       'km', ((CASE
                                                   WHEN a1.kbm_maar IS NULL
                                                       THEN COALESCE(
                                                           (n.properties :: JSONB ->>
                                                            'vat'),
                                                           '-') :: VARCHAR(20)
                                                   ELSE a1.kbm_maar END)::VARCHAR(20)),
                                       'uhik', n.uhik,
                                       'yksus',(a1.properties ->>'yksus'),
                                       'muud', a1.muud,
                                       'markused',(TRIM(n.nimetus) || ',' || a1.muud)) AS details
             FROM docs.arv1 a1
                      INNER JOIN docs.arv a
                                 ON a.id = a1.parentId
                      INNER JOIN libs.nomenklatuur n ON n.id = a1.nomId
             WHERE a.parentid IN (SELECT ids FROM params)
               AND a1.kogus <> 0)

                    SELECT d.id,
                         a.id as doc_id,
                         $2 :: INTEGER                                             AS userid,
                         to_char(created, 'DD.MM.YYYY HH:MM:SS') :: TEXT           AS created,
                         to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS') :: TEXT        AS lastupdate,
                         d.bpm,
                         d.status                                                  AS doc_status,
                         a.number::TEXT                                            AS number,
                         a.rekvId,
                         a.liik,
                         a.operid,
                         to_char(a.kpv, 'YYYY-MM-DD')::TEXT                        AS kpv,
                         to_char(a.kpv, 'DD.MM.YYYY')::TEXT                        AS kpv_print,
                         a.asutusid,
                         a.arvId,
                         a.lisa:: TEXT                                             AS lisa,
                         to_char(a.tahtaeg, 'YYYY-MM-DD')::TEXT                    AS tahtaeg,
                         to_char(a.tahtaeg, 'DD.MM.YYYY')::TEXT                    AS tahtaeg_print,
                         a.kbmta,
                         a.kbm,
                         a.summa,
                         a.tasud,
                         a.tasudok::TEXT                                           AS tasudok,
                         a.muud,
                         asutus.regkood,
                         asutus.nimetus::TEXT                                      AS asutus,
                         asutus.aadress,
                         asutus.email::TEXT                                        AS email,
                         asutus.properties ->> 'kmkr'                              AS kmkr,
                         asutus.properties::JSONB -> 'asutus_aa' -> 0 ->> 'aa'     AS asutuse_aa,
                         a.doklausid,
                         a.journalid,
                         coalesce(jid.number, 0) :: INTEGER                        AS laus_nr,
                         dp.details :: JSONB ->> 'konto'                           AS konto,
                         dp.details :: JSONB ->> 'kbmkonto'                        AS kbmkonto,
                         dp.selg :: TEXT                                           AS dokprop,
                         dp.vaatalaus                                              AS is_show_journal,
                         d.history -> 0 ->> 'user'                                 AS koostaja,
                         a.properties ->> 'aa'                                     AS aa,
                         l.id                                                      AS lapsId,
                         l.isikukood::TEXT,
                         l.nimi::TEXT                                              AS lapse_nimi,
                         lapsed.get_viitenumber(d.rekvid, l.id)                    AS viitenr,
                         a.properties ->> 'tyyp'::TEXT                             AS tyyp,
                         a.jaak::NUMERIC(12, 2)                                    AS jaak,
                         to_char(make_date(year(arved.alg_kpv), month(arved.alg_kpv), 1)::DATE, 'DD.MM.YYYY') AS period_alg_print,
                         lpad(month(arved.lopp_kpv)::TEXT, 2, '0') || '.' ||
                         year(arved.lopp_kpv)::TEXT                                AS laekumise_period,
                         a.properties ->> 'ettemaksu_period'                       AS ettemaksu_period,
                         va.properties ->> 'pank'                                  AS pank,
                         va.properties ->> 'iban'                                  AS iban,
                       to_jsonb(array((SELECT kaibed FROM kaibed WHERE kaibed.isik_id = l.id))) AS kaibed,
                       to_jsonb(array((SELECT details FROM details det WHERE det.parentid = d.id)))   AS details,
                        r.muud as tais_nimetus,
                        r.tel as rekv_tel,
                        r.email as rekv_email,
                        r.aadress as rekv_aadress,
                        r.regkood as rekv_regkood
                                                                                             
                  FROM arved, docs.doc d
                           INNER JOIN docs.arv a ON a.parentId = d.id
                           INNER JOIN libs.asutus AS asutus ON asutus.id = a.asutusId
                           inner join ou.rekv r on r.id = d.rekvid
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                           LEFT OUTER JOIN libs.dokprop dp ON dp.id = a.doklausid
                           LEFT OUTER JOIN docs.journal j ON j.parentid = a.journalid
                           LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
                           LEFT OUTER JOIN lapsed.liidestamine ll ON ll.docid = d.id
                           LEFT OUTER JOIN lapsed.laps l
                                           ON l.id = ll.parentid
--                           LEFT OUTER JOIN lapsed.vanemad v ON v.asutusid = asutus.id
                           LEFT OUTER JOIN lapsed.vanem_arveldus va
                                           ON va.asutusid = a.asutusid AND va.rekvid = d.rekvid AND va.parentid = l.id
                                               AND va.parentid = l.id

                  WHERE d.id in (SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER)                  
                  )
                SELECT doc.*,
                    coalesce((doc.kaibed->0 ->> 'alg_db')::NUMERIC, 0) -
                    coalesce((doc.kaibed->0 ->> 'alg_kr')::NUMERIC, 0) AS alg_jaak,
                    coalesce((doc.kaibed->0 ->> 'lopp_db')::NUMERIC, 0) -
                    coalesce((doc.kaibed->0 ->> 'lopp_kr')::NUMERIC, 0) AS tasumisele,
                    coalesce((doc.kaibed->0 ->> 'kr')::NUMERIC, 0)      AS laekumised,
                    CASE
                        WHEN coalesce((doc.kaibed ->> 'lopp_kr')::NUMERIC, 0) > 0
                            THEN coalesce((doc.kaibed ->> 'lopp_kr')::NUMERIC, 0)
                        ELSE 0 END                                   AS ettemaksud,
                
                       (SELECT string_agg(arve::TEXT, ',') 
                        FROM ou.aa
                        WHERE parentid = doc.rekvid
                          AND kassa = 1
                          AND coalesce((properties ->> 'kas_oppetasu')::BOOLEAN, FALSE)) AS arved                                                 
                FROM doc`
    },
    select: [
        {
            sql: `with doc as (
                    SELECT d.id,
                         $2 :: INTEGER                                             AS userid,
                         to_char(created, 'DD.MM.YYYY HH:MM:SS') :: TEXT           AS created,
                         to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS') :: TEXT        AS lastupdate,
                         d.bpm,
                         d.status                                                  AS doc_status,
                         a.number::TEXT                                            AS number,
                         a.rekvId,
                         a.liik,
                         a.operid,
                         to_char(a.kpv, 'YYYY-MM-DD')::TEXT                        AS kpv,
                         to_char(a.kpv, 'DD.MM.YYYY')::TEXT                        AS kpv_print,
                         a.asutusid,
                         a.arvId,
                         a.lisa:: TEXT                                             AS lisa,
                         to_char(a.tahtaeg, 'YYYY-MM-DD')::TEXT                    AS tahtaeg,
                         to_char(a.tahtaeg, 'DD.MM.YYYY')::TEXT                    AS tahtaeg_print,
                         a.kbmta,
                         a.kbm,
                         a.summa,
                         a.tasud,
                         a.tasudok::TEXT                                           AS tasudok,
                         a.muud,
                         ltrim(rtrim(asutus.regkood)) as regkood,
                         asutus.nimetus::TEXT                                      AS asutus,
                         asutus.aadress,
                         asutus.email::TEXT                                        AS email,
                         asutus.properties ->> 'kmkr'                              AS kmkr,
                         asutus.properties::JSONB -> 'asutus_aa' -> 0 ->> 'aa'     AS asutuse_aa,
                         a.doklausid,
                         a.journalid,
                         coalesce(jid.number, 0) :: INTEGER                        AS laus_nr,
                         dp.details :: JSONB ->> 'konto'                           AS konto,
                         dp.details :: JSONB ->> 'kbmkonto'                        AS kbmkonto,
                         dp.selg :: TEXT                                           AS dokprop,
                         dp.vaatalaus                                              AS is_show_journal,
                         d.history -> 0 ->> 'user'                                 AS koostaja,
                         a.properties ->> 'aa'                                     AS aa,
                         l.id                                                      AS lapsId,
                         l.isikukood::TEXT,
                         l.nimi::TEXT                                              AS lapse_nimi,
                         lapsed.get_viitenumber(d.rekvid, l.id)                    AS viitenr,
                         (SELECT viitenumber
                                FROM lapsed.viitenr vn
                                WHERE vn.rekv_id = a.rekvId 
                                and vn.isikukood = l.isikukood 
                                order by id desc limit 1)::text                    AS vana_viitenr,
                         a.properties ->> 'tyyp'::TEXT                             AS tyyp,
                         a.jaak::NUMERIC(12, 2)                                    AS jaak,
                         to_char(make_date(year(a.kpv), month(a.kpv), 1)::DATE, 'DD.MM.YYYY') AS period_alg_print,
                         lpad(month(a.kpv)::TEXT, 2, '0') || '.' ||
                         year(a.kpv)::TEXT                                         AS laekumise_period,
                         a.properties ->> 'ettemaksu_period'                       AS ettemaksu_period,
                         va.properties ->> 'pank'                                  AS pank,
                         va.properties ->> 'iban'                                  AS iban,
                         a.kpv                                                     AS doc_kpv,
                         to_char(make_date(year(a.kpv), month(a.kpv), 1) ,'YYYY-MM-DD') as balance_day                         
                  FROM docs.doc d
                           INNER JOIN docs.arv a ON a.parentId = d.id
                           INNER JOIN libs.asutus AS asutus ON asutus.id = a.asutusId
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                           LEFT OUTER JOIN libs.dokprop dp ON dp.id = a.doklausid
                           LEFT OUTER JOIN docs.journal j ON j.parentid = a.journalid
                           LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
                           LEFT OUTER JOIN lapsed.liidestamine ll ON ll.docid = d.id
                           LEFT OUTER JOIN lapsed.laps l
                                           ON l.id = ll.parentid
                           LEFT OUTER JOIN lapsed.vanem_arveldus va
                                           ON va.asutusid = a.asutusid AND va.rekvid = d.rekvid AND va.parentid = l.id
                                               AND va.parentid = l.id

                  WHERE D.id = $1)
                SELECT doc.*,
                       coalesce(saldod.laekumised, 0)::NUMERIC(12, 2) AS laekumised,
                       coalesce(saldod.alg_jaak, 0)::NUMERIC(12, 2)       AS alg_jaak,
                       coalesce(saldod.lopp_jaak, 0)::NUMERIC(12, 2)       AS lopp_jaak,
                       coalesce(saldod.ettemaksud, 0)::NUMERIC(12, 2) AS ettemaksud,
                       coalesce(saldod.lopp_jaak, 0)::NUMERIC(12, 2)       AS tasumisele,
                       (SELECT string_agg(arve::TEXT, ',') 
                        FROM ou.aa
                        WHERE parentid = doc.rekvid
                          AND kassa = 1
                          AND coalesce((properties ->> 'kas_oppetasu')::BOOLEAN, FALSE)) AS arved
                       
                FROM doc,
                     (
                         SELECT (lopp_db - lopp_kr)                           AS lopp_jaak,
                                (alg_db - alg_kr)                           AS alg_jaak,
                                kr                                            AS laekumised,
                                CASE WHEN lopp_kr > 0 THEN lopp_kr ELSE 0 END AS ettemaksud
                         FROM doc,
                              lapsed.saldo_ja_kaibeandmik(doc.rekvid, make_date(year(doc.doc_kpv), month(doc.doc_kpv), 1)::DATE,
                                                          gomonth(make_date(year(doc.doc_kpv), month(doc.doc_kpv), 01), 1)::date - 1,doc.lapsId)) saldod`,
            sqlAsNew: `SELECT $1 :: INTEGER                                                          AS id,
                              $2 :: INTEGER                                                          AS userid,
                              to_char(now(), 'YYYY-MM-DD HH:MM:SS') :: TEXT                          AS created,
                              to_char(now(), 'YYYY-MM-DD HH:MM:SS') :: TEXT                          AS lastupdate,
                              NULL                                                                   AS bpm,
                              0                                                                      AS doc_status,
                              (SELECT arve
                               FROM ou.aa aa
                               WHERE aa.parentid = u.rekvid
                                 AND NOT empty(default_::INTEGER)
                                 AND NOT empty(kassa::INTEGER)
                                 AND kassa = 1
                               LIMIT 1)::VARCHAR(20)                                                 AS aa,

                              docs.sp_get_number(u.rekvId, 'ARV', year(date()), NULL) :: VARCHAR(20) AS number,
                              0.00::NUMERIC(12, 2)                                                   AS summa,
                              NULL :: INTEGER                                                        AS rekvId,
                              0                                                                      AS liik,
                              NULL :: INTEGER                                                        AS operid,
                              to_char(now() :: DATE, 'YYYY-MM-DD')::TEXT                             AS kpv,
                              NULL :: INTEGER                                                        AS asutusid,
                              NULL :: INTEGER                                                        AS arvId,
                              '' :: VARCHAR(120)                                                     AS lisa,
                              to_char((now() + INTERVAL '14 days') :: DATE, 'YYYY-MM-DD')::TEXT      AS tahtaeg,
                              0 :: NUMERIC                                                           AS kbmta,
                              0.00 :: NUMERIC                                                        AS kbm,
                              0 :: NUMERIC(14, 2)                                                    AS summa,
                              NULL :: DATE                                                           AS tasud,
                              NULL :: VARCHAR(20)                                                    AS tasudok,
                              NULL :: TEXT                                                           AS muud,
                              0.00                                                                   AS jaak,
                              0 :: INTEGER                                                           AS objektId,
                              NULL :: VARCHAR(20)                                                    AS objekt,
                              NULL :: VARCHAR(20)                                                    AS regkood,
                              NULL :: VARCHAR(120)                                                   AS asutus,
                              NULL :: TEXT                                                           AS aadress,
                              NULL :: VARCHAR(120)                                                   AS kmkr,
                              NULL :: INTEGER                                                        AS doklausid,
                              NULL :: VARCHAR(120)                                                   AS dokprop,
                              NULL :: TEXT                                                           AS konto,
                              NULL :: TEXT                                                           AS kbmkonto,
                              NULL :: INTEGER                                                        AS journalid,
                              NULL :: INTEGER                                                        AS laus_nr,
                              NULL :: VARCHAR(120)                                                   AS koostaja,
                              0 ::INTEGER                                                            AS is_show_journal,
                              ''::VARCHAR(120)                                                       AS viitenr,
                              NULL::INTEGER                                                          AS lapsId,
                              NULL::INTEGER                                                          AS ettemaksu_period,
                              current_date::DATE                                                     AS period_alg
                       FROM ou.userid u
                       WHERE u.id = $2 :: INTEGER`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT a1.id,
                         $2 :: INTEGER                                                                AS userid,
                         a1.nomid,
                         a1.kogus,
                         a1.hind::NUMERIC(12, 4),
                         a1.kbm::NUMERIC(12, 2),
                         a1.kbmta::NUMERIC(12, 2),
                         a1.summa::NUMERIC(12, 2),
                         trim(n.kood) :: VARCHAR(20)                                                  AS kood,
                         trim(n.nimetus) :: VARCHAR(254)                                              AS nimetus,
                         trim(n.uhik) :: TEXT                                                         AS uhik,
                         coalesce((SELECT vahe
                                   FROM lapsed.cur_lapse_taabel
                                   WHERE id = (a1.properties ->> 'lapse_taabel_id')::INTEGER
                                   LIMIT 1)::NUMERIC(12, 4),
                                  0)::NUMERIC(12, 4)                                                  AS vahe,
                         coalesce((a1.properties ->> 'soodustus')::NUMERIC(12, 4), 0)::NUMERIC(12, 4) AS soodustus,
                         a1.hind::NUMERIC(12, 4)                                                      AS tais_hind,
                         a1.soodus::NUMERIC(12, 4),
                         a1.kood1,
                         a1.kood2,
                         a1.kood3,
                         a1.kood4,
                         a1.kood5,
                         a1.tunnus,
                         a1.proj,
                         a1.konto,
                         a1.tp,
                         NULL :: TEXT                                                                 AS vastisik,
                         NULL :: TEXT                                                                 AS formula,
                         'EUR' :: VARCHAR(20)                                                         AS valuuta,
                         1 :: NUMERIC                                                                 AS kuurs,
                         (CASE
                              WHEN a1.kbm_maar IS NULL
                                  THEN COALESCE((n.properties :: JSONB ->>
                                                 'vat'),
                                                '-') :: VARCHAR(20)
                              ELSE a1.kbm_maar END)::VARCHAR(20)                                      AS km,
                         n.uhik,
                         a1.properties ->>
                         'yksus'                                                                      AS yksus,
                         a1.muud,
                         trim(n.nimetus) || ',' || a1.muud                                            AS markused
                  FROM docs.arv1 a1
                           INNER JOIN docs.arv a
                                      ON a.id = a1.parentId
                           INNER JOIN libs.nomenklatuur n ON n.id = a1.nomId
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                  WHERE a.parentid = $1 :: INTEGER
                    AND a1.kogus <> 0`,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        },
        {
            sql: `SELECT rd.id,
                         $2 :: INTEGER   AS userid,
                         trim(l.kood)    AS doc_type,
                         trim(l.nimetus) AS name,
                         CASE
                             WHEN t.id IS NOT NULL THEN t.number
                             WHEN m.id IS NOT NULL THEN m.number
                             WHEN aa.id IS NOT NULL THEN aa.number
                             END         AS number
                  FROM docs.doc d
                           LEFT OUTER JOIN docs.doc rd ON rd.id IN (SELECT unnest(d.docs_ids))
                           LEFT OUTER JOIN libs.library l ON rd.doc_type_id = l.id
                           LEFT OUTER JOIN docs.teatis t ON t.parentid = rd.id
                           LEFT OUTER JOIN docs.mk m ON m.parentid = rd.id
                           LEFT OUTER JOIN docs.arv aa ON aa.parentid = rd.id
                           INNER JOIN ou.userid u ON u.id = $2 :: INTEGER
                  WHERE d.id = $1 :: INTEGER`,
            query: null,
            multiple: true,
            alias: 'relations',
            data: []
        },
        {
            sql: `SELECT Arvtasu.id,
                         arvtasu.kpv,
                         to_char(arvtasu.kpv, 'DD.MM.YYYY')                            AS print_kpv,
                         arvtasu.summa,
                         coalesce(arvtasu.inf3_summa, 0)                               AS inf3_summa,
                         CASE WHEN mk.opt = 2 THEN 'SMK' ELSE 'VMK' END :: VARCHAR(20) AS dok,
                         'PANK' :: VARCHAR                                             AS liik,
                         mk.number                                                     AS dok_nr,
                         pankkassa,
                         mk1.journalid,
                         doc_tasu_id,
                         coalesce(journalid.number, 0)                                 AS number,
                         a.nimetus                                                     AS maksja,
                         $2                                                            AS userid
                  FROM docs.arvtasu arvtasu
                           INNER JOIN docs.mk mk ON (arvtasu.doc_tasu_id = mk.parentid AND arvtasu.pankkassa = 1)
                           INNER JOIN docs.mk1 mk1 ON (mk.id = mk1.parentid)
                           LEFT OUTER JOIN docs.journalid journalid ON mk1.journalId = journalId.journalId
                           INNER JOIN libs.asutus a ON a.id = mk1.asutusid
                  WHERE Arvtasu.doc_arv_id = $1
                    AND arvtasu.summa <> 0
                    AND arvtasu.status <> 3
                  UNION ALL
                  SELECT Arvtasu.id
                          ,
                         arvtasu.kpv
                          ,
                         to_char(arvtasu.kpv, 'DD.MM.YYYY') AS print_kpv
                          ,
                         arvtasu.summa
                          ,
                         coalesce(arvtasu.inf3_summa, 0)    AS inf3_summa
                          ,
                         'KASSAORDER' :: VARCHAR(20)        AS dok
                          ,
                         'KASSA' :: VARCHAR                 AS liik
                          ,
                         korder1.number                     AS dok_nr
                          ,
                         pankkassa
                          ,
                         korder1.journalid
                          ,
                         doc_tasu_id
                          ,
                         coalesce(journalid.number, 0)      AS number
                          ,
                         a.nimetus                          AS maksja
                          ,
                         $2                                 AS userid
                  FROM docs.arvtasu arvtasu
                           INNER JOIN docs.korder1 korder1
                                      ON (arvtasu.doc_tasu_id = korder1.parentid AND arvtasu.pankkassa = 2)
                           LEFT OUTER JOIN docs.journalid journalid ON korder1.journalId = journalId.journalId
                           INNER JOIN libs.asutus a ON a.id = korder1.asutusid
                  WHERE Arvtasu.doc_arv_id = $1
                    AND arvtasu.summa <> 0
                    AND arvtasu.status <> 3
                  UNION ALL
                  SELECT Arvtasu.id
                          ,
                         arvtasu.kpv
                          ,
                         to_char(arvtasu.kpv, 'DD.MM.YYYY') AS print_kpv
                          ,
                         arvtasu.summa
                          ,
                         coalesce(arvtasu.inf3_summa, 0)    AS inf3_summa
                          ,
                         'PAEVARAAMAT' :: VARCHAR(20)       AS dok
                          ,
                         'JOURNAL' :: VARCHAR               AS liik
                          ,
                         NULL::TEXT                         AS dok_nr
                          ,
                         pankkassa
                          ,
                         arvtasu.doc_tasu_id                AS journalid
                          ,
                         doc_tasu_id
                          ,
                         coalesce(journalid.number, 0)      AS number
                          ,
                         a.nimetus                          AS maksja
                          ,
                         $2                                 AS userid
                  FROM docs.arvtasu arvtasu
                           LEFT OUTER JOIN docs.journal journal
                                           ON (arvtasu.doc_tasu_id = journal.parentId AND arvtasu.pankkassa = 3)
                           LEFT OUTER JOIN docs.journalid journalid ON (journal.id = journalId.journalId)
                           INNER JOIN libs.asutus a ON a.id = journal.asutusid
                  WHERE Arvtasu.doc_arv_id = $1
                    AND arvtasu.summa <> 0
                    AND arvtasu.status <> 3
                    AND arvtasu.pankkassa = 3
                  UNION ALL
                  SELECT Arvtasu.id
                          ,
                         arvtasu.kpv
                          ,
                         to_char(arvtasu.kpv, 'DD.MM.YYYY') AS print_kpv
                          ,
                         arvtasu.summa
                          ,
                         coalesce(arvtasu.inf3_summa, 0)    AS inf3_summa
                          ,
                         '' :: VARCHAR(20)                  AS dok
                          ,
                         'MUUD' :: VARCHAR                  AS liik
                          ,
                         NULL::TEXT                         AS dok_nr
                          ,
                         pankkassa
                          ,
                         0                                  AS journalid
                          ,
                         NULL
                          ,
                         0                                  AS number
                          ,
                         ''::TEXT                           AS maksja
                          ,
                         $2                                 AS userid
                  FROM docs.arvtasu arvtasu
                  WHERE Arvtasu.doc_arv_id = $1
                    AND arvtasu.summa <> 0
                    AND arvtasu.status <> 3
                    AND arvtasu.pankkassa IN (0, 4)
            `,
            query: null,
            multiple: true,
            alias: 'queryArvTasu',
            data: []
        },


    ],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1px", show: false},
            {id: "number", name: "Number", width: "5%", type: "text"},
            {id: "kpv", name: "Kuupaev", width: "5%", type: 'date', interval: true},
            {id: "asutus", name: "Maksja", width: "15%"},
            {id: "summa", name: "Summa", width: "5%", type: "number", interval: true},
            {id: "tahtaeg", name: "Tähtaeg", width: "5%", type: 'date', interval: true},
            {id: "jaak", name: "Jääk", width: "5%", type: "number", interval: true},
            {id: "tasud", name: "Tasud", width: "5%", type: 'date', interval: true},
            {id: "nimi", name: "Nimi", width: "15%"},
            {id: "isikukood", name: "Isikukood", width: "7%"},
            {id: "viitenr", name: "Viitenr", width: "5%"},
            {id: "printimine", name: "Arve esitatakse", width: "5%"},
            {id: "tyyp", name: "Tüüp", width: "5%", show: false},
            {id: "ebatoenaolised", name: "Ebatõenaolised", width: "5%"},
            {id: "ebatoenaolised", name: "Ebatõenaolised", width: "5%"},
            {id: "select", name: "Valitud", width: "5%", show: false, type: 'boolean', hideFilter: true},
            {id: "esitatud", name: "Kas esitatud?", width: "5%", type: 'select', data: ['', 'Jah', 'Ei'], show: false},

        ],
        sqlString: `SELECT id,
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
                           kas_paberil::BOOLEAN                 AS kas_paberil,
                           kas_email::BOOLEAN                   AS kas_email,
                           kas_earved::BOOLEAN                  AS kas_earved,
                           CASE
                               WHEN kas_esitatud THEN 'JAH'
                               ELSE 'EI' END::TEXT              AS esitatud,
                           pank::TEXT,
                           ebatoenaolised,
                           vn.vn                                AS vana_vn,
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
                               ELSE '' END ::TEXT               AS printimine
                    FROM lapsed.cur_laste_arved a
                             LEFT OUTER JOIN (SELECT string_agg(viitenumber, ', ') AS vn, vn.isikukood
                                              FROM lapsed.viitenr vn
                                              WHERE vn.rekv_id IN (SELECT rekv_id
                                                                   FROM get_asutuse_struktuur($1))
                                              GROUP BY vn.isikukood
                    ) vn
                                             ON vn.isikukood = a.isikukood

                    WHERE a.rekvId = $1::INTEGER`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curLasteArved'
    },
    returnData: {
        row: {},
        details: [],
        relations: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'nomid', name: 'nomId', width: '0px', show: false, type: 'text', readOnly: false},
            {
                id: 'kood',
                name: 'Kood',
                width: '10%',
                show: true,
                type: 'select',
                readOnly: false,
                dataSet: 'nomenclature',
                valueFieldName: 'nomid'
            },
            {id: 'yksus', name: 'Üksus', width: '15%', show: true, readOnly: true},
            {id: 'nimetus', name: 'Nimetus', width: '25%', show: true, readOnly: true},
            {id: 'hind', name: 'Hind', width: '10%', show: true, type: 'number', readOnly: false},
            {id: 'soodustus', name: 'Soodustus', width: '10%', show: true, type: 'number', readOnly: false},
            {id: 'vahe', name: 'Vahe', width: '5%', show: true, type: 'number', readOnly: false},
            {id: 'uhik', name: 'Ühik', width: '5%', show: true, readOnly: true},
            {id: 'kogus', name: 'kogus', width: '10%', show: true, type: 'number', readOnly: false},
            {id: 'kbm', name: 'Käibemaks', width: '10%', show: true, type: 'number', readOnly: false},
            {id: 'summa', name: 'Summa', width: '10%', show: true, type: 'number', readOnly: false}
        ],
        gridTasudConfig:
            [
                {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
                {id: 'dok', name: 'Dokument', width: '10%', show: true, type: 'text', readOnly: true},
                {id: 'dok_nr', name: 'Dok.nr', width: '10%', show: true, type: 'text', readOnly: true},
                {id: 'print_kpv', name: 'Kuupäev', width: '10%', show: true, type: 'text', readOnly: true},
                {id: 'summa', name: 'Summa', width: '10%', show: true, type: 'text', readOnly: true},
                {id: 'inf3_summa', name: 'INF3 Summa', width: '10%', show: true, type: 'text', readOnly: true},
                {id: 'number', name: 'Lausend', width: '10%', show: true, type: 'text', readOnly: true},
                {id: 'maksja', name: 'Maksja', width: '10%', show: true, type: 'text', readOnly: true},
            ]

    },
    saveDoc: `select docs.sp_salvesta_arv($1::json, $2::integer, $3::integer) as id`,
    deleteDoc: `SELECT docs.sp_delete_arv($1::INTEGER, id::INTEGER)
                FROM lapsed.cur_laste_arved
                WHERE id::TEXT IN (SELECT unnest(string_to_array($2::TEXT, ',')))
    `, // $1 - userId, $2 - docId
    requiredFields: [
        {
            name: 'kpv',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {
            name: 'tahtaeg',
            type: 'D',
            min: now.setFullYear(now.getFullYear() - 1),
            max: now.setFullYear(now.getFullYear() + 1)
        },
        {name: 'asutusid', type: 'N', min: null, max: null},
        {name: 'lapsid', type: 'N', min: null, max: null}
    ],
    executeCommand: {
        command: `select docs.sp_kooperi_arv($1::integer, $2::integer) as result`,
        type: 'sql',
        alias: 'kooperiArv'
    },
    bpm: [
        {
            name: 'Контировка',
            action: 'generateJournal',
            type: 'automat',
            actualStep: false
        },
        {
            name: 'Koosta maksekorraldus',
            task: 'generatePaymentOrder',
            type: 'manual',
            action: 'generatePaymentOrder',
        },
        {
            name: 'Koosta kassaorder',
            task: 'generateCashOrder',
            type: 'manual',
            action: 'generateCashOrder',
        },
        {
            name: 'Ebatõenäoliste nõuete mahakandmine',
            task: 'ebatoenaolised',
            type: 'manual',
            hideDate: false,
            action: 'ebatoenaolised',
        }

    ],
    generateJournal: {
        command: "SELECT error_code, result, error_message FROM docs.gen_lausend_arv($1::INTEGER, $2::INTEGER)", //$1 - docs.doc.id, $2 - userId
        type: "sql",
        alias: 'generateJournal'
    },
    generatePaymentOrder: {
        command: `SELECT error_code, result, error_message, doc_type_id
                  FROM docs.create_new_mk($2::INTEGER, (SELECT to_jsonb(row.*) FROM (SELECT $1 AS arv_id) row))`, //$1 - docs.doc.id, $2 - userId
        type: "sql",
        alias: 'generatePaymentOrder'
    },
    generateCashOrder: {
        command: `SELECT error_code, result, error_message, doc_type_id
                  FROM docs.create_new_order($2::INTEGER, (SELECT to_jsonb(row.*) FROM (SELECT $1 AS arv_id) row))`, //$1 - docs.doc.id, $2 - userId
        type: "sql",
        alias: 'generateCashOrder'
    },
    ebatoenaolised: {
        command: `SELECT error_code, result, error_message, 'ARV' AS doc_type_id
                  FROM docs.ebatoenaolised_mahakandmine($2::INTEGER, $1::INTEGER, $3::DATE)`, //$1 - docs.doc.id, $2 - userId, $3 - kpv
        type: "sql",
        alias: 'ebatoenaolised'
    },
    ebatoenaolisedMass: {
        command: `SELECT row_number() OVER ()                                          AS id,
                         tulemus -> 'result'                                           AS result,
                         tulemus -> 'error_code'                                       AS error_code,
                         coalesce((tulemus ->> 'error_code')::INTEGER, 0)::INTEGER > 0 AS kas_vigane,
                         tulemus -> 'error_message'                                    AS error_message
                  FROM (
                           SELECT to_jsonb(docs.ebatoenaolised_mahakandmine($2::INTEGER, id::INTEGER, $3::DATE)) tulemus
                           FROM cur_arved
                           WHERE id IN (
                               SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER
                           )) qry`, //$1 - docs ids, $2 - userId, $3 - kpv
        type: "sql",
        alias: 'ebatoenaolised'
    },

    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                                 AS id,
                         (ajalugu ->> 'user')::TEXT                                           AS kasutaja,
                         to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS') AS koostatud,
                         to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS') AS muudatud,
                         to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS')   AS prinditud,
                         to_char((ajalugu ->> 'email')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS')   AS email,
                         to_char((ajalugu ->> 'earve')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS')   AS earve,
                         to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH24.MI.SS') AS kustutatud

                  FROM (
                           SELECT jsonb_array_elements(history) AS ajalugu, d.id, d.rekvid
                           FROM docs.doc d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry`,
        type: "sql",
        alias: "getLogs"
    },


    executeTask: function (task, docId, userId) {
        // выполнит задачу, переданную в параметре

        let executeTask = task;
        if (executeTask.length === 0) {
            executeTask = ['start'];
        }

        let taskFunction = eval(executeTask[0]);
        return taskFunction(docId, userId, this);
    },
    print: [
        {
            view: 'arve_kaart',
            params: 'id',
            register: `UPDATE docs.doc
                       SET history = history ||
                                     (SELECT row_to_json(row)
                                      FROM (SELECT now()                                                AS print,
                                                   (SELECT kasutaja FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                       WHERE id = $1`
        },
        {
            view: 'arve_register',
            params: 'sqlWhere'
        },
    ],
    multiple_print: [
        {
            view: 'arve_kaart',
            params: 'id',
            register: `UPDATE docs.doc
                       SET history = history ||
                                     (SELECT row_to_json(row)
                                      FROM (SELECT now()                                                AS print,
                                                   (SELECT kasutaja FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                       WHERE id = $1`
        },
        {
            view: 'arve_register',
            params: 'sqlWhere'
        },
    ],

    email: [
        {
            view: 'arve_email',
            params: 'id',
            register: `UPDATE docs.doc
                       SET history = history ||
                                     (SELECT row_to_json(row)
                                      FROM (SELECT now()                                                AS email,
                                                   (SELECT kasutaja FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                       WHERE id = $1`,
            register_error: `UPDATE docs.doc
                             SET history = history ||
                                           (SELECT row_to_json(row)
                                            FROM (SELECT now()                                                AS email_viga,
                                                         (SELECT kasutaja FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                             WHERE id = $1`

        }
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

module.exports = Arv;

