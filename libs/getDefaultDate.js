/**
 * добавит ноль в месяц или день по необходимости
 * @param value
 * @returns {string}
 */
const getTwoDigits = (value) => value < 10 ? `0${value}` : value;


/**
 * вернет дефолтные значения взависимости от типа
 * @param row
 */
const getDefaultDate = (period) => {
    let returnValue = {
        start: null,
        end: null,
        value: null
    };
    Date.prototype.daysInMonth = function () {
        return 33 - new Date(this.getFullYear(), this.getMonth(), 33).getDate();
    };

    let today = new Date();

    let currentMonth = getTwoDigits(today.getMonth() + 1);
    let currentYear = getTwoDigits(today.getFullYear());
    let startMonth = `${currentYear}-${currentMonth}-01`;
    let daysInMonth = getTwoDigits(today.daysInMonth());

    let finishMonth = `${currentYear}-${currentMonth}-${daysInMonth}`;

    switch (period) {
        case 'KUU':


            returnValue.start = startMonth;
            returnValue.end = finishMonth;

            break;
        case 'AASTA':
            returnValue.start = `${currentYear}-01-01`;
            returnValue.end = `${currentYear}-12-31`;

        default:
            returnValue.start = null;
            returnValue.end = null;
    }
    return returnValue;


};


module.exports = getDefaultDate;