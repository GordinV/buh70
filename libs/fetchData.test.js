//const request = require('request');
const URL = 'http://localhost:3000';
const fetchData = require('./fetchData');

describe('test for fetchData', () => {
    it('should be loaded',()=> {
        expect(fetchData).toBeDefined();
    });

    it('test of get request', async()=>{
        let response = await fetchData.fetchDataGet(URL);
        expect(response).toBeDefined();
        expect(response.status).toBe(200);
    });

    it('test of post to newApi request', async()=>{
        const url = URL + '/newApi';
        const params = {
            parameter: 'TUNNUS', // параметры
            sortBy: null, // сортировка
            sqlWhere: null, // динамический фильтр грида
            lastDocId: null
        }
        let response = await fetchData.fetchDataPost(URL, params);
        expect(response).toBeDefined();
        expect(response.status).toBeDefined();
        expect(response.status).toBe(200);
    });

    it('test of post to /newApi/startMenu request', async()=>{
        const url = URL + '/newApi/startMenu';
        let response = await fetchData.fetchDataPost(URL);
        expect(response).toBeDefined();
        expect(response.status).toBeDefined();
        expect(response.status).toBe(200);
    });

});
