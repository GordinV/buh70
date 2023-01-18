'use strict';


const React = require('react');
const ReactServer = require('react-dom/server');
const path = require('path');
const Moment = require('moment');
let now = Moment().format('YYYY-MM-DD');
const prepaireFilterData = require('./../libs/prepaireFilterData');
const prepareSqlWhereFromFilter = require('./../libs/prepareSqlWhereFromFilter');
const config = require('./../config/lapsed');
const menuModel = require('./../models/ou/start-menu');
const RECORDS_LIMIT = require('./../config/constants').RECORDS_LIMIT;
const async = require('async');

const db = require('./../libs/db');

exports.get = async (req, res) => {
    // рендер грида на сервере при первой загрузке странице
    // берем тип документа из параметра в адресе
    let documentType = 'DOK';

    if (req.params.id) {
        documentType = req.params.id;
    }
    documentType.toLowerCase();

    const DocumentRegister = require(`../frontend/docs/${documentType}/index.jsx`);
    let user = await require('../middleware/userData')(req);  // check for userid in session

    if (!user) {
        //error 401, no user
        return res.status(401).redirect('/login');
    }

    // готовим загрузку конфигурации регистров
    let kataloog = './../models/';
    const docConfig = [];

    Object.keys(config).forEach(key => {
        let folder = path.join(kataloog, config[key]);
        docConfig.push({docTypeId: key.toUpperCase(), grid: require(folder).grid.gridConfiguration})
    });


    const Doc = require('./../classes/DocumentTemplate');
    const Document = new Doc(documentType, null, user.userId, user.asutusId);

    // делаем запрос , получаем первоначальные данные
    const gridConfig = Document.config.grid.gridConfiguration;

    // применить дефолты
    let sortBy;
    let sqlWhere;

    const filterData = prepaireFilterData(gridConfig, documentType);
    sqlWhere = prepareSqlWhereFromFilter(filterData, documentType);


    const sqlString = menuModel.sqlString,
        params = [module];


    // вызвать метод
    let data = {
        result: await Document.selectDocs(sortBy, sqlWhere, RECORDS_LIMIT),
        menu: await db.queryDb(menuModel.sqlString, ['lapsed']),
        gridConfig: gridConfig,
        docTypeId: documentType,
        docsConfig: docConfig,
        requiredFields: Document.config.requiredFields ? Document.config.requiredFields : []

    };

    const Component = React.createElement(
        DocumentRegister,
        {id: 'doc', initData: data, userData: user, title: documentType}, 'Тут будут компоненты');

    try {
        let html = ReactServer.renderToString(Component);
        // передатим в хранилище данные
        let storeInitialData = JSON.stringify(data);
        let userData = JSON.stringify(user);

        res.render(documentType + 'Register', {
            "user": user,
            "userData": userData,
            "store": storeInitialData,
            "title": documentType
            , react: html
        });

    } catch (e) {
        console.error('error:', e);
        res.statusCode = 500;
    }

};

exports.post = async (req, res) => {

    let user = await require('../middleware/userData')(req); // данные пользователя
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

    res.send({action: 'select', result: 'ok', data: [preparedData], userData: user, title: documentType});

};

