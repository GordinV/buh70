function compareDates(date1, date2) {

    let kpv1 = new Date(date1);

    let kpv2  = new Date(date2);
    if (kpv1 > kpv2) {
        console.log('первая дата больше', date1);
        return true;
    } else {
        console.log('вторая дата больше или даты равны', date2);
        return false;
    }
}

module.exports = compareDates;