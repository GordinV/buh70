module.exports = {
    selectAsLibs: `select id, trim(arve) as kood, trim(nimetus) as name 
    from ou.aa 
    where parentid = 1 
    and pank = 1
    order by default_ desc`
}
