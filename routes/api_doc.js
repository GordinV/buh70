// обработка пост запросов для документа
'use strict';
const React = require('react');
const DocDataObject = require('../models/documents') // подключим модель


exports.post = function (req, res) {
    console.log('called post API', req.body, req.body.action);
    let user = require('../middleware/userData')(req),
        data = JSON.parse(req.body.data),
        action = req.body.action,
        docId = data.docId,
        docTypeId = data.doc_type_id,
        results = {},
        params = [];

    if (docId) {
        /*
         req.session.docs.push(
         {  component:'doc',
         parameter: docTypeId,
         sortBy:null,
         sqlWhere:null,
         docId: docId,
         action: action
         });
         */
        let docs = req.session.docs,
            lastInxex = docs.length - 1;

        req.session.docs[lastInxex].docId = docId;

    }

    switch (action) {
        case 'save':
            params = [data, user.userId, user.asutusId];
            try {
                // тут вызов метода сохранение
                // выборка сохраненных данных
                DocDataObject.saveDocPromise(docTypeId, params)
                    .then(data => {
                            res.send(data)
                        },
                        err => {
                            console.error('viga:', err);
                            res.send({result: 'Error'});
                        });
            } catch (err) {
                console.error('error:', err); // @todo Обработка ошибок
                res.send({result: 'Error'});

            }
            break;
        case 'execute':
            /*
             обработка запросов на исполнение задач.
             */
            params = {params: data, userId: user.userId, rekvId: user.asutusId, userName: user.userName};

            DocDataObject.executeTaskPromise(docTypeId, params)
                .then(docData => {
                        console.log('docData',docData);
                        res.send({result: 'Ok', data: docData});
                    },
                    err => {
                        console.error('catched error', err);
                        res.send({result: 'Error'});
                    });

            break;
        case 'select':
            // select data for Grid
            // @todo закончить
            let parameter = req.body.parameter || '',
                results = {},
                lastDocId = req.body.lastDocId ? req.body.lastDocId : 0,
                sortBy = req.body.sortBy || '', //порядок сортировки
                sqlWhere = req.body.sqlWhere || ''; //динамический фильтр

            try {
                const result = DocDataObject[docTypeId].requery(parameter, callback, results, sortBy, sqlWhere, user);

/*
                const returnData = components.map(function (component) {
                    component.data = results[component.name].data;
                    component.lastDocId = lastDocId;

                    return component;
                });
*/
                res.send(result);

            } catch (err) {
                console.error('error:', err); // @todo Обработка ошибок
                res.send({result: 'Error'});
            }
            break;
        case 'selectAsLibs':
            console.log('docTypeId, params, action', docTypeId, params, action);
            //@todo Убрать повоторяющийся код
            params = [];
            if (data.params.length > 0) {
                params = data.params;
            }

            try {

                DocDataObject.selectDocPromise(docTypeId, params, action)
                    .then(data => {
                            res.send(data)
                        },
                        err => {
                            console.error('viga:', err);
                            res.send({result: 'Error'});
                        });
            } catch (err) {
                console.error('error:', err); // @todo Обработка ошибок
                res.send({result: 'Error'});
            }
            break;
        case 'saveAndSelect':
            params = [];
            async.waterfall([
                    function (callback) {
                        DocDataObject.saveDoc(docTypeId, params, callback); // сохраняем документ
                    },
                    function (savedResult, callback) {
                        results = result.rows[0]; // результат сохранения
                        DocDataObject.selectDoc(docTypeId, params, callback); // выборка документов
                    },
                    function (selectResult, callback) {
                        results.data = selectResult; // результат выборки
                        callback(null, selectResult);
                    }
                ],
                function (err, result) {
                    if (err) {
                        console.error('SQL error');
                        throw err;
                    }
                    res.send(result.rows[0] || {});
                });

            // ищем данные в кеше
            //   if (!results) {
            DocDataObject.selectDoc(docTypeId, params, function (err, data) {
                if (err) {
                    console.error('selectDoc error:' + JSON.stringify(err));
                    throw err;
                }
                // сохраним данные в кеше
//            localStorage.setLib(docTypeId, data, req);
                res.send(data);
            }, results);
//    }
            break;
    } // case


}; //function post

exports.delete = async (req, res) => {
    let user = require('../middleware/userData')(req),
        parameter = req.params.id,
        docTypePattern = /[0-9]/gi,
        docIdPattern = /[^0-9]/gi,
        docId = parameter.replace(docIdPattern, '').trim(),
        docTypeId = parameter.replace( docTypePattern, '').trim(),
        params = [user.userId, docId];

    try {
        // тут вызов метода сохранение
        let results = await DocDataObject.deleteDocPromise(docTypeId, params);
        res.send(results);
    } catch (err) {
        console.error('error:', err);
        res.send({result: 'Error'});

    }
}; //function delete
