/**
 * Справочник доступныйх профилей контировки для типа документа.
 */
module.exports = {
    selectAsLibs: `select d.id, d.selg as name, l.nimetus as dok, d.details 
         from libs.library l 
         left outer join libs.dokprop d on l.id = d.parentId 
         where l.library = 'DOK'`  //and l.kood = $1  and l.rekvId = $2`
};
