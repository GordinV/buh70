const _ = require('lodash');

// осуществляет фильтрацию по значение и ищет во всех текстовых полях

module.exports = (data, filter) => {
    let result = data.filter((row) => {

        return !! _.find((row), function (value, key) {

            if (typeof value === 'string' && value.includes(filter)) {
                return true;
            }
        });
    });
    return result;
};