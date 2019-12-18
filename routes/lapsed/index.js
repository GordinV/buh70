'use strict';

const React = require('react');
const ReactServer = require('react-dom/server');
const getModule = require('./../../libs/getModule');

const {StaticRouter} = require('react-router');
const App = require('./../../frontend/modules/lapsed.jsx');
const DocContext = require('./../../frontend/doc-context');

exports.get = async (req, res) => {
    let documentType = req.params.documentType ? req.params.documentType : 'laps';

    let user = req.app.locals.user;
    req.app.locals.user = null;

    if (!user) {
        //error 401, no user
        return res.status(401).redirect('/login');
    }

    const Doc = require('./../../classes/DocumentTemplate');
    const Document = new Doc(documentType, null, user.userId, user.asutusId, 'lapsed');
    // делаем запрос , получаем первоначальные данные
    let gridConfig = Document.config.grid.gridConfiguration;
    // вызвать метод

    const sqlData = {
        docTypeId: documentType,
        result: await Document.selectDocs(),
        gridConfig: gridConfig,
        requiredFields: Document.requiredFields ? Document.requiredFields: [],
        subtotals: Document.config.grid.subtotals ? Document.config.grid.subtotals : []
    };

    let storeInitialData = JSON.stringify(sqlData);
    let userData = JSON.stringify(user);
    let context = {};

    DocContext.initData = sqlData;
    DocContext.userData = user;
    DocContext.module = 'lapsed';

    const Component = React.createElement(
        StaticRouter,
        {context: context, location: req.url}, React.createElement(
            App,
            {initData: sqlData, userData: user}));

    try {
        let html = ReactServer.renderToString(Component);
        if (context.url) {
            res.writeHead(301, {
                location: context.url
            });
            res.end()
        } else {
            res.render('lapsed', {
                "title": documentType,
                "user": user,
                "userData": userData,
                "store": storeInitialData
                , react: html
            });
        }


    } catch (e) {
        console.error('error:', e);
        res.statusCode = 500;
    }

};

exports.post = async (req, res) => {

    let user = require('./../../middleware/userData')(req); // данные пользователя
    const documentType = req.params.documentType.toUpperCase(); // получим из параметра тип документа
    const docId = Number(req.params.id); //ид документа

    const params = {
        documentType: documentType,
        docId: docId,
        user: user
    };

    const Doc = require('./../classes/DocumentTemplate');
    const Document = new Doc(documentType, docId, user.userId, user.asutusId);

    let data;

    // вызвать метод. Есди ИД = 0, то вызывается запрос на создание нового документа
    if (docId) {
        data = {result: await Document.select()};
    } else {
        data = {result: await Document.createNew()};
    }

    const preparedData = Object.assign({}, data.result.row,
        {gridData: data.result.details},
        {relations: data.result.relations},
        {gridConfig: data.result.gridConfig});

    res.send({params: params, data: [preparedData]});

};

exports.put = async (req, res) => {
    let user = require('../middleware/userData')(req); // данные пользователя
    let documentType = req.params.documentType.toUpperCase(); // получим из параметра тип документа
    const docId = Number(req.params.id); //ид документа
    let data = req.body;

    if (!user) {
        user = {
            userId: 1,
            asutusId: 1
        }
    }

    const params = {
        userId: user.userId,
        asutusId: user.asutusId,
        data: {data}
    };

    const Doc = require('./../classes/DocumentTemplate');
    const Document = new Doc(documentType, docId, user.userId, user.asutusId);

    let savedData = await Document.save(params);

    const prepairedData = Object.assign({}, savedData.row[0],
        {bpm: savedData.bpm ? savedData.bpm : []},
        {gridData: savedData.details ? savedData.details : []},
        {relations: savedData.relations ? savedData.relations : []},
        {gridConfig: savedData.gridConfig ? savedData.gridConfig : []});


    res.send({result: {error_code: 0, error_message: null, docId: prepairedData.id}, data: [prepairedData]}); //пока нет новых данных


};