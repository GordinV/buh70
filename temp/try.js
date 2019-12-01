const data = JSON.parse(`[
    {"Projekt LSP6 T":[{"id":"2","isikukood":"37303023721","nimi":"Lev Gordin","asutus":"Projekt LSP6 T","age":"02.03.1973","age_27":"02.03.2000"}]},
    {"RAHANDUSAMET T":[{"id":"1","isikukood":"37303023721","nimi":"Lev Gordin","asutus":"RAHANDUSAMET T","age":"02.03.1973","age_27":"02.03.2000"}]}]`);

data.forEach(row=> {
    console.log('row', Object.keys(row)[0]);
    console.log('data', row[Object.keys(row)[0]]);
});

//console.log(Object.keys(data[0]))
