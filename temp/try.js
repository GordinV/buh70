let obj = [{id: 1, summa: 10, name: "Koosta arve"}, {id: 2, summa: 20, name:'test asutus'}, {id:3, name:'nimi'}];
let summa = obj.reduce((summaKokku, currentRow) => {
    console.log(summaKokku, currentRow);
    return (summaKokku + (currentRow.summa ? currentRow.summa: 0));
},0);

console.log('indx', summa);

