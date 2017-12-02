module.exports = {
    sqlString: `select module::text as id, '0' as parentId, trim(both '"' from module::text) as kood, trim(both '"' from module::text) as name, null::text as props, true as is_node
                        from (select distinct  jsonb_array_elements((properties::jsonb -> 'module')) as module
                                from libs.library l 
                                where ($1 = 0 or l.rekvid = $1) 
                                and l.library = 'DOK') modules
                    union all            
                    select l.id::text , modules.module::text as parentId, ltrim(rtrim(kood))::text as kood, trim(l.nimetus)::text as name, 
                        properties::text as props, false as is_node
                        from libs.library l 
                        left outer join (select distinct  jsonb_array_elements((properties::jsonb -> 'module')) as module
                                from libs.library l 
                                where ($1 = 0 or l.rekvid = $1) 
                                and l.library = 'DOK'
                                ) modules on (properties::jsonb -> 'module')::jsonb @> modules.module
                        where ($1 = 0 or l.rekvid = $1) and l.library = 'DOK'`,
    params: ['rekvId']
}
