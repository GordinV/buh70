'use strict';
const request = require('request');
const URL = 'http://localhost:3000';

describe('test for newApi', () => {
    let responseHeader,
        cookieJar,
        cookies,
        cookie

    it('get request', async () => {
            expect.assertions(1);
            //auth
            let response = await asyncRequestPost(URL + '/login', {username: 'vlad', password: '123'});
            expect(response.statusCode).toBeDefined();
        }
    );

    it ('test of NewApi', async() => {
        // сортировка
        let sqlSortBy = '',
            sqlWhere = '';

        const params = {
            parameter: 'TUNNUS', // параметры
            sortBy: sqlSortBy, // сортировка
            lastDocId: null,
            sqlWhere: sqlWhere, // динамический фильтр грида
        };

        expect.assertions(2);
        let response = await asyncRequestPost(URL + '/newApi', params);
        expect(response.statusCode).toBeDefined();
        expect(response.statusCode).toBe(200);
        console.log(response.body);

    });


});

const asyncRequestPost = (url, params, jar, cookie) => {
    return new Promise((resolve, reject) => {
        request.post({
            url: url,
            form: params,
            jar: jar,
            headers: {Cookie: cookie}

        }, (error, response, body) => {
            if (error) return reject(error);
            resolve(response);
        });
    });
}

const asyncRequestGet = (url, jar, cookie) => {
    return new Promise((resolve, reject) => {
        request.get({
            url: url,
            jar: true,
            headers: {Cookie: cookie}
        }, (error, response) => {
            if (error) return reject(error);
            resolve(response);
        });
    });
}
