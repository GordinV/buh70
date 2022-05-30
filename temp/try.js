let data = JSON.parse( '[{"filter_total":"5","id":74810,"parentid":13931,"rekvid":80,"nomid":18782,"kuu":5,"aasta":2022,"kogus":"2.00","hind":"0.32","uhik":"päev","umberarvestus":"Ei","soodustus":"0.00","summa":"0.64","isikukood":"51901210112","viitenumber":"9064720","nimi":"Potapov Platon","kood":"322040-005","teenus":"Toitlustamine (pärastlõuna - sõimerühm)","yksus":"02 Sõimerühm-","viitenr":"9064720","userid":48,"muud":null,"tab_tyyp":"Tavaline"},{"filter_total":"5","id":74813,"parentid":13931,"rekvid":80,"nomid":18781,"kuu":5,"aasta":2022,"kogus":"2.00","hind":"0.72","uhik":"päev","umberarvestus":"Ei","soodustus":"0.00","summa":"1.44","isikukood":"51901210112","viitenumber":"9064720","nimi":"Potapov Platon","kood":"322040-004","teenus":"Toitlustamine (lõuna - sõimerühm)","yksus":"02 Sõimerühm-","viitenr":"9064720","userid":48,"muud":null,"tab_tyyp":"Tavaline"},{"filter_total":"5","id":74812,"parentid":13931,"rekvid":80,"nomid":18780,"kuu":5,"aasta":2022,"kogus":"2.00","hind":"0.56","uhik":"päev","umberarvestus":"Ei","soodustus":"0.00","summa":"1.12","isikukood":"51901210112","viitenumber":"9064720","nimi":"Potapov Platon","kood":"322040-003","teenus":"Toitlustamine (hommikueine - sõimerühm)","yksus":"02 Sõimerühm-","viitenr":"9064720","userid":48,"muud":null,"tab_tyyp":"Tavaline"},{"filter_total":"5","id":74814,"parentid":13931,"rekvid":80,"nomid":18778,"kuu":5,"aasta":2022,"kogus":"1.00","hind":"8.76","uhik":"kuu","umberarvestus":"Ei","soodustus":"2.19","summa":"6.57","isikukood":"51901210112","viitenumber":"9064720","nimi":"Potapov Platon","kood":"322030-016","teenus":" Õppetasu","yksus":"02 Sõimerühm-","viitenr":"9064720","userid":48,"muud":"(2 päeva)","tab_tyyp":"Tavaline"},{"filter_total":"5","id":74811,"parentid":13931,"rekvid":80,"nomid":18776,"kuu":5,"aasta":2022,"kogus":"1.00","hind":"20.44","uhik":"kuu","umberarvestus":"Ei","soodustus":"5.11","summa":"15.33","isikukood":"51901210112","viitenumber":"9064720","nimi":"Potapov Platon","kood":"322020-014","teenus":"Kohatasu","yksus":"02 Sõimerühm-","viitenr":"9064720","userid":48,"muud":"(2 päeva)","tab_tyyp":"Tavaline"}]');


// пройти по циклу, найти льготы и сделать вставку на льготу
let dataUpdated = [];

data.forEach((row, index) => {
    row.kasSoodustus = false;
    // ищем льготы

    if (Number(row.soodustus) > 0 ) {
// меняем сумму на полную
        row.summa = Number(row.kogus) * Number(row.hind);
        console.log('Soodustus',row.soodustus );
        // делаем вставку в массив
        let lisa = Object.assign({},row);
        lisa.kasSoodustus = true;
        lisa.summa = Number(row.soodustus);
        dataUpdated.push(lisa);
    }
    dataUpdated.push(row);

});

console.log(dataUpdated);

