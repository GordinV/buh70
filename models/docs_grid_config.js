module.exports = {
    DOK: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "type", name: "type", width: "20%"},
            {id: "created", name: "created", width: "20%"},
            {id: "lastupdate", name: "Last change", width: "20%"},
            {id: "status", name: "Status", width: "30%"}

        ],
        sqlString: `select d.id, trim(l.nimetus) as type, to_char(d.created, 'DD.MM.YYYY HH:MM:SS')::text as created, 
         to_char(d.lastupdate,'DD.MM.YYYY HH:MM:SS')::text as lastupdate, 
         trim(s.nimetus) as status 
         from docs.doc d 
         inner join libs.library s on s.kood = d.status::text
         inner join libs.library l on l.id = d.doc_type_id 
         where d.rekvId = $1
         and docs.usersRigths(d.id, 'select', $2)
         limit 100`,
        params: ''
    },

    ARV: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px", show: false},
            {id: "number", name: "Number", width: "100px"},
            {id: "kpv", name: "Kuupaev", width: "100px"},
            {id: "summa", name: "Summa", width: "75px"},
            {id: "tahtaeg", name: "Tähtaeg", width: "100px"},
            {id: "jaak", name: "Jääk", width: "100px"},
            {id: "tasud", name: "Tasud", width: "100px"},
            {id: "asutus", name: "Asutus", width: "200px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Staatus", width: "100px"},
        ],
        sqlString: `select d.id, trim(a.number) as number, to_char(a.kpv,'DD.MM.YYYY') as kpv, a.summa, 
        to_char(a.tahtaeg,'DD.MM.YYYY') as tahtaeg, a.jaak, to_char(a.tasud,'DD.MM.YYYY') as tasud,
         trim(asutus.nimetus) as asutus,
         to_char(d.created,'DD.MM.YYYY HH:MM') as created, to_char(d.lastupdate,'DD.MM.YYYY HH:MM') as lastupdate,
         trim(s.nimetus) as status 
         from docs.doc d 
         inner join docs.arv a on a.parentId = d.id
         inner join libs.library s on s.kood = d.status::text
         left outer join libs.asutus asutus on a.asutusid = asutus.id 
         where d.rekvId = $1 
         and docs.usersRigths(d.id, 'select', $2)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: ''
    },
    JOURNAL: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px", "type": "integer"},
            {id: "kpv", name: "Kuupaev", width: "100px", "type": "date"},
            {id: "number", name: "Number", width: "100px", "type": "integer"},
            {id: "selg", name: "Selgitus", width: "200px", "type": "text"},
            {id: "dok", name: "Dokument", width: "200px", "type": "text"},
            {id: "deebet", name: "Db", width: "50px", "type": "string"},
            {id: "kreedit", name: "Kr", width: "50px", "type": "string"},
            {id: "summa", name: "Summa", width: "100px", "type": "number"},
            {id: "created", name: "Lisatud", width: "150px", "type": "date"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px", "type": "date"},
            {id: "status", name: "Status", width: "100px", "type": "string"}
        ],
        sqlString: `select d.id, to_char(j.kpv,'DD.MM.YYYY') as kpv, jid.number, j.selg, j.dok, 
         j1.deebet, j1.kreedit, j1.summa, 
         to_char(d.created,'DD.MM.YYYY HH:MM') as created, to_char(d.lastupdate,'DD.MM.YYYY HH:MM') as lastupdate , 
         s.nimetus as status 
         from docs.journal j 
         inner join docs.doc d on d.id = j.parentid 
         inner join docs.journalid jid on j.id = jid.journalid 
         inner join docs.journal1 j1 on j.id = j1.parentid 
         inner join libs.library s on s.kood = d.status::text 
         where d.rekvId = $1
            and coalesce(docs.usersRigths(d.id, 'select', $2),true)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: ''
    },
    SORDER: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "kpv", name: "Kuupaev", width: "100px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "nimi", name: "Nimi", width: "200px"},
            {id: "dokument", name: "Dokument", width: "200px"},
            {id: "summa", name: "Summa", width: "100px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Status", width: "100px"}
        ],
        sqlString: `select d.id, to_char(k.kpv,'DD-MM-YYYY') as kpv, trim(k.number) as number, trim(k.nimi) as nimi, 
        trim(k.dokument) as dokument, 
         to_char(d.created,'DD.MM.YYYY HH:MM') as created, to_char(d.lastupdate,'DD.MM.YYYY HH:MM') as lastupdate , 
         k.summa,
         s.nimetus as status 
         from docs.doc d 
         inner join docs.korder1 k on d.id = k.parentid 
         inner join libs.library s on s.kood = d.status::text 
         where k.tyyp = 1
            and d.rekvId = $1
            and coalesce(docs.usersRigths(d.id, 'select', $2),true)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: ''
    },
    VORDER: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "kpv", name: "Kuupaev", width: "100px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "nimi", name: "Nimi", width: "200px"},
            {id: "dokument", name: "Dokument", width: "200px"},
            {id: "summa", name: "Summa", width: "100px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Status", width: "100px"}
        ],
        sqlString: `select d.id, to_char(k.kpv,'DD-MM-YYYY') as kpv, trim(k.number) as number, 
             trim(k.nimi) as nimi, trim(k.dokument) as dokument,
             to_char(d.created,'DD.MM.YYYY HH:MM') as created, to_char(d.lastupdate,'DD.MM.YYYY HH:MM') as lastupdate , 
             k.summa, 
             s.nimetus as status 
             from docs.doc d 
             inner join docs.korder1 k on d.id = k.parentid 
             inner join libs.library s on s.kood = d.status::text
             where k.tyyp = 2
                and d.rekvId = $1
                and coalesce(docs.usersRigths(d.id, 'select', $2),true)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: ''
    },
    SMK: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "kpv", name: "Kuupäev", width: "100px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "asutus", name: "Maksja", width: "200px"},
            {id: "aa", name: "Arveldus arve", width: "100px"},
            {id: "viitenr", name: "Viite number", width: "100px"},
            {id: "maksepaev", name: "Maksepäev", width: "100px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Status", width: "100px"}
        ],
        sqlString: `select d.id, to_char(k.kpv,'DD-MM-YYYY') as kpv, trim(k.number) as number, 
             trim(a.nimetus) as asutus, k1.aa, k1.summa, k.viitenr,
             to_char(k.maksepaev,'DD-MM-YYYY') as maksepaev,
             to_char(d.created,'DD.MM.YYYY HH:MM') as created, to_char(d.lastupdate,'DD.MM.YYYY HH:MM') as lastupdate , 
             s.nimetus as status 
             from docs.doc d 
             inner join docs.mk k on d.id = k.parentid 
             inner join docs.mk1 k1 on k.id = k1.parentid 
             inner join libs.asutus a on a.id = k1.asutusid
             inner join libs.library s on s.kood = d.status::text 
             where k.opt = 0
                and d.rekvId = $1
                and coalesce(docs.usersRigths(d.id, 'select', $2),true)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: ''
    },
    VMK: {
        gridConfiguration: [
            {id: "id", name: "id", width: "25px"},
            {id: "kpv", name: "Kuupäev", width: "100px"},
            {id: "number", name: "Number", width: "100px"},
            {id: "asutus", name: "Maksja", width: "200px"},
            {id: "aa", name: "Arveldus arve", width: "100px"},
            {id: "viitenr", name: "Viite number", width: "100px"},
            {id: "maksepaev", name: "Maksepäev", width: "100px"},
            {id: "created", name: "Lisatud", width: "150px"},
            {id: "lastupdate", name: "Viimane parandus", width: "150px"},
            {id: "status", name: "Status", width: "100px"}
        ],
        sqlString: `select d.id, to_char(k.kpv,'DD-MM-YYYY') as kpv, trim(k.number) as number, 
             trim(a.nimetus) as asutus, k1.aa, k1.summa, k.viitenr,
             to_char(k.maksepaev,'DD-MM-YYYY') as maksepaev,
             to_char(d.created,'DD.MM.YYYY HH:MM') as created, to_char(d.lastupdate,'DD.MM.YYYY HH:MM') as lastupdate , 
             s.nimetus as status 
             from docs.doc d 
             inner join docs.mk k on d.id = k.parentid 
             inner join docs.mk1 k1 on k.id = k1.parentid 
             inner join libs.asutus a on a.id = k1.asutusid
             inner join libs.library s on s.kood = d.status::text 
             where k.opt = 1
                and d.rekvId = $1
                and coalesce(docs.usersRigths(d.id, 'select', $2),true)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя
        params: ''
    },
    PALK: {
        gridConfiguration: [
            {id: "id", name: "id", width: "50px"},
            {id: "document", name: "Документ", width: "100px"},
            {id: "isik", name: "Работник", width: "100px"},
            {id: "kpv", name: "Kuupaev", width: "100px"},
            {id: "summa", name: "Сумма", width: "100px"},
            {id: "algab", name: "Договор с ", width: "100px"},
            {id: "lopp", name: "Договор по", width: "100px"},
            {id: "created", name: "Создан", width: "150px"},
            {id: "lastupdate", name: "Последнее изменение", width: "150px"},
            {id: "status", name: "Статус", width: "100px"},

        ],
        sqlString: `select d.id, ltrim(rtrim(l.nimetus))::text as document,ltrim(rtrim(a.nimetus))::text as isik,
         to_char(p.kpv, 'DD.MM.YYYY') as kpv, p.summa, to_char(t.algab,'DD.MM.YYYY') as algab,
         to_char(t.lopp,'DD.MM.YYYY') as lopp, to_char(d.created,'DD.MM.YYYY HH:MM:SS') as created, 
         to_char(d.lastupdate, 'DD.MM.YYYY HH:MM:SS') as lastupdate, s.nimetus as status
         from docs.doc d 
         inner join libs.library l on d.doc_type_id = l.id 
         inner join docs.palk_oper p on p.parentId = d.Id 
         inner join libs.tooleping t on p.lepingId = t.id
         inner join libs.asutus a on a.id = t.parentId
         inner join libs.library s on s.kood = d.status::text 
         where d.rekvId = $1 
         and docs.usersRigths(d.id, 'select', $2)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя

        params: ''
    },
    TAABEL: {
        gridConfiguration: [
            {id: "id", name: "id", width: "50px"},
            {id: "document", name: "Документ", width: "100px"},
            {id: "isik", name: "Работник", width: "100px"},
            {id: "period", name: "Period", width: "100px"},
            {id: "kokku", name: "Tunnid,kokku", width: "100px"},
            {id: "uleajatoo", name: "Üle ajatöö", width: "100px"},
            {id: "created", name: "Создан", width: "150px"},
            {id: "lastupdate", name: "Последнее изменение", width: "150px"},
            {id: "status", name: "Статус", width: "100px"}
        ],
        sqlString: `select d.id, ltrim(rtrim(l.nimetus))::text as document,ltrim(rtrim(a.nimetus))::text as isik,
        (tb.kuu::text || '/' || tb.aasta::text) as period, tb.kokku, tb.uleajatoo,
        to_char(d.created,'DD.MM.YYYY HH:MM:SS') as created, to_char(d.lastupdate,'DD.MM.YYYY HH:MM:SS') as lastupdate,
        ltrim(rtrim(s.nimetus)) as status 
        from docs.doc d 
        inner join libs.library l on d.doc_type_id = l.id 
        inner join docs.palk_taabel1 tb on tb.parentId = d.Id 
        inner join libs.tooleping t on tb.toolepingid = t.id 
        inner join libs.asutus a on a.id = t.parentId
       inner join libs.library s on s.kood = d.status::text 
        where d.rekvId = $1
        and docs.usersRigths(d.id, 'select', $2)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя

        params: ''
    },
    PVKAART: {
        gridConfiguration: [
            {id: "id", name: "id", width: "50px"},
            {id: "document", name: "Документ", width: "100px"},
            {id: "kood", name: "Kood", width: "100px"},
            {id: "nimetus", name: "PV nimetus", width: "200px"},
            {id: "soetmaks", name: "PV soetmaks", width: "100px"},
            {id: "kulum", name: "Kulum(%)", width: "100px"},
            {id: "jaak", name: "Jääk", width: "100px"},
            {id: "isik", name: "Vast.Isik", width: "200px"},
            {id: "created", name: "Создан", width: "150px"},
            {id: "lastupdate", name: "Последнее изменение", width: "150px"},
            {id: "status", name: "Статус", width: "100px"}
        ],
        sqlString: `select d.id, ltrim(rtrim(l.nimetus))::text as document,
         pv.kood, pv.nimetus, pv.soetmaks, pv.kulum, pv.jaak, 
         ltrim(rtrim(a.nimetus))::text as isik, 
         to_char(d.created,'DD.MM.YYYY HH:MM:SS') as created, to_char(d.lastupdate,'DD.MM.YYYY HH:MM:SS') as lastupdate, 
         ltrim(rtrim(s.nimetus)) as status 
         from docs.doc d 
         inner join libs.library l on d.doc_type_id = l.id 
         inner join docs.pv_kaart pv on pv.parentid = d.id 
         left outer join libs.asutus a on a.id = pv.vastisikId 
         inner join libs.library s on s.kood = d.status::text
         where d.rekvId = $1
         and docs.usersRigths(d.id, 'select', $2)`,     // $1 всегда ид учреждения $2 - всегда ид пользователя

        params: ''
    },
    PVOPER: {
        gridConfiguration: [
            {id: "id", name: "id", width: "50px"},
            {id: "document", name: "Документ", width: "100px"},
            {id: "kood", name: "Kood", width: "100px"},
            {id: "nimetus", name: "PV nimetus", width: "200px"},
            {id: "summa", name: "Summa", width: "100px"},
            {id: "tehing", name: "Tehing", width: "100px"},
            {id: "asutus", name: "Kont.agent", width: "100px"},
            {id: "created", name: "Создан", width: "150px"},
            {id: "lastupdate", name: "Последнее изменение", width: "150px"},
            {id: "status", name: "Статус", width: "100px"}
        ],
        sqlString: `select d.id, ltrim(rtrim(l.nimetus))::text as document, 
        pv.kood, ltrim(rtrim(pv.nimetus))::text as nimetus, 
        ltrim(rtrim(g.nimetus))::text as grupp, 
        po.summa, 
        ltrim(rtrim(n.nimetus)) as tehing, 
        ltrim(rtrim(a.nimetus))::text as asutus, 
        to_char(d.created,'DD.MM.YYYY HH:MM:SS') as created, to_char(d.lastupdate,'DD.MM.YYYY HH:MM:SS') as lastupdate 
        ,ltrim(rtrim(s.nimetus)) as status 
        from docs.doc d
        inner join libs.library l on d.doc_type_id = l.id 
        inner join docs.pv_oper po on po.parentid = d.id 
        inner join docs.pv_kaart pv on pv.id = po.pv_kaart_id 
        inner join libs.nomenklatuur n on n.id = po.nomid 
        inner join libs.library g on g.id = pv.gruppid 
        left outer join libs.asutus a on a.id = po.asutusId
        inner join libs.library s on s.kood = d.status::text
        where d.rekvId = $1
        and docs.usersRigths(d.id, 'select', $2)`,     //$1 всегда ид учреждения $2 - всегда ид пользователя
        params: ''
    }

};
