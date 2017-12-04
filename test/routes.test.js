'use strict';
const request = require('request');
const URL = 'http://localhost:3000';

describe('test for server', () => {
    let responseHeader,
        cookieJar,
        cookies,
        cookie;

    it('get request', async() => {
            expect.assertions(1);
            let response = await asyncRequestGet(URL);
            expect(response.statusCode).toBe(200);
        }
    );

    it('test of get routes, login', async() => {
        expect.assertions(1);
        let response = await asyncRequestGet(URL + '/login');
        expect(response.statusCode).toBe(200);
    });

    it('test of get routes, logout', async() => {
        expect.assertions(1);
        let response = await asyncRequestGet(URL + '/logout');

        expect(response.statusCode).toBe(200);
    });

    it('test of post routes, login with wrong password', async() => {
        let response = await asyncRequestPost(URL + '/login', {username: 'vlad', password: 'xxx123'});
        expect(response.statusCode).toBeDefined();
        expect(response.statusCode).toBe(200); //redirect
        expect(response.headers).not.toHaveProperty('location'); //no redirect
    });

    it('test of post routes, login with right password', async() => {
        let response = await asyncRequestPost(URL + '/login', {username: 'vlad', password: '123'});
        expect(response.statusCode).toBeDefined();
        expect(response.statusCode).toBe(302); //redirect
        expect(response.headers).toHaveProperty('location'); //redirect
        expect(response.headers.location).toBe('/documents'); //redirect
        cookieJar = request.jar();
        responseHeader = response.headers;
        cookies = response.headers['set-cookie'][0].split(',').map(item => item.split(';')[0]);
        cookie = cookies.join(';');

    });

    it('test of get routes, documents', async() => {
        expect.assertions(2);
        let response = await asyncRequestGet(URL + '/documents', cookieJar, cookie);
        expect(response.statusCode).toBe(404);
        response = await asyncRequestGet(URL + '/documents/tunnus', cookieJar, cookie);
        expect(response.statusCode).toBe(200); //проверка для регистра с типом TUNNUS
    });

    it('test of get routes, document', async() => {
        expect.assertions(1);
        let response = await asyncRequestGet(URL + '/document/ARV0', cookieJar, cookie);
        expect(response.statusCode).toBe(200);
    });

    it('test of get wrong route, wrong', async() => {
        expect.assertions(1);
        let response = await asyncRequestGet(URL + '/wrong', cookieJar, cookie);
        expect(response.statusCode).toBe(404);
    });

    it('test of delete api', async() => {
        let response;
        try {
            response = await asyncRequestDelete(URL + '/api/doc' + '/ARV1', cookieJar, cookie);

        } catch (e) {
            console.log('failed', e);
        }
        let result = JSON.parse(response.body);
        expect(response.statusCode).toBeDefined();
        expect(response.statusCode).toBe(200);
        expect(result).toBeDefined();
        expect(result[0]).toHaveProperty('error_code');
    });

    it('test of doc selectAsLibs api', async() => {
        //        requery('selectAsLibs', JSON.stringify({doc_type_id: libraryName, id: 0, params: libParams}), function (err, data) {

        let params = {
            action: 'selectAsLibs',
            data: JSON.stringify({doc_type_id: 'aa', id:0, params:[]})
        };

        let response = await asyncRequestPost(URL + '/api/doc',params, cookieJar, cookie);

        expect(response.statusCode).toBeDefined();
        expect(response.statusCode).toBe(200);
        expect(response.statusCode).toBe(200);

        let result = JSON.parse(response.body);
        expect(result).toBeDefined();
        expect(result[0]).toHaveProperty('id');
    });

    it('test of doc execute api', async() => {
        //            params = {params: data, userId: user.userId, rekvId: user.asutusId, userName: user.userName};
        const tasksParameters = {
            docId: 0,
            tasks: ['start'],
            doc_type_id: 'ARV'
        };

        let params = {
            action: 'execute',
            data: JSON.stringify(tasksParameters)
        };

        let response = await asyncRequestPost(URL + '/api/doc',params, cookieJar, cookie);

        expect(response.statusCode).toBeDefined();
        expect(response.statusCode).toBe(200);
        expect(response.statusCode).toBe(200);

        let result = JSON.parse(response.body);
        expect(result).toBeDefined();
        expect(result).toHaveProperty('result');

    });
});

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
};

const asyncRequestDelete = (url, jar, cookie) => {
    return new Promise((resolve, reject) => {
        request.delete({
            url: url,
            jar: jar,
            headers: {Cookie: cookie}

        }, (error, response, body) => {
            if (error) return reject(error);
            resolve(response);
        });
    });
};

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
};