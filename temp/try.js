const data = [{"47102122229":[{"id":"1","lapsed_kokku":"2","soodustus":"25.00","percent":"25","period":"2018-12-31T22:00:00.000Z","lapse_isikukood":"49308233762","lapse_nimi":"Angelina","vanem_nimi":"Svetlana Tsaikina","vanem_isikukood":"47102122229","lapsed":2,"asutus":"RAHANDUSAMET T","viga":null,"kond":"70"},{"id":"2","lapsed_kokku":"2","soodustus":"28.57","percent":"25","period":"2018-12-31T22:00:00.000Z","lapse_isikukood":"5090939329","lapse_nimi":"Mark","vanem_nimi":"Svetlana Tsaikina","vanem_isikukood":"47102122229","lapsed":2,"asutus":"RAHANDUSAMET T","viga":"Viga, > 25","kond":"70"}]}];

let groupValue = Object.keys(data[0])[0];
console.log('objKokku',groupValue,'obj', data[0][groupValue][0].lapsed_kokku);


