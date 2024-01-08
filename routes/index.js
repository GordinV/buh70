'use strict';

const checkAuth = require('../middleware/checkAuth');

module.exports = function (app) {

    // arv.palk leht

    /*
        app.get('/print/PALK_LEHT/', require('./palk/palk_leht').get); //checkAuth
        // arv.palk leht
        app.get('/print/PALK_LEHT/:id', require('./palk/palk_leht').get); //checkAuth
        // arv.palk leht, pdf
        app.get('/pdf/PALK_LEHT/:id', require('./palk/palk_leht').pdf); //checkAuth
        // arv.palk leht, email
        app.get('/email/PALK_LEHT/:id', require('./palk/palk_leht').email); //checkAuth
    */

// taotlus
    app.get('/print/TAOTLUS/:hash/:id/', require('./eelproj/taotlus').get); //checkAuth
    app.post('/print/TAOTLUS/:hash/:id', require('./eelproj/taotlus').post); //checkAuth


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

    app.get('/get_access_code/:kasutaja/:access_code', require('./get_access_code').get);
    app.post('/get_access_code', require('./get_access_code').post);
    app.get('/raama', require('./raama').get); // module raamatupidamine
    app.get('/raama/:documentType', checkAuth, require('./raama').get); // module raamatupidamine
    app.get('/raama/:documentType/:id', checkAuth, require('./raama/document').get); // module raamatupidamine

    app.get('/palk/:documentType/', require('./palk').get); //checkAuth


    app.get('/lapsed', checkAuth, require('./lapsed').get); // module lapsed
    app.get('/lapsed/:documentType', checkAuth, require('./lapsed').get); // module lapsed
    app.get('/lapsed/:documentType/:id', checkAuth, require('./lapsed/document').get); // module lapsed
    app.get('/lapsed/:documentType/:id/:paramId', checkAuth, require('./lapsed/document').get); // module lapsed
// /newApi/noticed

    app.post('/newApi/noticed', require('./noticed').post); //checkAuth,
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
    app.get('/multiple_print/teatis/:uuid/:id/', require('./multiple_print').teatis); //checkAuth
    app.get('/multiple_print/arv/:uuid/:id/', require('./multiple_print').arve); //checkAuth
    app.get('/multiple_print/:documentType/:uuid/:id/', require('./multiple_print').get); //checkAuth


    app.get('/print/:documentType/:uuid/', require('./print').get); //checkAuth

    app.get('/help/:documentType?/', require('./help').get); //checkAuth

    app.get('/reports/child_age/:uuid/:filter/:params*?', require('./reports/child_age').get);
    app.get('/reports/ebatoenaolised/:uuid/:filter/:params*?', require('./reports/ebatoenaolised').get);
    app.get('/reports/kondarve/:uuid/:filter/:params*?', require('./reports/kondarve').get);
    app.get('/reports/kaive_aruanne_kokku/:uuid/:filter/:params*?', require('./reports/kaive_aruanne_kokku').get);
    app.get('/reports/kaive_aruanne/:uuid/:filter/:params*?', require('./reports/kaive_aruanne').get);
    app.get('/reports/saldo_ja_kaive/:uuid/:filter/:params*?', require('./reports/saldo_ja_kaive').get);
    app.get('/reports/saldo_ja_kaibeandmik/:uuid/:filter/:params*?', require('./reports/saldo_ja_kaibeandmik').get);
    app.get('/reports/kuutabeli_aruanne/:uuid/:filter/:params*?', require('./reports/kuutabeli_aruanne').get);
    app.get('/reports/arved_koodi_jargi/:uuid/:filter/:params*?', require('./reports/arved_koodi_jargi').get);
    app.get('/reports/arved_koodi_jargi/:uuid/:params*?', require('./reports/arved_koodi_jargi').get);
    app.get('/reports/inf3/:uuid/:filter/:params*?/', require('./reports/inf3').get);
    app.get('/reports/inf3/:uuid/:params/', require('./reports/inf3').get);
    app.get('/reports/inf3/:uuid/', require('./reports/inf3').get);
    app.get('/reports/inf3_analuus/:uuid/:filter/:params*?/', require('./reports/inf3_analuus').get);
    app.get('/reports/inf3_analuus/:uuid/:params*?', require('./reports/inf3_analuus').get);
    app.get('/reports/kuu_taabel/:uuid/:filter/:params*?', require('./reports/kuu_taabel').get);
    app.get('/reports/yksuse_taabel/:uuid/:filter/:params*?', require('./reports/yksuse_taabel').get);
    app.get('/reports/kohaoleku_aruanne/:uuid/:filter/:params*?', require('./reports/kohaoleku_aruanne').get);
    app.get('/reports/lapse_kaart/:uuid/:kond/:filter/:params*?', require('./reports/lapse_kaart').get);
    app.get('/reports/lapse_kaart/:uuid/:kond/', require('./reports/lapse_kaart').get);
    app.get('/reports/lapse_taabel/:uuid/:params*?/', require('./reports/lapse_taabel').get);
    app.get('/reports/pank_vv/:uuid/:filter/:params*?/', require('./reports/pank_vv').get);
    app.get('/reports/pank_vv/:uuid/:params*?/', require('./reports/pank_vv').get);

    app.get('/pdf/:documentType/:uuid/:id/:params', require('./pdf').get); //checkAuth
    app.get('/pdf/:documentType/:uuid/:id/', require('./pdf').get); //checkAuth


    app.post('/email/sendPrintForm', checkAuth, require('./email').sendPrintForm); //will send printForm to receiver
    app.post('/email/teatis', checkAuth, require('./email').sendTeatis); //will send teatis
    app.post('/email', checkAuth, require('./email').post); //will send arve

    app.post('/e-arved', checkAuth, require('./e-arved').post); //checkAuth
    app.get('/e-arved/seb/:uuid/:id/', require('./e-arved').seb);
    app.get('/e-arved/swed/:uuid/:id/', require('./e-arved').swed);
    app.get('/e-arved/:uuid/:id/', require('./e-arved').get);
    app.get('/sepa/:uuid/:id/', require('./sepa').get);

    app.post('/calc/koostaTeatis', checkAuth, require('./lapsed/koostaTeatis').post); //checkAuth
    app.post('/calc/muuda_ettemaksu_period', checkAuth, require('./lapsed/muuda_ettemaksu_period').post); //checkAuth
    app.post('/calc/muuda_teenuste_tahtaeg', checkAuth, require('./lapsed/muuda_teenuste_tahtaeg').post); //checkAuth
    app.post('/calc/koostaEttemaksuArved', checkAuth, require('./lapsed/koostaEttemaksud').post); //checkAuth
    app.post('/calc/koostaArved', checkAuth, require('./lapsed/koostaArved').post); //checkAuth
    app.post('/calc/koostaKoikArved', checkAuth, require('./lapsed/koostaKoikArved').post); //checkAuth
    app.post('/calc/arvestaTaabel', checkAuth, require('./lapsed/arvestaTaabel').post); //checkAuth
    app.post('/calc/arvestaKoikTaabelid', checkAuth, require('./lapsed/arvestaKoikTaabelid').post); //checkAuth
    app.post('/calc/koostaTagasimakse', checkAuth, require('./raama/koostaTagasimakse').post); //checkAuth
    app.post('/calc/loe_makse', checkAuth, require('./lapsed/loe_makse').post); //checkAuth
    app.post('/calc/ebatoenaolised', checkAuth, require('./raama/ebatoenaolised').post); //checkAuth
    app.post('/calc/importAsendusTaabel', checkAuth, require('./lapsed/importAsendusTaabel').post); //checkAuth
    app.post('/calc/:taskName', checkAuth, require('./calc').post); //checkAuth

    app.delete('/newApi/:documentType/:id', checkAuth, require('./documentRegister').delete); //апи для обмена даты по протоколу delete с моделью документа

    /*

        app.delete('/api/doc/:id', checkAuth, require('./api_doc').delete);

    */

};