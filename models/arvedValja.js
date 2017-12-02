module.exports = {
    selectAsLibs: "select a.id, trim(a.number) as kood, ('Number:' || a.number::text || ' Kuupäev:' || a.kpv::text || ' Jääk:' || a.jaak::text) as name " +
    " from docs.arv a" +
    " inner join docs.doc d on d.id = a.parentid " +
    " where (a.liik = 0 "  +
    " and a.asutusid = $1 " +
    " and d.status > 0 " +
    " and a.jaak > 0 " +
    ") " +
    " or (a.id = $2) " +
    " order by a.id desc"
}

