module.exports =  (rekvId, userId, params, receivedFilter)=> {
    let SqlParams = params.map(parameter => {
        // ищем в фильтре параметер
        if (parameter === 'rekvid') {
            return rekvId;
        }

        if (parameter === 'userid') {
            return userId;
        }

        let fieldValue;
        const result = receivedFilter.find(row=> {
            let fieldName = row.id;
            let parameterToSearch = parameter;

            if (!!parameter.match(/_start/) && !!row.start) {
                fieldName = `${row.id.toLowerCase()}_start`;
                fieldValue = row.start;
            } else if ((!!parameter.match(/_end/) && row.end)) {
                fieldName = `${row.id.toLowerCase()}_end`;
                fieldValue = row.end;
            } else {
                fieldName = row.id;
                fieldValue = row.value;
            }

            return fieldName === parameterToSearch;
        });

        if (result) {
            return fieldValue;
        } else {
            return null
        }
    });

    return SqlParams;
};