/**
 * создаст строку - фильтр из параметров
 * @param filterData
 * @param docTypeId
 * @returns {string}
 */
const prepareSqlWhereFromFilter = (filterData, docTypeId) => {
    let filterString = ''; // строка фильтра

    filterData.forEach((row) => {
        if (row.value) {
            filterString = filterString + (filterString.length > 0 ? " and " : " where ");

            switch (row.type) {
                case 'text':

                    let prepairedParameter = row.value.split(',').map(str => `'${str.trim()}'`).join(',');

                    // если параметры раздедены, то множественный параметр
                    if (row.value.match(/,/)) {
                        filterString = `${filterString} ${row.name} in (${prepairedParameter})`;
                    } else {
                        if (docTypeId == 'KUU_TAABEL') {
                            filterString = `${filterString}  upper(${row.name})  like upper('%${row.value.trim()}%')`;
                        } else {
                            // обработка некорректной кодировки
                            filterString = `${filterString}  upper(${row.name})  like upper('%${row.value.trim()}%')`;

                        }
                    }
                    break;
                case 'string':
                    filterString = `${filterString}  upper(${row.name}) like upper('%${row.value.trim()}%')`;
                    break;
                case 'date':
                    if ('start' in row) {
                        filterString = `${filterString} format_date(${row.id}::text)  >=  format_date('${row.start}'::text) and format_date(${row.id}::text)  <=  format_date('${row.end}'::text)`;
                    } else {
                        filterString = filterString + row.id + " = '" + row.value + "'";
                    }

                    break;
                case 'number':
                    if ('start' in row) {
                        filterString = `${filterString} ${row.name}::numeric  >=  ${row.start} and ${row.name}::numeric  <=  ${row.end} `;
                    } else {
                        filterString = filterString + row.name + "::numeric = " + row.value;
                    }
                    break;
                case 'integer':
                    if ('start' in row) {
                        filterString = `${filterString} ${row.name}  >=  ${row.start} and ${row.name}  <=  ${row.end} `;
                    } else {
                        filterString = filterString + row.name + "::integer = " + row.value;
                    }
                    break;
            }
        }
    });

    return filterString;
};


module.exports = prepareSqlWhereFromFilter;