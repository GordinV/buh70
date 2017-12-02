'use strict';
/*

 exports.get = function (req, res) {
 const rows = [{id: 1, name: "row1/0", text: "Text 1"}, {id: 2, name: "row2-2", text: "Text 2"}, {
 id: 3,
 name: "row3",
 text: "Text 3"
 }, {id: 4, name: "row4", text: "Text 4"}],
 columns = [{id: "id", name: "id", width: "50px"}, {id: "name", name: "name", width: "300px"}, {
 id: "text",
 name: "text",
 width: "400px"
 }];

 res.send({"gridColumns": columns, "gridData": rows});
 };

 */

exports.post = function (req, res) {
    //   console.log('api req.body', req.body);
    let returnData = [],
        results = {},
        DocDataObject = require('../models/documents'),
        async = require('async'),
        components,
        user = require('../middleware/userData')(req), // данные пользователя
        parameter = req.body.parameter || '',// параметры если переданы
        lastDocId = req.body.lastDocId ? req.body.lastDocId : 0,
        sortBy = req.body.sortBy || '', //порядок сортировки
        sqlWhere = req.body.sqlWhere || ''; //динамический фильтр

    try {
        components = JSON.parse(req.body.components); // массив компонентов для запроса данных
    } catch (e) {
        console.error('parse error', e);
        res.statusCode = 500;
//        res.send();
    }

    if (!req.session.docs) {
        req.session.docs = [];
    }

    console.log('api', components);
    try {
        async.forEach(components, (component, callback) => {
            // сохраним в сессии параметры запроса
            if (lastDocId) {

                req.session.docs.push({
                    component: component.name,
                    parameter: parameter,
                    sortBy: sortBy,
                    sqlWhere: sqlWhere,
                    docId: lastDocId
                });


            }

            // выполняем запрос
            let componentName = component.name;


            console.log('componentName', componentName, parameter);
            DocDataObject[componentName].requery(parameter, callback, results, sortBy, sqlWhere, user);
        }, (err) => {
            if (err) {
                res.send({result:'Error'});
                return
            }

            returnData = components.map(function (component) {
                component.data = results[component.name].data;
                component.lastDocId = lastDocId;

                return component;
            });
            res.send(returnData);
        });
    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({result:'Error'});

    }
// end try
};