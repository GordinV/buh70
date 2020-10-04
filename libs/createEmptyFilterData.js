const DocContext = require('./../frontend/doc-context');


/**
 * создаст массив для создания фильтра
 */
function createEmptyFilterData(gridConfig, filterData, docTypeId) {
    filterData = gridConfig.map((row) => {
        // props.data пустое, создаем
        let value = row.value ? row.value : null;

        if (row.default) {

            const defaultValue = getDefaultDates(row.default);
            value = defaultValue.start;
            if (row.interval) {
                row.start = defaultValue.start;
                row[`${row.id}_start`] = defaultValue.start;
                row.end = defaultValue.end;
                row[`${row.id}_end`] = defaultValue.end;
            }
        }

        if (!row.type) {
            row.type = 'text';
        }
        row.value = value;
        return row;

    });

    DocContext.filter[docTypeId] = filterData;
    return filterData;
}

module.exports = createEmptyFilterData;