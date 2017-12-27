'use strict';

const checkAuth = require('../middleware/checkAuth');

module.exports = function (app) {
// same as main
    app.get('/', require('./login').get);
    app.post('/', require('./login').post);

//login logic
    app.get('/login', require('./login').get);

    app.post('/login', require('./login').post);
    // logout logic
    app.get('/logout', require('./logout').get);
//  app.post('/logout', require('./logout').post);
//  app.get('/api/doc/', checkAuth, require('./api_doc').get);
//    app.get('/document/:documentType/:id', checkAuth, require('./documentNew').get);

    app.get('/raama', require('./raama').get); // module raamatupidamine
    app.get('/raama/:documentType', require('./raama').get); // module raamatupidamine
    app.get('/raama/:documentType/:id', checkAuth, require('./raama/document').get); // module raamatupidamine
//    app.get('/tunnused/tunnus:id', checkAuth, require('./tunnus').get); // module tunnused


    // opens main page
    // opens page with list of departments
/*
    app.get('/changeDepartment', checkAuth, require('./changeDepartment').get);
    app.get('/changeDepartment/:id', checkAuth, require('./changeDepartment').get);
*/
    // opens document template
    // opens document template
 /*   app.post('/api', checkAuth, require('./api').post);

    app.post('/api/docs', checkAuth, require('./api').post);
    app.post('/api/doc', checkAuth, require('./api_doc').post);
*/
    app.post('/newApi/startMenu',require('./startMenu').post); //checkAuth,
    app.post('/newApi/document/:documentType/:id',require('./documentRegister').post); //апи для обмена даты по протоколу POST с моделью документа
    app.put('/newApi/document/:documentType/:id',require('./documentRegister').put); //апи для обмена даты по протоколу POST с моделью документа
    app.post('/newApi/loadLibs/:documentType', require('./loadLibs').post); //checkAuth,
    app.post('/newApi', checkAuth, require('./newApi').post); //checkAuth,
/*

    app.delete('/api/doc/:id', checkAuth, require('./api_doc').delete);

*/

};