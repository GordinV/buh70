'use strict';


const React = require('react');
const ReactServer = require('react-dom/server');

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
        docTypeId: documentType,
        requiredFields: Document.config.requiredFields ? Document.config.requiredFields : []

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

    const Doc = require('./../classes/DocumentTemplate');
    const Document = new Doc(documentType, docId, user.userId, user.asutusId, module.toLowerCase());

    let data;

    // вызвать метод. Есди ИД = 0, то вызывается запрос на создание нового документа
    if (docId) {
        data = {result: await Document.select()};
    } else {
        data = {result: await Document.createNew()};
    }

    const bpm = Document.config.bpm ? Document.config.bpm.filter(task => task.type === 'manual') : [];

    const preparedData = Object.assign({},
        data.result ? data.result.row[0] : {},
        data.result,
        {gridData: data.result ? data.result.details : []},
        {relations: data.result ? data.result.relations : []},
        {gridConfig: data.result ? data.result.gridConfig : []},
        {bpm: bpm},
        {requiredFields: Document.config.requiredFields ? Document.config.requiredFields : []}
    );

    res.send({action: 'select', result: 'ok', data: [preparedData], userData: user});

};

exports.put = async (req, res) => {
    let user = require('../middleware/userData')(req); // данные пользователя
    let documentType = req.params.documentType.toUpperCase(); // получим из параметра тип документа

    const docId = Number(req.params.id); //ид документа
    const module = req.params.module || 'lapsed';
    let data = req.body;

    if (!user) {
        console.error('No user', user);
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

    if (Document.config.bpm) {
        // bpm proccess
        const automatTaks = Document.config.bpm.filter(task => task.type === 'automat');

        automatTaks.forEach(async (process) => {
            const bpmResult = await Document.executeTask(process.action);
        })

    }

    if (!savedData.row || savedData.row.length < 1) {
        console.error('error in save', params, savedData);
        return res.status(500).send({
            action: 'save',
            result: {error_code: 1, error_message: 'Error in save', docId: 0}
        });
    }


    const prepairedData = Object.assign({}, savedData.row[0],
        savedData,
        {bpm: savedData.bpm ? savedData.bpm : []},
        {gridData: savedData.details ? savedData.details : []},
        {relations: savedData.relations ? savedData.relations : []},
        {gridConfig: savedData.gridConfig ? savedData.gridConfig : []});

    res.send({
        action: 'save',
        result: {error_code: 0, error_message: null, docId: prepairedData.id},
        data: [prepairedData]
    }); //пока нет новых данных


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

    const Document = new Doc(documentType, docId, userId, user.asutusId, module.toLowerCase());
    let data;

    data = {result: await Document.delete()};
    res.send({action: 'delete', data: data});

};

exports.executeTask = async (req, res) => {
    const user = require('../middleware/userData')(req); // данные пользователя
    const taskName = req.params.taskName; // получим из параметра task
    const Doc = require('./../classes/DocumentTemplate');
    const params = req.body;
    const Document = new Doc(params.docTypeId, params.docId, user.userId, user.asutusId, params.module.toLowerCase());

    const data = await Document.executeTask(taskName);

    const prepairedData = Object.assign({}, data);
    res.send({
        action: 'task',
        result: {
            error_code: 0,
            error_message: null,
            docId: prepairedData.result,
            docTypeId: prepairedData.doc_type_id,
            module: params.module
        },
        data: prepairedData
    });
};

exports.validate = async (req, res) => {
    const user = require('../middleware/userData')(req); // данные пользователя
    const method = req.params.method; // получим из параметра метод в моделе
    const parameter = req.params.parameter; // получим из параметра искомое значение
    const Doc = require('./../classes/DocumentTemplate');
    const params = req.body;
    const Document = new Doc(params.docTypeId, params.docId, user.userId, user.asutusId, params.module.toLowerCase());

    const data = await Document.executeTask(method, [parameter]);

    const prepairedData = Object.assign({}, data);
    res.send({
        action: 'task',
        result: {
            error_code: 0,
            error_message: null,
            docId: prepairedData.result,
            docTypeId: prepairedData.doc_type_id,
            module: params.module
        },
        data: prepairedData
    });
};

exports.getLogs = async (req, res) => {
    const user = require('../middleware/userData')(req); // данные пользователя
    const Doc = require('./../classes/DocumentTemplate');
    const params = req.body;
    const Document = new Doc(params.docTypeId, params.docId, user.userId, user.asutusId, params.module.toLowerCase());

    const data = await Document.executeTask('getLog');

    const prepairedData = Object.assign({}, data);
    res.send({
        action: 'getLog',
        result: {
            error_code: 0,
            error_message: null,
            data: prepairedData.result,
            module: params.module
        },
        data: prepairedData
    });

};


exports.upload = async (req, res) => {
    const multer = require('multer');
    const storage = multer.memoryStorage();
    const upload = multer({
        storage: storage
    }).single('file');

    // читаем из буфера файл в память
    upload(req, res, function (err) {
        if (err instanceof multer.MulterError) {
            return res.status(500).json(err);
        } else if (err) {
            return res.status(500).json(err);
        }
        const content = req.file.buffer.toString();

        // доп параметры
        let params = JSON.parse(JSON.stringify(req.body));
        const user = require('../middleware/userData')(req, params.uuid); // данные пользователя

        if (!user) {
            return res.status(401);
        }

        // вызываем разбор файла
        try {
            const readFile = require(`./import/${params.docTypeId}`);
            readFile(content, req.file.mimetype, user).then((result) => {
                    // ответ
                    console.log('success', result);
                    return res.status(200).send(result);
                }
            );


        } catch (e) {
            return res.status(500);

        }

    });

};