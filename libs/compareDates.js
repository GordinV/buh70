function compareDates(date1, date2) {

    let kpv1 = new Date(date1);
    kpv1.setDate(kpv1.getDate() + 1);

    let kpv2  = new Date(date2);
    if (kpv1 >= kpv2) {
        return true;
    } else {
        return false;
    }
}

module.exports = compareDates;