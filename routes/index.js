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
    app.get('/document/:id', checkAuth, require('./document').get);

    app.get('/tunnus', checkAuth, require('./tunnused').get); // module tunnused
    app.get('/tunnused', checkAuth, require('./tunnused').get); // module tunnused
//    app.get('/tunnused/tunnus:id', checkAuth, require('./tunnus').get); // module tunnused


    // opens main page
    app.get('/main', checkAuth, require('./main').get);
    // opens page with list of departments
    app.get('/changeDepartment', checkAuth, require('./changeDepartment').get);
    app.get('/changeDepartment/:id', checkAuth, require('./changeDepartment').get);
    // opens document template
    app.get('/documents', checkAuth, require('./documents').get);

    // temorary solution> only for test
    //app.get('/docs', checkAuth, require('./docs').get);
    // opens document template
    app.post('/api', checkAuth, require('./api').post);

    app.post('/api/docs', checkAuth, require('./api').post);
    app.post('/api/doc', checkAuth, require('./api_doc').post);

    app.post('/newApi/startMenu',checkAuth, require('./startMenu').post); //checkAuth,
    app.post('/newApi', checkAuth, require('./newApi').post); //checkAuth,

    app.delete('/api/doc/:id', checkAuth, require('./api_doc').delete);


};