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

    if (!!row.interval && !row.start && !row.end) {
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

    // проверим, если фильтр уже сохранен, то вернем уже ранее сохжанный массив
    if (DocContext.getFilter.length > 0) {
        data = DocContext.getFilter;
    } else {
        gridConfig.map((row) => {

            const field = {
                id: row.id,
                value: row.value ? row.value : null,
                name: row.id,
                sqlNo: 1,
                type: row.type ? row.type : 'text',
                interval: !!row.interval,
                start: row.value ? row.value : null,
                end: row.value ? row.value : null
            };


            if (row.interval) {
                field[`${row.id}_start`] = row.value ? row.value : null;
                field[`${row.id}_end`] = row.value ? row.value : null
            }

            data.push(field);

        });
    }

    return data;
}


module.exports = prepareFilterData;