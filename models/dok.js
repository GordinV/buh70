module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "type", name: "type", width: "20%"},
            {id: "doc_type_id", name: "docTypeId", width: "20%", show: false},
            {id: "created", name: "created", width: "20%"},
            {id: "lastupdate", name: "Last change", width: "20%"},
            {id: "status", name: "Status", width: "30%"}

        ],
        sqlString: `select d.id, trim(l.nimetus) as type, trim(l.kood)::text as doc_type_id, to_char(d.created, 'DD.MM.YYYY HH:MM:SS')::text as created, 
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
};