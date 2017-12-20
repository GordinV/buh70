'use strict';
const request = require('request');
const URL = 'http://localhost:3000';

describe('test for loadLibs', () => {
    let responseHeader,
        cookieJar,
        cookies,
        cookie;

    it('post auth request', async () => {
            expect.assertions(1);
            //auth
            let response = await asyncRequestPost(URL + '/login', {username: 'vlad', password: '123'});
            expect(response.statusCode).toBeDefined();
        }
    );

    it('test of loadLibs api', async () => {
        expect.assertions(2);

        let response = await asyncRequestPost(URL + '/newApi/loadLibs/KONTOD');

        expect(response.statusCode).toBeDefined();
        expect(response.statusCode).toBe(200);
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
