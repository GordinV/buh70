const DocContext = require('./../frontend/doc-context');
const getDefaultDates = require('./getDefaultDate');

/**
 * создаст массив для создания фильтра
 */
function createEmptyFilterData(gridConfig, filterData, docTypeId) {
    filterData = gridConfig.map((row) => {
        // props.data пустое, создаем
        let value = row.value ? row.value : null;

        if (row.default) {

            const defaultValue = getDefaultDates(row.default);

            if (row.interval) {
                value = defaultValue.start;

                row.start = defaultValue.start;
                row[`${row.id}_start`] = defaultValue.start;
                row.end = defaultValue.end;
                row[`${row.id}_end`] = defaultValue.end;
            } else {
                if (docTypeId === 'LAPS' && (row.id === 'kehtivus' || row.id === 'kehtiv_kpv')) {
                    value = defaultValue.value;
                }
            }
        }


        if (!row.type) {
            row.type = 'text';
        }
        row.value = value;
        return row;

    });

    DocContext.setFilter = filterData;
    return filterData;
}

module.exports = createEmptyFilterData;