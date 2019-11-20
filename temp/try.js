const arveRead = [{vat: '0', summa: 10}, {vat: '10', summa: 20}, {vat: '10', summa: 30}];
const vatArray = [];
const vatTotals = [];

arveRead.forEach(rea => {
    vatArray.push(rea.vat)
});

let unique = [...new Set(vatArray)];

// summ
unique.forEach((vat, index) => {
    let summa = 0;
    arveRead.forEach(rea => {
        if (rea.vat === vat) {
            summa = summa + rea.summa;
        }
    });

    // push
    vatTotals.push({vat: vat, summa: summa});
});
console.log('vatTotals', vatTotals);