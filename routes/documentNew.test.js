'use strict';
const request = require('request');
const URL = 'http://localhost:3000';

describe('test for documentNew', () => {
    let responseHeader,
        cookieJar,
        cookies,
        cookie;

    it('login Post', async () => {
            expect.assertions(1);
            //auth
            let response = await asyncRequestPost(URL + '/login', {username: 'vlad', password: '123'});
            expect(response.statusCode).toBeDefined();
        }
    );

    it ('test of /document/:documentType/:id', async(done) => {

//        expect.assertions(3);
        let response = await asyncRequestGet(URL + '/document/journal/0');
        expect(response.statusCode).toBeDefined();
        expect(response.statusCode).toBe(200);
        done();
    });

    it.skip ('test of PUT NewApi/document', async(done) => {
        let kood = 'testKood' + +Math.random();
        const params = {
            id: 0,
            kood: kood.slice(0, 20),
            nimetus: 'testNimetus',
            library:"TUNNUS"
        };

        expect.assertions(3);
        let response = await asyncRequestPut(URL + '/newApi/document/tunnus/0', params);
        expect(response.statusCode).toBeDefined();
        expect(response.statusCode).toBe(200);
        let result = JSON.parse(response.body).result;
        expect(result.result.error_code).toBe(0);
        done();
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
};

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

const asyncRequestPut = (url, params, jar, cookie) => {
    return new Promise((resolve, reject) => {
        request.put({
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
