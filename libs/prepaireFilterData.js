const DocContext = require('./../frontend/doc-context');
const getDefaulDate = require('./getDefaultDate');

/**
 * вернет дефолтные значения взависимости от типа
 * @param row
 */
const getDefaultValues = (row) => {
    let returnValue = {
        start: null,
        end: null,
        value: null
    };

    if (!!row.interval && !row.start && !row.end)
    {
        switch (row.type) {
            case 'date':
                returnValue.start = getDefaulDate().start;
                returnValue.end = getDefaulDate().end;
                break;
            default:
                returnValue.start = null;
                returnValue.end;
        }
    }
    return returnValue;
};


function prepareFilterData(gridConfig, docTypeId) {
    let data = [];

    if (!DocContext.filter) {
        DocContext.filter = {};
    }

    if (!DocContext.filter[docTypeId]) {
        DocContext.filter[docTypeId] = [];
    }

    // проверим, если фильтр уже сохранен, то вернем уже ранее сохжанный массив
    if (docTypeId && DocContext.filter[docTypeId].length > 0) {
        data = DocContext.filter[docTypeId];
    } else {
        gridConfig.map((row) => {
            let defValue = getDefaultValues(row);
            let start = defValue.start;
            let end = defValue.end;

            const field = {
                value: row.value ? row.value : null,
                name: row.id,
                type: row.type ? row.type : 'text',
                interval: !!row.interval,
                start: row.value ? row.value : start,
                end: row.value ? row.value : end
            };

            data.push(field);

        });
    }

    return data;
}




module.exports = prepareFilterData;