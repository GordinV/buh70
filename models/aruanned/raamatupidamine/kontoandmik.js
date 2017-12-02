module.exports = {
    grid: {
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
        params: '',
    }
}
