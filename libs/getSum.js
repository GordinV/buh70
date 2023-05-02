// will calculate sum of some field
const getSum = (data, columnField) => {

    let total = 0;
    if (data && data.length ) {
        data.forEach((row) => {
            total = total + (row[columnField] ? Number(row[columnField]): 0);
            return total;
        });
    }

    return total.toFixed(2);
};
module.exports = getSum;