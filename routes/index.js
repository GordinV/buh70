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

    app.get('/raama', require('./raama').get); // module raamatupidamine
    app.get('/raama/:documentType', require('./raama').get); // module raamatupidamine
    app.get('/raama/:documentType/:id', checkAuth, require('./raama/document').get); // module raamatupidamine

    app.get('/lapsed', checkAuth, require('./lapsed').get); // module raamatupidamine
    app.get('/lapsed/:documentType', checkAuth, require('./lapsed').get); // module raamatupidamine
    app.get('/lapsed/:documentType/:id', checkAuth, require('./lapsed/document').get); // module lapsed
    app.get('/lapsed/:documentType/:id/:paramId', checkAuth, require('./lapsed/document').get); // module lapsed

    app.post('/newApi/startMenu/:module',require('./startMenu').post); //checkAuth,
    app.post('/newApi/document/:documentType/:id',require('./documentRegister').post); //апи для обмена даты по протоколу POST с моделью документа
    app.put('/newApi/document/:documentType/:id',require('./documentRegister').put); //апи для обмена даты по протоколу POST с моделью документа
    app.post('/newApi/loadLibs/:documentType', require('./loadLibs').post); //checkAuth,
    app.post('/newApi/changeAsutus/:rekvId', checkAuth, require('./changeAsutus').post); //checkAuth,
    app.post('/newApi', checkAuth, require('./newApi').post); //checkAuth,
/*

    app.delete('/api/doc/:id', checkAuth, require('./api_doc').delete);

*/

};