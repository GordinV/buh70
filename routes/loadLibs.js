'use strict';
const _ = require('lodash'),
    HttpError = require('./../error').HttpError;


exports.post = async (req, res) => {
    let user = require('../middleware/userData')(req); // данные пользователя
    let documentType = req.params.documentType.toUpperCase(); // получим из параметра тип документа

    let sqlWhere = _.has(req.body,'sql') ? req.body.sql: null;
    let sqlLimit = _.has(req.body,'limit') ? req.body.limit: null;

    if (!user) {
        const err = new HttpError(403, 'No user');
        res.send({result: 'error'});
    }

    const Doc = require('./../classes/DocumentTemplate');
    const Document = new Doc(documentType, null, user.userId, user.asutusId);

    let data = await Document.selectLibs(sqlWhere, sqlLimit);
    let local_result = Object.assign({},{result: data});

    res.send({result: local_result}); //пока нет новых данных

};