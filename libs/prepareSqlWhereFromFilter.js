/**
 * создаст строку - фильтр из параметров
 * @param filterData
 * @param docTypeId
 * @returns {string}
 */
const prepareSqlWhereFromFilter = (filterData, docTypeId) => {
    let filterString = ''; // строка фильтра
    let kas_sisaldab = '';

    filterData.forEach((row) => {
        if (row.value) {
            filterString = filterString + (filterString.length > 0 ? " and " : " where ");

            kas_sisaldab = row.sqlNo && Number(row.sqlNo) == 0 ? 'NOT' : '';

            switch (row.type) {
                case 'text':

                    let prepairedParameter = row.value.split(',').map(str => `'${str.trim()}'`).join(',');

                    // если параметры раздедены, то множественный параметр
                    if (row.value.match(/,/)) {
                        filterString = `${filterString} ${row.id} ${kas_sisaldab}  in (${prepairedParameter})`;
                    } else {
                        if (docTypeId == 'KUU_TAABEL') {
                            filterString = `${filterString}  upper(${row.id}) ${kas_sisaldab} like upper('%${row.value.trim()}%')`;
                        } else {
                            // обработка некорректной кодировки
                            filterString = `${filterString}  upper(${row.id}) ${kas_sisaldab} like upper('%${row.value.trim()}%')`;

                        }
                    }
                    break;
                case 'string':
                    filterString = `${filterString}  upper(${row.id}) ${kas_sisaldab} like upper('%${row.value.trim()}%')`;
                    break;
                case 'date':
                    if ('start' in row && row.start) {
                        filterString = `${filterString} format_date(${row.id}::text)  >=  format_date('${row.start}'::text) and (format_date(${row.id}::text)  <=  format_date('${row.end}'::text) or ${row.end} is null)`;
                    } else if (row.id == 'valid') {
                        // для этого поля ставим фильтр на контект действует до
                        filterString = `${filterString} (format_date(${row.id}::text)  >=  format_date('${row.value}'::text) or ${row.id} is null)`;
                    } else {
                        filterString = filterString + row.id + (kas_sisaldab && kas_sisaldab == 'NOT' ? "<>" : "=") + "'" + row.value + "'";
                    }


                    break;
                case 'number':
                    if ('start' in row && row.start) {
                        filterString = `${filterString} ${row.id}::numeric  >=  ${row.start} and (${row.id}::numeric  <=  ${row.end} or ${row.end} is null)`;
                    } else {
                        filterString = filterString + row.id + "::numeric  " + (kas_sisaldab && kas_sisaldab == 'NOT' ? "<>" : "=") + row.value;
                    }
                    break;
                case 'integer':
                    if ('start' in row && row.start) {
                        filterString = `${filterString} ${row.id}  >=  ${row.start} and (${row.id}  <=  ${row.end} or ${row.end} is null)`;
                    } else {
                        filterString = filterString + row.id + "::integer  " + (kas_sisaldab && kas_sisaldab == 'NOT' ? "<>" : "=") + row.value;
                    }
                    break;
            }
        }
    });

    return filterString;
};


module.exports = prepareSqlWhereFromFilter;