'use strict';


const React = require('react');
const ReactServer = require('react-dom/server');
const getModule = require('./../libs/getModule');

exports.get = async (req, res) => {
    // рендер грида на сервере при первой загрузке странице
    // берем тип документа из параметра в адресе
    let documentType = 'DOK';

    if (req.params.id) {
        documentType = req.params.id;
    }
    documentType.toLowerCase();

    const DocumentRegister = require(`../frontend/docs/${documentType}/index.jsx`);
    let user = require('../middleware/userData')(req);  // check for userid in session

    if (!user) {
        //error 401, no user
        return res.status(401).redirect('/login');
    }

    const Doc = require('./../classes/DocumentTemplate');
    const Document = new Doc(documentType, null, user.userId, user.asutusId);

    // делаем запрос , получаем первоначальные данные
    let gridConfig = Document.config.grid.gridConfiguration;
    // вызвать метод
    let data = {
        result: await Document.selectDocs(),
        gridConfig: gridConfig,
        docTypeId: documentType
    };

    const Component = React.createElement(
        DocumentRegister,
        {id: 'doc', initData: data, userData: user}, 'Тут будут компоненты');

    try {
        let html = ReactServer.renderToString(Component);

        // передатим в хранилище данные
        let storeInitialData = JSON.stringify(data);
        let userData = JSON.stringify(user);

        res.render(documentType + 'Register', {
            "user": user,
            "userData": userData,
            "store": storeInitialData
            , react: html
        });

    } catch (e) {
        console.error('error:', e);
        res.statusCode = 500;
    }

};

exports.post = async (req, res) => {
    let user = require('../middleware/userData')(req); // данные пользователя
    const documentType = req.params.documentType.toUpperCase(); // получим из параметра тип документа
    const docId = Number(req.params.id); //ид документа
    const module = req.params.module || 'lapsed'; // используемый модуль


    if (!user) {
        return res.status(401).end();
    }

    const params = {
        documentType: documentType,
        docId: docId,
        user: user
    };

    const Doc = require('./../classes/DocumentTemplate');
    const Document = new Doc(documentType, docId, user.userId, user.asutusId, module.toLowerCase());

    let data;

    // вызвать метод. Есди ИД = 0, то вызывается запрос на создание нового документа
    if (docId) {
        data = {result: await Document.select()};
    } else {
        data = {result: await Document.createNew()};
    }

    const preparedData = Object.assign({},
        data.result ? data.result.row[0] : {},
        data.result,
        {gridData: data.result ? data.result.details : []},
        {relations: data.result ? data.result.relations : []},
        {gridConfig: data.result ? data.result.gridConfig : []});

    res.send({data: [preparedData], userData: user});

};

exports.put = async (req, res) => {
    let user = require('../middleware/userData')(req); // данные пользователя
    let documentType = req.params.documentType.toUpperCase(); // получим из параметра тип документа

    const docId = Number(req.params.id); //ид документа
    const module = req.params.module || 'lapsed';
    let data = req.body;

    if (!user) {
        raise.error('No user', user);
        const err = new HttpError(err);
        if (err instanceof HttpError) {
            return res.send({"message": 'No user'});
        }
    }

    const params = {
        userId: user.userId,
        asutusId: user.asutusId,
        data: {data}
    };

    const Doc = require('./../classes/DocumentTemplate');
    const Document = new Doc(documentType, docId, user.userId, user.asutusId, module);

    const savedData = await Document.save(params);

    if (!savedData.row || savedData.row.length < 1) {
        return res.status(500).send({result: {error_code: 1, error_message: 'Error in save', docId: 0}});
    }


    const prepairedData = Object.assign({}, savedData.row[0],
        savedData,
        {bpm: savedData.bpm ? savedData.bpm : []},
        {gridData: savedData.details ? savedData.details : []},
        {relations: savedData.relations ? savedData.relations : []},
        {gridConfig: savedData.gridConfig ? savedData.gridConfig : []});


    res.send({result: {error_code: 0, error_message: null, docId: prepairedData.id}, data: [prepairedData]}); //пока нет новых данных


};

exports.delete = async (req, res) => {
    const documentType = req.body.parameter.toUpperCase(); // получим из параметра тип документа
    const docId = Number(req.body.docId); //ид документа
    const module = req.body.module || 'lapsed'; // используемый модуль
    const userId = req.body.userId;


    const Doc = require('./../classes/DocumentTemplate');

    // вызвать метод. Есди ИД = 0, то вызывается запрос на создание нового документа

    let user = require('../middleware/userData')(req); // данные пользователя

    if (!userId) {
        console.error('no userId', userId, req.body, user.userId);
        return res.status(401).end();
    }
    const params = {
        documentType: documentType,
        docId: docId,
        user: user
    };


    const Document = new Doc(documentType, docId, userId, user.asutusId, module.toLowerCase());
    let data;

    data = {result: await Document.delete()};
    res.send({data: data});

};