exports.put = async (req, res) => {
    let user = await require('../middleware/userData')(req); // данные пользователя
    let documentType = req.params.documentType.toUpperCase(); // получим из параметра тип документа

    const docId = Number(req.params.id); //ид документа
    const module = req.params.module || 'lapsed';
    let data = req.body;

    if (!user) {
        console.error('No user', user);
        return res.send({
            action: 'save',
            result: {error_code: 4, error_message: 'Autentimise viga'},
            data: []
        });
    }

    const params = {
        userId: user.userId,
        asutusId: user.asutusId,
        data: {data}
    };

    const Doc = require('./../classes/DocumentTemplate');
    const Document = new Doc(documentType, docId, user.userId, user.asutusId, module);

    // валидация использование
    let result = Document.config.select.find(row => {
        if (row.alias && row.alias == 'validate_lib_usage') {
            return row;
        }
    });

    if (result && data.valid) {
        // есть запрос для валидации
        const tulemused = await db.queryDb(result.sql, [user.asutusId, docId, data.valid]);

        if (tulemused && ((tulemused.result && tulemused.result > 0) || tulemused.error_code)) {
            let raport = tulemused.data.map((row, index) => {
                return {id: index, result: 0, kas_vigane: true, error_message: row.error_message};
            });

            if (tulemused.error_code && !tulemused.data.length) {
                // одно сообщение не массив
                raport = [{id: 1, result: 0, kas_vigane: true, error_message: tulemused.error_message}];
            }

            return res.send({
                action: 'save',
                result: {error_code: 1, error_message: 'Kood kasutusel'},
                data: raport
            })
        }
    }
    let savedData;
    try {
        savedData = await Document.save(params);

        let l_error = '';
        if (Document.config.bpm) {
            // bpm proccess
            const automatTask = await Document.config.bpm.filter(task => task.type === 'automat');

            await automatTask.forEach(async (process) => {
                const bpmResult = await Document.executeTask(process.action);
                if (bpmResult && bpmResult.error_code) {
                    // raise error
                    l_error = l_error ? l_error : 'Lisa töö viga ' + bpmResult.error_message ? bpmResult.error_message : '';
                    console.error('BPM error', l_error);
                }

            });
        }

        if (!savedData.row || savedData.row.length < 1 || l_error.length > 1) {
            l_error = l_error + (savedData && savedData.error_message ? savedData.error_message : null);
            return res.send({
                action: 'save',
                result: {error_code: 1, error_message: l_error ? l_error : 'Error in save ', docId: 0}
            });

        }

    } catch (e) {
        return res.send({
            action: 'save',
            result: {error_code: 1, error_message: 'Error in save ', docId: 0}
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
    const additionalData = req.body.data; //ид документа
    const module = req.body.module || 'lapsed'; // используемый модуль
    const userId = req.body.userId;
    let isBundleDelete = false;
    let docsIds = [];
    const rows = [];
    let deletedRows = 0;
    let errorMessage;
    let errorCode;

    if (additionalData && additionalData.docs && additionalData.docs.length) {
        docsIds = additionalData.docs;
        isBundleDelete = true;
    }

    const Doc = require('./../classes/DocumentTemplate');

    // вызвать метод. Есди ИД = 0, то вызывается запрос на создание нового документа

    let user = await require('../middleware/userData')(req); // данные пользователя

    if (!userId) {
        console.error('no userId', userId, req.body, user.userId);
        return res.status(401).end();
    }

//    return res.status(500).end();

    const Document = new Doc(documentType, docId, userId, user.asutusId, module.toLowerCase());
    let data = [];

    if (isBundleDelete) {
        Document.setDocumentId(docsIds.join(','));
    }
    deletedRows = 1;
    let result = await Document.delete();

    if (result && !result.error_code) {
        deletedRows = deletedRows + result.result;
        errorMessage = result.error_message
    } else {
        errorCode = result.error_code;
        errorMessage = result.error_message;
        console.error('error', data, result)
    }

    if (deletedRows) {
        res.send({
            action: 'delete',
            error: 0,
            error_message: null,
            data: {result: deletedRows, error_code: null, error_message: errorMessage}
        });
    } else {
        res.send({
            action: 'delete',
            error: errorCode,
            data: rows,
            error_message: errorMessage
        });
    }

};

exports.executeTask = async (req, res) => {
    const user = await require('../middleware/userData')(req); // данные пользователя
    const taskName = req.params.taskName; // получим из параметра task
    const Doc = require('./../classes/DocumentTemplate');
    const params = req.body;
    let module = (params.module ? params.module : 'lapsed').toLowerCase();

    let seisuga = params.seisuga ? params.seisuga : now;
    let gruppId = params.gruppId ? params.gruppId : null;
    let viitenumber = params.viitenumber ? params.viitenumber : null;
    let kogus = params.kogus ? params.kogus : null;

    const Document = new Doc(params.docTypeId, params.docId, user.userId, user.asutusId, module);

    let taskParams;

    if ((params.docTypeId === 'LAPS' || params.docTypeId === 'PAEVA_TAABEL' || params.docTypeId === 'LAPSE_GRUPP' || params.docTypeId === 'SMK' || params.docTypeId === 'NOMENCLATURE')) {
        //@TODO сделать универсальный набор параметров
        taskParams = [params.docId, user.userId, seisuga];
        if (viitenumber) {
            // есть 4 параметр, добавим
            taskParams.push(viitenumber);
        }
        if (kogus && taskName == 'KoostaUlekanneMakse') {
            // есть 5 параметр, добавим
            taskParams.push(kogus);
        }
    }

    if (taskName == 'ebatoenaolised') {
        taskParams = [params.docId, user.userId, seisuga];
    }

    if (params.docTypeId === 'LAPS' && gruppId) {
        // задача с параметром gruppId
        taskParams.push(gruppId);
    }
    const data = await Document.executeTask(taskName, taskParams ? taskParams : null);


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
    const user = await require('../middleware/userData')(req); // данные пользователя
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

exports.validateLibs = async (req, res) => {
    const user = await require('../middleware/userData')(req); // данные пользователя
    const Doc = require('./../classes/DocumentTemplate');
    const params = req.body;
    const Document = new Doc(params.docTypeId, params.docId, user.userId, user.asutusId, params.module.toLowerCase());

    let result = Document.find(row => {
        if (row.alias && row.alias == 'validate_lib_usage') {
            return row;
        }
    });

    if (!result) {
        return res.send({
            action: 'validate',
            result: {
                error_code: 1,
                error_message: 'validate_lib_usage not found',
                docId: null
            },
            data: null
        })
    }


    const sqlString = result.sql;

    // вызвать метод
    let data = {
        data: await db.queryDb(sqlString, params),
    };

    res.send({
        action: 'validateLibs',
        result: {
            error_code: 0,
            error_message: null,
        },
        data: data
    });
};

exports.getLogs = async (req, res) => {
    const user = await require('../middleware/userData')(req); // данные пользователя
    const Doc = require('./../classes/DocumentTemplate');
    const params = req.body;
    if (!user || !user.userId) {
        // ошибка ацтификации
        return res.status(401).end();
    }
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
    upload(req, res, async function (err) {
        if (err instanceof multer.MulterError) {
            return res.status(500).json(err);
        } else if (err) {
            return res.status(500).json(err);
        }
        const content = req.file.buffer.toString();

        // доп параметры
        let params = JSON.parse(JSON.stringify(req.body));
        const user = await require('../middleware/userData')(req, params.uuid); // данные пользователя

        if (!user) {
            return res.status(401);
        }

        // вызываем разбор файла
        try {
            const readFile = require(`./import/${params.docTypeId.toLowerCase()}`);

            const result = await readFile(content, req.file.mimetype, user);
            return res.status(200).send(result);
        } catch (e) {
            console.error('viga', e);
            return res.status(500).send(e.error);

        }

    });

};