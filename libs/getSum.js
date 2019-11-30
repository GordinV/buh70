// will calculate sum of some field
const getSum = (data, columnField) => {

    let total = 0;
    if (data && data.length && data[0][columnField]) {
        data.forEach(row => total = total + Number(row[columnField]));
    }

    return total.toFixed(2);
};
module.exports = getSum;