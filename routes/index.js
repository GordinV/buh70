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
    // logout logic
    app.post('/logout', require('./logout').post);

    app.get('/raama', require('./raama').get); // module raamatupidamine
    app.get('/raama/:documentType', checkAuth, require('./raama').get); // module raamatupidamine
    app.get('/raama/:documentType/:id', checkAuth, require('./raama/document').get); // module raamatupidamine

    app.get('/lapsed', checkAuth, require('./lapsed').get); // module lapsed
    app.get('/lapsed/:documentType', checkAuth, require('./lapsed').get); // module lapsed
    app.get('/lapsed/:documentType/:id', checkAuth, require('./lapsed/document').get); // module lapsed
    app.get('/lapsed/:documentType/:id/:paramId', checkAuth, require('./lapsed/document').get); // module lapsed

    app.post('/newApi/startMenu/:module', require('./startMenu').post); //checkAuth,
    app.post('/newApi/document/:documentType/:id', checkAuth, require('./documentRegister').post); //апи для обмена даты по протоколу POST с моделью документа
    app.put('/newApi/document/:documentType/:id', checkAuth, require('./documentRegister').put); //апи для обмена даты по протоколу PUT с моделью документа
    app.post('/newApi/loadLibs/:documentType', checkAuth, require('./loadLibs').post); //checkAuth,
    app.post('/newApi/changeAsutus/:rekvId', checkAuth, require('./changeAsutus').post); //checkAuth,
    app.post('/newApi/delete', checkAuth, require('./documentRegister').delete); //checkAuth
    app.post('/newApi/task/:taskName', checkAuth, require('./documentRegister').executeTask);
    app.post('/newApi/logs', checkAuth, require('./documentRegister').getLogs);
//    app.post('/newApi/upload/:uuid/:documentType', require('./documentRegister').upload);
    app.post('/newApi/upload/', require('./documentRegister').upload);
    app.post('/newApi/validate/:method/:parameter', checkAuth, require('./documentRegister').validate); //проверка в моделе , метод по значению

    app.post('/newApi', checkAuth, require('./newApi').post); //checkAuth, //checkAuth,

    app.get('/print/:documentType/:uuid/:id/:params', require('./print').get); //checkAuth
//    app.get('/print/:documentType/:uuid/:id/:sqlWhere/:sqlSort', require('./print').get); //checkAuth
    app.get('/print/:documentType/:uuid/:id/', require('./print').get); //checkAuth
    app.get('/multiple_print/:documentType/:uuid/:id/', require('./multiple_print').get); //checkAuth
    app.get('/print/:documentType/:uuid/', require('./print').get); //checkAuth


    app.get('/reports/child_age/:uuid/:filter/:params*?',require('./reports/child_age').get);
    app.get('/reports/ebatoenaolised/:uuid/:filter/:params*?',require('./reports/ebatoenaolised').get);

    app.get('/reports/saldo_ja_kaive/:uuid/:filter/:params*?',require('./reports/saldo_ja_kaive').get);

    app.get('/reports/arved_koodi_jargi/:uuid/:params*?',require('./reports/arved_koodi_jargi').get);

    app.get('/reports/inf3/:uuid/:params/',require('./reports/inf3').get);
    app.get('/reports/inf3/:uuid/',require('./reports/inf3').get);

    app.get('/pdf/:documentType/:uuid/:id/', require('./pdf').get); //checkAuth

    app.post('/email', checkAuth, require('./email').post); //checkAuth

    app.post('/e-arved', checkAuth, require('./e-arved').post); //checkAuth
    app.get('/e-arved/:uuid/:id/',require('./e-arved').get);
    app.get('/sepa/:uuid/:id/',require('./sepa').get);

    app.post('/calc/muuda_ettemaksu_period', checkAuth, require('./lapsed/muuda_ettemaksu_period').post); //checkAuth
    app.post('/calc/:taskName', checkAuth, require('./calc').post); //checkAuth
    app.delete('/newApi/:documentType/:id', checkAuth, require('./documentRegister').delete); //апи для обмена даты по протоколу delete с моделью документа

    /*

        app.delete('/api/doc/:id', checkAuth, require('./api_doc').delete);

    */

};